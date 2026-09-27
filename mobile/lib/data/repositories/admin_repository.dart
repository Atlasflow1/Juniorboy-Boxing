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

  Future<void> deletePlan(String id) => db.doc('membershipPlans/$id').delete();

  Future<void> saveTemplate(String id, Map<String, dynamic> values) =>
      db.doc('recurringTemplates/$id').set(values, SetOptions(merge: true));

  Future<void> deleteTemplate(String id) =>
      db.doc('recurringTemplates/$id').delete();

  Future<void> savePromoVideoUrl(String url) =>
      db.doc('gymSettings/config').set({
        'promoVideoUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> saveGymInfo(String address, String phone) =>
      db.doc('gymSettings/config').set({
        'address': address,
        'phone': phone,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  /// Uploads the gym's own promo video to Storage and points Home at it.
  /// Being the gym's own file (not a YouTube embed), there's no embedding
  /// restriction to run into regardless of what the source video is.
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
    await savePromoVideoUrl(await ref.getDownloadURL());
  }

  Stream<List<Map<String, dynamic>>> orders() => watchQuery(
    db.collection('payments').orderBy('createdAt', descending: true).limit(200),
    'admin_orders',
  );

  Future<Map<String, dynamic>?> buyer(String userId) async {
    final snap = await db.doc('users/$userId').get();
    return snap.data();
  }

  Future<void> setOrderDelivery(
    String paymentId,
    DateTime estimatedDeliveryDate,
    String note,
  ) => FirebaseFunctions.instance.httpsCallable('setOrderDelivery').call({
    'paymentId': paymentId,
    'estimatedDeliveryDate': estimatedDeliveryDate.toIso8601String(),
    'note': note,
  });

  Future<void> deletePayment(String paymentId) =>
      FirebaseFunctions.instance.httpsCallable('deletePayment').call({
        'paymentId': paymentId,
      });

  Stream<List<Map<String, dynamic>>> bookings() => watchQuery(
    db.collection('bookings').orderBy('date', descending: true).limit(200),
    'admin_bookings',
  );

  Future<void> markAttendance(String bookingId, String status) =>
      FirebaseFunctions.instance.httpsCallable('markBookingCompleted').call({
        'bookingId': bookingId,
        'status': status,
      });

  Future<void> cancelBookingAsAdmin(String bookingId, String reason) =>
      FirebaseFunctions.instance.httpsCallable('cancelBooking').call({
        'bookingId': bookingId,
        'reason': reason,
      });
}
