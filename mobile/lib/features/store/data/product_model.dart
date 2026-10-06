import '../domain/product.dart';
import '../../../core/utils/non_empty.dart';

class ProductModel extends Product {
  ProductModel({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    required super.priceLabel,
    required super.imageUrl,
    required super.imageUrls,
    required super.sizes,
    required super.isActive,
    required super.isFeatured,
    required super.category,
    required super.discountActive,
    required super.discountPercent,
    required super.sortOrder,
    required super.createdAt,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) => ProductModel(
    id: map['id'] as String? ?? '',
    name: nonEmpty(map['name'] as String?),
    description: nonEmpty(map['description'] as String?),
    price: map['price'] as num?,
    priceLabel: nonEmpty(map['priceLabel'] as String?),
    imageUrl: nonEmpty(map['imageUrl'] as String?),
    imageUrls: map['imageUrls'] != null
        ? List<String>.from(map['imageUrls'])
        : (map['imageUrl'] as String? ?? '').isNotEmpty
        ? [map['imageUrl'] as String]
        : const [],
    sizes: List<String>.from(map['sizes'] ?? const []),
    isActive: map['isActive'] as bool?,
    isFeatured: map['isFeatured'] == true,
    category: nonEmpty(map['category'] as String?),
    discountActive: map['discountActive'] == true,
    discountPercent: map['discountPercent'] as num? ?? 0,
    sortOrder: map['sortOrder'] as num? ?? 0,
    createdAt: map['createdAt'],
  );
}
