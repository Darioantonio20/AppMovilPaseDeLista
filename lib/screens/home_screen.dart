import 'package:flutter/material.dart';
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
