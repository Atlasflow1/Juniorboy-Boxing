import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../resources/app_colors.dart';
import '../resources/app_sizes.dart';

class JbbLoading extends StatelessWidget {
  const JbbLoading({super.key});
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: AppColors.card,
    highlightColor: AppColors.border,
    child: Column(
      children: List.generate(
        3,
        (_) => Container(
          height: AppSizes.loadingPlaceholderHeight,
          margin: const EdgeInsets.only(bottom: AppSizes.s12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSizes.radius12),
          ),
        ),
      ),
    ),
  );
}
