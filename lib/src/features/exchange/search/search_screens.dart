part of '../exchange_pages.dart';

class SearchLandingScreen extends StatefulWidget {
  const SearchLandingScreen({
    super.key,
    required this.sessionController,
    required this.tradeController,
    required this.marketDetailController,
    required this.marketQuoteController,
    this.marketNewsController,
    required this.notificationController,
    required this.recentSearches,
    required this.favoriteStockCodes,
    required this.onSearchCommitted,
    required this.onRemoveRecentSearch,
    required this.onClearRecentSearches,
    required this.onToggleFavoriteStock,
    this.onFavoriteChanged,
    required this.onNavigateToAccounts,
    this.nowProvider,
  });

  final ExchangeSessionController sessionController;
  final TradeController tradeController;
  final MarketDetailController marketDetailController;
  final MarketQuoteController marketQuoteController;
  final MarketNewsController? marketNewsController;
  final NotificationController notificationController;
  final List<String> recentSearches;
  final Set<String> favoriteStockCodes;
  final ValueChanged<String> onSearchCommitted;
  final ValueChanged<String> onRemoveRecentSearch;
  final VoidCallback onClearRecentSearches;
  final ValueChanged<String> onToggleFavoriteStock;
  final Future<bool> Function(String stockCode, bool nextIsFavorite)?
      onFavoriteChanged;
  final VoidCallback onNavigateToAccounts;
  final DateTime Function()? nowProvider;

  @override
  State<SearchLandingScreen> createState() => _SearchLandingScreenState();
}

class _SearchLandingScreenState extends State<SearchLandingScreen> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late List<String> _recentSearches;
  late final Set<String> _favoriteStockCodes;
  Timer? _searchDebounce;
  String _query = '';
  bool _isSearching = false;
  String? _searchErrorMessage;
  bool _rankingsLoading = true;
  bool _trendingLoading = true;
  List<StockSearchItem> _liveResults = const [];
  List<StockSearchRankingItem> _rankings = const [];
  List<MarketNewsItem> _trendingNews = const [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _recentSearches = List<String>.from(widget.recentSearches);
    _favoriteStockCodes = {...widget.favoriteStockCodes};
    _controller.addListener(_handleSearchInputChanged);
    unawaited(_loadRankings());
    unawaited(_loadTrendingNews());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _controller.removeListener(_handleSearchInputChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitQuery([String? rawQuery]) {
    final query = (rawQuery ?? _controller.text).trim();
    if (query.isEmpty) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SearchResultScreen(
          initialQuery: query,
          sessionController: widget.sessionController,
          tradeController: widget.tradeController,
          marketDetailController: widget.marketDetailController,
          marketQuoteController: widget.marketQuoteController,
          notificationController: widget.notificationController,
          favoriteStockCodes: _favoriteStockCodes,
          onSearchCommitted: widget.onSearchCommitted,
          onToggleFavoriteStock: widget.onToggleFavoriteStock,
          onFavoriteChanged: widget.onFavoriteChanged,
          onNavigateToAccounts: widget.onNavigateToAccounts,
          nowProvider: widget.nowProvider,
        ),
      ),
    );
  }

  void _clearRecentSearches() {
    setState(() {
      _recentSearches = <String>[];
    });
    widget.onClearRecentSearches();
  }

  void _handleSearchInputChanged() {
    final query = _controller.text.trim();
    if (query == _query) {
      return;
    }
    _searchDebounce?.cancel();
    setState(() {
      _query = query;
      if (query.isEmpty) {
        _liveResults = const [];
        _isSearching = false;
        _searchErrorMessage = null;
      } else {
        _isSearching = true;
        _searchErrorMessage = null;
      }
    });
    if (query.isEmpty) {
      return;
    }
    _searchDebounce = Timer(
      const Duration(milliseconds: 260),
      () => unawaited(_runSearch(query)),
    );
  }

  Future<void> _runSearch(String query) async {
    if (query.isEmpty) {
      return;
    }
    setState(() {
      _query = query;
      _isSearching = true;
      _searchErrorMessage = null;
    });
    try {
      final response = await widget.marketQuoteController.searchStocks(
        query: query,
        limit: 20,
      );
      if (!mounted || _controller.text.trim() != query) {
        return;
      }
      setState(() {
        _liveResults = response.results;
        _isSearching = false;
        _searchErrorMessage = null;
      });
    } on ExchangeApiException catch (error) {
      if (!mounted || _controller.text.trim() != query) {
        return;
      }
      setState(() {
        _liveResults = const [];
        _isSearching = false;
        _searchErrorMessage = error.message;
      });
    } on Object {
      if (!mounted || _controller.text.trim() != query) {
        return;
      }
      setState(() {
        _liveResults = const [];
        _isSearching = false;
        _searchErrorMessage = 'Unable to search stocks.';
      });
    }
  }

  Future<void> _loadRankings() async {
    try {
      final response = await widget.marketQuoteController.loadSearchRankings(
        windowHours: 24,
        limit: 10,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _rankings = response.results;
        _rankingsLoading = false;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _rankings = const [];
        _rankingsLoading = false;
      });
    }
  }

  Future<void> _loadTrendingNews() async {
    final controller = widget.marketNewsController;
    if (controller == null) {
      setState(() {
        _trendingLoading = false;
      });
      return;
    }
    try {
      final response = await controller.loadTrending(windowHours: 24, limit: 5);
      if (!mounted) {
        return;
      }
      setState(() {
        _trendingNews = response.news;
        _trendingLoading = false;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _trendingNews = const [];
        _trendingLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite(String stockCode) async {
    final wasFavorite = _favoriteStockCodes.contains(stockCode);
    final nextIsFavorite = !wasFavorite;
    setState(() {
      if (nextIsFavorite) {
        _favoriteStockCodes.add(stockCode);
      } else {
        _favoriteStockCodes.remove(stockCode);
      }
    });
    final changed = widget.onFavoriteChanged == null
        ? true
        : await widget.onFavoriteChanged!(stockCode, nextIsFavorite);
    if (!changed && mounted) {
      setState(() {
        if (wasFavorite) {
          _favoriteStockCodes.add(stockCode);
        } else {
          _favoriteStockCodes.remove(stockCode);
        }
      });
      return;
    }
    if (widget.onFavoriteChanged == null) {
      widget.onToggleFavoriteStock(stockCode);
    }
  }

  void _rememberSelectedStock(StockSearchItem item) {
    final label = _stockHistoryLabel(item);
    widget.onSearchCommitted(label);
    setState(() {
      _recentSearches = [
        label,
        ..._recentSearches.where(
          (entry) =>
              entry != label && _historySearchQuery(entry) != item.stockCode,
        ),
      ].take(6).toList(growable: false);
    });
    unawaited(widget.marketQuoteController.recordSearchSelection(item));
  }

  void _openDetail(StockSearchItem item) {
    _rememberSelectedStock(item);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => StockDetailScreen(
          sessionController: widget.sessionController,
          marketDetailController: widget.marketDetailController,
          marketQuoteController: widget.marketQuoteController,
          tradeController: widget.tradeController,
          notificationController: widget.notificationController,
          stockCode: item.stockCode,
          title: item.stockName,
          market: item.market,
          sector: item.sector,
          isFavorite: _favoriteStockCodes.contains(item.stockCode),
          onFavoriteToggle: () => _toggleFavorite(item.stockCode),
          onFavoriteChanged: widget.onFavoriteChanged,
          onNavigateToAccounts: widget.onNavigateToAccounts,
          nowProvider: widget.nowProvider,
        ),
      ),
    );
  }

  void _openTrendingNews(MarketNewsItem item) {
    final controller = widget.marketNewsController;
    if (controller == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => MarketNewsDetailScreen(
          item: item,
          marketNewsController: controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _SearchHeaderBar(
              fieldKey: const ValueKey('market-search-input'),
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              hintText: 'Search Everything',
              onSubmitted: _submitQuery,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                children: [
                  if (_query.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Search Results',
                      trailing: _isSearching
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.orange500,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 8),
                    if (_isSearching && _liveResults.isEmpty)
                      const _MutedInfoCard(
                        title: 'Searching stocks',
                        body: 'Loading matching tickers from the exchange.',
                      )
                    else if (_searchErrorMessage != null)
                      _ErrorStateCard(
                        title: 'Search error',
                        message: _searchErrorMessage!,
                        onRetry: () => _runSearch(_query),
                      )
                    else if (_liveResults.isEmpty)
                      const _MutedInfoCard(
                        title: 'No matching stocks',
                        body:
                            'Try a company name, Korean ticker, or English ticker symbol.',
                      )
                    else
                      ..._liveResults.map(
                        (item) => _SearchResultTile(
                          item: item,
                          query: _query,
                          isFavorite:
                              _favoriteStockCodes.contains(item.stockCode),
                          onFavoriteTap: () => _toggleFavorite(item.stockCode),
                          onTap: () => _openDetail(item),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                  _SectionHeader(
                    title: 'Search History',
                    trailing: IconButton(
                      onPressed:
                          _recentSearches.isEmpty ? null : _clearRecentSearches,
                      icon: Image.asset(
                        AppAssets.binIcon,
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                        color: _recentSearches.isEmpty
                            ? AppColors.gray500
                            : AppColors.gray600,
                      ),
                    ),
                  ),
                  if (_recentSearches.isEmpty)
                    const _MutedInfoCard(
                      title: 'No recent searches',
                      body:
                          'Once you search, recent tickers and company names will be stored here.',
                    )
                  else ...[
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (var index = 0;
                              index < _recentSearches.length;
                              index++) ...[
                            _HistoryChip(
                              query: _recentSearches[index],
                              onTap: () {
                                final historyEntry = _recentSearches[index];
                                final query = _historySearchQuery(historyEntry);
                                _controller.text = historyEntry;
                                _controller.selection = TextSelection.collapsed(
                                  offset: _controller.text.length,
                                );
                                _submitQuery(query);
                              },
                            ),
                            if (index != _recentSearches.length - 1)
                              const SizedBox(width: 10),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Most Searched',
                    trailing: Image.asset(
                      AppAssets.rightArrow,
                      width: 18,
                      height: 18,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_rankingsLoading)
                    const _MutedInfoCard(
                      title: 'Loading rankings',
                      body: 'Most searched stocks are being calculated.',
                    )
                  else if (_rankings.isEmpty)
                    const _MutedInfoCard(
                      title: 'No ranking data yet',
                      body:
                          'Stocks selected from search will appear here after users open them.',
                    )
                  else
                    ..._rankings.map(
                      (item) => _MostSearchedRow(
                        item: item,
                        onTap: () => _openDetail(item.toSearchItem()),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Image.asset(
                        AppAssets.trendingIcon,
                        width: 18,
                        height: 18,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Trending',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_trendingLoading)
                    const _MutedInfoCard(
                      title: 'Loading trending news',
                      body: 'Recent article views are being calculated.',
                    )
                  else if (_trendingNews.isEmpty)
                    const _MutedInfoCard(
                      title: 'No trending news yet',
                      body:
                          'Market news opened in the last 24 hours will appear here.',
                    )
                  else
                    ...List.generate(
                      _trendingNews.length,
                      (index) => _TrendingHeadlineRow(
                        rank: index + 1,
                        title: _trendingNews[index].displayTitle,
                        onTap: () => _openTrendingNews(_trendingNews[index]),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchResultScreen extends StatefulWidget {
  const SearchResultScreen({
    super.key,
    required this.initialQuery,
    required this.sessionController,
    required this.tradeController,
    required this.marketDetailController,
    required this.marketQuoteController,
    required this.notificationController,
    required this.favoriteStockCodes,
    required this.onSearchCommitted,
    required this.onToggleFavoriteStock,
    this.onFavoriteChanged,
    required this.onNavigateToAccounts,
    this.nowProvider,
  });

  final String initialQuery;
  final ExchangeSessionController sessionController;
  final TradeController tradeController;
  final MarketDetailController marketDetailController;
  final MarketQuoteController marketQuoteController;
  final NotificationController notificationController;
  final Set<String> favoriteStockCodes;
  final ValueChanged<String> onSearchCommitted;
  final ValueChanged<String> onToggleFavoriteStock;
  final Future<bool> Function(String stockCode, bool nextIsFavorite)?
      onFavoriteChanged;
  final VoidCallback onNavigateToAccounts;
  final DateTime Function()? nowProvider;

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final Set<String> _favoriteStockCodes;
  bool _isLoading = false;
  String? _errorMessage;
  String _query = '';
  List<StockSearchItem> _results = const [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _focusNode = FocusNode();
    _favoriteStockCodes = {...widget.favoriteStockCodes};
    _runSearch(widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitQuery([String? rawQuery]) {
    final query = (rawQuery ?? _controller.text).trim();
    if (query.isEmpty) {
      return;
    }
    widget.onSearchCommitted(query);
    _runSearch(query);
  }

  Future<void> _runSearch(String query) async {
    setState(() {
      _query = query;
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await widget.marketQuoteController.searchStocks(
        query: query,
        limit: 20,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _results = response.results;
        _isLoading = false;
        _errorMessage = null;
      });
    } on ExchangeApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _results = const [];
        _isLoading = false;
        _errorMessage = error.message;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _results = const [];
        _isLoading = false;
        _errorMessage = 'Unable to search stocks.';
      });
    }
  }

  void _toggleFavorite(String stockCode) {
    setState(() {
      if (_favoriteStockCodes.contains(stockCode)) {
        _favoriteStockCodes.remove(stockCode);
      } else {
        _favoriteStockCodes.add(stockCode);
      }
    });
    widget.onToggleFavoriteStock(stockCode);
  }

  void _openDetail(StockSearchItem item) {
    widget.onSearchCommitted(_stockHistoryLabel(item));
    unawaited(widget.marketQuoteController.recordSearchSelection(item));
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => StockDetailScreen(
          sessionController: widget.sessionController,
          marketDetailController: widget.marketDetailController,
          marketQuoteController: widget.marketQuoteController,
          tradeController: widget.tradeController,
          notificationController: widget.notificationController,
          stockCode: item.stockCode,
          title: item.stockName,
          market: item.market,
          sector: item.sector,
          isFavorite: _favoriteStockCodes.contains(item.stockCode),
          onFavoriteToggle: () => _toggleFavorite(item.stockCode),
          onFavoriteChanged: widget.onFavoriteChanged,
          onNavigateToAccounts: widget.onNavigateToAccounts,
          nowProvider: widget.nowProvider,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _SearchHeaderBar(
              fieldKey: const ValueKey('market-search-results-input'),
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              hintText: 'Search Everything',
              onSubmitted: _submitQuery,
              onChanged: (value) {
                final query = value.trim();
                if (query.isNotEmpty) {
                  unawaited(_runSearch(query));
                }
              },
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
                children: [
                  if (_isLoading)
                    const _MutedInfoCard(
                      title: 'Searching stocks',
                      body: 'The stock master is loading matching tickers.',
                    )
                  else if (_errorMessage != null)
                    _ErrorStateCard(
                      title: 'Search error',
                      message: _errorMessage!,
                      onRetry: () => _submitQuery(_query),
                    )
                  else if (_results.isEmpty)
                    const _MutedInfoCard(
                      title: 'No matching stocks',
                      body:
                          'Try a company name, Korean ticker, or English ticker symbol.',
                    )
                  else
                    ..._results.map(
                      (item) => _SearchResultTile(
                        item: item,
                        query: _query,
                        isFavorite:
                            _favoriteStockCodes.contains(item.stockCode),
                        onFavoriteTap: () => _toggleFavorite(item.stockCode),
                        onTap: () => _openDetail(item),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _stockHistoryLabel(StockSearchItem item) {
  final stockCode = item.stockCode.trim();
  final stockName = item.stockName.trim();
  if (stockCode.isEmpty) {
    return stockName;
  }
  if (stockName.isEmpty || stockName == stockCode) {
    return stockCode;
  }
  return '$stockCode $stockName';
}

String _historySearchQuery(String historyEntry) {
  final normalized = historyEntry.trim();
  final codeMatch = RegExp(r'^\d{6}\b').firstMatch(normalized);
  return codeMatch == null ? normalized : codeMatch.group(0)!;
}

class _SearchHeaderBar extends StatelessWidget {
  const _SearchHeaderBar({
    required this.fieldKey,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.onSubmitted,
    required this.onBack,
    this.onChanged,
    this.autofocus = false,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onBack;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(
              width: 36,
              height: 36,
            ),
            icon: Image.asset(
              AppAssets.backArrow,
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SizedBox(
              height: 44,
              child: AppSearchField(
                fieldKey: fieldKey,
                controller: controller,
                focusNode: focusNode,
                autofocus: autofocus,
                hintText: hintText,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                filledColor: AppColors.surface,
                showBorder: false,
                borderRadius: 12,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
