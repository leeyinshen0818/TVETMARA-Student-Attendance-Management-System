String normalizeSubjectCodeForId(String subjectCode) {
  final normalized = subjectCode
      .trim()
      .toUpperCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[^A-Z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_');
  return normalized.replaceAll(RegExp(r'^_+|_+$'), '');
}

String buildSubjectId({
  required String programId,
  required String subjectCode,
}) {
  return '${programId.trim().toUpperCase()}_${normalizeSubjectCodeForId(subjectCode)}';
}
