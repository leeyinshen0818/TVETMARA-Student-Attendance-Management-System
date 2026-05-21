import '../models/app_models.dart';
import 'package:uuid/uuid.dart';

final _uuid = const Uuid();

final List<ProgramCode> programs = [
  const ProgramCode(id: 'DGS', name: 'DIPLOMA TEKNOLOGI KEJURUTERAAN GAS', departmentId: null),
  const ProgramCode(id: 'DPP', name: 'DIPLOMA TEKNOLOGI KEJURUTERAAN PENYAMANAN UDARA DAN PENYEJUKAN', departmentId: null),
  const ProgramCode(id: 'DED', name: 'DIPLOMA TEKNOLOGI KEJURUTERAAN ELEKTRIK (DOMESTIK INDUSTRI)', departmentId: 'elektrik'),
  const ProgramCode(id: 'DEK', name: 'DIPLOMA TEKNOLOGI PEMBUATAN ELEKTRONIK', departmentId: null),
  const ProgramCode(id: 'DCP', name: 'DIPLOMA KOMPETENSI ELEKTRIK (KUASA)', departmentId: 'elektrik'),
  const ProgramCode(id: 'DCB', name: 'DIPLOMA LANJUTAN KOMPETENSI ELEKTRIK (PENJANAAN)', departmentId: 'elektrik'),
  const ProgramCode(id: 'DKM', name: 'DIPLOMA KEJURUTERAAN MEKANIKAL', departmentId: 'mekanikal'),
  const ProgramCode(id: 'DKA', name: 'DIPLOMA KEJURUTERAAN AUTOMOTIF', departmentId: 'mekanikal'),
  const ProgramCode(id: 'DKI', name: 'DIPLOMA KIMPALAN INDUSTRI', departmentId: 'mekanikal'),
  const ProgramCode(id: 'DSK', name: 'DIPLOMA SISTEM KOMPUTER', departmentId: 'komputer'),
  const ProgramCode(id: 'DPM', name: 'DIPLOMA PENYELENGGARAAN MESIN', departmentId: 'mekanikal'),
  const ProgramCode(id: 'DKB', name: 'DIPLOMA KEJURUTERAAN BANGUNAN', departmentId: null),
  const ProgramCode(id: 'DSE', name: 'DIPLOMA SISTEM ELEKTRONIK', departmentId: 'elektrik'),
  const ProgramCode(id: 'DPB', name: 'DIPLOMA PEMESINAN BERKOMPUTER', departmentId: 'mekanikal'),
];

const roomResources = [
  RoomResource(name: 'BILIK KULIAH 1', block: 'Utama', type: 'Kelas'),
  RoomResource(name: 'BILIK KULIAH 2', block: 'Utama', type: 'Kelas'),
  RoomResource(name: 'MAKMAL KOMPUTER A', block: 'Komputer', type: 'Makmal'),
  RoomResource(name: 'BENGKEL ELEKTRIK', block: 'Elektrik', type: 'Bengkel'),
  RoomResource(name: 'BENGKEL MEKANIKAL', block: 'Mekanikal', type: 'Bengkel'),
];

final List<AppUser> users = [
  const AppUser(id: 'U001', name: 'Pentadbir TVETMARA', email: 'admin@tvetmara.edu.my', role: UserRole.admin, department: 'Pentadbiran', active: true, lastLogin: '2026-05-01 08:00'),
  const AppUser(id: 'KJ_E', name: 'KJ Elektrik', email: 'kj_elektrik@tvetmara.edu.my', role: UserRole.ketuaJabatan, department: 'elektrik', active: true, lastLogin: '2026-05-01 08:00'),
  const AppUser(id: 'KJ_M', name: 'KJ Mekanikal', email: 'kj_mekanikal@tvetmara.edu.my', role: UserRole.ketuaJabatan, department: 'mekanikal', active: true, lastLogin: '2026-05-01 08:00'),
  const AppUser(id: 'KJ_K', name: 'KJ Komputer', email: 'kj_komputer@tvetmara.edu.my', role: UserRole.ketuaJabatan, department: 'komputer', active: true, lastLogin: '2026-05-01 08:00'),
  ...programs.map((p) => AppUser(id: 'KP_${p.id}', name: 'KP ${p.id}', email: 'kp_${p.id.toLowerCase()}@tvetmara.edu.my', role: UserRole.ketuaProgram, program: p.id, active: true, lastLogin: '2026-05-01 08:00')),
  ...programs.map((p) => AppUser(id: 'L_${p.id}', name: 'Pensyarah ${p.id}', email: 'pensyarah_${p.id.toLowerCase()}@tvetmara.edu.my', role: UserRole.pensyarah, department: p.departmentId ?? 'Umum', active: true, lastLogin: '2026-05-01 08:00')),
];

final List<Lecturer> lecturers = users.where((u) => u.role == UserRole.pensyarah).map((u) => Lecturer(
  id: u.id,
  name: u.name,
  email: u.email,
  department: u.department ?? 'Umum',
  subjects: ['SUBJ101', 'SUBJ102'],
)).toList();

final List<Student> students = [];
final List<TimetableSlot> timetable = [];

bool _initialized = false;

void _generateMockData() {
  if (_initialized) return;
  int studentIdCounter = 1;
  int slotIdCounter = 1;

  final sections = ['1A', '1B', '2A'];

  for (var prog in programs) {
    for (var sectionSuffix in sections) {
      final sectionName = '${prog.id} $sectionSuffix';
      
      // Generate 5 students per section (15 per program)
      for (int i = 0; i < 5; i++) {
        students.add(Student(
          id: 'S${2026000 + studentIdCounter}',
          name: 'Pelajar ${studentIdCounter} ($sectionName)',
          email: 'student${studentIdCounter}@student.tvetmara.edu.my',
          phone: '012-3456789',
          program: prog.name,
          semester: sectionSuffix.startsWith('1') ? 1 : 2,
          section: sectionName,
          attendance: 75 + (studentIdCounter % 25),
        ));
        studentIdCounter++;
      }

      // Generate 2 timetable slots per section (6 per program)
      for (int i = 0; i < 2; i++) {
        timetable.add(TimetableSlot(
          id: 'T${slotIdCounter.toString().padLeft(3, "0")}',
          session: 'Jan-Jun 2026',
          semester: sectionSuffix.startsWith('1') ? 1 : 2,
          program: prog.name,
          section: sectionName,
          subjectCode: 'SUBJ${sectionSuffix.startsWith('1') ? '10' : '20'}${i+1}',
          subjectName: 'Asas ${prog.id} ${sectionSuffix.startsWith('1') ? '1' : '2'}.${i+1}',
          lecturerId: 'L_${prog.id}',
          lecturerName: 'Pensyarah ${prog.id}',
          day: i == 0 ? 'Isnin' : 'Selasa',
          date: i == 0 ? '2026-05-18' : '2026-05-19',
          startTime: sectionSuffix == '1A' ? '08:00' : sectionSuffix == '1B' ? '10:00' : '14:00',
          endTime: sectionSuffix == '1A' ? '10:00' : sectionSuffix == '1B' ? '12:00' : '16:00',
          room: 'BILIK KULIAH ${sectionSuffix == '1A' ? '1' : sectionSuffix == '1B' ? '2' : '3'}',
          enrolled: 5,
          capacity: 30,
          classType: 'Teori',
          slotType: 'Kelas Biasa',
          status: i == 0 ? 'Attendance Completed' : 'Upcoming',
        ));
        slotIdCounter++;
      }
    }
  }
  _initialized = true;
}

void initializeMockData() {
  _generateMockData();
}
final disciplineReports = <DisciplineReport>[
  const DisciplineReport(
    id: 'D001',
    studentId: 'S2026001',
    studentName: 'Pelajar 1 (DED)',
    section: 'DED 1A',
    subject: 'Asas DED 1',
    lecturer: 'Pensyarah DED',
    date: '2026-05-18',
    issueType: 'Kerap Tidak Hadir',
    severity: 'High',
    description: 'Pelajar tidak hadir.',
    followUp: true,
    status: 'Under Review',
  ),
];

final bookings = <BookingRequest>[
  const BookingRequest(
    id: 'B001',
    lecturerId: 'L_DED',
    lecturerName: 'Pensyarah DED',
    subject: 'Asas DED 1',
    section: 'DED 1A',
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
