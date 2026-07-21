part of '../exchange_pages.dart';

class MarketNewsDetailScreen extends StatefulWidget {
  const MarketNewsDetailScreen({
    super.key,
    required this.item,
    required this.marketNewsController,
  });

  final MarketNewsItem item;
  final MarketNewsController marketNewsController;

  @override
  State<MarketNewsDetailScreen> createState() => _MarketNewsDetailScreenState();
}

class _MarketNewsDetailScreenState extends State<MarketNewsDetailScreen> {
  final GlobalKey _articleContentStackKey = GlobalKey();
  final GlobalKey _glossaryTooltipKey = GlobalKey();
  Timer? _glossaryTooltipTimer;
  _VisibleNotificationArticleGlossaryTooltip? _visibleGlossaryTooltip;
  late MarketNewsItem _resolvedItem;

  @override
  void initState() {
    super.initState();
    _resolvedItem = widget.item;
    unawaited(_refreshDetailOnce());
  }

  @override
  void dispose() {
    _glossaryTooltipTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshDetailOnce() async {
    if (widget.item.newsId.isEmpty) {
      return;
    }
    try {
      final latest = await widget.marketNewsController.loadDetail(
        widget.item.newsId,
      );
      if (mounted && latest.displayBody.isNotEmpty) {
        setState(() => _resolvedItem = latest);
      }
    } on Object {
      // 목록의 번역 전문을 유지한다.
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _NotificationArticleDetailData.fromMarketNews(_resolvedItem);
    return Scaffold(
      key: const ValueKey('market-news-detail-screen'),
      backgroundColor: AppColors.white,
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _handlePointerDown,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _NotificationArticleDetailHeader(
                onBack: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: Stack(
                  children: [
                    NotificationListener<ScrollStartNotification>(
                      onNotification: (notification) {
                        _dismissGlossaryTooltip();
                        return false;
                      },
                      child: SingleChildScrollView(
                        key: const ValueKey('market-news-detail-scroll'),
                        padding: const EdgeInsets.only(bottom: 140),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              key: _articleContentStackKey,
                              clipBehavior: Clip.none,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _NotificationArticleHeroImage(
                                      imageUrl: detail.imageUrl,
                                    ),
                                    const SizedBox(height: 20),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: _NotificationArticleSummarySection(
                                        detail: detail,
                                        articleContentStackKey:
                                            _articleContentStackKey,
                                        onGlossaryTap: _showGlossaryTooltip,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: _NotificationArticleAnalysisCard(
                                        detail: detail,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: _NotificationArticleBody(
                                        detail: detail,
                                        articleContentStackKey:
                                            _articleContentStackKey,
                                        onGlossaryTap: _showGlossaryTooltip,
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                  ],
                                ),
                                if (_visibleGlossaryTooltip != null)
                                  _NotificationArticleGlossaryTooltipOverlay(
                                    key: _glossaryTooltipKey,
                                    glossary: _visibleGlossaryTooltip!.glossary,
                                    anchorRect:
                                        _visibleGlossaryTooltip!.anchorRect,
                                    maxWidth: constraints.maxWidth,
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: _NotificationArticleBottomActionBar(
                        onPressed: () {
                          unawaited(
                            _openOriginalArticleUrl(context, detail),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGlossaryTooltip(
    _NotificationArticleGlossaryEntry glossary,
    Rect anchorRect,
  ) {
    _glossaryTooltipTimer?.cancel();
    setState(() {
      _visibleGlossaryTooltip = _VisibleNotificationArticleGlossaryTooltip(
        glossary: glossary,
        anchorRect: anchorRect,
      );
    });
    _glossaryTooltipTimer = Timer(
      const Duration(seconds: 10),
      _dismissGlossaryTooltip,
    );
    unawaited(
      widget.marketNewsController
          .recordTermClick(term: glossary.highlightedText, item: widget.item)
          .catchError((Object _) {}),
    );
  }

  void _dismissGlossaryTooltip() {
    _glossaryTooltipTimer?.cancel();
    _glossaryTooltipTimer = null;
    if (_visibleGlossaryTooltip == null || !mounted) {
      return;
    }
    setState(() {
      _visibleGlossaryTooltip = null;
    });
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_visibleGlossaryTooltip == null) {
      return;
    }
    final tooltipContext = _glossaryTooltipKey.currentContext;
    final tooltipBox = tooltipContext?.findRenderObject() as RenderBox?;
    if (tooltipBox == null || !tooltipBox.hasSize) {
      _dismissGlossaryTooltip();
      return;
    }
    final tooltipRect = tooltipBox.localToGlobal(Offset.zero) & tooltipBox.size;
    if (tooltipRect.contains(event.position)) {
      return;
    }
    _dismissGlossaryTooltip();
  }
}
