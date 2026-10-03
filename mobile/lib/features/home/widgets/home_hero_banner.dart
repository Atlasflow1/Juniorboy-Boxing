import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';

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
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            (imageUrl ?? '').isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    AppAssets.homeHero,
                    fit: BoxFit.cover,
                    semanticLabel: 'Junior Boy Boxing',
                  ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.black.withValues(alpha: 0),
                    ],
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
                            style: TextStyle(color: Colors.white),
                          ),
                          TextSpan(
                            text: '$name!',
                            style: const TextStyle(color: AppColors.red),
                          ),
                        ],
                      ),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Keep training. Keep improving.',
                      style: TextStyle(color: Colors.white70),
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
