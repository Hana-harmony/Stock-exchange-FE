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
                title: 'Market news unavailable',
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
            padding: const EdgeInsets.only(bottom: 120),
            itemCount: news.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.gray100,
            ),
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
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 124,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: _StockNewsTargetBadge(
                              label: item.displayQuery,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _StockNewsSentimentBadge(
                            sentiment: _sentimentFromString(item.sentiment),
                          ),
                          const SizedBox(width: 6),
                          _StockNewsPriorityBadge(
                            priority: _priorityFromStrings(
                              item.importance,
                              '',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.displayTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: 16,
                                  height: 1.4,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.gray1000,
                                ),
                      ),
                      const Spacer(),
                      Text(
                        '${_marketNewsSourceLabel(item.originalUrl)} · '
                        '${_relativeTimeLabel(item.publishedAt ?? item.createdAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              height: 1.4,
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
          ),
        ),
      ),
    );
  }
}

String _marketNewsSourceLabel(String rawUrl) {
  final uri = Uri.tryParse(rawUrl.trim());
  final host = uri?.host.toLowerCase() ?? '';
  if (host.isEmpty) {
    return 'K-News';
  }
  return host.startsWith('www.') ? host.substring(4) : host;
}
