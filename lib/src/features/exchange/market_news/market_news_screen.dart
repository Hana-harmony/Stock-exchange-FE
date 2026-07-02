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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(widget.marketNewsController.loadLatest(limit: 20));
      }
    });
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
            key: const ValueKey('discover-market-news-list'),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            itemCount: news.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              return _MarketNewsCard(item: news[index]);
            },
          ),
        );
      },
    );
  }
}

class _MarketNewsCard extends StatelessWidget {
  const _MarketNewsCard({required this.item});

  final MarketNewsItem item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StockNewsImage(
              imageUrl: item.imageUrl,
              width: 82,
              height: 82,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _StockNewsTargetBadge(
                        label: item.displayQuery,
                      ),
                      const Spacer(),
                      Text(
                        _relativeTimeLabel(item.publishedAt ?? item.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray1000,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.displaySummary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.gray700,
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
