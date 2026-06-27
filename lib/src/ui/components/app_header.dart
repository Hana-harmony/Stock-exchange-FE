import 'package:flutter/material.dart';

import '../assets/app_assets.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.leading,
    this.actions = const <Widget>[],
    this.showBrandMark = false,
  });

  final String title;
  final Widget? leading;
  final List<Widget> actions;
  final bool showBrandMark;

  @override
  Size get preferredSize => const Size.fromHeight(44);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: leading ?? (showBrandMark ? const _BrandMark() : null),
      leadingWidth: leading == null && !showBrandMark ? null : 48,
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      actions: actions,
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          height: 36,
          width: 36,
          child: Image.asset(
            AppAssets.logoSymbol,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
