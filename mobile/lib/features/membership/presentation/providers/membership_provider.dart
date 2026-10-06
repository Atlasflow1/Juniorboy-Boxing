import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/membership_remote_data_source.dart';
import '../../data/membership_repository_impl.dart';
import '../../domain/membership_repository.dart';
import '../../domain/membership_plan.dart';
import '../../../../core/services/stripe_service.dart';

final membershipRepositoryProvider = Provider<MembershipRepository>(
  (ref) =>
      MembershipRepositoryImpl(MembershipRemoteDataSource(), StripeService()),
);
final plansProvider = StreamProvider<List<MembershipPlan>>(
  (ref) => ref.watch(membershipRepositoryProvider).plans(),
);
