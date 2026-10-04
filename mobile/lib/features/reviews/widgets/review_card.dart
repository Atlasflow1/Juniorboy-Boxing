import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/resources/app_colors.dart';
import '../../../core/resources/app_icons.dart';
import '../../../core/resources/app_sizes.dart';
import '../../../core/resources/app_strings.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../data/models/review_model.dart';
import 'star_rating.dart';

/// Displays a single review: avatar, name, star rating, date and comment.
/// Pass [onDelete] to show a delete action (only the review's own author
/// should be able to delete it — the caller decides when to pass this).
class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review, this.onDelete});

  final ReviewModel review;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: AppSizes.s12),
    padding: const EdgeInsets.all(AppSizes.s16),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppSizes.radius12),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: AppSizes.avatarRadiusMedium,
              backgroundColor: AppColors.border,
              backgroundImage: review.userAvatarUrl.isNotEmpty
                  ? CachedNetworkImageProvider(review.userAvatarUrl)
                  : null,
              child: review.userAvatarUrl.isEmpty
                  ? const AppIcon(
                      AppIcons.user,
                      color: AppColors.muted,
                      size: AppSizes.s20,
                    )
                  : null,
            ),
            const SizedBox(width: AppSizes.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppSizes.font15,
                    ),
                  ),
                  const SizedBox(height: AppSizes.s2),
                  Row(
                    children: [
                      StarRating(
                        rating: review.rating.toDouble(),
                        size: AppSizes.s14,
                      ),
                      const SizedBox(width: AppSizes.s8),
                      Text(
                        dateLabel(review.createdAt),
                        style: const TextStyle(
                          color: AppColors.muted,
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
                icon: const AppIcon(
                  AppIcons.trash,
                  size: AppSizes.s20,
                  color: AppColors.muted,
                ),
                tooltip: AppStrings.deleteYourReview,
                onPressed: onDelete,
              ),
          ],
        ),
        if (review.comment.isNotEmpty) ...[
          const SizedBox(height: AppSizes.s12),
          Text(
            review.comment,
            style: const TextStyle(height: AppSizes.lineHeightBody),
          ),
        ],
      ],
    ),
  );
}
