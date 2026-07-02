import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stock_exchange_fe/src/core/exchange_api_client.dart';
import 'package:stock_exchange_fe/src/core/trade_controller.dart';

void main() {
  test('checks orderability warnings before mock order', () async {
    final controller = TradeController(
      apiClient: _client((request) async {
        expect(
          request.url.path,
          '/api/v1/accounts/ACC-ABC123456789/trades/orderability',
        );
        expect(request.url.queryParameters['stockCode'], '005930');
        expect(request.url.queryParameters['side'], 'BUY');
        expect(request.url.queryParameters['quantity'], '2');

        return _jsonResponse({
          'success': true,
          'status': 200,
          'code': 'COMMON_000',
          'message': 'OK',
          'data': {
            'stockCode': '005930',
            'side': 'BUY',
            'quantity': 2,
            'canPlaceMockOrder': true,
            'blockingReasons': [],
            'warnings': [
              'VI_ACTIVE',
              'SINGLE_PRICE_TRADING',
              'BUY_AT_UPPER_LIMIT',
            ],
            'orderabilitySource': 'Hana-OmniLens-API',
            'tradingMode': 'EXCHANGE_MOCK_LEDGER_NOT_KIS_MOCK_TRADING',
          },
          'timestamp': '2026-06-18T06:00:00Z',
        });
      }),
    );

    await controller.checkOrderability(
      accountId: 'ACC-ABC123456789',
      stockCode: '005930',
      side: 'BUY',
      quantity: 2,
    );

    expect(controller.value.status, TradeStatus.loaded);
    expect(
      controller.value.orderability?.summary,
      contains('Volatility interruption is active'),
    );
    expect(
      controller.value.orderability?.summary,
      contains('Single-price trading is active'),
    );
    expect(
      controller.value.orderability?.summary,
      contains('Buy order is at the upper price limit'),
    );
  });

  test('formats blocking reasons for users', () async {
    final controller = TradeController(
      apiClient: _client((request) async => _jsonResponse({
            'success': true,
            'status': 200,
            'code': 'COMMON_000',
            'message': 'OK',
            'data': {
              'stockCode': '005930',
              'side': 'BUY',
              'quantity': 1,
              'canPlaceMockOrder': false,
              'blockingReasons': ['FOREIGN_LIMIT_EXCEEDED'],
              'warnings': [],
              'orderabilitySource': 'Hana-OmniLens-API',
              'tradingMode': 'EXCHANGE_MOCK_LEDGER_NOT_KIS_MOCK_TRADING',
            },
            'timestamp': '2026-06-18T06:00:00Z',
          })),
    );

    await controller.checkOrderability(
      accountId: 'ACC-ABC123456789',
      stockCode: '005930',
      side: 'BUY',
      quantity: 1,
    );

    expect(
      controller.value.orderability?.summary,
      'Blocked: This buy order may not be filled if the foreign ownership limit is reached',
    );
  });

  test('executes mock trade and refreshes portfolio', () async {
    final paths = <String>[];
    final controller = TradeController(
      apiClient: _client((request) async {
        paths.add('${request.method} ${request.url.path}');
        if (request.method == 'POST') {
          expect(jsonDecode(request.body), {
            'stockCode': '005930',
            'side': 'BUY',
            'quantity': 2,
            'orderType': 'LIMIT',
            'limitPriceUsd': 50.0,
          });
          return _jsonResponse({
            'success': true,
            'status': 200,
            'code': 'COMMON_000',
            'message': 'OK',
            'data': _orderJson(tradeExecution: _tradeJson()),
            'timestamp': '2026-06-18T06:00:00Z',
          });
        }
        if (request.url.path.endsWith('/orders')) {
          return _jsonResponse({
            'success': true,
            'status': 200,
            'code': 'COMMON_000',
            'message': 'OK',
            'data': {
              'accountId': 'ACC-ABC123456789',
              'orderCount': 1,
              'orders': [_orderJson(tradeExecution: _tradeJson())],
            },
            'timestamp': '2026-06-18T06:00:00Z',
          });
        }

        return _jsonResponse({
          'success': true,
          'status': 200,
          'code': 'COMMON_000',
          'message': 'OK',
          'data': _portfolioJson(),
          'timestamp': '2026-06-18T06:00:00Z',
        });
      }),
    );

    await controller.executeTrade(
      accountId: 'ACC-ABC123456789',
      stockCode: '005930',
      side: 'BUY',
      quantity: 2,
      limitPriceUsd: 50.00,
    );

    expect(paths, [
      'POST /api/v1/accounts/ACC-ABC123456789/trades',
      'GET /api/v1/accounts/ACC-ABC123456789/portfolio',
      'GET /api/v1/accounts/ACC-ABC123456789/trades',
      'GET /api/v1/accounts/ACC-ABC123456789/orders',
    ]);
    expect(controller.value.lastTrade?.stockName, 'Samsung Electronics');
    expect(controller.value.portfolio?.holdings.single.quantity, 2);
  });

  test('keeps sell trade realized PnL for tax refund input', () async {
    final controller = TradeController(
      apiClient: _client((request) async {
        if (request.method == 'POST') {
          expect(jsonDecode(request.body), {
            'stockCode': '005930',
            'side': 'SELL',
            'quantity': 1,
            'orderType': 'LIMIT',
            'limitPriceUsd': 70.0,
          });
          final trade = _tradeJson(
            side: 'SELL',
            quantity: 1,
            realizedPnlUsd: '20.00',
            remainingQuantity: 1,
          );
          return _jsonResponse({
            'success': true,
            'status': 200,
            'code': 'COMMON_000',
            'message': 'OK',
            'data':
                _orderJson(side: 'SELL', quantity: 1, tradeExecution: trade),
            'timestamp': '2026-06-18T06:00:00Z',
          });
        }
        if (request.url.path.endsWith('/orders')) {
          return _jsonResponse({
            'success': true,
            'status': 200,
            'code': 'COMMON_000',
            'message': 'OK',
            'data': {
              'accountId': 'ACC-ABC123456789',
              'orderCount': 1,
              'orders': [
                _orderJson(
                  side: 'SELL',
                  quantity: 1,
                  tradeExecution: _tradeJson(
                    side: 'SELL',
                    quantity: 1,
                    realizedPnlUsd: '20.00',
                    remainingQuantity: 1,
                  ),
                )
              ],
            },
            'timestamp': '2026-06-18T06:00:00Z',
          });
        }

        return _jsonResponse({
          'success': true,
          'status': 200,
          'code': 'COMMON_000',
          'message': 'OK',
          'data': _portfolioJson(
            realizedPnlUsd: '20.00',
            recentTrades: [
              _tradeJson(
                side: 'SELL',
                quantity: 1,
                realizedPnlUsd: '20.00',
                remainingQuantity: 1,
              ),
            ],
          ),
          'timestamp': '2026-06-18T06:00:00Z',
        });
      }),
    );

    await controller.executeTrade(
      accountId: 'ACC-ABC123456789',
      stockCode: '005930',
      side: 'SELL',
      quantity: 1,
      limitPriceUsd: 70.00,
    );

    expect(controller.value.lastTrade?.isSell, isTrue);
    expect(controller.value.lastTrade?.realizedPnlDisplay, 'USD 20.00');
    expect(controller.value.portfolio?.realizedPnlUsd, '20.00');
    expect(controller.value.portfolio?.recentTrades.single.isSell, isTrue);
  });

  test('validates sign in stock code and quantity before API call', () async {
    var requestCount = 0;
    final controller = TradeController(
      apiClient: _client((request) async {
        requestCount++;
        return _jsonResponse({});
      }),
    );

    await controller.executeTrade(
      accountId: null,
      stockCode: '005930',
      side: 'BUY',
      quantity: 1,
      limitPriceUsd: 50.00,
    );
    expect(controller.value.errorMessage, 'Sign in before placing an order.');

    await controller.checkOrderability(
      accountId: 'ACC-ABC123456789',
      stockCode: 'ABCDEF',
      side: 'BUY',
      quantity: 1,
    );
    expect(controller.value.errorMessage, 'Enter a 6 digit Korean stock code.');

    await controller.checkOrderability(
      accountId: 'ACC-ABC123456789',
      stockCode: '005930',
      side: 'BUY',
      quantity: 0,
    );
    expect(controller.value.errorMessage, 'Quantity must be at least 1.');
    expect(requestCount, 0);
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

Map<String, Object?> _tradeJson({
  String side = 'BUY',
  int quantity = 2,
  String realizedPnlUsd = '0.00',
  int remainingQuantity = 2,
}) {
  return {
    'tradeId': 'TRD-1',
    'accountId': 'ACC-ABC123456789',
    'stockCode': '005930',
    'stockName': 'Samsung Electronics',
    'side': side,
    'quantity': quantity,
    'executionPriceUsd': '50.00',
    'grossAmountUsd': (50 * quantity).toStringAsFixed(2),
    'realizedPnlUsd': realizedPnlUsd,
    'remainingQuantity': remainingQuantity,
    'cashBalanceUsdAfter': '100.00',
    'tradingMode': 'EXCHANGE_MOCK_LEDGER_NOT_KIS_MOCK_TRADING',
  };
}

Map<String, Object?> _orderJson({
  String side = 'BUY',
  int quantity = 2,
  Map<String, Object?>? tradeExecution,
}) {
  return {
    'orderId': 'ORD-1',
    'accountId': 'ACC-ABC123456789',
    'stockCode': '005930',
    'stockName': 'Samsung Electronics',
    'side': side,
    'quantity': quantity,
    'orderType': 'LIMIT',
    'limitPriceUsd': side == 'SELL' ? '70.00' : '50.00',
    'observedPriceUsd': side == 'SELL' ? '70.00' : '50.00',
    'status': tradeExecution == null ? 'PENDING' : 'FILLED',
    'message': tradeExecution == null ? 'Pending' : 'Filled',
    'tradeExecution': tradeExecution,
  };
}

Map<String, Object?> _portfolioJson({
  String realizedPnlUsd = '0.00',
  List<Map<String, Object?>>? recentTrades,
}) {
  return {
    'accountId': 'ACC-ABC123456789',
    'currency': 'USD',
    'cashBalanceUsd': '100.00',
    'totalMarketValueUsd': '110.00',
    'totalAssetValueUsd': '210.00',
    'realizedPnlUsd': realizedPnlUsd,
    'unrealizedPnlUsd': '10.00',
    'tradingMode': 'EXCHANGE_MOCK_LEDGER_NOT_KIS_MOCK_TRADING',
    'holdings': [
      {
        'stockCode': '005930',
        'stockName': 'Samsung Electronics',
        'quantity': 2,
        'averagePriceUsd': '50.00',
        'currentPriceUsd': '55.00',
        'marketValueUsd': '110.00',
        'unrealizedPnlUsd': '10.00',
        'unrealizedPnlRate': '10.00',
      }
    ],
    'recentTrades': recentTrades ?? [_tradeJson()],
  };
}

http.Response _jsonResponse(Map<String, Object?> body) {
  return http.Response(
    jsonEncode(body),
    200,
    headers: {'content-type': 'application/json'},
  );
}
