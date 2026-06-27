import 'package:flutter/material.dart';

import '../../core/exchange_session_controller.dart';
import '../../core/market_detail_controller.dart';
import '../../core/market_quote_controller.dart';
import '../../core/trade_controller.dart';
import '../assets/app_assets.dart';
import '../components/app_scaffold.dart';
import '../components/app_search_field.dart';
import '../theme/app_tokens.dart';

String marketQuoteLiveStatusLabel(
  MarketQuoteLiveStatus liveStatus,
  MarketQuote? quote, {
  DateTime? nowUtc,
}) {
  final now = (nowUtc ?? DateTime.now()).toUtc().add(const Duration(hours: 9));
  final minutes = now.hour * 60 + now.minute;
  final isWeekday =
      now.weekday >= DateTime.monday && now.weekday <= DateTime.friday;
  final isRegularHours = isWeekday && minutes >= 540 && minutes < 930;
  if (!isRegularHours) {
    return 'Closed';
  }
  switch (liveStatus) {
    case MarketQuoteLiveStatus.connecting:
      return 'Connecting';
    case MarketQuoteLiveStatus.live:
      return quote == null ? 'Live' : 'Live ${quote.market}';
    case MarketQuoteLiveStatus.failure:
      return 'Reconnect';
    case MarketQuoteLiveStatus.disconnected:
      return 'Paused';
  }
}

class MarketScreen extends StatefulWidget {
  const MarketScreen({
    super.key,
    required this.sessionController,
    required this.tradeController,
    required this.marketDetailController,
    required this.marketIndexController,
    required this.marketQuoteController,
  });

  final ExchangeSessionController sessionController;
  final TradeController tradeController;
  final MarketDetailController marketDetailController;
  final Object marketIndexController;
  final MarketQuoteController marketQuoteController;

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  static const _marketCategories = <String>[
    'Stocks',
    'Cryto',
    'Options',
    'ETFs',
    'Overview',
  ];

  int _selectedCategoryIndex = 0;

  static const _heroCards = <String>[
    AppAssets.stockCardRed,
    AppAssets.stockCardGreen,
    AppAssets.stockCardRed,
  ];

  static const _trendingStocks = <_TrendingStock>[
    _TrendingStock(
      symbol: 'NVDA',
      name: 'NVIDIA',
      market: 'NASDAQ',
      priceDisplay: '205.190',
      changeDisplay: '+37.25%',
      isPositive: true,
    ),
    _TrendingStock(
      symbol: 'NVDA',
      name: 'NVIDIA',
      market: 'NASDAQ',
      priceDisplay: '205.190',
      changeDisplay: '-37.25%',
      isPositive: false,
    ),
    _TrendingStock(
      symbol: 'NVDA',
      name: 'NVIDIA',
      market: 'NASDAQ',
      priceDisplay: '205.190',
      changeDisplay: '-37.25%',
      isPositive: false,
    ),
    _TrendingStock(
      symbol: 'NVDA',
      name: 'NVIDIA',
      market: 'NASDAQ',
      priceDisplay: '205.190',
      changeDisplay: '+37.25%',
      isPositive: true,
    ),
    _TrendingStock(
      symbol: 'NVDA',
      name: 'NVIDIA',
      market: 'NASDAQ',
      priceDisplay: '205.190',
      changeDisplay: '+37.25%',
      isPositive: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
      children: [
        SizedBox(
          height: 42,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final isSelected = index == _selectedCategoryIndex;
              return _MarketCategoryTab(
                label: _marketCategories[index],
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedCategoryIndex = index;
                  });
                },
              );
            },
            separatorBuilder: (context, index) => const SizedBox(width: 24),
            itemCount: _marketCategories.length,
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            children: [
              SizedBox(
                height: 134,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.large),
                      child: Image.asset(
                        _heroCards[index],
                        width: 120,
                        height: 134,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemCount: _heroCards.length,
                ),
              ),
              const SizedBox(height: 20),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.gray1000,
                  borderRadius: BorderRadius.circular(AppRadii.large),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.large),
                  child: SizedBox(
                    height: 77,
                    width: double.infinity,
                    child: ClipRect(
                      child: FittedBox(
                        fit: BoxFit.fitHeight,
                        alignment: Alignment.centerLeft,
                        child: Image.asset(AppAssets.marketDataContainer),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Trending Stocks',
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontSize: 28,
                                height: 1.1,
                              ),
                    ),
                  ),
                  Image.asset(
                    AppAssets.rightArrow,
                    width: 18,
                    height: 18,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              for (var index = 0; index < _trendingStocks.length; index++)
                _TrendingStockTile(
                  stock: _trendingStocks[index],
                  rank: index + 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class SearchLandingScreen extends StatefulWidget {
  const SearchLandingScreen({
    super.key,
    required this.sessionController,
    required this.tradeController,
    required this.marketDetailController,
    required this.marketQuoteController,
    required this.recentSearches,
    required this.favoriteStockCodes,
    required this.onSearchCommitted,
    required this.onRemoveRecentSearch,
    required this.onClearRecentSearches,
    required this.onToggleFavoriteStock,
  });

  final ExchangeSessionController sessionController;
  final TradeController tradeController;
  final MarketDetailController marketDetailController;
  final MarketQuoteController marketQuoteController;
  final List<String> recentSearches;
  final Set<String> favoriteStockCodes;
  final ValueChanged<String> onSearchCommitted;
  final ValueChanged<String> onRemoveRecentSearch;
  final VoidCallback onClearRecentSearches;
  final ValueChanged<String> onToggleFavoriteStock;

  @override
  State<SearchLandingScreen> createState() => _SearchLandingScreenState();
}

class _SearchLandingScreenState extends State<SearchLandingScreen> {
  static const _mostSearched = <_MarketSearchPreview>[
    _MarketSearchPreview(
      symbol: 'NVDA',
      name: 'NVIDIA',
      priceDisplay: '864.010',
      changeDisplay: '+37.25%',
      secondaryPriceDisplay: '857.990',
      secondaryChangeDisplay: '-0.70%',
      isPositive: true,
    ),
    _MarketSearchPreview(
      symbol: 'NVDA',
      name: 'NVIDIA',
      priceDisplay: '263.470',
      changeDisplay: '-16.74%',
      secondaryPriceDisplay: '272.780',
      secondaryChangeDisplay: '+3.53%',
      isPositive: false,
    ),
    _MarketSearchPreview(
      symbol: 'NVDA',
      name: 'NVIDIA',
      priceDisplay: '864.010',
      changeDisplay: '+37.25%',
      secondaryPriceDisplay: '857.990',
      secondaryChangeDisplay: '-0.70%',
      isPositive: true,
    ),
    _MarketSearchPreview(
      symbol: 'NVDA',
      name: 'NVIDIA',
      priceDisplay: '864.010',
      changeDisplay: '+37.25%',
      secondaryPriceDisplay: '857.990',
      secondaryChangeDisplay: '-0.70%',
      isPositive: true,
    ),
    _MarketSearchPreview(
      symbol: 'NVDA',
      name: 'NVIDIA',
      priceDisplay: '864.010',
      changeDisplay: '+37.25%',
      secondaryPriceDisplay: '857.990',
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
          favoriteStockCodes: widget.favoriteStockCodes,
          onSearchCommitted: widget.onSearchCommitted,
          onToggleFavoriteStock: widget.onToggleFavoriteStock,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 24,
                      height: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppSearchField(
                      fieldKey: const ValueKey('market-search-input'),
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: true,
                      hintText: 'Search Everthing',
                      onSubmitted: _submitQuery,
                      filledColor: AppColors.surface,
                      showBorder: false,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
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
    required this.favoriteStockCodes,
    required this.onSearchCommitted,
    required this.onToggleFavoriteStock,
  });

  final String initialQuery;
  final ExchangeSessionController sessionController;
  final TradeController tradeController;
  final MarketDetailController marketDetailController;
  final MarketQuoteController marketQuoteController;
  final Set<String> favoriteStockCodes;
  final ValueChanged<String> onSearchCommitted;
  final ValueChanged<String> onToggleFavoriteStock;

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
          stockCode: item.stockCode,
          title: item.stockName,
          market: item.market,
          sector: item.sector,
          isFavorite: _favoriteStockCodes.contains(item.stockCode),
          onFavoriteToggle: () => _toggleFavorite(item.stockCode),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: AppSearchField(
                      fieldKey: const ValueKey('market-search-results-input'),
                      controller: _controller,
                      focusNode: _focusNode,
                      hintText: 'Search market, stock, or ticker',
                      onSubmitted: _submitQuery,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppSearchFieldAction(
                    label: 'Cancel',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  Row(
                    children: [
                      Image.asset(
                        AppAssets.koreaFlagIcon,
                        width: 28,
                        height: 21,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_query results',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: const [
                      _MarketBadge(assetPath: AppAssets.countryBadgeKr),
                      _MarketBadge(assetPath: AppAssets.countryBadgeHk),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                        meta: _SyntheticStockMeta.fromItem(item),
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

class StockDetailScreen extends StatefulWidget {
  const StockDetailScreen({
    super.key,
    required this.sessionController,
    required this.marketDetailController,
    required this.marketQuoteController,
    required this.tradeController,
    required this.stockCode,
    required this.title,
    this.market = 'KOSPI',
    this.sector = '',
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  final ExchangeSessionController sessionController;
  final MarketDetailController marketDetailController;
  final MarketQuoteController marketQuoteController;
  final TradeController tradeController;
  final String stockCode;
  final String title;
  final String market;
  final String sector;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    widget.onFavoriteToggle?.call();
  }

  @override
  Widget build(BuildContext context) {
    final meta = _SyntheticStockMeta.fromParts(
      stockCode: widget.stockCode,
      market: widget.market,
    );

    return DefaultTabController(
      length: 4,
      child: AppScaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    _FavoriteButton(
                      isFavorite: _isFavorite,
                      onTap: _toggleFavorite,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadii.large),
                    border: Border.all(color: AppColors.gray200),
                    boxShadow: AppShadows.card,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _MarketBadge(
                              assetPath: meta.countryBadgeAsset,
                              small: true,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.market,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            if (widget.sector.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                widget.sector,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.stockCode,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          meta.priceDisplay,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Image.asset(
                              meta.directionIconAsset,
                              width: 22,
                              height: 22,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              meta.changeDisplay,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: meta.changeColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.large),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadii.large),
                    border: Border.all(color: AppColors.gray200),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: AppColors.gray1000,
                  unselectedLabelColor: AppColors.gray600,
                  labelStyle: Theme.of(context).textTheme.labelLarge,
                  tabs: const [
                    Tab(text: 'Order'),
                    Tab(text: 'Chart'),
                    Tab(text: 'Fundamentals'),
                    Tab(text: 'K-News'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Expanded(
                child: TabBarView(
                  children: [
                    _EmptyTabView(label: 'Order'),
                    _EmptyTabView(label: 'Chart'),
                    _EmptyTabView(label: 'Fundamentals'),
                    _EmptyTabView(label: 'K-News'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShellPlaceholderScreen extends StatelessWidget {
  const ShellPlaceholderScreen({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppInsets.compactScreen,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        _MutedInfoCard(
          title: '$title tab',
          body: description,
        ),
      ],
    );
  }
}

class _TrendingStockTile extends StatelessWidget {
  const _TrendingStockTile({
    required this.stock,
    required this.rank,
  });

  final _TrendingStock stock;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final changeColor =
        stock.isPositive ? AppColors.green500 : AppColors.red500;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$rank',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.gray200),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stock.symbol,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  stock.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.gray600,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 108,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  stock.changeDisplay,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: changeColor,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  stock.priceDisplay,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketCategoryTab extends StatelessWidget {
  const _MarketCategoryTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontSize: 16,
          height: 1.1,
          fontWeight: FontWeight.w500,
          color: isSelected ? AppColors.gray1000 : AppColors.gray600,
        );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.orange500 : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(label, style: textStyle),
      ),
    );
  }
}

class _HistoryChip extends StatelessWidget {
  const _HistoryChip({
    required this.query,
    required this.onTap,
  });

  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            query,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ),
    );
  }
}

class _MostSearchedRow extends StatelessWidget {
  const _MostSearchedRow({
    required this.item,
    required this.onTap,
  });

  final _MarketSearchPreview item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        item.isPositive ? AppColors.green500 : AppColors.red500;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.medium),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gray200),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.symbol,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.gray600,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.priceDisplay,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      item.changeDisplay,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.secondaryPriceDisplay,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                    const SizedBox(width: 18),
                    Text(
                      item.secondaryChangeDisplay,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendingHeadlineRow extends StatelessWidget {
  const _TrendingHeadlineRow({
    required this.rank,
    required this.title,
  });

  final int rank;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 26,
            child: Text(
              '$rank',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.orange500,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.item,
    required this.meta,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onTap,
  });

  final StockSearchItem item;
  final _SyntheticStockMeta meta;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        key: ValueKey('stock-search-result-${item.stockCode}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.large),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadii.large),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _MarketBadge(assetPath: meta.countryBadgeAsset),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.stockName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.market} · ${item.stockCode} · ${item.sector}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      meta.priceDisplay,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          meta.directionIconAsset,
                          width: 16,
                          height: 16,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          meta.changeDisplay,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: meta.changeColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                _FavoriteButton(
                  isFavorite: isFavorite,
                  onTap: onFavoriteTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({
    required this.isFavorite,
    required this.onTap,
  });

  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: ColorFiltered(
        colorFilter: ColorFilter.mode(
          isFavorite ? AppColors.orange500 : AppColors.gray500,
          BlendMode.srcIn,
        ),
        child: Image.asset(
          AppAssets.favoriteIcon,
          width: 22,
          height: 22,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _MutedInfoCard extends StatelessWidget {
  const _MutedInfoCard({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.large),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorStateCard extends StatelessWidget {
  const _ErrorStateCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.large),
        border: Border.all(color: AppColors.red500),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search error',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTabView extends StatelessWidget {
  const _EmptyTabView({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _MutedInfoCard(
          title: '$label view',
          body:
              'This tab is intentionally left empty for now, matching the current page spec.',
        ),
      ),
    );
  }
}

class _MarketBadge extends StatelessWidget {
  const _MarketBadge({
    required this.assetPath,
    this.small = false,
  });

  final String assetPath;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: small ? 24 : 28,
      height: small ? 18 : 21,
      fit: BoxFit.contain,
    );
  }
}

class _TrendingStock {
  const _TrendingStock({
    required this.symbol,
    required this.name,
    required this.market,
    required this.priceDisplay,
    required this.changeDisplay,
    required this.isPositive,
  });

  final String symbol;
  final String name;
  final String market;
  final String priceDisplay;
  final String changeDisplay;
  final bool isPositive;
}

class _MarketSearchPreview {
  const _MarketSearchPreview({
    required this.symbol,
    required this.name,
    required this.priceDisplay,
    required this.changeDisplay,
    required this.secondaryPriceDisplay,
    required this.secondaryChangeDisplay,
    required this.isPositive,
  });

  final String symbol;
  final String name;
  final String priceDisplay;
  final String changeDisplay;
  final String secondaryPriceDisplay;
  final String secondaryChangeDisplay;
  final bool isPositive;
}

class _SyntheticStockMeta {
  const _SyntheticStockMeta({
    required this.priceDisplay,
    required this.changeDisplay,
    required this.changeColor,
    required this.directionIconAsset,
    required this.countryBadgeAsset,
  });

  final String priceDisplay;
  final String changeDisplay;
  final Color changeColor;
  final String directionIconAsset;
  final String countryBadgeAsset;

  factory _SyntheticStockMeta.fromItem(StockSearchItem item) {
    return _SyntheticStockMeta.fromParts(
      stockCode: item.stockCode,
      market: item.market,
    );
  }

  factory _SyntheticStockMeta.fromParts({
    required String stockCode,
    required String market,
  }) {
    final seed = stockCode.codeUnits.fold<int>(0, (sum, value) => sum + value);
    final isPositive = seed.isEven;
    final price = 18000 + (seed * 37) % 220000;
    final basisPoints = 45 + (seed % 210);
    final major = basisPoints ~/ 100;
    final minor = (basisPoints % 100).toString().padLeft(2, '0');
    return _SyntheticStockMeta(
      priceDisplay: 'KRW ${_formatNumber(price)}',
      changeDisplay: '${isPositive ? '+' : '-'}$major.$minor%',
      changeColor: isPositive ? AppColors.green500 : AppColors.red500,
      directionIconAsset:
          isPositive ? AppAssets.arrowUpBig : AppAssets.arrowDownBig,
      countryBadgeAsset: _isHongKongMarket(market)
          ? AppAssets.countryBadgeHk
          : AppAssets.countryBadgeKr,
    );
  }
}

const _dummyStockSearchEntries = <_DummyStockSearchEntry>[
  _DummyStockSearchEntry(
    stockCode: '005930',
    stockName: '삼성전자',
    market: 'KOSPI',
    sector: 'Semiconductor',
    aliases: ['삼성전자', 'samsung', 'samsung electronics', '005930'],
  ),
  _DummyStockSearchEntry(
    stockCode: '000660',
    stockName: 'SK hynix',
    market: 'KOSPI',
    sector: 'Semiconductor',
    aliases: ['sk hynix', '하이닉스', 'sk하이닉스', '000660'],
  ),
  _DummyStockSearchEntry(
    stockCode: '035420',
    stockName: 'NAVER',
    market: 'KOSPI',
    sector: 'Internet',
    aliases: ['naver', '네이버', '035420'],
  ),
  _DummyStockSearchEntry(
    stockCode: '035720',
    stockName: '카카오',
    market: 'KOSPI',
    sector: 'IT',
    aliases: ['카카오', 'kakao', '035720'],
  ),
  _DummyStockSearchEntry(
    stockCode: '323410',
    stockName: '카카오뱅크',
    market: 'KOSPI',
    sector: 'Bank',
    aliases: ['카카오뱅크', 'kakaobank', 'kakao bank', '323410'],
  ),
  _DummyStockSearchEntry(
    stockCode: '005380',
    stockName: '현대차',
    market: 'KOSPI',
    sector: 'Automotive',
    aliases: ['현대차', 'hyundai', 'hyundai motor', '005380'],
  ),
  _DummyStockSearchEntry(
    stockCode: 'NVDA',
    stockName: 'NVIDIA',
    market: 'NASDAQ',
    sector: 'Semiconductor',
    aliases: ['nvda', 'nvidia'],
  ),
];

class _DummyStockSearchEntry {
  const _DummyStockSearchEntry({
    required this.stockCode,
    required this.stockName,
    required this.market,
    required this.sector,
    required this.aliases,
  });

  final String stockCode;
  final String stockName;
  final String market;
  final String sector;
  final List<String> aliases;

  StockSearchItem toSearchItem() {
    return StockSearchItem(
      stockCode: stockCode,
      stockName: stockName,
      market: market,
      sector: sector,
      dataSource: 'Dummy',
    );
  }
}

List<StockSearchItem> _searchDummyStocks(String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) {
    return const [];
  }

  return _dummyStockSearchEntries
      .where((entry) {
        return entry.aliases.any(
              (alias) => alias.toLowerCase().contains(normalized),
            ) ||
            entry.stockName.toLowerCase().contains(normalized) ||
            entry.stockCode.toLowerCase().contains(normalized);
      })
      .map((entry) => entry.toSearchItem())
      .toList(growable: false);
}

bool _isHongKongMarket(String market) {
  final normalized = market.toUpperCase();
  return normalized.contains('HK') || normalized.contains('HANG');
}

String _formatNumber(int value) {
  final digits = '$value';
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    final remaining = digits.length - index;
    buffer.write(digits[index]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}
