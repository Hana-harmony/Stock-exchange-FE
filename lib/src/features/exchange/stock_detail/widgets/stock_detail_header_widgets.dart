part of '../../exchange_pages.dart';

class _StockDetailHeader extends StatelessWidget {
  const _StockDetailHeader({
    required this.snapshot,
    required this.showCompactTitle,
    required this.isFavorite,
    required this.onBack,
    required this.onSearch,
    required this.onFavorite,
    this.showCompactChange = true,
    this.showBottomBorder = true,
  });

  final _StockDetailSnapshot snapshot;
  final bool showCompactTitle;
  final bool isFavorite;
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onFavorite;
  final bool showCompactChange;
  final bool showBottomBorder;

  @override
  Widget build(BuildContext context) {
    final priceColor =
        snapshot.isPositive ? AppColors.green500 : AppColors.red500;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: showBottomBorder && showCompactTitle
                ? AppColors.gray200
                : Colors.transparent,
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
                  child: showCompactChange
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              snapshot.stockName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
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
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontSize: 14,
                                    height: 1,
                                    fontWeight: FontWeight.w500,
                                    color: priceColor,
                                  ),
                            ),
                          ],
                        )
                      : Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            snapshot.stockName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontSize: 17,
                                  height: 1,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
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
                                const WidgetSpan(child: SizedBox(width: 6)),
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
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: AppColors.gray1000,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
