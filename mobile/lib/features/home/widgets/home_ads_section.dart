import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/nav_debounce.dart';
import '../providers/home_provider.dart';

/// Shows the gym's own home-page promos (admin-managed "Home Ads") as a
/// single banner that advances on its own, one direction only (left to
/// right) — not swipeable, so it never feels like it's fighting the user.
/// Same content the website's home page features, kept in sync via the
/// shared `homeAds` Firestore collection.
class HomeAdsSection extends ConsumerStatefulWidget {
  const HomeAdsSection({super.key});
  @override
  ConsumerState<HomeAdsSection> createState() => _HomeAdsSectionState();
}

class _HomeAdsSectionState extends ConsumerState<HomeAdsSection> {
  final controller = PageController();
  Timer? timer;
  int page = 0;

  void _restartAutoAdvance(int itemCount) {
    timer?.cancel();
    if (itemCount <= 1) return;
    timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!controller.hasClients) return;
      // Paging to a lower index slides new content in from the left — the
      // left-to-right motion this banner is supposed to have.
      final next = (page - 1 + itemCount) % itemCount;
      controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ads = ref.watch(homeAdsProvider).value ?? [];
    if (ads.isEmpty) return const SizedBox.shrink();
    _restartAutoAdvance(ads.length);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 160,
        child: PageView.builder(
          controller: controller,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ads.length,
          onPageChanged: (i) => setState(() => page = i),
          itemBuilder: (context, i) => _HomeAdBanner(ad: ads[i]),
        ),
      ),
    );
  }
}

class _HomeAdBanner extends StatelessWidget {
  const _HomeAdBanner({required this.ad});
  final Map<String, dynamic> ad;
  @override
  Widget build(BuildContext context) {
    final imageUrl = (ad['imageUrl'] ?? '').toString();
    return Material(
      color: AppColors.card,
      child: InkWell(
        onTap: () => context.safePush(
          (ad['linkHref'] as String?)?.isNotEmpty == true
              ? ad['linkHref']
              : '/pricing',
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl.isNotEmpty)
              CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.88),
                  ],
                  stops: const [0.3, 1],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ad['title'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((ad['priceLabel'] ?? '').isNotEmpty ||
                        (ad['timeLabel'] ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if ((ad['priceLabel'] ?? '').isNotEmpty)
                              Text(
                                ad['priceLabel'],
                                style: const TextStyle(
                                  color: AppColors.red,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(color: Colors.black87, blurRadius: 8),
                                  ],
                                ),
                              ),
                            if ((ad['priceLabel'] ?? '').isNotEmpty &&
                                (ad['timeLabel'] ?? '').isNotEmpty)
                              const SizedBox(width: 8),
                            if ((ad['timeLabel'] ?? '').isNotEmpty)
                              Text(
                                ad['timeLabel'],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  shadows: [
                                    Shadow(color: Colors.black87, blurRadius: 8),
                                  ],
                                ),
                              ),
                          ],
                        ),
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
