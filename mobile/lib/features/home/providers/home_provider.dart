import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../booking/domain/booking.dart';
import '../../booking/domain/booking_eligibility.dart';
import '../../booking/presentation/providers/booking_provider.dart';

final nextBookingProvider = Provider<Booking?>((ref) {
  final items = ref.watch(bookingsProvider).value ?? [];
  final upcoming =
      items.where((b) => isUpcomingBooking(b, DateTime.now())).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
  return upcoming.isEmpty ? null : upcoming.first;
});
