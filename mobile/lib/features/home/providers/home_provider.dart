import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
