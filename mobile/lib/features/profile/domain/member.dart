class Member {
  const Member({
    required this.id,
    required this.fullName,
    required this.sessionsRemaining,
    required this.sessionsReserved,
    required this.childName,
    required this.childAge,
    required this.waiverVersion,
  });

  final String id;
  final String fullName;
  final int sessionsRemaining;
  final int sessionsReserved;
  final String childName;
  final int childAge;
  final String waiverVersion;
}
