import '../domain/gym_settings.dart';

class GymSettingsModel extends GymSettings {
  GymSettingsModel({
    required super.coachName,
    required super.address,
    required super.phone,
    required super.email,
    required super.operatingHours,
    required super.aboutText,
    required super.cancellationPolicyHours,
    required super.promoVideoUrl,
    required super.heroImageUrl,
  });

  factory GymSettingsModel.fromMap(Map<String, dynamic> map) =>
      GymSettingsModel(
        coachName: map['coachName'] as String?,
        address: map['address'] as String?,
        phone: map['phone'] as String?,
        email: map['email'] as String?,
        operatingHours:
            (map['operatingHours'] as Map?)?.map(
              (key, value) => MapEntry(key.toString(), value),
            ) ??
            const {},
        aboutText: map['aboutText'] as String?,
        cancellationPolicyHours: map['cancellationPolicyHours'] as num? ?? 24,
        promoVideoUrl: map['promoVideoUrl'] as String?,
        heroImageUrl: map['heroImageUrl'] as String?,
      );
}
