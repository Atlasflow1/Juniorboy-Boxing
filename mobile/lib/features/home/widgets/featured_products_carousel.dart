import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/nav_debounce.dart';
import '../../store/providers/store_provider.dart';

/// A sliding, auto-advancing banner of the products the admin flagged
/// "Feature on Home" — swipe manually or let it advance on its own. Tapping
/// a slide opens the Gym Store.
class FeaturedProductsCarousel extends ConsumerStatefulWidget {
  const FeaturedProductsCarousel({super.key});
  @override
  ConsumerState<FeaturedProductsCarousel> createState() =>
      _FeaturedProductsCarouselState();
}

class _FeaturedProductsCarouselState
    extends ConsumerState<FeaturedProductsCarousel> {
  final controller = PageController();
  Timer? timer;
  int page = 0;

  void _restartAutoAdvance(int itemCount) {
    timer?.cancel();
    if (itemCount <= 1) return;
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!controller.hasClients) return;
      // Paging to a higher index slides new content in from the right —
      // the right-to-left motion this carousel is supposed to have.
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
    final products = ref.watch(featuredProductsProvider);
    if (products.isEmpty) return const SizedBox.shrink();
    _restartAutoAdvance(products.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 108,
          child: PageView.builder(
            controller: controller,
            itemCount: products.length,
            onPageChanged: (i) => setState(() => page = i),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _ProductSlide(product: products[i]),
            ),
          ),
        ),
        if (products.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < products.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == page ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == page ? AppColors.red : Colors.white24,
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

class _ProductSlide extends StatelessWidget {
  const _ProductSlide({required this.product});
  final Map<String, dynamic> product;
  @override
  Widget build(BuildContext context) {
    final imageUrl = (product['imageUrl'] as String?) ?? '';
    final discountPercent = (product['discountPercent'] as num?)?.toDouble() ?? 0;
    final hasDiscount = product['discountActive'] == true && discountPercent > 0;
    final priceCents = (product['price'] as num?) ?? 0;
    final saleCents = hasDiscount
        ? (priceCents * (1 - discountPercent / 100)).round()
        : priceCents;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: AppColors.card,
        child: InkWell(
          onTap: () => context.safePush('/store'),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)
                        : Container(
                            color: Colors.white10,
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FROM THE GYM STORE',
                        style: TextStyle(
                          color: AppColors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (product['name'] as String?) ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (hasDiscount)
                        Row(
                          children: [
                            Text(
                              '\$${(priceCents / 100).toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '\$${(saleCents / 100).toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          (product['priceLabel'] as String?) ?? '',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
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
    );
  }
}
