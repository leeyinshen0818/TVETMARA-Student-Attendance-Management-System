class TimetableImportWritePlan {
  const TimetableImportWritePlan({
    required this.academicSessionId,
    required this.status,
    required this.totalRows,
    required this.successRows,
    required this.skippedRows,
    required this.duplicateRows,
    required this.errorRows,
    required this.warningRows,
    required this.subjectUpsertDraftsCount,
    required this.classCreateDraftsCount,
    required this.validationErrors,
    required this.validationWarnings,
  });

  final String academicSessionId;
  final String status;
  final int totalRows;
  final int successRows;
  final int skippedRows;
  final int duplicateRows;
  final int errorRows;
  final int warningRows;
  final int subjectUpsertDraftsCount;
  final int classCreateDraftsCount;
  final List<String> validationErrors;
  final List<String> validationWarnings;

  bool get hasImportableRows => successRows > 0;
}

class TimetableImportWriteResult {
  const TimetableImportWriteResult({
    required this.uploadId,
    required this.fileName,
    required this.status,
    required this.savedAs,
    required this.slotsCreated,
    required this.subjectsUpserted,
    required this.classesCreated,
    required this.duplicatesSkipped,
    required this.errorsSkipped,
    required this.skippedRows,
    required this.conflictRows,
    required this.roomConflicts,
    required this.lecturerConflicts,
    required this.classConflicts,
  });

  final String uploadId;
  final String fileName;
  final String status;
  final String savedAs;
  final int slotsCreated;
  final int subjectsUpserted;
  final int classesCreated;
  final int duplicatesSkipped;
  final int errorsSkipped;
  final int skippedRows;
  final int conflictRows;
  final int roomConflicts;
  final int lecturerConflicts;
  final int classConflicts;
}
