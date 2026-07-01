part of '../exchange_pages.dart';

class StockDetailScreen extends StatefulWidget {
  const StockDetailScreen({
    super.key,
    required this.sessionController,
    required this.marketDetailController,
    required this.marketQuoteController,
    required this.tradeController,
    required this.notificationController,
    required this.stockCode,
    required this.title,
    this.market = 'KOSPI',
    this.sector = '',
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.onNavigateToAccounts,
  });

  final ExchangeSessionController sessionController;
  final MarketDetailController marketDetailController;
  final MarketQuoteController marketQuoteController;
  final TradeController tradeController;
  final NotificationController notificationController;
  final String stockCode;
  final String title;
  final String market;
  final String sector;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onNavigateToAccounts;

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  late bool _isFavorite;
  late final ScrollController _detailScrollController;
  bool _tabsPinned = false;
  bool _showViBanner = false;
  bool _isLowLimitTriggered = false;

  int get _activeAlertBannerCount {
    var count = 0;
    if (_showViBanner) {
      count += 1;
    }
    if (_isLowLimitTriggered) {
      count += 1;
    }
    return count;
  }

  double get _alertBannerBlockHeight => _activeAlertBannerCount == 0
      ? 0
      : (_AlertStatusBanner.height * _activeAlertBannerCount) +
          (12 * _activeAlertBannerCount) +
          8;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
    _detailScrollController = ScrollController()..addListener(_handleScroll);
  }

  @override
  void dispose() {
    _detailScrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    widget.onFavoriteToggle?.call();
  }

  void _handleScroll() {
    final nextPinned = _detailScrollController.offset >=
        _StockOverviewSection.height + _alertBannerBlockHeight;
    if (nextPinned == _tabsPinned) {
      return;
    }
    setState(() {
      _tabsPinned = nextPinned;
    });
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
            final snapshot = _buildSnapshot();

            return SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _StockDetailHeader(
                    snapshot: snapshot,
                    showCompactTitle: _tabsPinned,
                    isFavorite: _isFavorite,
                    onBack: () => Navigator.of(context).pop(),
                    onSearch: _openSearch,
                    onFavorite: _toggleFavorite,
                  ),
                  Expanded(
                    child: NestedScrollView(
                      controller: _detailScrollController,
                      headerSliverBuilder: (context, innerBoxIsScrolled) {
                        return [
                          if (_activeAlertBannerCount > 0)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  12,
                                ),
                                child: Column(
                                  children: [
                                    if (_showViBanner)
                                      _ViTriggeredBanner(
                                        onInfoTap: _showViInfoPanel,
                                      ),
                                    if (_showViBanner && _isLowLimitTriggered)
                                      const SizedBox(height: 12),
                                    if (_isLowLimitTriggered)
                                      _LowLimitReachedBanner(
                                        onInfoTap: _showLowLimitInfoPanel,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          SliverToBoxAdapter(
                            child: _StockOverviewSection(snapshot: snapshot),
                          ),
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _StockDetailTabsHeaderDelegate(),
                          ),
                        ];
                      },
                      body: TabBarView(
                        children: [
                          _StockOrderTab(snapshot: snapshot),
                          const _StockChartTab(),
                          _StockFundamentalsTab(
                            isViTriggered: _showViBanner,
                            isLowLimitTriggered: _isLowLimitTriggered,
                            onToggleVi: _toggleViBanner,
                            onToggleLowLimit: _toggleLowLimitTriggered,
                          ),
                          _StockNewsTab(
                            notificationController:
                                widget.notificationController,
                            accountId:
                                widget.sessionController.session?.accountId,
                            stockCode: widget.stockCode,
                            stockName: snapshot.stockName,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: _StockBottomActionBar(
          onSell: () => _handleTradeAction('Sell'),
          onBuy: () => _handleTradeAction('Buy', _buildSnapshot()),
        ),
      ),
    );
  }

  _StockDetailSnapshot _buildSnapshot() {
    return _StockDetailSnapshot.fromControllers(
      stockCode: widget.stockCode,
      fallbackTitle: widget.title,
      fallbackMarket: widget.market,
      fallbackSector: widget.sector,
      detailState: widget.marketDetailController.value,
      tradeState: widget.tradeController.value,
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
          notificationController: widget.notificationController,
          recentSearches: const [],
          favoriteStockCodes: _isFavorite ? {widget.stockCode} : const {},
          onSearchCommitted: (_) {},
          onRemoveRecentSearch: (_) {},
          onClearRecentSearches: () {},
          onToggleFavoriteStock: (_) {},
          onNavigateToAccounts: widget.onNavigateToAccounts ?? () {},
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

  void _handleTradeAction(String side, [_StockDetailSnapshot? snapshot]) {
    if (_isLowLimitTriggered) {
      _showPriceLimitRestrictionDialog();
      return;
    }
    if (_showViBanner) {
      _showViRestrictionDialog();
      return;
    }
    if (side == 'Buy' && snapshot != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => _StockOrderEntryScreen(
            sessionController: widget.sessionController,
            marketDetailController: widget.marketDetailController,
            marketQuoteController: widget.marketQuoteController,
            tradeController: widget.tradeController,
            notificationController: widget.notificationController,
            stockCode: widget.stockCode,
            snapshot: snapshot,
            initialIsFavorite: _isFavorite,
            onFavoriteToggle: _toggleFavorite,
            onViewAccounts: widget.onNavigateToAccounts,
          ),
        ),
      );
      return;
    }
    _showTradePlaceholder(side);
  }

  void _toggleViBanner() {
    final nextValue = !_showViBanner;
    setState(() {
      _showViBanner = nextValue;
    });
    if (nextValue && _detailScrollController.hasClients) {
      _detailScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _showViInfoPanel() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const _ViInfoPanel();
      },
    );
  }

  void _showLowLimitInfoPanel() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const _LowLimitInfoPanel();
      },
    );
  }

  void _toggleLowLimitTriggered() {
    final nextValue = !_isLowLimitTriggered;
    setState(() {
      _isLowLimitTriggered = nextValue;
    });
    if (nextValue && _detailScrollController.hasClients) {
      _detailScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _showViRestrictionDialog() {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'VI restriction',
      barrierColor: const Color.fromRGBO(0, 0, 0, 0.5),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const _ViRestrictionDialog();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  Future<void> _showPriceLimitRestrictionDialog() {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Price limit restriction',
      barrierColor: const Color.fromRGBO(0, 0, 0, 0.5),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const _PriceLimitRestrictionDialog();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
}
