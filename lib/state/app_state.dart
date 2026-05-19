import 'package:flutter/foundation.dart';

import '../data/mock_data.dart' as mock;
import '../models/app_models.dart';

class AppState extends ChangeNotifier {
  AppUser? currentUser;
  final users = List<AppUser>.from(mock.users);
  final students = List<Student>.from(mock.students);
  final lecturers = List<Lecturer>.from(mock.lecturers);
  final roomResources = List<RoomResource>.from(mock.roomResources);
  final timetable = List<TimetableSlot>.from(mock.timetable);
  final disciplineReports = List<DisciplineReport>.from(mock.disciplineReports);
  final bookings = List<BookingRequest>.from(mock.bookings);
  final attendance = <String, List<AttendanceRecord>>{};

  int attendanceThreshold = 80;
  String reportFrequency = 'Weekly';
  String session = 'Jan - Jun 2026';
  int semester = 2;

  AppState() {
    for (final slot
        in timetable.where((slot) => slot.status == 'Attendance Completed')) {
      attendance[slot.id] = mock.attendanceForSlot(slot);
    }
  }

  bool login(String email) {
    final normalized = email.toLowerCase().trim();
    final user = users
        .where((item) => item.email.toLowerCase() == normalized)
        .firstOrNull;
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
    return students
        .where((student) => sections.contains(student.section))
        .toList();
  }

  void saveAttendance(String slotId, List<AttendanceRecord> records) {
    attendance[slotId] = records;
    final index = timetable.indexWhere((slot) => slot.id == slotId);
    if (index != -1) {
      timetable[index] =
          timetable[index].copyWith(status: 'Attendance Completed');
    }
    notifyListeners();
  }

  void addDiscipline(DisciplineReport report) {
    disciplineReports.insert(0, report);
    notifyListeners();
  }

  void updateDiscipline(String id, String status) {
    final index = disciplineReports.indexWhere((report) => report.id == id);
    if (index != -1) {
      disciplineReports[index] =
          disciplineReports[index].copyWith(status: status);
    }
    notifyListeners();
  }

  void addBooking(BookingRequest booking) {
    if (!isRoomAvailable(
      room: booking.room,
      date: booking.replacementDate,
      start: booking.replacementStart,
      end: booking.replacementEnd,
      ignoreBookingId: booking.id,
    )) {
      return;
    }
    bookings.insert(0, booking);
    notifyListeners();
  }

  void updateBooking(String id, String status) {
    final index = bookings.indexWhere((booking) => booking.id == id);
    if (index == -1) return;
    bookings[index] = bookings[index].copyWith(status: status);
    if (status == 'Approved') {
      final booking = bookings[index];
      if (!isRoomAvailable(
        room: booking.room,
        date: booking.replacementDate,
        start: booking.replacementStart,
        end: booking.replacementEnd,
        ignoreBookingId: booking.id,
      )) {
        bookings[index] = booking.copyWith(status: 'Rejected');
        notifyListeners();
        return;
      }
      final source = timetable
          .where((slot) => slot.section == booking.section)
          .firstOrNull;
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
          day: 'Ganti',
          date: booking.replacementDate,
          startTime: booking.replacementStart,
          endTime: booking.replacementEnd,
          room: booking.room,
          enrolled: source?.enrolled ?? 0,
          capacity: source?.capacity ?? 0,
          classType: source?.classType ?? 'Teori',
          slotType: 'Kelas Ganti',
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

  void updateReportFrequency(String value) {
    reportFrequency = value;
    notifyListeners();
  }

  AttendanceSummary attendanceSummaryForStudent(Student student) {
    const historicalDenominator = 10;
    final historicalAttended =
        ((student.attendance / 100) * historicalDenominator).round();
    var summary = AttendanceSummary(
      present: historicalAttended,
      late: 0,
      absent: historicalDenominator - historicalAttended,
      mc: 0,
      ck: 0,
    );

    for (final records in attendance.values) {
      for (final record
          in records.where((record) => record.studentId == student.id)) {
        summary = summary.add(record.status);
      }
    }
    return summary;
  }

  int attendancePercentageForStudent(Student student) {
    return attendanceSummaryForStudent(student).percentage;
  }

  String attendanceRiskForStudent(Student student) {
    final percentage = attendancePercentageForStudent(student);
    if (percentage >= attendanceThreshold) return 'Safe';
    if (percentage >= 75) return 'Warning';
    return 'Critical';
  }

  List<Student> get criticalStudents {
    return scopedStudents
        .where((student) =>
            attendancePercentageForStudent(student) < attendanceThreshold)
        .toList();
  }

  bool isRoomAvailable({
    required String room,
    required String date,
    required String start,
    required String end,
    String? ignoreBookingId,
  }) {
    final matchingSlots =
        timetable.where((slot) => slot.room == room && slot.date == date);
    for (final slot in matchingSlots) {
      if (_timesOverlap(start, end, slot.startTime, slot.endTime)) return false;
    }

    final approvedBookings = bookings.where(
      (booking) =>
          booking.id != ignoreBookingId &&
          booking.status == 'Approved' &&
          booking.room == room &&
          booking.replacementDate == date,
    );
    for (final booking in approvedBookings) {
      if (_timesOverlap(
          start, end, booking.replacementStart, booking.replacementEnd)) {
        return false;
      }
    }
    return true;
  }

  bool _timesOverlap(String startA, String endA, String startB, String endB) {
    final aStart = _minutes(startA);
    final aEnd = _minutes(endA);
    final bStart = _minutes(startB);
    final bEnd = _minutes(endB);
    return aStart < bEnd && bStart < aEnd;
  }

  int _minutes(String text) {
    final parts = text.split(':');
    if (parts.length != 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }
}
