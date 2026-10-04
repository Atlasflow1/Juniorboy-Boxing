class Review {
  const Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final int rating;
  final String comment;
  final DateTime createdAt;
}

class ReviewStats {
  ReviewStats({
    required this.count,
    required this.average,
    required Map<String, int> distribution,
  }) : distribution = Map.unmodifiable(distribution);

  final int count;
  final double average;
  final Map<String, int> distribution;

  static final empty = ReviewStats(count: 0, average: 0, distribution: {});

  int countFor(int star) => distribution['$star'] ?? 0;
}
