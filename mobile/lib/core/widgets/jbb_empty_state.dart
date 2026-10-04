import '../theme/app_palette.dart';
import 'package:flutter/material.dart';
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
        AppIcon(
          AppIcons.boxingGlove,
          size: AppSizes.emptyStateIconSize,
          color: context.palette.textSecondary,
        ),
        SizedBox(height: AppSizes.s14),
        Text(message, textAlign: TextAlign.center),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: Text(AppStrings.retry)),
      ],
    ),
  );
}
