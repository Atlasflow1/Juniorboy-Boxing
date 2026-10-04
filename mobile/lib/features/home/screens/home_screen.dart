import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/page_content.dart';
import '../../profile/providers/profile_provider.dart';
import '../../booking/providers/booking_provider.dart';
import '../../membership/widgets/membership_plans_section.dart';
import '../widgets/home_hero_banner.dart';
import '../widgets/featured_products_carousel.dart';
import '../widgets/home_ads_section.dart';
import '../widgets/gym_contact_footer.dart';
import '../widgets/youtube_background_player.dart';
import '../widgets/direct_video_background_player.dart';
import '../../../core/widgets/social_links_row.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(profileProvider).value;
    final settings = ref.watch(settingsProvider).value;
    final heroImageUrl = settings?['heroImageUrl'] as String?;
    final promoVideoUrl = settings?['promoVideoUrl'] ?? '';
    final videoId = extractYoutubeId(promoVideoUrl);
    return PageContent(
      showHeader: false,
      refresh: () async {
        ref.invalidate(profileProvider);
        ref.invalidate(bookingsProvider);
        await ref.read(bookingsProvider.future);
      },
      children: [
        HomeHeroBanner(
          name: (user?['fullName'] ?? 'Champion').toString().split(' ').first,
          imageUrl: heroImageUrl,
        ),
        const SizedBox(height: 14),
        const Center(child: SocialLinksRow()),
        if (videoId != null) ...[
          const SizedBox(height: 16),
          YoutubeBackgroundPlayer(videoId: videoId),
        ] else if (promoVideoUrl.isNotEmpty) ...[
          const SizedBox(height: 16),
          DirectVideoBackgroundPlayer(url: promoVideoUrl),
        ],
        const SizedBox(height: 20),
        const FeaturedProductsCarousel(),
        const SizedBox(height: 20),
        const HomeAdsSection(),
        const SizedBox(height: 20),
        const MembershipPlansSection(),
        const SizedBox(height: 28),
        const GymContactFooter(),
      ],
    );
  }
}
