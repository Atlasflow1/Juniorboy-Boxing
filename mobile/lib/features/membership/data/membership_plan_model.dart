import '../domain/membership_plan.dart';

class MembershipPlanModel extends MembershipPlan {
  const MembershipPlanModel({
    required super.id,
    required super.name,
    required super.priceLabel,
    required super.perSessionLabel,
    required super.sortOrder,
    required super.isRecommended,
    required super.sessionCount,
  });

  factory MembershipPlanModel.fromMap(Map<String, dynamic> map) =>
      MembershipPlanModel(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        priceLabel: map['priceLabel'] as String? ?? '',
        perSessionLabel: map['perSessionLabel'] as String? ?? '',
        sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
        isRecommended: map['isRecommended'] == true,
        sessionCount: (map['sessionCount'] as num?)?.toInt(),
      );
}
