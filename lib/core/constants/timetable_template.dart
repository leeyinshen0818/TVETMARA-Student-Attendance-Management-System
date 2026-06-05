/// CSV is the supported timetable upload format for this phase.
///
/// Excel files are not parsed directly yet. Users may prepare the timetable in
/// Excel, then export or save it as CSV before uploading it to the app.
class TimetableCsvTemplate {
  TimetableCsvTemplate._();

  static const defaultAcademicSessionId = 'JAN_JUN_2026';
  static const defaultAcademicSessionName = 'Jan-Jun 2026';

  static const requiredColumns = [
    'academicSessionId',
    'programId',
    'classId',
    'subjectCode',
    'subjectName',
    'lecturerEmail',
    'roomId',
    'dayOfWeek',
    'startTime',
    'endTime',
    'weekStart',
    'weekEnd',
  ];

  static const optionalColumns = [
    'programName',
    'subjectId',
    'lecturerName',
    'roomName',
    'status',
    'remarks',
  ];

  static const fullHeader = [
    'academicSessionId',
    'programId',
    'programName',
    'classId',
    'subjectCode',
    'subjectName',
    'subjectId',
    'lecturerEmail',
    'lecturerName',
    'roomId',
    'roomName',
    'dayOfWeek',
    'startTime',
    'endTime',
    'weekStart',
    'weekEnd',
    'status',
    'remarks',
  ];

  static const allowedDayOfWeekValues = [
    'Isnin',
    'Selasa',
    'Rabu',
    'Khamis',
    'Jumaat',
    'Sabtu',
    'Ahad',
  ];

  static const allowedStatusValues = [
    'active',
    'inactive',
    'cancelled',
  ];

  static const expectedTimeFormat = 'HH:mm, for example 08:00 or 14:30';
  static const expectedDateFormat = 'YYYY-MM-DD, for example 2026-05-18';
}
