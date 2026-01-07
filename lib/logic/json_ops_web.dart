import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import 'package:file_picker/file_picker.dart';

// LOGICA PER IL WEB
Future<void> saveAndShareFile(String fileName, String jsonStr) async {
  final bytes = utf8.encode(jsonStr);
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

Future<Map<String, dynamic>?> pickAndReadFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
  );

  if (result != null) {
    // Su web leggiamo i bytes direttamente dalla memoria
    final fileBytes = result.files.first.bytes;
    if (fileBytes != null) {
      String content = utf8.decode(fileBytes);
      return jsonDecode(content);
    }
  }
  return null;
}