import 'package:flutter/material.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../../core/resources/app_icons.dart';
import '../../../../core/resources/app_sizes.dart';
import '../../../../core/resources/app_strings.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/jbb_card.dart';
import '../../domain/membership_plan.dart';

class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.plan,
    required this.selected,
    required this.onTap,
  });
  final MembershipPlan plan;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: JbbCard(
      selected: selected,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plan.isRecommended == true)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSizes.s10),
              child: Text(
                AppStrings.uiRecommended,
                style: TextStyle(
                  color: AppColors.materialRed,
                  fontSize: AppSizes.font11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: AppSizes.labelTracking,
                ),
              ),
            ),
          Row(
            children: [
              AppIcon(
                selected ? AppIcons.checkCircle : AppIcons.circle,
                color: selected ? AppColors.materialRed : AppColors.grey,
              ),
              const SizedBox(width: AppSizes.s12),
              Expanded(
                child: Text(
                  plan.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppSizes.font17,
                  ),
                ),
              ),
              Text(
                plan.priceLabel,
                style: const TextStyle(
                  fontSize: AppSizes.font22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: AppSizes.s36,
              top: AppSizes.s8,
            ),
            child: Text(
              plan.perSessionLabel,
              style: const TextStyle(color: AppColors.grey),
            ),
          ),
        ],
      ),
    ),
  );
}
