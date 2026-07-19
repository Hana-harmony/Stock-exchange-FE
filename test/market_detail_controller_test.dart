import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stock_exchange_fe/src/core/exchange_api_client.dart';
import 'package:stock_exchange_fe/src/core/market_detail_controller.dart';

void main() {
  test('loads stock detail chart and order book together', () async {
    final paths = <String>[];
    final controller = MarketDetailController(
      apiClient: ExchangeApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          paths.add(request.url.path);
          expect(request.url.queryParameters['currency'], 'USD');

          if (request.url.path.endsWith('/chart')) {
            expect(request.url.queryParameters['interval'], '1d');
            return _jsonResponse(_chartJson());
          }
          if (request.url.path.endsWith('/orderbook')) {
            return _jsonResponse(_orderBookJson());
          }
          return _jsonResponse(_detailJson());
        }),
      ),
    );
    addTearDown(controller.dispose);

    await controller.loadStock(
      stockCode: '005930',
      from: DateTime.utc(2026, 6, 1),
      to: DateTime.utc(2026, 6, 18),
    );

    expect(controller.value.status, MarketDetailStatus.loaded);
    expect(controller.value.detail?.stockName, 'Samsung Electronics');
    expect(controller.value.detail?.localCurrencyDisplay, 'USD 1,024.24');
    expect(controller.value.detail?.riskBadge, 'VI active');
    expect(controller.value.detail?.foreignLimitBuyWarning, isTrue);
    expect(controller.value.detail?.singlePriceTrading, isTrue);
    expect(
      controller.value.detail?.predictedOwnershipRangeDisplay,
      '55.20% - 55.45%',
    );
    expect(
      controller.value.detail?.predictedLimitRangeDisplay,
      '55.25% - 55.60%',
    );
    expect(
      controller.value.detail?.predictionModelDisplay,
      'hannah-foreign-ownership-timeseries-v1 / AI_TIME_SERIES_ADJUSTED 0.8',
    );
    expect(
      controller.value.chart?.latestPoint?.closeLocalDisplay,
      'USD 1,024.24',
    );
    expect(controller.value.orderBook?.bids.single.quantity, 1200);
    expect(
      controller.value.orderBook?.bestAsk?.displayPrice('KRW', 'USD'),
      'KRW 82,500 / USD 1,024.31',
    );
    expect(
      controller.value.orderBook?.bestBid?.displayPrice('KRW', 'USD'),
      'KRW 82,400 / USD 1,024.24',
    );
    expect(paths, [
      '/api/v1/stocks/005930',
      '/api/v1/market/stocks/005930/chart',
      '/api/v1/market/stocks/005930/orderbook',
    ]);
  });

  test('keeps partial detail data when a secondary detail API fails', () async {
    final paths = <String>[];
    final controller = MarketDetailController(
      apiClient: ExchangeApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          paths.add(request.url.path);

          if (request.url.path.endsWith('/chart')) {
            return http.Response(
              jsonEncode({
                'success': false,
                'status': 503,
                'code': 'MARKET_002',
                'message': 'Chart provider is temporarily unavailable',
                'timestamp': '2026-06-18T06:00:00Z',
              }),
              503,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path.endsWith('/orderbook')) {
            return _jsonResponse(_orderBookJson());
          }
          return _jsonResponse(_detailJson());
        }),
      ),
    );
    addTearDown(controller.dispose);

    await controller.loadStock(
      stockCode: '005930',
      from: DateTime.utc(2026, 6, 1),
      to: DateTime.utc(2026, 6, 18),
    );

    expect(controller.value.status, MarketDetailStatus.failure);
    expect(controller.value.detail?.stockName, 'Samsung Electronics');
    expect(controller.value.chart, isNull);
    expect(controller.value.orderBook?.bids.single.quantity, 1200);
    expect(
      controller.value.errorMessage,
      'Market data is temporarily unavailable.',
    );
    expect(paths, [
      '/api/v1/stocks/005930',
      '/api/v1/market/stocks/005930/chart',
      '/api/v1/market/stocks/005930/orderbook',
    ]);
  });

  test('starts stock detail chart and order book requests together', () async {
    final startedPaths = <String>[];
    final detailCompleter = Completer<http.Response>();
    final chartCompleter = Completer<http.Response>();
    final orderBookCompleter = Completer<http.Response>();
    final controller = MarketDetailController(
      apiClient: ExchangeApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) {
          startedPaths.add(request.url.path);

          if (request.url.path.endsWith('/chart')) {
            return chartCompleter.future;
          }
          if (request.url.path.endsWith('/orderbook')) {
            return orderBookCompleter.future;
          }
          return detailCompleter.future;
        }),
      ),
    );
    addTearDown(controller.dispose);

    final loadFuture = controller.loadStock(
      stockCode: '005930',
      from: DateTime.utc(2026, 6, 1),
      to: DateTime.utc(2026, 6, 18),
    );
    await Future<void>.delayed(Duration.zero);

    expect(startedPaths, [
      '/api/v1/stocks/005930',
      '/api/v1/market/stocks/005930/chart',
      '/api/v1/market/stocks/005930/orderbook',
    ]);

    detailCompleter.complete(_jsonResponse(_detailJson()));
    chartCompleter.complete(_jsonResponse(_chartJson()));
    orderBookCompleter.complete(_jsonResponse(_orderBookJson()));
    await loadFuture;

    expect(controller.value.status, MarketDetailStatus.loaded);
  });

  test('rejects invalid stock code before calling API', () async {
    var called = false;
    final controller = MarketDetailController(
      apiClient: ExchangeApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          called = true;
          return _jsonResponse({});
        }),
      ),
    );
    addTearDown(controller.dispose);

    await controller.loadStock(stockCode: 'ABC');

    expect(called, isFalse);
    expect(controller.value.status, MarketDetailStatus.failure);
    expect(controller.value.errorMessage, 'Enter a 6 digit Korean stock code.');
  });

  test('refreshes order book without reloading detail or chart', () async {
    final paths = <String>[];
    var orderBookCalls = 0;
    final controller = MarketDetailController(
      apiClient: ExchangeApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          paths.add(request.url.path);

          if (request.url.path.endsWith('/chart')) {
            return _jsonResponse(_chartJson());
          }
          if (request.url.path.endsWith('/orderbook')) {
            orderBookCalls += 1;
            return _jsonResponse(
              _orderBookJson(bidQuantity: orderBookCalls == 1 ? 1200 : 2400),
            );
          }
          return _jsonResponse(_detailJson());
        }),
      ),
    );
    addTearDown(controller.dispose);

    await controller.loadStock(
      stockCode: '005930',
      from: DateTime.utc(2026, 6, 1),
      to: DateTime.utc(2026, 6, 18),
    );
    await controller.refreshOrderBook(stockCode: '005930');

    expect(controller.value.status, MarketDetailStatus.loaded);
    expect(controller.value.detail?.stockName, 'Samsung Electronics');
    expect(controller.value.chart?.pointCount, 1);
    expect(controller.value.orderBook?.bestBid?.quantity, 2400);
    expect(paths, [
      '/api/v1/stocks/005930',
      '/api/v1/market/stocks/005930/chart',
      '/api/v1/market/stocks/005930/orderbook',
      '/api/v1/market/stocks/005930/orderbook',
    ]);
  });

  test('hides upstream market json when stock detail provider is unavailable',
      () async {
    final controller = MarketDetailController(
      apiClient: ExchangeApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': false,
              'status': 503,
              'code': 'MARKET_002',
              'message':
                  'No live provider price is available for stockCode=000660',
              'timestamp': '2026-06-24T04:55:13Z',
            }),
            503,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );
    addTearDown(controller.dispose);

    await controller.loadStock(stockCode: '000660');

    expect(controller.value.status, MarketDetailStatus.failure);
    expect(
      controller.value.errorMessage,
      'Market data is temporarily unavailable.',
    );
  });

  test('parses complete global comparison contract and keeps brand names', () {
    final match = GlobalPeerMatch.fromJson(_globalPeerInsightJson());

    expect(match.comparisons, hasLength(1));
    expect(match.keyStrengths, hasLength(4));
    expect(
      match.comparisons.single.peer.comparisonLabel,
      'Bank of America',
    );
  });

  test('hides the whole insight when a nested contract is malformed', () {
    final missingStrength = _globalPeerInsightJson();
    (missingStrength['keyStrengths'] as List<Object?>).removeLast();

    final invalidIcon = _globalPeerInsightJson();
    ((invalidIcon['keyStrengths'] as List<Object?>).first
        as Map<String, Object?>)['iconKey'] = 'untrusted_icon';

    final missingPeer = _globalPeerInsightJson();
    ((missingPeer['comparisons'] as List<Object?>).first
        as Map<String, Object?>)['peer'] = <String, Object?>{};

    for (final payload in [missingStrength, invalidIcon, missingPeer]) {
      final match = GlobalPeerMatch.fromJson(payload);
      expect(match.comparisons, isEmpty);
      expect(match.keyStrengths, isEmpty);
    }
  });
}

Map<String, dynamic> _globalPeerInsightJson() {
  return {
    'stockCode': '005930',
    'stockName': 'Samsung Electronics',
    'headline': "Samsung Electronics is the 'Apple + TSMC' of South Korea",
    'summary': 'Diversified technology profile.',
    'primaryPeer': {
      'rank': 1,
      'ticker': 'AAPL',
      'companyName': 'Apple Inc.',
    },
    'peers': <Object?>[],
    'comparisons': [
      {
        'dimension': 'financial_services',
        'description': 'A diversified global financial-services benchmark.',
        'peer': {
          'rank': 1,
          'ticker': 'BAC',
          'companyName': 'Bank of America Corporation',
          'logoUrl': 'https://financialmodelingprep.com/image-stock/BAC.png',
        },
      },
    ],
    'keyStrengths': [
      {
        'title': 'Memory Leadership',
        'description': 'Global memory market position',
        'iconKey': 'memory',
      },
      {
        'title': 'Foundry Technology',
        'description': 'Advanced process capability',
        'iconKey': 'foundry',
      },
      {
        'title': 'Device Ecosystem',
        'description': 'Connected consumer devices',
        'iconKey': 'ecosystem',
      },
      {
        'title': 'AI Infrastructure',
        'description': 'AI data-center demand exposure',
        'iconKey': 'ai',
      },
    ],
    'confidenceScore': '0.9',
    'confidenceLevel': 'HIGH',
    'modelVersion': 'test',
    'dataSource': 'Hana-Omni-Connect-API',
  };
}

http.Response _jsonResponse(Map<String, Object?> data) {
  return http.Response(
    jsonEncode({
      'success': true,
      'status': 200,
      'code': 'COMMON_000',
      'message': 'OK',
      'data': data,
      'timestamp': '2026-06-18T06:00:00Z',
    }),
    200,
    headers: {'content-type': 'application/json'},
  );
}

Map<String, Object?> _detailJson() {
  return {
    'stockCode': '005930',
    'stockName': 'Samsung Electronics',
    'market': 'KOSPI',
    'sector': 'Semiconductor',
    'baseCurrency': 'KRW',
    'displayCurrency': 'USD',
    'currentPriceKrw': '82400',
    'localCurrencyPrice': '1024.24',
    'changeRate': '+1.23%',
    'volume': 18300000,
    'marketDataTime': '2026-06-18T06:00:00Z',
    'foreignOwnershipRate': '55.31',
    'foreignLimitExhaustionRate': '55.31',
    'predictedForeignOwnershipRateMin': '55.20',
    'predictedForeignOwnershipRateMax': '55.45',
    'predictedForeignLimitExhaustionRateMin': '55.25',
    'predictedForeignLimitExhaustionRateMax': '55.60',
    'foreignOwnershipPredictionConfidenceLevel': 'AI_TIME_SERIES_ADJUSTED',
    'foreignOwnershipPredictionConfidenceScore': '0.8',
    'foreignOwnershipPredictionModelVersion':
        'hannah-foreign-ownership-timeseries-v1',
    'foreignOwnershipBaseDate': '2026-06-18',
    'foreignLimitBuyWarning': true,
    'viActive': true,
    'singlePriceTrading': true,
    'priceLimitState': 'NORMAL',
    'tradingHalted': false,
    'orderable': true,
    'dataSource': 'Hana-Omni-Connect-API',
    'servedAt': '2026-06-18T06:00:01Z',
  };
}

Map<String, Object?> _chartJson() {
  return {
    'dataSource': 'Hana-Omni-Connect-API',
    'stockCode': '005930',
    'interval': '1d',
    'from': '2026-06-01',
    'to': '2026-06-18',
    'baseCurrency': 'KRW',
    'displayCurrency': 'USD',
    'pointCount': 1,
    'points': [
      {
        'tradeDate': '2026-06-18',
        'openPriceKrw': '81000',
        'highPriceKrw': '82900',
        'lowPriceKrw': '80500',
        'closePriceKrw': '82400',
        'localCurrency': 'USD',
        'closeLocalCurrencyPrice': '1024.24',
        'volume': 18300000,
        'adjusted': false,
      }
    ],
    'servedAt': '2026-06-18T06:00:01Z',
  };
}

Map<String, Object?> _orderBookJson({
  int askQuantity = 800,
  int bidQuantity = 1200,
}) {
  return {
    'dataSource': 'Hana-Omni-Connect-API',
    'stockCode': '005930',
    'market': 'KOSPI',
    'baseCurrency': 'KRW',
    'displayCurrency': 'USD',
    'asks': [
      {
        'priceKrw': '82500',
        'localCurrencyPrice': '1024.31',
        'quantity': askQuantity,
        'orderCount': 12,
      }
    ],
    'bids': [
      {
        'priceKrw': '82400',
        'localCurrencyPrice': '1024.24',
        'quantity': bidQuantity,
        'orderCount': 19,
      }
    ],
    'marketDataTime': '2026-06-18T06:00:00Z',
    'servedAt': '2026-06-18T06:00:01Z',
  };
}
