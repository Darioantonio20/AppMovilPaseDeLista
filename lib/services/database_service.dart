import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
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
      version: 4, // Incrementar versión
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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
        subject TEXT, -- Agregar el campo de materia
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

    await db.execute('''
      CREATE TABLE attendance(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId INTEGER,
        date TEXT,
        status TEXT,
        FOREIGN KEY(studentId) REFERENCES students(id)
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      await db.execute('''
        ALTER TABLE grade_groups ADD COLUMN subject TEXT;
      ''');
    }
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

  Future<int> addAttendance(int studentId, String date, String status) async {
    final db = await database;
    return await db.insert('attendance', {
      'studentId': studentId,
      'date': date,
      'status': status,
    });
  }

  Future<List<Map<String, dynamic>>> getAttendanceByDate(String date, int gradeGroupId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT students.id, students.name, students.matricula, attendance.status
      FROM attendance
      JOIN students ON attendance.studentId = students.id
      WHERE attendance.date = ? AND students.gradeGroupId = ?
    ''', [date, gradeGroupId]);
  }

  Future<List<Map<String, dynamic>>> getAttendanceByGradeGroup(int gradeGroupId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT students.id AS studentId, students.name, students.matricula, attendance.date, attendance.status
      FROM attendance
      JOIN students ON attendance.studentId = students.id
      WHERE students.gradeGroupId = ?
      ORDER BY attendance.date DESC
    ''', [gradeGroupId]);
  }
}

// poner agregar grado y grupo enmodal -> en grado _> nombre de materia y en grupo poner string grado - grupo

// pase de lista cambiar estado a asistencia - estado de permido
// alternativa de cambiar boton de manera dinamica para cambiar estado
// exportar la tabla donde esta la fecha y estatus de los alumnos en un csv o pdf