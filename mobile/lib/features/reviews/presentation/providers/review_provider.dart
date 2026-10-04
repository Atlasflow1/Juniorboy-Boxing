import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/review.dart';
import '../../data/review_repository_impl.dart';
import '../../data/review_remote_data_source.dart';
import '../../domain/review_repository.dart';
import '../../../auth/providers/auth_provider.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>(
  (ref) => ReviewRepositoryImpl(ReviewRemoteDataSource()),
);

final reviewsProvider = StreamProvider<List<Review>>(
  (ref) => ref.watch(reviewRepositoryProvider).reviews(),
);

final reviewStatsProvider = StreamProvider<ReviewStats>(
  (ref) => ref.watch(reviewRepositoryProvider).stats(),
);

/// The signed-in user's own review, derived from [reviewsProvider]. Null
/// while loading, unauthenticated, or if the user hasn't reviewed yet.
final myReviewProvider = Provider<Review?>((ref) {
  final uid = ref.watch(authProvider).value?.uid;
  final reviews = ref.watch(reviewsProvider).value;
  if (uid == null || reviews == null) return null;
  for (final review in reviews) {
    if (review.userId == uid) return review;
  }
  return null;
});
