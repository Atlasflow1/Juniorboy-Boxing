import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/resources/app_assets.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../../core/resources/app_icons.dart';
import '../../../../core/resources/app_sizes.dart';
import '../../../../core/resources/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/nav_debounce.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/jbb_card.dart';

class ProgramsSection extends StatelessWidget {
  const ProgramsSection({super.key});
  static const _textPrograms = [
    ('ic_boxing_glove', AppStrings.uiBoxingTraining),
    ('ic_dumbbell', AppStrings.uiFitnessTraining),
    ('ic_triple_glove', AppStrings.uiStrengthConditioning),
    ('ic_growth_chart', AppStrings.uiWeightLossTraining),
    ('ic_shield_privacy', AppStrings.uiSelfDefenseTraining),
  ];
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        AppStrings.ourPrograms,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: AppSizes.s12),
      for (final item in [
        (AppAssets.junior, AppStrings.uiJuniorBoxingKidsTeens),
        (AppAssets.group, AppStrings.uiGroupTraining34People),
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.s12),
          child: Semantics(
            button: true,
            label: AppStrings.viewProgramSchedule(item.$2),
            child: InkWell(
              onTap: () => context.safeNavigate(AppRoutes.schedulePath),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radius12),
                child: Image.asset(
                  item.$1,
                  fit: BoxFit.fitWidth,
                  width: double.infinity,
                ),
              ),
            ),
          ),
        ),
      for (final item in _textPrograms)
        JbbCard(
          onTap: () => context.safeNavigate(
            AppRoutes.program(
              [
                'boxing',
                'fitness',
                'strength',
                'weight-loss',
                'self-defense',
              ][_textPrograms.indexOf(item)],
            ),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/${item.$1}.svg',
                width: AppSizes.programIconSize,
                height: AppSizes.programIconSize,
                colorFilter: const ColorFilter.mode(
                  AppColors.red,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: AppSizes.s14),
              Expanded(
                child: Text(
                  item.$2,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: AppSizes.font15,
                  ),
                ),
              ),
              const AppIcon(AppIcons.chevronRight, color: AppColors.muted),
            ],
          ),
        ),
    ],
  );
}
