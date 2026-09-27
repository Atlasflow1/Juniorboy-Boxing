import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/jbb_card.dart';
import '../../../core/widgets/jbb_empty_state.dart';
import '../../../core/widgets/jbb_loading.dart';
import '../providers/admin_provider.dart';
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
      appBar: AppBar(title: const Text('Bookings')),
      body: bookings.when(
        data: (rows) {
          if (rows.isEmpty) {
            return const JbbEmptyState(
              message: 'No bookings yet. They will appear here once a member books a class.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
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
                                booking['className'] ?? 'Class',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              BuyerName(userId: booking['userId']),
                              const SizedBox(height: 4),
                              Text(
                                '${dateLabel(readDate(booking['date']))} · ${timeLabel(readDate(booking['date']))}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          booking['status'] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
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
  final Map<String, dynamic> booking;
  @override
  ConsumerState<_BookingDetailSheet> createState() =>
      _BookingDetailSheetState();
}

class _BookingDetailSheetState extends ConsumerState<_BookingDetailSheet> {
  Map<String, dynamic>? member;
  bool loading = true, busy = false;

  @override
  void initState() {
    super.initState();
    ref
        .read(adminRepositoryProvider)
        .buyer(widget.booking['userId'])
        .then((value) {
      if (mounted) setState(() => member = value);
    }).whenComplete(() {
      if (mounted) setState(() => loading = false);
    });
  }

  Future<void> markAttendance(String status) async {
    setState(() => busy = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .markAttendance(widget.booking['id'], status);
      if (mounted) {
        showMessage(context, status == 'completed' ? 'Marked present.' : 'Marked no-show.');
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
          title: const Text('Cancel this booking?'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Reason'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(
                controller.text.trim().isEmpty
                    ? 'Cancelled by admin'
                    : controller.text.trim(),
              ),
              child: const Text('Cancel Booking'),
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
          .cancelBookingAsAdmin(widget.booking['id'], reason);
      if (mounted) {
        showMessage(context, 'Booking cancelled.');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.booking['status'] as String? ?? '';
    final ended = readDate(widget.booking['endAt']).isBefore(DateTime.now());
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.booking['className'] ?? 'Booking',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              '${dateLabel(readDate(widget.booking['date']))} · ${timeLabel(readDate(widget.booking['date']))}–${timeLabel(readDate(widget.booking['endAt']))} · $status',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (loading)
              const Center(child: JbbLoading())
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${member?['fullName'] ?? ''} ${member?['lastName'] ?? ''}'
                          .trim(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (member?['phone'] as String? ?? '').isNotEmpty
                          ? member!['phone']
                          : 'No phone on file',
                    ),
                    Text(member?['email'] ?? ''),
                    const SizedBox(height: 4),
                    Text(
                      (member?['address'] as String? ?? '').isNotEmpty
                          ? '${member!['address']}${(member?['zipCode'] as String? ?? '').isNotEmpty ? ', ${member!['zipCode']}' : ''}'
                          : 'No address on file',
                    ),
                    if ((member?['childName'] as String? ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Participant: ${member!['childName']}${(member?['childAge'] ?? 0) > 0 ? ' (${member!['childAge']})' : ''}',
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 16),
            if (status == 'confirmed') ...[
              if (ended)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: busy ? null : () => markAttendance('completed'),
                        child: const Text('Present'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: busy ? null : () => markAttendance('no-show'),
                        child: const Text('No-show'),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: busy ? null : cancel,
                child: const Text('Cancel Booking'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
