import '../theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../resources/app_sizes.dart';

class JbbLoading extends StatelessWidget {
  const JbbLoading({super.key});
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: context.palette.surface,
    highlightColor: context.palette.separator,
    child: Column(
      children: List.generate(
        3,
        (_) => Container(
          height: AppSizes.loadingPlaceholderHeight,
          margin: const EdgeInsets.only(bottom: AppSizes.s12),
          decoration: BoxDecoration(
            color: context.palette.textPrimary,
            borderRadius: BorderRadius.circular(AppSizes.radius12),
          ),
        ),
      ),
    ),
  );
}
