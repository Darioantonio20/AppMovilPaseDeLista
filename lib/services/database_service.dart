import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/student_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'students.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE students(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        matricula TEXT
      )
    ''');
  }

  Future<int> addStudent(Student student) async {
    final db = await database;
    return await db.insert('students', student.toMap());
  }

  // Agregar varios estudiantes a la vez (utilizado al subir el archivo CSV)
  Future<void> addStudents(List<Student> students) async {
    final db = await database;
    Batch batch = db.batch();  // Ejecutamos una inserción en batch (grupo)
    students.forEach((student) {
      batch.insert('students', student.toMap());
    });
    await batch.commit(noResult: true);
  }

  Future<List<Student>> getStudents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('students');

    return List.generate(maps.length, (i) {
      return Student.fromMap(maps[i]);
    });
  }

  Future<void> deleteStudent(int id) async {
    final db = await database;
    await db.delete('students', where: 'id = ?', whereArgs: [id]);
  }
}
