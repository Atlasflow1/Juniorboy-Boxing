import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_remote_data_source.dart';
import '../../data/admin_repository_impl.dart';
import '../../domain/admin_repository.dart';
import '../../domain/recurring_template.dart';
import '../../../booking/domain/booking.dart';
import '../../../membership/domain/membership_plan.dart';
import '../../../payments/domain/payment.dart';
import '../../../schedule/domain/program.dart';
import '../../../home/domain/home_ad.dart';

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepositoryImpl(AdminRemoteDataSource()),
);
final adminPlansProvider = StreamProvider<List<MembershipPlan>>(
  (ref) => ref.watch(adminRepositoryProvider).plans(),
);
final adminTemplatesProvider = StreamProvider<List<RecurringTemplate>>(
  (ref) => ref.watch(adminRepositoryProvider).templates(),
);
final adminProgramsProvider = StreamProvider<List<Program>>(
  (ref) => ref.watch(adminRepositoryProvider).programs(),
);
final adminAdsProvider = StreamProvider<List<HomeAd>>(
  (ref) => ref.watch(adminRepositoryProvider).ads(),
);
final adminOrdersProvider = StreamProvider<List<Payment>>(
  (ref) => ref.watch(adminRepositoryProvider).orders(),
);
final adminBookingsProvider = StreamProvider<List<Booking>>(
  (ref) => ref.watch(adminRepositoryProvider).bookings(),
);
