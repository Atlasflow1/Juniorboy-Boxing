import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';

class JbbBottomNav extends ConsumerWidget {
  const JbbBottomNav({super.key, required this.location});
  final String location;
  static const routes = ['/home', '/schedule', '/bookings', '/more'];
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = routes.indexWhere(
      (p) => location == p || location.startsWith('$p/'),
    );
    return NavigationBar(
      height: 64,
      backgroundColor: ref.watch(backgroundColorProvider),
      indicatorColor: Colors.transparent,
      selectedIndex: index < 0 ? 3 : index,
      onDestinationSelected: (i) => context.go(routes[i]),
      destinations: [
        for (final item in [
          ('Home', 'home'),
          ('Schedule', 'schedule'),
          ('Bookings', 'log'),
          ('More', 'more'),
        ])
          NavigationDestination(
            icon: SvgPicture.asset(
              'assets/icons/ic_nav_${item.$2}.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
            ),
            selectedIcon: SvgPicture.asset(
              'assets/icons/ic_nav_${item.$2}.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                AppColors.red,
                BlendMode.srcIn,
              ),
            ),
            label: item.$1,
          ),
      ],
    );
  }
}
