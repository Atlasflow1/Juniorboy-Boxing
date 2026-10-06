/// Treats missing or whitespace-only optional data as absent.
String? nonEmpty(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
