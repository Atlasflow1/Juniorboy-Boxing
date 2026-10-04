import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/resources/app_colors.dart';
import '../../../core/resources/app_sizes.dart';
import '../../../core/resources/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/nav_debounce.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/jbb_button.dart';
import '../../../core/widgets/jbb_card.dart';
import '../../../core/widgets/jbb_empty_state.dart';
import '../../../core/widgets/jbb_loading.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/screens/waiver_screen.dart';
import '../../schedule/providers/schedule_provider.dart';
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
      context.safeNavigate(AppRoutes.waiver);
      return;
    }
    if ((user?['sessionsRemaining'] ?? 0) - (user?['sessionsReserved'] ?? 0) <
        1) {
      context.safeNavigate(AppRoutes.membership);
      return;
    }
    setState(() => busy = true);
    try {
      await ref.read(bookingRepositoryProvider).create(widget.scheduleId);
      if (mounted) context.go(AppRoutes.bookingConfirmed);
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
      appBar: AppBar(title: const Text(AppStrings.bookClass)),
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
              return ListView(
                padding: const EdgeInsets.all(AppSizes.s16),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radius12),
                    child: Hero(
                      tag: 'class-${widget.scheduleId}',
                      child: Image.asset(
                        'assets/images/photos/photo_kid_boxing.jpg',
                        height: AppSizes.bookingProgramImageHeight,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.s20),
                  JbbCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          program['className'] ?? AppStrings.uiBoxingClass,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(program['ageGroup'] ?? ''),
                        const SizedBox(height: AppSizes.s22),
                        for (final item in [
                          (
                            AppStrings.uiDate,
                            dateLabel(readDate(session['date'])),
                          ),
                          (
                            AppStrings.uiTime,
                            '${timeLabel(readDate(session['date']))} – ${timeLabel(readDate(session['endAt']))} PT',
                          ),
                          (
                            AppStrings.uiLocation2,
                            program['address'] ?? '3200 Naglee Rd, Tracy, CA',
                          ),
                          (AppStrings.uiAvailability, '$spots spots'),
                        ])
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSizes.s18,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.$1,
                                  style: const TextStyle(
                                    color: AppColors.materialRed,
                                    fontSize: AppSizes.font11,
                                    letterSpacing: AppSizes.labelTracking,
                                  ),
                                ),
                                const SizedBox(height: AppSizes.s5),
                                Text(item.$2),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  JbbButton(
                    label: AppStrings.confirmBooking,
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
