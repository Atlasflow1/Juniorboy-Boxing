import '../domain/review.dart';
import '../domain/review_repository.dart';
import 'review_model.dart';
import 'review_remote_data_source.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  ReviewRepositoryImpl(this.source);

  final ReviewRemoteDataSource source;

  @override
  Stream<List<Review>> reviews() => source.reviews().map(
    (rows) => rows.map<Review>(ReviewModel.fromMap).toList(),
  );

  @override
  Stream<ReviewStats> stats() => source.stats().map(ReviewStatsModel.fromMap);

  @override
  Future<void> submitReview({required int rating, required String comment}) =>
      source.submitReview(rating: rating, comment: comment);

  @override
  Future<void> deleteReview() => source.deleteReview();
}
