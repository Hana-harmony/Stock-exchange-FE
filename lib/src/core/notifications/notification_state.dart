part of '../notification_controller.dart';

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
  })  : status = NotificationStatus.loading,
        errorMessage = null;

  const NotificationState.loaded({
    required this.inbox,
    required this.feed,
    this.devices,
    this.selectedFilter = NotificationFilter.all,
  })  : status = NotificationStatus.loaded,
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

  bool get hasUnreadNotifications => (inbox?.unreadCount ?? 0) > 0;

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
