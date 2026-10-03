import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/widgets/page_content.dart';
import '../../../core/widgets/jbb_card.dart';
import '../../../core/widgets/social_links_row.dart';
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
                    ? const Icon(Icons.person)
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
          ('My Bookings', Icons.calendar_month, '/bookings'),
          ('Membership', Icons.workspace_premium, '/membership'),
          ('Gym Store', Icons.shopping_bag_outlined, '/store'),
          ('Reviews & Ratings', Icons.star_outline, '/reviews'),
          ('My Account', Icons.receipt_long, '/payments'),
          ('Notifications', Icons.notifications_outlined, '/notifications'),
          ('Contact Us', Icons.mail_outline, '/contact'),
          ('About Us', Icons.info_outline, '/about'),
          ('Blog', Icons.article_outlined, '/blog'),
          ('Privacy Policy', Icons.shield_outlined, '/privacy'),
          ('Terms of Service', Icons.description_outlined, '/terms'),
          ('Waiver & Disclaimer', Icons.gavel_outlined, '/waiver'),
          if (user?['role'] == 'admin')
            ('Admin Dashboard', Icons.admin_panel_settings_outlined, '/admin'),
        ])
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(item.$2, color: Colors.red),
            title: Text(item.$1),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.safePush(item.$3),
          ),
        const Padding(
          padding: EdgeInsets.only(bottom: 20),
          child: SocialLinksRow(),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Black Background'),
          subtitle: const Text('Switch between black and the app\'s teal background.'),
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
