import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pase_de_lista/models/institution_model.dart';
import 'package:pase_de_lista/services/database_service.dart';
import 'package:csv/csv.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:collection/collection.dart';


class AttendanceHistoryScreen extends StatefulWidget {
  final GradeGroup gradeGroup;

  AttendanceHistoryScreen({required this.gradeGroup});

  @override
  _AttendanceHistoryScreenState createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  List<Map<String, dynamic>> attendanceHistory = [];
  Map<int, Map<String, int>> attendanceSummary = {};

  @override
  void initState() {
    super.initState();
    _loadAttendanceHistory();
  }

  void _loadAttendanceHistory() async {
    List<Map<String, dynamic>> data =
        await DatabaseService().getAttendanceByGradeGroup(widget.gradeGroup.id!);

    Map<int, Map<String, int>> summary = {};

    for (var record in data) {
      int? studentId = record['studentId'] as int?;
      String status = record['status'] ?? 'Presente';

      if (studentId == null) continue;

      if (!summary.containsKey(studentId)) {
        summary[studentId] = {'Presente': 0, 'Retardo': 0, 'Falta': 0, 'Permiso': 0};
      }

      summary[studentId]![status] = (summary[studentId]![status] ?? 0) + 1;
    }

    setState(() {
      attendanceHistory = data;
      attendanceSummary = summary;
    });
  }

  Future<void> _shareCSV() async {
    Set<String> dateSet = attendanceHistory
        .map((record) => record['date'] != null ? record['date'] as String : '')
        .toSet();
    List<String> dates = dateSet.toList()..sort();

    List<List<String>> csvData = [];

    List<String> header = ['Nombre', 'Matrícula'] + dates + ['Presente', 'Falta', 'Permiso', 'Retardo'];
    csvData.add(header);

    var groupedData = groupBy(attendanceHistory, (record) => record['studentId']);

    groupedData.forEach((studentId, records) {
      String name = records.first['name'] ?? 'Sin nombre';
      String matricula = records.first['matricula'] ?? 'Sin matrícula';
      Map<String, String> dateStatusMap = {};
      for (var record in records) {
        String date = record['date'] != null ? record['date'] as String : '';
        String status = record['status'] ?? 'Presente';
        dateStatusMap[date] = status;
      }
      List<String> row = [name, matricula];
      for (var date in dates) {
        row.add(dateStatusMap[date] ?? '');
      }
      int presentes = attendanceSummary[studentId]!['Presente'] ?? 0;
      int faltas = attendanceSummary[studentId]!['Falta'] ?? 0;
      int permisos = attendanceSummary[studentId]!['Permiso'] ?? 0;
      int retardos = attendanceSummary[studentId]!['Retardo'] ?? 0;
      row.addAll([presentes.toString(), faltas.toString(), permisos.toString(), retardos.toString()]);
      csvData.add(row);
    });

    String csv = const ListToCsvConverter().convert(csvData);

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/historial_asistencia.csv';
    final file = File(path);

    await file.writeAsString(csv);

    final xfile = XFile(path);

    await Share.shareXFiles([xfile], text: 'Historial de Asistencia');
  }

  Future<void> _sharePDF() async {
    Set<String> dateSet = attendanceHistory
        .map((record) => record['date'] != null ? record['date'] as String : '')
        .toSet();
    List<String> dates = dateSet.toList()..sort();

    final pdf = pw.Document();
    final fontData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    final ttf = pw.Font.ttf(fontData);

    List<List<String>> tableData = [];

    List<String> header = ['Nombre', 'Matrícula'] + dates + ['Presente', 'Falta', 'Permiso', 'Retardo'];
    tableData.add(header);

    var groupedData = groupBy(attendanceHistory, (record) => record['studentId']);

    groupedData.forEach((studentId, records) {
      String name = records.first['name'] ?? 'Sin nombre';
      String matricula = records.first['matricula'] ?? 'Sin matrícula';
      Map<String, String> dateStatusMap = {};
      for (var record in records) {
        String date = record['date'] != null ? record['date'] as String : '';
        String status = record['status'] ?? 'Presente';
        dateStatusMap[date] = status;
      }
      List<String> row = [name, matricula];
      for (var date in dates) {
        row.add(dateStatusMap[date] ?? '');
      }
      int presentes = attendanceSummary[studentId]!['Presente'] ?? 0;
      int faltas = attendanceSummary[studentId]!['Falta'] ?? 0;
      int permisos = attendanceSummary[studentId]!['Permiso'] ?? 0;
      int retardos = attendanceSummary[studentId]!['Retardo'] ?? 0;
      row.addAll([presentes.toString(), faltas.toString(), permisos.toString(), retardos.toString()]);
      tableData.add(row);
    });

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          children: [
            pw.Text('Historial de Asistencia', style: pw.TextStyle(font: ttf)),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: header,
              data: tableData.skip(1).toList(),
              cellStyle: pw.TextStyle(font: ttf, fontSize: 8),
              headerStyle: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 8),
            ),
          ],
        ),
      ),
    );

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/historial_asistencia.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());

    final xfile = XFile(path);

    await Share.shareXFiles([xfile], text: 'Historial de Asistencia');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Historial de asistencia",
            style: TextStyle(color: const Color.fromARGB(255, 8, 8, 8),
            fontSize: 20,)
          ),
          centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.file_download_outlined, color: const Color.fromARGB(255, 87, 156, 115)),
            onPressed: _shareCSV,
            tooltip: 'Compartir CSV',
          ),
          IconButton(
            icon: Icon(Icons.picture_as_pdf_outlined, color: Color.fromARGB(255, 183, 61, 86)),
            onPressed: _sharePDF,
            tooltip: 'Compartir PDF',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: attendanceHistory.isEmpty
              ? Center(child: Text('No hay registros de asistencia disponibles'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: attendanceSummary.keys.map((studentId) {
                          List<Map<String, dynamic>> studentRecords = attendanceHistory
                              .where((record) => record['studentId'] == studentId)
                              .toList();
                          if (studentRecords.isEmpty) return SizedBox.shrink();
                          String studentName = studentRecords[0]['name'] ?? 'Sin nombre';
                          String studentMatricula =
                              studentRecords[0]['matricula'] ?? 'Sin matrícula';
                          return Card(
                            elevation: 5,
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: const Color.fromARGB(255, 237, 235, 235),
                                        child: Icon(Icons.person, color: const Color.fromARGB(255, 84, 112, 179)),
                                      ),
                                      const SizedBox(width: 10), // Espacio entre el icono y el texto
                                      Text(
                                        '$studentName - $studentMatricula',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text('Estatus', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Column(
                                    children: studentRecords.map((record) {
                                      String formattedDate = record['date'] != null
                                          ? DateFormat('yyyy-MM-dd')
                                              .format(DateTime.parse(record['date']))
                                          : 'Sin fecha';
                                      String status = record['status'] ?? 'Presente';
                                      Color statusColor;
                                      if (status == 'Presente') {
                                        statusColor = Colors.green;
                                      } else if (status == 'Retardo') {
                                        statusColor = Colors.blue;
                                      } else if (status == 'Permiso') {
                                        statusColor = Colors.purple;
                                      } else {
                                        statusColor = Colors.red;
                                      }

                                      return Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(formattedDate),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: statusColor,
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                            child: Text(
                                              status,
                                              style: TextStyle(color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Asistencias: ${attendanceSummary[studentId]!['Presente']}',
                                        style: TextStyle(color: Colors.green),
                                      ),
                                      Text(
                                        'Retardos: ${attendanceSummary[studentId]!['Retardo']}',
                                        style: TextStyle(color: Colors.blue),
                                      ),
                                      Text(
                                        'Permisos: ${attendanceSummary[studentId]!['Permiso']}',
                                        style: TextStyle(color: Colors.purple),
                                      ),
                                      Text(
                                        'Faltas: ${attendanceSummary[studentId]!['Falta']}',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
