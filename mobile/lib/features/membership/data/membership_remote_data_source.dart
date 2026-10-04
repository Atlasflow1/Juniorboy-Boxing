import '../../../core/data/cached_repository.dart';

class MembershipRemoteDataSource extends CachedRepository {
  Stream<List<Map<String, dynamic>>> plans() => watchQuery(
    db.collection('membershipPlans').where('isActive', isEqualTo: true),
    'plans',
  );
}
