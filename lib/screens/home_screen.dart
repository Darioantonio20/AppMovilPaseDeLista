import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../services/database_service.dart';
import '../models/student_model.dart';
import 'add_student_screen.dart';
import 'attendance_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Student> students = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  void _loadStudents() async {
    final data = await DatabaseService().getStudents();
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
        // Leer el archivo CSV desde su ruta
        final File csvFile = File(file.path!);
        String content = await csvFile.readAsString();  // Leer el archivo como String

        // Eliminar BOM si está presente y normalizar saltos de línea
        content = content.replaceAll('\uFEFF', '').replaceAll("\r\n", "\n").replaceAll("\r", "\n");

        // Para depurar, mostrar el contenido del archivo CSV en consola
        print("Contenido del CSV: ");
        print(content);

        // Convertir el contenido del CSV en una lista
        final csvData = CsvToListConverter().convert(content, eol: "\n");

        if (csvData.isNotEmpty) {
          List<Student> csvStudents = [];
          List<Student> duplicatedStudents = [];

          // Obtener los estudiantes actuales en la base de datos
          List<Student> existingStudents = await DatabaseService().getStudents();

          // Procesar los datos (omitimos la primera fila que es la cabecera)
          for (var i = 1; i < csvData.length; i++) {
            var row = csvData[i];
            if (row.length >= 2) {
              String newName = row[0];
              String newMatricula = row[1].toString();

              // Verificar si el estudiante ya existe en la base de datos
              bool isDuplicate = existingStudents.any((student) =>
                  student.name == newName || student.matricula == newMatricula);

              if (isDuplicate) {
                duplicatedStudents.add(Student(name: newName, matricula: newMatricula));
              } else {
                csvStudents.add(Student(name: newName, matricula: newMatricula));
              }
            }
          }

          // Insertar los estudiantes no duplicados en la base de datos
          if (csvStudents.isNotEmpty) {
            await DatabaseService().addStudents(csvStudents);
            _loadStudents();  // Recargar la lista de estudiantes
          }

          // Mostrar una alerta si hay duplicados
          if (duplicatedStudents.isNotEmpty) {
            String duplicatedMessage = duplicatedStudents
                .map((student) => '${student.name} (Matrícula: ${student.matricula})')
                .join('\n');
            _showError('Los siguientes estudiantes ya están registrados y no se agregaron:\n$duplicatedMessage');
          } else {
            _showSuccess('Todos los estudiantes fueron agregados exitosamente.');
          }
        } else {
          _showError('El archivo CSV está vacío o no tiene contenido válido.');
        }
      } else {
        _showError('No se pudo acceder a la ruta del archivo CSV.');
      }
    }
  } catch (e) {
    _showError('Error al procesar el archivo CSV: $e');
  }
}

// Mostrar un diálogo de éxito
void _showSuccess(String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Éxito'),
        content: Text(message),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}



  // Mostrar un diálogo de error
  void _showError(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteStudent(int id) async {
    await DatabaseService().deleteStudent(id);
    _loadStudents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Alumnos'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddStudentScreen()),
              ).then((value) {
                _loadStudents();
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.upload_file),
            onPressed: _pickCsvFile,  // Al presionar, selecciona el archivo CSV
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
              onPressed: () => _deleteStudent(students[index].id!),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AttendanceScreen(student: students[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
