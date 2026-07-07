import 'package:flutter_test/flutter_test.dart';
import 'package:stock_exchange_fe/src/core/market_news_controller.dart';

void main() {
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

    expect(item.displayBody, item.originalContent);
    expect(item.displayBody, isNot(contains('What:')));
  });
}
