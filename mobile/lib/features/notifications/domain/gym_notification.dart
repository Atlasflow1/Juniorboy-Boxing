class GymNotification {
  const GymNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
  });
  final String id;
  final String title;
  final String body;
  final bool isRead;
}
