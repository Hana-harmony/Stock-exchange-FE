import 'package:flutter/foundation.dart';

import 'exchange_api_client.dart';
import 'notification_controller.dart';

enum MarketNewsStatus { idle, loading, loaded, failure }

class MarketNewsState {
  const MarketNewsState({
    required this.status,
    this.feed,
    this.errorMessage,
  });

  const MarketNewsState.idle()
      : status = MarketNewsStatus.idle,
        feed = null,
        errorMessage = null;

  const MarketNewsState.loading({this.feed})
      : status = MarketNewsStatus.loading,
        errorMessage = null;

  const MarketNewsState.loaded({required this.feed})
      : status = MarketNewsStatus.loaded,
        errorMessage = null;

  const MarketNewsState.failure({required this.errorMessage, this.feed})
      : status = MarketNewsStatus.failure;

  final MarketNewsStatus status;
  final MarketNewsFeed? feed;
  final String? errorMessage;
}

class MarketNewsController extends ValueNotifier<MarketNewsState> {
  MarketNewsController({required ExchangeApiClient apiClient})
      : _apiClient = apiClient,
        super(const MarketNewsState.idle());

  final ExchangeApiClient _apiClient;

  Future<void> loadLatest({int limit = 20}) async {
    value = MarketNewsState.loading(feed: value.feed);
    try {
      final response = await _apiClient.getMarketNews(limit: limit);
      value = MarketNewsState.loaded(
        feed: MarketNewsFeed.fromJson(response.data ?? {}),
      );
    } on ExchangeApiException catch (error) {
      value = MarketNewsState.failure(
        errorMessage: error.message,
        feed: value.feed,
      );
    } on Object {
      value = MarketNewsState.failure(
        errorMessage: 'Unable to load Korea market news.',
        feed: value.feed,
      );
    }
  }

  Future<MarketNewsFeed> loadTrending({
    int windowHours = 24,
    int limit = 10,
  }) async {
    final response = await _apiClient.getTrendingMarketNews(
      windowHours: windowHours,
      limit: limit,
    );
    return MarketNewsFeed.fromJson(response.data ?? {});
  }

  Future<MarketNewsItem> loadDetail(String newsId) async {
    final response = await _apiClient.getMarketNewsDetail(newsId);
    return MarketNewsItem.fromJson(response.data ?? {});
  }
}

class MarketNewsFeed {
  const MarketNewsFeed({
    required this.newsCount,
    required this.news,
  });

  final int newsCount;
  final List<MarketNewsItem> news;

  static MarketNewsFeed fromJson(Map<String, dynamic> json) {
    final newsValues = json['news'] is List
        ? json['news'] as List<Object?>
        : const <Object?>[];
    return MarketNewsFeed(
      newsCount: _int(json['newsCount']),
      news: newsValues
          .map((value) => MarketNewsItem.fromJson(_map(value)))
          .toList(),
    );
  }
}

class MarketNewsItem {
  const MarketNewsItem({
    required this.newsId,
    required this.query,
    required this.title,
    required this.translatedTitle,
    required this.summary,
    required this.summaryLines,
    required this.translatedSummary,
    required this.originalContent,
    required this.translatedContent,
    required this.imageUrls,
    required this.contentAvailability,
    required this.originalUrl,
    required this.canonicalUrl,
    required this.sourceLicensePolicy,
    required this.glossaryTerms,
    required this.sentiment,
    required this.importance,
    required this.duplicateKey,
    this.publishedAt,
    this.createdAt,
  });

  final String newsId;
  final String query;
  final String title;
  final String translatedTitle;
  final String summary;
  final AlertSummaryLines summaryLines;
  final String translatedSummary;
  final String originalContent;
  final String translatedContent;
  final List<String> imageUrls;
  final String contentAvailability;
  final String originalUrl;
  final String canonicalUrl;
  final String sourceLicensePolicy;
  final List<AlertGlossaryTerm> glossaryTerms;
  final String sentiment;
  final String importance;
  final String duplicateKey;
  final DateTime? publishedAt;
  final DateTime? createdAt;

  String get displayTitle =>
      translatedTitle.isNotEmpty ? translatedTitle : title;

  String get displayQuery => _englishMarketQueryLabel(query);

  String get displaySummary {
    if (summaryLines.hasAny) {
      return summaryLines.lines.join('\n');
    }
    return translatedSummary.isNotEmpty ? translatedSummary : summary;
  }

  String get displayBody {
    if (_isArticleBodyCandidate(
      translatedContent,
      summaryLines: summaryLines,
      translatedSummary: translatedSummary,
    )) {
      return translatedContent;
    }
    return '';
  }

  String? get imageUrl => imageUrls.isEmpty ? null : imageUrls.first;

  static MarketNewsItem fromJson(Map<String, dynamic> json) {
    return MarketNewsItem(
      newsId: _string(json['newsId'], fallback: ''),
      query: _string(json['query'], fallback: ''),
      title: _string(json['title'], fallback: 'Untitled market news'),
      translatedTitle: _string(json['translatedTitle'], fallback: ''),
      summary: _string(json['summary'], fallback: ''),
      summaryLines: AlertSummaryLines.fromJson(_map(json['summaryLines'])),
      translatedSummary: _string(json['translatedSummary'], fallback: ''),
      originalContent: _string(json['originalContent'], fallback: ''),
      translatedContent: _string(json['translatedContent'], fallback: ''),
      imageUrls: _stringList(json['imageUrls']),
      contentAvailability:
          _string(json['contentAvailability'], fallback: 'SUMMARY_ONLY'),
      originalUrl: _string(json['originalUrl'], fallback: ''),
      canonicalUrl: _string(json['canonicalUrl'], fallback: ''),
      sourceLicensePolicy: _string(json['sourceLicensePolicy'], fallback: ''),
      glossaryTerms: _glossaryTerms(json['glossaryTerms']),
      sentiment: _string(json['sentiment'], fallback: 'NEUTRAL'),
      importance: _string(json['importance'], fallback: 'MEDIUM'),
      duplicateKey: _string(json['duplicateKey'], fallback: ''),
      publishedAt: _dateTime(json['publishedAt']),
      createdAt: _dateTime(json['createdAt']),
    );
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry('$key', value));
  }
  return {};
}

String _string(Object? value, {required String fallback}) {
  if (value == null) {
    return fallback;
  }
  final text = '$value';
  return text.isEmpty ? fallback : text;
}

int _int(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse('$value') ?? 0;
}

DateTime? _dateTime(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}

List<String> _stringList(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value
      .map((item) => '$item'.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

List<AlertGlossaryTerm> _glossaryTerms(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value
      .map((item) => AlertGlossaryTerm.fromJson(_map(item)))
      .toList(growable: false);
}

String _englishMarketQueryLabel(String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) {
    return 'Korea Market';
  }
  if (normalized.contains('코스피') && normalized.contains('코스닥')) {
    return 'KOSPI/KOSDAQ';
  }
  if (normalized.contains('코스피')) {
    return 'KOSPI';
  }
  if (normalized.contains('코스닥')) {
    return 'KOSDAQ';
  }
  if (normalized.contains('국내') || normalized.contains('증시')) {
    return 'Korea Market';
  }
  return query;
}

bool _looksEnglish(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return false;
  }
  final hangulCount = RegExp(r'[가-힣]').allMatches(trimmed).length;
  final letterCount = RegExp(r'[A-Za-z]').allMatches(trimmed).length;
  if (hangulCount == 0) {
    return letterCount > 0;
  }
  return letterCount > hangulCount * 2;
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
  return _looksEnglish(trimmed) || RegExp(r'[가-힣]').hasMatch(trimmed);
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
