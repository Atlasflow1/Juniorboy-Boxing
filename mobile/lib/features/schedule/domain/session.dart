class Session {
  const Session({
    required this.id,
    required this.classId,
    required this.date,
    required this.endAt,
    required this.maxSpots,
    required this.bookedSpots,
    required this.isCancelled,
  });

  final String id;
  final String classId;
  final DateTime date;
  final DateTime endAt;
  final int maxSpots;
  final int bookedSpots;
  final bool isCancelled;
}
