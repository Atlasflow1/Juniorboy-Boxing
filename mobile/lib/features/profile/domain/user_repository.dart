import 'dart:io';

import 'gym_settings.dart';
import 'member.dart';

abstract class UserRepository {
  Stream<Member> watch();
  Stream<GymSettings> settings();
  Future<Member?> fetchProfile();
  Future<void> save(Map<String, dynamic> values);
  Future<void> changeEmail(String email);
  Future<void> uploadAvatar(File file);
}
