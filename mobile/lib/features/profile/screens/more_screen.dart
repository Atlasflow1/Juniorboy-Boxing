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
                      onPressed: () => context.safePush('/profile'),
                      child: const Text('Edit Profile'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        for (final item in [
          ('My Bookings', AppIcons.calendar, '/bookings'),
          ('Membership', AppIcons.crown, '/membership'),
          ('Gym Store', AppIcons.shoppingBag, '/store'),
          ('Reviews & Ratings', AppIcons.star, '/reviews'),
          ('My Account', AppIcons.receipt, '/payments'),
          ('Notifications', AppIcons.notification, '/notifications'),
          ('Contact Us', AppIcons.phone, '/contact'),
          ('Location', AppIcons.location, '/contact'),
          ('About Us', AppIcons.info, '/about'),
          ('Privacy Policy', AppIcons.shield, '/privacy'),
          ('Terms of Service', AppIcons.document, '/terms'),
          ('Waiver & Disclaimer', AppIcons.gavel, '/waiver'),
          if (user?['role'] == 'admin')
            ('Admin Dashboard', AppIcons.admin, '/admin'),
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
              if (context.mounted) context.go('/welcome');
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
