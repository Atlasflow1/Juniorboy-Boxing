import '../../../../core/theme/app_palette.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/resources/app_icons.dart';
import '../../../../core/resources/app_sizes.dart';
import '../../../../core/resources/app_strings.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../domain/review.dart';
import 'star_rating.dart';

/// Displays a single review: avatar, name, star rating, date and comment.
/// Pass [onDelete] to show a delete action (only the review's own author
/// should be able to delete it — the caller decides when to pass this).
class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review, this.onDelete});

  final Review review;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: AppSizes.s12),
    padding: const EdgeInsets.all(AppSizes.s16),
    decoration: BoxDecoration(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(AppSizes.radius12),
      border: Border.all(color: context.palette.separator),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: AppSizes.avatarRadiusMedium,
              backgroundColor: context.palette.separator,
              backgroundImage: review.userAvatarUrl.isNotEmpty
                  ? CachedNetworkImageProvider(review.userAvatarUrl)
                  : null,
              child: review.userAvatarUrl.isEmpty
                  ? AppIcon(
                      AppIcons.user,
                      color: context.palette.textSecondary,
                      size: AppSizes.s20,
                    )
                  : null,
            ),
            SizedBox(width: AppSizes.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.userName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppSizes.font15,
                    ),
                  ),
                  SizedBox(height: AppSizes.s2),
                  Row(
                    children: [
                      StarRating(
                        rating: review.rating.toDouble(),
                        size: AppSizes.s14,
                      ),
                      SizedBox(width: AppSizes.s8),
                      Text(
                        dateLabel(review.createdAt),
                        style: TextStyle(
                          color: context.palette.textSecondary,
                          fontSize: AppSizes.font12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: AppIcon(
                  AppIcons.trash,
                  size: AppSizes.s20,
                  color: context.palette.textSecondary,
                ),
                tooltip: AppStrings.deleteYourReview,
                onPressed: onDelete,
              ),
          ],
        ),
        if (review.comment.isNotEmpty) ...[
          SizedBox(height: AppSizes.s12),
          Text(
            review.comment,
            style: TextStyle(height: AppSizes.lineHeightBody),
          ),
        ],
      ],
    ),
  );
}
