import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_utils.dart';
import '../../booking/providers/booking_provider.dart';

final homeAdsProvider = StreamProvider((ref) => FirebaseFirestore.instance
    .collection('homeAds')
    .where('isActive', isEqualTo: true)
    .snapshots()
    .map((snapshot) {
  final rows = snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList()
    ..sort((a, b) =>
        ((a['sortOrder'] as num?) ?? 0).compareTo((b['sortOrder'] as num?) ?? 0));
  return rows;
}));

final nextBookingProvider = Provider<Map<String, dynamic>?>((ref) {
  final items = ref.watch(bookingsProvider).value ?? [];
  final upcoming =
      items
          .where(
            (b) =>
                b['status'] == 'confirmed' &&
                readDate(b['date']).isAfter(DateTime.now()),
          )
          .toList()
        ..sort((a, b) => readDate(a['date']).compareTo(readDate(b['date'])));
  return upcoming.isEmpty ? null : upcoming.first;
});
