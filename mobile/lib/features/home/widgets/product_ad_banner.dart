import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';

/// Advertises the product an admin flagged as "featured" near the top of
/// Home, linking through to the Gym Store. Navigates with [context.push],
/// the same pattern [QuickActionsGrid] already uses for `/store` from
/// Home, so it never double-stacks the route.
class ProductAdBanner extends StatelessWidget {
  const ProductAdBanner({super.key, required this.product});
  final Map<String, dynamic> product;
  @override
  Widget build(BuildContext context) {
    final imageUrl = (product['imageUrl'] as String?) ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: AppColors.card,
        child: InkWell(
          onTap: () => context.push('/store'),
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
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                          )
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
