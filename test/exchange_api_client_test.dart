import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stock_exchange_fe/src/core/exchange_api_client.dart';

void main() {
  test('login parses Stock-exchange-BE auth session envelope', () async {
    final client = ExchangeApiClient(
      baseUri: Uri.parse('http://localhost:3000'),
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/auth/login');
        expect(_header(request, 'content-type'), 'application/json');
        expect(jsonDecode(request.body), {
          'username': 'hana',
          'password': 'secret',
        });

        return _jsonResponse({
          'success': true,
          'status': 200,
          'code': 'COMMON_000',
          'message': 'OK',
          'data': {
            'username': 'hana',
            'accountId': 'ACC-ABC123456789',
            'tokenType': 'Bearer',
            'accessToken': 'access-token',
            'refreshToken': 'refresh-token',
            'accessTokenExpiresAt': '2026-06-18T07:00:00Z',
            'refreshTokenExpiresAt': '2026-06-19T07:00:00Z',
          },
          'timestamp': '2026-06-18T06:00:00Z',
        });
      }),
    );

    final session = await client.login(username: 'hana', password: 'secret');

    expect(session.username, 'hana');
    expect(session.accountId, 'ACC-ABC123456789');
    expect(session.authHeaders['Authorization'], 'Bearer access-token');
    expect(session.accessTokenExpiresAt?.toUtc().year, 2026);
  });

  test('auth session serializes for secure session storage', () {
    final session = AuthSession.fromJson({
      'username': 'hana',
      'accountId': 'ACC-ABC123456789',
      'tokenType': 'Bearer',
      'accessToken': 'access-token',
      'refreshToken': 'refresh-token',
      'accessTokenExpiresAt': '2026-06-18T07:00:00Z',
      'refreshTokenExpiresAt': '2026-06-19T07:00:00Z',
    });

    expect(session.toJson(), {
      'username': 'hana',
      'accountId': 'ACC-ABC123456789',
      'tokenType': 'Bearer',
      'accessToken': 'access-token',
      'refreshToken': 'refresh-token',
      'accessTokenExpiresAt': '2026-06-18T07:00:00.000Z',
      'refreshTokenExpiresAt': '2026-06-19T07:00:00.000Z',
    });
  });

  test('market quote snapshot sends query and bearer token', () async {
    const session = AuthSession(
      username: 'hana',
      accountId: 'ACC-ABC123456789',
      tokenType: 'Bearer',
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
    final client = ExchangeApiClient(
      baseUri: Uri.parse('http://localhost:3000'),
      sessionProvider: () => session,
      httpClient: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/market/quotes');
        expect(request.url.queryParameters['market'], 'KOSPI');
        expect(request.url.queryParameters['currency'], 'USD');
        expect(request.url.queryParameters.containsKey('limit'), isFalse);
        expect(_header(request, 'authorization'), 'Bearer access-token');

        return _jsonResponse({
          'success': true,
          'status': 200,
          'code': 'COMMON_000',
          'message': 'OK',
          'data': {
            'quotes': [
              {
                'stockCode': '005930',
                'priceKrw': 82400,
                'priceUsd': 54.00,
              }
            ],
            'fxRateSource': 'Hana-OmniLens-API',
          },
          'timestamp': '2026-06-18T06:00:00Z',
        });
      }),
    );

    final response = await client.getMarketQuotes(
      market: 'KOSPI',
      currency: 'USD',
    );

    expect(response.status, 200);
    expect(response.data?['fxRateSource'], 'Hana-OmniLens-API');
  });

  test('notification APIs use account and stock intelligence paths', () async {
    const session = AuthSession(
      username: 'hana',
      accountId: 'ACC-ABC123456789',
      tokenType: 'Bearer',
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
    final seenPaths = <String>[];
    final client = ExchangeApiClient(
      baseUri: Uri.parse('http://localhost:3000'),
      sessionProvider: () => session,
      httpClient: MockClient((request) async {
        seenPaths.add('${request.method} ${request.url.path}');
        expect(_header(request, 'authorization'), 'Bearer access-token');
        return _jsonResponse({
          'success': true,
          'status': 200,
          'code': 'COMMON_000',
          'message': 'OK',
          'data': <String, Object?>{},
          'timestamp': '2026-06-18T06:00:00Z',
        });
      }),
    );

    await client.getNotifications('ACC-ABC123456789');
    await client.getStockIntelligenceFeed('005930');
    await client.markNotificationRead(
      accountId: 'ACC-ABC123456789',
      notificationId: 'NTF-ABC123456789',
    );

    expect(seenPaths, [
      'GET /api/v1/accounts/ACC-ABC123456789/notifications',
      'GET /api/v1/stocks/005930/intelligence',
      'POST /api/v1/accounts/ACC-ABC123456789/notifications/NTF-ABC123456789/read',
    ]);
  });

  test('deposit sends amountUsd and bearer token', () async {
    const session = AuthSession(
      username: 'hana',
      accountId: 'ACC-ABC123456789',
      tokenType: 'Bearer',
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
    final client = ExchangeApiClient(
      baseUri: Uri.parse('http://localhost:3000'),
      sessionProvider: () => session,
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.path,
          '/api/v1/accounts/ACC-ABC123456789/deposits',
        );
        expect(_header(request, 'authorization'), 'Bearer access-token');
        expect(jsonDecode(request.body), {'amountUsd': 500});

        return _jsonResponse({
          'success': true,
          'status': 200,
          'code': 'COMMON_000',
          'message': 'OK',
          'data': {
            'accountId': 'ACC-ABC123456789',
            'currency': 'USD',
            'cashBalanceUsd': '500.00',
            'lastLedgerEntryId': 'CASH-1',
          },
          'timestamp': '2026-06-18T06:00:00Z',
        });
      }),
    );

    final response = await client.depositUsd(
      accountId: 'ACC-ABC123456789',
      amount: 500,
    );

    expect(response.data?['cashBalanceUsd'], '500.00');
  });

  test('throws ExchangeApiException for common envelope failure', () async {
    final client = ExchangeApiClient(
      baseUri: Uri.parse('http://localhost:3000'),
      httpClient: MockClient((request) async {
        return _jsonResponse(
          {
            'success': false,
            'status': 409,
            'code': 'TRADE_001',
            'message': 'Mock USD account has insufficient balance',
            'timestamp': '2026-06-18T06:00:00Z',
          },
          statusCode: 409,
        );
      }),
    );

    expect(
      client.depositUsd(
        accountId: 'ACC-ABC123456789',
        amount: 500,
      ),
      throwsA(
        isA<ExchangeApiException>()
            .having((error) => error.status, 'status', 409)
            .having((error) => error.code, 'code', 'TRADE_001'),
      ),
    );
  });

  test('account scoped quote snapshots send market and bearer token', () async {
    const session = AuthSession(
      username: 'hana',
      accountId: 'ACC-ABC123456789',
      tokenType: 'Bearer',
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
    final paths = <String>[];
    final client = ExchangeApiClient(
      baseUri: Uri.parse('http://localhost:3000'),
      sessionProvider: () => session,
      httpClient: MockClient((request) async {
        paths.add(request.url.path);
        expect(request.url.queryParameters['market'], 'KOSPI');
        expect(request.url.queryParameters['currency'], 'USD');
        expect(_header(request, 'authorization'), 'Bearer access-token');

        return _jsonResponse({
          'success': true,
          'status': 200,
          'code': 'COMMON_000',
          'message': 'OK',
          'data': {'quotes': []},
          'timestamp': '2026-06-18T06:00:00Z',
        });
      }),
    );

    await client.getWatchlistQuotes('ACC-ABC123456789', market: 'KOSPI');
    await client.getPortfolioQuotes('ACC-ABC123456789', market: 'KOSPI');

    expect(paths, [
      '/api/v1/accounts/ACC-ABC123456789/market/quotes/watchlist',
      '/api/v1/accounts/ACC-ABC123456789/market/quotes/portfolio',
    ]);
  });

  test('stock detail chart and order book APIs use USD query contracts', () async {
    const session = AuthSession(
      username: 'hana',
      accountId: 'ACC-ABC123456789',
      tokenType: 'Bearer',
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
    final requests = <String>[];
    final client = ExchangeApiClient(
      baseUri: Uri.parse('http://localhost:3000'),
      sessionProvider: () => session,
      httpClient: MockClient((request) async {
        requests.add('${request.method} ${request.url.path}');
        expect(_header(request, 'authorization'), 'Bearer access-token');
        expect(request.url.queryParameters['currency'], 'USD');

        if (request.url.path.endsWith('/chart')) {
          expect(request.url.queryParameters['from'], '2026-06-01');
          expect(request.url.queryParameters['to'], '2026-06-18');
          expect(request.url.queryParameters['interval'], '1d');
        }

        return _jsonResponse({
          'success': true,
          'status': 200,
          'code': 'COMMON_000',
          'message': 'OK',
          'data': {},
          'timestamp': '2026-06-18T06:00:00Z',
        });
      }),
    );

    await client.getStockDetail(stockCode: '005930');
    await client.getMarketChart(
      stockCode: '005930',
      from: '2026-06-01',
      to: '2026-06-18',
    );
    await client.getOrderBook(stockCode: '005930');

    expect(requests, [
      'GET /api/v1/stocks/005930',
      'GET /api/v1/market/stocks/005930/chart',
      'GET /api/v1/market/stocks/005930/orderbook',
    ]);
  });

  test('trade APIs send mock ledger contracts and bearer token', () async {
    const session = AuthSession(
      username: 'hana',
      accountId: 'ACC-ABC123456789',
      tokenType: 'Bearer',
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
    final requests = <String>[];
    final client = ExchangeApiClient(
      baseUri: Uri.parse('http://localhost:3000'),
      sessionProvider: () => session,
      httpClient: MockClient((request) async {
        requests.add('${request.method} ${request.url.path}');
        expect(_header(request, 'authorization'), 'Bearer access-token');

        if (request.url.path.endsWith('/trades/orderability')) {
          expect(request.url.queryParameters['stockCode'], '005930');
          expect(request.url.queryParameters['side'], 'BUY');
          expect(request.url.queryParameters['quantity'], '2');
          return _jsonResponse({
            'success': true,
            'status': 200,
            'code': 'COMMON_000',
            'message': 'OK',
            'data': {'canPlaceMockOrder': true},
            'timestamp': '2026-06-18T06:00:00Z',
          });
        }
        if (request.url.path.endsWith('/trades')) {
          expect(jsonDecode(request.body), {
            'stockCode': '005930',
            'side': 'BUY',
            'quantity': 2,
          });
          return _jsonResponse({
            'success': true,
            'status': 200,
            'code': 'COMMON_000',
            'message': 'OK',
            'data': {'tradeId': 'TRD-1'},
            'timestamp': '2026-06-18T06:00:00Z',
          });
        }

        expect(request.url.path, '/api/v1/accounts/ACC-ABC123456789/portfolio');
        return _jsonResponse({
          'success': true,
          'status': 200,
          'code': 'COMMON_000',
          'message': 'OK',
          'data': {'holdings': [], 'recentTrades': []},
          'timestamp': '2026-06-18T06:00:00Z',
        });
      }),
    );

    await client.checkOrderability(
      accountId: 'ACC-ABC123456789',
      stockCode: '005930',
      side: 'BUY',
      quantity: 2,
    );
    await client.executeTrade(
      accountId: 'ACC-ABC123456789',
      stockCode: '005930',
      side: 'BUY',
      quantity: 2,
    );
    await client.getPortfolio('ACC-ABC123456789');

    expect(requests, [
      'GET /api/v1/accounts/ACC-ABC123456789/trades/orderability',
      'POST /api/v1/accounts/ACC-ABC123456789/trades',
      'GET /api/v1/accounts/ACC-ABC123456789/portfolio',
    ]);
  });

  test('tax refund status sends account scoped bearer contract', () async {
    const session = AuthSession(
      username: 'hana',
      accountId: 'ACC-ABC123456789',
      tokenType: 'Bearer',
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
    final client = ExchangeApiClient(
      baseUri: Uri.parse('http://localhost:3000'),
      sessionProvider: () => session,
      httpClient: MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.path,
          '/api/v1/accounts/ACC-ABC123456789/tax/refund-status',
        );
        expect(_header(request, 'authorization'), 'Bearer access-token');

        return _jsonResponse({
          'success': true,
          'status': 200,
          'code': 'COMMON_000',
          'message': 'OK',
          'data': {'status': 'REFUND_APPROVED'},
          'timestamp': '2026-06-18T06:00:00Z',
        });
      }),
    );

    final response = await client.getTaxRefundStatus('ACC-ABC123456789');

    expect(response.data?['status'], 'REFUND_APPROVED');
  });
}

String? _header(http.Request request, String name) {
  final normalizedName = name.toLowerCase();
  for (final entry in request.headers.entries) {
    if (entry.key.toLowerCase() == normalizedName) {
      return entry.value;
    }
  }
  return null;
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
