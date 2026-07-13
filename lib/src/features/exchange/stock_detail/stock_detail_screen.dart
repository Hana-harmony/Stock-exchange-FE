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
  late ValueListenable<MarketQuote?> _liveQuoteListenable;
  bool _tabsPinned = false;
  bool _hasDemandQuoteLiveSubscription = false;
  _StockChartPeriod _chartPeriod = _StockChartPeriod.oneDay;

  StockDetail? get _currentDetail => widget.marketDetailController.value.detail;

  bool get _showViBanner => _currentDetail?.viActive ?? false;

  bool get _showCircuitBreakerBanner =>
      _liveQuoteListenable.value?.circuitBreakerActive ?? false;

  bool get _isLowLimitTriggered =>
      _currentDetail?.normalizedPriceLimitState == 'LOWER';

  int get _activeAlertBannerCount {
    var count = 0;
    if (_showCircuitBreakerBanner) {
      count += 1;
    } else if (_showViBanner) {
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
    _liveQuoteListenable =
        widget.marketQuoteController.acquireQuoteListenable(widget.stockCode);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_loadStockDetail());
      }
    });
  }

  @override
  void didUpdateWidget(covariant StockDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final stockChanged = oldWidget.stockCode != widget.stockCode;
    final quoteControllerChanged =
        oldWidget.marketQuoteController != widget.marketQuoteController;
    if (stockChanged || quoteControllerChanged) {
      _releaseQuoteListenableAfterFrame(
        oldWidget.marketQuoteController,
        oldWidget.stockCode,
      );
      oldWidget.marketDetailController.unsubscribeRealtimeSource(
        stockCode: oldWidget.stockCode,
      );
      if (_hasDemandQuoteLiveSubscription) {
        unawaited(
          oldWidget.marketQuoteController.removeDemandLiveStock(
            oldWidget.stockCode,
          ),
        );
        _hasDemandQuoteLiveSubscription = false;
      }
      _liveQuoteListenable =
          widget.marketQuoteController.acquireQuoteListenable(widget.stockCode);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_loadStockDetail());
        }
      });
    }
  }

  @override
  void dispose() {
    _releaseQuoteListenableAfterFrame(
      widget.marketQuoteController,
      widget.stockCode,
    );
    widget.marketDetailController.unsubscribeRealtimeSource(
      stockCode: widget.stockCode,
    );
    if (_hasDemandQuoteLiveSubscription) {
      final stockCode = widget.stockCode;
      final marketQuoteController = widget.marketQuoteController;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!marketQuoteController.isDisposed) {
          unawaited(marketQuoteController.removeDemandLiveStock(stockCode));
        }
      });
    }
    _detailScrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _releaseQuoteListenableAfterFrame(
    MarketQuoteController controller,
    String stockCode,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.isDisposed) {
        controller.releaseQuoteListenable(stockCode);
      }
    });
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
            final detailState = widget.marketDetailController.value;
            final liveQuote = _liveQuoteListenable.value;
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

            return _buildDetailLayout(
              detailState: detailState,
              isInitialLoading: isInitialLoading,
              isInitialFailure: isInitialFailure,
            );
          },
        ),
        bottomNavigationBar: AnimatedBuilder(
          animation: Listenable.merge([
            widget.marketDetailController,
            widget.tradeController,
            _liveQuoteListenable,
          ]),
          builder: (context, _) {
            final snapshot = _buildSnapshot(
              liveQuote: _liveQuoteListenable.value,
            );
            return _StockBottomActionBar(
              onSell: () => _handleTradeAction(
                'Sell',
                _buildSnapshot(liveQuote: _liveQuoteListenable.value),
              ),
              onBuy: () => _handleTradeAction(
                'Buy',
                _buildSnapshot(liveQuote: _liveQuoteListenable.value),
              ),
              isTradeEnabled: snapshot.isTradeEnabled,
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailLayout({
    required MarketDetailState detailState,
    required bool isInitialLoading,
    required bool isInitialFailure,
  }) {
    final stableSnapshot = _buildSnapshot(liveQuote: null);
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _buildQuoteSnapshot(
            builder: (context, snapshot, _) => _StockDetailHeader(
              snapshot: snapshot,
              showCompactTitle: _tabsPinned,
              isFavorite: _isFavorite,
              onBack: () => Navigator.of(context).pop(),
              onSearch: _openSearch,
              onFavorite: _toggleFavorite,
            ),
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
                        key: const ValueKey('stock-detail-initial-error'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _MutedInfoCard(
                            title: 'Detail unavailable',
                            body: detailState.errorMessage ??
                                'Stock detail is temporarily unavailable.',
                          ),
                        ),
                      )
                    : NestedScrollView(
                        controller: _detailScrollController,
                        headerSliverBuilder: (context, innerBoxIsScrolled) {
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
                            SliverToBoxAdapter(
                              child: ValueListenableBuilder<MarketQuote?>(
                                valueListenable: _liveQuoteListenable,
                                builder: (context, liveQuote, _) {
                                  if (_activeAlertBannerCount == 0) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      8,
                                      16,
                                      12,
                                    ),
                                    child: Column(
                                      children: [
                                        if (_showCircuitBreakerBanner)
                                          _CircuitBreakerTriggeredBanner(
                                            onInfoTap:
                                                _showCircuitBreakerInfoPanel,
                                          )
                                        else if (_showViBanner)
                                          _ViTriggeredBanner(
                                            onInfoTap: _showViInfoPanel,
                                          ),
                                        if ((_showCircuitBreakerBanner ||
                                                _showViBanner) &&
                                            _isLowLimitTriggered)
                                          const SizedBox(height: 12),
                                        if (_isLowLimitTriggered)
                                          _LowLimitReachedBanner(
                                            onInfoTap: _showLowLimitInfoPanel,
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: _buildQuoteSnapshot(
                                builder: (context, snapshot, _) =>
                                    _StockOverviewSection(
                                  snapshot: snapshot,
                                  onQuestionTap: _showGlobalPeers,
                                ),
                              ),
                            ),
                            SliverPersistentHeader(
                              pinned: true,
                              delegate: _StockDetailTabsHeaderDelegate(),
                            ),
                          ];
                        },
                        body: TabBarView(
                          children: [
                            _buildQuoteSnapshot(
                              builder: (context, snapshot, _) =>
                                  _StockOrderTab(snapshot: snapshot),
                            ),
                            ValueListenableBuilder<MarketQuote?>(
                              valueListenable: _liveQuoteListenable,
                              builder: (context, liveQuote, _) =>
                                  _StockChartTab(
                                chart: detailState.chart,
                                chartPoints: detailState.chart?.points,
                                status: detailState.status,
                                errorMessage: detailState.errorMessage,
                                marketDataTime: liveQuote?.marketDataTime ??
                                    _currentDetail?.marketDataTime,
                                liveQuote: liveQuote,
                                selectedPeriod: _chartPeriod,
                                onPeriodChanged: _handleChartPeriodChanged,
                              ),
                            ),
                            _StockNewsTab(
                              notificationController:
                                  widget.notificationController,
                              stockCode: widget.stockCode,
                              stockName: stableSnapshot.stockName,
                              sourceType: 'NEWS',
                              emptyTitle: 'No K-News',
                              emptyBody:
                                  'There are no related stock news items yet.',
                            ),
                            _StockNewsTab(
                              notificationController:
                                  widget.notificationController,
                              stockCode: widget.stockCode,
                              stockName: stableSnapshot.stockName,
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
  }

  Widget _buildQuoteSnapshot({
    required Widget Function(
      BuildContext context,
      _StockDetailSnapshot snapshot,
      MarketQuote? liveQuote,
    ) builder,
  }) {
    return ValueListenableBuilder<MarketQuote?>(
      valueListenable: _liveQuoteListenable,
      builder: (context, liveQuote, _) {
        return builder(
          context,
          _buildSnapshot(liveQuote: liveQuote),
          liveQuote,
        );
      },
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

  _StockDetailSnapshot _buildSnapshot({required MarketQuote? liveQuote}) {
    final detailState = widget.marketDetailController.value;
    final now = _now();
    return _StockDetailSnapshot.fromControllers(
      stockCode: widget.stockCode,
      fallbackTitle: widget.title,
      fallbackMarket: widget.market,
      fallbackSector: widget.sector,
      detailState: detailState,
      liveQuote: liveQuote,
      chartPoints: detailState.chart?.points,
      useQuoteChangeRate: _chartPeriod == _StockChartPeriod.oneDay,
      nowUtc: now.toUtc(),
      tradeState: widget.tradeController.value,
    );
  }

  DateTime _now() => widget.nowProvider?.call() ?? DateTime.now();

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

  void _handleTradeAction(String side, [_StockDetailSnapshot? snapshot]) {
    if (!_buildSnapshot(liveQuote: _liveQuoteListenable.value).isTradeEnabled) {
      return;
    }
    if (_isLowLimitTriggered) {
      _showPriceLimitRestrictionDialog();
      return;
    }
    if (_showCircuitBreakerBanner) {
      _showCircuitBreakerInfoPanel();
      return;
    }
    if (_showViBanner) {
      _showViRestrictionDialog();
      return;
    }
    if (snapshot != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => _StockOrderEntryScreen(
            sessionController: widget.sessionController,
            marketDetailController: widget.marketDetailController,
            marketQuoteController: widget.marketQuoteController,
            tradeController: widget.tradeController,
            notificationController: widget.notificationController,
            stockCode: widget.stockCode,
            side: side.toUpperCase(),
            snapshot: snapshot,
            initialIsFavorite: _isFavorite,
            onFavoriteToggle: _toggleFavorite,
            onViewAccounts: widget.onNavigateToAccounts,
          ),
        ),
      );
      return;
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

  void _showCircuitBreakerInfoPanel() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const _CircuitBreakerInfoPanel();
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
    final peerFuture = widget.marketDetailController.loadGlobalPeers(
      stockCode: widget.stockCode,
    );
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _GlobalPeerBottomSheet(
          peerFuture: peerFuture,
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

class _GlobalPeerBottomSheet extends StatefulWidget {
  const _GlobalPeerBottomSheet({required this.peerFuture});

  final Future<GlobalPeerMatch> peerFuture;

  @override
  State<_GlobalPeerBottomSheet> createState() => _GlobalPeerBottomSheetState();
}

class _GlobalPeerBottomSheetState extends State<_GlobalPeerBottomSheet> {
  late final DraggableScrollableController _sheetController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _sheetController = DraggableScrollableController()
      ..addListener(_handleSheetSizeChanged);
  }

  @override
  void dispose() {
    _sheetController
      ..removeListener(_handleSheetSizeChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSheetSizeChanged() {
    final nextExpanded = _sheetController.size > 0.48;
    if (nextExpanded == _isExpanded) {
      return;
    }
    setState(() {
      _isExpanded = nextExpanded;
    });
  }

  Future<void> _expandSheet() async {
    if (_isExpanded || !_sheetController.isAttached) {
      return;
    }
    await _sheetController.animateTo(
      0.92,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.35,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _isExpanded ? null : () => unawaited(_expandSheet()),
          child: Container(
            key: const ValueKey('global-peer-bottom-sheet'),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.05),
                  blurRadius: 10,
                  offset: Offset(4, 0),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: FutureBuilder<GlobalPeerMatch>(
              future: widget.peerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return _GlobalPeerSheetFrame(
                    onExpand:
                        _isExpanded ? null : () => unawaited(_expandSheet()),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: CircularProgressIndicator(
                          color: AppColors.orange500,
                        ),
                      ),
                    ),
                  );
                }
                if (snapshot.hasError || snapshot.data == null) {
                  return _GlobalPeerSheetFrame(
                    onExpand:
                        _isExpanded ? null : () => unawaited(_expandSheet()),
                    child: _MutedInfoCard(
                      title: 'Peer match unavailable',
                      body: 'Global peer analysis could not be loaded.',
                    ),
                  );
                }
                return SingleChildScrollView(
                  controller: scrollController,
                  child: _GlobalPeerSheetContent(
                    match: snapshot.data!,
                    isExpanded: _isExpanded,
                    onExpand:
                        _isExpanded ? null : () => unawaited(_expandSheet()),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _GlobalPeerSheetFrame extends StatelessWidget {
  const _GlobalPeerSheetFrame({
    required this.child,
    this.onExpand,
  });

  final Widget child;
  final VoidCallback? onExpand;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              button: onExpand != null,
              label: 'Expand global peers',
              child: GestureDetector(
                key: const ValueKey('global-peer-expand-handle'),
                behavior: HitTestBehavior.opaque,
                onTap: onExpand,
                child: const _FigmaBottomSheetHandle(),
              ),
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _GlobalPeerSheetContent extends StatelessWidget {
  const _GlobalPeerSheetContent({
    required this.match,
    required this.isExpanded,
    this.onExpand,
  });

  final GlobalPeerMatch match;
  final bool isExpanded;
  final VoidCallback? onExpand;

  @override
  Widget build(BuildContext context) {
    final primaryPeer = match.primaryPeer;
    final tags = _globalPeerTags(match);
    final comparisonItems = _globalPeerComparisonItems(match);
    final strengthItems = _globalPeerStrengthItems(match);

    return _GlobalPeerSheetFrame(
      onExpand: onExpand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _GlobalPeerStockLogo(match: match),
              const SizedBox(width: 12),
              Expanded(
                child: _GlobalPeerHeadline(
                  headline: _globalPeerHeadline(match),
                  primaryPeer: primaryPeer,
                  isExpanded: isExpanded,
                ),
              ),
            ],
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in tags) _GlobalPeerHashTag(label: tag),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text(
            _globalPeerSummary(match),
            key: const ValueKey('global-peer-sheet-summary'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray700,
                ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: isExpanded
                ? const SizedBox.shrink()
                : const Padding(
                    key: ValueKey('global-peer-swipe-hint'),
                    padding: EdgeInsets.only(top: 14),
                    child: Text(
                      '↑ Swipe up for more details',
                      style: TextStyle(
                        color: AppColors.gray400,
                        fontSize: 16,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ),
          ),
          if (comparisonItems.isNotEmpty) ...[
            const SizedBox(height: 20),
            _GlobalPeerComparisonSection(
              items: comparisonItems,
              isExpanded: isExpanded,
            ),
          ],
          if (strengthItems.isNotEmpty) ...[
            const SizedBox(height: 20),
            _GlobalPeerStrengthSection(
              items: strengthItems,
            ),
          ],
        ],
      ),
    );
  }
}

class _FigmaBottomSheetHandle extends StatelessWidget {
  const _FigmaBottomSheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 48,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.gray300,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class _GlobalPeerStockLogo extends StatelessWidget {
  const _GlobalPeerStockLogo({required this.match});

  final GlobalPeerMatch match;

  @override
  Widget build(BuildContext context) {
    return _GlobalPeerLogoMark(
      label: _globalPeerLogoLabel(match),
      logoAssetPath: _koreanStockLogoAssetPath(match.stockCode),
      size: 50,
      backgroundColor: AppColors.blue500,
      foregroundColor: AppColors.white,
    );
  }
}

class _GlobalPeerHeadline extends StatelessWidget {
  const _GlobalPeerHeadline({
    required this.headline,
    required this.primaryPeer,
    required this.isExpanded,
  });

  final String headline;
  final GlobalPeerMatchPeer? primaryPeer;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontSize: 18,
          height: 1.4,
          fontWeight: FontWeight.w600,
          color: AppColors.gray1000,
        );

    return Text.rich(
      TextSpan(
        children: _globalPeerHeadlineSpans(
          headline: headline,
          primaryPeer: primaryPeer,
          baseStyle: baseStyle,
        ),
      ),
      key: const ValueKey('global-peer-sheet-headline'),
      maxLines: isExpanded ? null : 2,
      overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
    );
  }
}

class _GlobalPeerHashTag extends StatelessWidget {
  const _GlobalPeerHashTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          '#$label',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: AppColors.gray700,
              ),
        ),
      ),
    );
  }
}

class _GlobalPeerComparisonSection extends StatelessWidget {
  const _GlobalPeerComparisonSection({
    required this.items,
    required this.isExpanded,
  });

  final List<_GlobalPeerComparisonItem> items;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Global Comparison',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: AppColors.gray1000,
              ),
        ),
        const SizedBox(height: 8),
        for (final item in items) ...[
          _GlobalPeerComparisonCard(
            item: item,
            isExpanded: isExpanded,
          ),
          if (item != items.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _GlobalPeerComparisonCard extends StatelessWidget {
  const _GlobalPeerComparisonCard({
    required this.item,
    required this.isExpanded,
  });

  final _GlobalPeerComparisonItem item;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.gray300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _GlobalPeerCompanyMark(
              label: item.peer.ticker,
              logoUrl: item.peer.logoUrl,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GlobalPeerComparisonTitle(
                    item: item,
                    isExpanded: isExpanded,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.summary,
                    maxLines: isExpanded ? null : 2,
                    overflow: isExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w400,
                          color: AppColors.gray700,
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

class _GlobalPeerComparisonTitle extends StatelessWidget {
  const _GlobalPeerComparisonTitle({
    required this.item,
    required this.isExpanded,
  });

  final _GlobalPeerComparisonItem item;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w600,
          color: AppColors.gray1000,
        );

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '${item.title} ', style: baseStyle),
          TextSpan(
            text: item.peerLabel,
            style: baseStyle?.copyWith(color: AppColors.orange500),
          ),
        ],
      ),
      maxLines: isExpanded ? null : 1,
      overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
    );
  }
}

class _GlobalPeerCompanyMark extends StatelessWidget {
  const _GlobalPeerCompanyMark({
    required this.label,
    required this.logoUrl,
  });

  final String label;
  final String logoUrl;

  @override
  Widget build(BuildContext context) {
    return _GlobalPeerLogoMark(
      label: label,
      logoAssetPath: _globalPeerComparisonLogoAssetPath(label),
      logoUrl: logoUrl,
      size: 48,
      backgroundColor: AppColors.gray100,
      foregroundColor: AppColors.orange500,
    );
  }
}

class _GlobalPeerLogoMark extends StatelessWidget {
  const _GlobalPeerLogoMark({
    required this.label,
    required this.logoAssetPath,
    required this.size,
    required this.backgroundColor,
    required this.foregroundColor,
    this.logoUrl = '',
  });

  final String label;
  final String? logoAssetPath;
  final double size;
  final Color backgroundColor;
  final Color foregroundColor;
  final String logoUrl;

  @override
  Widget build(BuildContext context) {
    final normalizedAssetPath = logoAssetPath?.trim() ?? '';
    if (normalizedAssetPath.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: size,
          height: size,
          color: AppColors.white,
          child: Image.asset(
            normalizedAssetPath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return _fallbackMark(context);
            },
          ),
        ),
      );
    }
    final trustedLogoUri = _trustedGlobalPeerLogoUri(logoUrl, label);
    if (trustedLogoUri != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: size,
          height: size,
          color: AppColors.white,
          child: Image.network(
            trustedLogoUri.toString(),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, error, stackTrace) {
              return _fallbackMark(context);
            },
          ),
        ),
      );
    }
    return _fallbackMark(context);
  }

  Widget _fallbackMark(BuildContext context) {
    final normalized = label.trim().isEmpty ? '?' : label.trim().toUpperCase();
    final visibleLabel = normalized.characters.take(4).join();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        visibleLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontSize: visibleLabel.length > 3 ? 11 : 13,
              height: 1,
              fontWeight: FontWeight.w700,
              color: foregroundColor,
            ),
      ),
    );
  }
}

class _GlobalPeerStrengthSection extends StatelessWidget {
  const _GlobalPeerStrengthSection({
    required this.items,
  });

  final List<_GlobalPeerStrengthItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Strengths',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: AppColors.gray1000,
              ),
        ),
        const SizedBox(height: 8),
        Column(
          children: [
            for (var index = 0; index < items.length; index += 2)
              Padding(
                padding: EdgeInsets.only(
                  bottom: index + 2 < items.length ? 8 : 0,
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _GlobalPeerStrengthCard(
                          key: ValueKey(
                            'global-peer-strength-card-${items[index].iconKey}',
                          ),
                          item: items[index],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: index + 1 < items.length
                            ? _GlobalPeerStrengthCard(
                                key: ValueKey(
                                  'global-peer-strength-card-'
                                  '${items[index + 1].iconKey}',
                                ),
                                item: items[index + 1],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _GlobalPeerStrengthCard extends StatelessWidget {
  const _GlobalPeerStrengthCard({
    super.key,
    required this.item,
  });

  final _GlobalPeerStrengthItem item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.gray300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _GlobalPeerStrengthIcon(iconKey: item.iconKey),
            const SizedBox(height: 4),
            Text(
              item.title,
              overflow: TextOverflow.visible,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray1000,
                  ),
            ),
            Text(
              item.description,
              overflow: TextOverflow.visible,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                    color: AppColors.gray600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlobalPeerComparisonItem {
  const _GlobalPeerComparisonItem({
    required this.title,
    required this.peerLabel,
    required this.summary,
    required this.peer,
  });

  final String title;
  final String peerLabel;
  final String summary;
  final GlobalPeerMatchPeer peer;
}

class _GlobalPeerStrengthItem {
  const _GlobalPeerStrengthItem({
    required this.title,
    required this.description,
    required this.iconKey,
  });

  final String title;
  final String description;
  final String iconKey;
}

List<_GlobalPeerComparisonItem> _globalPeerComparisonItems(
  GlobalPeerMatch match,
) {
  return [
    for (final comparison in match.comparisons)
      _GlobalPeerComparisonItem(
        title: _globalPeerDimensionLabel(comparison.dimension),
        peerLabel: _globalPeerShortPeerLabel(comparison.peer),
        summary: comparison.description,
        peer: comparison.peer,
      ),
  ];
}

String _globalPeerShortPeerLabel(GlobalPeerMatchPeer peer) {
  return peer.comparisonLabel;
}

List<_GlobalPeerStrengthItem> _globalPeerStrengthItems(GlobalPeerMatch match) {
  return match.keyStrengths
      .map(
        (strength) => _GlobalPeerStrengthItem(
          title: strength.title,
          description: strength.description,
          iconKey: strength.iconKey,
        ),
      )
      .toList(growable: false);
}

String _globalPeerDimensionLabel(String dimension) {
  switch (dimension.trim().toLowerCase()) {
    case 'overall_business':
      return 'Overall Business';
    case 'semiconductor_ds':
      return 'Semiconductor(DS)';
    case 'consumer_electronics':
      return 'Consumer Electronics';
    case 'software_platform':
      return 'Software Platform';
    case 'financial_services':
      return 'Financial Services';
    case 'drug_delivery':
      return 'Drug Delivery';
    case 'operational_scale':
      return 'Operational Scale';
    default:
      return _formatGlobalPeerTag(dimension);
  }
}

String? _globalPeerComparisonLogoAssetPath(String ticker) {
  switch (ticker.trim().toUpperCase()) {
    case 'AAPL':
      return AppAssets.stockQuestionComparisonApple;
    case 'INTC':
      return AppAssets.stockQuestionComparisonIntel;
    case 'TSM':
    case 'TSMC':
      return AppAssets.stockQuestionComparisonTsmc;
    default:
      return _usStockLogoAssetPath(ticker);
  }
}

Uri? _trustedGlobalPeerLogoUri(String rawUrl, String ticker) {
  final normalizedTicker = ticker.trim().toUpperCase();
  if (!RegExp(r'^[A-Z0-9.-]{1,12}$').hasMatch(normalizedTicker)) {
    return null;
  }
  final uri = Uri.tryParse(rawUrl.trim());
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host != 'financialmodelingprep.com' ||
      uri.userInfo.isNotEmpty ||
      (uri.hasPort && uri.port != 443) ||
      uri.query.isNotEmpty ||
      uri.fragment.isNotEmpty ||
      uri.pathSegments.length != 2 ||
      uri.pathSegments.first != 'image-stock' ||
      uri.pathSegments.last.toUpperCase() != '$normalizedTicker.PNG') {
    return null;
  }
  return uri;
}

class _GlobalPeerStrengthIcon extends StatelessWidget {
  const _GlobalPeerStrengthIcon({required this.iconKey});

  final String iconKey;

  @override
  Widget build(BuildContext context) {
    final assetPath = _globalPeerStrengthIconAsset(iconKey);
    if (assetPath != null) {
      return Image.asset(
        assetPath,
        width: 24,
        height: 24,
        fit: BoxFit.contain,
      );
    }
    return Icon(
      _globalPeerStrengthIconData(iconKey),
      key: ValueKey('global-peer-strength-icon-$iconKey'),
      color: AppColors.orange500,
      size: 24,
    );
  }
}

String? _globalPeerStrengthIconAsset(String iconKey) {
  switch (iconKey.trim().toLowerCase()) {
    case 'memory':
      return AppAssets.stockQuestionMemoryIcon;
    case 'foundry':
      return AppAssets.stockQuestionFoundryIcon;
    case 'ecosystem':
      return AppAssets.stockQuestionEcosystemIcon;
    case 'ai':
      return AppAssets.stockQuestionAiIcon;
    default:
      return null;
  }
}

IconData _globalPeerStrengthIconData(String iconKey) {
  switch (iconKey.trim().toLowerCase()) {
    case 'semiconductor':
      return Icons.memory;
    case 'consumer_electronics':
      return Icons.devices;
    case 'software_platform':
      return Icons.apps;
    case 'financial_services':
      return Icons.account_balance;
    case 'payments':
      return Icons.payments;
    case 'biotechnology':
      return Icons.biotech;
    case 'drug_delivery':
      return Icons.medication;
    case 'battery':
      return Icons.battery_charging_full;
    case 'automotive':
      return Icons.directions_car;
    case 'telecommunications':
      return Icons.cell_tower;
    case 'energy':
      return Icons.bolt;
    case 'materials':
      return Icons.layers;
    case 'industrial':
      return Icons.precision_manufacturing;
    case 'commerce':
      return Icons.storefront;
    case 'media':
      return Icons.movie;
    case 'operational_scale':
      return Icons.factory;
    case 'memory':
    case 'foundry':
    case 'ai':
    case 'ecosystem':
    case 'global_business':
    default:
      return Icons.public;
  }
}

String _globalPeerHeadline(GlobalPeerMatch match) {
  final headline = match.headline.trim();
  if (headline.isNotEmpty) {
    return headline;
  }
  final peer = match.primaryPeer;
  if (peer != null) {
    return '${match.stockName} is similar to ${peer.companyName}';
  }
  return 'Global peer analysis';
}

String _globalPeerSummary(GlobalPeerMatch match) {
  final summary = match.summary.trim();
  if (summary.isNotEmpty) {
    return summary;
  }
  final peer = match.primaryPeer;
  if (peer != null && peer.rationale.trim().isNotEmpty) {
    return peer.rationale.trim();
  }
  return 'Global peer analysis is unavailable for the latest stock data.';
}

List<String> _globalPeerTags(GlobalPeerMatch match) {
  final values = <String>[
    ...match.keyStrengths.map(_globalPeerTagForStrength),
    ...?match.primaryPeer?.businessTags,
    if (match.primaryPeer?.sector.isNotEmpty ?? false)
      match.primaryPeer!.sector,
    if (match.primaryPeer?.industry.isNotEmpty ?? false)
      match.primaryPeer!.industry,
  ];
  final seen = <String>{};
  return values
      .map(_formatGlobalPeerTag)
      .where((tag) => tag.isNotEmpty)
      .where((tag) => seen.add(tag.toLowerCase()))
      .take(3)
      .toList(growable: false);
}

String _globalPeerTagForStrength(GlobalPeerKeyStrength strength) {
  switch (strength.iconKey.trim().toLowerCase()) {
    case 'memory':
    case 'foundry':
    case 'semiconductor':
      return 'Semiconductors';
    case 'ecosystem':
    case 'consumer_electronics':
      return 'Consumer Electronics';
    case 'ai':
      return 'AI';
    default:
      return strength.title;
  }
}

String _formatGlobalPeerTag(String value) {
  final normalized = value.trim().replaceAll(RegExp(r'[_-]+'), ' ');
  if (normalized.isEmpty) {
    return '';
  }
  return normalized
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) {
    if (part.length <= 2 && part.toUpperCase() == part) {
      return part;
    }
    return '${part[0].toUpperCase()}${part.substring(1)}';
  }).join(' ');
}

String _globalPeerLogoLabel(GlobalPeerMatch match) {
  final source = match.stockName.trim().isNotEmpty
      ? match.stockName.trim()
      : match.stockCode.trim();
  final letters = source
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part.characters.first)
      .take(2)
      .join()
      .toUpperCase();
  return letters.isEmpty ? '?' : letters;
}

List<TextSpan> _globalPeerHeadlineSpans({
  required String headline,
  required GlobalPeerMatchPeer? primaryPeer,
  required TextStyle? baseStyle,
}) {
  final accentStyle = baseStyle?.copyWith(color: AppColors.orange500);
  final quoteMatch = RegExp("[‘']([^’']+)[’']").firstMatch(headline);
  if (quoteMatch != null) {
    final start = quoteMatch.start;
    final end = quoteMatch.end;
    return [
      TextSpan(text: headline.substring(0, start), style: baseStyle),
      TextSpan(text: headline.substring(start, end), style: accentStyle),
      TextSpan(text: headline.substring(end), style: baseStyle),
    ];
  }

  final peerName = primaryPeer?.companyName.trim() ?? '';
  final peerToken = peerName.split(RegExp(r'\s+')).firstWhere(
        (part) => part.isNotEmpty,
        orElse: () => '',
      );
  if (peerToken.isNotEmpty) {
    final index = headline.toLowerCase().indexOf(peerToken.toLowerCase());
    if (index >= 0) {
      return [
        TextSpan(text: headline.substring(0, index), style: baseStyle),
        TextSpan(
          text: headline.substring(index, index + peerToken.length),
          style: accentStyle,
        ),
        TextSpan(
          text: headline.substring(index + peerToken.length),
          style: baseStyle,
        ),
      ];
    }
  }

  return [TextSpan(text: headline, style: baseStyle)];
}
