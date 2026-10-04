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
  Stream<List<Map<String, dynamic>>> programs() =>
      watchQuery(db.collection('classes'), 'admin_programs');
  Stream<List<Map<String, dynamic>>> ads() =>
      watchQuery(db.collection('homeAds'), 'admin_ads');

  Future<void> savePlan(String id, Map<String, dynamic> values) =>
      db.doc('membershipPlans/$id').set({
        ...values,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> deletePlan(String id) => db.doc('membershipPlans/$id').delete();

  /// Shares the same `gym/plans/{id}` Storage path the web admin panel
  /// uploads to, so a photo added from either platform shows on both.
  Future<String> uploadPlanImage(String planId, File file) async {
    if (await file.length() > 5 * 1024 * 1024) {
      throw const FormatException('Image must be smaller than 5 MB');
    }
    final ref = FirebaseStorage.instance.ref('gym/plans/$planId');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<void> saveProgram(String id, Map<String, dynamic> values) =>
      db.doc('classes/$id').set({
        ...values,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  /// Shares the same `gym/programs/{id}` Storage path the web admin panel
  /// uploads to, so a photo added from either platform shows on both.
  Future<String> uploadProgramImage(String classId, File file) async {
    if (await file.length() > 5 * 1024 * 1024) {
      throw const FormatException('Image must be smaller than 5 MB');
    }
    final ref = FirebaseStorage.instance.ref('gym/programs/$classId');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  /// Shares the same `gym/programs/{id}_ad{index}` Storage path the web
  /// admin panel uploads to, for the home-page program ad banners.
  Future<String> uploadProgramAdImage(String classId, int index, File file) async {
    if (await file.length() > 5 * 1024 * 1024) {
      throw const FormatException('Image must be smaller than 5 MB');
    }
    final ref = FirebaseStorage.instance.ref('gym/programs/${classId}_ad$index');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<void> saveAd(String id, Map<String, dynamic> values) =>
      db.doc('homeAds/$id').set({
        ...values,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> deleteAd(String id) => db.doc('homeAds/$id').delete();

  /// Shares the same `gym/ads/{id}` Storage path the web admin panel uploads
  /// to, so a photo added from either platform shows on both.
  Future<String> uploadAdImage(String adId, File file) async {
    if (await file.length() > 5 * 1024 * 1024) {
      throw const FormatException('Image must be smaller than 5 MB');
    }
    final ref = FirebaseStorage.instance.ref('gym/ads/$adId');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<void> saveTemplate(String id, Map<String, dynamic> values) =>
      db.doc('recurringTemplates/$id').set(values, SetOptions(merge: true));

  Future<void> deleteTemplate(String id) =>
      db.doc('recurringTemplates/$id').delete();

  /// Immediately generates next week's bookable sessions from the active
  /// recurring templates, instead of waiting for the Sunday cron — needed
  /// right after adding/fixing a class time so it shows up without delay.
  Future<void> generateScheduleNow() =>
      FirebaseFunctions.instance.httpsCallable('generateScheduleNow').call();

  /// Creates or edits a one-off bookable session on a specific date (as
  /// opposed to a recurring weekly class time) — e.g. "October 10,
  /// 10:00-11:00". Server-side `saveSchedule` enforces the capacity rule
  /// (Private=1, Duo=2, Group=admin's choice) and future-date/overlap
  /// checks, so this is a thin wrapper, same pattern as generateScheduleNow.
  Future<void> saveSession({
    String? scheduleId,
    required String classId,
    required String date,
    required String startTime,
    required String endTime,
    required int maxSpots,
  }) => FirebaseFunctions.instance.httpsCallable('saveSchedule').call({
    'scheduleId': scheduleId,
    'classId': classId,
    'date': date,
    'startTime': startTime,
    'endTime': endTime,
    'maxSpots': maxSpots,
  });

  Future<void> savePromoVideoUrl(String url) =>
      db.doc('gymSettings/config').set({
        'promoVideoUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> saveGymInfo({
    required String houseNumber,
    required String streetName,
    required String city,
    required String country,
    required String zipCode,
    required String phone,
  }) => db.doc('gymSettings/config').set({
    // Street, city, zip, country — the conventional mailing-address order.
    // Built here (not via the shared composeAddress helper used for member
    // profiles) so zip lands between city and country instead of after.
    'address': [
      [houseNumber, streetName].where((s) => s.trim().isNotEmpty).join(' '),
      city,
      zipCode,
      country,
    ].where((s) => s.trim().isNotEmpty).join(', '),
    'zipCode': zipCode,
    'phone': phone,
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  Future<void> saveSocialLinks(Map<String, String> links) =>
      db.doc('gymSettings/config').set({
        'socialLinks': links,
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
