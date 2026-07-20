import 'package:flutter/material.dart';

import '../assets/app_assets.dart';
import '../theme/app_tokens.dart';

const appShellNavigationItems = <AppBottomNavigationItem>[
  AppBottomNavigationItem(
    label: 'WatchLists',
    defaultIconAsset: AppAssets.bottomWatchlistsDefault,
    selectedIconAsset: AppAssets.bottomWatchlistsSelected,
  ),
  AppBottomNavigationItem(
    label: 'Markets',
    defaultIconAsset: AppAssets.bottomMarketsDefault,
    selectedIconAsset: AppAssets.bottomMarketsSelected,
  ),
  AppBottomNavigationItem(
    label: 'Accounts',
    defaultIconAsset: AppAssets.bottomAccountsDefault,
    selectedIconAsset: AppAssets.bottomAccountsSelected,
  ),
  AppBottomNavigationItem(
    label: 'Discover',
    defaultIconAsset: AppAssets.bottomDiscoverDefault,
    selectedIconAsset: AppAssets.bottomDiscoverSelected,
  ),
  AppBottomNavigationItem(
    label: 'MY',
    defaultIconAsset: AppAssets.bottomMyDefault,
    selectedIconAsset: AppAssets.bottomMySelected,
  ),
];

class AppBottomNavigationItem {
  const AppBottomNavigationItem({
    required this.label,
    required this.defaultIconAsset,
    required this.selectedIconAsset,
  });

  final String label;
  final String defaultIconAsset;
  final String selectedIconAsset;
}

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onTap,
  });

  final int selectedIndex;
  final List<AppBottomNavigationItem> items;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.gray200)),
        boxShadow: AppShadows.navigation,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 57,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Row(
              children: [
                for (var index = 0; index < items.length; index++)
                  Expanded(
                    child: _BottomNavigationButton(
                      item: items[index],
                      isSelected: index == selectedIndex,
                      onTap: () => onTap(index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavigationButton extends StatelessWidget {
  const _BottomNavigationButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final AppBottomNavigationItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final labelColor = isSelected ? AppColors.orange500 : AppColors.gray600;
    final iconAsset =
        isSelected ? item.selectedIconAsset : item.defaultIconAsset;

    return Semantics(
      button: true,
      selected: isSelected,
      label: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('bottom-nav-${item.label}'),
          onTap: onTap,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          hoverColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: 24,
                  child: Image.asset(
                    iconAsset,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.label,
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: labelColor,
                            letterSpacing: -0.24,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
