import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// LOGICA PER MOBILE / DESKTOP
Future<void> saveAndShareFile(String fileName, String jsonStr) async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/$fileName');
  await file.writeAsString(jsonStr);
  await Share.shareXFiles([XFile(file.path)], text: 'Ecco il file del personaggio!');
}

Future<Map<String, dynamic>?> pickAndReadFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
  );

  if (result != null && result.files.single.path != null) {
    File file = File(result.files.single.path!);
    String content = await file.readAsString();
    return jsonDecode(content);
  }
  return null;
}