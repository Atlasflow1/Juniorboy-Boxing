import '../../../core/data/cached_repository.dart';

class PaymentsRemoteDataSource extends CachedRepository {
  Stream<List<Map<String, dynamic>>> watch() => watchQuery(
    db
        .collection('payments')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(100),
    'payments',
  );
}
