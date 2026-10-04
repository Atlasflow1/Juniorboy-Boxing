class Program {
  const Program({
    required this.id,
    required this.className,
    required this.ageGroup,
    required this.address,
  });

  final String id;
  final String? className;
  final String? ageGroup;
  final String? address;

  static const empty = Program(
    id: '',
    className: null,
    ageGroup: null,
    address: null,
  );
}
