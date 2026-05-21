import 'package:flutter/foundation.dart';

import '../models/app_models.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AppState extends ChangeNotifier {
  AppUser? currentUser;
  List<AppUser> users = [];
  List<Student> students = [];
  List<Lecturer> lecturers = [];
  List<RoomResource> roomResources = [];
  List<TimetableSlot> timetable = [];
  List<DisciplineReport> disciplineReports = [];
  List<BookingRequest> bookings = [];
  final attendance = <String, List<AttendanceRecord>>{};

  List<ProgramCode> programs = [];
  List<Department> departments = [];

  int attendanceThreshold = 80;
  String reportFrequency = 'Weekly';
  String session = 'Jan - Jun 2026';
  int semester = 2;

  bool _loading = true;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  final _fs = FirestoreService.instance;

  /// Load all data from Firestore.
  /// Call once after Firebase is initialised and the user is authenticated.
  Future<void> loadData() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _fs.getUsers(),
        _fs.getStudents(),
        _fs.getLecturers(),
        _fs.getRoomResources(),
        _fs.getTimetableSlots(),
        _fs.getDisciplineReports(),
        _fs.getBookings(),
        _fs.getAllAttendance(),
        _fs.getPrograms(),
        _fs.getDepartments(),
      ]);

      users = results[0] as List<AppUser>;
      students = results[1] as List<Student>;
      lecturers = results[2] as List<Lecturer>;
      roomResources = results[3] as List<RoomResource>;
      timetable = results[4] as List<TimetableSlot>;
      disciplineReports = results[5] as List<DisciplineReport>;
      bookings = results[6] as List<BookingRequest>;

      final attendanceMap = results[7] as Map<String, List<AttendanceRecord>>;
      attendance
        ..clear()
        ..addAll(attendanceMap);

      programs = results[8] as List<ProgramCode>;
      departments = results[9] as List<Department>;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Authenticate with Firebase Auth, then look up the matching AppUser
  /// profile in Firestore by email.
  Future<bool> login(String email, String password) async {
    try {
      await AuthService.instance.signIn(email, password);
      // After Firebase Auth success, fetch the user profile from Firestore
      final appUser = await _fs.getUserByEmail(email);
      if (appUser == null) {
        // Auth succeeded but no profile doc — sign out and fail.
        await AuthService.instance.signOut();
        return false;
      }
      currentUser = appUser;
      await _fs.updateLastLogin(appUser.id);
      await loadData();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void logout() {
    AuthService.instance.signOut();
    currentUser = null;
    notifyListeners();
  }

  List<TimetableSlot> get scopedTimetable {
    final user = currentUser;
    if (user == null || user.role == UserRole.admin) return [];

    if (user.role == UserRole.ketuaJabatan) {
      final deptPrograms = programs
          .where((p) => p.departmentId == user.department)
          .map((p) => p.name)
          .toSet();
      return timetable
          .where((slot) => deptPrograms.contains(slot.program))
          .toList();
    }

    if (user.role == UserRole.ketuaProgram) {
      final kpProgram =
          programs.where((p) => p.id == user.program).firstOrNull?.name;
      if (kpProgram == null) return [];
      return timetable.where((slot) => slot.program == kpProgram).toList();
    }

    // Pensyarah
    return timetable.where((slot) => slot.lecturerId == user.id).toList();
  }

  List<Student> get scopedStudents {
    final user = currentUser;
    if (user == null || user.role == UserRole.admin) return [];

    if (user.role == UserRole.ketuaJabatan) {
      final deptPrograms = programs
          .where((p) => p.departmentId == user.department)
          .map((p) => p.name)
          .toSet();
      return students
          .where((student) => deptPrograms.contains(student.program))
          .toList();
    }

    if (user.role == UserRole.ketuaProgram) {
      final kpProgram =
          programs.where((p) => p.id == user.program).firstOrNull?.name;
      if (kpProgram == null) return [];
      return students.where((student) => student.program == kpProgram).toList();
    }

    // Pensyarah sees only students physically enrolled in sections they teach
    final sections = scopedTimetable.map((slot) => slot.section).toSet();
    return students
        .where((student) => sections.contains(student.section))
        .toList();
  }

  List<DisciplineReport> get scopedDisciplineReports {
    final user = currentUser;
    if (user == null || user.role == UserRole.admin) return [];

    if (user.role == UserRole.ketuaJabatan ||
        user.role == UserRole.ketuaProgram) {
      final validStudents = scopedStudents.map((s) => s.id).toSet();
      return disciplineReports
          .where((r) => validStudents.contains(r.studentId))
          .toList();
    }
    // Pensyarah
    return disciplineReports.where((r) => r.lecturer == user.name).toList();
  }

  List<BookingRequest> get scopedBookings {
    final user = currentUser;
    if (user == null || user.role == UserRole.admin) return [];

    // KJ and KP can see and approve bookings for their scope
    if (user.role == UserRole.ketuaJabatan ||
        user.role == UserRole.ketuaProgram) {
      // Find sections within their scope using timetable
      final validSections = scopedTimetable.map((t) => t.section).toSet();
      return bookings
          .where((b) => validSections.contains(b.section))
          .toList();
    }
    // Pensyarah
    return bookings.where((b) => b.lecturerId == user.id).toList();
  }

  Future<void> saveAttendance(
      String slotId, List<AttendanceRecord> records) async {
    attendance[slotId] = records;
    final index = timetable.indexWhere((slot) => slot.id == slotId);
    if (index != -1) {
      timetable[index] =
          timetable[index].copyWith(status: 'Attendance Completed');
    }
    notifyListeners();

    // Persist to Firestore
    await _fs.saveAttendance(slotId, records);
    await _fs.updateSlotStatus(slotId, 'Attendance Completed');
  }

  Future<void> addDiscipline(DisciplineReport report) async {
    disciplineReports.insert(0, report);
    notifyListeners();
    await _fs.addDisciplineReport(report);
  }

  Future<void> updateDiscipline(String id, String status) async {
    final index = disciplineReports.indexWhere((report) => report.id == id);
    if (index != -1) {
      disciplineReports[index] =
          disciplineReports[index].copyWith(status: status);
    }
    notifyListeners();
    await _fs.updateDisciplineStatus(id, status);
  }

  Future<void> addBooking(BookingRequest booking) async {
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
    await _fs.addBooking(booking);
  }

  Future<void> updateBooking(String id, String status) async {
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
        await _fs.updateBookingStatus(id, 'Rejected');
        return;
      }
      final source = timetable
          .where((slot) => slot.section == booking.section)
          .firstOrNull;
      final newSlot = TimetableSlot(
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
      );
      timetable.add(newSlot);
      await _fs.addTimetableSlot(newSlot);
    }
    notifyListeners();
    await _fs.updateBookingStatus(id, status);
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
