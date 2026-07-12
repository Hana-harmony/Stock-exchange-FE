import 'package:flutter/foundation.dart';

import 'exchange_api_client.dart';

part 'notifications/notification_state.dart';
part 'notifications/notification_models.dart';
part 'notifications/notification_parsing.dart';

class NotificationController extends ValueNotifier<NotificationState> {
  NotificationController({required ExchangeApiClient apiClient})
      : _apiClient = apiClient,
        super(const NotificationState.idle());

  final ExchangeApiClient _apiClient;
  String? _loadedFeedStockCode;
  Future<void>? _feedLoadFuture;
  Future<void>? _feedLoadMoreFuture;

  void setFilter(NotificationFilter filter) {
    value = value.copyWithFilter(filter);
  }

  void clear() {
    value = const NotificationState.idle();
  }

  Future<void> recordTermClick({
    required String term,
    required NotificationItem item,
  }) async {
    await _apiClient.explainFinancialTerm(
      term: term,
      sourceType: item.sourceType,
      title: item.title,
      context: item.summary,
      stockCode: item.primaryStockCode,
      articleId: item.eventId,
      articleUrl: item.originalUrl,
    );
  }

  Future<void> loadAlerts({
    required String? accountId,
    String stockCode = '005930',
  }) async {
    final resolvedAccountId = _validatedAccountId(
      accountId,
      errorMessage: 'Sign in to load alert inbox.',
    );
    if (resolvedAccountId == null) {
      return;
    }

    final currentInbox =
        value.inbox?.accountId == resolvedAccountId ? value.inbox : null;
    value = NotificationState.loading(
      inbox: currentInbox,
      feed: value.feed,
      devices: value.devices,
      selectedFilter: value.selectedFilter,
    );

    try {
      final results = await Future.wait([
        _apiClient.getNotifications(resolvedAccountId),
        _apiClient.getStockIntelligenceFeed(stockCode),
        _apiClient.getNotificationDevices(resolvedAccountId),
      ]);
      _setLoaded(
        inbox: NotificationInbox.fromJson(results[0].data ?? {}),
        feed: StockIntelligenceFeed.fromJson(results[1].data ?? {}),
        devices: NotificationDeviceList.fromJson(results[2].data ?? {}),
      );
    } on ExchangeApiException catch (error) {
      _setFailure(error.message);
    } on Object {
      _setFailure('Unable to load alert inbox.');
    }
  }

  Future<void> loadStockIntelligenceFeed({
    required String stockCode,
  }) async {
    final normalizedStockCode = stockCode.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(normalizedStockCode)) {
      _setFailure('Enter a 6 digit Korean stock code.');
      return;
    }
    if (_loadedFeedStockCode == normalizedStockCode &&
        value.feed?.stockCode == normalizedStockCode &&
        value.feed?.items.isNotEmpty == true) {
      return;
    }
    final activeLoad = _feedLoadFuture;
    if (activeLoad != null && _loadedFeedStockCode == normalizedStockCode) {
      return activeLoad;
    }

    value = NotificationState.loading(
      inbox: value.inbox,
      feed: value.feed,
      devices: value.devices,
      selectedFilter: value.selectedFilter,
    );

    _loadedFeedStockCode = normalizedStockCode;
    final loadFuture = () async {
      final response =
          await _apiClient.getStockIntelligenceFeed(normalizedStockCode);
      _setLoaded(
        inbox: value.inbox,
        feed: StockIntelligenceFeed.fromJson(response.data ?? {}),
        devices: value.devices,
      );
    }();
    _feedLoadFuture = loadFuture;

    try {
      await loadFuture;
    } on ExchangeApiException catch (error) {
      _loadedFeedStockCode = null;
      _setFailure(error.message);
    } on Object {
      _loadedFeedStockCode = null;
      _setFailure('Unable to load stock intelligence feed.');
    } finally {
      if (identical(_feedLoadFuture, loadFuture)) {
        _feedLoadFuture = null;
      }
    }
  }

  Future<void> loadMoreStockIntelligenceFeed({
    required String stockCode,
    int limit = 20,
  }) {
    final normalizedStockCode = stockCode.trim();
    final current = value.feed;
    final cursor = current?.nextCursor;
    if (current == null ||
        current.stockCode != normalizedStockCode ||
        cursor == null ||
        cursor.isEmpty) {
      return Future.value();
    }
    final active = _feedLoadMoreFuture;
    if (active != null) {
      return active;
    }
    final future = () async {
      try {
        final response = await _apiClient.getStockIntelligenceFeed(
          normalizedStockCode,
          limit: limit,
          cursor: cursor,
        );
        _setLoaded(
          inbox: value.inbox,
          feed: current
              .merge(StockIntelligenceFeed.fromJson(response.data ?? {})),
          devices: value.devices,
        );
      } on ExchangeApiException catch (error) {
        _setFailure(error.message);
      } on Object {
        _setFailure('Unable to load more stock intelligence.');
      }
    }();
    _feedLoadMoreFuture = future;
    return future.whenComplete(() {
      if (identical(_feedLoadMoreFuture, future)) {
        _feedLoadMoreFuture = null;
      }
    });
  }

  Future<void> markRead({
    required String? accountId,
    required String notificationId,
  }) async {
    final resolvedAccountId = _validatedAccountId(
      accountId,
      errorMessage: 'Sign in to update alert inbox.',
    );
    if (resolvedAccountId == null) {
      return;
    }

    try {
      final response = await _apiClient.markNotificationRead(
        accountId: resolvedAccountId,
        notificationId: notificationId,
      );
      final currentInbox = value.inbox;
      if (currentInbox == null) {
        return;
      }

      final updated = NotificationItem.fromJson(response.data ?? {});
      final notifications = currentInbox.notifications
          .map((item) => item.notificationId == notificationId ? updated : item)
          .toList();
      _replaceInbox(currentInbox.copyWith(notifications: notifications));
    } on ExchangeApiException catch (error) {
      _setFailure(error.message);
    } on Object {
      _setFailure('Unable to mark alert as read.');
    }
  }

  Future<bool> registerPushDevice({
    required String? accountId,
    required String platform,
    required String provider,
    required String deviceToken,
    required String appVersion,
    required String locale,
  }) async {
    final resolvedAccountId = _validatedAccountId(
      accountId,
      errorMessage: 'Sign in to register this device.',
    );
    if (resolvedAccountId == null) {
      return false;
    }

    try {
      final response = await _apiClient.registerNotificationDevice(
        accountId: resolvedAccountId,
        platform: platform,
        provider: provider,
        deviceToken: deviceToken,
        appVersion: appVersion,
        locale: locale,
      );
      _upsertDevice(NotificationDevice.fromJson(response.data ?? {}));
      return true;
    } on ExchangeApiException catch (error) {
      _setFailure(error.message);
      return false;
    } on Object {
      _setFailure('Unable to register this device.');
      return false;
    }
  }

  Future<void> disableDevice({
    required String? accountId,
    required String deviceTokenId,
  }) async {
    final resolvedAccountId = _validatedAccountId(
      accountId,
      errorMessage: 'Sign in to disable this device.',
    );
    if (resolvedAccountId == null) {
      return;
    }

    try {
      final response = await _apiClient.disableNotificationDevice(
        accountId: resolvedAccountId,
        deviceTokenId: deviceTokenId,
      );
      _upsertDevice(NotificationDevice.fromJson(response.data ?? {}));
    } on ExchangeApiException catch (error) {
      _setFailure(error.message);
    } on Object {
      _setFailure('Unable to disable this device.');
    }
  }

  String? _validatedAccountId(
    String? accountId, {
    required String errorMessage,
  }) {
    final normalized = accountId?.trim() ?? '';
    if (normalized.isEmpty) {
      _setFailure(errorMessage);
      return null;
    }
    return normalized;
  }

  void _setFailure(String errorMessage) {
    value = NotificationState.failure(
      errorMessage: errorMessage,
      inbox: value.inbox,
      feed: value.feed,
      devices: value.devices,
      selectedFilter: value.selectedFilter,
    );
  }

  void _setLoaded({
    NotificationInbox? inbox,
    StockIntelligenceFeed? feed,
    NotificationDeviceList? devices,
  }) {
    value = NotificationState.loaded(
      inbox: inbox,
      feed: feed,
      devices: devices,
      selectedFilter: value.selectedFilter,
    );
  }

  void _upsertDevice(NotificationDevice device) {
    final currentDevices = value.devices ??
        NotificationDeviceList(
          accountId: '',
          activeCount: 0,
          totalCount: 0,
          devices: const [],
          servedAt: DateTime.now().toUtc(),
        );
    _setLoaded(
      inbox: value.inbox,
      feed: value.feed,
      devices: currentDevices.replace(device),
    );
  }

  void _replaceInbox(NotificationInbox inbox) {
    _setLoaded(
      inbox: inbox,
      feed: value.feed,
      devices: value.devices,
    );
  }
}
