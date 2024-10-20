class Student {
  final int? id;
  final String name;
  final String matricula;

  Student({this.id, required this.name, required this.matricula});

  // Convertir un Student en un mapa para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'matricula': matricula,
    };
  }

  // Crear un Student desde un mapa de SQLite
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      name: map['name'],
      matricula: map['matricula'],
    );
  }
}
