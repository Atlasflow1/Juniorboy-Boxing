import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_icons.dart';
import '../theme/app_colors.dart';
import 'app_icon.dart';

class JbbBottomNav extends StatelessWidget {
  const JbbBottomNav({super.key, required this.location});
  final String location;
  static const routes = ['/home', '/schedule', '/book', '/membership', '/more'];
  @override
  Widget build(BuildContext context) {
    final index = routes.indexWhere(
      (p) => location == p || location.startsWith('$p/'),
    );
    return NavigationBar(
      height: 64,
      backgroundColor: AppColors.background,
      indicatorColor: Colors.transparent,
      selectedIndex: index < 0 ? 4 : index,
      onDestinationSelected: (i) => context.go(routes[i]),
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
