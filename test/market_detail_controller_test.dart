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
    expect(controller.value.detail?.localCurrencyDisplay, 'USD 54.01');
    expect(controller.value.detail?.riskBadge, 'VI active');
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
      'USD 54.01',
    );
    expect(controller.value.orderBook?.bids.single.quantity, 1200);
    expect(
      controller.value.orderBook?.bestAsk?.displayPrice('KRW', 'USD'),
      'KRW 82500 / USD 54.08',
    );
    expect(
      controller.value.orderBook?.bestBid?.displayPrice('KRW', 'USD'),
      'KRW 82400 / USD 54.01',
    );
    expect(paths, [
      '/api/v1/stocks/005930',
      '/api/v1/market/stocks/005930/chart',
      '/api/v1/market/stocks/005930/orderbook',
    ]);
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
    'localCurrencyPrice': '54.01',
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
    'viActive': true,
    'singlePriceTrading': true,
    'priceLimitState': 'NORMAL',
    'tradingHalted': false,
    'orderable': true,
    'dataSource': 'Hana-OmniLens-API',
    'servedAt': '2026-06-18T06:00:01Z',
  };
}

Map<String, Object?> _chartJson() {
  return {
    'dataSource': 'Hana-OmniLens-API',
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
        'closeLocalCurrencyPrice': '54.01',
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
    'dataSource': 'Hana-OmniLens-API',
    'stockCode': '005930',
    'market': 'KOSPI',
    'baseCurrency': 'KRW',
    'displayCurrency': 'USD',
    'asks': [
      {
        'priceKrw': '82500',
        'localCurrencyPrice': '54.08',
        'quantity': askQuantity,
        'orderCount': 12,
      }
    ],
    'bids': [
      {
        'priceKrw': '82400',
        'localCurrencyPrice': '54.01',
        'quantity': bidQuantity,
        'orderCount': 19,
      }
    ],
    'marketDataTime': '2026-06-18T06:00:00Z',
    'servedAt': '2026-06-18T06:00:01Z',
  };
}
