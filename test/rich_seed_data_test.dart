import 'package:flutter_test/flutter_test.dart';
import 'package:tvetmara_student_attendance/data/mock_data.dart' as mock;
import 'package:tvetmara_student_attendance/models/app_models.dart';

void main() {
  setUpAll(mock.initializeMockData);

  test('rich seed creates classes, students, and timetable coverage', () {
    expect(mock.demoClasses.length, 45);
    expect(mock.students.length, 680);
    expect(mock.timetable.length, 119);

    expect(
      mock.demoClasses.map((item) => item.classId),
      containsAll(['DED 1A', 'DGS 1A', 'DED 3A', 'DGS 3A', 'SMI 3A']),
    );
  });

  test('seed includes multiple academic sessions for timetable planning', () {
    expect(
      mock.academicSessions.map((session) => session.academicSessionId),
      containsAll(['JAN_JUN_2026', 'JUL_DEC_2026', 'JAN_JUN_2027']),
    );
    expect(
      mock.academicSessions.every((session) =>
          RegExp(r'^[A-Z0-9_]+$').hasMatch(session.academicSessionId)),
      isTrue,
    );
  });

  test('DED 1A client-inspired slots use real subjects and rooms', () {
    final dedClientSlots = mock.timetable
        .where((slot) => slot.sourceUploadId == 'seed_client_ded_1a')
        .toList();

    expect(dedClientSlots.length, 5);
    expect(
      dedClientSlots.map((slot) => slot.subjectId),
      containsAll([
        'DED_DED10044',
        'DED_DEV10043',
        'DED_DUM10122',
        'DED_DKV10213',
        'DED_DUS10062',
      ]),
    );
    expect(
      dedClientSlots.map((slot) => slot.roomId),
      containsAll(['ELEC MACHINE LAB', 'BILIK KULIAH DED 1', 'PLC LAB']),
    );
  });

  test('generated timetable avoids old fake room ids', () {
    final roomIds = mock.timetable.map((slot) => slot.roomId ?? slot.room);
    expect(roomIds, isNot(contains('BILIK KULIAH 1')));
    expect(roomIds, isNot(contains('BILIK KULIAH 2')));
    expect(roomIds, isNot(contains('BILIK KULIAH 3')));
  });

  test('seed includes intentional conflict demo slots', () {
    final conflictSlots = mock.timetable
        .where((slot) => slot.sourceUploadId == 'seed_conflict_demo')
        .toList();

    expect(conflictSlots.length, 6);
    expect(
      conflictSlots.map((slot) => slot.id),
      containsAll([
        'CONFLICT_ROOM_DED1B',
        'CONFLICT_ROOM_DCP1A',
        'CONFLICT_LECT_DED1A',
        'CONFLICT_LECT_DCP1A',
        'CONFLICT_CLASS_DGS1A_A',
        'CONFLICT_CLASS_DGS1A_B',
      ]),
    );
  });

  test('attendance seed includes present, late, absent, MC, and CK', () {
    final slot = mock.timetable.firstWhere((slot) => slot.section == 'DED 1A');
    final bundles = mock.attendanceBundlesForSlot(slot);

    expect(bundles.length, 4);
    final statuses = bundles
        .expand((bundle) => bundle.records)
        .map((record) => record.status)
        .toSet();

    expect(
      statuses,
      containsAll([
        AttendanceStatus.present,
        AttendanceStatus.late,
        AttendanceStatus.absent,
        AttendanceStatus.mc,
        AttendanceStatus.ck,
      ]),
    );
  });
}
