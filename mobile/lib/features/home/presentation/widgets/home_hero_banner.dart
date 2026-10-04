import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/resources/app_assets.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../../core/resources/app_sizes.dart';
import '../../../../core/resources/app_strings.dart';

/// Square brand hero image at the top of Home, with the welcome
/// greeting overlaid on a dark gradient scrim. Shows the gym's uploaded
/// [imageUrl] (kept in sync with the website's Home page) when set,
/// falling back to the bundled asset otherwise.
class HomeHeroBanner extends StatelessWidget {
  const HomeHeroBanner({super.key, required this.name, this.imageUrl});
  final String name;
  final String? imageUrl;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radius20),
      child: AspectRatio(
        aspectRatio: AppSizes.heroImageAspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            (imageUrl ?? '').isNotEmpty
                ? CachedNetworkImage(imageUrl: imageUrl!, fit: BoxFit.cover)
                : Image.asset(
                    AppAssets.homeHero,
                    fit: BoxFit.cover,
                    semanticLabel: AppStrings.gymName,
                  ),
            Positioned(
              left: AppSizes.s0,
              right: AppSizes.s0,
              top: AppSizes.s0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.s20,
                  AppSizes.s24,
                  AppSizes.s20,
                  AppSizes.s48,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.heroScrimStart, AppColors.heroScrimEnd],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Welcome Back, ',
                            style: TextStyle(color: AppColors.white),
                          ),
                          TextSpan(
                            text: '$name!',
                            style: const TextStyle(color: AppColors.red),
                          ),
                        ],
                      ),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: AppColors.white),
                    ),
                    const SizedBox(height: AppSizes.s6),
                    const Text(
                      AppStrings.uiKeepTrainingKeepImproving,
                      style: TextStyle(color: AppColors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
