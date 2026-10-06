import '../theme/app_palette.dart';
import 'package:flutter/material.dart';
import '../resources/app_colors.dart';
import '../resources/app_sizes.dart';

class JbbCard extends StatelessWidget {
  const JbbCard({
    super.key,
    required this.child,
    this.selected = false,
    this.onTap,
  });
  final Widget child;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: AppSizes.s12),
    decoration: BoxDecoration(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      border: Border.all(
        color: selected ? context.palette.accent : context.palette.separator,
        width: selected ? 2 : 1,
      ),
    ),
    child: Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.s16),
          child: child,
        ),
      ),
    ),
  );
}
