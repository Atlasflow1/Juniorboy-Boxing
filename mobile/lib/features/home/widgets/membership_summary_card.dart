import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    onTap: () => context.push('/membership'),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.workspace_premium, color: Colors.red),
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
        const Icon(Icons.chevron_right, color: Colors.grey),
      ],
    ),
  );
}
