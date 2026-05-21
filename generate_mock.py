import random
import datetime

programs = [
    ("DGS", "DIPLOMA TEKNOLOGI KEJURUTERAAN GAS", None),
    ("DPP", "DIPLOMA TEKNOLOGI KEJURUTERAAN PENYAMANAN UDARA DAN PENYEJUKAN", None),
    ("DED", "DIPLOMA TEKNOLOGI KEJURUTERAAN ELEKTRIK (DOMESTIK INDUSTRI)", "elektrik"),
    ("DEK", "DIPLOMA TEKNOLOGI PEMBUATAN ELEKTRONIK", None),
    ("DCP", "DIPLOMA KOMPETENSI ELEKTRIK (KUASA)", "elektrik"),
    ("DCB", "DIPLOMA LANJUTAN KOMPETENSI ELEKTRIK (PENJANAAN)", "elektrik"),
    ("DKM", "DIPLOMA KEJURUTERAAN MEKANIKAL", "mekanikal"),
    ("DKA", "DIPLOMA KEJURUTERAAN AUTOMOTIF", "mekanikal"),
    ("DKI", "DIPLOMA KIMPALAN INDUSTRI", "mekanikal"),
    ("DSK", "DIPLOMA SISTEM KOMPUTER", "komputer"),
    ("DPM", "DIPLOMA PENYELENGGARAAN MESIN", "mekanikal"),
    ("DKB", "DIPLOMA KEJURUTERAAN BANGUNAN", None),
    ("DSE", "DIPLOMA SISTEM ELEKTRONIK", "elektrik"),
    ("DPB", "DIPLOMA PEMESINAN BERKOMPUTER", "mekanikal"),
]

dart_code = f\"\"\"import '../models/app_models.dart';
import 'package:uuid/uuid.dart';

final _uuid = Uuid();

final List<ProgramCode> programs = [
\"\"\"

for p in programs:
    dept = f"'{p[2]}'" if p[2] else "null"
    dart_code += f"  ProgramCode(id: '{p[0]}', name: '{p[1]}', departmentId: {dept}),\n"

dart_code += "];\n\n"

dart_code += \"\"\"
const roomResources = [
  RoomResource(name: 'BILIK KULIAH 1', block: 'Utama', type: 'Kelas'),
  RoomResource(name: 'BILIK KULIAH 2', block: 'Utama', type: 'Kelas'),
  RoomResource(name: 'MAKMAL KOMPUTER A', block: 'Komputer', type: 'Makmal'),
  RoomResource(name: 'BENGKEL ELEKTRIK', block: 'Elektrik', type: 'Bengkel'),
  RoomResource(name: 'BENGKEL MEKANIKAL', block: 'Mekanikal', type: 'Bengkel'),
];

final List<AppUser> users = [
  AppUser(id: 'U001', name: 'Pentadbir TVETMARA', email: 'admin@tvetmara.edu.my', role: UserRole.admin, department: 'Pentadbiran', active: true, lastLogin: '2026-05-01 08:00'),
  AppUser(id: 'KJ_E', name: 'KJ Elektrik', email: 'kj_elektrik@tvetmara.edu.my', role: UserRole.ketuaJabatan, department: 'elektrik', active: true, lastLogin: '2026-05-01 08:00'),
  AppUser(id: 'KJ_M', name: 'KJ Mekanikal', email: 'kj_mekanikal@tvetmara.edu.my', role: UserRole.ketuaJabatan, department: 'mekanikal', active: true, lastLogin: '2026-05-01 08:00'),
  AppUser(id: 'KJ_K', name: 'KJ Komputer', email: 'kj_komputer@tvetmara.edu.my', role: UserRole.ketuaJabatan, department: 'komputer', active: true, lastLogin: '2026-05-01 08:00'),
\"\"\"

for p in programs:
    dart_code += f"  AppUser(id: 'KP_{p[0]}', name: 'KP {p[0]}', email: 'kp_{p[0].lower()}@tvetmara.edu.my', role: UserRole.ketuaProgram, program: '{p[0]}', active: true, lastLogin: '2026-05-01 08:00'),\n"

for p in programs:
    dart_code += f"  AppUser(id: 'L_{p[0]}', name: 'Pensyarah {p[0]}', email: 'pensyarah_{p[0].lower()}@tvetmara.edu.my', role: UserRole.pensyarah, department: '{p[2] or 'Umum'}', active: true, lastLogin: '2026-05-01 08:00'),\n"

dart_code += "];\n\n"

dart_code += \"\"\"
final List<Lecturer> lecturers = users.where((u) => u.role == UserRole.pensyarah).map((u) => Lecturer(
  id: u.id,
  name: u.name,
  email: u.email,
  department: u.department ?? 'Umum',
  subjects: ['SUBJ101', 'SUBJ102'],
)).toList();

final List<Student> students = [];
final List<TimetableSlot> timetable = [];

void _generateMockData() {
  int studentIdCounter = 1;
  int slotIdCounter = 1;

  for (var prog in programs) {
    // Generate 10 students per program
    for (int i = 0; i < 10; i++) {
      students.add(Student(
        id: 'S',
        name: 'Pelajar  ()',
        email: 'student@student.tvetmara.edu.my',
        phone: '012-3456789',
        program: prog.name,
        semester: 1,
        section: ' 1A',
        attendance: 75 + (studentIdCounter % 25),
      ));
      studentIdCounter++;
    }

    // Generate 2 timetable slots per program assigned to their respective lecturer
    for (int i = 0; i < 2; i++) {
      timetable.add(TimetableSlot(
        id: 'T',
        session: 'Jan-Jun 2026',
        semester: 1,
        program: prog.name,
        section: ' 1A',
        subjectCode: 'SUBJ10',
        subjectName: 'Asas  ',
        lecturerId: 'L_',
        lecturerName: 'Pensyarah ',
        day: i == 0 ? 'Isnin' : 'Selasa',
        date: i == 0 ? '2026-05-18' : '2026-05-19',
        startTime: '08:00',
        endTime: '10:00',
        room: 'BILIK KULIAH 1',
        enrolled: 10,
        capacity: 30,
        classType: 'Teori',
        slotType: 'Kelas Biasa',
        status: i == 0 ? 'Attendance Completed' : 'Upcoming',
      ));
      slotIdCounter++;
    }
  }
}

final _init = (() { _generateMockData(); return true; })();

final disciplineReports = <DisciplineReport>[
  DisciplineReport(
    id: 'D001',
    studentId: 'S2026001',
    studentName: 'Pelajar 1 (DGS)',
    section: 'DGS 1A',
    subject: 'Asas DGS 1',
    lecturer: 'Pensyarah DGS',
    date: '2026-05-18',
    issueType: 'Kerap Tidak Hadir',
    severity: 'High',
    description: 'Pelajar tidak hadir.',
    followUp: true,
    status: 'Under Review',
  ),
];

final bookings = <BookingRequest>[
  BookingRequest(
    id: 'B001',
    lecturerId: 'L_DGS',
    lecturerName: 'Pensyarah DGS',
    subject: 'Asas DGS 1',
    section: 'DGS 1A',
    originalDate: '2026-05-18',
    originalTime: '08:00 - 10:00',
    replacementDate: '2026-05-20',
    replacementStart: '14:00',
    replacementEnd: '16:00',
    room: 'BILIK KULIAH 2',
    reason: 'Kecemasan',
    remarks: '',
    status: 'Pending',
  ),
];

List<AttendanceRecord> attendanceForSlot(TimetableSlot slot) {
  final sectionStudents = students.where((s) => s.section == slot.section).toList();
  return sectionStudents.map((s) => AttendanceRecord(
    slotId: slot.id,
    studentId: s.id,
    status: AttendanceStatus.present,
    checkIn: '08:00',
    remarks: '',
  )).toList();
}
\"\"\"

with open('lib/data/mock_data.dart', 'w', encoding='utf-8') as f:
    f.write(dart_code)

print("Generated mock_data.dart")
