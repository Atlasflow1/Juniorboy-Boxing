import '../domain/waiver.dart';

class WaiverModel extends Waiver {
  const WaiverModel({
    required super.version,
    required super.body,
    required super.published,
    required super.requiredOnBooking,
  });

  factory WaiverModel.fromMap(Map<String, dynamic>? map) => WaiverModel(
    version: map?['version'] as String?,
    body: map?['body'] as String?,
    published: map?['published'] == true,
    requiredOnBooking: map?['requiredOnBooking'] == true,
  );
}
