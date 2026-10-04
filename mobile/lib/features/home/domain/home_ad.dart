class HomeAd {
  const HomeAd({required this.id, required this.title, this.description, this.imageUrl, this.price, this.priceLabel, this.timeLabel, this.linkHref, this.isActive = true, this.sortOrder = 0, this.createdAt});
  final String id, title;
  final String? description, imageUrl, priceLabel, timeLabel, linkHref;
  final num? price;
  final bool isActive;
  final int sortOrder;
  final Object? createdAt;
}
