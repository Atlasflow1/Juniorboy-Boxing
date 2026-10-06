import 'review.dart';

abstract class ReviewRepository {
  Stream<List<Review>> reviews();
  Stream<ReviewStats> stats();
  Future<void> submitReview({required int rating, required String comment});
  Future<void> deleteReview();
}
