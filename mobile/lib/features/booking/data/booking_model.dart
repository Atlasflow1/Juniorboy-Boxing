import '../../../core/utils/date_utils.dart';
import '../domain/booking.dart';

class BookingModel extends Booking {
  const BookingModel({
    required super.id,
    required super.className,
    required super.date,
    required super.endAt,
    required super.status,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map) => BookingModel(
    id: map['id'] as String? ?? '',
    className: map['className'] as String? ?? '',
    date: readDate(map['date']),
    endAt: readDate(map['endAt']),
    status: map['status'] as String? ?? '',
  );
}
