import '../../../../core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/resources/app_sizes.dart';
import '../../../../core/resources/app_strings.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/jbb_card.dart';
import '../../../../core/widgets/jbb_empty_state.dart';
import '../../../../core/widgets/jbb_loading.dart';
import '../providers/payments_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(profileProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.myAccount)),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.s16),
        children: [
          if (user != null)
            JbbCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.navMembership,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppSizes.font16,
                    ),
                  ),
                  SizedBox(height: AppSizes.s8),
                  Text(AppStrings.sessionsRemaining(user.sessionsRemaining)),
                  Text(
                    '${user.sessionsReserved} reserved for upcoming classes',
                    style: TextStyle(
                      color: context.palette.textSecondary,
                      fontSize: AppSizes.font13,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: AppSizes.s20),
          Text(
            AppStrings.uiPaymentHistory,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppSizes.font16,
            ),
          ),
          SizedBox(height: AppSizes.s8),
          ref
              .watch(paymentsProvider)
              .when(
                data: (rows) => rows.isEmpty
                    ? JbbEmptyState(message: AppStrings.noPaymentsYet)
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
                                        p.productName != null
                                            ? p.size != null
                                                  ? '${p.productName} · Size ${p.size} (Store)'
                                                  : '${p.productName} (Store)'
                                            : AppStrings.navMembership,
                                      ),
                                      subtitle: Text(
                                        '${dateLabel(p.createdAt)} · ${timeLabel(p.createdAt)} · \$${(p.amount / 100).toStringAsFixed(2)} · ${p.paymentMethod}',
                                      ),
                                      trailing: Text(p.status),
                                    ),
                                    if (p.productName != null &&
                                        p.estimatedDeliveryDate != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: AppSizes.s16,
                                          right: AppSizes.s16,
                                          bottom: AppSizes.s12,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Expected ${dateLabel(p.estimatedDeliveryDate!)}',
                                              style: TextStyle(
                                                color: context.palette.accent,
                                                fontWeight: FontWeight.w600,
                                                fontSize: AppSizes.font13,
                                              ),
                                            ),
                                            if ((p.deliveryNote ?? '')
                                                .isNotEmpty)
                                              Text(
                                                p.deliveryNote!,
                                                style: TextStyle(
                                                  color: context
                                                      .palette
                                                      .textSecondary,
                                                  fontSize: AppSizes.font12,
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
                loading: () => JbbLoading(),
              ),
        ],
      ),
    );
  }
}
