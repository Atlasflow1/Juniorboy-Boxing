import 'package:flutter/material.dart';
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
class AdminSubscriptionsScreen extends ConsumerWidget {
  const AdminSubscriptionsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            return const JbbEmptyState(
              message: 'No membership purchases yet.',
            );
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
