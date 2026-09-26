import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'cached_repository.dart';

/// Admin-only data access for the in-app dashboard: membership plan
/// prices and class schedule times. Firestore rules already restrict
/// writes to these collections to role:'admin' accounts, matching the
/// same pattern the web admin panel uses.
class AdminRepository extends CachedRepository {
  Stream<List<Map<String, dynamic>>> plans() =>
      watchQuery(db.collection('membershipPlans'), 'admin_plans');
  Stream<List<Map<String, dynamic>>> templates() =>
      watchQuery(db.collection('recurringTemplates'), 'admin_templates');

  Future<void> savePlan(String id, Map<String, dynamic> values) =>
      db.doc('membershipPlans/$id').set({
        ...values,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> saveTemplate(String id, Map<String, dynamic> values) =>
      db.doc('recurringTemplates/$id').set(values, SetOptions(merge: true));

  Future<void> deleteTemplate(String id) =>
      db.doc('recurringTemplates/$id').delete();

  /// Uploads the gym's own promo video to Storage and points Home at it.
  /// Being the gym's own file, there's no embedding restriction or
  /// third-party branding to work around.
  Future<void> uploadPromoVideo(File file) async {
    if (await file.length() > 80 * 1024 * 1024) {
      throw const FormatException('Video must be smaller than 80 MB');
    }
    final ext = file.path.split('.').last.toLowerCase();
    final contentType = switch (ext) {
      'mov' => 'video/quicktime',
      'webm' => 'video/webm',
      _ => 'video/mp4',
    };
    final ref = FirebaseStorage.instance.ref('gym/promo_video.$ext');
    await ref.putFile(file, SettableMetadata(contentType: contentType));
    await db.doc('gymSettings/config').set({
      'promoVideoUrl': await ref.getDownloadURL(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removePromoVideo() => db.doc('gymSettings/config').set({
    'promoVideoUrl': '',
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  /// Verifies the admin PIN server-side; the PIN itself is never sent to
  /// or readable by any client.
  Future<void> verifyPin(String pin) =>
      FirebaseFunctions.instance.httpsCallable('verifyAdminPin').call({
        'pin': pin,
      });
}
