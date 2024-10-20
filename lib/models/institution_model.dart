class Institution {
  final int? id;
  final String name;
  final String turno; // 'Matutino' o 'Vespertino'

  Institution({this.id, required this.name, required this.turno});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'turno': turno,
    };
  }

  factory Institution.fromMap(Map<String, dynamic> map) {
    return Institution(
      id: map['id'],
      name: map['name'],
      turno: map['turno'],
    );
  }
}

class GradeGroup {
  final int? id;
  final String grade;
  final String group;
  final int institutionId; // Relación con la institución

  GradeGroup({this.id, required this.grade, required this.group, required this.institutionId});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'grade': grade,
      'group': group,
      'institutionId': institutionId,
    };
  }

  factory GradeGroup.fromMap(Map<String, dynamic> map) {
    return GradeGroup(
      id: map['id'],
      grade: map['grade'],
      group: map['group'],
      institutionId: map['institutionId'],
    );
  }
}
