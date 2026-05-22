import 'package:flutter_test/flutter_test.dart';
import 'package:tvetmara_student_attendance/data/mock_data.dart' as mock;
import 'package:tvetmara_student_attendance/models/app_models.dart';
import 'package:tvetmara_student_attendance/state/app_state.dart';

AppState _stateFor(AppUser user) {
  mock.initializeMockData();
  final state = AppState()
    ..currentUser = user
    ..users = List<AppUser>.from(mock.users)
    ..students = List<Student>.from(mock.students)
    ..lecturers = List<Lecturer>.from(mock.lecturers)
    ..roomResources = List<RoomResource>.from(mock.roomResources)
    ..timetable = List<TimetableSlot>.from(mock.timetable)
    ..disciplineReports = List<DisciplineReport>.from(mock.disciplineReports)
    ..bookings = List<BookingRequest>.from(mock.bookings)
    ..programs = List<ProgramCode>.from(mock.programs);
  return state;
}

AppUser _user(String email) {
  return mock.users.firstWhere((user) => user.email == email);
}

void main() {
  test('Ketua Jabatan sees department data and discipline, not bookings', () {
    final state = _stateFor(_user('kj_elektrik@tvetmara.edu.my'));
    final electricPrograms = mock.programs
        .where((program) => program.departmentId == 'elektrik')
        .map((program) => program.name)
        .toSet();

    expect(state.scopedTimetable, isNotEmpty);
    expect(
      state.scopedTimetable
          .every((slot) => electricPrograms.contains(slot.program)),
      isTrue,
    );
    expect(state.scopedDisciplineReports.map((report) => report.id),
        contains('D001'));
    expect(state.scopedBookings, isEmpty);
  });

  test('Ketua Program sees program data and bookings, not discipline', () {
    final state = _stateFor(_user('kp_ded@tvetmara.edu.my'));

    expect(state.currentProgramHasKetuaJabatan, isTrue);
    expect(state.currentKetuaProgramInheritsKetuaJabatanTasks, isFalse);
    expect(state.scopedStudents, isNotEmpty);
    expect(
      state.scopedStudents
          .every((student) => student.section.startsWith('DED')),
      isTrue,
    );
    expect(state.scopedBookings.map((booking) => booking.id), contains('B001'));
    expect(state.scopedDisciplineReports, isEmpty);
  });

  test(
      'Ketua Program without Ketua Jabatan inherits timetable and discipline scope',
      () {
    final state = _stateFor(_user('kp_dgs@tvetmara.edu.my'));

    expect(state.currentProgramHasKetuaJabatan, isFalse);
    expect(state.currentKetuaProgramInheritsKetuaJabatanTasks, isTrue);
    expect(state.scopedTimetable, isNotEmpty);
    expect(
      state.scopedTimetable.every((slot) => slot.section.startsWith('DGS')),
      isTrue,
    );
    expect(state.scopedStudents, isNotEmpty);
    expect(
      state.scopedStudents
          .every((student) => student.section.startsWith('DGS')),
      isTrue,
    );
  });

  test(
      'Pensyarah sees own classes, booking requests, and own discipline reports',
      () {
    final state = _stateFor(_user('pensyarah_ded@tvetmara.edu.my'));

    expect(state.scopedTimetable, isNotEmpty);
    expect(
      state.scopedTimetable.every((slot) => slot.lecturerId == 'L_DED'),
      isTrue,
    );
    expect(state.scopedBookings.map((booking) => booking.id), contains('B001'));
    expect(state.scopedDisciplineReports.map((report) => report.id),
        contains('D001'));
  });
}
