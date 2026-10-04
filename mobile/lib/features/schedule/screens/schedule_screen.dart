import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/page_content.dart';
import '../../../core/widgets/jbb_loading.dart';
import '../../../core/widgets/jbb_empty_state.dart';
import '../../../core/utils/nav_debounce.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/schedule_provider.dart';
import '../widgets/month_navigator.dart';
import '../widgets/day_selector.dart';
import '../widgets/class_list_card.dart';

/// The 3 session types a member can own credits for; classes without a
/// trainingType yet (older data) are treated as 'private'.
const _trainingTypes = ['private', 'group', 'duo'];

Set<String> _ownedTrainingTypes(Map<String, dynamic>? user) {
  if (user == null) return const {};
  return {
    for (final type in _trainingTypes)
      if (((user['${type}SessionsRemaining'] as num?) ?? 0) -
              ((user['${type}SessionsReserved'] as num?) ?? 0) >
          0)
        type,
  };
}

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key, this.programId});
  final String? programId;
  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleState();
}

class _ScheduleState extends ConsumerState<ScheduleScreen> {
  DateTime day = gymTime(DateTime.now());
  @override
  void initState() {
    super.initState();
    // Land on the nearest day that actually has a class instead of an
    // empty "today" when the gym's schedule doesn't run every day.
    ref.read(scheduleRepositoryProvider).nextSessionDate().then((next) {
      if (mounted && next != null) setState(() => day = gymTime(next));
    });
  }

  @override
  Widget build(BuildContext context) {
    final key = DateFormat('yyyy-MM-dd').format(day),
        programs = ref.watch(classesProvider).value ?? [];
    final sessions = ref.watch(scheduleProvider(key));
    final ownedTypes = _ownedTrainingTypes(ref.watch(profileProvider).value);
    return PageContent(
      title: 'Class Schedule',
      children: [
        MonthNavigator(date: day, onChange: (v) => setState(() => day = v)),
        DaySelector(date: day, onChange: (v) => setState(() => day = v)),
        const SizedBox(height: 24),
        Text(
          '${DateFormat('EEEE, MMM d').format(day)} · Pacific time',
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 14),
        sessions.when(
          data: (allRows) {
            final rows = allRows.where((s) {
              if (widget.programId != null && s['classId'] != widget.programId) {
                return false;
              }
              final program = programs.firstWhere(
                (c) => c['id'] == s['classId'],
                orElse: () => <String, dynamic>{},
              );
              final trainingType = (program['trainingType'] as String?) ?? 'private';
              return ownedTypes.contains(trainingType);
            }).toList();
            if (ownedTypes.isEmpty) {
              return JbbEmptyState(
                message:
                    "You don't have any session credits yet — choose a plan to see bookable classes.",
                onRetry: () => context.safePush('/membership'),
                actionLabel: 'Choose a Plan',
              );
            }
            return rows.isEmpty
                ? const JbbEmptyState(
                    message:
                        'No classes scheduled for this selection. Contact the gym for availability.',
                  )
                : Column(
                    children: rows
                        .map(
                          (s) => JbbClassCard(
                            session: s,
                            program: programs.firstWhere(
                              (c) => c['id'] == s['classId'],
                              orElse: () => <String, dynamic>{},
                            ),
                          ),
                        )
                        .toList(),
                  );
          },
          error: (e, stack) => JbbEmptyState(
            message: friendlyError(e),
            onRetry: () => ref.invalidate(scheduleProvider(key)),
          ),
          loading: () => const JbbLoading(),
        ),
      ],
    );
  }
}
