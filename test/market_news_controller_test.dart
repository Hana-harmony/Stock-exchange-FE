import 'package:flutter_test/flutter_test.dart';
import 'package:stock_exchange_fe/src/core/market_news_controller.dart';

void main() {
  test('merges cursor pages without duplicate market news ids', () {
    final first = MarketNewsFeed.fromJson({
      'newsCount': 2,
      'nextCursor': 'cursor-2',
      'news': [
        {'newsId': 'mkt-1'},
        {'newsId': 'mkt-2'},
      ],
    });
    final second = MarketNewsFeed.fromJson({
      'newsCount': 2,
      'nextCursor': null,
      'news': [
        {'newsId': 'mkt-2'},
        {'newsId': 'mkt-3'},
      ],
    });

    final merged = first.merge(second);

    expect(merged.news.map((item) => item.newsId), ['mkt-1', 'mkt-2', 'mkt-3']);
    expect(merged.nextCursor, isNull);
  });

  test('does not treat What Why Impact summary as market news body', () {
    final item = MarketNewsItem.fromJson({
      'newsId': 'mkt-1',
      'query': '한국 증시',
      'title': '시장 뉴스',
      'translatedTitle': 'Market news',
      'summary': '요약',
      'summaryLines': {
        'what': 'KOSPI rose on foreign buying.',
        'why': 'The article cites stronger semiconductor demand.',
        'impact': 'Investors should monitor index breadth.',
      },
      'translatedSummary':
          'KOSPI rose on foreign buying. The article cites stronger semiconductor demand. Investors should monitor index breadth.',
      'originalContent':
          '코스피는 외국인 순매수와 반도체 수요 회복 기대에 상승했다. 기사 원문은 장중 수급과 업종별 흐름을 상세히 설명한다.',
      'translatedContent':
          'What: KOSPI rose on foreign buying. Why: The article cites stronger semiconductor demand. Impact: Investors should monitor index breadth.',
      'imageUrls': <String>[],
      'contentAvailability': 'FULL_TEXT',
      'originalUrl': 'https://news.example.com/market/1',
      'canonicalUrl': 'https://news.example.com/market/1',
      'sourceLicensePolicy': 'licensed_naver_original_full_text_v1',
      'glossaryTerms': <Object>[],
      'sentiment': 'POSITIVE',
      'importance': 'MEDIUM',
      'duplicateKey': 'mkt-duplicate',
      'publishedAt': '2026-06-18T06:00:00Z',
      'createdAt': '2026-06-18T06:01:00Z',
    });

    expect(item.displayBody, isEmpty);
    expect(item.displayBody, isNot(contains('What:')));
  });

  test('does not treat translation fallback notice as market news body', () {
    final item = MarketNewsItem.fromJson({
      'newsId': 'mkt-2',
      'query': '한국 증시',
      'title': '시장 뉴스',
      'translatedTitle': 'Market news',
      'summary': '요약',
      'summaryLines': {
        'what': 'KOSPI rose on foreign buying.',
        'why': 'The article cites stronger semiconductor demand.',
        'impact': 'Investors should monitor index breadth.',
      },
      'translatedSummary': 'Translated summary.',
      'originalContent': '실제 원문 전문입니다. 번역 실패 시 이 원문은 본문으로 표시하지 않습니다.',
      'translatedContent':
          'The original Korean text is retained because machine translation was unavailable. Review the linked article or filing for price, liquidity, and portfolio impact.',
      'imageUrls': <String>[],
      'contentAvailability': 'ORIGINAL_TEXT_ONLY',
      'originalUrl': 'https://news.example.com/market/2',
      'canonicalUrl': 'https://news.example.com/market/2',
      'sourceLicensePolicy': 'licensed_naver_original_full_text_v1',
      'glossaryTerms': <Object>[],
      'sentiment': 'NEUTRAL',
      'importance': 'MEDIUM',
      'duplicateKey': 'mkt-duplicate-2',
    });

    expect(item.displayBody, isEmpty);
    expect(item.displayBody, isNot(contains('machine translation')));
  });

  test('preserves translated article paragraphs and line breaks', () {
    final item = MarketNewsItem.fromJson({
      'newsId': 'mkt-3',
      'translatedContent':
          'The market opened higher.\nForeign investors led buying.\n\nSemiconductor shares outperformed.',
      'contentAvailability': 'FULL_TEXT',
    });

    expect(
      item.displayBody,
      'The market opened higher.\nForeign investors led buying.\n\nSemiconductor shares outperformed.',
    );
  });
}
