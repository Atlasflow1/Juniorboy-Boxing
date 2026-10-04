import 'package:flutter/material.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/widgets/app_icon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/jbb_button.dart';
import '../../../core/widgets/jbb_card.dart';
import '../../../core/widgets/jbb_empty_state.dart';
import '../../../core/widgets/jbb_loading.dart';
import '../providers/admin_provider.dart';
import '../widgets/buyer_name.dart';

/// Dedicated admin view of store orders (product purchases only), separate
/// from membership payments. Lets the admin see who bought what and reach
/// their contact/address so it can be shipped or handed over at the gym.
class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(adminOrdersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Store Orders')),
      body: orders.when(
        data: (rows) {
          final products = rows.where((p) => p['productId'] != null).toList();
          if (products.isEmpty) {
            return const JbbEmptyState(
              message:
                  'No store orders yet. They will appear here once a customer buys something.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: products
                .map(
                  (order) => JbbCard(
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => _OrderDetailSheet(order: order),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order['size'] != null
                                    ? '${order['productName'] ?? 'Product'} · Size ${order['size']}'
                                    : order['productName'] ?? 'Product',
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
                              if (order['estimatedDeliveryDate'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    'Delivery: ${dateLabel(readDate(order['estimatedDeliveryDate']))}',
                                    style: const TextStyle(
                                      color: AppColors.red,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
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

class _OrderDetailSheet extends ConsumerStatefulWidget {
  const _OrderDetailSheet({required this.order});
  final Map<String, dynamic> order;
  @override
  ConsumerState<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends ConsumerState<_OrderDetailSheet> {
  Map<String, dynamic>? buyer;
  bool loading = true, busy = false;
  DateTime? deliveryDate;
  final note = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.order['deliveryNote'] != null) {
      note.text = widget.order['deliveryNote'];
    }
    if (widget.order['estimatedDeliveryDate'] != null) {
      deliveryDate = readDate(widget.order['estimatedDeliveryDate']);
    }
    ref
        .read(adminRepositoryProvider)
        .buyer(widget.order['userId'])
        .then((value) {
          if (mounted) setState(() => buyer = value);
        })
        .whenComplete(() {
          if (mounted) setState(() => loading = false);
        });
  }

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (deliveryDate == null) {
      showMessage(context, 'Pick an expected delivery/pickup date.');
      return;
    }
    setState(() => busy = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .setOrderDelivery(
            widget.order['id'],
            deliveryDate!,
            note.text.trim(),
          );
      if (mounted) {
        showMessage(context, 'Delivery date saved.');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this order?'),
        content: const Text(
          'This removes the order record only. It does not refund the '
          'customer or reverse fulfillment — use Refund first if the '
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
    setState(() => busy = true);
    try {
      await ref.read(adminRepositoryProvider).deletePayment(widget.order['id']);
      if (mounted) {
        showMessage(context, 'Order deleted.');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
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
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.order['size'] != null
                      ? '${widget.order['productName'] ?? 'Order'} · Size ${widget.order['size']}'
                      : widget.order['productName'] ?? 'Order',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              IconButton(
                onPressed: busy ? null : delete,
                icon: const AppIcon(AppIcons.trash),
              ),
            ],
          ),
          Text(
            '\$${(widget.order['amount'] / 100).toStringAsFixed(2)} · ${widget.order['status']}',
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
                    '${buyer?['fullName'] ?? ''} ${buyer?['lastName'] ?? ''}'
                        .trim(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (buyer?['phone'] as String? ?? '').isNotEmpty
                        ? buyer!['phone']
                        : 'No phone on file',
                  ),
                  Text(buyer?['email'] ?? ''),
                  const SizedBox(height: 4),
                  Text(
                    (buyer?['address'] as String? ?? '').isNotEmpty
                        ? '${buyer!['address']}${(buyer?['zipCode'] as String? ?? '').isNotEmpty ? ', ${buyer!['zipCode']}' : ''}'
                        : 'No address on file',
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              deliveryDate == null
                  ? 'Set expected delivery / pickup date'
                  : 'Expected ${dateLabel(deliveryDate!)}',
            ),
            trailing: const AppIcon(AppIcons.calendar),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: deliveryDate ?? DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => deliveryDate = picked);
            },
          ),
          TextField(
            controller: note,
            decoration: const InputDecoration(
              labelText: 'Note for the buyer (optional)',
              hintText: 'e.g. Ships via USPS, or ready for pickup',
            ),
          ),
          const SizedBox(height: 16),
          JbbButton(
            label: 'Save Delivery Date',
            busy: busy,
            onPressed: widget.order['status'] == 'completed' ? save : null,
          ),
        ],
      ),
    ),
  );
}
