import 'dart:io';
import 'package:file_picker/file_picker.dart';

class FilePickerUtil {
  Future<File?> pickCsvFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result != null) {
      return File(result.files.single.path!);
    }
    return null;
  }
}
