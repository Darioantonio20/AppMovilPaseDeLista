class Student {
  final int? id;
  final String name;
  final String matricula;
  final int gradeGroupId;

  Student({
    this.id,
    required this.name,
    required this.matricula,
    required this.gradeGroupId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'matricula': matricula,
      'gradeGroupId': gradeGroupId,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      name: map['name'],
      matricula: map['matricula'],
      gradeGroupId: map['gradeGroupId'],
    );
  }
}
