import '../core/constants/timetable_template.dart';
import '../models/app_models.dart';

const List<ProgramCode> programs = [
  ProgramCode(
      id: 'DGS',
      name: 'DIPLOMA TEKNOLOGI KEJURUTERAAN GAS (DGS)',
      departmentId: null),
  ProgramCode(
      id: 'DPP',
      name:
          'DIPLOMA TEKNOLOGI KEJURUTERAAN PENYAMANAN UDARA DAN PENYEJUKAN (DPP)',
      departmentId: null),
  ProgramCode(
      id: 'DED',
      name: 'DIPLOMA TEKNOLOGI KEJURUTERAAN ELEKTRIK (DOMESTIK INDUSTRI) (DED)',
      departmentId: 'elektrik'),
  ProgramCode(
      id: 'DEK',
      name: 'DIPLOMA TEKNOLOGI PEMBUATAN ELEKTRONIK (DEK)',
      departmentId: null),
  ProgramCode(
      id: 'DCP',
      name: 'DIPLOMA KOMPETENSI ELEKTRIK (KUASA) (DCP)',
      departmentId: 'elektrik'),
  ProgramCode(
      id: 'DCB',
      name: 'DIPLOMA LANJUTAN KOMPETENSI ELEKTRIK (PENJANAAN) (DCB)',
      departmentId: 'elektrik'),
  ProgramCode(
      id: 'ITW',
      name: 'DIPLOMA KOMPETENSI KIMPALAN (ITW)',
      departmentId: 'mekanikal'),
  ProgramCode(
      id: 'DGM',
      name: 'DIPLOMA TEKNOLOGI MEKATRONIK (DGM)',
      departmentId: null),
  ProgramCode(
      id: 'IMF',
      name: 'DIPLOMA INDUSTRI SIAPAN LOGAM (IMF)',
      departmentId: 'automotif'),
  ProgramCode(
      id: 'SLR',
      name: 'SIJIL TEKNOLOGI KEJURUTERAAN LUKISAN DAN REKABENTUK (SLR)',
      departmentId: 'mekanikal'),
  ProgramCode(
      id: 'SMI',
      name: 'SIJIL TEKNOLOGI KEJURUTERAAN MEKANIK INDUSTRI (SMI)',
      departmentId: 'mekanikal'),
  ProgramCode(
      id: 'SMK',
      name: 'SIJIL TEKNOLOGI KEJURUTERAAN MEKATRONIK (SMK)',
      departmentId: null),
  ProgramCode(
      id: 'SMM',
      name: 'SIJIL TEKNOLOGI KEJURUTERAAN MARIN (SMM)',
      departmentId: 'automotif'),
  ProgramCode(
      id: 'DMM',
      name: 'DIPLOMA TEKNOLOGI MARIN (DMM)',
      departmentId: 'automotif'),
];

const roomResources = [
  RoomResource(name: 'BAS LAB', block: 'Workshop', type: 'Makmal'),
  RoomResource(name: 'BENGKEL FABRIKASI', block: 'Workshop', type: 'Bengkel'),
  RoomResource(name: 'BILIK AIRCOND', block: 'Unknown', type: 'Bilik'),
  RoomResource(name: 'BILIK BINCANG', block: 'Unknown', type: 'Bilik'),
  RoomResource(name: 'BILIK ELEKTRIK', block: 'Elektrik', type: 'Bilik'),
  RoomResource(name: 'BILIK FITTING', block: 'Unknown', type: 'Bengkel'),
  RoomResource(name: 'BILIK KU PM', block: 'Unknown', type: 'Bilik'),
  RoomResource(name: 'BILIK KULIAH DED 1', block: 'DED', type: 'Kelas'),
  RoomResource(name: 'BILIK KULIAH DED 2', block: 'DED', type: 'Kelas'),
  RoomResource(name: 'MAKMAL FIRE ALARM', block: 'Unknown', type: 'Makmal'),
  RoomResource(name: 'BILIK KULIAH SPN', block: 'SPN', type: 'Kelas'),
  RoomResource(name: 'BILIK SHIPBOARD', block: 'Unknown', type: 'Bilik'),
  RoomResource(name: 'BILIK SIMULATOR', block: 'Unknown', type: 'Makmal'),
  RoomResource(name: 'BK A', block: 'Unknown', type: 'Kelas'),
  RoomResource(name: 'BK B', block: 'Unknown', type: 'Kelas'),
  RoomResource(name: 'BK C', block: 'Unknown', type: 'Kelas'),
  RoomResource(name: 'BK C1', block: 'Unknown', type: 'Kelas'),
  RoomResource(name: 'BK SPN', block: 'SPN', type: 'Kelas'),
  RoomResource(name: 'BK1 DPP', block: 'DPP', type: 'Kelas'),
  RoomResource(name: 'BK2 DPP', block: 'DPP', type: 'Kelas'),
  RoomResource(name: 'BK3 DPP', block: 'DPP', type: 'Kelas'),
  RoomResource(name: 'BK3A DPP', block: 'DPP', type: 'Kelas'),
  RoomResource(name: 'BK3B DPP', block: 'DPP', type: 'Kelas'),
  RoomResource(name: 'BK4 DPP', block: 'DPP', type: 'Kelas'),
  RoomResource(name: 'BK5 DPP', block: 'DPP', type: 'Kelas'),
  RoomResource(name: 'COMP. LAB 1', block: 'ICT', type: 'Makmal'),
  RoomResource(name: 'COMP. LAB 2', block: 'ICT', type: 'Makmal'),
  RoomResource(name: 'COMPUTER LAB 2 SPN', block: 'SPN', type: 'Makmal'),
  RoomResource(name: 'COMPUTER LAB1 SPN', block: 'SPN', type: 'Makmal'),
  RoomResource(
      name: 'ELEC AUTOCAD/ PLC LAB', block: 'Elektrik', type: 'Makmal'),
  RoomResource(name: 'ELEC MACHINE LAB', block: 'Elektrik', type: 'Makmal'),
  RoomResource(name: 'ELEC PRINCPLE LAB', block: 'Elektrik', type: 'Makmal'),
  RoomResource(name: 'HYDRAULIC LAB', block: 'Workshop', type: 'Makmal'),
  RoomResource(
      name: 'KUE CLASSROOM INTERGRASI', block: 'Unknown', type: 'Room'),
  RoomResource(name: 'LAB ICT', block: 'ICT', type: 'Makmal'),
  RoomResource(name: 'PLC LAB', block: 'Elektrik', type: 'Makmal'),
  RoomResource(name: 'PNEUMATIC LAB', block: 'Workshop', type: 'Makmal'),
  RoomResource(name: 'POWER E LAB', block: 'Elektrik', type: 'Makmal'),
  RoomResource(
      name: 'RENEWABLE ENERGY LAB (RETTAC)', block: 'Workshop', type: 'Makmal'),
  RoomResource(name: 'SLR 1A', block: 'SLR', type: 'Kelas'),
  RoomResource(name: 'SLR 2A', block: 'SLR', type: 'Kelas'),
  RoomResource(name: 'SLR 3A', block: 'SLR', type: 'Kelas'),
  RoomResource(name: 'SLR BENGKEL GEGAS', block: 'SLR', type: 'Bengkel'),
  RoomResource(name: 'SLR LAB 2', block: 'SLR', type: 'Makmal'),
  RoomResource(name: 'SLR LAB 3', block: 'SLR', type: 'Makmal'),
  RoomResource(name: 'SLR LAB 4', block: 'SLR', type: 'Makmal'),
  RoomResource(name: 'SLR STUDIO 1', block: 'SLR', type: 'Makmal'),
  RoomResource(name: 'SLR STUDIO 2', block: 'SLR', type: 'Makmal'),
  RoomResource(name: 'SLR STUDIO 4', block: 'SLR', type: 'Makmal'),
  RoomResource(name: 'SMART CLASSROOM', block: 'ICT', type: 'Makmal'),
  RoomResource(name: 'SMI 1A', block: 'SMI', type: 'Kelas'),
  RoomResource(name: 'SMI 3A', block: 'SMI', type: 'Kelas'),
  RoomResource(name: 'SMI AUTOCAD LAB', block: 'SMI', type: 'Makmal'),
  RoomResource(name: 'SMI BILIK KULIAH 1', block: 'SMI', type: 'Kelas'),
  RoomResource(name: 'SMI BILIK KULIAH 2', block: 'SMI', type: 'Kelas'),
  RoomResource(name: 'SMI BK 1', block: 'SMI', type: 'Room'),
  RoomResource(name: 'SMI BK 2', block: 'SMI', type: 'Room'),
  RoomResource(name: 'SMI CNC WORKSHOP', block: 'SMI', type: 'Bengkel'),
  RoomResource(name: 'SMI ELEC. BAY', block: 'SMI', type: 'Bengkel'),
  RoomResource(name: 'SMI ELECTRCAL BAY', block: 'SMI', type: 'Bengkel'),
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
  RoomResource(name: 'SMI WELDING BAY', block: 'SMI', type: 'Bengkel'),
  RoomResource(name: 'SWITCHBOARD LAB', block: 'Elektrik', type: 'Makmal'),
  RoomResource(name: 'WORKSHOP FITTING', block: 'Workshop', type: 'Bengkel'),
  RoomResource(name: 'WORKSHOP GRINDING', block: 'Workshop', type: 'Bengkel'),
  RoomResource(name: 'WORKSHOP LATHE', block: 'Workshop', type: 'Bengkel'),
  RoomResource(
      name: 'BENGKEL PEPASANGAN 1', block: 'Workshop', type: 'Bengkel'),
  RoomResource(
      name: 'BENGKEL PEPASANGAN 2', block: 'Workshop', type: 'Bengkel'),
  RoomResource(
      name: 'BENGKEL PEPASANGAN 3', block: 'Workshop', type: 'Bengkel'),
  RoomResource(
      name: 'BENGKEL PEPASANGAN 4', block: 'Workshop', type: 'Bengkel'),
  RoomResource(
      name: 'BENGKEL PEPASANGAN 5', block: 'Workshop', type: 'Bengkel'),
  RoomResource(
      name: 'BENGKEL PEPASANGAN 6', block: 'Workshop', type: 'Bengkel'),
  RoomResource(
      name: 'MAKMAL SYNCHCRONIZATION', block: 'Elektrik', type: 'Makmal'),
  RoomResource(
      name: 'MAKMAL KOMPUTER ELEKTRIK', block: 'Elektrik', type: 'Makmal'),
  RoomResource(
      name: 'MAKMAL KOMPUTER DIGITAL', block: 'Unknown', type: 'Makmal'),
];

final List<AppUser> users = [
  const AppUser(
      uid: 'U001',
      name: 'Pentadbir TVETMARA',
      email: 'admin@tvetmara.edu.my',
      role: UserRole.pentadbir,
      departmentId: 'Pentadbiran',
      isActive: true,
      createdAt: '2026-05-01 08:00',
      updatedAt: '2026-05-01 08:00'),
  const AppUser(
      uid: 'KJ_E',
      name: 'KJ Elektrik',
      email: 'kj_elektrik@tvetmara.edu.my',
      role: UserRole.ketua_jabatan,
      departmentId: 'elektrik',
      isActive: true,
      createdAt: '2026-05-01 08:00',
      updatedAt: '2026-05-01 08:00'),
  const AppUser(
      uid: 'KJ_M',
      name: 'KJ Mekanikal',
      email: 'kj_mekanikal@tvetmara.edu.my',
      role: UserRole.ketua_jabatan,
      departmentId: 'mekanikal',
      isActive: true,
      createdAt: '2026-05-01 08:00',
      updatedAt: '2026-05-01 08:00'),
  const AppUser(
      uid: 'KJ_K',
      name: 'KJ Automotif',
      email: 'kj_automotif@tvetmara.edu.my',
      role: UserRole.ketua_jabatan,
      departmentId: 'automotif',
      isActive: true,
      createdAt: '2026-05-01 08:00',
      updatedAt: '2026-05-01 08:00'),
  ...programs.map((p) => AppUser(
      uid: 'KP_${p.id}',
      name: 'KP ${p.id}',
      email: 'kp_${p.id.toLowerCase()}@tvetmara.edu.my',
      role: UserRole.ketua_program,
      programId: p.id,
      isActive: true,
      createdAt: '2026-05-01 08:00',
      updatedAt: '2026-05-01 08:00')),
  ...programs.map((p) => AppUser(
      uid: 'L_${p.id}',
      name: 'Pensyarah ${p.id}',
      email: 'pensyarah_${p.id.toLowerCase()}@tvetmara.edu.my',
      role: UserRole.pensyarah,
      departmentId: p.departmentId ?? 'Umum',
      programId: p.id,
      isActive: true,
      createdAt: '2026-05-01 08:00',
      updatedAt: '2026-05-01 08:00')),
];

final List<Lecturer> lecturers = users
    .where((u) => u.role == UserRole.pensyarah)
    .map((u) => Lecturer(
          id: u.id,
          name: u.name,
          email: u.email,
          department: u.departmentId ?? 'Umum',
          subjects: ['SUBJ101', 'SUBJ102'],
        ))
    .toList();

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
          name: 'Pelajar $studentIdCounter ($sectionName)',
          email: 'student$studentIdCounter@student.tvetmara.edu.my',
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
          session: TimetableCsvTemplate.defaultAcademicSessionId,
          semester: sectionSuffix.startsWith('1') ? 1 : 2,
          program: prog.name,
          section: sectionName,
          subjectCode:
              'SUBJ${sectionSuffix.startsWith('1') ? '10' : '20'}${i + 1}',
          subjectName:
              'Asas ${prog.id} ${sectionSuffix.startsWith('1') ? '1' : '2'}.${i + 1}',
          lecturerId: 'L_${prog.id}',
          lecturerName: 'Pensyarah ${prog.id}',
          day: i == 0 ? 'Isnin' : 'Selasa',
          date: i == 0 ? '2026-05-18' : '2026-05-19',
          startTime: sectionSuffix == '1A'
              ? '08:00'
              : sectionSuffix == '1B'
                  ? '10:00'
                  : '14:00',
          endTime: sectionSuffix == '1A'
              ? '10:00'
              : sectionSuffix == '1B'
                  ? '12:00'
                  : '16:00',
          room:
              'BILIK KULIAH ${sectionSuffix == '1A' ? '1' : sectionSuffix == '1B' ? '2' : '3'}',
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
    studentId: 'S2026031',
    studentName: 'Pelajar 31 (DED 1A)',
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
  final sectionStudents =
      students.where((s) => s.section == slot.section).toList();
  return sectionStudents.asMap().entries.map((entry) {
    final status = switch (entry.key % 5) {
      0 => AttendanceStatus.present,
      1 => AttendanceStatus.late,
      2 => AttendanceStatus.absent,
      3 => AttendanceStatus.mc,
      _ => AttendanceStatus.ck,
    };
    return AttendanceRecord(
      slotId: slot.id,
      studentId: entry.value.id,
      status: status,
      checkIn: status.countsAsAttended ? slot.startTime : '-',
      remarks: status.isExempt ? 'Dikecualikan' : '',
    );
  }).toList();
}
