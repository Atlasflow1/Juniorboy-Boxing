import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/notification_remote_data_source.dart';
import '../../data/notification_repository_impl.dart';
import '../../domain/gym_notification.dart';
import '../../domain/notification_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepositoryImpl(NotificationRemoteDataSource()),
);
final notificationsProvider = StreamProvider<List<GymNotification>>((ref) {
  if (ref.watch(authProvider).value == null) {
    return const Stream<List<GymNotification>>.empty();
  }
  return ref.watch(notificationRepositoryProvider).watch();
});
