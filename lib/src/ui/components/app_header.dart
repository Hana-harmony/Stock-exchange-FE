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
  });

  final String title;
  final Widget? leading;
  final List<Widget> actions;
  final bool showBrandMark;
  final bool showDefaultActions;

  @override
  Size get preferredSize => const Size.fromHeight(44);

  @override
  Widget build(BuildContext context) {
    final resolvedActions = actions.isNotEmpty
        ? actions
        : showDefaultActions
            ? const <Widget>[_HeaderActions()]
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
      style: Theme.of(context).textTheme.headlineSmall,
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
          height: 36,
          width: 36,
          child: Image.asset(
            AppAssets.logoSymbol,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 4),
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
  const _HeaderActions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          _HeaderActionButton(
            assetPath: AppAssets.headerSearch,
            semanticLabel: 'Search',
          ),
          SizedBox(width: 4),
          _HeaderActionButton(
            assetPath: AppAssets.headerNotifications,
            semanticLabel: 'Notifications',
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.assetPath,
    required this.semanticLabel,
  });

  final String assetPath;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkResponse(
        onTap: () {},
        radius: 18,
        child: SizedBox(
          height: 36,
          width: 36,
          child: Padding(
            padding: const EdgeInsets.all(6),
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
