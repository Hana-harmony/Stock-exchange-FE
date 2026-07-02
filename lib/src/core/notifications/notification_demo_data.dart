part of '../notification_controller.dart';

NotificationInbox _buildDemoInbox() {
  final now = DateTime.now().toUtc();
  return NotificationInbox(
    accountId: 'LOCAL-DEMO-ACCOUNT',
    unreadCount: 0,
    totalCount: 6,
    notifications: [
      _buildDemoItem(
        notificationId: 'LOCAL-NTF-0001',
        title:
            'SAMSUNG ELEC: Dividend Payout Confirmed for FY2025 SAMSUNG ELEC: Dividend Payout Confirmed for FY2025',
        summary:
            'Dividend payout confirmed. Positive signal for watchlist users tracking Samsung Electronics.',
        matchReasons: const ['WATCHLIST'],
        createdAt: now.subtract(const Duration(hours: 1)),
        read: true,
      ),
      _buildDemoItem(
        notificationId: 'LOCAL-NTF-0002',
        title:
            'SAMSUNG ELEC: Dividend Payout Confirmed for FY2025 SAMSUNG ELEC: Dividend Payout Confirmed for FY2025',
        summary:
            'Dividend payout confirmed. Portfolio holders can review the payout timing.',
        matchReasons: const ['PORTFOLIO'],
        createdAt: now.subtract(const Duration(hours: 1, minutes: 8)),
        read: true,
      ),
      _buildDemoItem(
        notificationId: 'LOCAL-NTF-0003',
        title:
            'SAMSUNG ELEC: Dividend Payout Confirmed for FY2025 SAMSUNG ELEC: Dividend Payout Confirmed for FY2025',
        summary:
            'Dividend payout confirmed. Portfolio holders can review the payout timing.',
        matchReasons: const ['HOLDER'],
        createdAt: now.subtract(const Duration(hours: 1, minutes: 14)),
        read: true,
      ),
      _buildDemoItem(
        notificationId: 'LOCAL-NTF-0004',
        title:
            'SAMSUNG ELEC: Dividend Payout Confirmed for FY2025 SAMSUNG ELEC: Dividend Payout Confirmed for FY2025',
        summary:
            'Dividend payout confirmed. Portfolio holders can review the payout timing.',
        matchReasons: const ['PORTFOLIO'],
        createdAt: now.subtract(const Duration(hours: 1, minutes: 20)),
        read: true,
      ),
      _buildDemoItem(
        notificationId: 'LOCAL-NTF-0005',
        title:
            'SAMSUNG ELEC: Dividend Payout Confirmed for FY2025 SAMSUNG ELEC: Dividend Payout Confirmed for FY2025',
        summary:
            'Dividend payout confirmed. Portfolio holders can review the payout timing.',
        matchReasons: const ['PORTFOLIO'],
        createdAt: now.subtract(const Duration(hours: 1, minutes: 27)),
        read: true,
      ),
      _buildDemoItem(
        notificationId: 'LOCAL-NTF-0006',
        title:
            'SAMSUNG ELEC: Dividend Payout Confirmed for FY2025 SAMSUNG ELEC: Dividend Payout Confirmed for FY2025',
        summary:
            'Dividend payout confirmed. Portfolio holders can review the payout timing.',
        matchReasons: const ['PORTFOLIO'],
        createdAt: now.subtract(const Duration(hours: 1, minutes: 34)),
        read: true,
      ),
    ],
    servedAt: now,
  );
}

NotificationItem _buildDemoItem({
  required String notificationId,
  required String title,
  required String summary,
  required List<String> matchReasons,
  required DateTime createdAt,
  required bool read,
}) {
  return NotificationItem(
    notificationId: notificationId,
    eventId: 'LOCAL-EVT-${notificationId.split('-').last}',
    subjectType: 'NEWS',
    subjectId: '005930',
    sourceType: 'LOCAL_DEMO',
    title: title,
    summary: summary,
    originalUrl: '',
    primaryStockCode: '005930',
    matchedStockCodes: const ['005930'],
    matchReasons: matchReasons,
    glossaryTerms: const [],
    translationQualityFlags: const [],
    deliveryStatus: 'DELIVERED',
    deliveryProvider: 'LOCAL_NOOP_PUSH',
    deliveryAttemptCount: 1,
    read: read,
    deliveredAt: createdAt,
    lastDeliveryError: null,
    createdAt: createdAt,
    readAt: read ? createdAt.add(const Duration(minutes: 1)) : null,
  );
}
