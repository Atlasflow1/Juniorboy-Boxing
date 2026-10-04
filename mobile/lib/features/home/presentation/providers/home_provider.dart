import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../booking/domain/booking.dart';
import '../../../booking/presentation/providers/booking_provider.dart';
import '../../data/home_repository_impl.dart';
import '../../domain/home_repository.dart';

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepositoryImpl(),
);
final nextBookingProvider = Provider<Booking?>((ref) {
  final items = ref.watch(bookingsProvider).value ?? [];
  return ref.watch(homeRepositoryProvider).nextBooking(items, DateTime.now());
});
