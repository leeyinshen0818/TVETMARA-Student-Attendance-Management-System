import 'package:flutter_test/flutter_test.dart';
import 'package:tvetmara_student_attendance/core/constants/timetable_template.dart';
import 'package:tvetmara_student_attendance/models/timetable_import_result.dart';
import 'package:tvetmara_student_attendance/services/timetable_import_service.dart';

const _header =
    'academicSessionId,programId,programName,classId,subjectCode,subjectName,subjectId,lecturerEmail,lecturerName,roomId,roomName,dayOfWeek,startTime,endTime,weekStart,weekEnd,status,remarks';

String _row({
  String academicSessionId = '2026_S1',
  String programId = 'DED',
  String programName = 'DIPLOMA TEKNOLOGI KEJURUTERAAN ELEKTRIK (DED)',
  String classId = 'DED_1A',
  String subjectCode = 'DED10044',
  String subjectName = 'Wiring and Installation Practice',
  String subjectId = 'DED_DED10044',
  String lecturerEmail = 'pensyarah_ded@tvetmara.edu.my',
  String lecturerName = 'Pensyarah DED',
  String roomId = 'BILIK_KULIAH_1',
  String roomName = 'BILIK KULIAH 1',
  String dayOfWeek = 'Isnin',
  String startTime = '08:00',
  String endTime = '10:00',
  String weekStart = '1',
  String weekEnd = '18',
  String status = 'active',
  String remarks = '',
}) {
  return [
    academicSessionId,
    programId,
    programName,
    classId,
    subjectCode,
    subjectName,
    subjectId,
    lecturerEmail,
    lecturerName,
    roomId,
    roomName,
    dayOfWeek,
    startTime,
    endTime,
    weekStart,
    weekEnd,
    status,
    remarks,
  ].join(',');
}

void main() {
  const service = TimetableImportService();

  test('CSV template default academic session matches seeded session id', () {
    expect(TimetableCsvTemplate.defaultAcademicSessionId, 'JAN_JUN_2026');
  });

  test('parses a valid CSV row', () {
    final result = service.parseAndValidate('$_header\n${_row()}');

    expect(result.validationErrors, isEmpty);
    expect(result.totalRows, 1);
    expect(result.validRows, 1);
    expect(result.warningRows, 0);
    expect(result.errorRows, 0);
    expect(result.duplicateRows, 0);

    final draft = result.parsedRows.single.draft!;
    expect(draft.academicSessionId, '2026_S1');
    expect(draft.programId, 'DED');
    expect(draft.subjectId, 'DED_DED10044');
    expect(draft.lecturerEmail, 'pensyarah_ded@tvetmara.edu.my');
    expect(draft.dayOfWeek, 'Isnin');
    expect(draft.weekStart, 1);
    expect(draft.weekEnd, 18);
    expect(draft.status, 'active');
  });

  test('normalizes full programme label in programId column', () {
    final result = service.parseAndValidate(
      '$_header\n${_row(programId: 'DIPLOMA KOMPETENSI ELEKTRIK (KUASA) (DCP)')}',
    );

    expect(result.validationErrors, isEmpty);
    expect(result.parsedRows.single.draft!.programId, 'DCP');
  });

  test('reports missing required header as a file-level error', () {
    final result = service.parseAndValidate(
      'academicSessionId,programId,classId\n2026_S1,DED,DED_1A',
    );

    expect(
        result.validationErrors.single, contains('Missing required columns'));
    expect(result.parsedRows, isEmpty);
  });

  test('matches headers case-insensitively and trims column names', () {
    const header =
        ' AcademicSessionId , PROGRAMID , programName , classId , subjectCode , subjectName , subjectId , lecturerEmail , lecturerName , roomId , roomName , dayOfWeek , startTime , endTime , weekStart , weekEnd , status , remarks ';
    final result = service.parseAndValidate('$header\n${_row()}');

    expect(result.validationErrors, isEmpty);
    expect(result.validRows, 1);
  });

  test('reports empty required fields', () {
    final result = service.parseAndValidate(
      '$_header\n${_row(
        academicSessionId: '',
        programId: '',
        classId: '',
        subjectCode: '',
        subjectName: '',
        lecturerEmail: '',
        roomId: '',
      )}',
    );

    expect(result.errorRows, 1);
    expect(result.parsedRows.single.errors,
        contains('academicSessionId is required.'));
    expect(result.parsedRows.single.errors, contains('programId is required.'));
    expect(result.parsedRows.single.errors, contains('classId is required.'));
    expect(
        result.parsedRows.single.errors, contains('subjectCode is required.'));
    expect(
        result.parsedRows.single.errors, contains('subjectName is required.'));
    expect(result.parsedRows.single.errors,
        contains('lecturerEmail is required.'));
    expect(result.parsedRows.single.errors, contains('roomId is required.'));
  });

  test('reports invalid lecturerEmail', () {
    final result = service.parseAndValidate(
      '$_header\n${_row(lecturerEmail: 'not-an-email')}',
    );

    expect(result.errorRows, 1);
    expect(result.parsedRows.single.errors,
        contains('lecturerEmail must be a valid email address.'));
  });

  test('reports invalid dayOfWeek', () {
    final result = service.parseAndValidate(
      '$_header\n${_row(dayOfWeek: 'Monday')}',
    );

    expect(result.errorRows, 1);
    expect(result.parsedRows.single.errors.single, contains('dayOfWeek'));
  });

  test('reports invalid time format', () {
    final result = service.parseAndValidate(
      '$_header\n${_row(startTime: '8:00')}',
    );

    expect(result.errorRows, 1);
    expect(result.parsedRows.single.errors,
        contains('startTime must use HH:mm format.'));
  });

  test('reports startTime after endTime', () {
    final result = service.parseAndValidate(
      '$_header\n${_row(startTime: '12:00', endTime: '10:00')}',
    );

    expect(result.errorRows, 1);
    expect(result.parsedRows.single.errors,
        contains('startTime must be before endTime.'));
  });

  test('reports invalid week range', () {
    final result = service.parseAndValidate(
      '$_header\n${_row(weekStart: '0', weekEnd: '19')}',
    );

    expect(result.errorRows, 1);
    expect(result.parsedRows.single.errors,
        contains('weekStart must be 1 or higher.'));
    expect(result.parsedRows.single.errors,
        contains('weekEnd must be 18 or lower.'));
  });

  test('reports invalid status', () {
    final result = service.parseAndValidate(
      '$_header\n${_row(status: 'draft')}',
    );

    expect(result.errorRows, 1);
    expect(result.parsedRows.single.errors.single, contains('status'));
  });

  test('detects duplicate rows within one CSV file', () {
    final result = service.parseAndValidate(
      '$_header\n${_row()}\n${_row()}',
    );

    expect(result.validRows, 1);
    expect(result.duplicateRows, 1);
    expect(result.parsedRows.last.status, TimetableImportRowStatus.duplicate);
    expect(result.parsedRows.last.errors.single, contains('row 2'));
  });

  test('allows blank optional fields and generates subjectId', () {
    final result = service.parseAndValidate(
      '$_header\n${_row(
        subjectId: '',
        lecturerName: '',
        roomName: '',
        status: '',
        remarks: '',
      )}',
    );

    expect(result.errorRows, 0);
    expect(result.warningRows, 1);
    final draft = result.parsedRows.single.draft!;
    expect(draft.subjectId, 'DED_DED10044');
    expect(draft.lecturerName, isNull);
    expect(draft.roomName, isNull);
    expect(draft.status, 'active');
  });

  test('blank subjectId uses safe normalized subject code', () {
    final result = service.parseAndValidate(
      '$_header\n${_row(
        programId: 'DGS',
        subjectCode: 'CUB2/31022',
        subjectName: 'E-TECHNOPRENEUR 2',
        subjectId: '',
      )}',
    );

    expect(result.errorRows, 0);
    expect(result.parsedRows.single.draft!.subjectId, 'DGS_CUB2_31022');
  });
}
