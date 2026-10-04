import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/nav_debounce.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/jbb_button.dart';
import '../../../core/widgets/jbb_card.dart';
import '../../../core/widgets/jbb_loading.dart';
import '../../../core/widgets/jbb_empty_state.dart';
import '../../schedule/providers/schedule_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/screens/waiver_screen.dart';
import '../providers/booking_provider.dart';

class BookClassScreen extends ConsumerStatefulWidget {
  const BookClassScreen({super.key, required this.scheduleId});
  final String scheduleId;
  @override
  ConsumerState<BookClassScreen> createState() => _BookClassState();
}

class _BookClassState extends ConsumerState<BookClassScreen> {
  bool busy = false;
  Future<void> confirm() async {
    final user = ref.read(profileProvider).value;
    final waiver = ref.read(waiverProvider).value?.data();
    if (waiver?['published'] == true &&
        waiver?['requiredOnBooking'] == true &&
        (user?['waiverVersion'] != waiver?['version'] ||
            user?['waiverParticipantName'] != user?['childName']?.trim() ||
            user?['waiverParticipantAge'] != user?['childAge'])) {
      context.safePush('/waiver');
      return;
    }
    final session = ref.read(sessionProvider(widget.scheduleId)).value;
    final program = ref
        .read(classesProvider)
        .value
        ?.firstWhere(
          (c) => c['id'] == session?['classId'],
          orElse: () => <String, dynamic>{},
        );
    final trainingType = (program?['trainingType'] as String?) ?? 'private';
    final remaining = (user?['${trainingType}SessionsRemaining'] ?? 0) as num;
    final reserved = (user?['${trainingType}SessionsReserved'] ?? 0) as num;
    if (remaining - reserved < 1) {
      context.go('/membership');
      return;
    }
    setState(() => busy = true);
    try {
      await ref.read(bookingRepositoryProvider).create(widget.scheduleId);
      if (mounted) context.go('/booking-confirmed');
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(waiverProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Book Class')),
      body: ref
          .watch(sessionProvider(widget.scheduleId))
          .when(
            data: (session) {
              final programs = ref.watch(classesProvider).value ?? [],
                  program = programs.firstWhere(
                    (c) => c['id'] == session['classId'],
                    orElse: () => <String, dynamic>{},
                  );
              final spots = session['maxSpots'] - session['bookedSpots'];
              final trainingType = (program['trainingType'] as String?) ?? 'private';
              final trainingTypeLabel = trainingType == 'private'
                  ? 'Private'
                  : trainingType == 'group'
                  ? 'Group'
                  : 'Duo';
              final user = ref.watch(profileProvider).value;
              final remaining =
                  ((user?['${trainingType}SessionsRemaining'] ?? 0) as num) -
                  ((user?['${trainingType}SessionsReserved'] ?? 0) as num);
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Hero(
                      tag: 'class-${widget.scheduleId}',
                      child: Image.asset(
                        'assets/images/photos/photo_kid_boxing.jpg',
                        height: 210,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  JbbCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((program['category'] ?? '').toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              program['category'].toString().toUpperCase(),
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        Text(
                          program['className'] ?? 'Boxing class',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(program['ageGroup'] ?? ''),
                        const SizedBox(height: 22),
                        for (final item in [
                          ('DATE', dateLabel(readDate(session['date']))),
                          (
                            'TIME',
                            '${timeLabel(readDate(session['date']))} – ${timeLabel(readDate(session['endAt']))} PT',
                          ),
                          ('TRAINING TYPE', trainingTypeLabel),
                          (
                            'AVAILABILITY',
                            '$spots of ${session['maxSpots']} spots',
                          ),
                          (
                            '$trainingTypeLabel SESSIONS REMAINING',
                            '$remaining remaining',
                          ),
                          if ((program['priceLabel'] ?? '').toString().isNotEmpty)
                            ('PRICE', program['priceLabel'].toString()),
                        ])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.$1,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 11,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(item.$2),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  JbbButton(
                    label: remaining < 1
                        ? 'Purchase a $trainingTypeLabel Package'
                        : 'Confirm Booking  ›',
                    busy: busy,
                    onPressed:
                        spots > 0 &&
                            session['isCancelled'] != true &&
                            readDate(session['date']).isAfter(DateTime.now())
                        ? confirm
                        : null,
                  ),
                ],
              );
            },
            error: (e, s) => JbbEmptyState(
              message: friendlyError(e),
              onRetry: () => ref.invalidate(sessionProvider(widget.scheduleId)),
            ),
            loading: () => const JbbLoading(),
          ),
    );
  }
}
