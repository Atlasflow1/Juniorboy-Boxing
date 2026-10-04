import 'package:flutter/material.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../../core/resources/app_icons.dart';
import '../../../../core/resources/app_sizes.dart';
import '../../../../core/resources/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/nav_debounce.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/jbb_card.dart';

/// Confirms the member's active subscription right on Home — plan name
/// and session balance — so a purchase feels immediately reflected,
/// without having to open the Membership tab to check.
class MembershipSummaryCard extends StatelessWidget {
  const MembershipSummaryCard({
    super.key,
    required this.planName,
    required this.sessionsRemaining,
    required this.sessionsReserved,
  });
  final String? planName;
  final int sessionsRemaining;
  final int sessionsReserved;
  @override
  Widget build(BuildContext context) => JbbCard(
    onTap: () => context.safeNavigate(AppRoutes.membership),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppIcon(AppIcons.crown, color: AppColors.materialRed),
        const SizedBox(width: AppSizes.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                planName ?? AppStrings.uiYourMembership,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: AppSizes.font16,
                ),
              ),
              const SizedBox(height: AppSizes.s4),
              Text(AppStrings.sessionsRemaining(sessionsRemaining)),
              if (sessionsReserved > 0)
                Text(
                  '$sessionsReserved reserved for upcoming classes',
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: AppSizes.font12,
                  ),
                ),
            ],
          ),
        ),
        const AppIcon(AppIcons.chevronRight, color: AppColors.grey),
      ],
    ),
  );
}
