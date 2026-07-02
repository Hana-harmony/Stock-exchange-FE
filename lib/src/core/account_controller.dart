import 'package:flutter/foundation.dart';

import 'currency_format.dart';
import 'exchange_api_client.dart';

enum AccountStatus {
  idle,
  loading,
  loaded,
  failure,
}

class AccountState {
  const AccountState({
    required this.status,
    this.account,
    this.errorMessage,
  });

  const AccountState.idle()
      : status = AccountStatus.idle,
        account = null,
        errorMessage = null;

  const AccountState.loading({this.account})
      : status = AccountStatus.loading,
        errorMessage = null;

  const AccountState.loaded(this.account)
      : status = AccountStatus.loaded,
        errorMessage = null;

  const AccountState.failure({
    required this.errorMessage,
    this.account,
  }) : status = AccountStatus.failure;

  final AccountStatus status;
  final MockUsdAccount? account;
  final String? errorMessage;
}

class MockUsdAccount {
  const MockUsdAccount({
    required this.accountId,
    required this.currency,
    required this.cashBalanceUsd,
    this.lastLedgerEntryId,
    this.updatedAt,
  });

  final String accountId;
  final String currency;
  final String cashBalanceUsd;
  final String? lastLedgerEntryId;
  final DateTime? updatedAt;

  String get cashDisplay => formatCurrencyDisplay(currency, cashBalanceUsd);

  static MockUsdAccount fromJson(Map<String, dynamic> json) {
    return MockUsdAccount(
      accountId: _string(json['accountId'], fallback: ''),
      currency: _string(json['currency'], fallback: 'USD'),
      cashBalanceUsd: _string(json['cashBalanceUsd'], fallback: '0.00'),
      lastLedgerEntryId: _nullableString(json['lastLedgerEntryId']),
      updatedAt: _dateTime(json['updatedAt']),
    );
  }
}

class AccountController extends ValueNotifier<AccountState> {
  AccountController({required ExchangeApiClient apiClient})
      : _apiClient = apiClient,
        super(const AccountState.idle());

  final ExchangeApiClient _apiClient;

  void clear() {
    value = const AccountState.idle();
  }

  Future<void> loadAccount(String? accountId) async {
    if (accountId == null || accountId.isEmpty) {
      value = AccountState.failure(
        errorMessage: 'Sign in to load your USD account.',
        account: value.account,
      );
      return;
    }

    value = AccountState.loading(account: value.account);
    try {
      final response = await _apiClient.getAccount(accountId);
      value = AccountState.loaded(
        MockUsdAccount.fromJson(response.data ?? {}),
      );
    } on ExchangeApiException catch (error) {
      value = AccountState.failure(
        errorMessage: error.message,
        account: value.account,
      );
    } on Object {
      value = AccountState.failure(
        errorMessage: 'Unable to load your USD account.',
        account: value.account,
      );
    }
  }

  Future<void> depositUsd({
    required String? accountId,
    required num amount,
  }) async {
    if (accountId == null || accountId.isEmpty) {
      value = AccountState.failure(
        errorMessage: 'Sign in before depositing USD.',
        account: value.account,
      );
      return;
    }
    if (amount <= 0) {
      value = AccountState.failure(
        errorMessage: 'Enter a deposit amount greater than 0.',
        account: value.account,
      );
      return;
    }

    value = AccountState.loading(account: value.account);
    try {
      final response = await _apiClient.depositUsd(
        accountId: accountId,
        amount: amount,
      );
      value = AccountState.loaded(
        MockUsdAccount.fromJson(response.data ?? {}),
      );
    } on ExchangeApiException catch (error) {
      value = AccountState.failure(
        errorMessage: error.message,
        account: value.account,
      );
    } on Object {
      value = AccountState.failure(
        errorMessage: 'Unable to deposit USD.',
        account: value.account,
      );
    }
  }
}

String _string(Object? value, {required String fallback}) {
  if (value == null) {
    return fallback;
  }
  return '$value';
}

String? _nullableString(Object? value) {
  if (value == null) {
    return null;
  }
  final text = '$value';
  return text.isEmpty ? null : text;
}

DateTime? _dateTime(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}
