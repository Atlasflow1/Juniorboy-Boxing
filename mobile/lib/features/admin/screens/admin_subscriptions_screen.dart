import 'package:flutter/material.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/widgets/app_icon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/jbb_card.dart';
import '../../../core/widgets/jbb_empty_state.dart';
import '../../../core/widgets/jbb_loading.dart';
import '../providers/admin_provider.dart';
import '../widgets/buyer_name.dart';

/// Dedicated admin view of membership purchases, separate from store
/// orders. Credits are added automatically on payment, so this is a
/// record/reporting view rather than something the admin has to act on.
class AdminSubscriptionsScreen extends ConsumerStatefulWidget {
  const AdminSubscriptionsScreen({super.key});
  @override
  ConsumerState<AdminSubscriptionsScreen> createState() =>
      _AdminSubscriptionsScreenState();
}

class _AdminSubscriptionsScreenState
    extends ConsumerState<AdminSubscriptionsScreen> {
  String? busyId;

  Future<void> delete(Map<String, dynamic> order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this subscription record?'),
        content: const Text(
          'This removes the payment record only. It does not remove '
          'session credits already added — use Refund first if the '
          'purchase itself needs to be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => busyId = order['id']);
    try {
      await ref.read(adminRepositoryProvider).deletePayment(order['id']);
      if (mounted) showMessage(context, 'Record deleted.');
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(adminOrdersProvider);
    final plans = ref.watch(adminPlansProvider).value ?? const [];
    final planNames = {
      for (final p in plans) p['id'] as String: p['name'] as String? ?? 'Plan',
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Membership Subscriptions')),
      body: orders.when(
        data: (rows) {
          final subs = rows
              .where((p) => p['membershipPlanId'] != null)
              .toList();
          if (subs.isEmpty) {
            return const JbbEmptyState(message: 'No membership purchases yet.');
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: subs
                .map(
                  (order) => JbbCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                planNames[order['membershipPlanId']] ??
                                    'Membership',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              BuyerName(userId: order['userId']),
                              const SizedBox(height: 4),
                              Text(
                                '${dateLabel(readDate(order['createdAt']))} · ${timeLabel(readDate(order['createdAt']))}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${(order['amount'] / 100).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (order['credits'] != null)
                              Text(
                                '${order['credits']} credits',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            Text(
                              order['status'] ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: busyId != null
                              ? null
                              : () => delete(order),
                          icon: busyId == order['id']
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const AppIcon(
                                  AppIcons.trash,
                                  color: Colors.grey,
                                  size: 20,
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
          onRetry: () => ref.invalidate(adminOrdersProvider),
        ),
        loading: () => const JbbLoading(),
      ),
    );
  }
}
