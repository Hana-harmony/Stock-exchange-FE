part of '../exchange_pages.dart';

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

  final StockSearchRankingItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.medium),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 44,
              child: Center(
                child: Transform.scale(
                  scale: 44 / 34,
                  child: _SearchResultAvatar(
                    stockCode: item.stockCode,
                    stockName: item.stockName,
                    logoUrl: item.logoUrl,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.stockCode,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.stockName,
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
                Text(
                  '#${item.rank == 0 ? '-' : item.rank}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.orange500,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.searchCount} opens',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w400,
                        color: AppColors.gray600,
                      ),
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
    required this.onTap,
  });

  final int rank;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
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
              _SearchResultAvatar(
                stockCode: item.stockCode,
                stockName: item.stockName,
                logoUrl: item.logoUrl,
              ),
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
