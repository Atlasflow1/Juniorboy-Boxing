import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/resources/app_sizes.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/nav_debounce.dart';
import '../../domain/home_ad.dart';
import '../providers/home_provider.dart';

class HomeAdsSection extends ConsumerStatefulWidget {
  const HomeAdsSection({super.key});
  @override
  ConsumerState<HomeAdsSection> createState() => _HomeAdsSectionState();
}

class _HomeAdsSectionState extends ConsumerState<HomeAdsSection> {
  final controller = PageController();
  Timer? timer;
  int page = 0;
  int count = 0;
  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  void schedule(int length) {
    if (length == count) return;
    count = length;
    timer?.cancel();
    if (length < 2) return;
    timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (controller.hasClients) {
        controller.animateToPage(
          (page - 1 + count) % count,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ads = ref.watch(homeAdsProvider).value ?? const <HomeAd>[];
    schedule(ads.length);
    if (ads.isEmpty) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 160,
        child: PageView.builder(
          controller: controller,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ads.length,
          onPageChanged: (value) => page = value,
          itemBuilder: (context, index) => _AdBanner(ad: ads[index]),
        ),
      ),
    );
  }
}

class _AdBanner extends StatelessWidget {
  const _AdBanner({required this.ad});
  final HomeAd ad;
  @override
  Widget build(BuildContext context) => Material(
    color: context.palette.surface,
    child: InkWell(
      onTap: () async {
        final href = ad.linkHref;
        final external = href == null ? null : Uri.tryParse(href);
        if (external != null && (external.scheme == 'https' || external.scheme == 'http')) {
          try { await launchUrl(external, mode: LaunchMode.externalApplication); }
          catch (error) { if (context.mounted) showMessage(context, friendlyError(error)); }
          return;
        }
        if (context.mounted) context.safeNavigate(_routeFor(href));
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (ad.imageUrl != null)
            CachedNetworkImage(imageUrl: ad.imageUrl!, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  context.palette.background.withValues(alpha: .1),
                  context.palette.background.withValues(alpha: .88),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.s16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppSizes.font18,
                      color: context.palette.textPrimary,
                    ),
                  ),
                  if (ad.priceLabel != null || ad.timeLabel != null)
                    Text(
                      [
                        ad.priceLabel,
                        ad.timeLabel,
                      ].whereType<String>().join(' · '),
                      style: TextStyle(color: context.palette.accent),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
  String _routeFor(String? href) {
    if (href == null) return AppRoutes.membership;
    if (href == '/pricing') return AppRoutes.membership;
    if (href.startsWith('/programs/')) return href;
    if (href == AppRoutes.blog || href == AppRoutes.bookings || href == AppRoutes.membership || href == AppRoutes.home || href == AppRoutes.more) return href;
    if (href == AppRoutes.store ||
        href == AppRoutes.schedulePath ||
        href == AppRoutes.contact) {
      return href;
    }
    return AppRoutes.membership;
  }
}
