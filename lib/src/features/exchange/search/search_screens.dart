part of '../exchange_pages.dart';

class SearchLandingScreen extends StatefulWidget {
  const SearchLandingScreen({
    super.key,
    required this.sessionController,
    required this.tradeController,
    required this.marketDetailController,
    required this.marketQuoteController,
    required this.notificationController,
    required this.recentSearches,
    required this.favoriteStockCodes,
    required this.onSearchCommitted,
    required this.onRemoveRecentSearch,
    required this.onClearRecentSearches,
    required this.onToggleFavoriteStock,
    required this.onNavigateToAccounts,
  });

  final ExchangeSessionController sessionController;
  final TradeController tradeController;
  final MarketDetailController marketDetailController;
  final MarketQuoteController marketQuoteController;
  final NotificationController notificationController;
  final List<String> recentSearches;
  final Set<String> favoriteStockCodes;
  final ValueChanged<String> onSearchCommitted;
  final ValueChanged<String> onRemoveRecentSearch;
  final VoidCallback onClearRecentSearches;
  final ValueChanged<String> onToggleFavoriteStock;
  final VoidCallback onNavigateToAccounts;

  @override
  State<SearchLandingScreen> createState() => _SearchLandingScreenState();
}

class _SearchLandingScreenState extends State<SearchLandingScreen> {
  static const _mostSearched = <_MarketSearchPreview>[
    _MarketSearchPreview(
      symbol: 'NVDA',
      name: 'NVIDIA',
      priceDisplay: '864.01',
      changeDisplay: '+37.25%',
      secondaryPriceDisplay: '857.99',
      secondaryChangeDisplay: '-0.70%',
      isPositive: true,
    ),
    _MarketSearchPreview(
      symbol: 'NVDA',
      name: 'NVIDIA',
      priceDisplay: '263.47',
      changeDisplay: '-16.74%',
      secondaryPriceDisplay: '272.78',
      secondaryChangeDisplay: '+3.53%',
      isPositive: false,
    ),
    _MarketSearchPreview(
      symbol: 'NVDA',
      name: 'NVIDIA',
      priceDisplay: '864.01',
      changeDisplay: '+37.25%',
      secondaryPriceDisplay: '857.99',
      secondaryChangeDisplay: '-0.70%',
      isPositive: true,
    ),
    _MarketSearchPreview(
      symbol: 'NVDA',
      name: 'NVIDIA',
      priceDisplay: '864.01',
      changeDisplay: '+37.25%',
      secondaryPriceDisplay: '857.99',
      secondaryChangeDisplay: '-0.70%',
      isPositive: true,
    ),
    _MarketSearchPreview(
      symbol: 'NVDA',
      name: 'NVIDIA',
      priceDisplay: '864.01',
      changeDisplay: '+37.25%',
      secondaryPriceDisplay: '857.99',
      secondaryChangeDisplay: '-0.70%',
      isPositive: true,
    ),
  ];

  static const _trendingTopics = <String>[
    'Broadcom’s post-earnings selloff drags down the chip sector - What’s your view a...',
    'Broadcom’s post-earnings selloff drags down the chip sector - What’s your view a',
    'Broadcom’s post-earnings selloff drags down the chip sector - What’s your view a',
  ];

  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late List<String> _recentSearches;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _recentSearches = List<String>.from(widget.recentSearches);
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
    if (!_recentSearches.contains(query)) {
      setState(() {
        _recentSearches = [query, ..._recentSearches].take(6).toList();
      });
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
          favoriteStockCodes: widget.favoriteStockCodes,
          onSearchCommitted: widget.onSearchCommitted,
          onToggleFavoriteStock: widget.onToggleFavoriteStock,
          onNavigateToAccounts: widget.onNavigateToAccounts,
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
                              onTap: () => _submitQuery(_recentSearches[index]),
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
                  ..._mostSearched.map(
                    (item) => _MostSearchedRow(
                      item: item,
                      onTap: () => _submitQuery(item.symbol),
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
                  ...List.generate(
                    _trendingTopics.length,
                    (index) => _TrendingHeadlineRow(
                      rank: index + 1,
                      title: _trendingTopics[index],
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
    required this.onNavigateToAccounts,
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
  final VoidCallback onNavigateToAccounts;

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
    final localResults = _searchDummyStocks(query);
    if (localResults.isNotEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _results = localResults;
        _isLoading = false;
      });
      return;
    }

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
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _results = const [];
        _isLoading = false;
        _errorMessage = null;
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
          onNavigateToAccounts: widget.onNavigateToAccounts,
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

class _SearchHeaderBar extends StatelessWidget {
  const _SearchHeaderBar({
    required this.fieldKey,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.onSubmitted,
    required this.onBack,
    this.autofocus = false,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onBack;
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
