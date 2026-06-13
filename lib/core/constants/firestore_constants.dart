class AppRoles {
  const AppRoles._();

  static const pentadbir = 'pentadbir';
  static const ketuaProgram = 'ketua_program';
  static const ketuaJabatan = 'ketua_jabatan';
  static const pensyarah = 'pensyarah';
}

class FirestoreCollections {
  const FirestoreCollections._();

  static const users = 'users';
  static const programs = 'programs';
  static const departments = 'departments';
  static const students = 'students';
  static const rooms = 'rooms';
  static const subjects = 'subjects';
  static const classes = 'classes';
  static const academicSessions = 'academic_sessions';
  static const lecturerCourseAssignments = 'lecturer_course_assignments';
  static const timetableSlots = 'timetable_slots';
  static const timetableUploads = 'timetable_uploads';
  static const attendanceSessions = 'attendance_sessions';
  static const attendanceRecords = 'attendance_records';
  static const disciplineReports = 'discipline_reports';
  static const bookingRequests = 'booking_requests';
  static const notifications = 'notifications';

  // Temporary legacy collection names kept for modules outside Phase 1.
  static const legacyBookings = 'bookings';
}

class UserFields {
  const UserFields._();

  static const uid = 'uid';
  static const name = 'name';
  static const email = 'email';
  static const role = 'role';
  static const programId = 'programId';
  static const departmentId = 'departmentId';
  static const phoneNumber = 'phoneNumber';
  static const lecturerProfileId = 'lecturerProfileId';
  static const isActive = 'isActive';
  static const createdAt = 'createdAt';
  static const updatedAt = 'updatedAt';
}
