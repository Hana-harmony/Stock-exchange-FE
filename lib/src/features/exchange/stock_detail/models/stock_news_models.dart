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
    required this.sourceItem,
    required this.title,
    required this.imageUrl,
    required this.sentiment,
    required this.priority,
    required this.targetLabel,
    required this.showTargetBadge,
    required this.relativeTimeLabel,
    required this.summaryRows,
  });

  final StockIntelligenceItem sourceItem;
  final String title;
  final String? imageUrl;
  final _StockNewsSentiment sentiment;
  final _StockNewsPriority priority;
  final String targetLabel;
  final bool showTargetBadge;
  final String relativeTimeLabel;
  final List<_StockNewsSummaryRowData> summaryRows;

  factory _StockNewsItemViewModel.fromFeedItem(StockIntelligenceItem item) {
    final rows = _analysisRowsFromStockIntelligence(item);

    return _StockNewsItemViewModel(
      sourceItem: item,
      title: item.title,
      imageUrl: item.imageUrls.isEmpty ? null : item.imageUrls.first,
      sentiment: _sentimentFromString(item.sentiment),
      priority: _priorityFromStrings(item.importance, item.riskLevel),
      targetLabel: item.targetLabel,
      showTargetBadge: item.holderTarget,
      relativeTimeLabel:
          _relativeTimeLabel(item.publishedAt ?? item.receivedAt),
      summaryRows: rows,
    );
  }
}

List<_StockNewsSummaryRowData> _analysisRowsFromStockIntelligence(
  StockIntelligenceItem item,
) {
  final rawRows = [
    (label: 'What', value: item.summaryLines.what),
    (label: 'Why', value: item.summaryLines.why),
    (label: 'Impact', value: item.summaryLines.impact),
  ];
  final cleanRows = [
    for (final row in rawRows)
      _StockNewsSummaryRowData(
        label: row.label,
        value: _cleanAnalysisLine(row.value),
      ),
  ];
  if (cleanRows.every((row) => row.value.isNotEmpty)) {
    return cleanRows;
  }
  return const [];
}

String _cleanAnalysisLine(String value) {
  final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.isEmpty ||
      normalized == '.' ||
      normalized == '-' ||
      normalized.startsWith('()') ||
      normalized.contains('· .') ||
      normalized.contains('..') ||
      normalized.length < 10) {
    return '';
  }
  final wordCount = RegExp(r'[A-Za-z가-힣]{2,}').allMatches(normalized).length;
  if (wordCount < 3) {
    return '';
  }
  final letterCount = RegExp(r'[A-Za-z가-힣]').allMatches(normalized).length;
  final punctuationCount = RegExp(r'[()%,;:·]').allMatches(normalized).length;
  if (letterCount == 0 || punctuationCount / letterCount > 0.34) {
    return '';
  }
  return normalized;
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
