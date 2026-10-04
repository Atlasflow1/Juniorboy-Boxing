import 'program.dart';
import 'session.dart';

abstract class ScheduleRepository {
  Stream<List<Session>> watch(DateTime from, DateTime to);
  Stream<List<Program>> classes();
  Stream<Session> detail(String id);
  Future<DateTime?> nextSessionDate();
}
