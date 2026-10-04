class MembershipPlan {
  const MembershipPlan({
    required this.id,
    required this.description,
    required this.price,
    required this.isActive,
    required this.planType,
    required this.createdAt,
    required this.name,
    required this.priceLabel,
    required this.perSessionLabel,
    required this.sortOrder,
    required this.isRecommended,
    required this.sessionCount,
    required this.category,
  });

  final String id;
  final String? description, planType;
  final num? price;
  final bool? isActive;
  final Object? createdAt;
  final String name;
  final String priceLabel;
  final String perSessionLabel;
  final int sortOrder;
  final bool isRecommended;
  final int? sessionCount;
  final String? category;
}
