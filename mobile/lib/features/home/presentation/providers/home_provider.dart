import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../booking/domain/booking.dart';
import '../../../booking/presentation/providers/booking_provider.dart';
import '../../data/home_repository_impl.dart';
import '../../data/home_remote_data_source.dart';
import '../../domain/home_repository.dart';
import '../../domain/home_ad.dart';

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepositoryImpl(HomeRemoteDataSource()),
);
final homeAdsProvider = StreamProvider<List<HomeAd>>(
  (ref) => ref.watch(homeRepositoryProvider).ads(),
);
final nextBookingProvider = Provider<Booking?>((ref) {
  final items = ref.watch(bookingsProvider).value ?? [];
  return ref.watch(homeRepositoryProvider).nextBooking(items, DateTime.now());
});
