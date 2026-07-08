import 'dart:convert';
import 'dart:typed_data';

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

  test('signup validation error exposes field-specific message', () async {
    final client = ExchangeApiClient(
      baseUri: Uri.parse('http://localhost:3000'),
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/auth/signup');
        return _jsonResponse(
          {
            'success': false,
            'status': 400,
            'code': 'COMMON_002',
            'message': 'Request validation failed',
            'errors': [
              {
                'field': 'username',
                'reason': 'must match "^[A-Za-z0-9_]{4,30}\$"',
              },
              {
                'field': 'password',
                'reason': 'size must be between 8 and 72',
              },
            ],
            'timestamp': '2026-06-18T06:00:00Z',
          },
          statusCode: 400,
        );
      }),
    );

    await expectLater(
      client.signUp(username: '한나', password: 'short'),
      throwsA(
        isA<ExchangeApiException>().having(
          (error) => error.message,
          'message',
          'Username must be 4-30 letters, numbers, or underscores.\n'
              'Password must be 8-72 characters.',
        ),
      ),
    );
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

  test('market quote snapshot sends repeated stock code parameters', () async {
    final client = ExchangeApiClient(
      baseUri: Uri.parse('http://localhost:3000'),
      httpClient: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/market/quotes');
        expect(request.url.queryParametersAll['stockCodes'], [
          '005930',
          '000270',
          '086790',
        ]);
        expect(request.url.queryParameters['currency'], 'USD');

        return _jsonResponse({
          'success': true,
          'status': 200,
          'code': 'COMMON_000',
          'message': 'OK',
          'data': {'quotes': <Object?>[]},
          'timestamp': '2026-06-18T06:00:00Z',
        });
      }),
    );

    await client.getMarketQuotes(
      stockCodes: ['005930', '000270', '086790'],
    );
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
    await client.getNotificationDevices('ACC-ABC123456789');
    await client.getStockIntelligenceFeed('005930');
    await client.markNotificationRead(
      accountId: 'ACC-ABC123456789',
      notificationId: 'NTF-ABC123456789',
    );

    expect(seenPaths, [
      'GET /api/v1/accounts/ACC-ABC123456789/notifications',
      'GET /api/v1/accounts/ACC-ABC123456789/notifications/devices',
      'GET /api/v1/stocks/005930/intelligence',
      'POST /api/v1/accounts/ACC-ABC123456789/notifications/NTF-ABC123456789/read',
    ]);
  });

  test('notification device APIs send registration and disable requests',
      () async {
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
        if (request.method == 'POST') {
          expect(jsonDecode(request.body), {
            'platform': 'IOS',
            'provider': 'LOCAL_NOOP_PUSH',
            'deviceToken': 'local-mobile-device-token-0001',
            'appVersion': '0.1.0',
            'locale': 'en_US',
          });
        }
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

    await client.registerNotificationDevice(
      accountId: 'ACC-ABC123456789',
      platform: 'IOS',
      provider: 'LOCAL_NOOP_PUSH',
      deviceToken: 'local-mobile-device-token-0001',
      appVersion: '0.1.0',
      locale: 'en_US',
    );
    await client.disableNotificationDevice(
      accountId: 'ACC-ABC123456789',
      deviceTokenId: 'NTD-ABC123456789',
    );

    expect(seenPaths, [
      'POST /api/v1/accounts/ACC-ABC123456789/notifications/devices',
      'DELETE /api/v1/accounts/ACC-ABC123456789/notifications/devices/NTD-ABC123456789',
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

  test('stock detail chart and order book APIs use USD query contracts',
      () async {
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
            'orderType': 'LIMIT',
            'limitPriceUsd': 50.0,
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
      limitPriceUsd: 50.00,
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

  test('tax document upload sends multipart bearer contract', () async {
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
          '/api/v1/accounts/ACC-ABC123456789/tax/documents',
        );
        expect(_header(request, 'authorization'), 'Bearer access-token');
        expect(
          _header(request, 'content-type'),
          contains('multipart/form-data'),
        );
        expect(request.body, contains('RESIDENCE_CERTIFICATE'));
        expect(request.body, contains('residence.pdf'));
        expect(request.body, contains('content-type: application/pdf'));

        return _jsonResponse({
          'success': true,
          'status': 200,
          'code': 'COMMON_000',
          'message': 'OK',
          'data': {
            'documentId': 'DOC-1',
            'documentType': 'RESIDENCE_CERTIFICATE',
            'originalFileName': 'residence.pdf',
            'verification': {
              'verificationStatus': 'VERIFIED',
              'ocrConfidence': 0.92,
              'fraudRiskScore': 0.02,
              'riskLevel': 'LOW',
              'manualReviewRequired': false,
              'extractedFields': {'residency_country_code': 'US'},
              'missingRequiredFields': [],
              'rejectionReasons': [],
              'documentModelVersion': 'hanah-tax-ocr-e2e-review-v1',
              'source': 'HANNAH_MONTANA_AI_TAX_OCR',
              'progressPercent': 100,
              'stage': 'VERIFICATION_COMPLETE',
              'updatedAt': '2026-06-18T06:00:01Z',
            },
          },
          'timestamp': '2026-06-18T06:00:00Z',
        });
      }),
    );

    final response = await client.uploadTaxDocument(
      accountId: 'ACC-ABC123456789',
      documentType: 'RESIDENCE_CERTIFICATE',
      fileName: 'residence.pdf',
      bytes: Uint8List.fromList(utf8.encode('document')),
      contentType: 'application/pdf',
    );

    expect(response.data?['documentId'], 'DOC-1');
    expect(
      (response.data?['verification'] as Map<String, dynamic>?)?['source'],
      'HANNAH_MONTANA_AI_TAX_OCR',
    );
  });

  test('tax document verification progress uses account scoped bearer contract',
      () async {
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
          '/api/v1/accounts/ACC-ABC123456789/tax/documents/DOC-1/verification',
        );
        expect(_header(request, 'authorization'), 'Bearer access-token');
        return _jsonResponse({
          'success': true,
          'status': 200,
          'code': 'COMMON_000',
          'message': 'OK',
          'data': {
            'verificationStatus': 'PENDING',
            'ocrConfidence': 0.0,
            'fraudRiskScore': 0.0,
            'riskLevel': 'MEDIUM',
            'manualReviewRequired': true,
            'extractedFields': {},
            'missingRequiredFields': [],
            'rejectionReasons': [],
            'documentModelVersion': 'pending',
            'source': 'HANA_EXCHANGE_BE',
            'progressPercent': 75,
            'stage': 'HANNAH_MONTANA_OCR',
            'updatedAt': '2026-06-18T06:00:01Z',
          },
          'timestamp': '2026-06-18T06:00:01Z',
        });
      }),
    );

    final response = await client.getTaxDocumentVerification(
      accountId: 'ACC-ABC123456789',
      documentId: 'DOC-1',
    );

    expect(response.data?['progressPercent'], 75);
    expect(response.data?['stage'], 'HANNAH_MONTANA_OCR');
  });

  test('tax refund request and sync use account scoped bearer contract',
      () async {
    final paths = <String>[];
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
        paths.add('${request.method} ${request.url.path}');
        expect(_header(request, 'authorization'), 'Bearer access-token');
        if (request.url.path.endsWith('/refund-cases')) {
          expect(jsonDecode(request.body), {
            'taxYear': 2026,
            'treatyCountry': 'US',
            'residenceCertificateFileName': 'residence.pdf',
            'reducedTaxApplicationFileName': 'reduced-tax.pdf',
            'residenceCertificateDocumentId': 'DOC-RES',
            'apostilleDocumentId': 'DOC-APO',
            'reducedTaxApplicationDocumentId': 'DOC-RED',
            'advancePaymentRequested': true,
          });
        }

        return _jsonResponse({
          'success': true,
          'status': 200,
          'code': 'COMMON_000',
          'message': 'OK',
          'data': {'status': 'READY_FOR_HANA_SYNC'},
          'timestamp': '2026-06-18T06:00:00Z',
        });
      }),
    );

    await client.createTaxRefundCase(
      accountId: 'ACC-ABC123456789',
      taxYear: 2026,
      treatyCountry: 'US',
      residenceCertificateFileName: 'residence.pdf',
      reducedTaxApplicationFileName: 'reduced-tax.pdf',
      residenceCertificateDocumentId: 'DOC-RES',
      apostilleDocumentId: 'DOC-APO',
      reducedTaxApplicationDocumentId: 'DOC-RED',
      advancePaymentRequested: true,
    );
    await client.syncTaxRefundStatus('ACC-ABC123456789');

    expect(paths, [
      'POST /api/v1/accounts/ACC-ABC123456789/tax/refund-cases',
      'POST /api/v1/accounts/ACC-ABC123456789/tax/refund-status/sync',
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
