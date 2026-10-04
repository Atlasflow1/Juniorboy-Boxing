import 'booking.dart';

abstract class BookingRepository {
  Stream<List<Booking>> watch();
  Future<String> create(String scheduleId);
  Future<void> cancel(String bookingId);
}
