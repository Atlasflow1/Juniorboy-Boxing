class Program {
  const Program({
    required this.id,
    required this.className,
    required this.ageGroup,
    required this.address,
    this.description,
    this.coachName,
    this.category,
    this.trainingType,
    this.price,
    this.priceLabel,
    this.discountPercent = 0,
    this.discountActive = false,
    this.durationMinutes = 60,
    this.imageUrl,
    this.adImages = const [],
    this.maxSpots = 12,
    this.isActive = true,
    this.createdAt,
  });

  final String id;
  final String? className;
  final String? ageGroup;
  final String? address;
  final String? description,
      coachName,
      category,
      trainingType,
      priceLabel,
      imageUrl;
  final num? price;
  final num discountPercent;
  final bool discountActive, isActive;
  final int durationMinutes, maxSpots;
  final List<String> adImages;
  final Object? createdAt;

  static const empty = Program(
    id: '',
    className: null,
    ageGroup: null,
    address: null,
  );
}
