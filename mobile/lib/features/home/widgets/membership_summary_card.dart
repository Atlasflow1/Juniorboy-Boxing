import '../../../core/router/app_routes.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/utils/nav_debounce.dart';
import '../../../core/widgets/jbb_card.dart';

/// Confirms the member's active subscription right on Home — plan name
/// and session balance — so a purchase feels immediately reflected,
/// without having to open the Membership tab to check.
class MembershipSummaryCard extends StatelessWidget {
  const MembershipSummaryCard({
    super.key,
    required this.planName,
    required this.sessionsRemaining,
    required this.sessionsReserved,
  });
  final String? planName;
  final int sessionsRemaining;
  final int sessionsReserved;
  @override
  Widget build(BuildContext context) => JbbCard(
    onTap: () => context.safePush(AppRoutes.membership),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppIcon(AppIcons.crown, color: Colors.red),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                planName ?? 'Your Membership',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text('$sessionsRemaining sessions remaining'),
              if (sessionsReserved > 0)
                Text(
                  '$sessionsReserved reserved for upcoming classes',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
            ],
          ),
        ),
        const AppIcon(AppIcons.chevronRight, color: Colors.grey),
      ],
    ),
  );
}
