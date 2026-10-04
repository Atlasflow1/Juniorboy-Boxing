import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/resources/app_sizes.dart';
import '../providers/admin_provider.dart';

/// Resolves a Firestore user id to a display name, for admin lists that
/// only carry a `userId` (payments, orders) and need it shown inline.
class BuyerName extends ConsumerWidget {
  const BuyerName({super.key, required this.userId});
  final String userId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => FutureBuilder(
    future: ref.read(adminRepositoryProvider).buyer(userId),
    builder: (context, snapshot) {
      final buyer = snapshot.data;
      final name = buyer == null
          ? null
          : '${buyer.fullName ?? ''} ${buyer.lastName ?? ''}'.trim();
      return Text(
        (name ?? '').isNotEmpty ? name! : 'Loading…',
        style: const TextStyle(fontSize: AppSizes.font13),
      );
    },
  );
}
