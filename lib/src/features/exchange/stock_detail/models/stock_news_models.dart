part of '../../exchange_pages.dart';

enum _StockNewsSentiment {
  positive,
  negative,
}

enum _StockNewsPriority {
  high,
  medium,
  low,
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
      _fallbackItem(targetLabel: 'Watchlist', showTargetBadge: false),
      _fallbackItem(targetLabel: 'My Portfolio', showTargetBadge: true),
      _fallbackItem(targetLabel: companyLabel, showTargetBadge: false),
      _fallbackItem(targetLabel: companyLabel, showTargetBadge: false),
    ];
  }

  static _StockNewsItemViewModel _fallbackItem({
    required String targetLabel,
    required bool showTargetBadge,
  }) {
    return _StockNewsItemViewModel(
      title:
          'SAMSUNG ELEC: Dividend Payout Confirmed for FY2025 SAMSUNG ELEC: Dividend Payout Confirmed for FY2025',
      imageUrl: null,
      sentiment: _StockNewsSentiment.positive,
      priority: _StockNewsPriority.high,
      targetLabel: targetLabel,
      showTargetBadge: showTargetBadge,
      relativeTimeLabel: showTargetBadge ? '53m ago' : '1h ago',
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
    );
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
