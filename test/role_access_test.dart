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
  test('Ketua Jabatan sees department data, discipline, and bookings', () {
    final state = _stateFor(_user('kj_elektrik@tvetmara.edu.my'));
    final electricProgramIds = mock.programs
        .where((program) => program.departmentId == 'elektrik')
        .map((program) => program.id)
        .toSet();

    expect(state.scopedTimetable, isNotEmpty);
    expect(state.scopedPrograms.map((program) => program.id),
        containsAll(['DED', 'DCP', 'DCB']));
    expect(
      state.scopedTimetable
          .every((slot) => electricProgramIds.contains(slot.programId)),
      isTrue,
    );
    expect(state.scopedTimetable.map((slot) => slot.programId),
        isNot(contains('DGS')));
    expect(state.scopedDisciplineReports.map((report) => report.id),
        contains('D001'));
    expect(state.scopedBookings.map((booking) => booking.id),
        containsAll(['B001', 'B002', 'B003']));
    expect(state.scopedBookings.map((booking) => booking.id),
        isNot(contains('B004')));
  });

  test('Ketua Jabatan booking scope follows own department only', () {
    final mekanikal = _stateFor(_user('kj_mekanikal@tvetmara.edu.my'));
    final automotif = _stateFor(_user('kj_automotif@tvetmara.edu.my'));

    expect(mekanikal.scopedBookings.map((booking) => booking.id),
        contains('B005'));
    expect(mekanikal.scopedBookings.map((booking) => booking.id),
        isNot(contains('B001')));
    expect(mekanikal.scopedBookings.map((booking) => booking.id),
        isNot(contains('B004')));
    expect(mekanikal.scopedBookings.map((booking) => booking.id),
        isNot(contains('B006')));

    expect(automotif.scopedBookings.map((booking) => booking.id),
        contains('B006'));
    expect(automotif.scopedBookings.map((booking) => booking.id),
        isNot(contains('B001')));
    expect(automotif.scopedBookings.map((booking) => booking.id),
        isNot(contains('B004')));
    expect(automotif.scopedBookings.map((booking) => booking.id),
        isNot(contains('B005')));
  });

  test('Ketua Jabatan scoped programmes follow client hierarchy', () {
    final elektrik = _stateFor(_user('kj_elektrik@tvetmara.edu.my'));
    final mekanikal = _stateFor(_user('kj_mekanikal@tvetmara.edu.my'));
    final automotif = _stateFor(_user('kj_automotif@tvetmara.edu.my'));

    expect(elektrik.scopedPrograms.map((program) => program.id).toSet(),
        equals({'DED', 'DCP', 'DCB'}));
    expect(mekanikal.scopedPrograms.map((program) => program.id).toSet(),
        equals({'ITW', 'SLR', 'SMI'}));
    expect(automotif.scopedPrograms.map((program) => program.id).toSet(),
        equals({'IMF', 'SMM', 'DMM'}));
  });

  test('Ketua Program sees own program data, bookings, and discipline', () {
    final state = _stateFor(_user('kp_ded@tvetmara.edu.my'));

    expect(state.currentProgramHasKetuaJabatan, isTrue);
    expect(state.currentKetuaProgramInheritsKetuaJabatanTasks, isFalse);
    expect(state.scopedPrograms.map((program) => program.id), ['DED']);
    expect(state.scopedStudents, isNotEmpty);
    expect(
      state.scopedStudents
          .every((student) => student.section.startsWith('DED')),
      isTrue,
    );
    expect(
      state.scopedTimetable.every((slot) => slot.programId == 'DED'),
      isTrue,
    );
    expect(state.scopedBookings.map((booking) => booking.id), contains('B001'));
    expect(state.scopedDisciplineReports.map((report) => report.id),
        contains('D001'));
    expect(state.scopedBookings.map((booking) => booking.id),
        isNot(contains('B003')));
  });

  test(
      'Ketua Program without Ketua Jabatan inherits timetable and discipline scope',
      () {
    final state = _stateFor(_user('kp_dgs@tvetmara.edu.my'));

    expect(state.currentProgramHasKetuaJabatan, isFalse);
    expect(state.currentKetuaProgramInheritsKetuaJabatanTasks, isTrue);
    expect(state.scopedPrograms.map((program) => program.id), ['DGS']);
    expect(state.scopedTimetable, isNotEmpty);
    expect(
      state.scopedTimetable.every((slot) => slot.programId == 'DGS'),
      isTrue,
    );
    expect(state.scopedStudents, isNotEmpty);
    expect(
      state.scopedStudents
          .every((student) => student.section.startsWith('DGS')),
      isTrue,
    );
    expect(state.scopedBookings.map((booking) => booking.id), contains('B004'));
    expect(state.scopedBookings.map((booking) => booking.id),
        isNot(contains('B001')));
    expect(state.scopedDisciplineReports.map((report) => report.id),
        contains('D002'));
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
    final taughtSections =
        state.scopedTimetable.map((slot) => slot.section).toSet();
    expect(
      state.scopedStudents
          .every((student) => taughtSections.contains(student.section)),
      isTrue,
    );
  });

  test('real lecturer login sees assigned slots by email/profile identity', () {
    final state = _stateFor(_user('lecturer046@tvetmara.edu.my'));

    expect(state.currentUser!.lecturerProfileId, 'REAL_L_046');
    expect(state.scopedTimetable, isNotEmpty);
    expect(
      state.scopedTimetable.every((slot) =>
          slot.lecturerId == 'REAL_L_046' ||
          slot.lecturerEmail == 'lecturer046@tvetmara.edu.my' ||
          slot.lecturerProfileId == 'REAL_L_046'),
      isTrue,
    );
  });

  test('pensyarah scope does not fall back to whole programme', () {
    final state = _stateFor(const AppUser(
      uid: 'UNASSIGNED_DED',
      name: 'Unassigned Lecturer',
      email: 'unassigned@tvetmara.edu.my',
      role: UserRole.pensyarah,
      programId: 'DED',
      departmentId: 'elektrik',
      isActive: true,
    ));

    expect(state.scopedTimetable, isEmpty);
  });

  test(
      'Pentadbir sees all student and lecturer records but no operational scope',
      () {
    final state = _stateFor(_user('admin@tvetmara.edu.my'));

    expect(state.scopedStudents.length, mock.students.length);
    expect(state.scopedPrograms.length, mock.programs.length);
    expect(state.scopedTimetable, isEmpty);
    expect(state.scopedBookings, isEmpty);
  });

  test('academic session management is restricted to pentadbir', () {
    expect(_stateFor(_user('admin@tvetmara.edu.my')).canManageAcademicSessions,
        isTrue);
    expect(
        _stateFor(_user('kj_elektrik@tvetmara.edu.my'))
            .canManageAcademicSessions,
        isFalse);
    expect(_stateFor(_user('kp_dgs@tvetmara.edu.my')).canManageAcademicSessions,
        isFalse);
    expect(_stateFor(_user('kp_ded@tvetmara.edu.my')).canManageAcademicSessions,
        isFalse);
    expect(
        _stateFor(_user('pensyarah_ded@tvetmara.edu.my'))
            .canManageAcademicSessions,
        isFalse);
  });
}
