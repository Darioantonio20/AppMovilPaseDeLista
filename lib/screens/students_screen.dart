import 'dart:io';
import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../models/institution_model.dart';
import '../services/database_service.dart';
import 'add_student_screen.dart';
import 'attendance_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:csv/csv.dart';

class StudentsScreen extends StatefulWidget {
  final GradeGroup gradeGroup;

  StudentsScreen({required this.gradeGroup});

  @override
  _StudentsScreenState createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  List<Student> students = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  void _loadStudents() async {
    final data = await DatabaseService().getStudentsByGradeGroup(widget.gradeGroup.id!);
    setState(() {
      students = data;
    });
  }

  Future<void> _pickCsvFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;

        if (file.path != null) {
          final File csvFile = File(file.path!);
          String content = await csvFile.readAsString();
          content = content.replaceAll('\uFEFF', '').replaceAll("\r\n", "\n").replaceAll("\r", "\n");

          final csvData = CsvToListConverter().convert(content, eol: "\n");

          if (csvData.isNotEmpty) {
            List<Student> csvStudents = [];
            List<Student> duplicatedStudents = [];

            List<Student> existingStudents = await DatabaseService().getStudentsByGradeGroup(widget.gradeGroup.id!);

            for (var i = 1; i < csvData.length; i++) {
              var row = csvData[i];
              if (row.length >= 2) {
                String newName = row[0];
                String newMatricula = row[1].toString();

                bool isDuplicate = existingStudents.any((student) => student.matricula == newMatricula);

                if (isDuplicate) {
                  duplicatedStudents.add(Student(name: newName, matricula: newMatricula, gradeGroupId: widget.gradeGroup.id!));
                } else {
                  csvStudents.add(Student(name: newName, matricula: newMatricula, gradeGroupId: widget.gradeGroup.id!));
                }
              }
            }

            if (duplicatedStudents.isNotEmpty) {
              _showDuplicateDialog(duplicatedStudents, csvStudents);
            } else {
              for (var student in csvStudents) {
                await DatabaseService().addStudent(student);
              }
              _loadStudents();
            }
          }
        }
      }
    } catch (e) {
      print('Error al cargar el archivo CSV: $e');
    }
  }

  void _showDuplicateDialog(List<Student> duplicatedStudents, List<Student> csvStudents) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Duplicados encontrados'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Se encontraron las siguientes matrículas duplicadas:'),
              SizedBox(height: 10),
              ...duplicatedStudents.map((student) => Text('${student.name} - Matrícula: ${student.matricula}')).toList(),
              SizedBox(height: 10),
              Text('¿Desea omitir los duplicados y continuar?'),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Omitir duplicados'),
              onPressed: () {
                _addStudentsWithoutDuplicates(csvStudents);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _addStudentsWithoutDuplicates(List<Student> csvStudents) async {
    for (var student in csvStudents) {
      await DatabaseService().addStudent(student);
    }
    _loadStudents();
  }

  void _deleteStudent(int studentId) async {
    await DatabaseService().deleteStudent(studentId);
    _loadStudents();
  }

  void _showDeleteConfirmation(Student student) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar eliminación'),
          content: Text('¿Está seguro de que desea eliminar al estudiante ${student.name}?'),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Eliminar'),
              onPressed: () {
                _deleteStudent(student.id!);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _addStudentManually() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddStudentScreen(gradeGroupId: widget.gradeGroup.id!),
      ),
    ).then((value) {
      _loadStudents();
    });
  }

  void _navigateToAttendance() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendanceScreen(gradeGroup: widget.gradeGroup),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alumnos de ${widget.gradeGroup.grade} - ${widget.gradeGroup.group}'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            color: const Color.fromARGB(255, 77, 191, 128),
            iconSize: 33,
            onPressed: _addStudentManually,
          ),
          IconButton(
            icon: Icon(Icons.upload_file),
            color: const Color.fromARGB(255, 76, 202, 133),
            iconSize: 33,
            onPressed: _pickCsvFile,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                Student student = students[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  elevation: 5,
                  margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16.0),
                    title: Text(
                      student.name,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Text(
                      'Matrícula: ${student.matricula}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      iconSize: 35,
                      color: Colors.red,
                      onPressed: () {
                        _showDeleteConfirmation(student);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _navigateToAttendance,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, 
                backgroundColor: const Color.fromARGB(255, 84, 112, 179), 
                textStyle: TextStyle(fontSize: 20), 
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12), 
              ),
              child: Text('Pase de Lista'),
            ),
          ),
        ],
      ),
    );
  }
}
