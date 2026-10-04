import 'waiver.dart';

abstract class WaiverRepository {
  Stream<Waiver> watch();
  Future<void> accept({
    required String? version,
    required String signerName,
    required bool guardian,
    required bool adult,
    required bool agree,
  });
}
