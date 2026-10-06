import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/non_empty.dart';

class SessionModel {
  const SessionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.images,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.maxParticipants,
    required this.joinedUserIds,
  });

  final String id;
  final String title;
  final String description;
  final double price;
  final List<String> images;
  final String type; // 'individual' | 'duo' | 'team'
  final DateTime startDate;
  final DateTime endDate;
  final String startTime;
  final String endTime;
  final int maxParticipants;
  final List<String> joinedUserIds;

  factory SessionModel.fromMap(Map<String, dynamic> map) => SessionModel(
    id: map['id'] as String? ?? '',
    title: nonEmpty(map['title'] as String?) ?? '',
    description: nonEmpty(map['description'] as String?) ?? '',
    price: (map['price'] as num?)?.toDouble() ?? 0.0,
    images: (map['images'] as List?)?.whereType<String>().toList() ?? const [],
    type: map['type'] as String? ?? 'individual',
    startDate: readDate(map['startDate']),
    endDate: readDate(map['endDate']),
    startTime: map['startTime'] as String? ?? '',
    endTime: map['endTime'] as String? ?? '',
    maxParticipants: (map['maxParticipants'] as num?)?.toInt() ?? 1,
    joinedUserIds: (map['joinedUserIds'] as List?)?.whereType<String>().toList() ?? const [],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'price': price,
    'images': images,
    'type': type,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'startTime': startTime,
    'endTime': endTime,
    'maxParticipants': maxParticipants,
    'joinedUserIds': joinedUserIds,
  };
}
