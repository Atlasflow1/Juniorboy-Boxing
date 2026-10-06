import '../../../core/services/stripe_service.dart';
import '../domain/membership_plan.dart';
import '../domain/membership_repository.dart';
import 'membership_plan_model.dart';
import 'membership_remote_data_source.dart';

class MembershipRepositoryImpl implements MembershipRepository {
  MembershipRepositoryImpl(this.source, this.stripe);
  final MembershipRemoteDataSource source;
  final StripeService stripe;

  @override
  Stream<List<MembershipPlan>> plans() => source.plans().map(
    (rows) => rows.map<MembershipPlan>(MembershipPlanModel.fromMap).toList(),
  );

  @override
  Future<String> purchase(String planId) => stripe.purchase(planId);
}
