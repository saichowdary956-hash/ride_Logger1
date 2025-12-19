import 'dart:io';

Future<String> writeStringToFile(String filename, String content) async {
  final file = File(filename);
  await file.create(recursive: true);
  await file.writeAsString(content);
  return file.path;
}
