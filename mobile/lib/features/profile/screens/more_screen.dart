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
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(profileProvider).value;
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
        const SizedBox(height: 24),
        const Center(child: SocialLinksRow()),
        if (user?['role'] == 'admin') ...[
          const SizedBox(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.admin_panel_settings_outlined, color: Colors.red),
            title: const Text('Admin Dashboard'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.safePush('/admin'),
          ),
        ],
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
