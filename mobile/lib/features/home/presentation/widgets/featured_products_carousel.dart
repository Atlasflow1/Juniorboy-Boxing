import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/resources/app_icons.dart';
import '../../../../core/resources/app_sizes.dart';
import '../../../../core/resources/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/nav_debounce.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../store/domain/product.dart';
import '../../../store/presentation/providers/store_provider.dart';

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
  int page = 0, count = 0;
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
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (controller.hasClients) {
        controller.animateToPage(
          (page + 1) % count,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(featuredProductsProvider);
    schedule(products.length);
    if (products.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 108,
      child: PageView.builder(
        controller: controller,
        itemCount: products.length,
        onPageChanged: (i) => page = i,
        itemBuilder: (context, i) => _ProductSlide(product: products[i]),
      ),
    );
  }
}

class _ProductSlide extends StatelessWidget {
  const _ProductSlide({required this.product});
  final Product product;
  @override
  Widget build(BuildContext context) {
    final discounted = product.discountActive && product.discountPercent > 0;
    final cents = product.price ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.s2),
      child: Material(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        child: InkWell(
          onTap: () => context.safeNavigate(AppRoutes.store),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.s14),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: product.imageUrl == null
                      ? AppIcon(
                          AppIcons.shoppingBag,
                          color: context.palette.textSecondary,
                        )
                      : CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(width: AppSizes.s14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.uiFromTheGymStore,
                        style: TextStyle(
                          color: context.palette.accent,
                          fontSize: AppSizes.font11,
                        ),
                      ),
                      Text(
                        product.name ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        discounted
                            ? '\$${(cents * (1 - product.discountPercent / 100) / 100).toStringAsFixed(2)}'
                            : product.priceLabel ?? '',
                        style: TextStyle(
                          color: discounted
                              ? context.palette.success
                              : context.palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                AppIcon(
                  AppIcons.chevronRight,
                  color: context.palette.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
