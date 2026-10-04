import '../domain/recurring_template.dart';
import '../../../core/utils/non_empty.dart';

class RecurringTemplateModel extends RecurringTemplate {
  const RecurringTemplateModel({
    required super.id,
    required super.classId,
    required super.dayOfWeek,
    required super.startTime,
    required super.maxSpots,
    required super.isActive,
  });

  factory RecurringTemplateModel.fromMap(Map<String, dynamic> map) =>
      RecurringTemplateModel(
        id: map['id'] as String? ?? '',
        classId: nonEmpty(map['classId'] as String?),
        dayOfWeek: (map['dayOfWeek'] as num?)?.toInt() ?? 1,
        startTime: nonEmpty(map['startTime'] as String?),
        maxSpots: (map['maxSpots'] as num?)?.toInt() ?? 12,
        isActive: map['isActive'] as bool?,
      );
}
