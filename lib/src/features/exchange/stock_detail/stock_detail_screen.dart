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
    this.onFavoriteChanged,
    this.onNavigateToAccounts,
    this.nowProvider,
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
  final Future<bool> Function(String stockCode, bool nextIsFavorite)?
      onFavoriteChanged;
  final VoidCallback? onNavigateToAccounts;
  final DateTime Function()? nowProvider;

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  late bool _isFavorite;
  late final ScrollController _detailScrollController;
  bool _tabsPinned = false;
  bool _hasDemandQuoteLiveSubscription = false;
  _StockChartPeriod _chartPeriod = _StockChartPeriod.oneDay;

  StockDetail? get _currentDetail => widget.marketDetailController.value.detail;

  bool get _showViBanner => _currentDetail?.viActive ?? false;

  bool get _isLowLimitTriggered =>
      _currentDetail?.normalizedPriceLimitState == 'LOWER';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_loadStockDetail());
      }
    });
  }

  @override
  void didUpdateWidget(covariant StockDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stockCode != widget.stockCode) {
      widget.marketDetailController.unsubscribeRealtimeSource(
        stockCode: oldWidget.stockCode,
      );
      if (_hasDemandQuoteLiveSubscription) {
        unawaited(
          widget.marketQuoteController.removeDemandLiveStock(
            oldWidget.stockCode,
          ),
        );
        _hasDemandQuoteLiveSubscription = false;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_loadStockDetail());
        }
      });
    }
  }

  @override
  void dispose() {
    widget.marketDetailController.unsubscribeRealtimeSource(
      stockCode: widget.stockCode,
    );
    if (_hasDemandQuoteLiveSubscription) {
      final stockCode = widget.stockCode;
      final marketQuoteController = widget.marketQuoteController;
      Future<void>.microtask(() {
        unawaited(marketQuoteController.removeDemandLiveStock(stockCode));
      });
    }
    _detailScrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadStockDetail() async {
    unawaited(
      widget.marketDetailController.subscribeRealtimeSource(
        stockCode: widget.stockCode,
      ),
    );
    _hasDemandQuoteLiveSubscription = true;
    unawaited(
        widget.marketQuoteController.addDemandLiveStock(widget.stockCode));
    final now = _now();
    await widget.marketDetailController.loadStock(
      stockCode: widget.stockCode,
      currency: 'USD',
      interval: _chartPeriod.apiInterval,
      from: _chartPeriod.fromDate(now),
      to: _chartPeriod.toDate(now),
    );
  }

  Future<void> _toggleFavorite() async {
    final wasFavorite = _isFavorite;
    final nextIsFavorite = !wasFavorite;
    setState(() {
      _isFavorite = nextIsFavorite;
    });
    final changed = widget.onFavoriteChanged == null
        ? true
        : await widget.onFavoriteChanged!(
            widget.stockCode,
            nextIsFavorite,
          );
    if (!changed && mounted) {
      setState(() {
        _isFavorite = wasFavorite;
      });
      return;
    }
    if (widget.onFavoriteChanged == null) {
      widget.onFavoriteToggle?.call();
    }
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
      length: 5,
      child: AppScaffold(
        bodySafeAreaBottom: false,
        extendBody: true,
        body: AnimatedBuilder(
          animation: Listenable.merge([
            widget.marketDetailController,
            widget.marketQuoteController,
            widget.tradeController,
          ]),
          builder: (context, _) {
            final detailState = widget.marketDetailController.value;
            final liveQuote =
                widget.marketQuoteController.quoteFor(widget.stockCode);
            final snapshot = _buildSnapshot();
            final hasRenderableMarketData = _hasRenderableMarketData(
              detailState: detailState,
              liveQuote: liveQuote,
            );
            final isInitialLoading =
                (detailState.status == MarketDetailStatus.idle ||
                        detailState.status == MarketDetailStatus.loading) &&
                    !hasRenderableMarketData;
            final isInitialFailure =
                detailState.status == MarketDetailStatus.failure &&
                    !hasRenderableMarketData;

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
                    child: isInitialLoading
                        ? const Center(
                            key: ValueKey('stock-detail-initial-loading'),
                            child: CircularProgressIndicator(
                              color: AppColors.orange500,
                            ),
                          )
                        : isInitialFailure
                            ? Center(
                                key: const ValueKey(
                                  'stock-detail-initial-error',
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: _MutedInfoCard(
                                    title: 'Detail unavailable',
                                    body: detailState.errorMessage ??
                                        'Stock detail is temporarily unavailable.',
                                  ),
                                ),
                              )
                            : NestedScrollView(
                                controller: _detailScrollController,
                                headerSliverBuilder:
                                    (context, innerBoxIsScrolled) {
                                  return [
                                    if (detailState.status ==
                                        MarketDetailStatus.loading)
                                      const SliverToBoxAdapter(
                                        child: LinearProgressIndicator(
                                          key: ValueKey(
                                            'stock-detail-partial-loading',
                                          ),
                                          minHeight: 2,
                                          color: AppColors.orange500,
                                          backgroundColor: AppColors.gray100,
                                        ),
                                      ),
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
                                              if (_showViBanner &&
                                                  _isLowLimitTriggered)
                                                const SizedBox(height: 12),
                                              if (_isLowLimitTriggered)
                                                _LowLimitReachedBanner(
                                                  onInfoTap:
                                                      _showLowLimitInfoPanel,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    SliverToBoxAdapter(
                                      child: _StockOverviewSection(
                                        snapshot: snapshot,
                                        onQuestionTap: _showGlobalPeers,
                                      ),
                                    ),
                                    SliverPersistentHeader(
                                      pinned: true,
                                      delegate:
                                          _StockDetailTabsHeaderDelegate(),
                                    ),
                                  ];
                                },
                                body: TabBarView(
                                  children: [
                                    _StockOrderTab(snapshot: snapshot),
                                    _StockChartTab(
                                      chart: detailState.chart,
                                      status: detailState.status,
                                      errorMessage: detailState.errorMessage,
                                      marketDataTime:
                                          liveQuote?.marketDataTime ??
                                              _currentDetail?.marketDataTime,
                                      selectedPeriod: _chartPeriod,
                                      onPeriodChanged:
                                          _handleChartPeriodChanged,
                                    ),
                                    _StockFundamentalsTab(
                                      snapshot: snapshot,
                                      detail: _currentDetail,
                                    ),
                                    _StockNewsTab(
                                      notificationController:
                                          widget.notificationController,
                                      stockCode: widget.stockCode,
                                      stockName: snapshot.stockName,
                                      sourceType: 'NEWS',
                                      emptyTitle: 'No K-News',
                                      emptyBody:
                                          'There are no related stock news items yet.',
                                    ),
                                    _StockNewsTab(
                                      notificationController:
                                          widget.notificationController,
                                      stockCode: widget.stockCode,
                                      stockName: snapshot.stockName,
                                      sourceType: 'DISCLOSURE',
                                      emptyTitle: 'No disclosures',
                                      emptyBody:
                                          'There are no related disclosure items yet.',
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

  void _handleChartPeriodChanged(_StockChartPeriod period) {
    if (period == _chartPeriod) {
      return;
    }
    setState(() {
      _chartPeriod = period;
    });
    unawaited(_loadStockDetail());
  }

  _StockDetailSnapshot _buildSnapshot() {
    final detailState = widget.marketDetailController.value;
    final liveQuote = widget.marketQuoteController.quoteFor(widget.stockCode);
    final now = _now();
    return _StockDetailSnapshot.fromControllers(
      stockCode: widget.stockCode,
      fallbackTitle: widget.title,
      fallbackMarket: widget.market,
      fallbackSector: widget.sector,
      detailState: detailState,
      liveQuote: liveQuote,
      chartPoints: _chartPointsForSnapshot(
        chart: detailState.chart,
        marketDataTime:
            liveQuote?.marketDataTime ?? _currentDetail?.marketDataTime,
      ),
      nowUtc: now.toUtc(),
      tradeState: widget.tradeController.value,
    );
  }

  DateTime _now() => widget.nowProvider?.call() ?? DateTime.now();

  List<MarketChartPoint>? _chartPointsForSnapshot({
    required MarketChart? chart,
    required DateTime? marketDataTime,
  }) {
    final points = chart?.points;
    if (points == null || points.isEmpty) {
      return null;
    }
    if (_chartPeriod == _StockChartPeriod.oneDay) {
      return _visibleOneDayChartPoints(points, marketDataTime);
    }
    return points;
  }

  bool _hasRenderableMarketData({
    required MarketDetailState detailState,
    required MarketQuote? liveQuote,
  }) {
    if (liveQuote?.stockCode == widget.stockCode) {
      return true;
    }
    if (detailState.detail?.stockCode == widget.stockCode) {
      return true;
    }
    if (detailState.chart?.stockCode == widget.stockCode &&
        detailState.chart!.points.isNotEmpty) {
      return true;
    }
    return false;
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
          onFavoriteChanged: widget.onFavoriteChanged,
          onNavigateToAccounts: widget.onNavigateToAccounts ?? () {},
          nowProvider: widget.nowProvider,
        ),
      ),
    );
  }

  void _showTradePlaceholder(String side) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$side orders are being prepared.'),
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

  Future<void> _showGlobalPeers() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _GlobalPeerBottomSheet(
          peerFuture: widget.marketDetailController.loadGlobalPeers(
            stockCode: widget.stockCode,
          ),
        );
      },
    );
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
        return FadeTransition(opacity: animation, child: child);
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
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}

class _GlobalPeerBottomSheet extends StatelessWidget {
  const _GlobalPeerBottomSheet({required this.peerFuture});

  final Future<GlobalPeerMatch> peerFuture;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: FutureBuilder<GlobalPeerMatch>(
            future: peerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.orange500),
                );
              }
              if (snapshot.hasError || snapshot.data == null) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(20, 28, 20, 28),
                  child: _MutedInfoCard(
                    title: 'Peer match unavailable',
                    body: 'Global peer analysis could not be loaded.',
                  ),
                );
              }
              final match = snapshot.data!;
              final primaryPeer = match.primaryPeer;
              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.gray300,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    match.headline.isEmpty
                        ? 'Global peer analysis'
                        : match.headline,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 22,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray1000,
                        ),
                  ),
                  if (match.summary.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      match.summary,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 15,
                            height: 1.45,
                            color: AppColors.gray800,
                          ),
                    ),
                  ],
                  if (primaryPeer != null) ...[
                    const SizedBox(height: 20),
                    _GlobalPeerCard(peer: primaryPeer),
                  ],
                  if (match.peers.length > 1) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Other close peers',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray1000,
                          ),
                    ),
                    const SizedBox(height: 10),
                    for (final peer in match.peers.skip(1).take(3)) ...[
                      _GlobalPeerCard(peer: peer),
                      const SizedBox(height: 10),
                    ],
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _GlobalPeerCard extends StatelessWidget {
  const _GlobalPeerCard({required this.peer});

  final GlobalPeerMatchPeer peer;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              peer.displayName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray1000,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              [
                if (peer.sector.isNotEmpty) peer.sector,
                if (peer.industry.isNotEmpty) peer.industry,
                if (peer.exchange.isNotEmpty) peer.exchange,
              ].join(' · '),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    height: 1.35,
                    color: AppColors.gray600,
                  ),
            ),
            if (peer.rationale.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                peer.rationale,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      height: 1.45,
                      color: AppColors.gray800,
                    ),
              ),
            ],
            if (peer.matchedFactors.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...peer.matchedFactors.take(4).map(
                    (factor) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 7),
                            child: SizedBox.square(
                              dimension: 4,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppColors.orange500,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              factor,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: AppColors.gray700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
