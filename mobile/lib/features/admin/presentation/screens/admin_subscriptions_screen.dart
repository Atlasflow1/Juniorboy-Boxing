import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../../core/resources/app_icons.dart';
import '../../../../core/resources/app_sizes.dart';
import '../../../../core/resources/app_strings.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/jbb_card.dart';
import '../../../../core/widgets/jbb_empty_state.dart';
import '../../../../core/widgets/jbb_loading.dart';
import '../providers/admin_provider.dart';
import '../../../payments/domain/payment.dart';
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

  Future<void> delete(Payment order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteThisSubscriptionRecord),
        content: const Text(
          'This removes the payment record only. It does not remove '
          'session credits already added — use Refund first if the '
          'purchase itself needs to be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => busyId = order.id);
    try {
      await ref.read(adminRepositoryProvider).deletePayment(order.id);
      if (mounted) showMessage(context, AppStrings.recordDeleted);
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
      for (final p in plans) p.id: p.name.isNotEmpty ? p.name : 'Plan',
    };
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.membershipSubscriptions)),
      body: orders.when(
        data: (rows) {
          final subs = rows.where((p) => p.membershipPlanId != null).toList();
          if (subs.isEmpty) {
            return const JbbEmptyState(
              message: AppStrings.noMembershipPurchasesYet,
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSizes.s16),
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
                                planNames[order.membershipPlanId] ??
                                    AppStrings.navMembership,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: AppSizes.font16,
                                ),
                              ),
                              const SizedBox(height: AppSizes.s4),
                              BuyerName(userId: order.userId),
                              const SizedBox(height: AppSizes.s4),
                              Text(
                                '${dateLabel(readDate(order.createdAt))} · ${timeLabel(readDate(order.createdAt))}',
                                style: const TextStyle(
                                  color: AppColors.grey,
                                  fontSize: AppSizes.font12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${(order.amount / 100).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSizes.s4),
                            if (order.credits != null)
                              Text(
                                '${order.credits} credits',
                                style: const TextStyle(
                                  fontSize: AppSizes.font12,
                                  color: AppColors.grey,
                                ),
                              ),
                            Text(
                              order.status,
                              style: const TextStyle(
                                fontSize: AppSizes.font12,
                                color: AppColors.grey,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: busyId != null
                              ? null
                              : () => delete(order),
                          icon: busyId == order.id
                              ? const SizedBox(
                                  width: AppSizes.s18,
                                  height: AppSizes.s18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: AppSizes.s2,
                                  ),
                                )
                              : const AppIcon(
                                  AppIcons.trash,
                                  color: AppColors.grey,
                                  size: AppSizes.s20,
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
