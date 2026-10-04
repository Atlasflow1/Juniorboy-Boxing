import 'package:flutter/material.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../../core/resources/app_icons.dart';
import '../../../../core/resources/app_sizes.dart';
import '../../../../core/resources/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/nav_debounce.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/jbb_card.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});
  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: AppSizes.quickActionColumns,
    childAspectRatio: AppSizes.quickActionAspectRatio,
    mainAxisSpacing: AppSizes.s0,
    crossAxisSpacing: AppSizes.s12,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    children: [
      for (final item in [
        (AppStrings.bookClass, AppIcons.boxingGlove, AppRoutes.book),
        (AppStrings.classSchedule, AppIcons.calendar, AppRoutes.schedulePath),
        (AppStrings.navMembership, AppIcons.crown, AppRoutes.membership),
        (AppStrings.gymStore, AppIcons.shoppingBag, AppRoutes.store),
        (AppStrings.uiReviews, AppIcons.star, AppRoutes.reviews),
        (AppStrings.uiContact, AppIcons.phone, AppRoutes.contact),
      ])
        JbbCard(
          onTap: () => context.safeNavigate(item.$3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(item.$2, color: AppColors.materialRed),
              const SizedBox(height: AppSizes.s8),
              Text(
                item.$1,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
    ],
  );
}
