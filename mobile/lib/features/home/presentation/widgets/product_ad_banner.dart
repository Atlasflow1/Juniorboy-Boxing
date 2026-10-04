import '../../../../core/theme/app_palette.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/resources/app_icons.dart';
import '../../../../core/resources/app_sizes.dart';
import '../../../../core/resources/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/nav_debounce.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../store/domain/product.dart';

/// Advertises the product an admin flagged as "featured" near the top of
/// Home, linking through to the Gym Store. Navigates with [context.push],
/// the same pattern [QuickActionsGrid] already uses for `/store` from
/// Home, so it never double-stacks the route.
class ProductAdBanner extends StatelessWidget {
  const ProductAdBanner({super.key, required this.product});
  final Product product;
  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl ?? '';
    final discountPercent = product.discountPercent.toDouble();
    final hasDiscount = product.discountActive == true && discountPercent > 0;
    final priceCents = product.price ?? 0;
    final saleCents = hasDiscount
        ? (priceCents * (1 - discountPercent / 100)).round()
        : priceCents;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radius16),
      child: Material(
        color: context.palette.surface,
        child: InkWell(
          onTap: () => context.safeNavigate(AppRoutes.store),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: context.palette.separator),
              borderRadius: BorderRadius.circular(AppSizes.radius16),
            ),
            padding: const EdgeInsets.all(AppSizes.s14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radius10),
                  child: SizedBox(
                    width: AppSizes.productThumbnailSize,
                    height: AppSizes.productThumbnailSize,
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: context.palette.separator,
                            child: AppIcon(
                              AppIcons.shoppingBag,
                              color: context.palette.textSecondary,
                            ),
                          ),
                  ),
                ),
                SizedBox(width: AppSizes.s14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.uiFromTheGymStore,
                        style: TextStyle(
                          color: context.palette.accent,
                          fontSize: AppSizes.font11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: AppSizes.badgeTracking,
                        ),
                      ),
                      SizedBox(height: AppSizes.s2),
                      Text(
                        product.name ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: AppSizes.font16,
                        ),
                        maxLines: AppSizes.bannerTextLines,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: AppSizes.s4),
                      if (hasDiscount)
                        Row(
                          children: [
                            Text(
                              '\$${(priceCents / 100).toStringAsFixed(2)}',
                              style: TextStyle(
                                color: context.palette.textSecondary,
                                fontSize: AppSizes.font12,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            SizedBox(width: AppSizes.s6),
                            Text(
                              '\$${(saleCents / 100).toStringAsFixed(2)}',
                              style: TextStyle(
                                color: context.palette.success,
                                fontWeight: FontWeight.bold,
                                fontSize: AppSizes.font13,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          product.priceLabel ?? '',
                          style: TextStyle(
                            color: context.palette.textSecondary,
                            fontSize: AppSizes.font13,
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
