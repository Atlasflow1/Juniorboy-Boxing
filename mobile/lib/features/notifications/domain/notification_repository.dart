import 'gym_notification.dart';

abstract class NotificationRepository {
  Stream<List<GymNotification>> watch();
  Future<void> markRead(String id);
}
