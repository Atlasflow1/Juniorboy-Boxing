import '../domain/program.dart';
import '../../../core/utils/non_empty.dart';

class ProgramModel extends Program {
  const ProgramModel({
    required super.id,
    required super.className,
    required super.ageGroup,
    required super.address,
    super.description,
    super.coachName,
    super.category,
    super.trainingType,
    super.price,
    super.priceLabel,
    super.discountPercent,
    super.discountActive,
    super.durationMinutes,
    super.imageUrl,
    super.adImages,
    super.maxSpots,
    super.isActive,
    super.createdAt,
  });

  factory ProgramModel.fromMap(Map<String, dynamic> map) => ProgramModel(
    id: map['id'] as String? ?? '',
    className: nonEmpty(map['className'] as String?),
    ageGroup: nonEmpty(map['ageGroup'] as String?),
    address: nonEmpty(map['address'] as String?),
    description: nonEmpty(map['description'] as String?),
    coachName: nonEmpty(map['coachName'] as String?),
    category: nonEmpty(map['category'] as String?),
    trainingType: nonEmpty(map['trainingType'] as String?),
    price: map['price'] as num?,
    priceLabel: nonEmpty(map['priceLabel'] as String?),
    discountPercent: map['discountPercent'] as num? ?? 0,
    discountActive: map['discountActive'] == true,
    durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 60,
    imageUrl: nonEmpty(map['imageUrl'] as String?),
    adImages:
        (map['adImages'] as List?)
            ?.whereType<String>()
            .where((s) => s.trim().isNotEmpty)
            .toList() ??
        const [],
    maxSpots: (map['maxSpots'] as num?)?.toInt() ?? 12,
    isActive: map['isActive'] != false,
    createdAt: map['createdAt'],
  );
}
