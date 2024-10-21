import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../services/database_service.dart';

class AddStudentScreen extends StatefulWidget {
  final int gradeGroupId;

  AddStudentScreen({required this.gradeGroupId});

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
      gradeGroupId: widget.gradeGroupId,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 40),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nombre del Alumno',
              labelStyle: TextStyle(fontSize: 20, color: Colors.grey[700]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color.fromARGB(255, 77, 191, 128), // Color verde
                ),
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 30),
          TextField(
            controller: _matriculaController,
            decoration: InputDecoration(
              labelText: 'Matrícula',
              labelStyle: TextStyle(fontSize: 20, color: Colors.grey[700]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color.fromARGB(255, 77, 191, 128), // Color verde
                ),
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 30),
          Center(
            child: ElevatedButton(
              onPressed: _addStudent,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 77, 191, 128),
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40.0),
                ),
                textStyle: TextStyle(fontSize: 18),
              ),
              child: Text('Agregar',
                  style: TextStyle(
                    color: Colors.white,
                  )),
            ),
          ),
        ],
      ),
    ),
  );
}
}
