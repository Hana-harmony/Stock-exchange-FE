import 'package:flutter/material.dart';

import '../assets/app_assets.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.leading,
    this.actions = const <Widget>[],
    this.showBrandMark = false,
    this.showDefaultActions = false,
    this.onAiTap,
    this.onSearchTap,
    this.onNotificationTap,
  });

  final String title;
  final Widget? leading;
  final List<Widget> actions;
  final bool showBrandMark;
  final bool showDefaultActions;
  final VoidCallback? onAiTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;

  @override
  Size get preferredSize => const Size.fromHeight(44);

  @override
  Widget build(BuildContext context) {
    final resolvedActions = actions.isNotEmpty
        ? actions
        : showDefaultActions
            ? <Widget>[
                _HeaderActions(
                  onAiTap: onAiTap,
                  onSearchTap: onSearchTap,
                  onNotificationTap: onNotificationTap,
                ),
              ]
            : const <Widget>[];

    return AppBar(
      automaticallyImplyLeading: false,
      leading: leading,
      leadingWidth: leading == null ? null : 48,
      titleSpacing: leading == null ? 12 : 0,
      title: _HeaderTitle(
        title: title,
        showBrandMark: showBrandMark && leading == null,
      ),
      actions: resolvedActions,
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle({
    required this.title,
    required this.showBrandMark,
  });

  final String title;
  final bool showBrandMark;

  @override
  Widget build(BuildContext context) {
    final titleText = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );

    if (!showBrandMark) {
      return Align(
        alignment: Alignment.centerLeft,
        child: titleText,
      );
    }

    return Row(
      children: [
        SizedBox(
          height: 28,
          width: 28,
          child: Image.asset(
            AppAssets.logoSymbol,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: titleText,
          ),
        ),
      ],
    );
  }
}

class _HeaderActions extends StatelessWidget {
  const _HeaderActions({
    required this.onAiTap,
    required this.onSearchTap,
    required this.onNotificationTap,
  });

  final VoidCallback? onAiTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: _HeaderActionsBody(
        onAiTap: onAiTap,
        onSearchTap: onSearchTap,
        onNotificationTap: onNotificationTap,
      ),
    );
  }
}

class _HeaderActionsBody extends StatelessWidget {
  const _HeaderActionsBody({
    required this.onAiTap,
    required this.onSearchTap,
    required this.onNotificationTap,
  });

  final VoidCallback? onAiTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HeaderActionButton(
          assetPath: AppAssets.headerAiIcon,
          semanticLabel: 'AI Assistant',
          onTap: onAiTap,
          padding: const EdgeInsets.all(2),
        ),
        const SizedBox(width: 8),
        _HeaderActionButton(
          assetPath: AppAssets.headerSearch,
          semanticLabel: 'Search',
          onTap: onSearchTap,
        ),
        const SizedBox(width: 4),
        _HeaderActionButton(
          assetPath: AppAssets.headerNotifications,
          semanticLabel: 'Notifications',
          onTap: onNotificationTap,
        ),
      ],
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.assetPath,
    required this.semanticLabel,
    this.onTap,
    this.padding = const EdgeInsets.all(6),
  });

  final String assetPath;
  final String semanticLabel;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkResponse(
        onTap: onTap,
        radius: 18,
        child: SizedBox(
          height: 36,
          width: 36,
          child: Padding(
            padding: padding,
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
