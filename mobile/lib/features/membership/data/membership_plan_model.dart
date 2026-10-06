import '../domain/membership_plan.dart';
import '../../../core/utils/non_empty.dart';

class MembershipPlanModel extends MembershipPlan {
  const MembershipPlanModel({
    required super.id,
    required super.description,
    required super.price,
    required super.isActive,
    required super.planType,
    required super.createdAt,
    required super.name,
    required super.priceLabel,
    required super.perSessionLabel,
    required super.sortOrder,
    required super.isRecommended,
    required super.sessionCount,
    required super.category,
    super.trainingType,
    super.imageUrl,
    super.discountActive,
    super.discountPercent,
  });

  factory MembershipPlanModel.fromMap(Map<String, dynamic> map) =>
      MembershipPlanModel(
        id: map['id'] as String? ?? '',
        description: nonEmpty(map['description'] as String?),
        price: map['price'] as num?,
        isActive: map['isActive'] as bool?,
        planType: nonEmpty(map['planType'] as String?),
        createdAt: map['createdAt'],
        name: map['name'] as String? ?? '',
        priceLabel: map['priceLabel'] as String? ?? '',
        perSessionLabel: map['perSessionLabel'] as String? ?? '',
        sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
        isRecommended: map['isRecommended'] == true,
        sessionCount: (map['sessionCount'] as num?)?.toInt(),
        category: nonEmpty(map['category'] as String?),
        trainingType: nonEmpty(map['trainingType'] as String?),
        imageUrl: nonEmpty(map['imageUrl'] as String?),
        discountActive: map['discountActive'] == true,
        discountPercent: map['discountPercent'] as num? ?? 0,
      );
}
