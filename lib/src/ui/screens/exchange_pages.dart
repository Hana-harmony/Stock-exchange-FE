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
    return DefaultTabController(
      length: 4,
      child: AppScaffold(
        bodySafeAreaBottom: false,
        extendBody: true,
        body: AnimatedBuilder(
          animation: Listenable.merge([
            widget.marketDetailController,
            widget.tradeController,
          ]),
          builder: (context, _) {
            final snapshot = _StockDetailSnapshot.fromControllers(
              stockCode: widget.stockCode,
              fallbackTitle: widget.title,
              fallbackMarket: widget.market,
              fallbackSector: widget.sector,
              detailState: widget.marketDetailController.value,
              tradeState: widget.tradeController.value,
            );

            return SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _StockDetailHeader(
                    isFavorite: _isFavorite,
                    onBack: () => Navigator.of(context).pop(),
                    onSearch: _openSearch,
                    onFavorite: _toggleFavorite,
                  ),
                  _StockOverviewSection(snapshot: snapshot),
                  const _StockDetailTabs(),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _StockOrderTab(snapshot: snapshot),
                        const _EmptyTabView(label: 'Chart'),
                        const _EmptyTabView(label: 'Fundamentals'),
                        const _EmptyTabView(label: 'K-News'),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: _StockBottomActionBar(
          onSell: () => _showTradePlaceholder('Sell'),
          onBuy: () => _showTradePlaceholder('Buy'),
        ),
      ),
    );
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SearchLandingScreen(
          sessionController: widget.sessionController,
          tradeController: widget.tradeController,
          marketDetailController: widget.marketDetailController,
          marketQuoteController: widget.marketQuoteController,
          recentSearches: const [],
          favoriteStockCodes: _isFavorite ? {widget.stockCode} : const {},
          onSearchCommitted: (_) {},
          onRemoveRecentSearch: (_) {},
          onClearRecentSearches: () {},
          onToggleFavoriteStock: (_) {},
        ),
      ),
    );
  }

  void _showTradePlaceholder(String side) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$side order flow is not included in this page scope.'),
      ),
    );
  }
}

class _StockDetailHeader extends StatelessWidget {
  const _StockDetailHeader({
    required this.isFavorite,
    required this.onBack,
    required this.onSearch,
    required this.onFavorite,
  });

  final bool isFavorite;
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        child: Row(
          children: [
            _HeaderIconButton(
              assetPath: AppAssets.backArrow,
              onTap: onBack,
            ),
            const Spacer(),
            _HeaderIconButton(
              assetPath: AppAssets.headerSearch,
              onTap: onSearch,
            ),
            const SizedBox(width: 4),
            _FavoriteButton(
              isFavorite: isFavorite,
              inactiveAssetPath: AppAssets.headerFavoriteIcon,
              onTap: onFavorite,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.assetPath,
    required this.onTap,
  });

  final String assetPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      icon: Image.asset(
        assetPath,
        width: 24,
        height: 24,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _StockOverviewSection extends StatelessWidget {
  const _StockOverviewSection({
    required this.snapshot,
  });

  final _StockDetailSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final priceColor =
        snapshot.isPositive ? AppColors.green500 : AppColors.red500;

    return SizedBox(
      height: 198,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          children: [
            SizedBox(
              height: 74,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 21,
                    child: Row(
                      children: [
                        _MarketBadge(assetPath: snapshot.countryBadgeAsset),
                        if (snapshot.showKoreaFlag) ...[
                          const SizedBox(width: 6),
                          Image.asset(
                            AppAssets.koreaFlagIcon,
                            width: 28,
                            height: 21,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 45,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 25,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: snapshot.stockCode,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontSize: 18,
                                        height: 1,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const WidgetSpan(
                                  child: SizedBox(width: 6),
                                ),
                                TextSpan(
                                  text: snapshot.stockName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontSize: 18,
                                        height: 1,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(
                          height: 20,
                          child: Text(
                            snapshot.marketStatusLabel,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontSize: 14,
                                  height: 1.2,
                                  color: AppColors.gray600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 74,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 53,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: Text(
                                  snapshot.currentPrice,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge
                                      ?.copyWith(
                                        fontSize: 44,
                                        height: 1,
                                        fontWeight: FontWeight.w500,
                                        color: priceColor,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Padding(
                                padding: const EdgeInsets.only(top: 9.5),
                                child: Image.asset(
                                  snapshot.isPositive
                                      ? AppAssets.arrowUpBig
                                      : AppAssets.arrowDownBig,
                                  width: 30,
                                  height: 30,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: snapshot.changeAmount,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w400,
                                        color: priceColor,
                                      ),
                                ),
                                TextSpan(
                                  text: ' ${snapshot.changeRate}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w400,
                                        color: priceColor,
                                      ),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: SizedBox(
                      width: 118,
                      height: 68,
                      child: Column(
                        children: [
                          _StockStatRow(
                              label: 'High', value: snapshot.highPrice),
                          _StockStatRow(label: 'Low', value: snapshot.lowPrice),
                          _StockStatRow(label: 'Vol', value: snapshot.volume),
                          _StockStatRow(
                            label: 'Prev',
                            value: snapshot.previousClose,
                          ),
                        ],
                      ),
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

class _StockStatRow extends StatelessWidget {
  const _StockStatRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 17,
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: AppColors.gray600,
                ),
          ),
          const Spacer(),
          Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: AppColors.gray1000,
                ),
          ),
        ],
      ),
    );
  }
}

class _StockDetailTabs extends StatelessWidget {
  const _StockDetailTabs();

  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);

    return SizedBox(
      height: 51,
      child: Column(
        children: [
          Container(
            height: 6,
            color: AppColors.gray200.withValues(alpha: 0.7),
          ),
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return SizedBox(
                height: 45,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12, top: 10),
                    child: SizedBox(
                      width: 330,
                      child: Row(
                        children: [
                          _StockDetailTabButton(
                            label: 'Order',
                            width: 48,
                            isSelected: controller.index == 0,
                            onTap: () => controller.animateTo(0),
                          ),
                          const SizedBox(width: 18),
                          _StockDetailTabButton(
                            label: 'Chart',
                            width: 47,
                            isSelected: controller.index == 1,
                            onTap: () => controller.animateTo(1),
                          ),
                          const SizedBox(width: 18),
                          _StockDetailTabButton(
                            label: 'Fundamentals',
                            width: 116,
                            isSelected: controller.index == 2,
                            onTap: () => controller.animateTo(2),
                          ),
                          const SizedBox(width: 18),
                          _StockDetailTabButton(
                            label: 'K-News',
                            width: 65,
                            isSelected: controller.index == 3,
                            onTap: () => controller.animateTo(3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StockDetailTabButton extends StatelessWidget {
  const _StockDetailTabButton({
    required this.label,
    required this.width,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final double width;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: 31,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 17,
                      height: 1,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color:
                          isSelected ? AppColors.gray1000 : AppColors.gray600,
                    ),
              ),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                width: isSelected ? width : 0,
                height: 2,
                color: AppColors.orange500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockOrderTab extends StatelessWidget {
  const _StockOrderTab({
    required this.snapshot,
  });

  final _StockDetailSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 140),
      children: [
        _ForeignOwnershipAlertCard(snapshot: snapshot),
        const SizedBox(height: 24),
        _InvestmentInfoSection(snapshot: snapshot),
        const SizedBox(height: 24),
        Container(
          height: 1,
          color: AppColors.gray200,
        ),
        const SizedBox(height: 24),
        _InvestmentInfoSection(snapshot: snapshot),
      ],
    );
  }
}

class _InvestmentInfoSection extends StatelessWidget {
  const _InvestmentInfoSection({
    required this.snapshot,
  });

  final _StockDetailSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final mutedStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: AppColors.gray600,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Cash Balance', style: mutedStyle),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                snapshot.accountDisplay,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: mutedStyle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _StockInfoRow(label: 'Average Price', value: snapshot.averagePrice),
        const SizedBox(height: 16),
        _StockInfoRow(
          label: 'Return',
          value: snapshot.returnRate,
          valueColor: AppColors.red500,
        ),
        const SizedBox(height: 16),
        _StockInfoRow(label: 'Shares', value: snapshot.sharesDisplay),
        const SizedBox(height: 16),
        _StockInfoRow(
          label: 'Market Value',
          value: snapshot.marketValue,
          trailing: snapshot.marketValueChange,
          trailingColor: AppColors.red500,
        ),
        const SizedBox(height: 16),
        _StockInfoRow(label: 'Cost', value: snapshot.costDisplay),
      ],
    );
  }
}

class _ForeignOwnershipAlertCard extends StatelessWidget {
  const _ForeignOwnershipAlertCard({
    required this.snapshot,
  });

  final _StockDetailSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Foreign Ownership Limit Alert',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: AppColors.gray500,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Based on a time-series regression analysis\nwith a 95% confidence interval',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.gray600,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimated',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.red500,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      snapshot.estimatedRange,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.red500,
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: snapshot.alertProgress,
                        minHeight: 12,
                        backgroundColor: AppColors.gray300,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.red500),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _AlertMetric(
                            label: 'Previous Day',
                            value: snapshot.previousDayForeignRatio,
                            alignEnd: false,
                          ),
                        ),
                        Expanded(
                          child: _AlertMetric(
                            label: 'Limit',
                            value: snapshot.limitForeignRatio,
                            alignEnd: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'The estimated maximum foreign ownership ratio '
                      '(${snapshot.estimatedRangeMax}) is close to the limit '
                      '(${snapshot.limitForeignRatio}). Trading may be restricted once '
                      'the limit is reached.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.gray700,
                            height: 1.45,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertMetric extends StatelessWidget {
  const _AlertMetric({
    required this.label,
    required this.value,
    required this.alignEnd,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.gray600,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

class _StockInfoRow extends StatelessWidget {
  const _StockInfoRow({
    required this.label,
    required this.value,
    this.valueColor = AppColors.gray1000,
    this.trailing,
    this.trailingColor,
  });

  final String label;
  final String value;
  final Color valueColor;
  final String? trailing;
  final Color? trailingColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray1000,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        color: valueColor,
                      ),
                ),
                if (trailing != null)
                  TextSpan(
                    text: ' $trailing',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: trailingColor ?? valueColor,
                        ),
                  ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _StockBottomActionBar extends StatelessWidget {
  const _StockBottomActionBar({
    required this.onSell,
    required this.onBuy,
  });

  final VoidCallback onSell;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 119,
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.white.withValues(alpha: 0),
                  AppColors.white,
                ],
                stops: const [0, 0.2],
              ),
            ),
            child: SizedBox(
              height: 85,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _TradeActionButton(
                        label: 'Sell',
                        backgroundColor: AppColors.red500,
                        onTap: onSell,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TradeActionButton(
                        label: 'Buy',
                        backgroundColor: AppColors.green500,
                        onTap: onBuy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            height: 34,
            color: AppColors.white,
            child: Center(
              child: Image.asset(
                AppAssets.bottomHomeBar,
                width: 402,
                height: 34,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TradeActionButton extends StatelessWidget {
  const _TradeActionButton({
    required this.label,
    required this.backgroundColor,
    required this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: AppColors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.white,
                fontSize: 19,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class _StockDetailSnapshot {
  const _StockDetailSnapshot({
    required this.stockCode,
    required this.stockName,
    required this.marketStatusLabel,
    required this.currentPrice,
    required this.changeAmount,
    required this.changeRate,
    required this.isPositive,
    required this.highPrice,
    required this.lowPrice,
    required this.volume,
    required this.previousClose,
    required this.countryBadgeAsset,
    required this.showKoreaFlag,
    required this.estimatedRange,
    required this.estimatedRangeMax,
    required this.previousDayForeignRatio,
    required this.limitForeignRatio,
    required this.alertProgress,
    required this.accountDisplay,
    required this.averagePrice,
    required this.returnRate,
    required this.sharesDisplay,
    required this.marketValue,
    required this.marketValueChange,
    required this.costDisplay,
  });

  final String stockCode;
  final String stockName;
  final String marketStatusLabel;
  final String currentPrice;
  final String changeAmount;
  final String changeRate;
  final bool isPositive;
  final String highPrice;
  final String lowPrice;
  final String volume;
  final String previousClose;
  final String countryBadgeAsset;
  final bool showKoreaFlag;
  final String estimatedRange;
  final String estimatedRangeMax;
  final String previousDayForeignRatio;
  final String limitForeignRatio;
  final double alertProgress;
  final String accountDisplay;
  final String averagePrice;
  final String returnRate;
  final String sharesDisplay;
  final String marketValue;
  final String marketValueChange;
  final String costDisplay;

  factory _StockDetailSnapshot.fromControllers({
    required String stockCode,
    required String fallbackTitle,
    required String fallbackMarket,
    required String fallbackSector,
    required MarketDetailState detailState,
    required TradeState tradeState,
  }) {
    final detail =
        detailState.detail?.stockCode == stockCode ? detailState.detail : null;
    final chart = detail != null ? detailState.chart : null;
    final market = detail?.market ?? fallbackMarket;
    final fallback = _StockDetailFallback.forStock(
      stockCode: stockCode,
      stockName: fallbackTitle,
      market: market,
      sector: fallbackSector,
    );
    final chartPoint = chart?.latestPoint;
    final currentPrice = detail?.currentPriceKrw ?? fallback.currentPrice;
    final previousClose = chartPoint?.openPriceKrw ?? fallback.previousClose;
    final changeRate = detail?.changeRate ?? fallback.changeRate;
    final changeAmount = detail != null && chartPoint != null
        ? _formatSignedDifference(currentPrice, previousClose)
        : fallback.changeAmount;
    final maxLimitRate = _parsePercent(
      '${detail?.predictedForeignLimitExhaustionRateMax ?? fallback.estimatedMax}%',
    );
    final limitValue = _parsePercent(fallback.limitForeignRatio);
    final portfolio = tradeState.portfolio;
    MockHolding? holding;
    if (portfolio != null) {
      for (final item in portfolio.holdings) {
        if (item.stockCode == stockCode) {
          holding = item;
          break;
        }
      }
    }

    return _StockDetailSnapshot(
      stockCode: stockCode,
      stockName: detail?.stockName ?? fallback.stockName,
      marketStatusLabel:
          _formatMarketStatus(detail?.marketDataTime) ?? fallback.marketStatus,
      currentPrice: currentPrice,
      changeAmount: changeAmount == '+0' ? fallback.changeAmount : changeAmount,
      changeRate: changeRate,
      isPositive: !changeRate.trim().startsWith('-'),
      highPrice: chartPoint?.highPriceKrw ?? fallback.highPrice,
      lowPrice: chartPoint?.lowPriceKrw ?? fallback.lowPrice,
      volume: chartPoint != null
          ? _formatCompactNumber(chartPoint.volume)
          : fallback.volume,
      previousClose: chartPoint?.closePriceKrw ?? fallback.previousClose,
      countryBadgeAsset: _isHongKongMarket(market)
          ? AppAssets.countryBadgeHk
          : AppAssets.countryBadgeKr,
      showKoreaFlag: !_isHongKongMarket(market),
      estimatedRange: _formatRange(
        detail?.predictedForeignLimitExhaustionRateMin,
        detail?.predictedForeignLimitExhaustionRateMax,
        fallback.estimatedRange,
      ),
      estimatedRangeMax:
          '${detail?.predictedForeignLimitExhaustionRateMax ?? fallback.estimatedMax}%',
      previousDayForeignRatio:
          '${detail?.foreignLimitExhaustionRate ?? fallback.previousDayRatio}%',
      limitForeignRatio: fallback.limitForeignRatio,
      alertProgress:
          limitValue == 0 ? 0 : (maxLimitRate / limitValue).clamp(0, 1),
      accountDisplay: portfolio != null && portfolio.accountId.isNotEmpty
          ? 'Account ${portfolio.accountId}'
          : fallback.accountDisplay,
      averagePrice: holding?.averagePriceUsd ?? fallback.averagePrice,
      returnRate: holding?.unrealizedPnlRate ?? fallback.returnRate,
      sharesDisplay: holding != null
          ? '${holding.quantity} Shares'
          : fallback.sharesDisplay,
      marketValue: holding?.marketValueUsd ?? fallback.marketValue,
      marketValueChange: holding != null
          ? '(${holding.unrealizedPnlUsd})'
          : fallback.marketValueChange,
      costDisplay: fallback.costDisplay,
    );
  }
}

class _StockDetailFallback {
  const _StockDetailFallback({
    required this.stockName,
    required this.marketStatus,
    required this.currentPrice,
    required this.changeAmount,
    required this.changeRate,
    required this.highPrice,
    required this.lowPrice,
    required this.volume,
    required this.previousClose,
    required this.estimatedRange,
    required this.estimatedMax,
    required this.previousDayRatio,
    required this.limitForeignRatio,
    required this.accountDisplay,
    required this.averagePrice,
    required this.returnRate,
    required this.sharesDisplay,
    required this.marketValue,
    required this.marketValueChange,
    required this.costDisplay,
  });

  final String stockName;
  final String marketStatus;
  final String currentPrice;
  final String changeAmount;
  final String changeRate;
  final String highPrice;
  final String lowPrice;
  final String volume;
  final String previousClose;
  final String estimatedRange;
  final String estimatedMax;
  final String previousDayRatio;
  final String limitForeignRatio;
  final String accountDisplay;
  final String averagePrice;
  final String returnRate;
  final String sharesDisplay;
  final String marketValue;
  final String marketValueChange;
  final String costDisplay;

  factory _StockDetailFallback.forStock({
    required String stockCode,
    required String stockName,
    required String market,
    required String sector,
  }) {
    if (stockCode == '005930') {
      return const _StockDetailFallback(
        stockName: 'Samsung Electronics',
        marketStatus: 'Market Closed Jun 5 15:30:00',
        currentPrice: '568000',
        changeAmount: '+39000',
        changeRate: '+6.43%',
        highPrice: '76,000',
        lowPrice: '76,000',
        volume: '76,000',
        previousClose: '76,000',
        estimatedRange: '38.78%~38.82%',
        estimatedMax: '38.82',
        previousDayRatio: '38.50',
        limitForeignRatio: '40.00%',
        accountDisplay: 'Account 010-2663-9046-0',
        averagePrice: '14,085',
        returnRate: '-16.15%',
        sharesDisplay: '80 Shares',
        marketValue: '52,425',
        marketValueChange: '(-20,000)',
        costDisplay: '2,201,740',
      );
    }

    final seed = stockCode.codeUnits.fold<int>(0, (sum, value) => sum + value);
    final price = 12000 + seed * 37;
    final prev = price - 240;
    final estimatedMin = 37 + (seed % 10) / 10;
    final estimatedMax = estimatedMin + 0.04;
    return _StockDetailFallback(
      stockName: stockName,
      marketStatus: 'Market Closed Jun 5 15:30:00',
      currentPrice: '$price',
      changeAmount: _formatSignedNumber(price - prev),
      changeRate: seed.isEven ? '+2.13%' : '-1.42%',
      highPrice: '$price',
      lowPrice: '$prev',
      volume: _formatCompactNumber(76000 + seed * 3),
      previousClose: '$prev',
      estimatedRange:
          '${estimatedMin.toStringAsFixed(2)}%~${estimatedMax.toStringAsFixed(2)}%',
      estimatedMax: estimatedMax.toStringAsFixed(2),
      previousDayRatio: estimatedMin.toStringAsFixed(2),
      limitForeignRatio: '40.00%',
      accountDisplay: 'Account 010-2663-9046-0',
      averagePrice: '${price - 550}',
      returnRate: seed.isEven ? '-3.18%' : '-1.42%',
      sharesDisplay: '${(seed % 90) + 10} Shares',
      marketValue: '${price * 3}',
      marketValueChange: '(-${(seed % 20) + 1},000)',
      costDisplay: '${price * 4}',
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
    required this.query,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onTap,
  });

  final StockSearchItem item;
  final String query;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final countryBadgeAsset = _isHongKongMarket(item.market)
        ? AppAssets.countryBadgeHk
        : AppAssets.countryBadgeKr;

    return SizedBox(
      height: 65,
      child: InkWell(
        key: ValueKey('stock-search-result-${item.stockCode}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              _MarketBadge(assetPath: countryBadgeAsset),
              const SizedBox(width: 8),
              const _SearchResultAvatar(),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.stockCode,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 1),
                    Text.rich(
                      TextSpan(
                        children: _buildDescriptionSpans(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
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
    );
  }

  List<TextSpan> _buildDescriptionSpans(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.gray600,
          fontWeight: FontWeight.w400,
        );
    final highlightStyle = baseStyle?.copyWith(
      color: AppColors.orange500,
      fontWeight: FontWeight.w500,
    );
    final source = item.stockName;
    final normalizedQuery = query.trim();

    if (normalizedQuery.isEmpty) {
      return [TextSpan(text: source, style: baseStyle)];
    }

    final lowerSource = source.toLowerCase();
    final lowerQuery = normalizedQuery.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;

    while (true) {
      final matchIndex = lowerSource.indexOf(lowerQuery, start);
      if (matchIndex == -1) {
        break;
      }
      if (matchIndex > start) {
        spans.add(
          TextSpan(
            text: source.substring(start, matchIndex),
            style: baseStyle,
          ),
        );
      }
      spans.add(
        TextSpan(
          text:
              source.substring(matchIndex, matchIndex + normalizedQuery.length),
          style: highlightStyle,
        ),
      );
      start = matchIndex + normalizedQuery.length;
    }

    if (spans.isEmpty) {
      return [TextSpan(text: source, style: baseStyle)];
    }

    if (start < source.length) {
      spans.add(
        TextSpan(
          text: source.substring(start),
          style: baseStyle,
        ),
      );
    }

    return spans;
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({
    required this.isFavorite,
    required this.onTap,
    this.inactiveAssetPath = AppAssets.favoriteIcon,
  });

  final bool isFavorite;
  final VoidCallback onTap;
  final String inactiveAssetPath;

  @override
  Widget build(BuildContext context) {
    return _AnimatedFavoriteIconButton(
      isFavorite: isFavorite,
      activeAssetPath: AppAssets.favoriteIconActive,
      inactiveAssetPath: inactiveAssetPath,
      onTap: onTap,
    );
  }
}

class _AnimatedFavoriteIconButton extends StatefulWidget {
  const _AnimatedFavoriteIconButton({
    required this.isFavorite,
    required this.activeAssetPath,
    required this.inactiveAssetPath,
    required this.onTap,
  });

  final bool isFavorite;
  final String activeAssetPath;
  final String inactiveAssetPath;
  final VoidCallback onTap;

  @override
  State<_AnimatedFavoriteIconButton> createState() =>
      _AnimatedFavoriteIconButtonState();
}

class _AnimatedFavoriteIconButtonState
    extends State<_AnimatedFavoriteIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 1.16,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.16,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 55,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant _AnimatedFavoriteIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
      _controller
        ..stop()
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assetPath =
        widget.isFavorite ? widget.activeAssetPath : widget.inactiveAssetPath;
    final iconSize = widget.isFavorite ? 24.0 : 22.0;

    return IconButton(
      onPressed: widget.onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(
        width: 36,
        height: 36,
      ),
      icon: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1).animate(animation),
                child: child,
              ),
            );
          },
          child: Image.asset(
            assetPath,
            key: ValueKey<String>(assetPath),
            width: iconSize,
            height: iconSize,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _SearchResultAvatar extends StatelessWidget {
  const _SearchResultAvatar();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size.square(34),
      painter: _SearchResultAvatarPainter(),
    );
  }
}

class _SearchResultAvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final circleRect = Offset.zero & size;
    final clipPath = Path()..addOval(circleRect);
    canvas.save();
    canvas.clipPath(clipPath);

    final backgroundPaint = Paint()
      ..color = AppColors.gray200.withValues(alpha: 0.45);
    canvas.drawOval(circleRect, backgroundPaint);

    final dotPaint = Paint()..color = AppColors.gray300.withValues(alpha: 0.9);
    const spacing = 4.0;
    const radius = 0.9;
    for (var x = 1.5; x < size.width; x += spacing) {
      for (var y = 1.5; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, dotPaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
  });

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: 28,
      height: 21,
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

const _dummyStockSearchEntries = <_DummyStockSearchEntry>[
  _DummyStockSearchEntry(
    stockCode: '005930',
    stockName: 'Samsung Electronics',
    market: 'KOSPI',
    sector: 'Semiconductor',
    aliases: ['삼성전자', 'samsung', 'samsung electronics', '005930'],
  ),
  _DummyStockSearchEntry(
    stockCode: '07747',
    stockName: 'CSOP Samsung Electronics Daily (2x) Leveraged Product',
    market: 'HKEX',
    sector: 'ETF',
    aliases: [
      'csop samsung electronics',
      'samsung',
      'hong kong',
      'hk',
      '07747',
    ],
  ),
  _DummyStockSearchEntry(
    stockCode: '207940',
    stockName: 'Samsung Biologics',
    market: 'KOSPI',
    sector: 'Biotech',
    aliases: ['삼성바이오로직스', 'samsung biologics', 'samsung', '207940'],
  ),
  _DummyStockSearchEntry(
    stockCode: '006400',
    stockName: 'Samsung SDI',
    market: 'KOSPI',
    sector: 'Battery',
    aliases: ['삼성sdi', 'samsung sdi', 'samsung', '006400'],
  ),
  _DummyStockSearchEntry(
    stockCode: '028260',
    stockName: 'Samsung C&T',
    market: 'KOSPI',
    sector: 'Industrial',
    aliases: ['삼성물산', 'samsung c&t', 'samsung', '028260'],
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

String? _formatMarketStatus(DateTime? marketDataTime) {
  if (marketDataTime == null) {
    return null;
  }

  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = marketDataTime.toUtc().add(const Duration(hours: 9));
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  final second = local.second.toString().padLeft(2, '0');
  return 'Market Closed ${months[local.month - 1]} ${local.day} '
      '$hour:$minute:$second';
}

String _formatSignedDifference(String current, String previous) {
  final currentValue = int.tryParse(current.replaceAll(',', ''));
  final previousValue = int.tryParse(previous.replaceAll(',', ''));
  if (currentValue == null || previousValue == null) {
    return '+0';
  }
  return _formatSignedNumber(currentValue - previousValue);
}

String _formatSignedNumber(int value) {
  if (value == 0) {
    return '+0';
  }
  return '${value > 0 ? '+' : '-'}${value.abs()}';
}

String _formatRange(String? min, String? max, String fallback) {
  if (min == null || max == null || min.isEmpty || max.isEmpty) {
    return fallback;
  }
  return '$min%~$max%';
}

double _parsePercent(String value) {
  return double.tryParse(value.replaceAll('%', '').trim()) ?? 0;
}

String _formatCompactNumber(int value) {
  return _formatNumber(value);
}
