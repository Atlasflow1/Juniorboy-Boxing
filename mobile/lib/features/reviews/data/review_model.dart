import '../../../core/utils/date_utils.dart';
import '../../../core/utils/non_empty.dart';
import '../domain/review.dart';

class ReviewModel extends Review {
  const ReviewModel({
    required super.id,
    required super.userId,
    required super.userName,
    required super.userAvatarUrl,
    required super.rating,
    required super.comment,
    required super.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map) => ReviewModel(
    id: map['id'] as String? ?? '',
    userId: map['userId'] as String? ?? '',
    userName: nonEmpty(map['userName'] as String?) ?? 'Member',
    userAvatarUrl: map['userAvatarUrl'] as String? ?? '',
    rating: (map['rating'] as num?)?.toInt() ?? 0,
    comment: map['comment'] as String? ?? '',
    createdAt: readDate(map['createdAt']),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'userName': userName,
    'userAvatarUrl': userAvatarUrl,
    'rating': rating,
    'comment': comment,
    'createdAt': createdAt.toIso8601String(),
  };
}

class ReviewStatsModel extends ReviewStats {
  ReviewStatsModel({
    required super.count,
    required super.average,
    required super.distribution,
  });

  factory ReviewStatsModel.fromMap(Map<String, dynamic> map) =>
      ReviewStatsModel(
        count: (map['count'] as num?)?.toInt() ?? 0,
        average: (map['average'] as num?)?.toDouble() ?? 0,
        distribution:
            (map['distribution'] as Map?)?.map(
              (key, value) => MapEntry(key.toString(), (value as num).toInt()),
            ) ??
            const {},
      );
}
