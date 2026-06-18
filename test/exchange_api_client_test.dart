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
