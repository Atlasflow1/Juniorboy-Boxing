import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/payments_remote_data_source.dart';
import '../../data/payments_repository_impl.dart';
import '../../domain/payment.dart';
import '../../domain/payments_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final paymentsRepositoryProvider = Provider<PaymentsRepository>(
  (ref) => PaymentsRepositoryImpl(PaymentsRemoteDataSource()),
);
final paymentsProvider = StreamProvider<List<Payment>>((ref) {
  if (ref.watch(authProvider).value == null) {
    return const Stream<List<Payment>>.empty();
  }
  return ref.watch(paymentsRepositoryProvider).watch();
});
