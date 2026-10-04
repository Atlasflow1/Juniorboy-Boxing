import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../../core/resources/app_sizes.dart';
import '../../../../core/resources/app_strings.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/jbb_button.dart';
import '../../domain/review.dart';
import '../providers/review_provider.dart';
import 'star_rating.dart';

/// Opens the review submission form. Pass [existing] to pre-fill it for
/// editing the user's own review; leave it null to write a new one.
Future<void> showReviewFormSheet(BuildContext context, {Review? existing}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    builder: (context) => ReviewFormSheet(existing: existing),
  );
}

class ReviewFormSheet extends ConsumerStatefulWidget {
  const ReviewFormSheet({super.key, this.existing});
  final Review? existing;
  @override
  ConsumerState<ReviewFormSheet> createState() => _ReviewFormSheetState();
}

class _ReviewFormSheetState extends ConsumerState<ReviewFormSheet> {
  late int rating = widget.existing?.rating ?? 0;
  late final comment = TextEditingController(
    text: widget.existing?.comment ?? '',
  );
  bool busy = false;

  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (rating == 0) {
      showMessage(context, AppStrings.selectAStarRatingFirst);
      return;
    }
    setState(() => busy = true);
    try {
      await ref
          .read(reviewRepositoryProvider)
          .submitReview(rating: rating, comment: comment.text.trim());
      if (mounted) {
        Navigator.of(context).pop();
        showMessage(context, AppStrings.thanksForYourReview);
      }
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: Container(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.s24,
        AppSizes.s20,
        AppSizes.s24,
        AppSizes.s32,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radius20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: AppSizes.reviewAvatarSize,
              height: AppSizes.s4,
              margin: const EdgeInsets.only(bottom: AppSizes.s20),
              decoration: BoxDecoration(
                color: AppColors.white24,
                borderRadius: BorderRadius.circular(AppSizes.radius2),
              ),
            ),
          ),
          Text(
            widget.existing == null
                ? AppStrings.uiWriteAReview
                : AppStrings.uiEditYourReview,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.s16),
          Center(
            child: StarRating(
              rating: rating.toDouble(),
              size: AppSizes.s36,
              onChanged: (value) => setState(() => rating = value),
            ),
          ),
          const SizedBox(height: AppSizes.s20),
          TextField(
            controller: comment,
            maxLines: AppSizes.reviewInputLines,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: AppStrings.shareYourExperienceOptional,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSizes.s12),
          JbbButton(
            label: AppStrings.submitReview,
            busy: busy,
            onPressed: submit,
          ),
        ],
      ),
    ),
  );
}
