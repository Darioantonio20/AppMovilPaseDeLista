import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';

class CsvService {
  Future<List<Map<String, dynamic>>> importCsv(File file) async {
    final input = file.openRead();
    final fields = await input.transform(utf8.decoder).transform(CsvToListConverter()).toList();

    List<Map<String, dynamic>> students = [];
    for (var row in fields) {
      students.add({
        'nombre': row[0],
        'matricula': row[1],
      });
    }
    return students;
  }
}
