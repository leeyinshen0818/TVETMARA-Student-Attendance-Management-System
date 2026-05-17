import '../models/app_models.dart';

const programs = [
  'Electrical Installation',
  'Automotive Technology',
  'Computer System Technology',
];

const rooms = [
  'Lab Elektrik 1',
  'Lab Elektrik 2',
  'Bengkel Automotif',
  'Makmal Komputer',
  'Lecture Room A',
  'Lecture Room B',
];

const users = [
  AppUser(
    id: 'U001',
    name: 'Admin TVETMARA',
    email: 'admin@tvetmara.edu.my',
    role: UserRole.admin,
    department: 'Administration',
    active: true,
    lastLogin: '2026-04-29 08:12',
  ),
  AppUser(
    id: 'L001',
    name: 'Encik Ahmad bin Ismail',
    email: 'lecturer@tvetmara.edu.my',
    role: UserRole.lecturer,
    department: 'Electrical',
    active: true,
    lastLogin: '2026-04-29 07:45',
  ),
  AppUser(
    id: 'L003',
    name: 'Encik Razak bin Hamid',
    email: 'razak@tvetmara.edu.my',
    role: UserRole.lecturer,
    department: 'Automotive',
    active: true,
    lastLogin: '2026-04-28 14:00',
  ),
];

const lecturers = [
  Lecturer(id: 'L001', name: 'Encik Ahmad bin Ismail', email: 'ahmad@tvetmara.edu.my', department: 'Electrical', subjects: ['EE101', 'EE103']),
  Lecturer(id: 'L002', name: 'Puan Siti Nurhaliza', email: 'siti@tvetmara.edu.my', department: 'Electrical', subjects: ['EE102', 'EE104']),
  Lecturer(id: 'L003', name: 'Encik Razak bin Hamid', email: 'razak@tvetmara.edu.my', department: 'Automotive', subjects: ['AT201', 'AT202']),
  Lecturer(id: 'L007', name: 'Puan Zarina binti Yusof', email: 'zarina@tvetmara.edu.my', department: 'Computer', subjects: ['CS101', 'CS102']),
];

final students = List<Student>.generate(36, (index) {
  final section = index < 12 ? 'ELI-1A' : index < 24 ? 'AUTO-2A' : 'CST-1A';
  final program = section.startsWith('ELI')
      ? programs[0]
      : section.startsWith('AUTO')
          ? programs[1]
          : programs[2];
  final names = ['Ahmad', 'Aiman', 'Farah', 'Hana', 'Danial', 'Sarah', 'Irfan', 'Nurul'];
  final last = ['Ismail', 'Hassan', 'Rahman', 'Yusof', 'Omar', 'Ali'];
  return Student(
    id: 'S${2026001 + index}',
    name: '${names[index % names.length]} ${index.isEven ? 'bin' : 'binti'} ${last[index % last.length]}',
    email: 'student${index + 1}@student.tvetmara.edu.my',
    phone: '01${index % 9 + 1}-${1000000 + index * 7777}',
    program: program,
    semester: section.startsWith('AUTO') ? 2 : 1,
    section: section,
    attendance: index % 7 == 0 ? 63 + index % 12 : 82 + index % 16,
  );
});

final timetable = <TimetableSlot>[
  _slot('T001', programs[0], 'ELI-1A', 'EE101', 'Electrical Installation Theory', 'L001', 'Encik Ahmad bin Ismail', 'Monday', '2026-04-27', '08:00', '10:00', rooms[4], 'Attendance Not Taken'),
  _slot('T002', programs[0], 'ELI-1A', 'EE103', 'Electrical Supply Act and Regulations', 'L001', 'Encik Ahmad bin Ismail', 'Wednesday', '2026-04-29', '13:30', '15:30', rooms[0], 'Upcoming'),
  _slot('T003', programs[0], 'ELI-1A', 'EE102', 'Electrical Installation Practice', 'L002', 'Puan Siti Nurhaliza', 'Thursday', '2026-04-30', '10:15', '12:15', rooms[1], 'Upcoming'),
  _slot('T004', programs[1], 'AUTO-2A', 'AT201', 'Automotive Service Practice', 'L003', 'Encik Razak bin Hamid', 'Tuesday', '2026-04-28', '10:15', '12:15', rooms[2], 'Ongoing'),
  _slot('T005', programs[1], 'AUTO-2A', 'AT202', 'Vehicle Electrical System', 'L003', 'Encik Razak bin Hamid', 'Friday', '2026-05-01', '08:00', '10:00', rooms[2], 'Upcoming'),
  _slot('T006', programs[2], 'CST-1A', 'CS101', 'Computer Hardware Maintenance', 'L007', 'Puan Zarina binti Yusof', 'Wednesday', '2026-04-29', '08:00', '10:00', rooms[3], 'Attendance Completed'),
];

TimetableSlot _slot(
  String id,
  String program,
  String section,
  String code,
  String subject,
  String lecturerId,
  String lecturerName,
  String day,
  String date,
  String start,
  String end,
  String room,
  String status,
) {
  final enrolled = students.where((student) => student.section == section).length;
  return TimetableSlot(
    id: id,
    session: '2025/2026',
    semester: section.startsWith('AUTO') ? 2 : 1,
    program: program,
    section: section,
    subjectCode: code,
    subjectName: subject,
    lecturerId: lecturerId,
    lecturerName: lecturerName,
    day: day,
    date: date,
    startTime: start,
    endTime: end,
    room: room,
    enrolled: enrolled,
    capacity: enrolled + 4,
    classType: code.endsWith('02') || code.endsWith('201') ? 'Practical' : 'Theory',
    slotType: 'Normal Class',
    status: status,
  );
}

final disciplineReports = [
  DisciplineReport(
    id: 'D001',
    studentId: students[3].id,
    studentName: students[3].name,
    section: students[3].section,
    subject: 'Electrical Installation Theory',
    lecturer: 'Encik Ahmad bin Ismail',
    date: '2026-04-22',
    issueType: 'Frequent Absence',
    severity: 'High',
    description: 'Student absent for 5 consecutive sessions without notice.',
    followUp: true,
    status: 'Under Review',
  ),
];

final bookings = [
  BookingRequest(
    id: 'B001',
    lecturerId: 'L001',
    lecturerName: 'Encik Ahmad bin Ismail',
    subject: 'Electrical Installation Theory',
    section: 'ELI-1A',
    originalDate: '2026-04-22',
    originalTime: '08:00 - 10:00',
    replacementDate: '2026-05-03',
    replacementStart: '14:00',
    replacementEnd: '16:00',
    room: 'Lecture Room A',
    reason: 'Public holiday',
    remarks: 'Replacement for holiday.',
    status: 'Pending',
  ),
];

List<AttendanceRecord> attendanceForSlot(TimetableSlot slot) {
  final sectionStudents = students.where((student) => student.section == slot.section);
  return sectionStudents.map((student) {
    return AttendanceRecord(
      slotId: slot.id,
      studentId: student.id,
      status: AttendanceStatus.present,
      checkIn: slot.startTime,
      remarks: '',
    );
  }).toList();
}
