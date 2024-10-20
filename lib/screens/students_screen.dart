import 'dart:io';
import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../models/institution_model.dart';
import '../services/database_service.dart';
import 'add_student_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alumnos de ${widget.gradeGroup.grade} - ${widget.gradeGroup.group}'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addStudentManually,
          ),
          IconButton(
            icon: Icon(Icons.upload_file),
            onPressed: _pickCsvFile,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: students.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(students[index].name),
            subtitle: Text('Matrícula: ${students[index].matricula}'),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                _showDeleteConfirmation(students[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
