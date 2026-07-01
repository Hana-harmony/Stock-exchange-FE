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
                            child: _StockOverviewSection(
                              snapshot: snapshot,
                              onQuestionTap: _showQuestionInfoSheet,
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

  Future<void> _showQuestionInfoSheet() {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Stock question info',
      barrierColor: const Color.fromRGBO(0, 0, 0, 0.5),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const _StockQuestionInfoSheetDialog();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
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

enum _StockQuestionSheetStage {
  preview(290),
  expanded(566),
  full(816);

  const _StockQuestionSheetStage(this.sheetHeight);

  final double sheetHeight;
}

class _StockQuestionInfoSheetDialog extends StatefulWidget {
  const _StockQuestionInfoSheetDialog();

  @override
  State<_StockQuestionInfoSheetDialog> createState() =>
      _StockQuestionInfoSheetDialogState();
}

class _StockQuestionInfoSheetDialogState
    extends State<_StockQuestionInfoSheetDialog> {
  late final DraggableScrollableController _sheetController;
  double _currentExtent = 0;
  double _previewExtent = 0;
  double _expandedExtent = 0;
  double _fullExtent = 0;

  @override
  void initState() {
    super.initState();
    _sheetController = DraggableScrollableController();
  }

  double _extentForHeight(double height, double viewportHeight) {
    return (height / viewportHeight).clamp(0.24, 0.96);
  }

  _StockQuestionSheetStage _resolveStage(double extent) {
    final previewThreshold = (_previewExtent + _expandedExtent) / 2;
    final expandedThreshold = (_expandedExtent + _fullExtent) / 2;
    if (extent < previewThreshold) {
      return _StockQuestionSheetStage.preview;
    }
    if (extent < expandedThreshold) {
      return _StockQuestionSheetStage.expanded;
    }
    return _StockQuestionSheetStage.full;
  }

  double _nearestSnapExtent(double extent, double velocity) {
    if (velocity <= -400) {
      return extent < _expandedExtent ? _expandedExtent : _fullExtent;
    }
    if (velocity >= 400) {
      return extent > _expandedExtent ? _expandedExtent : _previewExtent;
    }

    final extents = [_previewExtent, _expandedExtent, _fullExtent];
    return extents.reduce(
      (best, candidate) =>
          (extent - candidate).abs() < (extent - best).abs() ? candidate : best,
    );
  }

  void _handleHeaderDragUpdate(
      DragUpdateDetails details, double viewportHeight) {
    if (!_sheetController.isAttached) {
      return;
    }
    final nextExtent =
        (_sheetController.size - ((details.primaryDelta ?? 0) / viewportHeight))
            .clamp(_previewExtent, _fullExtent);
    _sheetController.jumpTo(nextExtent);
  }

  Future<void> _handleHeaderDragEnd(DragEndDetails details) async {
    if (!_sheetController.isAttached) {
      return;
    }
    final velocity = details.primaryVelocity ?? 0;
    if (velocity >= 900 && _sheetController.size <= _previewExtent + 0.01) {
      Navigator.of(context).pop();
      return;
    }

    await _sheetController.animateTo(
      _nearestSnapExtent(_sheetController.size, velocity),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.sizeOf(context).height;
    _previewExtent = _extentForHeight(
      _StockQuestionSheetStage.preview.sheetHeight,
      viewportHeight,
    );
    _expandedExtent = _extentForHeight(
      _StockQuestionSheetStage.expanded.sheetHeight,
      viewportHeight,
    );
    _fullExtent = _extentForHeight(
      _StockQuestionSheetStage.full.sheetHeight,
      viewportHeight,
    );
    _currentExtent = _currentExtent == 0 ? _previewExtent : _currentExtent;
    final currentStage = _resolveStage(_currentExtent);
    final comparisonProgress =
        ((_currentExtent - _previewExtent) / (_expandedExtent - _previewExtent))
            .clamp(0.0, 1.0);
    final strengthsProgress =
        ((_currentExtent - _expandedExtent) / (_fullExtent - _expandedExtent))
            .clamp(0.0, 1.0);
    final hintOpacity = (1 - comparisonProgress).clamp(0.0, 1.0);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              key: const ValueKey('stock-question-sheet-dim'),
              onTap: () => Navigator.of(context).pop(),
              child: const SizedBox.expand(),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                final nextExtent = notification.extent;
                if ((nextExtent - _currentExtent).abs() < 0.0001) {
                  return false;
                }
                setState(() {
                  _currentExtent = nextExtent;
                });
                return false;
              },
              child: DraggableScrollableSheet(
                controller: _sheetController,
                expand: false,
                initialChildSize: _previewExtent,
                minChildSize: _previewExtent,
                maxChildSize: _fullExtent,
                snap: true,
                snapSizes: [_previewExtent, _expandedExtent, _fullExtent],
                builder: (context, scrollController) {
                  return DecoratedBox(
                    key: ValueKey('stock-question-sheet-${currentStage.name}'),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.05),
                          blurRadius: 20,
                          offset: Offset(4, 0),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          GestureDetector(
                            key: const ValueKey('stock-question-sheet-gesture'),
                            behavior: HitTestBehavior.opaque,
                            onVerticalDragUpdate: (details) =>
                                _handleHeaderDragUpdate(
                                    details, viewportHeight),
                            onVerticalDragEnd: _handleHeaderDragEnd,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: _StockQuestionSheetHandle(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _StockQuestionSheetBody(
                              scrollController: scrollController,
                              hintOpacity: hintOpacity,
                              comparisonProgress: comparisonProgress,
                              strengthsProgress: strengthsProgress,
                            ),
                          ),
                          const _StockHomeBar(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockQuestionSheetHandle extends StatelessWidget {
  const _StockQuestionSheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.gray300,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _StockQuestionSheetBody extends StatelessWidget {
  const _StockQuestionSheetBody({
    required this.scrollController,
    required this.hintOpacity,
    required this.comparisonProgress,
    required this.strengthsProgress,
  });

  final ScrollController scrollController;
  final double hintOpacity;
  final double comparisonProgress;
  final double strengthsProgress;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: scrollController,
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _StockQuestionOverviewContent(),
                const SizedBox(height: 12),
                Opacity(
                  key:
                      const ValueKey('stock-question-sheet-swipe-hint-opacity'),
                  opacity: Curves.easeOut.transform(hintOpacity),
                  child: const Text(
                    '↑ Swipe up for more details',
                    key: ValueKey('stock-question-sheet-swipe-hint'),
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFBABABA),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _StockQuestionRevealSection(
                  key:
                      const ValueKey('stock-question-sheet-comparison-opacity'),
                  progress: comparisonProgress,
                  child: const _StockQuestionComparisonSection(),
                ),
                const SizedBox(height: 20),
                _StockQuestionRevealSection(
                  key: const ValueKey('stock-question-sheet-strengths-opacity'),
                  progress: strengthsProgress,
                  child: const _StockQuestionKeyStrengthsSection(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StockQuestionRevealSection extends StatelessWidget {
  const _StockQuestionRevealSection({
    super.key,
    required this.progress,
    required this.child,
  });

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final easedProgress = Curves.easeOutCubic.transform(progress);
    return Transform.translate(
      offset: Offset(0, (1 - easedProgress) * 16),
      child: Opacity(
        opacity: easedProgress,
        child: child,
      ),
    );
  }
}

class _StockQuestionOverviewContent extends StatelessWidget {
  const _StockQuestionOverviewContent();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 370,
      height: 186,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 50,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          AppAssets.stockQuestionSamsung,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 291,
                        height: 50,
                        child: FittedBox(
                          alignment: Alignment.topLeft,
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: 291,
                            height: 50,
                            child: Text(
                              'Samsung Electronics Is\nThe ‘Apple + TSMC’ of South Korea',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontSize: 18,
                                    height: 1.4,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.gray1000,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    _StockQuestionHashtagChip(
                      label: '#Semiconductors',
                      width: 125,
                    ),
                    SizedBox(width: 6),
                    _StockQuestionHashtagChip(
                      label: '#Consumer Electronics',
                      width: 159,
                    ),
                    SizedBox(width: 6),
                    _StockQuestionHashtagChip(
                      label: '#AI',
                      width: 37,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 340,
            height: 80,
            child: FittedBox(
              alignment: Alignment.topLeft,
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: 340,
                height: 80,
                child: Text(
                  'Samsung Electronics combines Apple’s consumer ecosystem with TSMC’s semiconductor strength, making it a global technology leader in devices, chips, and AI infrastructure.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gray700,
                        letterSpacing: -0.28,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockQuestionHashtagChip extends StatelessWidget {
  const _StockQuestionHashtagChip({
    required this.label,
    required this.width,
  });

  final String label;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 28,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: AppColors.gray750,
              letterSpacing: -0.28,
            ),
      ),
    );
  }
}

class _StockQuestionComparisonSection extends StatelessWidget {
  const _StockQuestionComparisonSection();

  static const List<_StockQuestionComparisonItem> _items = [
    _StockQuestionComparisonItem(
      category: 'Overall Business',
      company: 'Apple',
      assetPath: AppAssets.stockQuestionComparisonApple,
      description:
          'A rare combination of leading consumer electroncis and world-calss chip manufacturing.',
    ),
    _StockQuestionComparisonItem(
      category: 'Semiconductor(DS)',
      company: 'Intel',
      assetPath: AppAssets.stockQuestionComparisonIntel,
      description:
          'A memory and logic chip leader powering AI servers, PCs, and smartphones.',
    ),
    _StockQuestionComparisonItem(
      category: 'Foundry',
      company: 'TSMC',
      assetPath: AppAssets.stockQuestionComparisonTsmc,
      description:
          'Advanced foundry capabilities supporting global fabless chip comparies.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('stock-question-sheet-comparison'),
      width: 370,
      height: 290,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Global Comparison',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray1000,
                  letterSpacing: -0.28,
                ),
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < _items.length; index++) ...[
            _StockQuestionComparisonCard(item: _items[index]),
            if (index < _items.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _StockQuestionComparisonCard extends StatelessWidget {
  const _StockQuestionComparisonCard({
    required this.item,
  });

  final _StockQuestionComparisonItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 370,
      height: 82,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray300),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                item.assetPath,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 58,
              child: FittedBox(
                alignment: Alignment.topLeft,
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: 278,
                  height: 58,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${item.category} ',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    fontSize: 14,
                                    height: 1.4,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.gray1000,
                                    letterSpacing: -0.28,
                                  ),
                            ),
                            TextSpan(
                              text: item.company,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    fontSize: 14,
                                    height: 1.4,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.orange500,
                                    letterSpacing: -0.28,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: FontWeight.w400,
                              color: AppColors.gray700,
                              letterSpacing: -0.24,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockQuestionKeyStrengthsSection extends StatelessWidget {
  const _StockQuestionKeyStrengthsSection();

  static const List<_StockQuestionStrengthItem> _items = [
    _StockQuestionStrengthItem(
      iconAssetPath: AppAssets.stockQuestionMemoryIcon,
      title: 'in Memory',
      description: 'Global DRAM & NAND\nmarket leader',
    ),
    _StockQuestionStrengthItem(
      iconAssetPath: AppAssets.stockQuestionFoundryIcon,
      title: 'Advanced Foundry',
      description: '3nm GAA and beyond\ntechnology leadership',
    ),
    _StockQuestionStrengthItem(
      iconAssetPath: AppAssets.stockQuestionEcosystemIcon,
      title: 'Strong Ecosystem',
      description: 'Smartphones, TVs, home\nappliances & more',
    ),
    _StockQuestionStrengthItem(
      iconAssetPath: AppAssets.stockQuestionAiIcon,
      title: 'AI Growth Driver',
      description: 'Powering AI data centers\nand the next wave of tech',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('stock-question-sheet-strengths'),
      width: 370,
      height: 230,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key Strengths',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray1000,
                  letterSpacing: -0.28,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _items
                .map(
                  (item) => _StockQuestionStrengthCard(item: item),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _StockQuestionStrengthCard extends StatelessWidget {
  const _StockQuestionStrengthCard({
    required this.item,
  });

  final _StockQuestionStrengthItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 181,
      height: 97,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray300),
      ),
      child: Column(
        children: [
          Image.asset(
            item.iconAssetPath,
            width: 24,
            height: 24,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: FittedBox(
              alignment: Alignment.topCenter,
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: 157,
                height: 45,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                            color: AppColors.gray1000,
                            letterSpacing: -0.24,
                          ),
                    ),
                    Text(
                      item.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            height: 1.4,
                            fontWeight: FontWeight.w400,
                            color: AppColors.gray600,
                            letterSpacing: -0.2,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockQuestionComparisonItem {
  const _StockQuestionComparisonItem({
    required this.category,
    required this.company,
    required this.assetPath,
    required this.description,
  });

  final String category;
  final String company;
  final String assetPath;
  final String description;
}

class _StockQuestionStrengthItem {
  const _StockQuestionStrengthItem({
    required this.iconAssetPath,
    required this.title,
    required this.description,
  });

  final String iconAssetPath;
  final String title;
  final String description;
}
