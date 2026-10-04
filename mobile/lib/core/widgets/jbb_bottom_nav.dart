import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_icons.dart';
import '../theme/app_colors.dart';
import 'app_icon.dart';

class JbbBottomNav extends StatelessWidget {
  const JbbBottomNav({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;
  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      height: 64,
      backgroundColor: AppColors.background,
      indicatorColor: Colors.transparent,
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      ),
      destinations: [
        for (final item in [
          ('Home', AppIcons.navHome),
          ('Schedule', AppIcons.navSchedule),
          ('Book', AppIcons.navBook),
          ('Membership', AppIcons.navMembership),
          ('More', AppIcons.navMore),
        ])
          NavigationDestination(
            icon: AppIcon(item.$2, color: Colors.grey),
            selectedIcon: AppIcon(item.$2, color: AppColors.red),
            label: item.$1,
          ),
      ],
    );
  }
}
