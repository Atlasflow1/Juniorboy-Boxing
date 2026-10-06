import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/non_empty.dart';

class UserModel {
  const UserModel({
    required this.uid,
    required this.fullName,
    required this.dateOfBirth,
    this.profilePicUrl,
    required this.role,
    required this.createdAt,
  });

  final String uid;
  final String fullName;
  final DateTime dateOfBirth;
  final String? profilePicUrl;
  final String role; // 'admin' | 'trainee'
  final DateTime createdAt;

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    uid: map['uid'] as String? ?? '',
    fullName: nonEmpty(map['fullName'] as String?) ?? '',
    dateOfBirth: readDate(map['dateOfBirth']),
    profilePicUrl: nonEmpty(map['profilePicUrl'] as String?),
    role: map['role'] as String? ?? 'trainee',
    createdAt: readDate(map['createdAt']),
  );

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'fullName': fullName,
    'dateOfBirth': Timestamp.fromDate(dateOfBirth),
    'profilePicUrl': profilePicUrl,
    'role': role,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
