import '../domain/gym_notification.dart';
import '../domain/notification_repository.dart';
import 'notification_model.dart';
import 'notification_remote_data_source.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this.source);
  final NotificationRemoteDataSource source;

  @override
  Stream<List<GymNotification>> watch() => source.watch().map(
    (rows) => rows.map<GymNotification>(NotificationModel.fromMap).toList(),
  );

  @override
  Future<void> markRead(String id) => source.markRead(id);
}
