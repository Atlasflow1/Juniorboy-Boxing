import '../../../core/utils/date_utils.dart';
import '../domain/session.dart';

class SessionModel extends Session {
  const SessionModel({
    required super.id,
    required super.classId,
    required super.date,
    required super.endAt,
    required super.maxSpots,
    required super.bookedSpots,
    required super.isCancelled,
    required super.startTime,
    required super.endTime,
  });

  factory SessionModel.fromMap(Map<String, dynamic> map) => SessionModel(
    id: map['id'] as String? ?? '',
    classId: map['classId'] as String? ?? '',
    date: readDate(map['date']),
    endAt: readDate(map['endAt']),
    maxSpots: (map['maxSpots'] as num?)?.toInt() ?? 0,
    bookedSpots: (map['bookedSpots'] as num?)?.toInt() ?? 0,
    isCancelled: map['isCancelled'] == true,
    startTime: map['startTime']?.toString() ?? 'null',
    endTime: map['endTime']?.toString() ?? 'null',
  );
}
