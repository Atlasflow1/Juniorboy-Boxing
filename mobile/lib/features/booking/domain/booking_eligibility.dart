import 'booking.dart';

bool isUpcomingBooking(Booking booking, DateTime now) =>
    booking.status == 'confirmed' && booking.date.isAfter(now);

bool canCancelBooking(Booking booking, DateTime now, num policyHours) =>
    booking.status == 'confirmed' &&
    booking.date.difference(now).inSeconds >= policyHours * 3600;
