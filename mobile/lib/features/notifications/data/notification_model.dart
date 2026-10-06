import '../domain/gym_notification.dart';

class NotificationModel extends GymNotification {
  const NotificationModel({
    required super.id,
    required super.title,
    required super.body,
    required super.isRead,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) =>
      NotificationModel(
        id: map['id'] as String? ?? '',
        title: map['title'] as String? ?? '',
        body: map['body'] as String? ?? '',
        isRead: map['isRead'] == true,
      );
}
