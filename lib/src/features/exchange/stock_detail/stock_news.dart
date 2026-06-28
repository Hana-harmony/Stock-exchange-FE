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
