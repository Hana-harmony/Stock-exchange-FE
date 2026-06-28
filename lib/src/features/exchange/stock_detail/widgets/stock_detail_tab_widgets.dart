part of '../../exchange_pages.dart';

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
