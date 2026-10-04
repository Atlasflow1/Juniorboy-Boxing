import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/resources/app_colors.dart';
import '../../../core/resources/app_sizes.dart';
import '../../../core/resources/app_strings.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/jbb_card.dart';
import '../../../core/widgets/jbb_empty_state.dart';
import '../../../core/widgets/jbb_loading.dart';
import '../../../data/repositories/notification_repository.dart';
import '../providers/profile_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text(AppStrings.notifications)),
    body: ListView(
      padding: const EdgeInsets.all(AppSizes.s16),
      children: [
        ref
            .watch(notificationsProvider)
            .when(
              data: (items) => items.isEmpty
                  ? const JbbEmptyState(message: AppStrings.youReAllCaughtUp)
                  : Column(
                      children: items
                          .map(
                            (n) => JbbCard(
                              selected: n['isRead'] != true,
                              onTap: () async {
                                try {
                                  await NotificationRepository().markRead(
                                    n['id'],
                                  );
                                } catch (e) {
                                  if (context.mounted) {
                                    showMessage(context, friendlyError(e));
                                  }
                                }
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n['title'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: AppSizes.s8),
                                  Text(n['body']),
                                  if (n['isRead'] != true)
                                    const Padding(
                                      padding: EdgeInsets.only(
                                        top: AppSizes.s10,
                                      ),
                                      child: Text(
                                        AppStrings.uiTapToMarkAsRead,
                                        style: TextStyle(
                                          color: AppColors.materialRed,
                                          fontSize: AppSizes.font12,
                                        ),
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
                onRetry: () => ref.invalidate(notificationsProvider),
              ),
              loading: () => const JbbLoading(),
            ),
      ],
    ),
  );
}
