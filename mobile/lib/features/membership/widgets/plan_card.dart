import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';

class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.plan,
    required this.selected,
    required this.onTap,
  });
  final Map<String, dynamic> plan;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final discountPercent = (plan['discountPercent'] as num?)?.toDouble() ?? 0;
    final hasDiscount = plan['discountActive'] == true && discountPercent > 0;
    final priceCents = (plan['price'] as num?) ?? 0;
    final saleCents = hasDiscount
        ? (priceCents * (1 - discountPercent / 100)).round()
        : priceCents;
    final imageUrl = (plan['imageUrl'] as String?) ?? '';
    return Semantics(
      selected: selected,
      button: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.red : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Stack(
                children: [
                  if (imageUrl.isNotEmpty)
                    Positioned.fill(
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  if (imageUrl.isNotEmpty)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.78),
                              Colors.black.withValues(alpha: 0.93),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (plan['isRecommended'] == true)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 10, right: 8),
                                child: Text(
                                  'RECOMMENDED',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            if (hasDiscount)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${discountPercent.toStringAsFixed(0)}% OFF',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              selected
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: selected ? Colors.red : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                plan['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (hasDiscount)
                              Text(
                                '\$${(priceCents / 100).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            if (hasDiscount) const SizedBox(width: 6),
                            Text(
                              hasDiscount
                                  ? '\$${(saleCents / 100).toStringAsFixed(2)}'
                                  : plan['priceLabel'],
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: hasDiscount ? Colors.green : null,
                                shadows: const [
                                  Shadow(color: Colors.black54, blurRadius: 6),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 36, top: 8),
                          child: Text(
                            plan['perSessionLabel'] ?? '',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
