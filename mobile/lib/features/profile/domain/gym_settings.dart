class GymSettings {
  GymSettings({
    required this.coachName,
    required this.address,
    required this.phone,
    required this.email,
    required Map<String, Object?> operatingHours,
    required this.aboutText,
    required this.cancellationPolicyHours,
    required this.promoVideoUrl,
    required this.heroImageUrl,
    this.zipCode,
    this.socialLinks = const {},
  }) : operatingHours = Map.unmodifiable(operatingHours);

  final String? coachName, address, phone, email, aboutText;
  final String? promoVideoUrl, heroImageUrl;
  final String? zipCode;
  final Map<String, String> socialLinks;
  final num cancellationPolicyHours;
  final Map<String, Object?> operatingHours;

  static final empty = GymSettings(
    coachName: null,
    address: null,
    phone: null,
    email: null,
    operatingHours: {},
    aboutText: null,
    cancellationPolicyHours: 24,
    promoVideoUrl: null,
    heroImageUrl: null,
    zipCode: null,
  );
}
