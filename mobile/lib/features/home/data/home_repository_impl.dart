import '../../booking/domain/booking.dart';
import '../../booking/domain/booking_eligibility.dart';
import '../domain/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  @override
  Booking? nextBooking(List<Booking> bookings, DateTime now) {
    final upcoming =
        bookings.where((booking) => isUpcomingBooking(booking, now)).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    return upcoming.isEmpty ? null : upcoming.first;
  }
}
