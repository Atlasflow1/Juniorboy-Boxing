import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository_impl.dart';
import '../../data/auth_remote_data_source.dart';
import '../../domain/auth_repository.dart';
import '../../domain/auth_account.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(AuthRemoteDataSource()),
);
final authProvider = StreamProvider<AuthAccount?>(
  (ref) => ref.watch(authRepositoryProvider).userChanges(),
);
