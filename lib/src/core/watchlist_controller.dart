import 'package:flutter/foundation.dart';

import 'exchange_api_client.dart';

enum WatchlistStatus { idle, loading, loaded, failure }

class WatchlistState {
  const WatchlistState({
    required this.status,
    this.watchlist,
    this.errorMessage,
  });

  const WatchlistState.idle()
      : status = WatchlistStatus.idle,
        watchlist = null,
        errorMessage = null;

  const WatchlistState.loading({this.watchlist})
      : status = WatchlistStatus.loading,
        errorMessage = null;

  const WatchlistState.loaded(this.watchlist)
      : status = WatchlistStatus.loaded,
        errorMessage = null;

  const WatchlistState.failure({
    required this.errorMessage,
    this.watchlist,
  }) : status = WatchlistStatus.failure;

  final WatchlistStatus status;
  final WatchlistSnapshot? watchlist;
  final String? errorMessage;

  Set<String> get stockCodes =>
      watchlist?.items.map((item) => item.stockCode).toSet() ?? const {};
}

class WatchlistSnapshot {
  const WatchlistSnapshot({
    required this.userId,
    required this.accountId,
    required this.itemCount,
    required this.targetingMode,
    required this.items,
    this.servedAt,
  });

  final String userId;
  final String accountId;
  final int itemCount;
  final String targetingMode;
  final List<WatchlistItem> items;
  final DateTime? servedAt;

  static WatchlistSnapshot fromJson(Map<String, dynamic> json) {
    final values = json['items'] is List
        ? json['items'] as List<Object?>
        : const <Object?>[];
    return WatchlistSnapshot(
      userId: _string(json['userId'], fallback: ''),
      accountId: _string(json['accountId'], fallback: ''),
      itemCount: _int(json['itemCount']),
      targetingMode: _string(json['targetingMode'], fallback: 'WATCHLIST'),
      items: values
          .map((value) => WatchlistItem.fromJson(_map(value)))
          .toList(growable: false),
      servedAt: _dateTime(json['servedAt']),
    );
  }
}

class WatchlistItem {
  const WatchlistItem({
    required this.stockCode,
    required this.stockName,
    required this.market,
    required this.targetingMode,
    this.addedAt,
  });

  final String stockCode;
  final String stockName;
  final String market;
  final String targetingMode;
  final DateTime? addedAt;

  static WatchlistItem fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      stockCode: _string(json['stockCode'], fallback: ''),
      stockName: _string(json['stockName'], fallback: 'Unknown stock'),
      market: _string(json['market'], fallback: 'KOREA'),
      targetingMode: _string(json['targetingMode'], fallback: 'WATCHLIST'),
      addedAt: _dateTime(json['addedAt']),
    );
  }
}

class WatchlistController extends ValueNotifier<WatchlistState> {
  WatchlistController({required ExchangeApiClient apiClient})
      : _apiClient = apiClient,
        super(const WatchlistState.idle());

  final ExchangeApiClient _apiClient;

  bool contains(String stockCode) => value.stockCodes.contains(stockCode);

  void clear() {
    value = const WatchlistState.idle();
  }

  Future<void> load(String? accountId) async {
    if (accountId == null || accountId.isEmpty) {
      value = WatchlistState.failure(
        errorMessage: 'Sign in to load watchlist.',
        watchlist: value.watchlist,
      );
      return;
    }
    await _run(() => _apiClient.getWatchlist(accountId));
  }

  Future<void> add({
    required String? accountId,
    required String stockCode,
  }) async {
    if (!_isValid(accountId, stockCode)) {
      return;
    }
    await _run(
      () => _apiClient.addWatchlistItem(
        accountId: accountId!,
        stockCode: stockCode,
      ),
    );
  }

  Future<void> remove({
    required String? accountId,
    required String stockCode,
  }) async {
    if (!_isValid(accountId, stockCode)) {
      return;
    }
    await _run(
      () => _apiClient.removeWatchlistItem(
        accountId: accountId!,
        stockCode: stockCode,
      ),
    );
  }

  bool _isValid(String? accountId, String stockCode) {
    if (accountId == null || accountId.isEmpty) {
      value = WatchlistState.failure(
        errorMessage: 'Sign in before changing watchlist.',
        watchlist: value.watchlist,
      );
      return false;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(stockCode)) {
      value = WatchlistState.failure(
        errorMessage: 'Watchlist supports 6 digit Korean stock codes.',
        watchlist: value.watchlist,
      );
      return false;
    }
    return true;
  }

  Future<void> _run(
    Future<ApiEnvelope<Map<String, dynamic>>> Function() action,
  ) async {
    value = WatchlistState.loading(watchlist: value.watchlist);
    try {
      final response = await action();
      value = WatchlistState.loaded(
        WatchlistSnapshot.fromJson(response.data ?? {}),
      );
    } on ExchangeApiException catch (error) {
      value = WatchlistState.failure(
        errorMessage: error.message,
        watchlist: value.watchlist,
      );
    } on Object {
      value = WatchlistState.failure(
        errorMessage: 'Unable to update watchlist.',
        watchlist: value.watchlist,
      );
    }
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry('$key', value));
  }
  return {};
}

String _string(Object? value, {required String fallback}) {
  if (value == null) {
    return fallback;
  }
  final text = '$value';
  return text.isEmpty ? fallback : text;
}

int _int(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse('$value') ?? 0;
}

DateTime? _dateTime(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}
