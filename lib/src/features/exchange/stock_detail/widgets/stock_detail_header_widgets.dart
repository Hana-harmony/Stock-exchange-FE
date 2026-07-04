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
    this.compactTitleFontSize = 17,
    this.compactTitleLineHeight = 1,
    this.leadingTitleSpacing = 8,
  });

  final _StockDetailSnapshot snapshot;
  final bool showCompactTitle;
  final bool isFavorite;
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onFavorite;
  final bool showCompactChange;
  final bool showBottomBorder;
  final double compactTitleFontSize;
  final double compactTitleLineHeight;
  final double leadingTitleSpacing;

  @override
  Widget build(BuildContext context) {
    final priceColor =
        snapshot.isPositive ? AppColors.green500 : AppColors.red500;

    return DecoratedBox(
      key: const ValueKey('stock-detail-page-title'),
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
              SizedBox(width: leadingTitleSpacing),
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
                                    fontSize: compactTitleFontSize,
                                    height: compactTitleLineHeight,
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
                                  fontSize: compactTitleFontSize,
                                  height: compactTitleLineHeight,
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
                key: const ValueKey('stock-detail-favorite-button'),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Image.asset(
              assetPath,
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

String _compactMarketStatusLabel(String label) {
  const prefix = 'Market Closed ';
  if (!label.startsWith(prefix) || !label.endsWith(')')) {
    return label;
  }
  final openParenthesis = label.lastIndexOf('(');
  if (openParenthesis < 0) {
    return label;
  }
  final kstLabel = label.substring(openParenthesis + 1, label.length - 1);
  return '$prefix$kstLabel';
}

class _StockOverviewSection extends StatelessWidget {
  const _StockOverviewSection({
    required this.snapshot,
    required this.onQuestionTap,
  });

  static const double height = 214;

  final _StockDetailSnapshot snapshot;
  final VoidCallback onQuestionTap;

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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 21,
                          child: Row(
                            children: [
                              _MarketBadge(
                                  assetPath: snapshot.countryBadgeAsset),
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
                                child: Row(
                                  children: [
                                    Text(
                                      snapshot.stockCode,
                                      maxLines: 1,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontSize: 18,
                                            height: 1,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        snapshot.stockName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontSize: 18,
                                              height: 1,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      key: const ValueKey(
                                        'stock-detail-name-help-icon-button',
                                      ),
                                      onTap: onQuestionTap,
                                      child: Image.asset(
                                        AppAssets.questionIcon,
                                        key: const ValueKey(
                                          'stock-detail-name-help-icon',
                                        ),
                                        width: 24,
                                        height: 24,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 20,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: FittedBox(
                                    key: const ValueKey(
                                      'stock-detail-market-status-label',
                                    ),
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _compactMarketStatusLabel(
                                        snapshot.marketStatusLabel,
                                      ),
                                      maxLines: 1,
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
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox.square(
                    dimension: 44,
                    child: Center(
                      child: Transform.scale(
                        scale: 44 / 34,
                        child: _SearchResultAvatar(
                          stockCode: snapshot.stockCode,
                          stockName: snapshot.stockName,
                          logoUrl: snapshot.logoUrl,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 90,
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
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    snapshot.currentPrice,
                                    maxLines: 1,
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
                        Text(
                          snapshot.currentPriceKrwDisplay,
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 12,
                                    height: 16 / 12,
                                    color: AppColors.gray500,
                                  ),
                        ),
                        Text(
                          '${snapshot.changeAmount} ${snapshot.changeRate}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontSize: 18,
                                    height: 20 / 18,
                                    fontWeight: FontWeight.w400,
                                    color: priceColor,
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
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                maxLines: 1,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: AppColors.gray1000,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
