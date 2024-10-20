import 'package:flutter/material.dart';
import '../models/student_model.dart';

class AttendanceScreen extends StatelessWidget {
  final Student student;

  AttendanceScreen({required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Asistencia de ${student.name}'),
      ),
      body: Center(
        child: Text('Pantalla de asistencia para ${student.name}'),
      ),
    );
  }
}
