import 'package:flutter_test/flutter_test.dart';
import 'package:tvetmara_student_attendance/models/timetable_import_result.dart';
import 'package:tvetmara_student_attendance/models/timetable_master_validation_result.dart';
import 'package:tvetmara_student_attendance/services/timetable_firestore_import_service.dart';

TimetablePreviewRow _row({
  int rowNumber = 2,
  TimetableImportRowStatus status = TimetableImportRowStatus.valid,
  String academicSessionId = '2026_S1',
  String subjectId = 'DED_DED10044',
  String classId = 'DED_1A',
}) {
  final draft = TimetablePreviewSlotDraft(
    academicSessionId: academicSessionId,
    programId: 'DED',
    programName: 'DIPLOMA TEKNOLOGI KEJURUTERAAN ELEKTRIK (DED)',
    departmentId: 'elektrik',
    classId: classId,
    subjectId: subjectId,
    subjectCode: 'DED10044',
    subjectName: 'Wiring and Installation Practice',
    lecturerId: 'UID_DED',
    lecturerEmail: 'pensyarah_ded@tvetmara.edu.my',
    lecturerProfileId: null,
    lecturerName: 'Pensyarah DED',
    roomId: 'BILIK KULIAH 1',
    roomName: 'BILIK KULIAH 1',
    dayOfWeek: 'Isnin',
    startTime: '08:00',
    endTime: '10:00',
    weekStart: 1,
    weekEnd: 18,
    status: 'active',
    remarks: null,
  );
  return TimetablePreviewRow(
    rowNumber: rowNumber,
    status: status,
    errors: status == TimetableImportRowStatus.error
        ? const ['programId missing']
        : status == TimetableImportRowStatus.duplicate
            ? const ['Duplicate row']
            : const [],
    warnings: status == TimetableImportRowStatus.warning
        ? const ['subject will be created']
        : const [],
    slotDraft: status == TimetableImportRowStatus.error ? null : draft,
    sourceRow: TimetableImportParsedRow(
      rowNumber: rowNumber,
      rawData: const {},
      draft: null,
      status: status,
      errors: const [],
      warnings: const [],
    ),
  );
}

TimetableMasterValidationResult _preview({
  List<TimetablePreviewRow>? rows,
  int? validRows,
  int? warningRows,
  int? duplicateRows,
  int? errorRows,
  List<TimetableSubjectUpsertDraft> subjectDrafts = const [],
  List<TimetableClassCreateDraft> classDrafts = const [],
}) {
  final previewRows = rows ?? [_row()];
  return TimetableMasterValidationResult(
    totalRows: previewRows.length,
    validRows: validRows ??
        previewRows
            .where((row) => row.status == TimetableImportRowStatus.valid)
            .length,
    warningRows: warningRows ??
        previewRows
            .where((row) => row.status == TimetableImportRowStatus.warning)
            .length,
    duplicateRows: duplicateRows ??
        previewRows
            .where((row) => row.status == TimetableImportRowStatus.duplicate)
            .length,
    errorRows: errorRows ??
        previewRows
            .where((row) => row.status == TimetableImportRowStatus.error)
            .length,
    subjectUpsertDrafts: subjectDrafts,
    classCreateDrafts: classDrafts,
    previewRows: previewRows,
    validationErrors: const [],
    validationWarnings: const [],
  );
}

void main() {
  test('buildPlan counts importable rows and skipped rows', () {
    final preview = _preview(rows: [
      _row(status: TimetableImportRowStatus.valid),
      _row(rowNumber: 3, status: TimetableImportRowStatus.warning),
      _row(rowNumber: 4, status: TimetableImportRowStatus.duplicate),
      _row(rowNumber: 5, status: TimetableImportRowStatus.error),
    ]);

    final plan = TimetableFirestoreImportService.buildPlan(preview);

    expect(plan.successRows, 2);
    expect(plan.skippedRows, 2);
    expect(plan.duplicateRows, 1);
    expect(plan.errorRows, 1);
    expect(plan.status, 'completed_with_warnings');
  });

  test('duplicate and error rows are filtered out', () {
    final preview = _preview(rows: [
      _row(status: TimetableImportRowStatus.valid),
      _row(rowNumber: 3, status: TimetableImportRowStatus.warning),
      _row(rowNumber: 4, status: TimetableImportRowStatus.duplicate),
      _row(rowNumber: 5, status: TimetableImportRowStatus.error),
    ]);

    final rows = TimetableFirestoreImportService.importableRows(preview);

    expect(rows.length, 2);
    expect(rows.every((row) => row.slotDraft != null), isTrue);
  });

  test('zero importable rows is represented as failed plan', () {
    final preview = _preview(rows: [
      _row(status: TimetableImportRowStatus.duplicate),
      _row(rowNumber: 3, status: TimetableImportRowStatus.error),
    ]);

    final plan = TimetableFirestoreImportService.buildPlan(preview);

    expect(plan.hasImportableRows, isFalse);
    expect(plan.status, 'failed');
    expect(plan.successRows, 0);
  });

  test('subject and class draft counts are included in plan', () {
    final preview = _preview(
      rows: [_row(status: TimetableImportRowStatus.warning)],
      subjectDrafts: const [
        TimetableSubjectUpsertDraft(
          subjectId: 'DED_DED10044',
          programId: 'DED',
          subjectCode: 'DED10044',
          subjectName: 'Wiring and Installation Practice',
        ),
      ],
      classDrafts: const [
        TimetableClassCreateDraft(
          classId: 'DED_1A',
          programId: 'DED',
          academicSessionId: '2026_S1',
        ),
      ],
    );

    final plan = TimetableFirestoreImportService.buildPlan(preview);

    expect(plan.subjectUpsertDraftsCount, 1);
    expect(plan.classCreateDraftsCount, 1);
  });

  test('subject and class drafts are filtered to imported rows only', () {
    final preview = _preview(
      rows: [
        _row(subjectId: 'DED_SUBJ1', classId: 'DED_1A'),
        _row(
          rowNumber: 3,
          status: TimetableImportRowStatus.duplicate,
          subjectId: 'DED_SUBJ2',
          classId: 'DED_1B',
        ),
      ],
      subjectDrafts: const [
        TimetableSubjectUpsertDraft(
          subjectId: 'DED_SUBJ1',
          programId: 'DED',
          subjectCode: 'SUBJ1',
          subjectName: 'Subject 1',
        ),
        TimetableSubjectUpsertDraft(
          subjectId: 'DED_SUBJ2',
          programId: 'DED',
          subjectCode: 'SUBJ2',
          subjectName: 'Subject 2',
        ),
      ],
      classDrafts: const [
        TimetableClassCreateDraft(
          classId: 'DED_1A',
          programId: 'DED',
          academicSessionId: '2026_S1',
        ),
        TimetableClassCreateDraft(
          classId: 'DED_1B',
          programId: 'DED',
          academicSessionId: '2026_S1',
        ),
      ],
    );

    final rows = TimetableFirestoreImportService.importableRows(preview);
    final subjectDrafts =
        TimetableFirestoreImportService.subjectDraftsForRows(preview, rows);
    final classDrafts =
        TimetableFirestoreImportService.classDraftsForRows(preview, rows);

    expect(subjectDrafts.map((draft) => draft.subjectId), ['DED_SUBJ1']);
    expect(classDrafts.map((draft) => draft.classId), ['DED_1A']);
  });

  test('academic session summary detects mixed sessions', () {
    final preview = _preview(rows: [
      _row(academicSessionId: '2026_S1'),
      _row(rowNumber: 3, academicSessionId: '2026_S2'),
    ]);

    expect(
        TimetableFirestoreImportService.academicSessionIdFor(preview), 'mixed');
  });
}
