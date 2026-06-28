part of '../exchange_pages.dart';

class NotificationArticleDetailScreen extends StatelessWidget {
  const NotificationArticleDetailScreen({
    super.key,
    required this.item,
    this.intelligenceItem,
  });

  final NotificationItem item;
  final StockIntelligenceItem? intelligenceItem;

  @override
  Widget build(BuildContext context) {
    final detail = _NotificationArticleDetailData.fromNotification(
      item,
      intelligenceItem: intelligenceItem,
    );

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _NotificationArticleDetailHeader(
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    key: const ValueKey('notification-article-scroll'),
                    padding: const EdgeInsets.only(bottom: 140),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _NotificationArticleHeroImage(
                            imageUrl: detail.imageUrl),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _NotificationArticleSummarySection(
                            detail: detail,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _NotificationArticleAnalysisCard(
                            detail: detail,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _NotificationArticleBody(detail: detail),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: _NotificationArticleBottomActionBar(
                      onPressed: () =>
                          _showOriginalLinkMessage(context, detail),
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

  void _showOriginalLinkMessage(
    BuildContext context,
    _NotificationArticleDetailData detail,
  ) {
    final message = detail.originalUrl.isEmpty
        ? 'Original article link is unavailable.'
        : 'Original article: ${detail.originalUrl}';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }
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
  });

  final _NotificationArticleDetailData detail;

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
        Text(
          detail.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 22,
                height: 31 / 22,
                fontWeight: FontWeight.w600,
                color: AppColors.gray1000,
              ),
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
                      AppAssets.headerAiIcon,
                      width: 36,
                      height: 36,
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
  static const _analysisLetterSpacing = -0.24;
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
    return SizedBox(
      height: 34,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _analysisLabelWidth(row.label),
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: _analysisLabelWidth(row.label),
              maxWidth: _analysisLabelVisualWidth(row.label),
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
          ),
          const SizedBox(width: 4),
          Expanded(
            child: SizedBox(
              height: 34,
              child: Text(
                row.value,
                maxLines: 2,
                strutStyle: _analysisStrutStyle,
                textHeightBehavior: _analysisTextHeightBehavior,
                overflow: TextOverflow.clip,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      height: _analysisLineHeight,
                      fontWeight: FontWeight.w400,
                      letterSpacing: _analysisLetterSpacing,
                      color: AppColors.gray700,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

double _analysisLabelWidth(String label) {
  return switch (label) {
    'What' => 29,
    'Why' => 24,
    'Impact' => 37,
    _ => 42,
  };
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
  });

  final _NotificationArticleDetailData detail;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontSize: 16,
          height: 1.4,
          fontWeight: FontWeight.w400,
          color: AppColors.gray900,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < detail.bodyParagraphs.length; index++) ...[
          Text(
            detail.bodyParagraphs[index],
            style: textStyle,
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
  final String originalUrl;
  final String? imageUrl;

  List<String> get bodyParagraphs {
    final normalized = bodyText
        .split(RegExp(r'\n\s*\n'))
        .map((paragraph) => paragraph.replaceAll('\n', ' ').trim())
        .where((paragraph) => paragraph.isNotEmpty)
        .toList();
    return normalized.isEmpty ? [bodyText.trim()] : normalized;
  }

  factory _NotificationArticleDetailData.fromNotification(
    NotificationItem item, {
    StockIntelligenceItem? intelligenceItem,
  }) {
    final useFigmaAnalysisMock = _shouldUseFigmaAnalysisMock(
      item,
      intelligenceItem: intelligenceItem,
    );

    if (intelligenceItem != null) {
      return _NotificationArticleDetailData(
        title: useFigmaAnalysisMock
            ? _figmaMockDetailTitle
            : intelligenceItem.title,
        companyLabel: _notificationCompanyLabel(item),
        relativeTimeLabel: _relativeTimeLabel(
          intelligenceItem.publishedAt ?? intelligenceItem.receivedAt,
        ),
        sentiment: _sentimentFromString(intelligenceItem.sentiment),
        priority: _priorityFromStrings(
          intelligenceItem.importance,
          intelligenceItem.riskLevel,
        ),
        analysisRows: useFigmaAnalysisMock
            ? _figmaMockAnalysisRows()
            : _analysisRowsFromIntelligence(intelligenceItem),
        bodyText: intelligenceItem.originalContent.isNotEmpty
            ? intelligenceItem.originalContent
            : intelligenceItem.translatedContent.isNotEmpty
                ? intelligenceItem.translatedContent
                : intelligenceItem.summary.isNotEmpty
                    ? intelligenceItem.summary
                    : intelligenceItem.displaySummary,
        originalUrl: intelligenceItem.originalUrl.isNotEmpty
            ? intelligenceItem.originalUrl
            : item.originalUrl,
        imageUrl: intelligenceItem.imageUrls.isEmpty
            ? null
            : intelligenceItem.imageUrls.first,
      );
    }

    return _NotificationArticleDetailData(
      title: useFigmaAnalysisMock ? _figmaMockDetailTitle : item.title,
      companyLabel: _notificationCompanyLabel(item),
      relativeTimeLabel: _relativeTimeLabel(item.createdAt),
      sentiment: _StockNewsSentiment.positive,
      priority: _StockNewsPriority.high,
      analysisRows: useFigmaAnalysisMock
          ? _figmaMockAnalysisRows()
          : [
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
      bodyText: item.summary.isNotEmpty
          ? '${item.title}\n${item.summary}'
          : item.title,
      originalUrl: item.originalUrl,
      imageUrl: null,
    );
  }

  static List<_StockNewsSummaryRowData> _analysisRowsFromIntelligence(
    StockIntelligenceItem item,
  ) {
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

    if (rows.isNotEmpty) {
      return rows;
    }

    return [
      _StockNewsSummaryRowData(
        label: 'What',
        value: item.summary.isNotEmpty ? item.summary : item.translatedSummary,
      ),
      _StockNewsSummaryRowData(
        label: 'Why',
        value: item.originalContent.isNotEmpty
            ? item.originalContent
            : item.summary.isNotEmpty
                ? item.summary
                : item.title,
      ),
      _StockNewsSummaryRowData(
        label: 'Impact',
        value: item.contentPreview.isNotEmpty
            ? item.contentPreview
            : item.originalContent.isNotEmpty
                ? item.originalContent
                : item.title,
      ),
    ];
  }
}

bool _shouldUseFigmaAnalysisMock(
  NotificationItem item, {
  StockIntelligenceItem? intelligenceItem,
}) {
  final title = intelligenceItem?.title ?? item.title;
  return title.startsWith(
    'SAMSUNG ELEC: Dividend Payout Confirmed for FY2025',
  );
}

const _figmaMockDetailTitle =
    'SAMSUNG ELEC: Dividend Payout Confirmed for FY2025';

List<_StockNewsSummaryRowData> _figmaMockAnalysisRows() {
  const figmaText =
      'SAMSUNG ELEC: Dividend Payout Confirmed for FY2025 AMSUNG SAMSUNG ELEC: Dividend Payout';
  return const [
    _StockNewsSummaryRowData(
      label: 'What',
      value: figmaText,
    ),
    _StockNewsSummaryRowData(
      label: 'Why',
      value: figmaText,
    ),
    _StockNewsSummaryRowData(
      label: 'Impact',
      value: figmaText,
    ),
  ];
}
