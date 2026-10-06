import '../../../../core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/resources/app_icons.dart';
import '../../../../core/resources/app_sizes.dart';
import '../../../../core/resources/app_strings.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/jbb_card.dart';
import '../../../../core/widgets/jbb_empty_state.dart';
import '../../../../core/widgets/jbb_loading.dart';
import '../../../booking/presentation/providers/booking_provider.dart';
import '../../../booking/domain/booking.dart';
import '../../../booking/domain/booking_eligibility.dart';
import '../../../membership/presentation/providers/membership_provider.dart';
import '../../../payments/presentation/providers/payments_provider.dart';
import '../../../payments/domain/payment.dart';
import '../providers/profile_provider.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});
  @override
  ConsumerState<MyBookingsScreen> createState() => _BookingsState();
}

class _BookingsState extends ConsumerState<MyBookingsScreen> {
  int selected = 0;
  final pending = <String>{};
  Future<bool> cancel(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.cancelThisBooking),
        content: Text(AppStrings.yourReservedSessionCreditWillBeReleased),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.keepBooking),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.cancelBooking),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return false;
    setState(() => pending.add(booking.id));
    try {
      await ref.read(bookingRepositoryProvider).cancel(booking.id);
      if (mounted) showMessage(context, AppStrings.bookingCancelled);
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => pending.remove(booking.id));
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppStrings.myBookings)),
    body: ListView(
      padding: const EdgeInsets.all(AppSizes.s16),
      children: [
        const _MembershipPurchases(),
        SizedBox(height: AppSizes.s24),
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: 0, label: Text(AppStrings.upcoming)),
            ButtonSegment(value: 1, label: Text(AppStrings.past)),
          ],
          selected: {selected},
          onSelectionChanged: (s) => setState(() => selected = s.first),
        ),
        SizedBox(height: AppSizes.s20),
        ref
            .watch(bookingsProvider)
            .when(
              data: (rows) {
                final items = rows.where((b) {
                  final upcoming = isUpcomingBooking(b, DateTime.now());
                  return selected == 0 ? upcoming : !upcoming;
                }).toList();
                if (items.isEmpty) {
                  return JbbEmptyState(message: AppStrings.noBookingsHereYet);
                }
                return Column(
                  children: items.map((b) {
                    final hours =
                        ref
                            .watch(settingsProvider)
                            .value
                            ?.cancellationPolicyHours ??
                        24;
                    final allowed = canCancelBooking(b, DateTime.now(), hours);
                    return Dismissible(
                      key: ValueKey(b.id),
                      direction: allowed
                          ? DismissDirection.endToStart
                          : DismissDirection.none,
                      confirmDismiss: (_) => cancel(b),
                      background: Container(
                        color: context.palette.accent,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.all(AppSizes.s20),
                        child: AppIcon(AppIcons.circleX),
                      ),
                      child: JbbCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.className.isEmpty
                                  ? AppStrings.uiBoxingClass
                                  : b.className,
                              style: TextStyle(
                                fontSize: AppSizes.font18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if ((b.category ?? '').isNotEmpty)
                              Text(
                                b.category!.toUpperCase(),
                                style: TextStyle(
                                  color: context.palette.accent,
                                  fontSize: AppSizes.font11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            SizedBox(height: AppSizes.s8),
                            Text(
                              '${dateLabel(b.date)} · ${timeLabel(b.date)} PT',
                            ),
                            SizedBox(height: AppSizes.s8),
                            Text(
                              b.status.toString().toUpperCase(),
                              style: TextStyle(
                                color: b.status == 'cancelled'
                                    ? context.palette.accent
                                    : context.palette.success,
                                fontSize: AppSizes.font12,
                              ),
                            ),
                            if (allowed)
                              TextButton(
                                onPressed: pending.contains(b.id)
                                    ? null
                                    : () => cancel(b),
                                child: Text(AppStrings.cancelBooking),
                              ),
                            if (!allowed && b.status == 'confirmed')
                              Padding(
                                padding: EdgeInsets.only(top: AppSizes.s8),
                                child: Text(
                                  AppStrings.uiForLateChangesContactTheGym,
                                  style: TextStyle(
                                    color: context.palette.textSecondary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              error: (e, s) => JbbEmptyState(
                message: friendlyError(e),
                onRetry: () => ref.invalidate(bookingsProvider),
              ),
              loading: () => JbbLoading(),
            ),
      ],
    ),
  );
}

class _MembershipPurchases extends ConsumerWidget {
  const _MembershipPurchases();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(profileProvider).value;
    final plans = ref.watch(plansProvider).value ?? const [];
    final purchases =
        (ref.watch(paymentsProvider).value ?? const <Payment>[])
            .where((p) => p.membershipPlanId != null && p.status == 'completed')
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    if (user == null || purchases.isEmpty) return const SizedBox.shrink();
    final used = <String, int>{};
    for (final type in ['private', 'group', 'duo']) {
      final sameType = purchases.where(
        (p) => (p.trainingType ?? 'private') == type,
      );
      final total = sameType.fold<int>(0, (sum, p) => sum + (p.credits ?? 0));
      final remaining = switch (type) {
        'group' => user.groupSessionsRemaining,
        'duo' => user.duoSessionsRemaining,
        _ => user.privateSessionsRemaining,
      };
      var toAllocate = (total - remaining).clamp(0, total);
      for (final p in sameType) {
        final count = p.credits ?? 0;
        used[p.id] = toAllocate.clamp(0, count);
        toAllocate -= used[p.id]!;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.membershipPurchases,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: AppSizes.font18,
          ),
        ),
        SizedBox(height: AppSizes.s12),
        for (final payment in purchases.reversed)
          JbbCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        plans
                                .where((p) => p.id == payment.membershipPlanId)
                                .firstOrNull
                                ?.name ??
                            '${payment.credits ?? 0}-Session Pack',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text('\$${(payment.amount / 100).toStringAsFixed(2)}'),
                  ],
                ),
                Text(
                  '${payment.credits ?? 0} sessions · ${payment.trainingType ?? 'private'}',
                ),
                Text(
                  '${used[payment.id] ?? 0} of ${payment.credits ?? 0} used',
                  style: TextStyle(color: context.palette.textSecondary),
                ),
                Text(
                  dateLabel(payment.createdAt),
                  style: TextStyle(color: context.palette.textSecondary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
