part of '../../exchange_pages.dart';

class _StockNewsLayoutButton extends StatelessWidget {
  const _StockNewsLayoutButton({
    super.key,
    required this.label,
    required this.iconAsset,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String iconAsset;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.03),
                      blurRadius: 4,
                      offset: Offset(0, 4),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                iconAsset,
                width: 16,
                height: 16,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? AppColors.gray700 : AppColors.gray600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockNewsListTile extends StatelessWidget {
  const _StockNewsListTile({
    required this.item,
    required this.companyLabel,
  });

  final _StockNewsItemViewModel item;
  final String companyLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StockNewsSentimentBadge(sentiment: item.sentiment),
                    const SizedBox(width: 6),
                    _StockNewsPriorityBadge(priority: item.priority),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$companyLabel · ${item.relativeTimeLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w400,
                        color: AppColors.gray600,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          _StockNewsImage(
            imageUrl: item.imageUrl,
            width: 85,
            height: 85,
          ),
        ],
      ),
    );
  }
}

class _StockNewsCard extends StatelessWidget {
  const _StockNewsCard({
    required this.item,
  });

  final _StockNewsItemViewModel item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StockNewsImage(
            imageUrl: item.imageUrl,
            width: double.infinity,
            height: 160,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (item.showTargetBadge)
                      _StockNewsTargetBadge(label: item.targetLabel),
                    _StockNewsSentimentBadge(sentiment: item.sentiment),
                    _StockNewsPriorityBadge(priority: item.priority),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                item.relativeTimeLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                      color: AppColors.gray600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray800,
                ),
          ),
          const SizedBox(height: 8),
          ...item.summaryRows.map(_StockNewsSummaryRow.new),
        ],
      ),
    );
  }
}

class _StockNewsSummaryRow extends StatelessWidget {
  const _StockNewsSummaryRow(this.row);

  final _StockNewsSummaryRowData row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: AppColors.orange500,
                ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              row.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                    color: AppColors.gray700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockNewsImage extends StatelessWidget {
  const _StockNewsImage({
    required this.imageUrl,
    required this.width,
    required this.height,
  });

  final String? imageUrl;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: AppColors.surface),
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallbackImage(),
                )
              : _fallbackImage(),
        ),
      ),
    );
  }

  Widget _fallbackImage() {
    return Image.asset(
      AppAssets.noImageDefault,
      fit: BoxFit.cover,
    );
  }
}

class _StockNewsTargetBadge extends StatelessWidget {
  const _StockNewsTargetBadge({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontSize: 10,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: AppColors.gray700,
              ),
        ),
      ),
    );
  }
}

class _StockNewsSentimentBadge extends StatelessWidget {
  const _StockNewsSentimentBadge({
    required this.sentiment,
    this.fontSize = 10,
  });

  final _StockNewsSentiment sentiment;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final isPositive = sentiment == _StockNewsSentiment.positive;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isPositive ? AppColors.green100 : AppColors.red100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              isPositive ? AppAssets.chartUpMini : AppAssets.chartDownMini,
              width: 12,
              height: 12,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 4),
            Text(
              isPositive ? 'Positive' : 'Negative',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontSize: fontSize,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: isPositive ? AppColors.green500 : AppColors.red500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockNewsPriorityBadge extends StatelessWidget {
  const _StockNewsPriorityBadge({
    required this.priority,
    this.fontSize = 10,
  });

  final _StockNewsPriority priority;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final config = switch (priority) {
      _StockNewsPriority.high => _StockNewsPriorityBadgeConfig(
          label: 'High Priority',
          backgroundColor: AppColors.red100,
          foregroundColor: AppColors.red500,
          dotColor: AppColors.red500,
        ),
      _StockNewsPriority.medium => _StockNewsPriorityBadgeConfig(
          label: 'Medium Priority',
          backgroundColor: const Color(0xFFFFF4E8),
          foregroundColor: AppColors.orange500,
          dotColor: AppColors.orange500,
        ),
      _StockNewsPriority.low => _StockNewsPriorityBadgeConfig(
          label: 'Low Priority',
          backgroundColor: const Color(0xFFFFF8DB),
          foregroundColor: const Color(0xFFE8B100),
          dotColor: const Color(0xFFE8B100),
        ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: config.dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              config.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontSize: fontSize,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: config.foregroundColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
