class RecurringTemplate {
  const RecurringTemplate({
    required this.id,
    required this.classId,
    required this.dayOfWeek,
    required this.startTime,
    required this.maxSpots,
    required this.isActive,
  });
  final String id;
  final String? classId, startTime;
  final int dayOfWeek, maxSpots;
  final bool? isActive;
}
