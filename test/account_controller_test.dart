import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stock_exchange_fe/src/core/account_controller.dart';
import 'package:stock_exchange_fe/src/core/exchange_api_client.dart';

void main() {
  test('loads mock USD account balance', () async {
    final controller = AccountController(
      apiClient: _client((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/accounts/ACC-ABC123456789');

        return _jsonResponse({
          'success': true,
          'status': 200,
          'code': 'COMMON_000',
          'message': 'OK',
          'data': _accountJson(cashBalanceUsd: '1024.24'),
          'timestamp': '2026-06-18T06:00:00Z',
        });
      }),
    );

    await controller.loadAccount('ACC-ABC123456789');

    expect(controller.value.status, AccountStatus.loaded);
    expect(controller.value.account?.cashDisplay, 'USD 1,024.24');
  });

  test('deposits mock USD without real payment settlement', () async {
    final controller = AccountController(
      apiClient: _client((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.path,
          '/api/v1/accounts/ACC-ABC123456789/deposits',
        );
        expect(jsonDecode(request.body), {'amountUsd': 250.75});

        return _jsonResponse({
          'success': true,
          'status': 200,
          'code': 'COMMON_000',
          'message': 'OK',
          'data': _accountJson(
            cashBalanceUsd: '1250.75',
            lastLedgerEntryId: 'CASH-123',
          ),
          'timestamp': '2026-06-18T06:00:00Z',
        });
      }),
    );

    await controller.depositUsd(
      accountId: 'ACC-ABC123456789',
      amount: 250.75,
    );

    expect(controller.value.status, AccountStatus.loaded);
    expect(controller.value.account?.cashDisplay, 'USD 1,250.75');
    expect(controller.value.account?.lastLedgerEntryId, 'CASH-123');
  });

  test('rejects missing sign in and invalid amount before API call', () async {
    var requestCount = 0;
    final controller = AccountController(
      apiClient: _client((request) async {
        requestCount++;
        return _jsonResponse({});
      }),
    );

    await controller.loadAccount(null);
    expect(controller.value.errorMessage, 'Sign in to load your USD account.');

    await controller.depositUsd(accountId: 'ACC-ABC123456789', amount: 0);
    expect(controller.value.errorMessage,
        'Enter a deposit amount greater than 0.');
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

Map<String, Object?> _accountJson({
  required String cashBalanceUsd,
  String? lastLedgerEntryId,
}) {
  return {
    'userId': 'USR-1',
    'accountId': 'ACC-ABC123456789',
    'currency': 'USD',
    'cashBalanceUsd': cashBalanceUsd,
    if (lastLedgerEntryId != null) 'lastLedgerEntryId': lastLedgerEntryId,
    'updatedAt': '2026-06-18T06:00:00Z',
  };
}

http.Response _jsonResponse(Map<String, Object?> body) {
  return http.Response(
    jsonEncode(body),
    200,
    headers: {'content-type': 'application/json'},
  );
}
