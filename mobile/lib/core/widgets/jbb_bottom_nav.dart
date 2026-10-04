import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../resources/app_colors.dart';
import '../resources/app_icons.dart';
import '../resources/app_sizes.dart';
import '../resources/app_strings.dart';
import 'app_icon.dart';

class JbbBottomNav extends StatelessWidget {
  const JbbBottomNav({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;
  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      height: AppSizes.bottomNavHeight,
      backgroundColor: AppColors.background,
      indicatorColor: AppColors.transparent,
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      ),
      destinations: [
        for (final item in [
          (AppStrings.navHome, AppIcons.navHome),
          (AppStrings.navSchedule, AppIcons.navSchedule),
          (AppStrings.navBook, AppIcons.navBook),
          (AppStrings.navMembership, AppIcons.navMembership),
          (AppStrings.navMore, AppIcons.navMore),
        ])
          NavigationDestination(
            icon: AppIcon(item.$2, color: AppColors.grey),
            selectedIcon: AppIcon(item.$2, color: AppColors.red),
            label: item.$1,
          ),
      ],
    );
  }
}
