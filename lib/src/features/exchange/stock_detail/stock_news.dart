part of '../exchange_pages.dart';

enum _StockNewsLayout {
  list,
  grid,
}

class _StockNewsTab extends StatefulWidget {
  const _StockNewsTab({
    required this.notificationController,
    required this.accountId,
    required this.stockCode,
    required this.stockName,
  });

  final NotificationController notificationController;
  final String? accountId;
  final String stockCode;
  final String stockName;

  @override
  State<_StockNewsTab> createState() => _StockNewsTabState();
}

class _StockNewsTabState extends State<_StockNewsTab> {
  static const _layoutTransitionDuration = Duration(milliseconds: 240);

  _StockNewsLayout _layout = _StockNewsLayout.list;

  @override
  void initState() {
    super.initState();
    widget.notificationController.loadAlerts(
      accountId: widget.accountId,
      stockCode: widget.stockCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.notificationController,
      builder: (context, _) {
        final state = widget.notificationController.value;
        final items = _resolveNewsItems(state);

        return ListView(
          key: const PageStorageKey<String>('stock-k-news-tab'),
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 140),
          children: [
            _StockNewsToolbar(
              layout: _layout,
              onLayoutChanged: (layout) {
                setState(() {
                  _layout = layout;
                });
              },
            ),
            AnimatedSwitcher(
              duration: _layoutTransitionDuration,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final beginOffset = _layout == _StockNewsLayout.list
                    ? const Offset(-0.03, 0)
                    : const Offset(0.03, 0);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: beginOffset,
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _StockNewsContent(
                key: ValueKey<String>('stock-news-content-${_layout.name}'),
                status: state.status,
                items: items,
                layout: _layout,
                stockName: widget.stockName,
              ),
            ),
          ],
        );
      },
    );
  }

  List<_StockNewsItemViewModel> _resolveNewsItems(NotificationState state) {
    final feedItems = state.feed?.items ?? const <StockIntelligenceItem>[];
    if (feedItems.isNotEmpty) {
      return feedItems
          .map(
            (item) => _StockNewsItemViewModel.fromFeedItem(
              item,
              fallbackCompanyLabel: _companyLabel(widget.stockName),
            ),
          )
          .toList();
    }

    return _StockNewsItemViewModel.fallbackItems(widget.stockName);
  }
}

class _StockNewsContent extends StatelessWidget {
  const _StockNewsContent({
    super.key,
    required this.status,
    required this.items,
    required this.layout,
    required this.stockName,
  });

  final NotificationStatus status;
  final List<_StockNewsItemViewModel> items;
  final _StockNewsLayout layout;
  final String stockName;

  @override
  Widget build(BuildContext context) {
    if (status == NotificationStatus.loading && items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: _MutedInfoCard(
          title: 'Loading K-News',
          body: 'The latest stock intelligence feed is being prepared.',
        ),
      );
    }

    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: _MutedInfoCard(
          title: 'No K-News',
          body: 'There are no related intelligence items for this stock yet.',
        ),
      );
    }

    final children = layout == _StockNewsLayout.list
        ? items
            .map(
              (item) => _StockNewsListTile(
                item: item,
                companyLabel: _companyLabel(stockName),
              ),
            )
            .toList()
        : items
            .map(
              (item) => _StockNewsCard(
                item: item,
              ),
            )
            .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

class _StockNewsToolbar extends StatelessWidget {
  const _StockNewsToolbar({
    required this.layout,
    required this.onLayoutChanged,
  });

  final _StockNewsLayout layout;
  final ValueChanged<_StockNewsLayout> onLayoutChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 2),
      child: Row(
        children: [
          InkWell(
            key: const ValueKey('stock-news-sort-button'),
            onTap: () {},
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Newest',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray900,
                        ),
                  ),
                  const SizedBox(width: 4),
                  Image.asset(
                    AppAssets.dropdownIcon,
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StockNewsLayoutButton(
                    key: const ValueKey('stock-news-layout-list'),
                    label: 'List',
                    iconAsset: layout == _StockNewsLayout.list
                        ? AppAssets.listIconActive
                        : AppAssets.listIcon,
                    isSelected: layout == _StockNewsLayout.list,
                    onTap: () => onLayoutChanged(_StockNewsLayout.list),
                  ),
                  const SizedBox(width: 2),
                  _StockNewsLayoutButton(
                    key: const ValueKey('stock-news-layout-grid'),
                    label: 'Card',
                    iconAsset: layout == _StockNewsLayout.grid
                        ? AppAssets.gridIconActive
                        : AppAssets.gridIcon,
                    isSelected: layout == _StockNewsLayout.grid,
                    onTap: () => onLayoutChanged(_StockNewsLayout.grid),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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

class _StockNewsPriorityBadgeConfig {
  const _StockNewsPriorityBadgeConfig({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.dotColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color dotColor;
}

enum _StockNewsSentiment {
  positive,
  negative,
}

enum _StockNewsPriority {
  high,
  medium,
  low,
}

class _StockNewsSummaryRowData {
  const _StockNewsSummaryRowData({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class _StockNewsItemViewModel {
  const _StockNewsItemViewModel({
    required this.title,
    required this.imageUrl,
    required this.sentiment,
    required this.priority,
    required this.targetLabel,
    required this.showTargetBadge,
    required this.relativeTimeLabel,
    required this.summaryRows,
  });

  final String title;
  final String? imageUrl;
  final _StockNewsSentiment sentiment;
  final _StockNewsPriority priority;
  final String targetLabel;
  final bool showTargetBadge;
  final String relativeTimeLabel;
  final List<_StockNewsSummaryRowData> summaryRows;

  factory _StockNewsItemViewModel.fromFeedItem(
    StockIntelligenceItem item, {
    required String fallbackCompanyLabel,
  }) {
    final rows = <_StockNewsSummaryRowData>[
      if (item.summaryLines.what.isNotEmpty)
        _StockNewsSummaryRowData(
          label: 'What',
          value: item.summaryLines.what,
        ),
      if (item.summaryLines.why.isNotEmpty)
        _StockNewsSummaryRowData(
          label: 'Why',
          value: item.summaryLines.why,
        ),
      if (item.summaryLines.impact.isNotEmpty)
        _StockNewsSummaryRowData(
          label: 'Impact',
          value: item.summaryLines.impact,
        ),
    ];

    return _StockNewsItemViewModel(
      title: item.title,
      imageUrl: item.imageUrls.isEmpty ? null : item.imageUrls.first,
      sentiment: _sentimentFromString(item.sentiment),
      priority: _priorityFromStrings(item.importance, item.riskLevel),
      targetLabel: item.targetLabel,
      showTargetBadge: item.holderTarget,
      relativeTimeLabel:
          _relativeTimeLabel(item.publishedAt ?? item.receivedAt),
      summaryRows: rows.isEmpty
          ? [
              _StockNewsSummaryRowData(
                label: 'What',
                value: item.translatedSummary.isNotEmpty
                    ? item.translatedSummary
                    : fallbackCompanyLabel,
              ),
            ]
          : rows,
    );
  }

  static List<_StockNewsItemViewModel> fallbackItems(String stockName) {
    final companyLabel = _companyLabel(stockName);
    return [
      _StockNewsItemViewModel(
        title:
            'SAMSUNG ELEC: Dividend Payout Confirmed for FY2025 SAMSUNG ELEC: Dividend Payout Confirmed for FY2025',
        imageUrl: null,
        sentiment: _StockNewsSentiment.positive,
        priority: _StockNewsPriority.high,
        targetLabel: 'Watchlist',
        showTargetBadge: false,
        relativeTimeLabel: '1h ago',
        summaryRows: const [
          _StockNewsSummaryRowData(
            label: 'What',
            value:
                'SAMSUNG ELEC: Dividend Payout Confirmed for FY2025 AMSUNG ELEC: Dividend Payout...',
          ),
          _StockNewsSummaryRowData(
            label: 'Why',
            value:
                'SAMSUNG ELEC: Dividend Payout Confirmed for FY2025 AMSUNG ELEC: Dividend Payout...',
          ),
          _StockNewsSummaryRowData(
            label: 'Impact',
            value:
                'SAMSUNG ELEC: Dividend Payout Confirmed for FY2025 AMSUNG ELEC: Dividend Payout...',
          ),
        ],
      ),
      _StockNewsItemViewModel(
        title:
            'SAMSUNG ELEC: Dividend Payout Confirmed for FY2025 SAMSUNG ELEC: Dividend Payout Confirmed for FY2025',
        imageUrl: null,
        sentiment: _StockNewsSentiment.positive,
        priority: _StockNewsPriority.high,
        targetLabel: 'My Portfolio',
        showTargetBadge: true,
        relativeTimeLabel: '53m ago',
        summaryRows: const [
          _StockNewsSummaryRowData(
            label: 'What',
            value:
                'SAMSUNG ELEC: Dividend Payout Confirmed for FY2025 AMSUNG ELEC: Dividend Payout...',
          ),
          _StockNewsSummaryRowData(
            label: 'Why',
            value:
                'SAMSUNG ELEC: Dividend Payout Confirmed for FY2025 AMSUNG ELEC: Dividend Payout...',
          ),
          _StockNewsSummaryRowData(
            label: 'Impact',
            value:
                'SAMSUNG ELEC: Dividend Payout Confirmed for FY2025 AMSUNG ELEC: Dividend Payout...',
          ),
        ],
      ),
      _StockNewsItemViewModel(
        title:
            'SAMSUNG ELEC: Dividend Payout Confirmed for FY2025 SAMSUNG ELEC: Dividend Payout Confirmed for FY2025',
        imageUrl: null,
        sentiment: _StockNewsSentiment.positive,
        priority: _StockNewsPriority.high,
        targetLabel: companyLabel,
        showTargetBadge: false,
        relativeTimeLabel: '1h ago',
        summaryRows: const [
          _StockNewsSummaryRowData(
            label: 'What',
            value:
                'SAMSUNG ELEC: Dividend Payout Confirmed for FY2025 AMSUNG ELEC: Dividend Payout...',
          ),
          _StockNewsSummaryRowData(
            label: 'Why',
            value:
                'SAMSUNG ELEC: Dividend Payout Confirmed for FY2025 AMSUNG ELEC: Dividend Payout...',
          ),
          _StockNewsSummaryRowData(
            label: 'Impact',
            value:
                'SAMSUNG ELEC: Dividend Payout Confirmed for FY2025 AMSUNG ELEC: Dividend Payout...',
          ),
        ],
      ),
      _StockNewsItemViewModel(
        title:
            'SAMSUNG ELEC: Dividend Payout Confirmed for FY2025 SAMSUNG ELEC: Dividend Payout Confirmed for FY2025',
        imageUrl: null,
        sentiment: _StockNewsSentiment.positive,
        priority: _StockNewsPriority.high,
        targetLabel: companyLabel,
        showTargetBadge: false,
        relativeTimeLabel: '1h ago',
        summaryRows: const [
          _StockNewsSummaryRowData(
            label: 'What',
            value:
                'SAMSUNG ELEC: Dividend Payout Confirmed for FY2025 AMSUNG ELEC: Dividend Payout...',
          ),
          _StockNewsSummaryRowData(
            label: 'Why',
            value:
                'SAMSUNG ELEC: Dividend Payout Confirmed for FY2025 AMSUNG ELEC: Dividend Payout...',
          ),
          _StockNewsSummaryRowData(
            label: 'Impact',
            value:
                'SAMSUNG ELEC: Dividend Payout Confirmed for FY2025 AMSUNG ELEC: Dividend Payout...',
          ),
        ],
      ),
    ];
  }
}

_StockNewsSentiment _sentimentFromString(String value) {
  return value.toUpperCase() == 'NEGATIVE'
      ? _StockNewsSentiment.negative
      : _StockNewsSentiment.positive;
}

_StockNewsPriority _priorityFromStrings(String importance, String riskLevel) {
  final normalizedImportance = importance.toUpperCase();
  if (normalizedImportance == 'HIGH') {
    return _StockNewsPriority.high;
  }
  if (normalizedImportance == 'MEDIUM') {
    return _StockNewsPriority.medium;
  }
  if (normalizedImportance == 'LOW') {
    return _StockNewsPriority.low;
  }

  return switch (riskLevel.toUpperCase()) {
    'HIGH' => _StockNewsPriority.high,
    'MEDIUM' => _StockNewsPriority.medium,
    _ => _StockNewsPriority.low,
  };
}
