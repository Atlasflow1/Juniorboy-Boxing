import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/nav_debounce.dart';
import '../../../core/widgets/jbb_card.dart';
import '../../schedule/providers/schedule_provider.dart';

class ProgramsSection extends ConsumerWidget {
  const ProgramsSection({super.key});
  static const _textPrograms = [
    ('ic_boxing_glove', 'Boxing Training'),
    ('ic_dumbbell', 'Fitness Training'),
    ('ic_triple_glove', 'Strength & Conditioning'),
    ('ic_growth_chart', 'Weight Loss Training'),
    ('ic_shield_privacy', 'Self Defense Training'),
  ];
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classes = ref.watch(classesProvider).value ?? [];
    return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Our Programs', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      for (final program in classes)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Semantics(
            button: true,
            label: 'View ${program['className']} schedule',
            child: InkWell(
              onTap: () => context.safePush('/schedule'),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((program['imageUrl'] ?? '').toString().startsWith('http'))
                      CachedNetworkImage(
                        imageUrl: program['imageUrl'],
                        fit: BoxFit.fitWidth,
                        width: double.infinity,
                      )
                    else if ((program['imageUrl'] ?? '').toString().startsWith('/assets/'))
                      Image.asset(
                        (program['imageUrl'] as String).substring(1),
                        fit: BoxFit.fitWidth,
                        width: double.infinity,
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 2,
                      ),
                      child: Text(
                        '${program['className'] ?? ''}${(program['ageGroup'] ?? '').isNotEmpty ? ' — ${program['ageGroup']}' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if ((program['priceLabel'] ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4, left: 2),
                        child: Builder(builder: (context) {
                          final discountPercent =
                              (program['discountPercent'] as num?)?.toDouble() ?? 0;
                          final hasDiscount =
                              program['discountActive'] == true &&
                              discountPercent > 0 &&
                              (program['price'] as num? ?? 0) > 0;
                          if (!hasDiscount) {
                            return Text(
                              program['priceLabel'],
                              style: const TextStyle(
                                color: AppColors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }
                          final priceCents = (program['price'] as num).toDouble();
                          final saleCents =
                              (priceCents * (1 - discountPercent / 100)).round();
                          return Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${discountPercent.toStringAsFixed(0)}% OFF',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
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
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      for (final item in _textPrograms)
        JbbCard(
          onTap: () => context.safePush(
            '/programs/${['boxing', 'fitness', 'strength', 'weight-loss', 'self-defense'][_textPrograms.indexOf(item)]}',
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/${item.$1}.svg',
                width: 26,
                height: 26,
                colorFilter: const ColorFilter.mode(
                  AppColors.red,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.$2,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
    ],
  );
  }
}
