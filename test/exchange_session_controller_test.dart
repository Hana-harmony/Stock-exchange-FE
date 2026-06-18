import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stock_exchange_fe/src/core/exchange_api_client.dart';
import 'package:stock_exchange_fe/src/core/exchange_session_controller.dart';

void main() {
  test('restore uses a stored auth session', () async {
    const storedSession = AuthSession(
      username: 'hana',
      accountId: 'ACC-ABC123456789',
      tokenType: 'Bearer',
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
    final store = MemoryExchangeSessionStore();
    await store.write(storedSession);
    final controller = ExchangeSessionController(
      apiClient: _client(),
      sessionStore: store,
    );

    await controller.restore();

    expect(controller.value.status, ExchangeSessionStatus.signedIn);
    expect(controller.value.session?.accountId, 'ACC-ABC123456789');
  });

  test('login stores a successful auth session', () async {
    final store = MemoryExchangeSessionStore();
    final controller = ExchangeSessionController(
      sessionStore: store,
      apiClient: _client((request) async {
        expect(request.url.path, '/api/v1/auth/login');
        return _jsonResponse({
          'success': true,
          'status': 200,
          'code': 'COMMON_000',
          'message': 'OK',
          'data': _sessionJson(accessToken: 'new-access-token'),
          'timestamp': '2026-06-18T06:00:00Z',
        });
      }),
    );

    await controller.login(username: 'hana', password: 'secret');

    expect(controller.value.status, ExchangeSessionStatus.signedIn);
    expect(controller.value.session?.accessToken, 'new-access-token');
    expect((await store.read())?.accessToken, 'new-access-token');
  });

  test('login failure preserves signed-out state with message', () async {
    final controller = ExchangeSessionController(
      sessionStore: MemoryExchangeSessionStore(),
      apiClient: _client((request) async {
        return _jsonResponse(
          {
            'success': false,
            'status': 401,
            'code': 'AUTH_002',
            'message': 'Invalid username or password',
            'timestamp': '2026-06-18T06:00:00Z',
          },
          statusCode: 401,
        );
      }),
    );

    await controller.login(username: 'hana', password: 'wrong');

    expect(controller.value.status, ExchangeSessionStatus.failure);
    expect(controller.value.errorMessage, 'Invalid username or password');
    expect(controller.value.session, isNull);
  });

  test('login validates blank credentials before API call', () async {
    var requestCount = 0;
    final controller = ExchangeSessionController(
      sessionStore: MemoryExchangeSessionStore(),
      apiClient: _client((request) async {
        requestCount++;
        return _jsonResponse({});
      }),
    );

    await controller.login(username: ' ', password: '');

    expect(requestCount, 0);
    expect(controller.value.status, ExchangeSessionStatus.failure);
    expect(controller.value.errorMessage, 'Username and password are required.');
  });

  test('sign up creates an account and then signs in', () async {
    final paths = <String>[];
    final store = MemoryExchangeSessionStore();
    final controller = ExchangeSessionController(
      sessionStore: store,
      apiClient: _client((request) async {
        paths.add(request.url.path);
        if (request.url.path == '/api/v1/auth/signup') {
          return _jsonResponse({
            'success': true,
            'status': 200,
            'code': 'COMMON_000',
            'message': 'OK',
            'data': {
              'username': 'hana',
              'accountId': 'ACC-ABC123456789',
            },
            'timestamp': '2026-06-18T06:00:00Z',
          });
        }
        return _jsonResponse({
          'success': true,
          'status': 200,
          'code': 'COMMON_000',
          'message': 'OK',
          'data': _sessionJson(accessToken: 'signup-access-token'),
          'timestamp': '2026-06-18T06:00:00Z',
        });
      }),
    );

    await controller.signUpAndLogin(username: ' hana ', password: 'secret');

    expect(paths, ['/api/v1/auth/signup', '/api/v1/auth/login']);
    expect(controller.value.status, ExchangeSessionStatus.signedIn);
    expect((await store.read())?.accessToken, 'signup-access-token');
  });

  test('refresh rotates the stored auth session', () async {
    const storedSession = AuthSession(
      username: 'hana',
      accountId: 'ACC-ABC123456789',
      tokenType: 'Bearer',
      accessToken: 'old-access-token',
      refreshToken: 'old-refresh-token',
    );
    final store = MemoryExchangeSessionStore();
    await store.write(storedSession);
    final controller = ExchangeSessionController(
      sessionStore: store,
      apiClient: _client((request) async {
        expect(request.url.path, '/api/v1/auth/token/refresh');
        expect(jsonDecode(request.body), {'refreshToken': 'old-refresh-token'});
        return _jsonResponse({
          'success': true,
          'status': 200,
          'code': 'COMMON_000',
          'message': 'OK',
          'data': _sessionJson(
            accessToken: 'rotated-access-token',
            refreshToken: 'rotated-refresh-token',
          ),
          'timestamp': '2026-06-18T06:00:00Z',
        });
      }),
    );

    await controller.restore();
    await controller.refresh();

    expect(controller.value.status, ExchangeSessionStatus.signedIn);
    expect(controller.value.session?.accessToken, 'rotated-access-token');
    expect((await store.read())?.refreshToken, 'rotated-refresh-token');
  });
}

ExchangeApiClient _client([
  Future<http.Response> Function(http.Request request)? handler,
]) {
  return ExchangeApiClient(
    baseUri: Uri.parse('http://localhost:3000'),
    httpClient: MockClient(handler ?? (_) async => _jsonResponse({})),
  );
}

Map<String, Object?> _sessionJson({
  String accessToken = 'access-token',
  String refreshToken = 'refresh-token',
}) {
  return {
    'username': 'hana',
    'accountId': 'ACC-ABC123456789',
    'tokenType': 'Bearer',
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'accessTokenExpiresAt': '2026-06-18T07:00:00Z',
    'refreshTokenExpiresAt': '2026-06-19T07:00:00Z',
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
