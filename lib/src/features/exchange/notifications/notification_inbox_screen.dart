part of '../exchange_pages.dart';

class NotificationInboxScreen extends StatefulWidget {
  const NotificationInboxScreen({
    super.key,
    required this.notificationController,
    required this.accountId,
    required this.selectedNavigationIndex,
    required this.onClose,
    required this.onNavigationSelected,
  });

  final NotificationController notificationController;
  final String? accountId;
  final int selectedNavigationIndex;
  final VoidCallback onClose;
  final ValueChanged<int> onNavigationSelected;

  @override
  State<NotificationInboxScreen> createState() =>
      _NotificationInboxScreenState();
}

class _NotificationInboxScreenState extends State<NotificationInboxScreen> {
  @override
  void initState() {
    super.initState();
    widget.notificationController.setFilter(NotificationFilter.all);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureNotificationInbox();
    });
  }

  Future<void> _ensureNotificationInbox() async {
    final currentInbox = widget.notificationController.value.inbox;
    final accountId = widget.accountId;
    final hasAccount = accountId != null && accountId.isNotEmpty;
    final hasInbox =
        currentInbox != null && currentInbox.notifications.isNotEmpty;
    final isDemoInbox =
        currentInbox != null && currentInbox.accountId == 'LOCAL-DEMO-ACCOUNT';

    if (hasAccount && (!hasInbox || isDemoInbox)) {
      await widget.notificationController.loadAlerts(accountId: accountId);
      return;
    }

    if (!hasInbox) {
      widget.notificationController.ensureDemoInbox();
    }
  }

  Future<void> _handleNotificationTap(NotificationItem item) async {
    if (!item.read) {
      final accountId = widget.accountId;
      final hasAccount = accountId != null && accountId.isNotEmpty;
      if (item.isLocalOnly || !hasAccount) {
        widget.notificationController.markReadLocally(item.notificationId);
      } else {
        await widget.notificationController.markRead(
          accountId: accountId,
          notificationId: item.notificationId,
        );
      }
    }

    if (!mounted) {
      return;
    }

    final currentState = widget.notificationController.value;
    final currentItem = _findNotificationItem(
          currentState.inbox?.notifications,
          item.notificationId,
        ) ??
        item;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => NotificationArticleDetailScreen(
          item: currentItem,
          intelligenceItem: _findNotificationIntelligenceItem(
            currentState.feed?.items,
            currentItem,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return ColoredBox(
      color: AppColors.white,
      child: Column(
        children: [
          SizedBox(height: topInset),
          _NotificationInboxHeader(onClose: widget.onClose),
          AnimatedBuilder(
            animation: widget.notificationController,
            builder: (context, _) {
              final state = widget.notificationController.value;
              return _NotificationInboxTabBar(
                selectedFilter: state.selectedFilter,
                onSelected: widget.notificationController.setFilter,
              );
            },
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: widget.notificationController,
              builder: (context, _) {
                final state = widget.notificationController.value;
                final notifications = state.filteredNotifications;

                if (state.status == NotificationStatus.loading &&
                    notifications.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.orange500,
                    ),
                  );
                }

                if (state.status == NotificationStatus.failure &&
                    notifications.isEmpty) {
                  return Padding(
                    padding: AppInsets.compactScreen,
                    child: _MutedInfoCard(
                      title: 'Unable to load notifications',
                      body: state.errorMessage ??
                          'The notification inbox is unavailable right now.',
                    ),
                  );
                }

                if (notifications.isEmpty) {
                  return const Padding(
                    padding: AppInsets.compactScreen,
                    child: _MutedInfoCard(
                      title: 'No notifications',
                      body:
                          'There are no notifications for the selected tab yet.',
                    ),
                  );
                }

                return ListView.separated(
                  key: const ValueKey('notification-inbox-list'),
                  padding: EdgeInsets.zero,
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 0),
                  itemBuilder: (context, index) {
                    final item = notifications[index];
                    return _NotificationInboxCard(
                      item: item,
                      onTap: () => _handleNotificationTap(item),
                    );
                  },
                );
              },
            ),
          ),
          AppBottomNavigation(
            selectedIndex: widget.selectedNavigationIndex,
            items: appShellNavigationItems,
            onTap: widget.onNavigationSelected,
          ),
        ],
      ),
    );
  }
}

NotificationItem? _findNotificationItem(
  List<NotificationItem>? notifications,
  String notificationId,
) {
  if (notifications == null) {
    return null;
  }
  for (final item in notifications) {
    if (item.notificationId == notificationId) {
      return item;
    }
  }
  return null;
}

StockIntelligenceItem? _findNotificationIntelligenceItem(
  List<StockIntelligenceItem>? items,
  NotificationItem notification,
) {
  if (items == null) {
    return null;
  }
  for (final item in items) {
    if (item.eventId == notification.eventId) {
      return item;
    }
  }
  return null;
}

class _NotificationInboxHeader extends StatelessWidget {
  const _NotificationInboxHeader({
    required this.onClose,
  });

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _compactHeaderPadding,
      child: Row(
        children: [
          _NotificationHeaderIconButton(
            key: const ValueKey('notification-header-back'),
            semanticLabel: 'Back',
            onTap: onClose,
            child: Image.asset(
              AppAssets.backArrow,
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Notifications',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 22,
                    height: 31 / 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray1000,
                  ),
            ),
          ),
          _NotificationHeaderIconButton(
            semanticLabel: 'Notification Search',
            onTap: () {},
            child: Image.asset(
              AppAssets.headerSearch,
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 4),
          _NotificationHeaderIconButton(
            semanticLabel: 'Notification Settings',
            onTap: () {},
            child: Image.asset(
              AppAssets.settingsIcon,
              width: 36,
              height: 36,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationHeaderIconButton extends StatelessWidget {
  const _NotificationHeaderIconButton({
    super.key,
    required this.semanticLabel,
    required this.onTap,
    required this.child,
  });

  final String semanticLabel;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: SizedBox.square(
          dimension: 36,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _NotificationInboxTabBar extends StatelessWidget {
  const _NotificationInboxTabBar({
    required this.selectedFilter,
    required this.onSelected,
  });

  final NotificationFilter selectedFilter;
  final ValueChanged<NotificationFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 41,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(left: 12, top: 10),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 234,
            height: 31,
            child: Row(
              children: [
                _NotificationFilterTab(
                  filter: NotificationFilter.all,
                  width: 22,
                  isSelected: selectedFilter == NotificationFilter.all,
                  onTap: () => onSelected(NotificationFilter.all),
                ),
                const SizedBox(width: 18),
                _NotificationFilterTab(
                  filter: NotificationFilter.portfolio,
                  width: 100,
                  isSelected: selectedFilter == NotificationFilter.portfolio,
                  onTap: () => onSelected(NotificationFilter.portfolio),
                ),
                const SizedBox(width: 18),
                _NotificationFilterTab(
                  filter: NotificationFilter.watchlist,
                  width: 76,
                  isSelected: selectedFilter == NotificationFilter.watchlist,
                  onTap: () => onSelected(NotificationFilter.watchlist),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationFilterTab extends StatelessWidget {
  const _NotificationFilterTab({
    required this.filter,
    required this.width,
    required this.isSelected,
    required this.onTap,
  });

  final NotificationFilter filter;
  final double width;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppUnderlineTab(
      key: ValueKey<String>('notification-filter-${filter.name}'),
      label: filter.label,
      width: width,
      isSelected: isSelected,
      onTap: onTap,
      fontSize: 18,
      fontWeightSelected: FontWeight.w600,
      fontWeightUnselected: FontWeight.w500,
      activeColor: AppColors.gray1000,
      inactiveColor: AppColors.gray600,
      underlineWidth: width,
      underlineHeight: 2,
    );
  }
}

class _NotificationInboxCard extends StatelessWidget {
  const _NotificationInboxCard({
    required this.item,
    required this.onTap,
  });

  final NotificationItem item;
  final VoidCallback onTap;

  static const _unreadBackgroundColor = AppColors.orange100;

  @override
  Widget build(BuildContext context) {
    final companyLabel = _notificationCompanyLabel(item);
    return Material(
      color: item.read ? AppColors.white : _unreadBackgroundColor,
      child: InkWell(
        key: ValueKey<String>('notification-card-${item.notificationId}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _StockNewsTargetBadge(label: item.targetLabel),
                        const _StockNewsSentimentBadge(
                          sentiment: _StockNewsSentiment.positive,
                        ),
                        const _StockNewsPriorityBadge(
                          priority: _StockNewsPriority.high,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                            height: 1.375,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$companyLabel · ${_relativeTimeLabel(item.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            height: 1.42,
                            fontWeight: FontWeight.w400,
                            color: AppColors.gray600,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              const _StockNewsImage(
                imageUrl: null,
                width: 85,
                height: 85,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _notificationCompanyLabel(NotificationItem item) {
  final title = item.title.toUpperCase();
  if (title.contains('SAMSUNG')) {
    return 'Samsung';
  }
  if (item.primaryStockCode == '005930') {
    return 'Samsung';
  }
  return item.primaryStockCode.isEmpty ? 'Market' : item.primaryStockCode;
}
