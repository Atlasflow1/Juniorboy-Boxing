import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/nav_debounce.dart';
import '../providers/home_provider.dart';

/// Shows the gym's own home-page promos (admin-managed "Home Ads"), the
/// same content the website's home page features, kept in sync via the
/// shared `homeAds` Firestore collection.
class HomeAdsSection extends ConsumerWidget {
  const HomeAdsSection({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ads = ref.watch(homeAdsProvider).value ?? [];
    if (ads.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final ad in ads)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Material(
                color: AppColors.card,
                child: InkWell(
                  onTap: () => context.safePush(
                    (ad['linkHref'] as String?)?.isNotEmpty == true
                        ? ad['linkHref']
                        : '/pricing',
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        if ((ad['imageUrl'] ?? '').isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: ad['imageUrl'],
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            ),
                          ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ad['title'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if ((ad['description'] ?? '').isNotEmpty)
                                Text(
                                  ad['description'],
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if ((ad['priceLabel'] ?? '').isNotEmpty ||
                                  (ad['timeLabel'] ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      if ((ad['priceLabel'] ?? '').isNotEmpty)
                                        Text(
                                          ad['priceLabel'],
                                          style: const TextStyle(
                                            color: AppColors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      if ((ad['priceLabel'] ?? '').isNotEmpty &&
                                          (ad['timeLabel'] ?? '').isNotEmpty)
                                        const SizedBox(width: 8),
                                      if ((ad['timeLabel'] ?? '').isNotEmpty)
                                        Text(
                                          ad['timeLabel'],
                                          style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
