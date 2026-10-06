import '../domain/booking.dart';
import '../domain/booking_repository.dart';
import 'booking_model.dart';
import 'booking_remote_data_source.dart';

class BookingRepositoryImpl implements BookingRepository {
  BookingRepositoryImpl(this.source);

  final BookingRemoteDataSource source;

  @override
  Stream<List<Booking>> watch() => source.watch().map(
    (rows) => rows.map<Booking>(BookingModel.fromMap).toList(),
  );

  @override
  Future<String> create(String scheduleId) => source.create(scheduleId);

  @override
  Future<void> cancel(String bookingId) => source.cancel(bookingId);
}
