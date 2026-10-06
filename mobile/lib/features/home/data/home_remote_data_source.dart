import '../../../core/data/cached_repository.dart';

class HomeRemoteDataSource extends CachedRepository {
  Stream<List<Map<String, dynamic>>> ads() => watchQuery(
    db.collection('homeAds').where('isActive', isEqualTo: true),
    'home_ads',
  );
}
