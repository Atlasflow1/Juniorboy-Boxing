import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/stripe_service.dart';
import '../../data/session_remote_data_source.dart';
import '../../data/session_repository_impl.dart';
import '../../domain/session_repository.dart';
import '../../models/session_model.dart';

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepositoryImpl(SessionRemoteDataSource(), StripeService()),
);

final sessionsProvider = StreamProvider<List<SessionModel>>(
  (ref) => ref.watch(sessionRepositoryProvider).watch(),
);
