class Waiver {
  const Waiver({
    required this.version,
    required this.body,
    required this.published,
    required this.requiredOnBooking,
  });

  final String? version;
  final String? body;
  final bool published;
  final bool requiredOnBooking;
}
