import '../domain/program.dart';
import '../../../core/utils/non_empty.dart';

class ProgramModel extends Program {
  const ProgramModel({
    required super.id,
    required super.className,
    required super.ageGroup,
    required super.address,
  });

  factory ProgramModel.fromMap(Map<String, dynamic> map) => ProgramModel(
    id: map['id'] as String? ?? '',
    className: nonEmpty(map['className'] as String?),
    ageGroup: nonEmpty(map['ageGroup'] as String?),
    address: nonEmpty(map['address'] as String?),
  );
}
