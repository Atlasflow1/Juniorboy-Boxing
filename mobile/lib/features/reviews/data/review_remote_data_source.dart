import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/data/cached_repository.dart';

class ReviewRemoteDataSource extends CachedRepository {
  Stream<List<Map<String, dynamic>>> reviews() => watchQuery(
    db.collection('reviews').orderBy('createdAt', descending: true).limit(50),
    'reviews',
  );

  Stream<Map<String, dynamic>> stats() => db
      .doc('reviewStats/summary')
      .snapshots()
      .map(
        (snapshot) =>
            normalize(snapshot.data()) as Map<String, dynamic>? ?? const {},
      );

  Future<void> submitReview({required int rating, required String comment}) =>
      FirebaseFunctions.instance.httpsCallable('submitReview').call({
        'rating': rating,
        'comment': comment,
      });

  Future<void> deleteReview() =>
      FirebaseFunctions.instance.httpsCallable('deleteReview').call();
}
