import '../../booking/domain/booking.dart';
import '../../booking/domain/booking_eligibility.dart';
import '../domain/home_repository.dart';
import '../domain/home_ad.dart';
import 'home_ad_model.dart';
import 'home_remote_data_source.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl([HomeRemoteDataSource? source])
    : source = source ?? HomeRemoteDataSource();
  final HomeRemoteDataSource source;

  @override
  Stream<List<HomeAd>> ads() => source.ads().map((rows) {
    final ads = rows.map<HomeAd>(HomeAdModel.fromMap).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return ads;
  });
  @override
  Booking? nextBooking(List<Booking> bookings, DateTime now) {
    final upcoming =
        bookings.where((booking) => isUpcomingBooking(booking, now)).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    return upcoming.isEmpty ? null : upcoming.first;
  }
}
