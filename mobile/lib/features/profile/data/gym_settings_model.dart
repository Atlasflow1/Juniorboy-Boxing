import '../domain/gym_settings.dart';
import '../../../core/utils/non_empty.dart';

class GymSettingsModel extends GymSettings {
  GymSettingsModel({
    required super.coachName,
    required super.address,
    required super.phone,
    required super.email,
    required super.operatingHours,
    required super.aboutText,
    required super.cancellationPolicyHours,
    required super.heroImageUrl,
    super.zipCode,
    super.socialLinks,
  });

  factory GymSettingsModel.fromMap(Map<String, dynamic> map) =>
      GymSettingsModel(
        coachName: nonEmpty(map['coachName'] as String?),
        address: nonEmpty(map['address'] as String?),
        phone: nonEmpty(map['phone'] as String?),
        email: nonEmpty(map['email'] as String?),
        operatingHours:
            (map['operatingHours'] as Map?)?.map(
              (key, value) => MapEntry(key.toString(), value),
            ) ??
            const {},
        aboutText: nonEmpty(map['aboutText'] as String?),
        cancellationPolicyHours: map['cancellationPolicyHours'] as num? ?? 24,
        heroImageUrl: nonEmpty(map['heroImageUrl'] as String?),
        zipCode: nonEmpty(map['zipCode'] as String?),
        socialLinks:
            (map['socialLinks'] as Map?)?.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            ) ??
            const {},
      );
}
