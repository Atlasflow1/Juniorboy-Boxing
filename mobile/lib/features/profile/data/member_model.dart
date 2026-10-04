import '../domain/member.dart';

class MemberModel extends Member {
  const MemberModel({
    required super.id,
    required super.fullName,
    required super.sessionsRemaining,
    required super.sessionsReserved,
    required super.childName,
    required super.childAge,
    required super.waiverVersion,
  });

  factory MemberModel.fromMap(Map<String, dynamic> map) => MemberModel(
    id: map['id'] as String? ?? '',
    fullName: map['fullName'] as String? ?? '',
    sessionsRemaining: (map['sessionsRemaining'] as num?)?.toInt() ?? 0,
    sessionsReserved: (map['sessionsReserved'] as num?)?.toInt() ?? 0,
    childName: map['childName'] as String? ?? '',
    childAge: (map['childAge'] as num?)?.toInt() ?? 0,
    waiverVersion: map['waiverVersion'] as String? ?? '',
  );
}
