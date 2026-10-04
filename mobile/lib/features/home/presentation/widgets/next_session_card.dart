import '../../../../core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import '../../../../core/resources/app_icons.dart';
import '../../../../core/resources/app_sizes.dart';
import '../../../../core/resources/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../booking/domain/booking.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/nav_debounce.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/jbb_card.dart';

class NextSessionCard extends StatelessWidget {
  const NextSessionCard({super.key, required this.booking});
  final Booking booking;
  @override
  Widget build(BuildContext context) => JbbCard(
    selected: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppIcon(AppIcons.calendar, color: context.palette.accent),
            SizedBox(width: AppSizes.s8),
            Text(AppStrings.nextSession),
          ],
        ),
        SizedBox(height: AppSizes.s12),
        Text(
          dateLabel(booking.date),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text('${timeLabel(booking.date)} – ${timeLabel(booking.endAt)}'),
        SizedBox(height: AppSizes.s6),
        Text(AppStrings.juniorBoyBoxingTracyCa),
        SizedBox(height: AppSizes.s16),
        FilledButton(
          onPressed: () => context.safeNavigate(AppRoutes.bookings),
          child: Text(AppStrings.viewBooking),
        ),
      ],
    ),
  );
}
