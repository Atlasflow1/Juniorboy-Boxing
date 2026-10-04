import 'membership_plan.dart';

abstract class MembershipRepository {
  Stream<List<MembershipPlan>> plans();
  Future<String> purchase(String planId);
}
