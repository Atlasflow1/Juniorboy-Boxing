import '../../../core/utils/non_empty.dart';
import '../domain/home_ad.dart';

class HomeAdModel extends HomeAd {
  const HomeAdModel({required super.id, required super.title, super.description, super.imageUrl, super.price, super.priceLabel, super.timeLabel, super.linkHref, super.isActive, super.sortOrder, super.createdAt});

  factory HomeAdModel.fromMap(Map<String, dynamic> map) => HomeAdModel(
    id: map['id'] as String? ?? '',
    title: map['title'] as String? ?? '',
    description: nonEmpty(map['description'] as String?),
    imageUrl: nonEmpty(map['imageUrl'] as String?),
    price: map['price'] as num?,
    priceLabel: nonEmpty(map['priceLabel'] as String?),
    timeLabel: nonEmpty(map['timeLabel'] as String?),
    linkHref: nonEmpty(map['linkHref'] as String?),
    isActive: map['isActive'] != false,
    sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
    createdAt: map['createdAt'],
  );
}
