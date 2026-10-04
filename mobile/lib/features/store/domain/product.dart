class Product {
  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.priceLabel,
    required this.imageUrl,
    required List<String> imageUrls,
    required List<String> sizes,
    required this.isActive,
    required this.isFeatured,
    required this.category,
    required this.discountActive,
    required this.discountPercent,
    required this.sortOrder,
    required this.createdAt,
  }) : imageUrls = List.unmodifiable(imageUrls),
       sizes = List.unmodifiable(sizes);

  final String id;
  final String? name, description, priceLabel, imageUrl, category;
  final List<String> imageUrls, sizes;
  final num? price;
  final num discountPercent, sortOrder;
  final bool? isActive;
  final bool isFeatured, discountActive;
  final Object? createdAt;
}
