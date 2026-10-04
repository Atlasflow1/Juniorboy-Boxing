class Member {
  const Member({
    required this.id,
    required this.fullName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.age,
    required this.address,
    required this.zipCode,
    required this.avatarUrl,
    required this.role,
    required this.isActive,
    required this.memberSince,
    required this.membershipPlanId,
    required this.sessionsRemaining,
    required this.sessionsReserved,
    required this.childName,
    required this.childAge,
    required this.waiverVersion,
    required this.waiverParticipantName,
    required this.waiverParticipantAge,
    required this.pushNotifications,
    required this.emailNotifications,
  });

  final String id;
  final String? fullName, lastName, email, phone, address, zipCode;
  final String? avatarUrl, role, membershipPlanId;
  final bool? isActive;
  final DateTime memberSince;
  final int age, sessionsRemaining, sessionsReserved, childAge;
  final String childName, waiverVersion;
  final String? waiverParticipantName;
  final int? waiverParticipantAge;
  final bool pushNotifications, emailNotifications;

  bool get isProfileComplete =>
      (phone ?? '').isNotEmpty &&
      (lastName ?? '').isNotEmpty &&
      age > 0 &&
      (address ?? '').isNotEmpty &&
      (zipCode ?? '').isNotEmpty;
}
