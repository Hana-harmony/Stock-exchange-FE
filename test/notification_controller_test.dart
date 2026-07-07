import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stock_exchange_fe/src/core/exchange_api_client.dart';
import 'package:stock_exchange_fe/src/core/notification_controller.dart';

void main() {
  test('loads notification inbox and K-News feed', () async {
    final controller = NotificationController(
      apiClient: ExchangeApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/notifications/devices')) {
            return _jsonEnvelope(_notificationDevicesJson());
          }
          if (request.url.path.endsWith('/notifications')) {
            return _jsonEnvelope(_notificationInboxJson());
          }
          if (request.url.path.endsWith('/intelligence')) {
            return _jsonEnvelope(_stockIntelligenceJson());
          }
          return _jsonEnvelope({});
        }),
      ),
    );
    addTearDown(controller.dispose);

    await controller.loadAlerts(accountId: 'ACC-ABC123456789');

    expect(controller.value.status, NotificationStatus.loaded);
    expect(controller.value.inbox?.unreadCount, 1);
    expect(controller.value.devices?.activeCount, 1);
    expect(
        controller.value.filteredNotifications.single.targetLabel, 'Watchlist');
    expect(
      controller
          .value.filteredNotifications.single.glossaryTerms.single.displayLabel,
      '공시 -> disclosure',
    );
    expect(
      controller.value.filteredNotifications.single.translationQualityFlags,
      ['GLOSSARY_MATCHED'],
    );
    expect(
      controller.value.filteredNotifications.single.deliveryProviderLabel,
      'LOCAL_NOOP_PUSH',
    );
    expect(
      controller.value.filteredNotifications.single.deliveryAttemptLabel,
      'Attempt 1',
    );
    expect(
      controller.value.filteredNotifications.single.deliveryNeedsAttention,
      isFalse,
    );
    expect(
        controller.value.feed?.items.single.title, 'Samsung earnings improve');
    expect(
      controller.value.feed?.items.single.glossaryTerms.single.englishTerm,
      'earnings',
    );
    expect(
        controller.value.feed?.items.single.summaryLines.what, 'What happened');
    expect(controller.value.feed?.items.single.imageUrls.single,
        'https://news.example.com/image.jpg');
    expect(
        controller.value.feed?.items.single.contentAvailability, 'FULL_TEXT');
  });

  test('filters watchlist notifications and marks read', () async {
    final controller = NotificationController(
      apiClient: ExchangeApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/read')) {
            return _jsonEnvelope(_readNotificationJson());
          }
          if (request.url.path.endsWith('/notifications/devices')) {
            return _jsonEnvelope(_notificationDevicesJson());
          }
          if (request.url.path.endsWith('/notifications')) {
            return _jsonEnvelope(_notificationInboxJson());
          }
          return _jsonEnvelope(_stockIntelligenceJson());
        }),
      ),
    );
    addTearDown(controller.dispose);

    await controller.loadAlerts(accountId: 'ACC-ABC123456789');
    controller.setFilter(NotificationFilter.watchlist);

    expect(controller.value.filteredNotifications.length, 1);

    await controller.markRead(
      accountId: 'ACC-ABC123456789',
      notificationId: 'NTF-ABC123456789',
    );

    expect(controller.value.inbox?.unreadCount, 0);
    expect(controller.value.filteredNotifications.single.read, true);
  });

  test('registers and disables local push device', () async {
    final seen = <String>[];
    final controller = NotificationController(
      apiClient: ExchangeApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          seen.add('${request.method} ${request.url.path}');
          if (request.method == 'POST' &&
              request.url.path.endsWith('/notifications/devices')) {
            expect(jsonDecode(request.body), {
              'platform': 'IOS',
              'provider': 'LOCAL_NOOP_PUSH',
              'deviceToken': 'local-mobile-device-token-0001',
              'appVersion': '0.1.0',
              'locale': 'en_US',
            });
            return _jsonEnvelope(_notificationDeviceJson(active: true));
          }
          if (request.method == 'DELETE') {
            return _jsonEnvelope(_notificationDeviceJson(active: false));
          }
          return _jsonEnvelope({});
        }),
      ),
    );
    addTearDown(controller.dispose);

    await controller.registerLocalDevice(accountId: 'ACC-ABC123456789');

    expect(controller.value.devices?.activeCount, 1);
    expect(
        controller.value.devices?.devices.single.maskedToken, 'local-...0001');

    await controller.disableDevice(
      accountId: 'ACC-ABC123456789',
      deviceTokenId: 'NTD-ABC123456789',
    );

    expect(controller.value.devices?.activeCount, 0);
    expect(controller.value.devices?.devices.single.active, false);
    expect(seen, [
      'POST /api/v1/accounts/ACC-ABC123456789/notifications/devices',
      'DELETE /api/v1/accounts/ACC-ABC123456789/notifications/devices/NTD-ABC123456789',
    ]);
  });

  test('requires sign in before loading alert inbox', () async {
    var called = false;
    final controller = NotificationController(
      apiClient: ExchangeApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          called = true;
          return _jsonEnvelope({});
        }),
      ),
    );
    addTearDown(controller.dispose);

    await controller.loadAlerts(accountId: null);

    expect(called, isFalse);
    expect(controller.value.status, NotificationStatus.failure);
    expect(controller.value.errorMessage, 'Sign in to load alert inbox.');
  });

  test('does not treat What Why Impact summary as stock article body', () {
    final item = StockIntelligenceItem.fromJson({
      ...((_stockIntelligenceJson()['items'] as List<Object?>).single
          as Map<String, Object?>),
      'translatedContent':
          'What: Samsung earnings improved. Why: HBM demand expanded. Impact: Investors should monitor profits.',
      'originalContent': '삼성전자 뉴스 원문 전문입니다. HBM 수요 확대와 실적 개선 배경을 상세히 설명합니다.',
    });

    expect(item.displayBody, item.originalContent);
    expect(item.contentPreview, startsWith('삼성전자 뉴스 원문 전문입니다.'));
    expect(item.contentPreview, isNot(contains('What:')));
  });
}

http.Response _jsonEnvelope(Map<String, Object?> data) {
  return http.Response(
    jsonEncode({
      'success': true,
      'status': 200,
      'code': 'COMMON_000',
      'message': 'OK',
      'data': data,
      'timestamp': '2026-06-18T06:00:00Z',
    }),
    200,
    headers: {'content-type': 'application/json'},
  );
}

Map<String, Object?> _notificationInboxJson() {
  return {
    'accountId': 'ACC-ABC123456789',
    'unreadCount': 1,
    'totalCount': 1,
    'notifications': [
      {
        'notificationId': 'NTF-ABC123456789',
        'eventId': 'ALERT-1',
        'subjectType': 'STOCK',
        'subjectId': '005930',
        'sourceType': 'DISCLOSURE',
        'title': 'Samsung disclosure translated',
        'summary': 'AI summary with sentiment and importance.',
        'originalUrl': 'https://dart.fss.or.kr/report',
        'primaryStockCode': '005930',
        'matchedStockCodes': ['005930'],
        'matchReasons': ['WATCHLIST'],
        'glossaryTerms': [_glossaryTerm('공시', 'disclosure', 'DISCLOSURE')],
        'translationQualityFlags': ['GLOSSARY_MATCHED'],
        'deliveryStatus': 'DELIVERED',
        'deliveryProvider': 'LOCAL_NOOP_PUSH',
        'deliveryAttemptCount': 1,
        'deliveredAt': '2026-06-18T06:00:00Z',
        'lastDeliveryError': null,
        'read': false,
        'createdAt': '2026-06-18T06:00:00Z',
        'readAt': null,
      }
    ],
    'servedAt': '2026-06-18T06:01:00Z',
  };
}

Map<String, Object?> _readNotificationJson() {
  final json = _notificationInboxJson()['notifications'] as List<Object?>;
  return {
    ...(json.single as Map<String, Object?>),
    'read': true,
    'readAt': '2026-06-18T06:02:00Z',
  };
}

Map<String, Object?> _stockIntelligenceJson() {
  return {
    'stockCode': '005930',
    'dataSource': 'ALERT_EVENT_STORE',
    'itemCount': 1,
    'items': [
      {
        'eventId': 'ALERT-1',
        'sourceType': 'NEWS',
        'title': 'Samsung earnings improve',
        'summary': 'Translated three-line summary.',
        'summaryLines': {
          'what': 'What happened',
          'why': 'Why it matters',
          'impact': 'Expected impact',
        },
        'translatedSummary': 'Translated three-line summary.',
        'originalContent': '원문 기사 전문',
        'translatedContent': 'Translated full article content.',
        'imageUrls': ['https://news.example.com/image.jpg'],
        'contentAvailability': 'FULL_TEXT',
        'originalUrl': 'https://news.example.com/1',
        'primaryStockCode': '005930',
        'relatedStocks': ['005930'],
        'sentiment': 'POSITIVE',
        'importance': 'HIGH',
        'riskLevel': 'LOW',
        'clusterKey': 'cluster-key',
        'glossaryTerms': [_glossaryTerm('실적', 'earnings', 'ACCOUNTING')],
        'translationQualityFlags': ['GLOSSARY_MATCHED'],
        'watchlistTarget': true,
        'holderTarget': false,
        'publishedAt': '2026-06-18T05:55:00Z',
        'receivedAt': '2026-06-18T06:00:00Z',
        'targetCount': 1,
      }
    ],
    'servedAt': '2026-06-18T06:01:00Z',
  };
}

Map<String, Object?> _glossaryTerm(
  String sourceTerm,
  String englishTerm,
  String category,
) {
  return {
    'sourceTerm': sourceTerm,
    'normalizedTerm': sourceTerm,
    'englishTerm': englishTerm,
    'category': category,
  };
}

Map<String, Object?> _notificationDevicesJson() {
  return {
    'accountId': 'ACC-ABC123456789',
    'activeCount': 1,
    'totalCount': 1,
    'devices': [_notificationDeviceJson(active: true)],
    'servedAt': '2026-06-18T06:01:00Z',
  };
}

Map<String, Object?> _notificationDeviceJson({required bool active}) {
  return {
    'deviceTokenId': 'NTD-ABC123456789',
    'platform': 'IOS',
    'provider': 'LOCAL_NOOP_PUSH',
    'tokenHash': 'hash',
    'maskedToken': 'local-...0001',
    'appVersion': '0.1.0',
    'locale': 'en_US',
    'active': active,
    'registeredAt': '2026-06-18T06:00:00Z',
    'lastSeenAt': '2026-06-18T06:00:00Z',
    'disabledAt': active ? null : '2026-06-18T06:02:00Z',
  };
}
