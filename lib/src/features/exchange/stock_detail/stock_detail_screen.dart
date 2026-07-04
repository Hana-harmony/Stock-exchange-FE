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

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.35,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
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
                return const _GlobalPeerSheetFrame(
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
                return const _GlobalPeerSheetFrame(
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
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _GlobalPeerSheetFrame extends StatelessWidget {
  const _GlobalPeerSheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _FigmaBottomSheetHandle(),
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
  });

  final GlobalPeerMatch match;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final primaryPeer = match.primaryPeer;
    final tags = _globalPeerTags(match);
    final comparisonItems = _globalPeerComparisonItems(match);
    final strengthItems = _globalPeerStrengthItems(match);

    return _GlobalPeerSheetFrame(
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
              isExpanded: isExpanded,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GlobalPeerCompanyMark(
              label: item.peer.ticker,
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
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return _GlobalPeerLogoMark(
      label: label,
      logoAssetPath: _usStockLogoAssetPath(label),
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
  });

  final String label;
  final String? logoAssetPath;
  final double size;
  final Color backgroundColor;
  final Color foregroundColor;

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
    required this.isExpanded,
  });

  final List<_GlobalPeerStrengthItem> items;
  final bool isExpanded;

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
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = isExpanded
                ? constraints.maxWidth
                : (constraints.maxWidth - 8) / 2;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in items)
                  SizedBox(
                    width: itemWidth,
                    child: _GlobalPeerStrengthCard(
                      item: item,
                      isExpanded: isExpanded,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _GlobalPeerStrengthCard extends StatelessWidget {
  const _GlobalPeerStrengthCard({
    required this.item,
    required this.isExpanded,
  });

  final _GlobalPeerStrengthItem item;
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
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              isExpanded ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Image.asset(
              item.iconAsset,
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 4),
            Text(
              item.title,
              maxLines: isExpanded ? null : 1,
              overflow:
                  isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              textAlign: isExpanded ? TextAlign.left : TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray1000,
                  ),
            ),
            Text(
              item.description,
              maxLines: isExpanded ? null : 2,
              overflow:
                  isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              textAlign: isExpanded ? TextAlign.left : TextAlign.center,
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
    required this.iconAsset,
  });

  final String title;
  final String description;
  final String iconAsset;
}

List<_GlobalPeerComparisonItem> _globalPeerComparisonItems(
  GlobalPeerMatch match,
) {
  final peers = match.peers.take(3).toList(growable: false);
  return [
    for (var index = 0; index < peers.length; index++)
      _GlobalPeerComparisonItem(
        title: _globalPeerComparisonTitle(peers[index], index),
        peerLabel: _globalPeerShortPeerLabel(peers[index]),
        summary: _globalPeerComparisonSummary(peers[index]),
        peer: peers[index],
      ),
  ];
}

String _globalPeerComparisonTitle(GlobalPeerMatchPeer peer, int index) {
  if (index == 0) {
    return 'Overall Business';
  }
  final tags = peer.businessTags
      .map(_formatGlobalPeerTag)
      .where((tag) => tag.isNotEmpty)
      .toList(growable: false);
  if (tags.isNotEmpty) {
    return tags.first;
  }
  if (peer.industry.trim().isNotEmpty) {
    return _formatGlobalPeerTag(peer.industry);
  }
  if (peer.sector.trim().isNotEmpty) {
    return _formatGlobalPeerTag(peer.sector);
  }
  return index == 1 ? 'Business Segment' : 'Growth Segment';
}

String _globalPeerShortPeerLabel(GlobalPeerMatchPeer peer) {
  final ticker = peer.ticker.trim();
  if (_isKnownTicker(ticker, const ['AAPL'])) {
    return 'Apple';
  }
  if (_isKnownTicker(ticker, const ['INTC'])) {
    return 'Intel';
  }
  if (_isKnownTicker(ticker, const ['TSM', 'TSMC'])) {
    return 'TSMC';
  }
  final companyName = peer.companyName.trim();
  if (companyName.isEmpty) {
    return ticker.isEmpty ? 'Peer' : ticker;
  }
  final normalized = companyName
      .replaceAll(RegExp(r'\b(Inc\.?|Corp\.?|Corporation|Ltd\.?)\b'), '')
      .trim();
  return normalized.split(RegExp(r'\s+')).firstWhere(
        (part) => part.isNotEmpty,
        orElse: () => companyName,
      );
}

String _globalPeerComparisonSummary(GlobalPeerMatchPeer peer) {
  for (final value in [
    peer.rationale,
    ...peer.matchedFactors,
    peer.businessModel,
  ]) {
    final normalized = value.trim();
    if (normalized.isNotEmpty) {
      return normalized;
    }
  }
  final descriptionParts = [
    if (peer.sector.isNotEmpty) peer.sector,
    if (peer.industry.isNotEmpty) peer.industry,
    if (peer.exchange.isNotEmpty) peer.exchange,
  ];
  return descriptionParts.isEmpty
      ? 'Peer similarity is derived from the latest global comparison model.'
      : '${descriptionParts.join(' · ')} peer selected by the global comparison model.';
}

List<_GlobalPeerStrengthItem> _globalPeerStrengthItems(GlobalPeerMatch match) {
  final primaryPeer = match.primaryPeer;
  if (primaryPeer == null) {
    return const <_GlobalPeerStrengthItem>[];
  }

  final subjectName = _globalPeerSubjectName(match);
  final seen = <String>{};
  final items = <_GlobalPeerStrengthItem>[];

  void addItem({
    required String title,
    required String description,
    required String rawValue,
  }) {
    if (items.length == 4) {
      return;
    }
    final normalizedTitle = title.trim();
    final normalizedDescription =
        description.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalizedTitle.isEmpty || normalizedDescription.isEmpty) {
      return;
    }
    final key = '$normalizedTitle|$normalizedDescription'.toLowerCase();
    if (!seen.add(key)) {
      return;
    }

    items.add(
      _GlobalPeerStrengthItem(
        title: normalizedTitle,
        description: normalizedDescription,
        iconAsset: _globalPeerStrengthIcon(rawValue, items.length),
      ),
    );
  }

  for (final rawValue in primaryPeer.businessTags) {
    final title = _globalPeerStrengthTitle(rawValue);
    final theme = title.toLowerCase();
    addItem(
      title: title,
      description:
          '$subjectName is tagged for $theme exposure in the global peer model.',
      rawValue: rawValue,
    );
  }

  for (final rawValue in primaryPeer.matchedFactors) {
    final item = _globalPeerSubjectStrengthFromFactor(
      rawValue: rawValue,
      subjectName: subjectName,
    );
    if (item == null) {
      continue;
    }
    addItem(
      title: item.title,
      description: item.description,
      rawValue: rawValue,
    );
  }

  final summary = match.summary.trim();
  if (!_globalPeerLooksComparative(summary)) {
    addItem(
      title: 'Business Summary',
      description: summary,
      rawValue: summary,
    );
  }

  if (items.isEmpty) {
    return [
      _GlobalPeerStrengthItem(
        title: 'Strong Match',
        description: _globalPeerSummary(match),
        iconAsset: AppAssets.stockQuestionEcosystemIcon,
      ),
    ];
  }
  return items;
}

String _globalPeerSubjectName(GlobalPeerMatch match) {
  final stockName = match.stockName.trim();
  if (stockName.isEmpty) {
    final stockCode = match.stockCode.trim();
    return stockCode.isEmpty ? 'This stock' : stockCode;
  }
  final englishName = stockName.split(RegExp(r'\s*\(')).first.trim();
  return englishName.isEmpty ? stockName : englishName;
}

String _globalPeerStrengthTitle(String value) {
  final formatted = _formatGlobalPeerTag(value);
  if (formatted.isEmpty) {
    return '';
  }
  if (formatted.toLowerCase() == 'memory') {
    return 'in Memory';
  }
  return formatted;
}

_GlobalPeerStrengthItem? _globalPeerSubjectStrengthFromFactor({
  required String rawValue,
  required String subjectName,
}) {
  final normalized = rawValue.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.isEmpty) {
    return null;
  }

  final sourceMatch = RegExp(
    r'source=([^,]+)(?:,\s*peer=|$)',
    caseSensitive: false,
  ).firstMatch(normalized);
  if (sourceMatch != null) {
    final sourceValue = sourceMatch.group(1)?.trim() ?? '';
    if (sourceValue.isNotEmpty) {
      return _GlobalPeerStrengthItem(
        title: 'Business Model',
        description: '$subjectName business model: $sourceValue.',
        iconAsset: _globalPeerStrengthIcon(sourceValue, 0),
      );
    }
  }

  final mappedMatch = RegExp(
    r'^(Sector|Industry|Scale):\s*both are mapped to\s+(.+?)\.?$',
    caseSensitive: false,
  ).firstMatch(normalized);
  if (mappedMatch != null) {
    final label = (mappedMatch.group(1) ?? '').toLowerCase();
    final value = (mappedMatch.group(2) ?? '').trim();
    final title = label == 'scale'
        ? _formatGlobalPeerTag(value)
        : _globalPeerStrengthTitle(value);
    final description = label == 'scale'
        ? '$subjectName is classified as ${_formatGlobalPeerTag(value)} in the global peer model.'
        : '$subjectName is classified under $value ${label == 'sector' ? 'sector' : 'industry'} in the global peer model.';
    return _GlobalPeerStrengthItem(
      title: title,
      description: description,
      iconAsset: _globalPeerStrengthIcon(value, 0),
    );
  }

  if (_globalPeerLooksComparative(normalized)) {
    return null;
  }

  return _GlobalPeerStrengthItem(
    title: _globalPeerSubjectFactorTitle(normalized),
    description: normalized,
    iconAsset: _globalPeerStrengthIcon(normalized, 0),
  );
}

String _globalPeerSubjectFactorTitle(String value) {
  final normalized = value.toLowerCase();
  if (normalized.startsWith('revenue model')) {
    return 'Revenue Mix';
  }
  if (normalized.startsWith('business model')) {
    return 'Business Model';
  }
  if (normalized.startsWith('sector')) {
    return 'Sector';
  }
  if (normalized.startsWith('industry')) {
    return 'Industry';
  }
  return 'Business Strength';
}

bool _globalPeerLooksComparative(String value) {
  final normalized = value.toLowerCase();
  return normalized.contains('both ') ||
      normalized.contains('peer=') ||
      normalized.contains(' peer ') ||
      normalized.contains('matched with') ||
      normalized.contains('closest us-listed') ||
      normalized.contains('comparison') ||
      normalized.contains('similarity');
}

String _globalPeerStrengthIcon(String value, int index) {
  final keyword = value.toLowerCase();
  if (keyword.contains('memory') ||
      keyword.contains('semiconductor') ||
      keyword.contains('chip') ||
      keyword.contains('nand') ||
      keyword.contains('dram')) {
    return AppAssets.stockQuestionMemoryIcon;
  }
  if (keyword.contains('foundry') ||
      keyword.contains('fab') ||
      keyword.contains('manufactur')) {
    return AppAssets.stockQuestionFoundryIcon;
  }
  if (keyword.contains('ai') ||
      keyword.contains('data') ||
      keyword.contains('growth')) {
    return AppAssets.stockQuestionAiIcon;
  }
  if (keyword.contains('ecosystem') ||
      keyword.contains('platform') ||
      keyword.contains('consumer')) {
    return AppAssets.stockQuestionEcosystemIcon;
  }
  return [
    AppAssets.stockQuestionMemoryIcon,
    AppAssets.stockQuestionFoundryIcon,
    AppAssets.stockQuestionEcosystemIcon,
    AppAssets.stockQuestionAiIcon,
  ][index % 4];
}

bool _isKnownTicker(String ticker, List<String> values) {
  return values.contains(ticker.trim().toUpperCase());
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
  return 'Global peer analysis is being prepared from the latest stock data.';
}

List<String> _globalPeerTags(GlobalPeerMatch match) {
  final values = <String>[
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
