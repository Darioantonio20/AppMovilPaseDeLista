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
  final String subject; // Nueva propiedad para materia
  final int institutionId;

  GradeGroup({this.id, required this.grade, required this.group, required this.subject, required this.institutionId});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'grade': grade,
      'group': group,
      'subject': subject, // Agregar materia en el mapeo
      'institutionId': institutionId,
    };
  }

  factory GradeGroup.fromMap(Map<String, dynamic> map) {
    return GradeGroup(
      id: map['id'],
      grade: map['grade'],
      group: map['group'],
      subject: map['subject'], // Obtener materia del mapa
      institutionId: map['institutionId'],
    );
  }
}
