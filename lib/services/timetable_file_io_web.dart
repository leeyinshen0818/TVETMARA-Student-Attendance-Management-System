// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

class PickedTextFile {
  const PickedTextFile({
    required this.name,
    required this.content,
  });

  final String name;
  final String content;
}

Future<PickedTextFile?> pickTimetableFile() async {
  final input = html.FileUploadInputElement()..accept = '.csv,text/csv';
  input.click();

  final change = await input.onChange.first;
  final target = change.target as html.FileUploadInputElement?;
  final file = target?.files?.isNotEmpty == true ? target!.files!.first : null;
  if (file == null) return null;

  final reader = html.FileReader();
  reader.readAsText(file);
  await reader.onLoad.first;
  return PickedTextFile(name: file.name, content: reader.result as String);
}

void downloadTextFile({
  required String filename,
  required String content,
  String mimeType = 'text/csv',
}) {
  final blob = html.Blob([content], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}

void downloadBinaryFile({
  required String filename,
  required List<int> bytes,
  String mimeType = 'application/octet-stream',
}) {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
