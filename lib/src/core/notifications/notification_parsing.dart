part of '../notification_controller.dart';

const Object _copyWithUndefined = Object();

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return {};
}

String _string(Object? value, {required String fallback}) {
  if (value == null) {
    return fallback;
  }
  return value.toString();
}

String? _nullableString(Object? value) {
  if (value == null) {
    return null;
  }
  final text = value.toString();
  return text.isEmpty ? null : text;
}

int _int(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

List<String> _stringList(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value.map((item) => item.toString()).toList();
}

List<AlertGlossaryTerm> _glossaryTerms(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value
      .map((item) => AlertGlossaryTerm.fromJson(_map(item)))
      .where((term) => term.displayLabel.isNotEmpty)
      .toList();
}

DateTime? _dateTime(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}

bool _isArticleBodyCandidate(
  String value, {
  required AlertSummaryLines summaryLines,
  required String translatedSummary,
}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty ||
      _looksLikeSummaryOnlyBody(trimmed, summaryLines, translatedSummary)) {
    return false;
  }
  return RegExp(r'[A-Za-z가-힣]').hasMatch(trimmed);
}

bool _looksLikeSummaryOnlyBody(
  String value,
  AlertSummaryLines summaryLines,
  String translatedSummary,
) {
  final lower = value.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
  if (lower.contains(
        'the original korean text is retained because machine translation was unavailable',
      ) ||
      lower.contains(
        'review the linked article or filing for price, liquidity, and portfolio impact',
      )) {
    return true;
  }
  if (_looksLikeStructuredSummaryText(value)) {
    return true;
  }
  final normalized = _normalizeArticleBodyComparison(value);
  final translatedSummaryNormalized =
      _normalizeArticleBodyComparison(translatedSummary);
  if (translatedSummaryNormalized.isNotEmpty &&
      normalized == translatedSummaryNormalized) {
    return true;
  }
  final rawSummaryLines = [
    summaryLines.what,
    summaryLines.why,
    summaryLines.impact,
  ].where((line) => line.trim().isNotEmpty).join(' ');
  final labeledSummaryLines = summaryLines.lines.join(' ');
  return normalized.isNotEmpty &&
      (normalized == _normalizeArticleBodyComparison(rawSummaryLines) ||
          normalized == _normalizeArticleBodyComparison(labeledSummaryLines));
}

bool _looksLikeStructuredSummaryText(String value) {
  final lower = value.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
  return RegExp(r'(^|\s)what\s*:').hasMatch(lower) &&
      RegExp(r'(^|\s)why\s*:').hasMatch(lower) &&
      RegExp(r'(^|\s)impact\s*:').hasMatch(lower);
}

String _normalizeArticleBodyComparison(String value) {
  return value
      .replaceAll(
        RegExp(
          r'\b(what|why|impact|what happened|why it matters|investor impact)\s*:',
          caseSensitive: false,
        ),
        '',
      )
      .replaceAll(RegExp(r'[^\w가-힣%]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .toLowerCase();
}
