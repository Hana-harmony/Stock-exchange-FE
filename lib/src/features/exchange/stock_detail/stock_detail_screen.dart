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
          onBuy: () => _handleTradeAction('Buy'),
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
          notificationController: widget.notificationController,
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

  void _handleTradeAction(String side) {
    if (_isLowLimitTriggered) {
      _showPriceLimitRestrictionDialog();
      return;
    }
    if (_showViBanner) {
      _showViRestrictionDialog();
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

class _StockDetailHeader extends StatelessWidget {
  const _StockDetailHeader({
    required this.snapshot,
    required this.showCompactTitle,
    required this.isFavorite,
    required this.onBack,
    required this.onSearch,
    required this.onFavorite,
  });

  final _StockDetailSnapshot snapshot;
  final bool showCompactTitle;
  final bool isFavorite;
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final priceColor =
        snapshot.isPositive ? AppColors.green500 : AppColors.red500;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: showCompactTitle ? AppColors.gray200 : Colors.transparent,
          ),
        ),
      ),
      child: SizedBox(
        height: 44,
        child: Padding(
          padding: _compactHeaderPadding,
          child: Row(
            children: [
              _HeaderIconButton(
                assetPath: AppAssets.backArrow,
                onTap: onBack,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedOpacity(
                  key: const ValueKey('stock-detail-collapsed-header'),
                  opacity: showCompactTitle ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        snapshot.stockName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 17,
                              height: 1,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${snapshot.changeAmount} ${snapshot.changeRate}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: 14,
                                  height: 1,
                                  fontWeight: FontWeight.w500,
                                  color: priceColor,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
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

  static const double height = 198;

  final _StockDetailSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final priceColor =
        snapshot.isPositive ? AppColors.green500 : AppColors.red500;

    return SizedBox(
      height: height,
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

class _AlertStatusBanner extends StatelessWidget {
  const _AlertStatusBanner({
    super.key,
    required this.iconAssetPath,
    required this.title,
    required this.description,
    required this.infoKey,
    required this.onInfoTap,
  });

  static const double height = 60;

  final String iconAssetPath;
  final String title;
  final String description;
  final Key infoKey;
  final VoidCallback onInfoTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: height),
      decoration: BoxDecoration(
        color: const Color(0xFF353A41),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Image.asset(
                      iconAssetPath,
                      width: 16,
                      height: 16,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                              color: AppColors.red500,
                            ),
                      ),
                    ),
                  ],
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w400,
                        color: AppColors.gray200,
                      ),
                ),
              ],
            ),
          ),
          InkWell(
            key: infoKey,
            onTap: onInfoTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                AppAssets.infoIcon,
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViTriggeredBanner extends StatelessWidget {
  const _ViTriggeredBanner({
    required this.onInfoTap,
  });

  final VoidCallback onInfoTap;

  @override
  Widget build(BuildContext context) {
    return _AlertStatusBanner(
      key: const ValueKey('vi-triggered-banner'),
      iconAssetPath: AppAssets.warningViIcon,
      title: 'VI triggered!',
      description: 'Trading may be temporarily halted.',
      infoKey: const ValueKey('vi-triggered-banner-info'),
      onInfoTap: onInfoTap,
    );
  }
}

class _LowLimitReachedBanner extends StatelessWidget {
  const _LowLimitReachedBanner({
    required this.onInfoTap,
  });

  final VoidCallback onInfoTap;

  @override
  Widget build(BuildContext context) {
    return _AlertStatusBanner(
      key: const ValueKey('low-limit-reached-banner'),
      iconAssetPath: AppAssets.chartDownMini,
      title: 'Lower limit reached!',
      description: 'Trading is limited at the daily price cap.',
      infoKey: const ValueKey('low-limit-reached-banner-info'),
      onInfoTap: onInfoTap,
    );
  }
}

class _ViInfoPanel extends StatelessWidget {
  const _ViInfoPanel();

  @override
  Widget build(BuildContext context) {
    return _StockAlertInfoPanelFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                AppAssets.warningViIcon,
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              Text(
                'VI triggered!',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.red500,
                      fontSize: 18,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Trading may be temporarily halted.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray900,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'VI is a temporary volatility interruption used to pause trading when price movement becomes too sharp.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w400,
                  color: AppColors.gray700,
                ),
          ),
        ],
      ),
    );
  }
}

class _LowLimitInfoPanel extends StatelessWidget {
  const _LowLimitInfoPanel();

  @override
  Widget build(BuildContext context) {
    return _StockAlertInfoPanelFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                AppAssets.chartDownMini,
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Lower limit reached!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.red500,
                        fontSize: 18,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Trading is limited at the daily price cap.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray900,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'The stock has reached its exchange-defined lower daily limit. Orders can still be placed, but executions are restricted around the capped price.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w400,
                  color: AppColors.gray700,
                ),
          ),
        ],
      ),
    );
  }
}

class _StockAlertInfoPanelFrame extends StatelessWidget {
  const _StockAlertInfoPanelFrame({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: _bottomSheetOuterPadding,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(_bottomSheetRadius),
          ),
          child: Padding(
            padding: _bottomSheetContentPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _BottomSheetDragHandle(),
                const SizedBox(height: 18),
                child,
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: _exchangePrimaryButtonStyle(
                      backgroundColor: AppColors.orange500,
                      padding: _secondaryActionPadding,
                    ),
                    child: const Text('확인'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomSheetDragHandle extends StatelessWidget {
  const _BottomSheetDragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.gray200,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _AlertRestrictionDialog extends StatelessWidget {
  const _AlertRestrictionDialog({
    required this.dialogKey,
    required this.confirmKey,
    required this.title,
    required this.description,
  });

  static const double _dialogWidth = 360;
  static const double _dialogHeight = 200;
  static const double _buttonHeight = 46;

  final Key dialogKey;
  final Key confirmKey;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 21),
          child: Container(
            key: dialogKey,
            width: _dialogWidth,
            height: _dialogHeight,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
            child: SizedBox(
              height: _dialogHeight - 48,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray1000,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 3,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          height: 1.4,
                          letterSpacing: -0.28,
                          fontWeight: FontWeight.w500,
                          color: AppColors.gray600,
                        ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: _buttonHeight,
                    child: FilledButton(
                      key: confirmKey,
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF1550),
                        foregroundColor: AppColors.white,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Confirm',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.white,
                              fontSize: 18,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ViRestrictionDialog extends StatelessWidget {
  const _ViRestrictionDialog();

  @override
  Widget build(BuildContext context) {
    return const _AlertRestrictionDialog(
      dialogKey: ValueKey('vi-restriction-dialog'),
      confirmKey: ValueKey('vi-restriction-confirm'),
      title: 'Volatility Interruption Triggered!',
      description: 'A VI has been triggered for this stock.\n'
          'Real-time executions are temporarily restricted, and\n'
          'orders will be processed through call auction trading.',
    );
  }
}

class _PriceLimitRestrictionDialog extends StatelessWidget {
  const _PriceLimitRestrictionDialog();

  @override
  Widget build(BuildContext context) {
    return const _AlertRestrictionDialog(
      dialogKey: ValueKey('price-limit-restriction-dialog'),
      confirmKey: ValueKey('price-limit-restriction-confirm'),
      title: 'Price Limit Reached!',
      description: 'This stock has reached the daily price limit.\n'
          'Orders may be delayed due to pending orders at the\n'
          'limit price.',
    );
  }
}

class _StockDetailTabs extends StatelessWidget {
  const _StockDetailTabs();

  static const double height = 51;

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
                          AppUnderlineTab(
                            key: const ValueKey('stock-detail-tab-order'),
                            label: 'Order',
                            width: 48,
                            isSelected: controller.index == 0,
                            onTap: () => controller.animateTo(0),
                          ),
                          const SizedBox(width: 18),
                          AppUnderlineTab(
                            key: const ValueKey('stock-detail-tab-chart'),
                            label: 'Chart',
                            width: 47,
                            isSelected: controller.index == 1,
                            onTap: () => controller.animateTo(1),
                          ),
                          const SizedBox(width: 18),
                          AppUnderlineTab(
                            key: const ValueKey(
                              'stock-detail-tab-fundamentals',
                            ),
                            label: 'Fundamentals',
                            width: 116,
                            isSelected: controller.index == 2,
                            onTap: () => controller.animateTo(2),
                          ),
                          const SizedBox(width: 18),
                          AppUnderlineTab(
                            key: const ValueKey('stock-detail-tab-k-news'),
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

class _StockDetailTabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => _StockDetailTabs.height;

  @override
  double get maxExtent => _StockDetailTabs.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: AppColors.white),
      child: _StockDetailTabs(),
    );
  }

  @override
  bool shouldRebuild(covariant _StockDetailTabsHeaderDelegate oldDelegate) {
    return false;
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
      key: const PageStorageKey<String>('stock-order-tab'),
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

class _StockChartTab extends StatelessWidget {
  const _StockChartTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey<String>('stock-chart-tab'),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 140),
      children: const [
        Column(
          key: ValueKey('stock-chart-content'),
          mainAxisSize: MainAxisSize.min,
          children: [
            _StockChartIllustration(assetPath: AppAssets.chartDetail1),
            _StockChartIllustration(assetPath: AppAssets.chartDetail2),
          ],
        ),
      ],
    );
  }
}

class _StockChartIllustration extends StatelessWidget {
  const _StockChartIllustration({
    required this.assetPath,
  });

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: double.infinity,
      fit: BoxFit.fitWidth,
      alignment: Alignment.topCenter,
    );
  }
}

class _StockFundamentalsTab extends StatelessWidget {
  const _StockFundamentalsTab({
    required this.isViTriggered,
    required this.isLowLimitTriggered,
    required this.onToggleVi,
    required this.onToggleLowLimit,
  });

  final bool isViTriggered;
  final bool isLowLimitTriggered;
  final VoidCallback onToggleVi;
  final VoidCallback onToggleLowLimit;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey<String>('stock-fundamentals-tab'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 140),
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const ValueKey('stock-fundamentals-trigger-vi'),
            onPressed: onToggleVi,
            style: _exchangePrimaryButtonStyle(
              backgroundColor:
                  isViTriggered ? AppColors.gray700 : AppColors.orange500,
            ),
            child: Text(isViTriggered ? 'VI발동 끄기' : 'VI발동 시키기'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const ValueKey('stock-fundamentals-trigger-low-limit'),
            onPressed: onToggleLowLimit,
            style: _exchangePrimaryButtonStyle(
              backgroundColor:
                  isLowLimitTriggered ? AppColors.gray700 : AppColors.orange500,
            ),
            child: Text(
              isLowLimitTriggered ? 'Low limit 발동 끄기' : 'Low limit 발동 시키기',
            ),
          ),
        ),
      ],
    );
  }
}
