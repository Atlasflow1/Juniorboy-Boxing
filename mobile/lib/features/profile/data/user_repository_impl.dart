import 'dart:io';

import '../domain/gym_settings.dart';
import '../domain/member.dart';
import '../domain/user_repository.dart';
import 'gym_settings_model.dart';
import 'member_model.dart';
import 'user_remote_data_source.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this.source);
  final UserRemoteDataSource source;

  @override
  Stream<Member> watch() => source.watch().map(MemberModel.fromMap);

  @override
  Stream<GymSettings> settings() =>
      source.settings().map(GymSettingsModel.fromMap);

  @override
  Future<Member?> fetchProfile() => source.fetchProfile();

  @override
  Future<void> save(Map<String, dynamic> values) => source.save(values);

  @override
  Future<void> changeEmail(String email) => source.changeEmail(email);

  @override
  Future<void> uploadAvatar(File file) => source.uploadAvatar(file);
}
