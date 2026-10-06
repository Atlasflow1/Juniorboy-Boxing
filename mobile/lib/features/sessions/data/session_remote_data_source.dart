import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/data/cached_repository.dart';

class SessionRemoteDataSource extends CachedRepository {
  String newId() => db.collection('sessions').doc().id;

  Stream<List<Map<String, dynamic>>> watch() =>
      watchQuery(db.collection('sessions'), 'sessions');

  Future<void> save(String id, Map<String, dynamic> values) async {
    final reference = db.doc('sessions/$id');
    final exists = (await reference.get()).exists;
    await reference.set({
      ...values,
      if (!exists) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> delete(String id) => db.doc('sessions/$id').delete();

  Future<String> uploadImage(String id, File file) async {
    if (await file.length() > 5 * 1024 * 1024) {
      throw const FormatException('Image must be smaller than 5 MB');
    }
    final ref = FirebaseStorage.instance.ref('gym/sessions/$id');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<List<Map<String, dynamic>>> fetchMembers(List<String> uids) async {
    if (uids.isEmpty) return [];
    final results = <Map<String, dynamic>>[];
    for (var i = 0; i < uids.length; i += 30) {
      final chunk = uids.sublist(i, i + 30 > uids.length ? uids.length : i + 30);
      final snap = await db
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      results.addAll(
        snap.docs.map((d) => <String, dynamic>{...d.data(), 'uid': d.id}),
      );
    }
    return results;
  }
}
