import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/resources/app_sizes.dart';
import '../../../core/resources/app_strings.dart';
import '../../../core/widgets/jbb_empty_state.dart';
import '../../../core/widgets/page_content.dart';
import '../../booking/providers/booking_provider.dart';
import '../../membership/providers/membership_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../store/providers/store_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/direct_video_background_player.dart';
import '../widgets/home_hero_banner.dart';
import '../widgets/membership_summary_card.dart';
import '../widgets/next_session_card.dart';
import '../widgets/product_ad_banner.dart';
import '../widgets/programs_section.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/youtube_background_player.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(profileProvider).value,
        next = ref.watch(nextBookingProvider);
    final settings = ref.watch(settingsProvider).value;
    final promoVideoUrl = settings?['promoVideoUrl'] ?? '';
    final heroImageUrl = settings?['heroImageUrl'] as String?;
    final videoId = extractYoutubeId(promoVideoUrl);
    final featuredProduct = ref.watch(featuredProductProvider);
    final sessionsRemaining = (user?['sessionsRemaining'] as num?) ?? 0;
    final sessionsReserved = (user?['sessionsReserved'] as num?) ?? 0;
    final planId = user?['membershipPlanId'] as String?;
    final plans = ref.watch(plansProvider).value ?? const [];
    final planName = planId == null
        ? null
        : plans.cast<Map<String, dynamic>?>().firstWhere(
                (p) => p?['id'] == planId,
                orElse: () => null,
              )?['name']
              as String?;
    return PageContent(
      showHeader: false,
      refresh: () async {
        ref.invalidate(profileProvider);
        ref.invalidate(bookingsProvider);
        await ref.read(bookingsProvider.future);
      },
      children: [
        HomeHeroBanner(
          name: (user?['fullName'] ?? AppStrings.uiChampion)
              .toString()
              .split(' ')
              .first,
          imageUrl: heroImageUrl,
        ),
        if (videoId != null) ...[
          const SizedBox(height: AppSizes.s16),
          YoutubeBackgroundPlayer(videoId: videoId),
        ] else if (promoVideoUrl.isNotEmpty) ...[
          const SizedBox(height: AppSizes.s16),
          DirectVideoBackgroundPlayer(url: promoVideoUrl),
        ],
        if (featuredProduct != null) ...[
          const SizedBox(height: AppSizes.s16),
          ProductAdBanner(product: featuredProduct),
        ],
        if (sessionsRemaining > 0 || sessionsReserved > 0) ...[
          const SizedBox(height: AppSizes.s16),
          MembershipSummaryCard(
            planName: planName,
            sessionsRemaining: sessionsRemaining.toInt(),
            sessionsReserved: sessionsReserved.toInt(),
          ),
        ],
        const SizedBox(height: AppSizes.s20),
        if (next != null)
          NextSessionCard(booking: next)
        else
          const JbbEmptyState(
            message: AppStrings.yourNextSessionStartsWithABooking,
          ),
        const QuickActionsGrid(),
        const SizedBox(height: AppSizes.s18),
        const ProgramsSection(),
      ],
    );
  }
}
