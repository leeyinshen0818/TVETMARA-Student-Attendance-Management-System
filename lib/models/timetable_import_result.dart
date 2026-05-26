enum TimetableImportRowStatus {
  valid,
  warning,
  duplicate,
  error,
}

class TimetableSlotDraft {
  const TimetableSlotDraft({
    required this.academicSessionId,
    required this.programId,
    required this.departmentId,
    required this.classId,
    required this.subjectId,
    required this.subjectCode,
    required this.subjectName,
    required this.lecturerEmail,
    required this.lecturerName,
    required this.roomId,
    required this.roomName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.weekStart,
    required this.weekEnd,
    required this.status,
    required this.remarks,
  });

  final String academicSessionId;
  final String programId;
  final String? departmentId;
  final String classId;
  final String subjectId;
  final String subjectCode;
  final String subjectName;
  final String lecturerEmail;
  final String? lecturerName;
  final String roomId;
  final String? roomName;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final int weekStart;
  final int weekEnd;
  final String status;
  final String? remarks;
}

class TimetableImportParsedRow {
  const TimetableImportParsedRow({
    required this.rowNumber,
    required this.rawData,
    required this.draft,
    required this.status,
    required this.errors,
    required this.warnings,
  });

  final int rowNumber;
  final Map<String, String> rawData;
  final TimetableSlotDraft? draft;
  final TimetableImportRowStatus status;
  final List<String> errors;
  final List<String> warnings;

  bool get hasError => errors.isNotEmpty;
  bool get hasWarning => warnings.isNotEmpty;
}

class TimetableImportResult {
  const TimetableImportResult({
    required this.totalRows,
    required this.validRows,
    required this.warningRows,
    required this.errorRows,
    required this.duplicateRows,
    required this.parsedRows,
    required this.validationErrors,
    required this.validationWarnings,
  });

  final int totalRows;
  final int validRows;
  final int warningRows;
  final int errorRows;
  final int duplicateRows;
  final List<TimetableImportParsedRow> parsedRows;
  final List<String> validationErrors;
  final List<String> validationWarnings;

  bool get hasFileErrors => validationErrors.isNotEmpty;
  bool get hasRowErrors => errorRows > 0 || duplicateRows > 0;
  bool get canProceed => !hasFileErrors && !hasRowErrors;
}
