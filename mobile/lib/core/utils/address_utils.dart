class StructuredAddress {
  const StructuredAddress({
    required this.houseNumber,
    required this.streetName,
    required this.city,
    required this.country,
  });
  final String houseNumber, streetName, city, country;

  factory StructuredAddress.parse(String? value) {
    final parts = (value ?? '').split(',').map((s) => s.trim()).toList();
    final street = parts.isEmpty ? '' : parts.first;
    final match = RegExp(r'^(\d+[A-Za-z]?)\s+(.+)$').firstMatch(street);
    return StructuredAddress(
      houseNumber: match?.group(1) ?? '',
      streetName: match?.group(2) ?? street,
      city: parts.length > 1 ? parts[1] : '',
      country: parts.length > 2 ? parts.last : '',
    );
  }
  String get formatted => composeAddress(
    houseNumber: houseNumber,
    streetName: streetName,
    city: city,
    country: country,
  );
}

String composeAddress({
  required String houseNumber,
  required String streetName,
  required String city,
  required String country,
}) {
  final line = [
    houseNumber,
    streetName,
  ].where((s) => s.trim().isNotEmpty).join(' ');
  return [
    line,
    city,
    country,
  ].where((s) => s.trim().isNotEmpty).join(', ').trim();
}
