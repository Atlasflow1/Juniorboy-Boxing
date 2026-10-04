import '../../../core/router/app_routes.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/widgets/app_icon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/widgets/page_content.dart';
import '../../../core/widgets/jbb_card.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/nav_debounce.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(profileProvider).value;
    final useBlackBackground = ref.watch(useBlackBackgroundProvider);
    return PageContent(
      title: 'More',
      children: [
        JbbCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: (user?['avatarUrl'] ?? '').isNotEmpty
                    ? CachedNetworkImageProvider(user!['avatarUrl'])
                    : null,
                child: (user?['avatarUrl'] ?? '').isEmpty
                    ? const AppIcon(AppIcons.user)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?['fullName'] ?? 'Member',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (user != null)
                      Text(
                        'Member since ${dateLabel(readDate(user['memberSince']))}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    TextButton(
                      onPressed: () => context.safePush(AppRoutes.profile),
                      child: const Text('Edit Profile'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        for (final item in [
          ('My Bookings', AppIcons.calendar, AppRoutes.bookings),
          ('Membership', AppIcons.crown, AppRoutes.membership),
          ('Gym Store', AppIcons.shoppingBag, AppRoutes.store),
          ('Reviews & Ratings', AppIcons.star, AppRoutes.reviews),
          ('My Account', AppIcons.receipt, AppRoutes.payments),
          ('Notifications', AppIcons.notification, AppRoutes.notifications),
          ('Contact Us', AppIcons.phone, AppRoutes.contact),
          ('Location', AppIcons.location, AppRoutes.contact),
          ('About Us', AppIcons.info, AppRoutes.about),
          ('Privacy Policy', AppIcons.shield, AppRoutes.privacy),
          ('Terms of Service', AppIcons.document, AppRoutes.terms),
          ('Waiver & Disclaimer', AppIcons.gavel, AppRoutes.waiver),
          if (user?['role'] == 'admin')
            ('Admin Dashboard', AppIcons.admin, AppRoutes.admin),
        ])
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: AppIcon(item.$2, color: Colors.red),
            title: Text(item.$1),
            trailing: const AppIcon(AppIcons.chevronRight),
            onTap: () => context.safePush(item.$3),
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Black Background'),
          subtitle: const Text(
            'Switch between black and the app\'s teal background.',
          ),
          value: useBlackBackground,
          onChanged: (value) =>
              ref.read(useBlackBackgroundProvider.notifier).toggle(value),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () async {
            try {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go(AppRoutes.welcome);
            } catch (e) {
              if (context.mounted) showMessage(context, friendlyError(e));
            }
          },
          child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
