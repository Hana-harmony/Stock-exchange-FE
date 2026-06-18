import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stock_exchange_fe/src/core/exchange_api_client.dart';
import 'package:stock_exchange_fe/src/core/market_quote_controller.dart';

void main() {
  test('loads REST market quote snapshot from Stock-exchange-BE', () async {
    final controller = MarketQuoteController(
      apiClient: _client((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/market/quotes');
        expect(request.url.queryParameters['market'], 'KOSPI');
        expect(request.url.queryParameters['currency'], 'USD');

        return _jsonResponse({
          'success': true,
          'status': 200,
          'code': 'COMMON_000',
          'message': 'OK',
          'data': _snapshotJson(),
          'timestamp': '2026-06-18T06:00:00Z',
        });
      }),
      seedQuotes: seedMarketQuotes,
    );

    await controller.loadSnapshot(market: 'KOSPI');

    expect(controller.value.status, MarketQuoteStatus.loaded);
    expect(controller.value.snapshot?.cacheStatus, 'FRESH_CACHE');
    expect(controller.value.quotes.single.stockName, 'Samsung Electronics');
    expect(controller.value.quotes.single.localCurrencyDisplay, 'USD 54.00');
    expect(controller.value.quotes.single.fxMeta, contains('Hana-OmniLens-API'));
  });

  test('keeps visible quotes when snapshot request fails', () async {
    final controller = MarketQuoteController(
      apiClient: _client((request) async {
        return _jsonResponse(
          {
            'success': false,
            'status': 502,
            'code': 'MARKET_001',
            'message': 'Hana OmniLens market upstream unavailable',
            'timestamp': '2026-06-18T06:00:00Z',
          },
          statusCode: 502,
        );
      }),
      seedQuotes: seedMarketQuotes,
    );

    await controller.loadSnapshot();

    expect(controller.value.status, MarketQuoteStatus.failure);
    expect(
      controller.value.errorMessage,
      'Hana OmniLens market upstream unavailable',
    );
    expect(controller.value.quotes, seedMarketQuotes);
  });

  test('requires sign in before account scoped snapshots', () async {
    var requestCount = 0;
    final controller = MarketQuoteController(
      apiClient: _client((request) async {
        requestCount++;
        return _jsonResponse({});
      }),
    );

    await controller.loadPortfolioSnapshot(accountId: null);
    await controller.loadWatchlistSnapshot(accountId: '');

    expect(requestCount, 0);
    expect(controller.value.status, MarketQuoteStatus.failure);
    expect(controller.value.errorMessage, 'Sign in to load watchlist quotes.');
  });

  test('loads portfolio quote snapshot for signed-in account', () async {
    final controller = MarketQuoteController(
      apiClient: _client((request) async {
        expect(
          request.url.path,
          '/api/v1/accounts/ACC-ABC123456789/market/quotes/portfolio',
        );
        expect(request.url.queryParameters['currency'], 'USD');

        return _jsonResponse({
          'success': true,
          'status': 200,
          'code': 'COMMON_000',
          'message': 'OK',
          'data': _snapshotJson(stockName: 'NAVER', stockCode: '035420'),
          'timestamp': '2026-06-18T06:00:00Z',
        });
      }),
    );

    await controller.loadPortfolioSnapshot(accountId: 'ACC-ABC123456789');

    expect(controller.value.status, MarketQuoteStatus.loaded);
    expect(controller.value.quotes.single.stockName, 'NAVER');
  });
}

ExchangeApiClient _client(
  Future<http.Response> Function(http.Request request) handler,
) {
  return ExchangeApiClient(
    baseUri: Uri.parse('http://localhost:3000'),
    httpClient: MockClient(handler),
  );
}

Map<String, Object?> _snapshotJson({
  String stockName = 'Samsung Electronics',
  String stockCode = '005930',
}) {
  return {
    'dataSource': 'Hana-OmniLens-API',
    'marketCoverage': 'KOSPI',
    'userLanguage': 'en',
    'displayCurrency': 'USD',
    'tradingMode': 'MOCK_LEDGER_ONLY',
    'transport': {
      'snapshot': 'REST',
      'realtime': 'WebSocket',
    },
    'cache': {
      'status': 'FRESH_CACHE',
      'cachedAt': '2026-06-18T06:00:00Z',
      'expiresAt': '2026-06-18T06:00:05Z',
      'staleUntil': '2026-06-18T06:00:30Z',
    },
    'quoteCount': 1,
    'quotes': [
      {
        'stockCode': stockCode,
        'stockName': stockName,
        'market': 'KOSPI',
        'currentPriceKrw': '82400',
        'changeRate': '+1.23%',
        'volume': 18300000,
        'localCurrency': 'USD',
        'localCurrencyPrice': '54.00',
        'fxRate': '1525.93',
        'fxRateTime': '2026-06-18T06:00:00Z',
        'fxRateSource': 'Hana-OmniLens-API',
        'fxStale': false,
      }
    ],
    'servedAt': '2026-06-18T06:00:01Z',
  };
}

http.Response _jsonResponse(
  Map<String, Object?> body, {
  int statusCode = 200,
}) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: {'content-type': 'application/json'},
  );
}
