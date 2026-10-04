import 'package:flutter/material.dart';
import '../../../core/resources/app_colors.dart';
import '../../../core/resources/app_icons.dart';
import '../../../core/resources/app_sizes.dart';
import '../../../core/resources/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/nav_debounce.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/jbb_card.dart';

class NextSessionCard extends StatelessWidget {
  const NextSessionCard({super.key, required this.booking});
  final Map<String, dynamic> booking;
  @override
  Widget build(BuildContext context) => JbbCard(
    selected: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            AppIcon(AppIcons.calendar, color: AppColors.materialRed),
            SizedBox(width: AppSizes.s8),
            Text(AppStrings.nextSession),
          ],
        ),
        const SizedBox(height: AppSizes.s12),
        Text(
          dateLabel(readDate(booking['date'])),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text(
          '${timeLabel(readDate(booking['date']))} – ${timeLabel(readDate(booking['endAt']))}',
        ),
        const SizedBox(height: AppSizes.s6),
        const Text(AppStrings.juniorBoyBoxingTracyCa),
        const SizedBox(height: AppSizes.s16),
        FilledButton(
          onPressed: () => context.safeNavigate(AppRoutes.bookings),
          child: const Text(AppStrings.viewBooking),
        ),
      ],
    ),
  );
}
