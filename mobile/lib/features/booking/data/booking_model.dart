import '../../../core/utils/date_utils.dart';
import '../domain/booking.dart';

class BookingModel extends Booking {
  const BookingModel({
    required super.id,
    required super.userId,
    required super.className,
    required super.date,
    required super.endAt,
    required super.status,
    super.category,
    super.trainingType,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map) => BookingModel(
    id: map['id'] as String? ?? '',
    userId: map['userId'] as String? ?? '',
    className: map['className'] as String? ?? '',
    date: readDate(map['date']),
    endAt: readDate(map['endAt']),
    status: map['status'] as String? ?? '',
    category: map['category'] as String?,
    trainingType: map['trainingType'] as String?,
  );
}
