import 'package:external_path/external_path.dart';
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
import 'package:cross_file/cross_file.dart'; // Importar XFile

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

  // Método para compartir el CSV
  Future<void> _shareCSV() async {
    List<List<String>> csvData = [
      <String>['Nombre', 'Matrícula', 'Fecha', 'Estatus'],
      ...attendanceHistory.map((record) => [
            record['name'] ?? 'Sin nombre',
            record['matricula'] ?? 'Sin matrícula',
            record['date'] != null
                ? DateFormat('yyyy-MM-dd').format(DateTime.parse(record['date']))
                : 'Sin fecha',
            record['status'] ?? 'Presente',
          ])
    ];

    String csv = const ListToCsvConverter().convert(csvData);

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/historial_asistencia.csv';
    final file = File(path);

    await file.writeAsString(csv);

    final xfile = XFile(path);

    await Share.shareXFiles([xfile], text: 'Historial de Asistencia');
  }

  // Método para compartir el PDF
  Future<void> _sharePDF() async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    final ttf = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          children: [
            pw.Text('Historial de Asistencia', style: pw.TextStyle(font: ttf)),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['Nombre', 'Matrícula', 'Fecha', 'Estatus'],
              data: attendanceHistory.map((record) {
                return [
                  record['name'] ?? 'Sin nombre',
                  record['matricula'] ?? 'Sin matrícula',
                  record['date'] != null
                      ? DateFormat('yyyy-MM-dd').format(DateTime.parse(record['date']))
                      : 'Sin fecha',
                  record['status'] ?? 'Presente'
                ];
              }).toList(),
              cellStyle: pw.TextStyle(font: ttf),
              headerStyle: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold),
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
      // No AppBar, según tu solicitud
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: attendanceHistory.isEmpty
              ? Center(child: Text('No hay registros de asistencia disponibles'))
              : Column(
                  children: [
                    // Botones con margen superior
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Solo los botones de compartir
                          IconButton(
                            icon: Icon(Icons.insert_drive_file),
                            onPressed: _shareCSV,
                            tooltip: 'Compartir CSV',
                          ),
                          IconButton(
                            icon: Icon(Icons.picture_as_pdf_outlined),
                            onPressed: _sharePDF,
                            tooltip: 'Compartir PDF',
                          ),
                        ],
                      ),
                    ),
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
                                  Text(
                                    '$studentName - $studentMatricula',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 18),
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
