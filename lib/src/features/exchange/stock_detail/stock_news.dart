part of '../exchange_pages.dart';

enum _StockNewsLayout { list, grid }

class _StockNewsTab extends StatefulWidget {
  const _StockNewsTab({
    required this.notificationController,
    required this.stockCode,
    required this.stockName,
    required this.sourceType,
    required this.emptyTitle,
    required this.emptyBody,
  });

  final NotificationController notificationController;
  final String stockCode;
  final String stockName;
  final String sourceType;
  final String emptyTitle;
  final String emptyBody;

  @override
  State<_StockNewsTab> createState() => _StockNewsTabState();
}

class _StockNewsTabState extends State<_StockNewsTab> {
  static const _layoutTransitionDuration = Duration(milliseconds: 240);
  static const _minimumScrollableItemCount = 8;

  _StockNewsLayout _layout = _StockNewsLayout.list;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreNearEnd);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_loadStockIntelligenceFeed());
      }
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadMoreNearEnd)
      ..dispose();
    super.dispose();
  }

  void _loadMoreNearEnd() {
    if (_scrollController.position.extentAfter > 480) {
      return;
    }
    unawaited(widget.notificationController.loadMoreStockIntelligenceFeed(
      stockCode: widget.stockCode,
    ));
  }

  @override
  void didUpdateWidget(covariant _StockNewsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stockCode != widget.stockCode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_loadStockIntelligenceFeed());
        }
      });
    }
  }

  Future<void> _loadStockIntelligenceFeed() {
    return widget.notificationController.loadStockIntelligenceFeed(
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
        _loadUntilScrollable(state: state, itemCount: items.length);

        return ListView(
          controller: _scrollController,
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
                emptyTitle: widget.emptyTitle,
                emptyBody: widget.emptyBody,
                onOpen: _openStockNewsDetail,
              ),
            ),
          ],
        );
      },
    );
  }

  void _loadUntilScrollable({
    required NotificationState state,
    required int itemCount,
  }) {
    final feed = state.feed;
    if (state.status != NotificationStatus.loaded ||
        feed?.stockCode != widget.stockCode ||
        feed?.nextCursor == null ||
        itemCount >= _minimumScrollableItemCount) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(widget.notificationController.loadMoreStockIntelligenceFeed(
        stockCode: widget.stockCode,
      ));
    });
  }

  void _openStockNewsDetail(_StockNewsItemViewModel item) {
    final sourceItem = item.sourceItem;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => NotificationArticleDetailScreen(
          item: NotificationItem(
            notificationId: 'stock-detail-${sourceItem.eventId}',
            eventId: sourceItem.eventId,
            subjectType: 'STOCK',
            subjectId: widget.stockCode,
            sourceType: sourceItem.sourceType,
            title: sourceItem.title,
            summary: sourceItem.displaySummary,
            originalUrl: sourceItem.originalUrl,
            primaryStockCode: sourceItem.primaryStockCode.isNotEmpty
                ? sourceItem.primaryStockCode
                : widget.stockCode,
            imageUrls: sourceItem.imageUrls,
            sentiment: sourceItem.sentiment,
            importance: sourceItem.importance,
            matchedStockCodes: sourceItem.relatedStocks.isEmpty
                ? [widget.stockCode]
                : sourceItem.relatedStocks,
            matchReasons: sourceItem.holderTarget
                ? const ['HOLDER']
                : sourceItem.watchlistTarget
                    ? const ['WATCHLIST']
                    : const ['MARKET'],
            glossaryTerms: sourceItem.glossaryTerms,
            translationQualityFlags: sourceItem.translationQualityFlags,
            deliveryStatus: 'DELIVERED',
            deliveryProvider: 'OMNILENS',
            deliveryAttemptCount: 1,
            read: true,
            createdAt: sourceItem.receivedAt ?? sourceItem.publishedAt,
            deliveredAt: sourceItem.receivedAt ?? sourceItem.publishedAt,
          ),
          intelligenceItem: sourceItem,
        ),
      ),
    );
  }

  List<_StockNewsItemViewModel> _resolveNewsItems(NotificationState state) {
    final feedItems = state.feed?.items ?? const <StockIntelligenceItem>[];
    final sourceType = widget.sourceType.toUpperCase();
    final filtered = feedItems
        .where((item) => item.sourceType.toUpperCase() == sourceType)
        .toList(growable: false);
    if (filtered.isNotEmpty) {
      return filtered.map(_StockNewsItemViewModel.fromFeedItem).toList();
    }

    return const [];
  }
}

class _StockNewsContent extends StatelessWidget {
  const _StockNewsContent({
    super.key,
    required this.status,
    required this.items,
    required this.layout,
    required this.stockName,
    required this.emptyTitle,
    required this.emptyBody,
    required this.onOpen,
  });

  final NotificationStatus status;
  final List<_StockNewsItemViewModel> items;
  final _StockNewsLayout layout;
  final String stockName;
  final String emptyTitle;
  final String emptyBody;
  final ValueChanged<_StockNewsItemViewModel> onOpen;

  @override
  Widget build(BuildContext context) {
    if (status == NotificationStatus.loading && items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: _MutedInfoCard(
          title: 'Loading intelligence',
          body: 'The latest OmniLens stock intelligence feed is unavailable.',
        ),
      );
    }

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: _MutedInfoCard(
          title: emptyTitle,
          body: emptyBody,
        ),
      );
    }

    final children = layout == _StockNewsLayout.list
        ? items
            .map(
              (item) => _StockNewsListTile(
                item: item,
                companyLabel: _companyLabel(stockName),
                onTap: () => onOpen(item),
              ),
            )
            .toList()
        : items
            .map(
              (item) => _StockNewsCard(
                item: item,
                onTap: () => onOpen(item),
              ),
            )
            .toList();

    return Column(mainAxisSize: MainAxisSize.min, children: children);
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
