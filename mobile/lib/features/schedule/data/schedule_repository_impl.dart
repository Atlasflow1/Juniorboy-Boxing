import '../domain/program.dart';
import '../domain/schedule_repository.dart';
import '../domain/session.dart';
import 'program_model.dart';
import 'schedule_remote_data_source.dart';
import 'session_model.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  ScheduleRepositoryImpl(this.source);
  final ScheduleRemoteDataSource source;

  @override
  Stream<List<Session>> watch(DateTime from, DateTime to) => source
      .watch(from, to)
      .map((rows) => rows.map<Session>(SessionModel.fromMap).toList());

  @override
  Stream<List<Program>> classes() => source.classes().map(
    (rows) => rows.map<Program>(ProgramModel.fromMap).toList(),
  );

  @override
  Stream<Session> detail(String id) =>
      source.detail(id).map(SessionModel.fromMap);

  @override
  Future<DateTime?> nextSessionDate() => source.nextSessionDate();
}
