import 'timetable_import_result.dart';

class TimetablePreviewSlotDraft {
  const TimetablePreviewSlotDraft({
    required this.academicSessionId,
    required this.programId,
    required this.programName,
    required this.departmentId,
    required this.classId,
    required this.subjectId,
    required this.subjectCode,
    required this.subjectName,
    required this.lecturerId,
    required this.lecturerEmail,
    required this.lecturerName,
    required this.lecturerProfileId,
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
  final String programName;
  final String? departmentId;
  final String classId;
  final String subjectId;
  final String subjectCode;
  final String subjectName;
  final String lecturerId;
  final String lecturerEmail;
  final String lecturerName;
  final String? lecturerProfileId;
  final String roomId;
  final String roomName;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final int weekStart;
  final int weekEnd;
  final String status;
  final String? remarks;
}

class TimetableSubjectUpsertDraft {
  const TimetableSubjectUpsertDraft({
    required this.subjectId,
    required this.programId,
    required this.subjectCode,
    required this.subjectName,
  });

  final String subjectId;
  final String programId;
  final String subjectCode;
  final String subjectName;
}

class TimetableClassCreateDraft {
  const TimetableClassCreateDraft({
    required this.classId,
    required this.programId,
    required this.academicSessionId,
  });

  final String classId;
  final String programId;
  final String academicSessionId;
}

class TimetablePreviewRow {
  const TimetablePreviewRow({
    required this.rowNumber,
    required this.status,
    required this.errors,
    required this.warnings,
    required this.slotDraft,
    required this.sourceRow,
  });

  final int rowNumber;
  final TimetableImportRowStatus status;
  final List<String> errors;
  final List<String> warnings;
  final TimetablePreviewSlotDraft? slotDraft;
  final TimetableImportParsedRow sourceRow;
}

class TimetableMasterValidationResult {
  const TimetableMasterValidationResult({
    required this.totalRows,
    required this.validRows,
    required this.warningRows,
    required this.duplicateRows,
    required this.errorRows,
    required this.subjectUpsertDrafts,
    required this.classCreateDrafts,
    required this.previewRows,
    required this.validationErrors,
    required this.validationWarnings,
  });

  final int totalRows;
  final int validRows;
  final int warningRows;
  final int duplicateRows;
  final int errorRows;
  final List<TimetableSubjectUpsertDraft> subjectUpsertDrafts;
  final List<TimetableClassCreateDraft> classCreateDrafts;
  final List<TimetablePreviewRow> previewRows;
  final List<String> validationErrors;
  final List<String> validationWarnings;

  int get subjectUpsertDraftsCount => subjectUpsertDrafts.length;
  int get classCreateDraftsCount => classCreateDrafts.length;
  int get importableRows => validRows + warningRows;
  bool get canImport =>
      validationErrors.isEmpty && errorRows == 0 && importableRows > 0;
}
