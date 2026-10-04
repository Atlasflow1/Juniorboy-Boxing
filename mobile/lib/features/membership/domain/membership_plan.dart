class MembershipPlan {
  const MembershipPlan({
    required this.id,
    required this.name,
    required this.priceLabel,
    required this.perSessionLabel,
    required this.sortOrder,
    required this.isRecommended,
    required this.sessionCount,
  });

  final String id;
  final String name;
  final String priceLabel;
  final String perSessionLabel;
  final int sortOrder;
  final bool isRecommended;
  final int? sessionCount;
}
