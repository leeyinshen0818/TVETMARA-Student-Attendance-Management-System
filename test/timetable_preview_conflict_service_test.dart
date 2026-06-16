import 'package:flutter_test/flutter_test.dart';
import 'package:tvetmara_student_attendance/models/app_models.dart';
import 'package:tvetmara_student_attendance/models/timetable_import_result.dart';
import 'package:tvetmara_student_attendance/models/timetable_master_validation_result.dart';
import 'package:tvetmara_student_attendance/services/timetable_preview_conflict_service.dart';

TimetablePreviewRow _row({
  required int rowNumber,
  String academicSessionId = 'JAN_JUN_2026',
  String programId = 'DED',
  String classId = 'DED 1A',
  String subjectCode = 'DED10044',
  String lecturerId = 'LECT_A',
  String lecturerEmail = 'lecturer.a@tvetmara.edu.my',
  String lecturerName = 'Lecturer A',
  String roomId = 'ROOM_A',
  String roomName = 'Room A',
  String dayOfWeek = 'Isnin',
  String startTime = '08:00',
  String endTime = '10:00',
  int weekStart = 1,
  int weekEnd = 18,
  TimetableImportRowStatus status = TimetableImportRowStatus.valid,
}) {
  final draft = TimetablePreviewSlotDraft(
    academicSessionId: academicSessionId,
    programId: programId,
    programName: programId,
    departmentId: 'elektrik',
    classId: classId,
    subjectId: '${programId}_$subjectCode',
    subjectCode: subjectCode,
    subjectName: 'Subject $subjectCode',
    lecturerId: lecturerId,
    lecturerEmail: lecturerEmail,
    lecturerName: lecturerName,
    lecturerProfileId: null,
    roomId: roomId,
    roomName: roomName,
    dayOfWeek: dayOfWeek,
    startTime: startTime,
    endTime: endTime,
    weekStart: weekStart,
    weekEnd: weekEnd,
    status: 'active',
    remarks: null,
  );
  return TimetablePreviewRow(
    rowNumber: rowNumber,
    status: status,
    errors: status == TimetableImportRowStatus.error
        ? const ['Program luar skop']
        : const [],
    warnings: const [],
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

TimetableMasterValidationResult _preview(
  List<TimetablePreviewRow> rows, {
  List<String> validationErrors = const [],
}) {
  return TimetableMasterValidationResult(
    totalRows: rows.length,
    validRows: rows
        .where((row) => row.status == TimetableImportRowStatus.valid)
        .length,
    warningRows: 0,
    duplicateRows: 0,
    errorRows: rows
        .where((row) => row.status == TimetableImportRowStatus.error)
        .length,
    subjectUpsertDrafts: const [],
    classCreateDrafts: const [],
    previewRows: rows,
    validationErrors: validationErrors,
    validationWarnings: const [],
  );
}

TimetableSlot _existingSlot({
  String id = 'slot_existing',
  String classId = 'DED 1A',
  String lecturerId = 'LECT_A',
  String roomId = 'ROOM_A',
  String day = 'Isnin',
  String startTime = '08:00',
  String endTime = '10:00',
  String status = 'active',
  bool isOfficial = true,
}) {
  return TimetableSlot(
    id: id,
    academicSessionId: 'JAN_JUN_2026',
    programId: 'DED',
    classId: classId,
    session: 'JAN_JUN_2026',
    semester: 1,
    program: 'DED',
    section: classId,
    subjectCode: 'DED10044',
    subjectName: 'Existing Subject',
    lecturerId: lecturerId,
    lecturerName: 'Lecturer A',
    lecturerEmail: 'lecturer.a@tvetmara.edu.my',
    roomId: roomId,
    roomName: roomId,
    day: day,
    date: '1',
    dayOfWeek: day,
    startTime: startTime,
    endTime: endTime,
    weekStart: '1',
    weekEnd: '18',
    room: roomId,
    enrolled: 0,
    capacity: 0,
    classType: 'Imported',
    slotType: 'Kelas Biasa',
    status: status,
    isOfficial: isOfficial,
  );
}

void main() {
  const service = TimetablePreviewConflictService();

  test('clean preview has no conflicts and can be official', () {
    final summary = service.detect(
      preview: _preview([
        _row(rowNumber: 2),
        _row(
          rowNumber: 3,
          classId: 'DED 1B',
          lecturerId: 'LECT_B',
          lecturerEmail: 'lecturer.b@tvetmara.edu.my',
          roomId: 'ROOM_B',
        ),
      ]),
      existingSlots: const [],
    );

    expect(summary.total, 0);
  });

  test('conflict preview detects class and lecturer conflicts only', () {
    final summary = service.detect(
      preview: _preview([
        _row(rowNumber: 2, classId: 'DED 1A', lecturerId: 'LECT_A'),
        _row(
          rowNumber: 3,
          classId: 'DED 1A',
          lecturerId: 'LECT_B',
          lecturerEmail: 'lecturer.b@tvetmara.edu.my',
          roomId: 'ROOM_B',
        ),
        _row(
          rowNumber: 4,
          classId: 'DCP 1A',
          lecturerId: 'LECT_C',
          lecturerEmail: 'lecturer.c@tvetmara.edu.my',
          roomId: 'ROOM_C',
          startTime: '10:00',
          endTime: '12:00',
        ),
        _row(
          rowNumber: 5,
          classId: 'DCP 2A',
          lecturerId: 'LECT_C',
          lecturerEmail: 'lecturer.c@tvetmara.edu.my',
          roomId: 'ROOM_D',
          startTime: '10:00',
          endTime: '12:00',
        ),
      ]),
      existingSlots: const [],
    );

    expect(summary.roomConflicts, 0);
    expect(summary.lecturerConflicts, 1);
    expect(summary.classConflicts, 1);
    expect(summary.hasConflicts, isTrue);
  });

  test('critical preview skips conflict detection', () {
    final summary = service.detect(
      preview: _preview(
        [
          _row(rowNumber: 2),
          _row(rowNumber: 3, status: TimetableImportRowStatus.error),
        ],
        validationErrors: const ['Ralat kritikal'],
      ),
      existingSlots: const [],
    );

    expect(summary.total, 0);
  });

  test('preview conflicts with existing official active slot only', () {
    final summary = service.detect(
      preview: _preview([
        _row(rowNumber: 2),
      ]),
      existingSlots: [
        _existingSlot(),
        _existingSlot(id: 'draft_slot', isOfficial: false),
        _existingSlot(id: 'inactive_slot', status: 'inactive'),
      ],
    );

    expect(summary.roomConflicts, 1);
    expect(summary.lecturerConflicts, 1);
    expect(summary.classConflicts, 1);
    expect(summary.conflicts.every((conflict) => conflict.involvesExistingSlot),
        isTrue);
  });

  test('publishing draft slot metadata makes it official', () {
    final draft = _existingSlot(
      id: 'draft_slot',
      status: 'draft',
      isOfficial: false,
    ).copyWith(
      importStatus: 'conflict_pending',
      hasConflict: true,
      conflictTypes: const ['class'],
    );

    final published = draft.copyWith(
      status: 'active',
      importStatus: 'official',
      isOfficial: true,
      hasConflict: false,
      conflictTypes: const [],
    );

    expect(published.status, 'active');
    expect(published.importStatus, 'official');
    expect(published.isOfficial, isTrue);
    expect(published.hasConflict, isFalse);
    expect(published.conflictTypes, isEmpty);
  });
}
