part of '../notification_controller.dart';

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

  NotificationInbox copyWith({
    String? accountId,
    List<NotificationItem>? notifications,
    DateTime? servedAt,
  }) {
    final nextNotifications = notifications ?? this.notifications;
    return NotificationInbox(
      accountId: accountId ?? this.accountId,
      unreadCount: nextNotifications.where((item) => !item.read).length,
      totalCount: nextNotifications.length,
      notifications: nextNotifications,
      servedAt: servedAt ?? this.servedAt,
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

  String get deliveryStatusLabel =>
      deliveryStatus.isEmpty ? 'PENDING' : deliveryStatus;

  String get deliveryProviderLabel =>
      deliveryProvider.isEmpty ? 'Not delivered' : deliveryProvider;

  String get deliveryAttemptLabel {
    if (deliveryAttemptCount <= 0) {
      return 'Attempt 0';
    }
    return 'Attempt $deliveryAttemptCount';
  }

  bool get deliveryNeedsAttention {
    final status = deliveryStatusLabel.toUpperCase();
    return status == 'FAILED' || status == 'RETRYING';
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

  NotificationItem copyWith({
    bool? read,
    DateTime? createdAt,
    Object? readAt = _copyWithUndefined,
  }) {
    return NotificationItem(
      notificationId: notificationId,
      eventId: eventId,
      subjectType: subjectType,
      subjectId: subjectId,
      sourceType: sourceType,
      title: title,
      summary: summary,
      originalUrl: originalUrl,
      primaryStockCode: primaryStockCode,
      matchedStockCodes: matchedStockCodes,
      matchReasons: matchReasons,
      glossaryTerms: glossaryTerms,
      translationQualityFlags: translationQualityFlags,
      deliveryStatus: deliveryStatus,
      deliveryProvider: deliveryProvider,
      deliveryAttemptCount: deliveryAttemptCount,
      read: read ?? this.read,
      deliveredAt: deliveredAt,
      lastDeliveryError: lastDeliveryError,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt == _copyWithUndefined ? this.readAt : readAt as DateTime?,
    );
  }
}

class StockIntelligenceFeed {
  const StockIntelligenceFeed({
    required this.stockCode,
    required this.dataSource,
    required this.itemCount,
    required this.items,
    this.nextCursor,
    this.servedAt,
  });

  final String stockCode;
  final String dataSource;
  final int itemCount;
  final List<StockIntelligenceItem> items;
  final String? nextCursor;
  final DateTime? servedAt;

  StockIntelligenceFeed merge(StockIntelligenceFeed next) {
    final byId = <String, StockIntelligenceItem>{
      for (final item in items) item.eventId: item,
      for (final item in next.items) item.eventId: item,
    };
    return StockIntelligenceFeed(
      stockCode: next.stockCode.isNotEmpty ? next.stockCode : stockCode,
      dataSource: next.dataSource.isNotEmpty ? next.dataSource : dataSource,
      itemCount: byId.length,
      items: byId.values.toList(growable: false),
      nextCursor: next.nextCursor,
      servedAt: next.servedAt ?? servedAt,
    );
  }

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
      nextCursor: _nullableString(json['nextCursor']),
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
    required this.summaryLines,
    required this.translatedSummary,
    required this.originalContent,
    required this.translatedContent,
    required this.imageUrls,
    required this.contentAvailability,
    required this.originalUrl,
    required this.primaryStockCode,
    required this.relatedStocks,
    required this.sentiment,
    required this.importance,
    required this.riskLevel,
    required this.clusterKey,
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
  final AlertSummaryLines summaryLines;
  final String translatedSummary;
  final String originalContent;
  final String translatedContent;
  final List<String> imageUrls;
  final String contentAvailability;
  final String originalUrl;
  final String primaryStockCode;
  final List<String> relatedStocks;
  final String sentiment;
  final String importance;
  final String riskLevel;
  final String clusterKey;
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

  String get displaySummary {
    if (summaryLines.hasAny) {
      return summaryLines.lines.join('\n');
    }
    return translatedSummary.isNotEmpty ? translatedSummary : summary;
  }

  String get displayBody {
    if (_isArticleBodyCandidate(
      translatedContent,
      summaryLines: summaryLines,
      translatedSummary: translatedSummary,
    )) {
      return translatedContent;
    }
    return '';
  }

  String get contentPreview {
    final content = displayBody;
    if (content.isEmpty) {
      return '';
    }
    return content.length > 280 ? '${content.substring(0, 280)}...' : content;
  }

  static StockIntelligenceItem fromJson(Map<String, dynamic> json) {
    return StockIntelligenceItem(
      eventId: _string(json['eventId'], fallback: ''),
      sourceType: _string(json['sourceType'], fallback: ''),
      title: _string(json['title'], fallback: 'Untitled intelligence'),
      summary: _string(json['summary'], fallback: ''),
      summaryLines: AlertSummaryLines.fromJson(_map(json['summaryLines'])),
      translatedSummary: _string(json['translatedSummary'], fallback: ''),
      originalContent: _string(json['originalContent'], fallback: ''),
      translatedContent: _string(json['translatedContent'], fallback: ''),
      imageUrls: _stringList(json['imageUrls']),
      contentAvailability:
          _string(json['contentAvailability'], fallback: 'SUMMARY_ONLY'),
      originalUrl: _string(json['originalUrl'], fallback: ''),
      primaryStockCode: _string(json['primaryStockCode'], fallback: ''),
      relatedStocks: _stringList(json['relatedStocks']),
      sentiment: _string(json['sentiment'], fallback: 'NEUTRAL'),
      importance: _string(json['importance'], fallback: 'NORMAL'),
      riskLevel: _string(json['riskLevel'], fallback: 'LOW'),
      clusterKey: _string(json['clusterKey'], fallback: ''),
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

class AlertSummaryLines {
  const AlertSummaryLines({
    required this.what,
    required this.why,
    required this.impact,
  });

  final String what;
  final String why;
  final String impact;

  bool get hasAny => what.isNotEmpty || why.isNotEmpty || impact.isNotEmpty;

  List<String> get lines => [
        if (what.isNotEmpty) 'What: $what',
        if (why.isNotEmpty) 'Why: $why',
        if (impact.isNotEmpty) 'Impact: $impact',
      ];

  static AlertSummaryLines fromJson(Map<String, dynamic> json) {
    return AlertSummaryLines(
      what: _string(json['what'], fallback: ''),
      why: _string(json['why'], fallback: ''),
      impact: _string(json['impact'], fallback: ''),
    );
  }
}

class AlertGlossaryTerm {
  const AlertGlossaryTerm({
    required this.sourceTerm,
    required this.normalizedTerm,
    required this.englishTerm,
    required this.category,
    required this.description,
  });

  final String sourceTerm;
  final String normalizedTerm;
  final String englishTerm;
  final String category;
  final String description;

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
      description: _string(json['description'], fallback: ''),
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
