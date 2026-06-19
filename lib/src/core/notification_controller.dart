import 'package:flutter/foundation.dart';

import 'exchange_api_client.dart';

enum NotificationStatus {
  idle,
  loading,
  loaded,
  failure,
}

class NotificationState {
  const NotificationState({
    required this.status,
    this.inbox,
    this.feed,
    this.devices,
    this.selectedFilter = NotificationFilter.all,
    this.errorMessage,
  });

  const NotificationState.idle()
      : status = NotificationStatus.idle,
        inbox = null,
        feed = null,
        devices = null,
        selectedFilter = NotificationFilter.all,
        errorMessage = null;

  const NotificationState.loading({
    this.inbox,
    this.feed,
    this.devices,
    this.selectedFilter = NotificationFilter.all,
  }) : status = NotificationStatus.loading,
        errorMessage = null;

  const NotificationState.loaded({
    required this.inbox,
    required this.feed,
    this.devices,
    this.selectedFilter = NotificationFilter.all,
  }) : status = NotificationStatus.loaded,
        errorMessage = null;

  const NotificationState.failure({
    required this.errorMessage,
    this.inbox,
    this.feed,
    this.devices,
    this.selectedFilter = NotificationFilter.all,
  }) : status = NotificationStatus.failure;

  final NotificationStatus status;
  final NotificationInbox? inbox;
  final StockIntelligenceFeed? feed;
  final NotificationDeviceList? devices;
  final NotificationFilter selectedFilter;
  final String? errorMessage;

  List<NotificationItem> get filteredNotifications {
    final notifications = inbox?.notifications ?? const <NotificationItem>[];
    return notifications.where(selectedFilter.matches).toList();
  }

  NotificationState copyWithFilter(NotificationFilter filter) {
    return NotificationState(
      status: status,
      inbox: inbox,
      feed: feed,
      devices: devices,
      selectedFilter: filter,
      errorMessage: errorMessage,
    );
  }
}

enum NotificationFilter {
  all('All'),
  portfolio('My Portfolio'),
  watchlist('Watchlist');

  const NotificationFilter(this.label);

  final String label;

  bool matches(NotificationItem item) {
    return switch (this) {
      NotificationFilter.all => true,
      NotificationFilter.portfolio => item.matchReasons.contains('HOLDER') ||
          item.matchReasons.contains('PORTFOLIO'),
      NotificationFilter.watchlist => item.matchReasons.contains('WATCHLIST'),
    };
  }
}

class NotificationInbox {
  const NotificationInbox({
    required this.accountId,
    required this.unreadCount,
    required this.totalCount,
    required this.notifications,
    this.servedAt,
  });

  final String accountId;
  final int unreadCount;
  final int totalCount;
  final List<NotificationItem> notifications;
  final DateTime? servedAt;

  static NotificationInbox fromJson(Map<String, dynamic> json) {
    final notificationValues = json['notifications'] is List
        ? json['notifications'] as List<Object?>
        : const <Object?>[];
    return NotificationInbox(
      accountId: _string(json['accountId'], fallback: ''),
      unreadCount: _int(json['unreadCount']),
      totalCount: _int(json['totalCount']),
      notifications: notificationValues
          .map((value) => NotificationItem.fromJson(_map(value)))
          .toList(),
      servedAt: _dateTime(json['servedAt']),
    );
  }
}

class NotificationItem {
  const NotificationItem({
    required this.notificationId,
    required this.eventId,
    required this.subjectType,
    required this.subjectId,
    required this.sourceType,
    required this.title,
    required this.summary,
    required this.originalUrl,
    required this.primaryStockCode,
    required this.matchedStockCodes,
    required this.matchReasons,
    required this.glossaryTerms,
    required this.translationQualityFlags,
    required this.deliveryStatus,
    required this.deliveryProvider,
    required this.deliveryAttemptCount,
    required this.read,
    this.deliveredAt,
    this.lastDeliveryError,
    this.createdAt,
    this.readAt,
  });

  final String notificationId;
  final String eventId;
  final String subjectType;
  final String subjectId;
  final String sourceType;
  final String title;
  final String summary;
  final String originalUrl;
  final String primaryStockCode;
  final List<String> matchedStockCodes;
  final List<String> matchReasons;
  final List<AlertGlossaryTerm> glossaryTerms;
  final List<String> translationQualityFlags;
  final String deliveryStatus;
  final String deliveryProvider;
  final int deliveryAttemptCount;
  final DateTime? deliveredAt;
  final String? lastDeliveryError;
  final bool read;
  final DateTime? createdAt;
  final DateTime? readAt;

  String get targetLabel {
    if (matchReasons.contains('HOLDER') || matchReasons.contains('PORTFOLIO')) {
      return 'My Portfolio';
    }
    if (matchReasons.contains('WATCHLIST')) {
      return 'Watchlist';
    }
    return 'All';
  }

  static NotificationItem fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      notificationId: _string(json['notificationId'], fallback: ''),
      eventId: _string(json['eventId'], fallback: ''),
      subjectType: _string(json['subjectType'], fallback: ''),
      subjectId: _string(json['subjectId'], fallback: ''),
      sourceType: _string(json['sourceType'], fallback: ''),
      title: _string(json['title'], fallback: 'Untitled alert'),
      summary: _string(json['summary'], fallback: ''),
      originalUrl: _string(json['originalUrl'], fallback: ''),
      primaryStockCode: _string(json['primaryStockCode'], fallback: ''),
      matchedStockCodes: _stringList(json['matchedStockCodes']),
      matchReasons: _stringList(json['matchReasons']),
      glossaryTerms: _glossaryTerms(json['glossaryTerms']),
      translationQualityFlags: _stringList(json['translationQualityFlags']),
      deliveryStatus: _string(json['deliveryStatus'], fallback: ''),
      deliveryProvider: _string(json['deliveryProvider'], fallback: ''),
      deliveryAttemptCount: _int(json['deliveryAttemptCount']),
      deliveredAt: _dateTime(json['deliveredAt']),
      lastDeliveryError: _nullableString(json['lastDeliveryError']),
      read: json['read'] as bool? ?? false,
      createdAt: _dateTime(json['createdAt']),
      readAt: _dateTime(json['readAt']),
    );
  }
}

class StockIntelligenceFeed {
  const StockIntelligenceFeed({
    required this.stockCode,
    required this.dataSource,
    required this.itemCount,
    required this.items,
    this.servedAt,
  });

  final String stockCode;
  final String dataSource;
  final int itemCount;
  final List<StockIntelligenceItem> items;
  final DateTime? servedAt;

  static StockIntelligenceFeed fromJson(Map<String, dynamic> json) {
    final itemValues = json['items'] is List
        ? json['items'] as List<Object?>
        : const <Object?>[];
    return StockIntelligenceFeed(
      stockCode: _string(json['stockCode'], fallback: ''),
      dataSource: _string(json['dataSource'], fallback: ''),
      itemCount: _int(json['itemCount']),
      items: itemValues
          .map((value) => StockIntelligenceItem.fromJson(_map(value)))
          .toList(),
      servedAt: _dateTime(json['servedAt']),
    );
  }
}

class StockIntelligenceItem {
  const StockIntelligenceItem({
    required this.eventId,
    required this.sourceType,
    required this.title,
    required this.summary,
    required this.originalUrl,
    required this.primaryStockCode,
    required this.relatedStocks,
    required this.sentiment,
    required this.importance,
    required this.riskLevel,
    required this.glossaryTerms,
    required this.translationQualityFlags,
    required this.watchlistTarget,
    required this.holderTarget,
    required this.targetCount,
    this.publishedAt,
    this.receivedAt,
  });

  final String eventId;
  final String sourceType;
  final String title;
  final String summary;
  final String originalUrl;
  final String primaryStockCode;
  final List<String> relatedStocks;
  final String sentiment;
  final String importance;
  final String riskLevel;
  final List<AlertGlossaryTerm> glossaryTerms;
  final List<String> translationQualityFlags;
  final bool watchlistTarget;
  final bool holderTarget;
  final DateTime? publishedAt;
  final DateTime? receivedAt;
  final int targetCount;

  String get targetLabel {
    if (holderTarget) {
      return 'My Portfolio';
    }
    if (watchlistTarget) {
      return 'Watchlist';
    }
    return 'All';
  }

  static StockIntelligenceItem fromJson(Map<String, dynamic> json) {
    return StockIntelligenceItem(
      eventId: _string(json['eventId'], fallback: ''),
      sourceType: _string(json['sourceType'], fallback: ''),
      title: _string(json['title'], fallback: 'Untitled intelligence'),
      summary: _string(json['summary'], fallback: ''),
      originalUrl: _string(json['originalUrl'], fallback: ''),
      primaryStockCode: _string(json['primaryStockCode'], fallback: ''),
      relatedStocks: _stringList(json['relatedStocks']),
      sentiment: _string(json['sentiment'], fallback: 'NEUTRAL'),
      importance: _string(json['importance'], fallback: 'NORMAL'),
      riskLevel: _string(json['riskLevel'], fallback: 'LOW'),
      glossaryTerms: _glossaryTerms(json['glossaryTerms']),
      translationQualityFlags: _stringList(json['translationQualityFlags']),
      watchlistTarget: json['watchlistTarget'] as bool? ?? false,
      holderTarget: json['holderTarget'] as bool? ?? false,
      publishedAt: _dateTime(json['publishedAt']),
      receivedAt: _dateTime(json['receivedAt']),
      targetCount: _int(json['targetCount']),
    );
  }
}

class AlertGlossaryTerm {
  const AlertGlossaryTerm({
    required this.sourceTerm,
    required this.normalizedTerm,
    required this.englishTerm,
    required this.category,
  });

  final String sourceTerm;
  final String normalizedTerm;
  final String englishTerm;
  final String category;

  String get displayLabel {
    if (sourceTerm.isEmpty && englishTerm.isEmpty) {
      return category;
    }
    if (sourceTerm.isEmpty) {
      return englishTerm;
    }
    if (englishTerm.isEmpty) {
      return sourceTerm;
    }
    return '$sourceTerm -> $englishTerm';
  }

  static AlertGlossaryTerm fromJson(Map<String, dynamic> json) {
    return AlertGlossaryTerm(
      sourceTerm: _string(json['sourceTerm'], fallback: ''),
      normalizedTerm: _string(json['normalizedTerm'], fallback: ''),
      englishTerm: _string(json['englishTerm'], fallback: ''),
      category: _string(json['category'], fallback: ''),
    );
  }
}

class NotificationDeviceList {
  const NotificationDeviceList({
    required this.accountId,
    required this.activeCount,
    required this.totalCount,
    required this.devices,
    this.servedAt,
  });

  final String accountId;
  final int activeCount;
  final int totalCount;
  final List<NotificationDevice> devices;
  final DateTime? servedAt;

  static NotificationDeviceList fromJson(Map<String, dynamic> json) {
    final deviceValues = json['devices'] is List
        ? json['devices'] as List<Object?>
        : const <Object?>[];
    return NotificationDeviceList(
      accountId: _string(json['accountId'], fallback: ''),
      activeCount: _int(json['activeCount']),
      totalCount: _int(json['totalCount']),
      devices: deviceValues
          .map((value) => NotificationDevice.fromJson(_map(value)))
          .toList(),
      servedAt: _dateTime(json['servedAt']),
    );
  }

  NotificationDeviceList replace(NotificationDevice device) {
    final replacedDevices = [
      for (final current in devices)
        if (current.deviceTokenId == device.deviceTokenId) device else current,
    ];
    final exists = devices.any(
      (current) => current.deviceTokenId == device.deviceTokenId,
    );
    final nextDevices = exists ? replacedDevices : [device, ...devices];
    return NotificationDeviceList(
      accountId: accountId,
      activeCount: nextDevices.where((item) => item.active).length,
      totalCount: nextDevices.length,
      devices: nextDevices,
      servedAt: servedAt,
    );
  }
}

class NotificationDevice {
  const NotificationDevice({
    required this.deviceTokenId,
    required this.platform,
    required this.provider,
    required this.tokenHash,
    required this.maskedToken,
    required this.active,
    this.appVersion,
    this.locale,
    this.registeredAt,
    this.lastSeenAt,
    this.disabledAt,
  });

  final String deviceTokenId;
  final String platform;
  final String provider;
  final String tokenHash;
  final String maskedToken;
  final String? appVersion;
  final String? locale;
  final bool active;
  final DateTime? registeredAt;
  final DateTime? lastSeenAt;
  final DateTime? disabledAt;

  String get displayLabel {
    final status = active ? 'Active' : 'Disabled';
    return '$platform $provider / $status / $maskedToken';
  }

  static NotificationDevice fromJson(Map<String, dynamic> json) {
    return NotificationDevice(
      deviceTokenId: _string(json['deviceTokenId'], fallback: ''),
      platform: _string(json['platform'], fallback: ''),
      provider: _string(json['provider'], fallback: ''),
      tokenHash: _string(json['tokenHash'], fallback: ''),
      maskedToken: _string(json['maskedToken'], fallback: ''),
      appVersion: _nullableString(json['appVersion']),
      locale: _nullableString(json['locale']),
      active: json['active'] as bool? ?? false,
      registeredAt: _dateTime(json['registeredAt']),
      lastSeenAt: _dateTime(json['lastSeenAt']),
      disabledAt: _dateTime(json['disabledAt']),
    );
  }
}

class NotificationController extends ValueNotifier<NotificationState> {
  NotificationController({required ExchangeApiClient apiClient})
      : _apiClient = apiClient,
        super(const NotificationState.idle());

  final ExchangeApiClient _apiClient;

  void setFilter(NotificationFilter filter) {
    value = value.copyWithFilter(filter);
  }

  void clear() {
    value = const NotificationState.idle();
  }

  Future<void> loadAlerts({
    required String? accountId,
    String stockCode = '005930',
  }) async {
    if (accountId == null || accountId.isEmpty) {
      value = NotificationState.failure(
        errorMessage: 'Sign in to load alert inbox.',
        inbox: value.inbox,
        feed: value.feed,
        devices: value.devices,
        selectedFilter: value.selectedFilter,
      );
      return;
    }

    value = NotificationState.loading(
      inbox: value.inbox,
      feed: value.feed,
      devices: value.devices,
      selectedFilter: value.selectedFilter,
    );
    try {
      final results = await Future.wait([
        _apiClient.getNotifications(accountId),
        _apiClient.getStockIntelligenceFeed(stockCode),
        _apiClient.getNotificationDevices(accountId),
      ]);
      value = NotificationState.loaded(
        inbox: NotificationInbox.fromJson(results[0].data ?? {}),
        feed: StockIntelligenceFeed.fromJson(results[1].data ?? {}),
        devices: NotificationDeviceList.fromJson(results[2].data ?? {}),
        selectedFilter: value.selectedFilter,
      );
    } on ExchangeApiException catch (error) {
      value = NotificationState.failure(
        errorMessage: error.message,
        inbox: value.inbox,
        feed: value.feed,
        devices: value.devices,
        selectedFilter: value.selectedFilter,
      );
    } on Object {
      value = NotificationState.failure(
        errorMessage: 'Unable to load alert inbox.',
        inbox: value.inbox,
        feed: value.feed,
        devices: value.devices,
        selectedFilter: value.selectedFilter,
      );
    }
  }

  Future<void> markRead({
    required String? accountId,
    required String notificationId,
  }) async {
    if (accountId == null || accountId.isEmpty) {
      value = NotificationState.failure(
        errorMessage: 'Sign in to update alert inbox.',
        inbox: value.inbox,
        feed: value.feed,
        devices: value.devices,
        selectedFilter: value.selectedFilter,
      );
      return;
    }
    try {
      final response = await _apiClient.markNotificationRead(
        accountId: accountId,
        notificationId: notificationId,
      );
      final updated = NotificationItem.fromJson(response.data ?? {});
      final currentInbox = value.inbox;
      if (currentInbox == null) {
        return;
      }
      final notifications = currentInbox.notifications
          .map((item) =>
              item.notificationId == notificationId ? updated : item)
          .toList();
      value = NotificationState.loaded(
        inbox: NotificationInbox(
          accountId: currentInbox.accountId,
          unreadCount: notifications.where((item) => !item.read).length,
          totalCount: currentInbox.totalCount,
          notifications: notifications,
          servedAt: currentInbox.servedAt,
        ),
        feed: value.feed,
        devices: value.devices,
        selectedFilter: value.selectedFilter,
      );
    } on ExchangeApiException catch (error) {
      value = NotificationState.failure(
        errorMessage: error.message,
        inbox: value.inbox,
        feed: value.feed,
        devices: value.devices,
        selectedFilter: value.selectedFilter,
      );
    } on Object {
      value = NotificationState.failure(
        errorMessage: 'Unable to mark alert as read.',
        inbox: value.inbox,
        feed: value.feed,
        devices: value.devices,
        selectedFilter: value.selectedFilter,
      );
    }
  }

  Future<void> registerLocalDevice({
    required String? accountId,
    String platform = 'IOS',
    String provider = 'LOCAL_NOOP_PUSH',
    String deviceToken = 'local-mobile-device-token-0001',
    String appVersion = '0.1.0',
    String locale = 'en_US',
  }) async {
    if (accountId == null || accountId.isEmpty) {
      value = NotificationState.failure(
        errorMessage: 'Sign in to register this device.',
        inbox: value.inbox,
        feed: value.feed,
        devices: value.devices,
        selectedFilter: value.selectedFilter,
      );
      return;
    }
    try {
      final response = await _apiClient.registerNotificationDevice(
        accountId: accountId,
        platform: platform,
        provider: provider,
        deviceToken: deviceToken,
        appVersion: appVersion,
        locale: locale,
      );
      _upsertDevice(NotificationDevice.fromJson(response.data ?? {}));
    } on ExchangeApiException catch (error) {
      value = NotificationState.failure(
        errorMessage: error.message,
        inbox: value.inbox,
        feed: value.feed,
        devices: value.devices,
        selectedFilter: value.selectedFilter,
      );
    } on Object {
      value = NotificationState.failure(
        errorMessage: 'Unable to register this device.',
        inbox: value.inbox,
        feed: value.feed,
        devices: value.devices,
        selectedFilter: value.selectedFilter,
      );
    }
  }

  Future<void> disableDevice({
    required String? accountId,
    required String deviceTokenId,
  }) async {
    if (accountId == null || accountId.isEmpty) {
      value = NotificationState.failure(
        errorMessage: 'Sign in to disable this device.',
        inbox: value.inbox,
        feed: value.feed,
        devices: value.devices,
        selectedFilter: value.selectedFilter,
      );
      return;
    }
    try {
      final response = await _apiClient.disableNotificationDevice(
        accountId: accountId,
        deviceTokenId: deviceTokenId,
      );
      _upsertDevice(NotificationDevice.fromJson(response.data ?? {}));
    } on ExchangeApiException catch (error) {
      value = NotificationState.failure(
        errorMessage: error.message,
        inbox: value.inbox,
        feed: value.feed,
        devices: value.devices,
        selectedFilter: value.selectedFilter,
      );
    } on Object {
      value = NotificationState.failure(
        errorMessage: 'Unable to disable this device.',
        inbox: value.inbox,
        feed: value.feed,
        devices: value.devices,
        selectedFilter: value.selectedFilter,
      );
    }
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
    value = NotificationState.loaded(
      inbox: value.inbox,
      feed: value.feed,
      devices: currentDevices.replace(device),
      selectedFilter: value.selectedFilter,
    );
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return {};
}

String _string(Object? value, {required String fallback}) {
  if (value == null) {
    return fallback;
  }
  return value.toString();
}

String? _nullableString(Object? value) {
  if (value == null) {
    return null;
  }
  final text = value.toString();
  return text.isEmpty ? null : text;
}

int _int(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

List<String> _stringList(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value.map((item) => item.toString()).toList();
}

List<AlertGlossaryTerm> _glossaryTerms(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value
      .map((item) => AlertGlossaryTerm.fromJson(_map(item)))
      .where((term) => term.displayLabel.isNotEmpty)
      .toList();
}

DateTime? _dateTime(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}
