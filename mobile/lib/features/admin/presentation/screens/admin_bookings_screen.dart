import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../../core/resources/app_sizes.dart';
import '../../../../core/resources/app_strings.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/jbb_card.dart';
import '../../../../core/widgets/jbb_empty_state.dart';
import '../../../../core/widgets/jbb_loading.dart';
import '../providers/admin_provider.dart';
import '../../../booking/domain/booking.dart';
import '../../../profile/domain/member.dart';
import '../widgets/buyer_name.dart';

/// Dedicated admin view of class bookings, so the admin can see who
/// confirmed a session — with their full contact details — mark
/// attendance, or cancel on the member's behalf.
class AdminBookingsScreen extends ConsumerWidget {
  const AdminBookingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(adminBookingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.bookings)),
      body: bookings.when(
        data: (rows) {
          if (rows.isEmpty) {
            return const JbbEmptyState(
              message: AppStrings.noBookingsYetTheyWillAppearHere,
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSizes.s16),
            children: rows
                .map(
                  (booking) => JbbCard(
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => _BookingDetailSheet(booking: booking),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.className.isEmpty
                                    ? AppStrings.uiClass
                                    : booking.className,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: AppSizes.font16,
                                ),
                              ),
                              const SizedBox(height: AppSizes.s4),
                              BuyerName(userId: booking.userId),
                              const SizedBox(height: AppSizes.s4),
                              Text(
                                '${dateLabel(readDate(booking.date))} · ${timeLabel(readDate(booking.date))}',
                                style: const TextStyle(
                                  color: AppColors.grey,
                                  fontSize: AppSizes.font12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          booking.status,
                          style: const TextStyle(
                            fontSize: AppSizes.font12,
                            color: AppColors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          );
        },
        error: (e, s) => JbbEmptyState(
          message: friendlyError(e),
          onRetry: () => ref.invalidate(adminBookingsProvider),
        ),
        loading: () => const JbbLoading(),
      ),
    );
  }
}

class _BookingDetailSheet extends ConsumerStatefulWidget {
  const _BookingDetailSheet({required this.booking});
  final Booking booking;
  @override
  ConsumerState<_BookingDetailSheet> createState() =>
      _BookingDetailSheetState();
}

class _BookingDetailSheetState extends ConsumerState<_BookingDetailSheet> {
  Member? member;
  bool loading = true, busy = false;

  @override
  void initState() {
    super.initState();
    ref
        .read(adminRepositoryProvider)
        .buyer(widget.booking.userId)
        .then((value) {
          if (mounted) setState(() => member = value);
        })
        .whenComplete(() {
          if (mounted) setState(() => loading = false);
        });
  }

  Future<void> markAttendance(String status) async {
    setState(() => busy = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .markAttendance(widget.booking.id, status);
      if (mounted) {
        showMessage(
          context,
          status == 'completed'
              ? AppStrings.uiMarkedPresent
              : AppStrings.uiMarkedNoShow,
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> cancel() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text(AppStrings.cancelThisBooking),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: AppStrings.reason),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AppStrings.back),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(
                controller.text.trim().isEmpty
                    ? AppStrings.uiCancelledByAdmin
                    : controller.text.trim(),
              ),
              child: const Text(AppStrings.cancelBooking2),
            ),
          ],
        );
      },
    );
    if (reason == null) return;
    setState(() => busy = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .cancelBookingAsAdmin(widget.booking.id, reason);
      if (mounted) {
        showMessage(context, AppStrings.bookingCancelled);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.booking.status as String? ?? '';
    final ended = widget.booking.endAt.isBefore(DateTime.now());
    return Padding(
      padding: EdgeInsets.only(
        left: AppSizes.s20,
        right: AppSizes.s20,
        top: AppSizes.s20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.booking.className.isEmpty
                  ? AppStrings.uiBooking
                  : widget.booking.className,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: AppSizes.font18,
              ),
            ),
            Text(
              '${dateLabel(widget.booking.date)} · ${timeLabel(widget.booking.date)}–${timeLabel(widget.booking.endAt)} · $status',
              style: const TextStyle(color: AppColors.grey),
            ),
            const SizedBox(height: AppSizes.s16),
            if (loading)
              const Center(child: JbbLoading())
            else
              Container(
                padding: const EdgeInsets.all(AppSizes.s12),
                decoration: BoxDecoration(
                  color: AppColors.white10,
                  borderRadius: BorderRadius.circular(AppSizes.radius10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${member?.fullName ?? ''} ${member?.lastName ?? ''}'
                          .trim(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSizes.s4),
                    Text(
                      (member?.phone ?? '').isNotEmpty
                          ? member!.phone!
                          : AppStrings.uiNoPhoneOnFile,
                    ),
                    Text(member?.email ?? ''),
                    const SizedBox(height: AppSizes.s4),
                    Text(
                      (member?.address ?? '').isNotEmpty
                          ? '${member!.address}${(member?.zipCode ?? '').isNotEmpty ? ', ${member!.zipCode}' : ''}'
                          : AppStrings.uiNoAddressOnFile,
                    ),
                    if ((member?.childName ?? '').isNotEmpty) ...[
                      const SizedBox(height: AppSizes.s4),
                      Text(
                        'Participant: ${member!.childName}${(member?.childAge ?? 0) > 0 ? ' (${member!.childAge})' : ''}',
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: AppSizes.s16),
            if (status == 'confirmed') ...[
              if (ended)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: busy
                            ? null
                            : () => markAttendance('completed'),
                        child: const Text(AppStrings.present),
                      ),
                    ),
                    const SizedBox(width: AppSizes.s12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: busy
                            ? null
                            : () => markAttendance('no-show'),
                        child: const Text(AppStrings.noShow),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: AppSizes.s12),
              TextButton(
                onPressed: busy ? null : cancel,
                child: const Text(AppStrings.cancelBooking2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
