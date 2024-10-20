import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/institution_model.dart';
import '../models/student_model.dart';
import '../models/institution_model.dart';

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
    String path = join(await getDatabasesPath(), 'school.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE institutions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        turno TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE grade_groups(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        grade TEXT,
        "group" TEXT,
        institutionId INTEGER,
        FOREIGN KEY(institutionId) REFERENCES institutions(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE students(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        matricula TEXT,
        gradeGroupId INTEGER,
        FOREIGN KEY(gradeGroupId) REFERENCES grade_groups(id)
      )
    ''');
  }

  Future<int> addInstitution(Institution institution) async {
    final db = await database;
    return await db.insert('institutions', institution.toMap());
  }

  Future<List<Institution>> getInstitutions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('institutions');
    return List.generate(maps.length, (i) {
      return Institution.fromMap(maps[i]);
    });
  }

  Future<void> deleteInstitution(int institutionId) async {
    final db = await database;
    await db.delete('institutions', where: 'id = ?', whereArgs: [institutionId]);
  }

  Future<int> addGradeGroup(GradeGroup gradeGroup) async {
    final db = await database;
    return await db.insert('grade_groups', gradeGroup.toMap());
  }

  Future<List<GradeGroup>> getGradeGroupsByInstitution(int institutionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('grade_groups', where: 'institutionId = ?', whereArgs: [institutionId]);
    return List.generate(maps.length, (i) {
      return GradeGroup.fromMap(maps[i]);
    });
  }

  Future<void> deleteGradeGroup(int gradeGroupId) async {
    final db = await database;
    await db.delete('grade_groups', where: 'id = ?', whereArgs: [gradeGroupId]);
  }

  Future<int> addStudent(Student student) async {
    final db = await database;
    return await db.insert('students', student.toMap());
  }

  Future<List<Student>> getStudentsByGradeGroup(int gradeGroupId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('students', where: 'gradeGroupId = ?', whereArgs: [gradeGroupId]);
    return List.generate(maps.length, (i) {
      return Student.fromMap(maps[i]);
    });
  }

  Future<void> deleteStudent(int studentId) async {
    final db = await database;
    await db.delete('students', where: 'id = ?', whereArgs: [studentId]);
  }
}
