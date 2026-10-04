import 'package:flutter/material.dart';
import '../resources/app_colors.dart';
import '../resources/app_icons.dart';
import '../resources/app_sizes.dart';
import '../resources/app_strings.dart';
import 'app_icon.dart';

class JbbEmptyState extends StatelessWidget {
  const JbbEmptyState({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSizes.s32),
    child: Column(
      children: [
        const AppIcon(
          AppIcons.boxingGlove,
          size: AppSizes.emptyStateIconSize,
          color: AppColors.grey,
        ),
        const SizedBox(height: AppSizes.s14),
        Text(message, textAlign: TextAlign.center),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text(AppStrings.retry)),
      ],
    ),
  );
}
