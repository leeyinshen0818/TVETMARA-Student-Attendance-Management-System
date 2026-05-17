import 'package:flutter/foundation.dart';

import '../data/mock_data.dart' as mock;
import '../models/app_models.dart';

class AppState extends ChangeNotifier {
  AppUser? currentUser;
  final users = List<AppUser>.from(mock.users);
  final students = List<Student>.from(mock.students);
  final lecturers = List<Lecturer>.from(mock.lecturers);
  final timetable = List<TimetableSlot>.from(mock.timetable);
  final disciplineReports = List<DisciplineReport>.from(mock.disciplineReports);
  final bookings = List<BookingRequest>.from(mock.bookings);
  final attendance = <String, List<AttendanceRecord>>{};

  int attendanceThreshold = 80;
  bool mcAsPresent = true;
  bool ckAsPresent = true;
  String session = '2025/2026';
  int semester = 2;

  AppState() {
    for (final slot in timetable.where((slot) => slot.status == 'Attendance Completed')) {
      attendance[slot.id] = mock.attendanceForSlot(slot);
    }
  }

  bool login(String email) {
    final normalized = email.toLowerCase().trim();
    final user = users.where((item) => item.email.toLowerCase() == normalized).firstOrNull;
    if (user == null) return false;
    currentUser = user;
    notifyListeners();
    return true;
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }

  List<TimetableSlot> get scopedTimetable {
    final user = currentUser;
    if (user?.role == UserRole.lecturer) {
      return timetable.where((slot) => slot.lecturerId == user!.id).toList();
    }
    return timetable;
  }

  List<Student> get scopedStudents {
    final user = currentUser;
    if (user?.role != UserRole.lecturer) return students;
    final sections = scopedTimetable.map((slot) => slot.section).toSet();
    return students.where((student) => sections.contains(student.section)).toList();
  }

  void saveAttendance(String slotId, List<AttendanceRecord> records) {
    attendance[slotId] = records;
    final index = timetable.indexWhere((slot) => slot.id == slotId);
    if (index != -1) timetable[index] = timetable[index].copyWith(status: 'Attendance Completed');
    notifyListeners();
  }

  void addDiscipline(DisciplineReport report) {
    disciplineReports.insert(0, report);
    notifyListeners();
  }

  void updateDiscipline(String id, String status) {
    final index = disciplineReports.indexWhere((report) => report.id == id);
    if (index != -1) disciplineReports[index] = disciplineReports[index].copyWith(status: status);
    notifyListeners();
  }

  void addBooking(BookingRequest booking) {
    bookings.insert(0, booking);
    notifyListeners();
  }

  void updateBooking(String id, String status) {
    final index = bookings.indexWhere((booking) => booking.id == id);
    if (index == -1) return;
    bookings[index] = bookings[index].copyWith(status: status);
    if (status == 'Approved') {
      final booking = bookings[index];
      final source = timetable.where((slot) => slot.section == booking.section).firstOrNull;
      timetable.add(
        TimetableSlot(
          id: 'T${DateTime.now().millisecondsSinceEpoch}',
          session: session,
          semester: semester,
          program: source?.program ?? '',
          section: booking.section,
          subjectCode: source?.subjectCode ?? 'REP',
          subjectName: booking.subject,
          lecturerId: booking.lecturerId,
          lecturerName: booking.lecturerName,
          day: 'Replacement',
          date: booking.replacementDate,
          startTime: booking.replacementStart,
          endTime: booking.replacementEnd,
          room: booking.room,
          enrolled: source?.enrolled ?? 0,
          capacity: source?.capacity ?? 0,
          classType: source?.classType ?? 'Theory',
          slotType: 'Replacement Class',
          status: 'Upcoming',
        ),
      );
    }
    notifyListeners();
  }

  void updateAttendanceThreshold(int value) {
    attendanceThreshold = value;
    notifyListeners();
  }

  void updateSemester(int value) {
    semester = value;
    notifyListeners();
  }

  void updateMcAsPresent(bool value) {
    mcAsPresent = value;
    notifyListeners();
  }

  void updateCkAsPresent(bool value) {
    ckAsPresent = value;
    notifyListeners();
  }
}
