import '../domain/program.dart';

class ProgramModel extends Program {
  const ProgramModel({
    required super.id,
    required super.className,
    required super.ageGroup,
    required super.address,
  });

  factory ProgramModel.fromMap(Map<String, dynamic> map) => ProgramModel(
    id: map['id'] as String? ?? '',
    className: map['className'] as String?,
    ageGroup: map['ageGroup'] as String?,
    address: map['address'] as String?,
  );
}
