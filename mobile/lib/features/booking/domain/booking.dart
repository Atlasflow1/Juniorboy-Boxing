class Booking {
  const Booking({
    required this.id,
    required this.className,
    required this.date,
    required this.endAt,
    required this.status,
  });

  final String id;
  final String className;
  final DateTime date;
  final DateTime endAt;
  final String status;
}
