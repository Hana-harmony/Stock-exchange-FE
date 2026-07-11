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
  late final Future<MarketNewsItem> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDetail();
  }

  @override
  void dispose() {
    _glossaryTooltipTimer?.cancel();
    super.dispose();
  }

  Future<MarketNewsItem> _loadDetail() async {
    if (widget.item.newsId.isEmpty) {
      throw const ExchangeApiException(
        status: 422,
        code: 'NEWS_DETAIL_ID_MISSING',
        message: 'The news detail identifier is missing.',
      );
    }
    return widget.marketNewsController.loadDetail(widget.item.newsId);
  }

  @override
  Widget build(BuildContext context) {
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
                child: FutureBuilder<MarketNewsItem>(
                  future: _detailFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.orange500,
                        ),
                      );
                    }
                    if (snapshot.hasError || snapshot.data == null) {
                      return const Padding(
                        padding: AppInsets.compactScreen,
                        child: _MutedInfoCard(
                          title: 'Unable to load article',
                          body: 'The translated article could not be loaded.',
                        ),
                      );
                    }
                    final item = snapshot.data!;
                    final detail =
                        _NotificationArticleDetailData.fromMarketNews(item);
                    return Stack(
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
                                          child:
                                              _NotificationArticleSummarySection(
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
                                          child:
                                              _NotificationArticleAnalysisCard(
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
                                        glossary:
                                            _visibleGlossaryTooltip!.glossary,
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
                    );
                  },
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
