import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/jbb_card.dart';
import '../../../core/widgets/jbb_loading.dart';
import '../../../core/widgets/jbb_empty_state.dart';
import '../../membership/providers/membership_provider.dart';
import '../providers/profile_provider.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(profileProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('My Account')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user != null)
            JbbCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Membership',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text('${user['sessionsRemaining'] ?? 0} sessions remaining'),
                  Text(
                    '${user['sessionsReserved'] ?? 0} reserved for upcoming classes',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          const Text(
            'Payment History',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ref
              .watch(paymentsProvider)
              .when(
                data: (rows) => rows.isEmpty
                    ? const JbbEmptyState(message: 'No payments yet.')
                    : Column(
                        children: rows
                            .map(
                              (p) => JbbCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        p['productName'] != null
                                            ? p['size'] != null
                                                  ? '${p['productName']} · Size ${p['size']} (Store)'
                                                  : '${p['productName']} (Store)'
                                            : 'Membership',
                                      ),
                                      subtitle: Text(
                                        '${dateLabel(readDate(p['createdAt']))} · ${timeLabel(readDate(p['createdAt']))} · \$${(p['amount'] / 100).toStringAsFixed(2)} · ${p['paymentMethod']}',
                                      ),
                                      trailing: Text(p['status']),
                                    ),
                                    if (p['productName'] != null &&
                                        p['estimatedDeliveryDate'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 16,
                                          right: 16,
                                          bottom: 12,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Expected ${dateLabel(readDate(p['estimatedDeliveryDate']))}',
                                              style: const TextStyle(
                                                color: Colors.red,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                            if ((p['deliveryNote'] ?? '')
                                                .isNotEmpty)
                                              Text(
                                                p['deliveryNote'],
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                error: (e, s) => JbbEmptyState(
                  message: friendlyError(e),
                  onRetry: () => ref.invalidate(paymentsProvider),
                ),
                loading: () => const JbbLoading(),
              ),
        ],
      ),
    );
  }
}
