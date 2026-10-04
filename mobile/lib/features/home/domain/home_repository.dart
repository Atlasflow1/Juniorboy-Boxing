import '../../booking/domain/booking.dart';
import 'home_ad.dart';

abstract class HomeRepository {
  Booking? nextBooking(List<Booking> bookings, DateTime now);
  Stream<List<HomeAd>> ads();
}
