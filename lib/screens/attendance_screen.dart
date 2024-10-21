import 'package:flutter/material.dart';
import 'package:pase_de_lista/models/institution_model.dart';
import '../models/student_model.dart';
import '../services/database_service.dart';
import 'package:intl/intl.dart';
import 'attendance_history_screen.dart';  // Importar la nueva pantalla de historial

class AttendanceScreen extends StatefulWidget {
  final GradeGroup gradeGroup;

  AttendanceScreen({required this.gradeGroup});

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime? selectedDate;
  List<Map<Student, String>> attendance = [];
  List<Student> students = [];
  bool isAttendanceLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  void _loadStudents() async {
    final data = await DatabaseService().getStudentsByGradeGroup(widget.gradeGroup.id!);
    setState(() {
      students = data;
      attendance = students.map((student) => {student: 'Asistidos'}).toList();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        isAttendanceLoaded = false;
      });
      _loadAttendanceForDate();
    }
  }

  void _loadAttendanceForDate() async {
    if (selectedDate != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
      List<Map<String, dynamic>> data = await DatabaseService().getAttendanceByDate(formattedDate, widget.gradeGroup.id!);
      
      if (data.isNotEmpty) {
        setState(() {
          isAttendanceLoaded = true;
          attendance = data.map((entry) {
            Student student = Student(
              id: entry['id'],
              name: entry['name'],
              matricula: entry['matricula'],
              gradeGroupId: widget.gradeGroup.id!,
            );
            return {student: entry['status'].toString()};
          }).toList();
        });
      }
    }
  }

  void _saveAttendance() async {
    if (selectedDate != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
      for (var entry in attendance) {
        Student student = entry.keys.first;
        String status = entry.values.first;

        await DatabaseService().addAttendance(student.id!, formattedDate, status);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pase de lista guardado')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, seleccione la fecha')),
      );
    }
  }

  void _setAttendanceStatus(Student student, String status) {
    setState(() {
      attendance = attendance.map((entry) {
        if (entry.keys.first == student) {
          return {student: status};
        }
        return entry;
      }).toList();
    });
  }

  void _showStatusDialog(Student student, String currentStatus) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Seleccionar Estado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['Asistidos', 'Retardo', 'Falta'].map((String value) {
              return ListTile(
                title: Text(value),
                onTap: () {
                  _setAttendanceStatus(student, value);
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _navigateToAttendanceHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendanceHistoryScreen(gradeGroup: widget.gradeGroup), // Redirigir a la pantalla de historial
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pase de Lista - ${widget.gradeGroup.grade} - ${widget.gradeGroup.group}'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: _navigateToAttendanceHistory, // Agregar botón que lleva a la tabla del historial
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: Text(
                    selectedDate == null
                        ? 'Seleccionar Fecha'
                        : 'Fecha: ${DateFormat.yMd().format(selectedDate!)}',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                Student student = students[index];
                String status = attendance.isNotEmpty && attendance[index][student] != null
                    ? attendance[index][student]!
                    : 'Asistidos';
                Color statusColor;
                if (status == 'Asistidos') {
                  statusColor = Colors.green.shade300;
                } else if (status == 'Retardo') {
                  statusColor = Colors.blue.shade300;
                } else {
                  statusColor = Colors.red.shade300;
                }
                return ListTile(
                  title: Text(student.name),
                  subtitle: Text('Matrícula: ${student.matricula}'),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: statusColor,
                    ),
                    onPressed: () {
                      _showStatusDialog(student, status);
                    },
                    child: Text(status),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _saveAttendance,
              child: Text('Guardar Pase de Lista'),
            ),
          ),
        ],
      ),
    );
  }
}
