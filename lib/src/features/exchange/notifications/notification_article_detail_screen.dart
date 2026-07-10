part of '../exchange_pages.dart';

class NotificationArticleDetailScreen extends StatefulWidget {
  const NotificationArticleDetailScreen({
    super.key,
    required this.item,
    this.intelligenceItem,
  });

  final NotificationItem item;
  final StockIntelligenceItem? intelligenceItem;

  @override
  State<NotificationArticleDetailScreen> createState() =>
      _NotificationArticleDetailScreenState();
}

class _NotificationArticleDetailScreenState
    extends State<NotificationArticleDetailScreen> {
  final GlobalKey _articleContentStackKey = GlobalKey();
  final GlobalKey _glossaryTooltipKey = GlobalKey();
  Timer? _glossaryTooltipTimer;
  _VisibleNotificationArticleGlossaryTooltip? _visibleGlossaryTooltip;

  @override
  void dispose() {
    _glossaryTooltipTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = _NotificationArticleDetailData.fromNotification(
      widget.item,
      intelligenceItem: widget.intelligenceItem,
    );

    return Scaffold(
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
                        key: const ValueKey('notification-article-scroll'),
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

Future<void> _openOriginalArticleUrl(
  BuildContext context,
  _NotificationArticleDetailData detail,
) async {
  final uri = Uri.tryParse(detail.originalUrl.trim());
  if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
    _showOriginalArticleError(context, 'Original article link is unavailable.');
    return;
  }

  final opened = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
    webOnlyWindowName: '_blank',
  );
  if (!opened && context.mounted) {
    _showOriginalArticleError(context, 'Unable to open original article.');
  }
}

void _showOriginalArticleError(BuildContext context, String message) {
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message)),
    );
}

class _NotificationArticleBottomActionBar extends StatelessWidget {
  const _NotificationArticleBottomActionBar({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final safeAreaHeight = bottomInset > 0 ? bottomInset : 34.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x00FFFFFF),
                Color(0xCCFFFFFF),
                AppColors.white,
                AppColors.white,
              ],
              stops: [0, 0.36, 0.68, 1],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 45,
              child: FilledButton(
                key: const ValueKey('notification-article-view-original'),
                onPressed: onPressed,
                style: _exchangePrimaryButtonStyle(
                  backgroundColor: AppColors.orange500,
                  padding: EdgeInsets.zero,
                  radius: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      AppAssets.externalLinkIcon,
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'View Original',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 18,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: safeAreaHeight,
          width: double.infinity,
          child: const ColoredBox(color: AppColors.white),
        ),
      ],
    );
  }
}

class _NotificationArticleDetailHeader extends StatelessWidget {
  const _NotificationArticleDetailHeader({
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Padding(
        padding: _compactHeaderPadding,
        child: Row(
          children: [
            _NotificationHeaderIconButton(
              key: const ValueKey('notification-article-back'),
              semanticLabel: 'Back',
              onTap: onBack,
              child: Image.asset(
                AppAssets.backArrow,
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
            ),
            const Spacer(),
            _NotificationHeaderIconButton(
              semanticLabel: 'Article Search',
              onTap: () {},
              child: Image.asset(
                AppAssets.headerSearch,
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 4),
            _NotificationHeaderIconButton(
              semanticLabel: 'Article More',
              onTap: () {},
              child: Image.asset(
                AppAssets.headerMoreIcon,
                width: 36,
                height: 36,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationArticleHeroImage extends StatelessWidget {
  const _NotificationArticleHeroImage({
    required this.imageUrl,
  });

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 240,
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
    );
  }

  Widget _fallbackImage() {
    return Image.asset(
      AppAssets.noImageDefault,
      fit: BoxFit.cover,
    );
  }
}

class _NotificationArticleSummarySection extends StatelessWidget {
  const _NotificationArticleSummarySection({
    required this.detail,
    required this.articleContentStackKey,
    required this.onGlossaryTap,
  });

  final _NotificationArticleDetailData detail;
  final GlobalKey articleContentStackKey;
  final void Function(
          _NotificationArticleGlossaryEntry glossary, Rect anchorRect)
      onGlossaryTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StockNewsSentimentBadge(
              sentiment: detail.sentiment,
              fontSize: 12,
            ),
            const SizedBox(width: 6),
            _StockNewsPriorityBadge(
              priority: detail.priority,
              fontSize: 12,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _NotificationArticleInteractiveParagraph(
          key: const ValueKey('notification-article-title'),
          paragraph: detail.title,
          glossaryEntries: detail.glossaryEntries,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 22,
                    height: 31 / 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray1000,
                  ) ??
              const TextStyle(
                fontSize: 22,
                height: 31 / 22,
                fontWeight: FontWeight.w600,
                color: AppColors.gray1000,
              ),
          articleContentStackKey: articleContentStackKey,
          onGlossaryTap: onGlossaryTap,
        ),
        const SizedBox(height: 4),
        Text(
          '${detail.companyLabel} · ${detail.relativeTimeLabel}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                height: 1.42,
                fontWeight: FontWeight.w400,
                color: AppColors.gray600,
              ),
        ),
      ],
    );
  }
}

class _NotificationArticleAnalysisCard extends StatelessWidget {
  const _NotificationArticleAnalysisCard({
    required this.detail,
  });

  final _NotificationArticleDetailData detail;
  static const _analysisCardGradient = LinearGradient(
    begin: Alignment(-0.62, -1),
    end: Alignment(0.62, 1),
    colors: [
      AppColors.orange100,
      AppColors.red100,
    ],
  );

  @override
  Widget build(BuildContext context) {
    if (detail.analysisRows.isEmpty) {
      return const SizedBox.shrink();
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: _analysisCardGradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                height: 36,
                child: Row(
                  children: [
                    Image.asset(
                      AppAssets.splashIcon,
                      width: 16,
                      height: 16,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AI Analysis',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                            color: AppColors.orange500,
                          ),
                    ),
                    const Spacer(),
                    Image.asset(
                      AppAssets.hanaMontanaAnalysisCharacter,
                      width: 73,
                      height: 54,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  for (var index = 0;
                      index < detail.analysisRows.length;
                      index++) ...[
                    _NotificationArticleAnalysisRow(
                      row: detail.analysisRows[index],
                    ),
                    if (index != detail.analysisRows.length - 1)
                      const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationArticleAnalysisRow extends StatelessWidget {
  const _NotificationArticleAnalysisRow({
    required this.row,
  });

  final _StockNewsSummaryRowData row;
  static const _analysisLineHeight = 1.4;
  static const _analysisLetterSpacing = 0.0;
  static const _analysisStrutStyle = StrutStyle(
    fontSize: 12,
    height: _analysisLineHeight,
    forceStrutHeight: true,
  );
  static const _analysisTextHeightBehavior = TextHeightBehavior(
    applyHeightToFirstAscent: false,
    applyHeightToLastDescent: false,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _analysisLabelVisualWidth(row.label),
          child: Text(
            row.label,
            maxLines: 1,
            softWrap: false,
            strutStyle: _analysisStrutStyle,
            textHeightBehavior: _analysisTextHeightBehavior,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  height: _analysisLineHeight,
                  fontWeight: FontWeight.w500,
                  letterSpacing: _analysisLetterSpacing,
                  color: AppColors.orange500,
                ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            row.value,
            strutStyle: _analysisStrutStyle,
            textHeightBehavior: _analysisTextHeightBehavior,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  height: _analysisLineHeight,
                  fontWeight: FontWeight.w400,
                  letterSpacing: _analysisLetterSpacing,
                  color: AppColors.gray700,
                ),
          ),
        ),
      ],
    );
  }
}

double _analysisLabelVisualWidth(String label) {
  return switch (label) {
    'What' => 31,
    'Why' => 26,
    'Impact' => 39,
    _ => 44,
  };
}

class _NotificationArticleBody extends StatelessWidget {
  const _NotificationArticleBody({
    required this.detail,
    required this.articleContentStackKey,
    required this.onGlossaryTap,
  });

  final _NotificationArticleDetailData detail;
  final GlobalKey articleContentStackKey;
  final void Function(
          _NotificationArticleGlossaryEntry glossary, Rect anchorRect)
      onGlossaryTap;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 16,
              height: 1.4,
              fontWeight: FontWeight.w400,
              color: AppColors.gray900,
            ) ??
        const TextStyle(
          fontSize: 16,
          height: 1.4,
          fontWeight: FontWeight.w400,
          color: AppColors.gray900,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < detail.bodyParagraphs.length; index++) ...[
          _NotificationArticleInteractiveParagraph(
            key: ValueKey('notification-article-body-paragraph-$index'),
            paragraph: detail.bodyParagraphs[index],
            glossaryEntries: detail.glossaryEntries,
            style: textStyle,
            articleContentStackKey: articleContentStackKey,
            onGlossaryTap: onGlossaryTap,
          ),
          if (index != detail.bodyParagraphs.length - 1)
            const SizedBox(height: 28),
        ],
      ],
    );
  }
}

class _NotificationArticleDetailData {
  const _NotificationArticleDetailData({
    required this.title,
    required this.companyLabel,
    required this.relativeTimeLabel,
    required this.sentiment,
    required this.priority,
    required this.analysisRows,
    required this.bodyText,
    required this.glossaryEntries,
    required this.originalUrl,
    this.imageUrl,
  });

  final String title;
  final String companyLabel;
  final String relativeTimeLabel;
  final _StockNewsSentiment sentiment;
  final _StockNewsPriority priority;
  final List<_StockNewsSummaryRowData> analysisRows;
  final String bodyText;
  final List<_NotificationArticleGlossaryEntry> glossaryEntries;
  final String originalUrl;
  final String? imageUrl;

  List<String> get bodyParagraphs {
    final normalized = bodyText
        .split(RegExp(r'\n\s*\n'))
        .map((paragraph) => paragraph.replaceAll('\n', ' ').trim())
        .where((paragraph) => paragraph.isNotEmpty)
        .toList();
    return normalized;
  }

  factory _NotificationArticleDetailData.fromNotification(
    NotificationItem item, {
    StockIntelligenceItem? intelligenceItem,
  }) {
    final resolvedBodyText = intelligenceItem != null
        ? intelligenceItem.displayBody.isNotEmpty
            ? intelligenceItem.displayBody
            : item.summary.isNotEmpty
                ? '${item.title}\n${item.summary}'
                : item.title
        : item.summary.isNotEmpty
            ? '${item.title}\n${item.summary}'
            : item.title;
    final resolvedTitle = intelligenceItem?.title ?? item.title;
    final resolvedGlossaryEntries = _glossaryEntriesFromTerms(
      intelligenceItem?.glossaryTerms ?? item.glossaryTerms,
      '$resolvedTitle\n$resolvedBodyText',
    );

    if (intelligenceItem != null) {
      return _NotificationArticleDetailData(
        title: intelligenceItem.title,
        companyLabel: _notificationCompanyLabel(item),
        relativeTimeLabel: _relativeTimeLabel(
          intelligenceItem.publishedAt ?? intelligenceItem.receivedAt,
        ),
        sentiment: _sentimentFromString(intelligenceItem.sentiment),
        priority: _priorityFromStrings(
          intelligenceItem.importance,
          intelligenceItem.riskLevel,
        ),
        analysisRows: _analysisRowsFromIntelligence(intelligenceItem),
        bodyText: resolvedBodyText,
        glossaryEntries: resolvedGlossaryEntries,
        originalUrl: intelligenceItem.originalUrl.isNotEmpty
            ? intelligenceItem.originalUrl
            : item.originalUrl,
        imageUrl: intelligenceItem.imageUrls.isEmpty
            ? null
            : intelligenceItem.imageUrls.first,
      );
    }

    return _NotificationArticleDetailData(
      title: item.title,
      companyLabel: _notificationCompanyLabel(item),
      relativeTimeLabel: _relativeTimeLabel(item.createdAt),
      sentiment: _StockNewsSentiment.positive,
      priority: _StockNewsPriority.high,
      analysisRows: [
        _StockNewsSummaryRowData(
          label: 'What',
          value: item.title,
        ),
        _StockNewsSummaryRowData(
          label: 'Why',
          value: item.summary.isNotEmpty ? item.summary : item.title,
        ),
        _StockNewsSummaryRowData(
          label: 'Impact',
          value:
              '${item.targetLabel} notification triggered for ${_notificationCompanyLabel(item)}.',
        ),
      ],
      bodyText: resolvedBodyText,
      glossaryEntries: resolvedGlossaryEntries,
      originalUrl: item.originalUrl,
      imageUrl: null,
    );
  }

  factory _NotificationArticleDetailData.fromMarketNews(MarketNewsItem item) {
    final bodyText = item.displayBody;
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

    return _NotificationArticleDetailData(
      title: item.displayTitle,
      companyLabel: item.displayQuery,
      relativeTimeLabel: _relativeTimeLabel(item.publishedAt ?? item.createdAt),
      sentiment: _StockNewsSentiment.positive,
      priority: _StockNewsPriority.medium,
      analysisRows: rows,
      bodyText: bodyText,
      glossaryEntries: _glossaryEntriesFromTerms(
        item.glossaryTerms,
        '${item.displayTitle}\n$bodyText',
      ),
      originalUrl:
          item.originalUrl.isNotEmpty ? item.originalUrl : item.canonicalUrl,
      imageUrl: item.imageUrl,
    );
  }

  static List<_StockNewsSummaryRowData> _analysisRowsFromIntelligence(
    StockIntelligenceItem item,
  ) {
    return _analysisRowsFromStockIntelligence(
      item,
    );
  }
}

class _NotificationArticleGlossaryEntry {
  const _NotificationArticleGlossaryEntry({
    required this.highlightedText,
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String highlightedText;
  final String eyebrow;
  final String title;
  final String description;
}

class _VisibleNotificationArticleGlossaryTooltip {
  const _VisibleNotificationArticleGlossaryTooltip({
    required this.glossary,
    required this.anchorRect,
  });

  final _NotificationArticleGlossaryEntry glossary;
  final Rect anchorRect;
}

class _NotificationArticleInteractiveParagraph extends StatelessWidget {
  const _NotificationArticleInteractiveParagraph({
    super.key,
    required this.paragraph,
    required this.glossaryEntries,
    required this.style,
    required this.articleContentStackKey,
    required this.onGlossaryTap,
  });

  final String paragraph;
  final List<_NotificationArticleGlossaryEntry> glossaryEntries;
  final TextStyle style;
  final GlobalKey articleContentStackKey;
  final void Function(
          _NotificationArticleGlossaryEntry glossary, Rect anchorRect)
      onGlossaryTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final paragraphLayout = _buildNotificationArticleParagraphLayout(
          paragraph,
          glossaryEntries,
          style,
        );

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: paragraphLayout.highlightRanges.isEmpty
              ? null
              : (details) {
                  final highlight = _findTappedHighlightRange(
                    tapPosition: details.localPosition,
                    layout: paragraphLayout,
                    maxWidth: constraints.maxWidth,
                    textDirection: Directionality.of(context),
                  );
                  if (highlight == null) {
                    return;
                  }
                  final paragraphBox = context.findRenderObject() as RenderBox?;
                  final stackBox = articleContentStackKey.currentContext
                      ?.findRenderObject() as RenderBox?;
                  if (paragraphBox == null ||
                      stackBox == null ||
                      !paragraphBox.hasSize ||
                      !stackBox.hasSize) {
                    return;
                  }
                  final anchorRect = Rect.fromPoints(
                    paragraphBox.localToGlobal(
                      highlight.rect.topLeft,
                      ancestor: stackBox,
                    ),
                    paragraphBox.localToGlobal(
                      highlight.rect.bottomRight,
                      ancestor: stackBox,
                    ),
                  );
                  onGlossaryTap(highlight.entry, anchorRect);
                },
          child: RichText(
            text: paragraphLayout.textSpan,
          ),
        );
      },
    );
  }
}

class _NotificationArticleGlossaryTooltipOverlay extends StatelessWidget {
  const _NotificationArticleGlossaryTooltipOverlay({
    super.key,
    required this.glossary,
    required this.anchorRect,
    required this.maxWidth,
  });

  final _NotificationArticleGlossaryEntry glossary;
  final Rect anchorRect;
  final double maxWidth;

  static const double _bubbleWidth = 264;
  static const double _bubbleHeight = 176;
  static const double _pointerWidth = 34;
  static const double _pointerHeight = 20;
  static const double _pointerOverlap = 12;
  static const double _topGap = 4;
  static const double _pointerAnchorBias = 13;

  @override
  Widget build(BuildContext context) {
    final left = (anchorRect.center.dx - (_bubbleWidth / 2))
        .clamp(0.0, (maxWidth - _bubbleWidth).clamp(0.0, double.infinity))
        .toDouble();
    final top = (anchorRect.top -
            (_bubbleHeight + _pointerHeight - _pointerOverlap + _topGap))
        .toDouble();
    final pointerLeft =
        (anchorRect.center.dx - left - (_pointerWidth / 2) - _pointerAnchorBias)
            .clamp(16.0, _bubbleWidth - _pointerWidth - 16)
            .toDouble();

    return Positioned(
      left: left,
      top: top,
      child: SizedBox(
        width: _bubbleWidth,
        height: _bubbleHeight + _pointerHeight - _pointerOverlap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: _bubbleWidth,
              height: _bubbleHeight,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                color: AppColors.slate600,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      glossary.eyebrow,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0,
                            color: AppColors.orange500,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      glossary.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                            color: AppColors.white,
                          ),
                    ),
                    if (glossary.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        glossary.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0,
                              color: AppColors.gray400,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Positioned(
              left: pointerLeft,
              top: _bubbleHeight - _pointerOverlap,
              child: CustomPaint(
                size: const Size(_pointerWidth, _pointerHeight),
                painter: _NotificationArticleTooltipPointerPainter(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationArticleTooltipPointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.slate600;
    const radius = 4.0;
    final halfWidth = size.width / 2;
    final path = Path()
      ..moveTo(radius, 0)
      ..lineTo(size.width - radius, 0)
      ..quadraticBezierTo(size.width, 0, size.width - 1.5, radius)
      ..lineTo(halfWidth + radius, size.height - radius)
      ..quadraticBezierTo(
        halfWidth,
        size.height,
        halfWidth - radius,
        size.height - radius,
      )
      ..lineTo(1.5, radius)
      ..quadraticBezierTo(0, 0, radius, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NotificationArticleParagraphLayout {
  const _NotificationArticleParagraphLayout({
    required this.textSpan,
    required this.highlightRanges,
  });

  final TextSpan textSpan;
  final List<_NotificationArticleHighlightRange> highlightRanges;
}

class _NotificationArticleHighlightRange {
  const _NotificationArticleHighlightRange({
    required this.start,
    required this.end,
    required this.entry,
  });

  final int start;
  final int end;
  final _NotificationArticleGlossaryEntry entry;
}

class _TappedNotificationArticleHighlight {
  const _TappedNotificationArticleHighlight({
    required this.entry,
    required this.rect,
  });

  final _NotificationArticleGlossaryEntry entry;
  final Rect rect;
}

_NotificationArticleParagraphLayout _buildNotificationArticleParagraphLayout(
  String paragraph,
  List<_NotificationArticleGlossaryEntry> glossaryEntries,
  TextStyle style,
) {
  final highlightRanges = _findNotificationArticleHighlightRanges(
    paragraph,
    glossaryEntries,
  );
  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final range in highlightRanges) {
    if (cursor < range.start) {
      spans.add(
        TextSpan(
          text: paragraph.substring(cursor, range.start),
          style: style,
        ),
      );
    }
    spans.add(
      TextSpan(
        text: paragraph.substring(range.start, range.end),
        style: style.copyWith(backgroundColor: AppColors.orange300),
      ),
    );
    cursor = range.end;
  }
  if (cursor < paragraph.length) {
    spans.add(TextSpan(text: paragraph.substring(cursor), style: style));
  }

  return _NotificationArticleParagraphLayout(
    textSpan: TextSpan(children: spans, style: style),
    highlightRanges: highlightRanges,
  );
}

List<_NotificationArticleHighlightRange>
    _findNotificationArticleHighlightRanges(
  String paragraph,
  List<_NotificationArticleGlossaryEntry> glossaryEntries,
) {
  final ranges = <_NotificationArticleHighlightRange>[];
  var searchStart = 0;
  while (searchStart < paragraph.length) {
    _NotificationArticleGlossaryEntry? bestEntry;
    int? bestStart;
    int bestLength = -1;

    for (final entry in glossaryEntries) {
      if (entry.highlightedText.isEmpty) {
        continue;
      }
      final matchStart = paragraph.indexOf(entry.highlightedText, searchStart);
      if (matchStart == -1) {
        continue;
      }
      final entryLength = entry.highlightedText.length;
      final isEarlier = bestStart == null || matchStart < bestStart;
      final isLongerAtSamePosition =
          matchStart == bestStart && entryLength > bestLength;
      if (isEarlier || isLongerAtSamePosition) {
        bestEntry = entry;
        bestStart = matchStart;
        bestLength = entryLength;
      }
    }

    if (bestEntry == null || bestStart == null) {
      break;
    }

    ranges.add(
      _NotificationArticleHighlightRange(
        start: bestStart,
        end: bestStart + bestLength,
        entry: bestEntry,
      ),
    );
    searchStart = bestStart + bestLength;
  }
  return ranges;
}

_TappedNotificationArticleHighlight? _findTappedHighlightRange({
  required Offset tapPosition,
  required _NotificationArticleParagraphLayout layout,
  required double maxWidth,
  required TextDirection textDirection,
}) {
  final textPainter = TextPainter(
    text: layout.textSpan,
    textDirection: textDirection,
  )..layout(maxWidth: maxWidth);

  for (final range in layout.highlightRanges) {
    final boxes = textPainter.getBoxesForSelection(
      TextSelection(baseOffset: range.start, extentOffset: range.end),
    );
    if (boxes.isEmpty) {
      continue;
    }
    final rect = _notificationArticleSelectionRect(boxes);
    final containsTap =
        boxes.any((box) => box.toRect().inflate(2).contains(tapPosition));
    if (containsTap) {
      return _TappedNotificationArticleHighlight(
        entry: range.entry,
        rect: rect,
      );
    }
  }

  return null;
}

Rect _notificationArticleSelectionRect(List<TextBox> boxes) {
  var left = boxes.first.left;
  var top = boxes.first.top;
  var right = boxes.first.right;
  var bottom = boxes.first.bottom;
  for (final box in boxes.skip(1)) {
    left = left < box.left ? left : box.left;
    top = top < box.top ? top : box.top;
    right = right > box.right ? right : box.right;
    bottom = bottom > box.bottom ? bottom : box.bottom;
  }
  return Rect.fromLTRB(left, top, right, bottom);
}

List<_NotificationArticleGlossaryEntry> _glossaryEntriesFromTerms(
  List<AlertGlossaryTerm> terms,
  String bodyText,
) {
  final entries = <_NotificationArticleGlossaryEntry>[];
  for (final term in terms) {
    final highlightedText = _glossaryHighlightText(term, bodyText);
    if (highlightedText == null) {
      continue;
    }
    entries.add(
      _NotificationArticleGlossaryEntry(
        highlightedText: highlightedText,
        eyebrow: 'Financial Glossary',
        title: _glossaryTooltipTitle(term, highlightedText),
        description: term.description,
      ),
    );
  }
  return entries;
}

String? _glossaryHighlightText(
  AlertGlossaryTerm term,
  String bodyText,
) {
  final candidates = <String>[
    term.sourceTerm,
    term.normalizedTerm,
    _titleCaseWords(term.englishTerm),
    term.englishTerm,
  ];
  for (final candidate in candidates) {
    if (candidate.isNotEmpty && bodyText.contains(candidate)) {
      return candidate;
    }
  }
  return null;
}

String _glossaryTooltipTitle(
  AlertGlossaryTerm term,
  String highlightedText,
) {
  final displayTerm = _titleCaseWords(highlightedText);
  final englishTitle = _titleCaseWords(term.englishTerm);
  if (displayTerm.isNotEmpty &&
      englishTitle.isNotEmpty &&
      displayTerm.toLowerCase() != englishTitle.toLowerCase()) {
    return '$displayTerm ($englishTitle)';
  }
  if (displayTerm.isNotEmpty) {
    return displayTerm;
  }
  if (englishTitle.isNotEmpty) {
    return englishTitle;
  }
  if (term.sourceTerm.isNotEmpty) {
    return term.sourceTerm;
  }
  if (term.normalizedTerm.isNotEmpty) {
    return term.normalizedTerm;
  }
  return highlightedText;
}

String _titleCaseWords(String value) {
  if (value.isEmpty) {
    return value;
  }
  return value
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .map(
        (word) => word.length == 1
            ? word.toUpperCase()
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');
}
