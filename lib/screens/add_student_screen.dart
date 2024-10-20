import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../services/database_service.dart';

class AddStudentScreen extends StatefulWidget {
  @override
  _AddStudentScreenState createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _matriculaController = TextEditingController();

  void _addStudent() async {
    final student = Student(
      name: _nameController.text,
      matricula: _matriculaController.text,
    );
    await DatabaseService().addStudent(student);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agregar Alumno'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Nombre del Alumno'),
            ),
            TextField(
              controller: _matriculaController,
              decoration: InputDecoration(labelText: 'Matrícula'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addStudent,
              child: Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }
}
