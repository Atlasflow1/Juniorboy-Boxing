import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/utils/nav_debounce.dart';
import '../../schedule/providers/schedule_provider.dart';

class _Slide {
  const _Slide(this.classId, this.imageUrl);
  final String classId;
  final String imageUrl;
}

/// A sliding, auto-advancing banner of the ad photos an admin added to a
/// program (class) — distinct from the small thumbnail shown in "Our
/// Programs". Tapping a slide opens that program's schedule.
class ProgramAdsCarousel extends ConsumerStatefulWidget {
  const ProgramAdsCarousel({super.key});
  @override
  ConsumerState<ProgramAdsCarousel> createState() => _ProgramAdsCarouselState();
}

class _ProgramAdsCarouselState extends ConsumerState<ProgramAdsCarousel> {
  final controller = PageController();
  Timer? timer;
  int page = 0;

  void _restartAutoAdvance(int itemCount) {
    timer?.cancel();
    if (itemCount <= 1) return;
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!controller.hasClients) return;
      final next = (page + 1) % itemCount;
      controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
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
    final classes = ref.watch(classesProvider).value ?? [];
    final slides = <_Slide>[
      for (final c in classes)
        for (final url in (c['adImages'] as List?) ?? const [])
          if ((url as String).isNotEmpty) _Slide(c['id'] as String? ?? '', url),
    ];
    if (slides.isEmpty) return const SizedBox.shrink();
    _restartAutoAdvance(slides.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: controller,
            itemCount: slides.length,
            onPageChanged: (i) => setState(() => page = i),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => context.safePush('/schedule'),
                  child: CachedNetworkImage(
                    imageUrl: slides[i].imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (slides.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == page ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == page ? Colors.red : Colors.white24,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
