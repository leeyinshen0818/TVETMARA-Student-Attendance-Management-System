import '../models/app_models.dart';

const programs = [
  'Diploma Teknologi Kejuruteraan Elektrik',
  'Sijil Teknologi Elektrik',
  'Sijil Teknologi Pembuatan',
];

const roomResources = [
  RoomResource(name: 'BAS LAB', block: 'Utama', type: 'Makmal'),
  RoomResource(name: 'BENGKEL FABRIKASI', block: 'Bengkel', type: 'Bengkel'),
  RoomResource(name: 'BILIK AIRCOND', block: 'Utama', type: 'Bilik'),
  RoomResource(name: 'BILIK BINCANG', block: 'Utama', type: 'Bilik'),
  RoomResource(name: 'BILIK ELEKTRIK', block: 'Elektrik', type: 'Bilik'),
  RoomResource(name: 'BILIK FITTING', block: 'Bengkel', type: 'Bilik'),
  RoomResource(name: 'BILIK KU PM', block: 'Utama', type: 'Bilik'),
  RoomResource(name: 'BILIK KULIAH DED 1', block: 'DED', type: 'Kelas'),
  RoomResource(name: 'BILIK KULIAH DED 2', block: 'DED', type: 'Kelas'),
  RoomResource(name: 'MAKMAL FIRE ALARM', block: 'Elektrik', type: 'Makmal'),
  RoomResource(name: 'BILIK KULIAH SPN', block: 'SPN', type: 'Kelas'),
  RoomResource(name: 'BILIK SHIPBOARD', block: 'SPN', type: 'Bilik'),
  RoomResource(name: 'BILIK SIMULATOR', block: 'SPN', type: 'Bilik'),
  RoomResource(name: 'BK A', block: 'BK', type: 'Kelas'),
  RoomResource(name: 'BK B', block: 'BK', type: 'Kelas'),
  RoomResource(name: 'BK C', block: 'BK', type: 'Kelas'),
  RoomResource(name: 'BK C1', block: 'BK', type: 'Kelas'),
  RoomResource(name: 'BK SPN', block: 'SPN', type: 'Kelas'),
  RoomResource(name: 'BK1 DPP', block: 'DPP', type: 'Kelas'),
  RoomResource(name: 'BK2 DPP', block: 'DPP', type: 'Kelas'),
  RoomResource(name: 'BK3 DPP', block: 'DPP', type: 'Kelas'),
  RoomResource(name: 'BK3A DPP', block: 'DPP', type: 'Kelas'),
  RoomResource(name: 'BK3B DPP', block: 'DPP', type: 'Kelas'),
  RoomResource(name: 'BK4 DPP', block: 'DPP', type: 'Kelas'),
  RoomResource(name: 'BK5 DPP', block: 'DPP', type: 'Kelas'),
  RoomResource(name: 'COMP. LAB 1', block: 'Komputer', type: 'Makmal'),
  RoomResource(name: 'COMP. LAB 2', block: 'Komputer', type: 'Makmal'),
  RoomResource(name: 'COMPUTER LAB 2 SPN', block: 'SPN', type: 'Makmal'),
  RoomResource(name: 'COMPUTER LAB1 SPN', block: 'SPN', type: 'Makmal'),
  RoomResource(
      name: 'ELEC AUTOCAD/ PLC LAB', block: 'Elektrik', type: 'Makmal'),
  RoomResource(name: 'ELEC MACHINE LAB', block: 'Elektrik', type: 'Makmal'),
  RoomResource(name: 'ELEC PRINCIPLE LAB', block: 'Elektrik', type: 'Makmal'),
  RoomResource(name: 'HYDRAULIC LAB', block: 'Bengkel', type: 'Makmal'),
  RoomResource(name: 'KUE CLASSROOM INTERGRASI', block: 'KUE', type: 'Kelas'),
  RoomResource(name: 'LAB ICT', block: 'Komputer', type: 'Makmal'),
  RoomResource(name: 'PLC LAB', block: 'Elektrik', type: 'Makmal'),
  RoomResource(name: 'PNEUMATIC LAB', block: 'Bengkel', type: 'Makmal'),
  RoomResource(name: 'POWER E LAB', block: 'Elektrik', type: 'Makmal'),
  RoomResource(
      name: 'RENEWABLE ENERGY LAB (RETTAC)', block: 'Elektrik', type: 'Makmal'),
  RoomResource(name: 'SLR 1A', block: 'SLR', type: 'Kelas'),
  RoomResource(name: 'SLR 2A', block: 'SLR', type: 'Kelas'),
  RoomResource(name: 'SLR 3A', block: 'SLR', type: 'Kelas'),
  RoomResource(name: 'SLR BENGKEL GEGAS', block: 'SLR', type: 'Bengkel'),
  RoomResource(name: 'SLR LAB 2', block: 'SLR', type: 'Makmal'),
  RoomResource(name: 'SLR LAB 3', block: 'SLR', type: 'Makmal'),
  RoomResource(name: 'SLR LAB 4', block: 'SLR', type: 'Makmal'),
  RoomResource(name: 'SLR STUDIO 1', block: 'SLR', type: 'Studio'),
  RoomResource(name: 'SLR STUDIO 2', block: 'SLR', type: 'Studio'),
  RoomResource(name: 'SLR STUDIO 4', block: 'SLR', type: 'Studio'),
  RoomResource(name: 'SMART CLASSROOM', block: 'Utama', type: 'Kelas'),
  RoomResource(name: 'SMI 1A', block: 'SMI', type: 'Kelas'),
  RoomResource(name: 'SMI 3A', block: 'SMI', type: 'Kelas'),
  RoomResource(name: 'SMI AUTOCAD LAB', block: 'SMI', type: 'Makmal'),
  RoomResource(name: 'SMI BILIK KULIAH 1', block: 'SMI', type: 'Kelas'),
  RoomResource(name: 'SMI BILIK KULIAH 2', block: 'SMI', type: 'Kelas'),
  RoomResource(name: 'SMI BK 1', block: 'SMI', type: 'Kelas'),
  RoomResource(name: 'SMI BK 2', block: 'SMI', type: 'Kelas'),
  RoomResource(name: 'SMI CNC WORKSHOP', block: 'SMI', type: 'Bengkel'),
  RoomResource(name: 'SMI ELEC. BAY', block: 'SMI', type: 'Bay'),
  RoomResource(name: 'SMI ELECTRICAL BAY', block: 'SMI', type: 'Bay'),
  RoomResource(name: 'SMI FITTING WORKSHOP', block: 'SMI', type: 'Bengkel'),
  RoomResource(name: 'SMI FYP WORKSHOP', block: 'SMI', type: 'Bengkel'),
  RoomResource(name: 'SMI HYDRAULIC LAB.', block: 'SMI', type: 'Makmal'),
  RoomResource(name: 'SMI MACHINE WORKSHOP', block: 'SMI', type: 'Bengkel'),
  RoomResource(
      name: 'SMI MAINTENANCE WORKSHOP 1', block: 'SMI', type: 'Bengkel'),
  RoomResource(
      name: 'SMI MAINTENANCE WORKSHOP 2', block: 'SMI', type: 'Bengkel'),
  RoomResource(name: 'SMI PLC LAB', block: 'SMI', type: 'Makmal'),
  RoomResource(name: 'SMI PNEUMATIC LAB', block: 'SMI', type: 'Makmal'),
  RoomResource(name: 'SMI WELDING BAY', block: 'SMI', type: 'Bay'),
  RoomResource(name: 'SWITCHBOARD LAB', block: 'Elektrik', type: 'Makmal'),
  RoomResource(name: 'WORKSHOP FITTING', block: 'Bengkel', type: 'Bengkel'),
  RoomResource(name: 'WORKSHOP GRINDING', block: 'Bengkel', type: 'Bengkel'),
  RoomResource(name: 'WORKSHOP LATHE', block: 'Bengkel', type: 'Bengkel'),
  RoomResource(name: 'BENGKEL PEPASANGAN 1', block: 'Bengkel', type: 'Bengkel'),
  RoomResource(name: 'BENGKEL PEPASANGAN 2', block: 'Bengkel', type: 'Bengkel'),
  RoomResource(name: 'BENGKEL PEPASANGAN 3', block: 'Bengkel', type: 'Bengkel'),
  RoomResource(name: 'BENGKEL PEPASANGAN 4', block: 'Bengkel', type: 'Bengkel'),
  RoomResource(name: 'BENGKEL PEPASANGAN 5', block: 'Bengkel', type: 'Bengkel'),
  RoomResource(name: 'BENGKEL PEPASANGAN 6', block: 'Bengkel', type: 'Bengkel'),
  RoomResource(
      name: 'MAKMAL SYNCHRONIZATION', block: 'Elektrik', type: 'Makmal'),
  RoomResource(
      name: 'MAKMAL KOMPUTER ELEKTRIK', block: 'Elektrik', type: 'Makmal'),
  RoomResource(
      name: 'MAKMAL KOMPUTER DIGITAL', block: 'Komputer', type: 'Makmal'),
];

final rooms = roomResources.map((room) => room.name).toList();

const users = [
  AppUser(
    id: 'U001',
    name: 'Pentadbir TVETMARA',
    email: 'admin@tvetmara.edu.my',
    role: UserRole.admin,
    department: 'Pentadbiran',
    active: true,
    lastLogin: '2026-04-29 08:12',
  ),
  AppUser(
    id: 'L001',
    name: 'Pn Syarifah',
    email: 'lecturer@tvetmara.edu.my',
    role: UserRole.lecturer,
    department: 'Elektrik',
    active: true,
    lastLogin: '2026-04-29 07:45',
  ),
  AppUser(
    id: 'L007',
    name: 'Puan Zarina binti Yusof',
    email: 'zarina@tvetmara.edu.my',
    role: UserRole.lecturer,
    department: 'Komputer',
    active: true,
    lastLogin: '2026-04-28 14:00',
  ),
];

const lecturers = [
  Lecturer(
      id: 'L001',
      name: 'Pn Syarifah',
      email: 'syarifah@tvetmara.edu.my',
      department: 'Elektrik',
      subjects: ['DED10044', 'DUY10031']),
  Lecturer(
      id: 'L002',
      name: 'Pn Norhati',
      email: 'norhati@tvetmara.edu.my',
      department: 'Elektrik',
      subjects: ['DKV10213', 'DEV10043']),
  Lecturer(
      id: 'L003',
      name: 'Pn Rafidah',
      email: 'rafidah@tvetmara.edu.my',
      department: 'Elektrik',
      subjects: ['DUM10122']),
  Lecturer(
      id: 'L004',
      name: 'En Faizal',
      email: 'faizal@tvetmara.edu.my',
      department: 'Elektrik',
      subjects: ['DEV10052']),
  Lecturer(
      id: 'L007',
      name: 'Puan Zarina binti Yusof',
      email: 'zarina@tvetmara.edu.my',
      department: 'Komputer',
      subjects: ['CSS30113', 'CSS10164']),
];

final students = List<Student>.generate(36, (index) {
  final section = index < 12
      ? 'DED 1A'
      : index < 24
          ? 'SMI 1A'
          : 'SMI 3A';
  final program = section.startsWith('DED')
      ? programs[0]
      : section.endsWith('1A')
          ? programs[1]
          : programs[2];
  final names = [
    'Ahmad',
    'Aiman',
    'Farah',
    'Hana',
    'Danial',
    'Sarah',
    'Irfan',
    'Nurul'
  ];
  final last = ['Ismail', 'Hassan', 'Rahman', 'Yusof', 'Omar', 'Ali'];
  return Student(
    id: 'S${2026001 + index}',
    name:
        '${names[index % names.length]} ${index.isEven ? 'bin' : 'binti'} ${last[index % last.length]}',
    email: 'student${index + 1}@student.tvetmara.edu.my',
    phone: '01${index % 9 + 1}-${1000000 + index * 7777}',
    program: program,
    semester: section.endsWith('3A') ? 3 : 1,
    section: section,
    attendance: index % 7 == 0 ? 63 + index % 12 : 82 + index % 16,
  );
});

final timetable = <TimetableSlot>[
  _slot(
      'T001',
      programs[0],
      'DED 1A',
      'DED10044',
      'Amali Pendawaian dan Pepasangan',
      'L001',
      'Pn Syarifah',
      'Isnin',
      '2026-05-18',
      '08:00',
      '12:00',
      'BENGKEL PEPASANGAN 3',
      'Attendance Completed'),
  _slot(
      'T002',
      programs[0],
      'DED 1A',
      'DED10044',
      'Amali Pendawaian dan Pepasangan',
      'L001',
      'Pn Syarifah',
      'Isnin',
      '2026-05-18',
      '14:00',
      '17:00',
      'BENGKEL PEPASANGAN 3',
      'Upcoming'),
  _slot(
      'T003',
      programs[0],
      'DED 1A',
      'DUE10000',
      'Komunikasi Bahasa Inggeris',
      'L002',
      'Pn Norhati',
      'Selasa',
      '2026-05-19',
      '11:00',
      '12:00',
      'BK1 DPP',
      'Ongoing'),
  _slot(
      'T004',
      programs[0],
      'DED 1A',
      'DUM10122',
      'Matematik',
      'L003',
      'Pn Rafidah',
      'Rabu',
      '2026-05-20',
      '08:00',
      '10:00',
      'BK3 DPP',
      'Attendance Not Taken'),
  _slot(
      'T005',
      programs[0],
      'DED 1A',
      'DKV10213',
      'Mesin Elektrik',
      'L002',
      'Pn Norhati',
      'Rabu',
      '2026-05-20',
      '10:00',
      '13:00',
      'ELEC MACHINE LAB',
      'Upcoming'),
  _slot(
      'T006',
      programs[0],
      'DED 1A',
      'DEV10043',
      'Prinsip Elektrik',
      'L002',
      'Pn Norhati',
      'Khamis',
      '2026-05-21',
      '08:00',
      '13:00',
      'ELEC PRINCIPLE LAB',
      'Upcoming'),
  _slot(
      'T007',
      programs[0],
      'DED 1A',
      'DEV10052',
      'Sistem Digital',
      'L004',
      'En Faizal',
      'Khamis',
      '2026-05-21',
      '14:00',
      '17:00',
      'MAKMAL KOMPUTER DIGITAL',
      'Upcoming'),
  _slot(
      'T008',
      programs[1],
      'SMI 1A',
      'CSS10164',
      'Asas Elektrik',
      'L007',
      'Puan Zarina binti Yusof',
      'Selasa',
      '2026-05-19',
      '08:00',
      '10:00',
      'SMI 1A',
      'Attendance Completed'),
  _slot(
      'T009',
      programs[2],
      'SMI 3A',
      'CSS30113',
      'Kawalan Logik Boleh Atur Cara',
      'L007',
      'Puan Zarina binti Yusof',
      'Rabu',
      '2026-05-20',
      '08:00',
      '10:00',
      'SMI PLC LAB',
      'Attendance Completed'),
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
  final enrolled =
      students.where((student) => student.section == section).length;
  return TimetableSlot(
    id: id,
    session: 'Jan - Jun 2026',
    semester: section.endsWith('3A') ? 3 : 1,
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
    classType: room.contains('LAB') ||
            room.contains('BENGKEL') ||
            room.contains('WORKSHOP')
        ? 'Amali'
        : 'Teori',
    slotType: 'Kelas Biasa',
    status: status,
  );
}

final disciplineReports = [
  DisciplineReport(
    id: 'D001',
    studentId: students[3].id,
    studentName: students[3].name,
    section: 'DED 1A',
    subject: 'Amali Pendawaian dan Pepasangan',
    lecturer: 'Pn Syarifah',
    date: '2026-05-18',
    issueType: 'Kerap Tidak Hadir',
    severity: 'High',
    description: 'Pelajar tidak hadir 5 sesi berturut-turut tanpa makluman.',
    followUp: true,
    status: 'Under Review',
  ),
];

const bookings = [
  BookingRequest(
    id: 'B001',
    lecturerId: 'L001',
    lecturerName: 'Pn Syarifah',
    subject: 'Amali Pendawaian dan Pepasangan',
    section: 'DED 1A',
    originalDate: '2026-05-18',
    originalTime: '08:00 - 10:00',
    replacementDate: '2026-05-03',
    replacementStart: '14:00',
    replacementEnd: '16:00',
    room: 'BILIK KULIAH DED 1',
    reason: 'Cuti umum',
    remarks: 'Gantian untuk cuti umum.',
    status: 'Pending',
  ),
];

List<AttendanceRecord> attendanceForSlot(TimetableSlot slot) {
  final sectionStudents =
      students.where((student) => student.section == slot.section).toList();
  return sectionStudents.asMap().entries.map((entry) {
    final index = entry.key;
    final student = entry.value;
    final status = switch (index % 10) {
      0 => AttendanceStatus.absent,
      1 => AttendanceStatus.late,
      2 => AttendanceStatus.mc,
      3 => AttendanceStatus.ck,
      _ => AttendanceStatus.present,
    };
    return AttendanceRecord(
      slotId: slot.id,
      studentId: student.id,
      status: status,
      checkIn: status.countsAsAttended ? slot.startTime : '-',
      remarks: status.isExempt ? 'Dikecualikan' : '',
    );
  }).toList();
}
