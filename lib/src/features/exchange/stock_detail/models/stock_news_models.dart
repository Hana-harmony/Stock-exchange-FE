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

  factory _StockNewsItemViewModel.fromFeedItem(
    StockIntelligenceItem item, {
    required String fallbackCompanyLabel,
  }) {
    final rows = _analysisRowsFromStockIntelligence(
      item,
      fallbackText: fallbackCompanyLabel,
    );

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
  StockIntelligenceItem item, {
  required String fallbackText,
}) {
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

  final fallbackLines = _fallbackAnalysisLines(
    primaryText: item.summary,
    secondaryText: item.originalContent,
    tertiaryText: item.translatedSummary,
    finalFallback: item.title.isNotEmpty ? item.title : fallbackText,
  );
  return [
    _StockNewsSummaryRowData(label: 'What', value: fallbackLines[0]),
    _StockNewsSummaryRowData(label: 'Why', value: fallbackLines[1]),
    _StockNewsSummaryRowData(label: 'Impact', value: fallbackLines[2]),
  ];
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

List<String> _fallbackAnalysisLines({
  required String primaryText,
  required String secondaryText,
  required String tertiaryText,
  required String finalFallback,
}) {
  final candidates = [
    ..._analysisSentenceCandidates(primaryText),
    ..._analysisSentenceCandidates(secondaryText),
    ..._analysisSentenceCandidates(tertiaryText),
  ];
  final deduped = <String>[];
  for (final candidate in candidates) {
    if (deduped.any((line) => line == candidate)) {
      continue;
    }
    deduped.add(candidate);
    if (deduped.length == 3) {
      break;
    }
  }

  final safeFallback = _trimAnalysisLine(finalFallback);
  while (deduped.length < 3) {
    deduped.add(safeFallback);
  }
  return deduped;
}

List<String> _analysisSentenceCandidates(String text) {
  final normalized = text
      .replaceAll('\r', '\n')
      .replaceAll(RegExp(r'[◆•●▶]'), '\n')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (normalized.isEmpty) {
    return const [];
  }
  final matches = RegExp(r'[^.!?。]+(?:[.!?。]|다\.|요\.|니다\.|습니다\.)')
      .allMatches(normalized)
      .map((match) => _trimAnalysisLine(match.group(0) ?? ''))
      .where((line) => line.length >= 12)
      .toList();
  if (matches.isNotEmpty) {
    return matches;
  }
  return [_trimAnalysisLine(normalized)]
      .where((line) => line.isNotEmpty)
      .toList();
}

String _trimAnalysisLine(String value) {
  final normalized = value
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^[\s:;,\-]+'), '')
      .trim();
  if (normalized.length <= 140) {
    return normalized;
  }
  final clipped = normalized.substring(0, 140).trimRight();
  return '$clipped...';
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
