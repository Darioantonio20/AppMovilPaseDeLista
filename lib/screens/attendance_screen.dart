import 'package:flutter/material.dart';
import 'package:pase_de_lista/models/institution_model.dart';
import '../models/student_model.dart';
import '../services/database_service.dart';
import 'package:intl/intl.dart';
import 'attendance_history_screen.dart';

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

  final List<String> attendanceStatuses = ['Presente', 'Retardo', 'Falta', 'Permiso'];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  void _loadStudents() async {
    final data = await DatabaseService().getStudentsByGradeGroup(widget.gradeGroup.id!);
    setState(() {
      students = data;
      attendance = students.isNotEmpty
          ? students.map((student) => {student: 'Presente'}).toList()
          : [];
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color.fromARGB(255, 45, 88, 189),
              onPrimary: Colors.white,
              onSurface: const Color.fromARGB(255, 45, 88, 189),
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
          ),
          child: child!,
        );
      },
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
      } else {
        setState(() {
          isAttendanceLoaded = true;
          attendance = students.isNotEmpty
              ? students.map((student) => {student: 'Presente'}).toList()
              : [];
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

  void _toggleAttendanceStatus(Student student) {
    setState(() {
      attendance = attendance.map((entry) {
        if (entry.keys.first == student) {
          String currentStatus = entry.values.first;
          int currentIndex = attendanceStatuses.indexOf(currentStatus);
          String nextStatus = attendanceStatuses[(currentIndex + 1) % attendanceStatuses.length];
          return {student: nextStatus};
        }
        return entry;
      }).toList();
    });
  }

  void _navigateToAttendanceHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendanceHistoryScreen(gradeGroup: widget.gradeGroup),
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
            icon: Icon(Icons.calendar_month_outlined),
            iconSize: 35,
            color: const Color.fromARGB(255, 45, 88, 189),
            onPressed: _navigateToAttendanceHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () => _selectDate(context),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color.fromARGB(255, 45, 88, 189),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
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
                if (students.isEmpty) {
                  return Center(child: Text("No hay estudiantes disponibles"));
                }
                Student student = students[index];
                String status = attendance.isNotEmpty && attendance[index][student] != null
                    ? attendance[index][student]!
                    : 'Presente';
                Color statusColor;
                if (status == 'Presente') {
                  statusColor = Colors.green.shade300;
                } else if (status == 'Retardo') {
                  statusColor = Colors.blue.shade300;
                } else if (status == 'Permiso') {
                  statusColor = Colors.purple.shade300;
                } else {
                  statusColor = Colors.red.shade300;
                }
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
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: statusColor,
                      ),
                      onPressed: () {
                        _toggleAttendanceStatus(student);
                      },
                      child: Text(status),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _saveAttendance,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 84, 112, 179),
                foregroundColor: Colors.white,
                textStyle: TextStyle(fontSize: 20),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('Guardar'),
            ),
          ),
        ],
      ),
    );
  }
}
