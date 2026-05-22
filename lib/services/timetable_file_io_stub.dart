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
