class PickedTextFile {
  const PickedTextFile({
    required this.name,
    required this.content,
  });

  final String name;
  final String content;
}

Future<PickedTextFile?> pickTimetableFile() async => null;

void downloadTextFile({
  required String filename,
  required String content,
  String mimeType = 'text/csv',
}) {}

void downloadBinaryFile({
  required String filename,
  required List<int> bytes,
  String mimeType = 'application/octet-stream',
}) {}
