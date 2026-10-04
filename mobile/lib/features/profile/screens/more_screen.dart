import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/resources/app_colors.dart';
import '../../../core/resources/app_icons.dart';
import '../../../core/resources/app_sizes.dart';
import '../../../core/resources/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/nav_debounce.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/jbb_card.dart';
import '../../../core/widgets/page_content.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(profileProvider).value;
    final useBlackBackground = ref.watch(useBlackBackgroundProvider);
    return PageContent(
      title: AppStrings.more,
      children: [
        JbbCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: AppSizes.avatarRadiusLarge,
                backgroundImage: (user?['avatarUrl'] ?? '').isNotEmpty
                    ? CachedNetworkImageProvider(user!['avatarUrl'])
                    : null,
                child: (user?['avatarUrl'] ?? '').isEmpty
                    ? const AppIcon(AppIcons.user)
                    : null,
              ),
              const SizedBox(width: AppSizes.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?['fullName'] ?? AppStrings.uiMember,
                      style: const TextStyle(
                        fontSize: AppSizes.font20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (user != null)
                      Text(
                        'Member since ${dateLabel(readDate(user['memberSince']))}',
                        style: const TextStyle(
                          fontSize: AppSizes.font12,
                          color: AppColors.grey,
                        ),
                      ),
                    TextButton(
                      onPressed: () => context.safePush(AppRoutes.profile),
                      child: const Text(AppStrings.editProfile),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        for (final item in [
          (AppStrings.myBookings, AppIcons.calendar, AppRoutes.bookings),
          (AppStrings.navMembership, AppIcons.crown, AppRoutes.membership),
          (AppStrings.gymStore, AppIcons.shoppingBag, AppRoutes.store),
          (AppStrings.reviewsRatings, AppIcons.star, AppRoutes.reviews),
          (AppStrings.myAccount, AppIcons.receipt, AppRoutes.payments),
          (
            AppStrings.notifications,
            AppIcons.notification,
            AppRoutes.notifications,
          ),
          (AppStrings.contactUs, AppIcons.phone, AppRoutes.contact),
          (AppStrings.uiLocation, AppIcons.location, AppRoutes.contact),
          (AppStrings.uiAboutUs, AppIcons.info, AppRoutes.about),
          (AppStrings.uiPrivacyPolicy, AppIcons.shield, AppRoutes.privacy),
          (AppStrings.uiTermsOfService, AppIcons.document, AppRoutes.terms),
          (AppStrings.waiverDisclaimer, AppIcons.gavel, AppRoutes.waiver),
          if (user?['role'] == 'admin')
            (AppStrings.adminDashboard, AppIcons.admin, AppRoutes.admin),
        ])
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: AppIcon(item.$2, color: AppColors.materialRed),
            title: Text(item.$1),
            trailing: const AppIcon(AppIcons.chevronRight),
            onTap: () => context.safePush(item.$3),
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(AppStrings.blackBackground),
          subtitle: const Text(
            'Switch between black and the app\'s teal background.',
          ),
          value: useBlackBackground,
          onChanged: (value) =>
              ref.read(useBlackBackgroundProvider.notifier).toggle(value),
        ),
        const SizedBox(height: AppSizes.s20),
        OutlinedButton(
          onPressed: () async {
            try {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go(AppRoutes.welcome);
            } catch (e) {
              if (context.mounted) showMessage(context, friendlyError(e));
            }
          },
          child: const Text(
            AppStrings.signOut,
            style: TextStyle(color: AppColors.materialRed),
          ),
        ),
      ],
    );
  }
}
