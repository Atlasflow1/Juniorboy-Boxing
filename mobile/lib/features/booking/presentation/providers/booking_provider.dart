import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/booking.dart';
import '../../domain/booking_repository.dart';
import '../../data/booking_repository_impl.dart';
import '../../data/booking_remote_data_source.dart';
import '../../../auth/providers/auth_provider.dart';

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => BookingRepositoryImpl(BookingRemoteDataSource()),
);
final bookingsProvider = StreamProvider<List<Booking>>((ref) {
  if (ref.watch(authProvider).value == null) {
    return const Stream<List<Booking>>.empty();
  }
  return ref.watch(bookingRepositoryProvider).watch();
});
