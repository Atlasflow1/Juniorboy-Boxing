import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/resources/app_sizes.dart';
import '../../../../core/resources/app_strings.dart';
import '../providers/session_provider.dart';
import 'session_card.dart';

/// Lists every admin-created session as a card — the Home-page surface for
/// the unified Sessions system (replaces the old Programs/Class Schedule
/// Times split). Hidden entirely when there are no sessions yet, same as
/// [HomeAdsSection].
class SessionsSection extends ConsumerWidget {
  const SessionsSection({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider).value ?? const [];
    if (sessions.isEmpty) return const SizedBox.shrink();
    final sorted = [...sessions]
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.s4),
          child: Text(
            AppStrings.uiSessions,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: AppSizes.s12),
        for (final session in sorted) ...[
          SessionCard(session: session),
          const SizedBox(height: AppSizes.s12),
        ],
      ],
    );
  }
}
