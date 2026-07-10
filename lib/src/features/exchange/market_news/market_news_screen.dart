part of '../exchange_pages.dart';

class MarketNewsScreen extends StatefulWidget {
  const MarketNewsScreen({
    super.key,
    required this.marketNewsController,
  });

  final MarketNewsController marketNewsController;

  @override
  State<MarketNewsScreen> createState() => _MarketNewsScreenState();
}

class _MarketNewsScreenState extends State<MarketNewsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreNearEnd);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(widget.marketNewsController.loadLatest(limit: 20));
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
    unawaited(widget.marketNewsController.loadMore());
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.marketNewsController,
      builder: (context, _) {
        final state = widget.marketNewsController.value;
        final news = state.feed?.news ?? const <MarketNewsItem>[];

        if (state.status == MarketNewsStatus.loading && news.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
            children: const [
              _MutedInfoCard(
                title: 'Loading Korea market news',
                body:
                    'OmniLens is preparing the latest translated market news.',
              ),
            ],
          );
        }

        if (state.status == MarketNewsStatus.failure && news.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
            children: [
              _ErrorStateCard(
                message: state.errorMessage ?? 'Unable to load market news.',
                onRetry: () =>
                    widget.marketNewsController.loadLatest(limit: 20),
              ),
            ],
          );
        }

        if (news.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
            children: const [
              _MutedInfoCard(
                title: 'No market news',
                body: 'There are no translated Korea market news items yet.',
              ),
            ],
          );
        }

        return RefreshIndicator(
          color: AppColors.orange500,
          onRefresh: () => widget.marketNewsController.loadLatest(limit: 20),
          child: ListView.separated(
            controller: _scrollController,
            key: const ValueKey('discover-market-news-list'),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            itemCount: news.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final item = news[index];
              return _MarketNewsCard(
                item: item,
                onTap: () => _openMarketNewsDetail(item),
              );
            },
          ),
        );
      },
    );
  }

  void _openMarketNewsDetail(MarketNewsItem item) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MarketNewsDetailScreen(
          item: item,
          marketNewsController: widget.marketNewsController,
        ),
      ),
    );
  }
}

class _MarketNewsCard extends StatelessWidget {
  const _MarketNewsCard({
    required this.item,
    required this.onTap,
  });

  final MarketNewsItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: ValueKey('market-news-card-${item.newsId}'),
      color: AppColors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: _StockNewsTargetBadge(
                              label: item.displayQuery,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _relativeTimeLabel(
                              item.publishedAt ?? item.createdAt,
                            ),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 12,
                                      color: AppColors.gray600,
                                    ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.displayTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: 16,
                                  height: 1.35,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.gray1000,
                                ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _StockNewsSentimentBadge(
                            sentiment: _sentimentFromString(item.sentiment),
                          ),
                          _StockNewsPriorityBadge(
                            priority: _priorityFromStrings(item.importance, ''),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _StockNewsImage(
                  imageUrl: item.imageUrl,
                  width: 88,
                  height: 88,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
