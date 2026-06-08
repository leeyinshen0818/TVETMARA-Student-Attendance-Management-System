import 'package:flutter_test/flutter_test.dart';
import 'package:tvetmara_student_attendance/data/mock_data.dart' as mock;
import 'package:tvetmara_student_attendance/services/timetable_view_export_service.dart';

void main() {
  setUpAll(mock.initializeMockData);

  test('class timetable filter returns selected class rows only', () {
    final rows = filterClassTimetableSlots(
      mock.timetable,
      programId: 'DED',
      classId: 'DED 1A',
      academicSessionId: 'JAN_JUN_2026',
    );

    expect(rows, isNotEmpty);
    expect(rows.every((slot) => slot.programId == 'DED'), isTrue);
    expect(rows.every((slot) => (slot.classId ?? slot.section) == 'DED 1A'),
        isTrue);
    expect(
      rows.every(
          (slot) => (slot.academicSessionId ?? slot.session) == 'JAN_JUN_2026'),
      isTrue,
    );
  });

  test('class timetable CSV includes official metadata and selected rows', () {
    final rows = filterClassTimetableSlots(
      mock.timetable,
      programId: 'DGS',
      classId: 'DGS 1A',
      academicSessionId: 'JAN_JUN_2026',
    );

    final csv = buildClassTimetableCsv(
      programId: 'DGS',
      programName: 'DIPLOMA TEKNOLOGI KEJURUTERAAN GAS (DGS)',
      classId: 'DGS 1A',
      academicSessionId: 'JAN_JUN_2026',
      generatedBy: 'KP DGS',
      generatedAt: DateTime(2026, 6, 8),
      slots: rows,
    );

    expect(csv, contains('JADUAL WAKTU KELAS'));
    expect(csv, contains('DGS 1A'));
    expect(csv, contains('JAN_JUN_2026'));
    expect(csv, isNot(contains('DED 1A')));
  });
}
