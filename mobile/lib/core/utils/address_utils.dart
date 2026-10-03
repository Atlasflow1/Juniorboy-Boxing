String composeAddress({
  required String houseNumber,
  required String streetName,
  required String city,
  required String country,
}) {
  final line = [houseNumber, streetName]
      .where((s) => s.trim().isNotEmpty)
      .join(' ');
  return [line, city, country]
      .where((s) => s.trim().isNotEmpty)
      .join(', ')
      .trim();
}
