import 'package:flutter/material.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../../core/resources/app_sizes.dart';
import '../../../../core/resources/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/nav_debounce.dart';
import '../../../../core/widgets/jbb_card.dart';
import '../../domain/session.dart';
import '../../domain/program.dart';

class JbbClassCard extends StatelessWidget {
  const JbbClassCard({super.key, required this.session, required this.program});
  final Session session;
  final Program program;
  @override
  Widget build(BuildContext context) {
    final spots = session.maxSpots - session.bookedSpots;
    return JbbCard(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radius8),
            child: Hero(
              tag: 'class-${session.id}',
              child: Image.asset(
                'assets/images/photos/photo_kid_boxing.jpg',
                width: AppSizes.classImageWidth,
                height: AppSizes.classImageHeight,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.s14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${session.startTime} – ${session.endTime}',
                  style: const TextStyle(
                    color: AppColors.red,
                    fontSize: AppSizes.font12,
                  ),
                ),
                const SizedBox(height: AppSizes.s5),
                Text(
                  program.className ?? AppStrings.uiBoxingClass,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppSizes.font17,
                  ),
                ),
                Text(
                  program.ageGroup ?? '',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: AppSizes.s6),
                Text(
                  spots > 0
                      ? '$spots spots available'
                      : AppStrings.uiFullyBooked,
                  style: TextStyle(
                    color: spots > 0 ? AppColors.green : AppColors.red,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.s8),
          SizedBox(
            width: AppSizes.classActionWidth,
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(64, 42),
                padding: EdgeInsets.zero,
              ),
              onPressed: spots > 0
                  ? () => context.safeNavigate(AppRoutes.booking(session.id))
                  : null,
              child: const Text(AppStrings.book),
            ),
          ),
        ],
      ),
    );
  }
}
