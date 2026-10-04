import '../../../../core/theme/app_palette.dart';
import 'package:flutter/material.dart';
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
          SizedBox(width: AppSizes.s14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${session.startTime} – ${session.endTime}',
                  style: TextStyle(
                    color: context.palette.accent,
                    fontSize: AppSizes.font12,
                  ),
                ),
                SizedBox(height: AppSizes.s5),
                Text(
                  program.className ?? AppStrings.uiBoxingClass,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppSizes.font17,
                  ),
                ),
                Text(
                  program.ageGroup ?? '',
                  style: TextStyle(color: context.palette.textSecondary),
                ),
                SizedBox(height: AppSizes.s6),
                Text(
                  spots > 0
                      ? '$spots spots available'
                      : AppStrings.uiFullyBooked,
                  style: TextStyle(
                    color: spots > 0
                        ? context.palette.success
                        : context.palette.accent,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSizes.s8),
          SizedBox(
            width: AppSizes.classActionWidth,
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: Size(64, 42),
                padding: EdgeInsets.zero,
              ),
              onPressed: spots > 0
                  ? () => context.safeNavigate(AppRoutes.booking(session.id))
                  : null,
              child: Text(AppStrings.book),
            ),
          ),
        ],
      ),
    );
  }
}
