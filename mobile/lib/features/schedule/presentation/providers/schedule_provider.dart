import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../data/schedule_remote_data_source.dart';
import '../../data/schedule_repository_impl.dart';
import '../../domain/schedule_repository.dart';
import '../../domain/session.dart';
import '../../domain/program.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>(
  (ref) => ScheduleRepositoryImpl(ScheduleRemoteDataSource()),
);
final classesProvider = StreamProvider((ref) {
  if (ref.watch(authProvider).value == null) {
    return const Stream<List<Program>>.empty();
  }
  return ref.watch(scheduleRepositoryProvider).classes();
});
final scheduleProvider = StreamProvider.family<List<Session>, String>((
  ref,
  day,
) {
  if (ref.watch(authProvider).value == null) return Stream.value([]);
  final d = DateTime.parse(day),
      location = tz.getLocation('America/Los_Angeles');
  final from = tz.TZDateTime(location, d.year, d.month, d.day),
      to = tz.TZDateTime(location, d.year, d.month, d.day + 1);
  return ref.watch(scheduleRepositoryProvider).watch(from, to);
});
final sessionProvider = StreamProvider.family<Session, String>(
  (ref, id) => ref.watch(scheduleRepositoryProvider).detail(id),
);
