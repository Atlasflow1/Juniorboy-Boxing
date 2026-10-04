import '../../../../core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import '../../../../core/resources/app_icons.dart';
import '../../../../core/resources/app_sizes.dart';
import '../../../../core/resources/app_strings.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../domain/review.dart';
import 'star_rating.dart';

/// Overall rating summary: big average number, stars, review count, and a
/// per-star distribution bar chart (5 stars down to 1).
class RatingSummaryHeader extends StatelessWidget {
  const RatingSummaryHeader({super.key, required this.stats});

  final ReviewStats stats;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSizes.s20),
    margin: const EdgeInsets.only(bottom: AppSizes.s20),
    decoration: BoxDecoration(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(AppSizes.radius12),
      border: Border.all(color: context.palette.separator),
    ),
    child: stats.count == 0
        ? Text(
            AppStrings.uiNoReviewsYetBeTheFirstToShare,
            style: TextStyle(color: context.palette.textSecondary),
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    stats.average.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: AppSizes.font40,
                      fontWeight: FontWeight.bold,
                      height: AppSizes.s1,
                    ),
                  ),
                  SizedBox(height: AppSizes.s4),
                  StarRating(rating: stats.average, size: AppSizes.s16),
                  SizedBox(height: AppSizes.s4),
                  Text(
                    '${stats.count} ${stats.count == 1 ? 'review' : 'reviews'}',
                    style: TextStyle(
                      color: context.palette.textSecondary,
                      fontSize: AppSizes.font12,
                    ),
                  ),
                ],
              ),
              SizedBox(width: AppSizes.s24),
              Expanded(
                child: Column(
                  children: [
                    for (var star = 5; star >= 1; star--)
                      _DistributionBar(
                        star: star,
                        count: stats.countFor(star),
                        total: stats.count,
                      ),
                  ],
                ),
              ),
            ],
          ),
  );
}

class _DistributionBar extends StatelessWidget {
  const _DistributionBar({
    required this.star,
    required this.count,
    required this.total,
  });

  final int star;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.s2),
      child: Row(
        children: [
          SizedBox(
            width: AppSizes.s10,
            child: Text(
              '$star',
              style: TextStyle(
                fontSize: AppSizes.font11,
                color: context.palette.textSecondary,
              ),
            ),
          ),
          SizedBox(width: AppSizes.s4),
          AppIcon(
            AppIcons.starFilled,
            size: AppSizes.s10,
            color: context.palette.accent,
          ),
          SizedBox(width: AppSizes.s6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radius4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: AppSizes.progressBarHeight,
                backgroundColor: context.palette.separator,
                valueColor: AlwaysStoppedAnimation(context.palette.accent),
              ),
            ),
          ),
          SizedBox(width: AppSizes.s6),
          SizedBox(
            width: AppSizes.s20,
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: AppSizes.font11,
                color: context.palette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
