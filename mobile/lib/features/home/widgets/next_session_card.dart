import 'package:flutter/material.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/nav_debounce.dart';
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
            AppIcon(AppIcons.calendar, color: Colors.red),
            SizedBox(width: 8),
            Text('Next Session'),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          dateLabel(readDate(booking['date'])),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text(
          '${timeLabel(readDate(booking['date']))} – ${timeLabel(readDate(booking['endAt']))}',
        ),
        const SizedBox(height: 6),
        const Text('Junior Boy Boxing · Tracy, CA'),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => context.safePush('/bookings'),
          child: const Text('View Booking  ›'),
        ),
      ],
    ),
  );
}
