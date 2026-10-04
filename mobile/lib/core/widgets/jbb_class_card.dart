import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/nav_debounce.dart';
import 'jbb_card.dart';

class JbbClassCard extends StatelessWidget {
  const JbbClassCard({super.key, required this.session, required this.program});
  final Map<String, dynamic> session, program;
  @override
  Widget build(BuildContext context) {
    final maxSpots = session['maxSpots'] as num;
    final spots = maxSpots - (session['bookedSpots'] as num);
    final trainingType = (program['trainingType'] as String?) ?? 'private';
    final trainingTypeLabel = switch (trainingType) {
      'group' => 'GROUP',
      'duo' => 'DUO',
      _ => 'PRIVATE',
    };
    final priceLabel = (program['priceLabel'] as String?) ?? '';
    return JbbCard(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Hero(
              tag: 'class-${session['id']}',
              child: Image.asset(
                'assets/images/photos/photo_kid_boxing.jpg',
                width: 66,
                height: 90,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${session['startTime']} – ${session['endTime']}',
                      style: const TextStyle(color: AppColors.red, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.red),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        trainingTypeLabel,
                        style: const TextStyle(
                          color: AppColors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  program['className'] ?? 'Boxing class',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                Text(
                  program['ageGroup'] ?? '',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 6),
                Text(
                  spots > 0
                      ? '$spots of $maxSpots spots available'
                      : 'Fully booked',
                  style: TextStyle(
                    color: spots > 0 ? AppColors.green : AppColors.red,
                    fontSize: 12,
                  ),
                ),
                if (priceLabel.isNotEmpty)
                  Text(
                    priceLabel,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(64, 42),
                padding: EdgeInsets.zero,
              ),
              onPressed: spots > 0
                  ? () => context.safePush('/booking/${session['id']}')
                  : null,
              child: const Text('Book'),
            ),
          ),
        ],
      ),
    );
  }
}
