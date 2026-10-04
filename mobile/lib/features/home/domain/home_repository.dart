import '../../booking/domain/booking.dart';

abstract class HomeRepository {
  Booking? nextBooking(List<Booking> bookings, DateTime now);
}
