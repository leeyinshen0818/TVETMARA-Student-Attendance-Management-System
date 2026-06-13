import '../core/constants/timetable_template.dart';
import '../data/lecturer_seed_data.dart' as lecturer_seed;
import '../data/subject_seed_data.dart' as subject_seed;
import '../models/app_models.dart';

const demoLecturerDedName = 'Pensyarah DED (Demo)';
const demoLecturerDgsName = 'Pensyarah DGS (Demo)';

String _demoLecturerName(String programId) {
  return switch (programId) {
    'DED' => demoLecturerDedName,
    'DGS' => demoLecturerDgsName,
    _ => 'Pensyarah $programId (Demo)',
  };
}

const realLecturerLoginProfileIds = {
  'REAL_L_001',
  'REAL_L_042',
  'REAL_L_044',
  'REAL_L_046',
  'REAL_L_047',
  'REAL_L_049',
  'REAL_L_050',
  'REAL_L_055',
  'REAL_L_057',
  'REAL_L_072',
};

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

const List<AcademicSession> academicSessions = [
  AcademicSession(
    academicSessionId: 'JAN_JUN_2026',
    name: 'Jan-Jun 2026',
    startDate: '2026-01-01',
    endDate: '2026-06-30',
    status: 'active',
    isActive: true,
  ),
  AcademicSession(
    academicSessionId: 'JUL_DEC_2026',
    name: 'Jul-Dec 2026',
    startDate: '2026-07-01',
    endDate: '2026-12-31',
    status: 'upcoming',
    isActive: true,
  ),
  AcademicSession(
    academicSessionId: 'JAN_JUN_2027',
    name: 'Jan-Jun 2027',
    startDate: '2027-01-01',
    endDate: '2027-06-30',
    status: 'upcoming',
    isActive: true,
  ),
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

final List<AppUser> demoAuthUsers = [
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
      name: _demoLecturerName(p.id),
      email: 'pensyarah_${p.id.toLowerCase()}@tvetmara.edu.my',
      role: UserRole.pensyarah,
      departmentId: p.departmentId ?? 'Umum',
      programId: p.id,
      isActive: true,
      createdAt: '2026-05-01 08:00',
      updatedAt: '2026-05-01 08:00')),
];

final List<AppUser> realLecturerLoginUsers = lecturer_seed.realLecturerProfiles
    .where(
        (profile) => realLecturerLoginProfileIds.contains(profile.lecturerId))
    .map((profile) => AppUser(
          uid: profile.lecturerId,
          name: profile.name,
          email: profile.email,
          role: UserRole.pensyarah,
          programId:
              profile.programIds.length == 1 ? profile.programIds.first : null,
          departmentId: profile.departmentIds.length == 1
              ? profile.departmentIds.first
              : null,
          lecturerProfileId: profile.lecturerId,
          isActive: true,
          createdAt: '2026-05-01 08:00',
          updatedAt: '2026-05-01 08:00',
        ))
    .toList();

final List<AppUser> realLecturerUsers = realLecturerLoginUsers;

final List<AppUser> users = [
  ...demoAuthUsers,
  ...realLecturerLoginUsers,
];

final List<Lecturer> lecturers = [
  ...demoAuthUsers
      .where((u) => u.role == UserRole.pensyarah)
      .map((u) => Lecturer(
            id: u.id,
            name: u.name,
            email: u.email,
            department: u.departmentId ?? 'Umum',
            subjects: _subjectsForProgram(u.programId ?? '')
                .take(4)
                .map((s) => s.subjectCode)
                .toList(),
          )),
  ...lecturer_seed.realLecturerProfiles.map((profile) => Lecturer(
        id: profile.lecturerId,
        name: profile.name,
        email: profile.email,
        department: profile.departmentIds.isEmpty
            ? 'Umum'
            : profile.departmentIds.join(','),
        subjects: profile.subjectCodes,
      )),
];

List<lecturer_seed.LecturerCourseAssignmentSeed>
    get lecturerCourseAssignmentsForSeed =>
        lecturer_seed.realLecturerCourseAssignments;

class DemoClass {
  const DemoClass({
    required this.classId,
    required this.programId,
    required this.academicSessionId,
    required this.semester,
    required this.section,
    required this.displayName,
    required this.isActive,
  });

  final String classId;
  final String programId;
  final String academicSessionId;
  final int semester;
  final String section;
  final String displayName;
  final bool isActive;
}

class AttendanceSeedBundle {
  const AttendanceSeedBundle({
    required this.session,
    required this.records,
  });

  final AttendanceSession session;
  final List<AttendanceRecord> records;
}

final List<Student> students = [];
final List<TimetableSlot> timetable = [];
final List<DemoClass> demoClasses = [];

// Real client workbook does not include usable subjects for every seeded
// programme. These records are explicitly generated demo master data so DGM
// and DMM can participate in full integration testing.
const generatedDemoSubjects = <SubjectCourse>[
  SubjectCourse(
      subjectId: 'DGM_DEMO101',
      programId: 'DGM',
      subjectCode: 'DEMO101',
      subjectName: 'DEMO MECHATRONICS FUNDAMENTALS'),
  SubjectCourse(
      subjectId: 'DGM_DEMO102',
      programId: 'DGM',
      subjectCode: 'DEMO102',
      subjectName: 'DEMO AUTOMATION PRACTICE'),
  SubjectCourse(
      subjectId: 'DGM_DEMO103',
      programId: 'DGM',
      subjectCode: 'DEMO103',
      subjectName: 'DEMO CONTROL SYSTEMS'),
  SubjectCourse(
      subjectId: 'DGM_DEMO104',
      programId: 'DGM',
      subjectCode: 'DEMO104',
      subjectName: 'DEMO INDUSTRIAL ROBOTICS'),
  SubjectCourse(
      subjectId: 'DMM_DEMO101',
      programId: 'DMM',
      subjectCode: 'DEMO101',
      subjectName: 'DEMO MARINE TECHNOLOGY'),
  SubjectCourse(
      subjectId: 'DMM_DEMO102',
      programId: 'DMM',
      subjectCode: 'DEMO102',
      subjectName: 'DEMO MARINE MAINTENANCE'),
  SubjectCourse(
      subjectId: 'DMM_DEMO103',
      programId: 'DMM',
      subjectCode: 'DEMO103',
      subjectName: 'DEMO MARINE SAFETY'),
  SubjectCourse(
      subjectId: 'DMM_DEMO104',
      programId: 'DMM',
      subjectCode: 'DEMO104',
      subjectName: 'DEMO VESSEL SYSTEMS'),
];

List<SubjectCourse> get subjectsForSeed => [
      ...subject_seed.subjectSeedData,
      ...generatedDemoSubjects,
    ];

bool _initialized = false;

void _generateMockData() {
  if (_initialized) return;
  int studentIdCounter = 1;
  int slotIdCounter = 1;

  const baseSections = ['1A', '1B', '2A'];
  const extraSections = {
    'DED': ['3A'],
    'DGS': ['3A'],
    'SMI': ['3A'],
  };

  for (final prog in programs) {
    final sections = [
      ...baseSections,
      ...(extraSections[prog.id] ?? const <String>[]),
    ];

    for (final sectionSuffix in sections) {
      final classId = '${prog.id} $sectionSuffix';
      demoClasses.add(DemoClass(
        classId: classId,
        programId: prog.id,
        academicSessionId: TimetableCsvTemplate.defaultAcademicSessionId,
        semester: _semesterForSection(sectionSuffix),
        section: sectionSuffix,
        displayName: classId,
        isActive: true,
      ));

      // Generated demo students. DED 1A is larger because it is the
      // client-inspired timetable sample used in demos.
      final studentCount = classId == 'DED 1A' ? 20 : 15;
      for (var i = 0; i < studentCount; i++) {
        students.add(Student(
          id: 'S${2026000 + studentIdCounter}',
          name:
              'Pelajar ${prog.id} $sectionSuffix ${(i + 1).toString().padLeft(2, '0')}',
          email: 'student$studentIdCounter@student.tvetmara.edu.my',
          phone: '012-3456789',
          program: prog.name,
          semester: _semesterForSection(sectionSuffix),
          section: classId,
          attendance: _demoAttendancePercentage(i),
        ));
        studentIdCounter++;
      }
    }
  }

  // Client-inspired DED 1A sample. It uses real subject master records and
  // real rooms. Exact PDF extraction is not automated in this seed phase.
  timetable.addAll([
    _slot(
      id: 'DED1A_CLIENT_001',
      programId: 'DED',
      sectionSuffix: '1A',
      subject: _subjectById('DED_DED10044'),
      day: 'Isnin',
      startTime: '08:00',
      endTime: '10:00',
      roomName: 'ELEC MACHINE LAB',
      slotType: 'Client Sample DED 1A',
      sourceUploadId: 'seed_client_ded_1a',
    ),
    _slot(
      id: 'DED1A_CLIENT_002',
      programId: 'DED',
      sectionSuffix: '1A',
      subject: _subjectById('DED_DEV10043'),
      day: 'Isnin',
      startTime: '10:00',
      endTime: '12:00',
      roomName: 'BILIK KULIAH DED 1',
      slotType: 'Client Sample DED 1A',
      sourceUploadId: 'seed_client_ded_1a',
    ),
    _slot(
      id: 'DED1A_CLIENT_003',
      programId: 'DED',
      sectionSuffix: '1A',
      subject: _subjectById('DED_DUM10122'),
      day: 'Selasa',
      startTime: '08:00',
      endTime: '10:00',
      roomName: 'BILIK KULIAH DED 2',
      slotType: 'Client Sample DED 1A',
      sourceUploadId: 'seed_client_ded_1a',
    ),
    _slot(
      id: 'DED1A_CLIENT_004',
      programId: 'DED',
      sectionSuffix: '1A',
      subject: _subjectById('DED_DKV10213'),
      day: 'Rabu',
      startTime: '10:00',
      endTime: '12:00',
      roomName: 'PLC LAB',
      slotType: 'Client Sample DED 1A',
      sourceUploadId: 'seed_client_ded_1a',
    ),
    _slot(
      id: 'DED1A_CLIENT_005',
      programId: 'DED',
      sectionSuffix: '1A',
      subject: _subjectById('DED_DUS10062'),
      day: 'Khamis',
      startTime: '08:00',
      endTime: '10:00',
      roomName: 'BILIK KULIAH DED 1',
      slotType: 'Client Sample DED 1A',
      sourceUploadId: 'seed_client_ded_1a',
    ),
  ]);

  // Generated demo timetable for full team testing. Real master subjects and
  // rooms are used wherever available; only DGM/DMM use labelled demo subjects.
  for (final prog in programs) {
    for (final sectionSuffix in const ['1A', '1B']) {
      if (prog.id == 'DED' && sectionSuffix == '1A') continue;
      final subjects = _subjectsForProgram(prog.id);
      for (var i = 0; i < 4; i++) {
        timetable.add(_slot(
          id: 'T${slotIdCounter.toString().padLeft(3, '0')}',
          programId: prog.id,
          sectionSuffix: sectionSuffix,
          subject: subjects[i % subjects.length],
          day: _demoDays[i % _demoDays.length],
          startTime: _timeBlocks[
              (i + (sectionSuffix == '1B' ? 1 : 0)) % _timeBlocks.length][0],
          endTime: _timeBlocks[
              (i + (sectionSuffix == '1B' ? 1 : 0)) % _timeBlocks.length][1],
          roomName: _roomForIndex(slotIdCounter),
          slotType: 'Generated Demo Timetable',
          sourceUploadId: 'seed_generated_demo',
        ));
        slotIdCounter++;
      }
    }
  }

  // Intentional conflict cases for Semakan Konflik testing. They are isolated
  // and labelled through sourceUploadId so staff can identify them as demos.
  timetable.addAll(_conflictDemoSlots());
  _initialized = true;
}

void initializeMockData() {
  _generateMockData();
}

List<DisciplineReport> get disciplineReports => <DisciplineReport>[
      DisciplineReport(
        id: 'D001',
        studentId: _studentIdForClass('DED 1A', 3),
        studentName: _studentNameForClass('DED 1A', 3),
        programId: 'DED',
        programName: _programById('DED').name,
        departmentId: 'elektrik',
        section: 'DED 1A',
        subject: 'ELECTRICAL INSTALLATION',
        subjectCode: 'DED10044',
        subjectName: 'ELECTRICAL INSTALLATION',
        slotId: 'DED1A_CLIENT_001',
        lecturer: demoLecturerDedName,
        date: '2026-05-18',
        issueType: 'Kerap Tidak Hadir',
        severity: 'High',
        description: 'Pelajar kerap tidak hadir tanpa makluman awal.',
        followUp: true,
        status: 'reviewed',
        createdBy: 'L_DED',
        createdByName: demoLecturerDedName,
        assignedReviewerRoles: ['ketua_program', 'ketua_jabatan'],
      ),
      DisciplineReport(
        id: 'D002',
        studentId: _studentIdForClass('DGS 1A', 4),
        studentName: _studentNameForClass('DGS 1A', 4),
        programId: 'DGS',
        programName: _programById('DGS').name,
        section: 'DGS 1A',
        subject: _subjectsForProgram('DGS').first.subjectName,
        subjectCode: _subjectsForProgram('DGS').first.subjectCode,
        subjectName: _subjectsForProgram('DGS').first.subjectName,
        lecturer: demoLecturerDgsName,
        date: '2026-05-20',
        issueType: 'Lewat ke kelas',
        severity: 'Medium',
        description:
            'Pelajar lewat hadir ke kelas beberapa kali dalam minggu semasa.',
        followUp: true,
        status: 'pending',
        createdBy: 'L_DGS',
        createdByName: demoLecturerDgsName,
        assignedReviewerRoles: ['ketua_program'],
      ),
      DisciplineReport(
        id: 'D003',
        studentId: _studentIdForClass('SMI 1A', 2),
        studentName: _studentNameForClass('SMI 1A', 2),
        programId: 'SMI',
        programName: _programById('SMI').name,
        departmentId: 'mekanikal',
        section: 'SMI 1A',
        subject: _subjectsForProgram('SMI').first.subjectName,
        subjectCode: _subjectsForProgram('SMI').first.subjectCode,
        subjectName: _subjectsForProgram('SMI').first.subjectName,
        lecturer: 'Pensyarah SMI (Demo)',
        date: '2026-05-21',
        issueType: 'Tidak mematuhi peraturan kelas',
        severity: 'Low',
        description:
            'Pelajar diberi teguran kerana tidak mematuhi arahan kelas.',
        followUp: false,
        status: 'action_taken',
        createdBy: 'L_SMI',
        createdByName: 'Pensyarah SMI (Demo)',
        assignedReviewerRoles: ['ketua_program', 'ketua_jabatan'],
      ),
      DisciplineReport(
        id: 'D004',
        studentId: _studentIdForClass('SMM 1A', 5),
        studentName: _studentNameForClass('SMM 1A', 5),
        programId: 'SMM',
        programName: _programById('SMM').name,
        departmentId: 'automotif',
        section: 'SMM 1A',
        subject: _subjectsForProgram('SMM').first.subjectName,
        subjectCode: _subjectsForProgram('SMM').first.subjectCode,
        subjectName: _subjectsForProgram('SMM').first.subjectName,
        lecturer: 'Pensyarah SMM (Demo)',
        date: '2026-05-22',
        issueType: 'Masalah disiplin ringan',
        severity: 'Medium',
        description: 'Laporan susulan disiplin ringan untuk semakan jabatan.',
        followUp: true,
        status: 'closed',
        createdBy: 'L_SMM',
        createdByName: 'Pensyarah SMM (Demo)',
        assignedReviewerRoles: ['ketua_program', 'ketua_jabatan'],
      ),
    ];

final bookings = <BookingRequest>[
  const BookingRequest(
    id: 'B001',
    lecturerId: 'L_DED',
    lecturerName: demoLecturerDedName,
    programId: 'DED',
    departmentId: 'elektrik',
    subject: 'ELECTRICAL INSTALLATION',
    section: 'DED 1A',
    originalDate: '2026-05-18',
    originalTime: '08:00 - 10:00',
    replacementDate: '2026-05-20',
    replacementStart: '14:00',
    replacementEnd: '16:00',
    roomId: 'BILIK KULIAH DED 1',
    roomName: 'BILIK KULIAH DED 1',
    room: 'BILIK KULIAH DED 1',
    reason: 'Kecemasan',
    remarks: 'Permohonan demo untuk ujian aliran kelulusan.',
    status: 'Pending',
  ),
  const BookingRequest(
    id: 'B002',
    lecturerId: 'L_DED',
    lecturerName: demoLecturerDedName,
    programId: 'DED',
    departmentId: 'elektrik',
    subject: 'ELECTRICAL CIRCUIT THEORY 1',
    section: 'DED 1B',
    originalDate: '2026-05-19',
    originalTime: '10:00 - 12:00',
    replacementDate: '2026-05-21',
    replacementStart: '14:00',
    replacementEnd: '16:00',
    roomId: 'PLC LAB',
    roomName: 'PLC LAB',
    room: 'PLC LAB',
    reason: 'Mesyuarat jabatan',
    remarks: 'Diluluskan untuk demo.',
    updatedAt: '2026-05-19 10:00',
    status: 'Approved',
  ),
  const BookingRequest(
    id: 'B003',
    lecturerId: 'L_DCP',
    lecturerName: 'Pensyarah DCP (Demo)',
    programId: 'DCP',
    departmentId: 'elektrik',
    subject: 'Demo kelas ganti DCP',
    section: 'DCP 1A',
    originalDate: '2026-05-20',
    originalTime: '08:00 - 10:00',
    replacementDate: '2026-05-21',
    replacementStart: '14:30',
    replacementEnd: '15:30',
    roomId: 'PLC LAB',
    roomName: 'PLC LAB',
    room: 'PLC LAB',
    reason: 'Pertukaran jadual',
    remarks: 'Ditolak untuk demo kerana bertindih dengan tempahan B002.',
    updatedAt: '2026-05-20 11:00',
    status: 'Rejected',
  ),
  const BookingRequest(
    id: 'B004',
    lecturerId: 'L_DGS',
    lecturerName: demoLecturerDgsName,
    programId: 'DGS',
    subject: 'Demo kelas ganti DGS',
    section: 'DGS 1A',
    originalDate: '2026-05-20',
    originalTime: '10:00 - 12:00',
    replacementDate: '2026-05-23',
    replacementStart: '09:00',
    replacementEnd: '11:00',
    roomId: 'SMART CLASSROOM',
    roomName: 'SMART CLASSROOM',
    room: 'SMART CLASSROOM',
    reason: 'Program DGS tanpa Ketua Jabatan',
    remarks: 'Untuk ujian laluan Ketua Program.',
    status: 'Pending',
  ),
  const BookingRequest(
    id: 'B005',
    lecturerId: 'L_SMI',
    lecturerName: 'Pensyarah SMI (Demo)',
    programId: 'SMI',
    departmentId: 'mekanikal',
    subject: 'Demo kelas ganti SMI',
    section: 'SMI 1A',
    originalDate: '2026-05-20',
    originalTime: '08:00 - 10:00',
    replacementDate: '2026-05-24',
    replacementStart: '10:00',
    replacementEnd: '12:00',
    roomId: 'SMI BILIK KULIAH 1',
    roomName: 'SMI BILIK KULIAH 1',
    room: 'SMI BILIK KULIAH 1',
    reason: 'Kelas ganti mekanikal',
    remarks: 'Untuk ujian laluan Ketua Jabatan Mekanikal.',
    status: 'Pending',
  ),
  const BookingRequest(
    id: 'B006',
    lecturerId: 'L_SMM',
    lecturerName: 'Pensyarah SMM (Demo)',
    programId: 'SMM',
    departmentId: 'automotif',
    subject: 'Demo kelas ganti SMM',
    section: 'SMM 1A',
    originalDate: '2026-05-20',
    originalTime: '14:00 - 16:00',
    replacementDate: '2026-05-24',
    replacementStart: '14:00',
    replacementEnd: '16:00',
    roomId: 'SMART CLASSROOM',
    roomName: 'SMART CLASSROOM',
    room: 'SMART CLASSROOM',
    reason: 'Kelas ganti automotif',
    remarks: 'Untuk ujian laluan Ketua Jabatan Automotif.',
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

List<AttendanceSeedBundle> attendanceBundlesForSlot(TimetableSlot slot) {
  if (!const {'DED 1A', 'DGS 1A', 'SMI 1A'}.contains(slot.section)) {
    return const [];
  }
  final sectionStudents =
      students.where((s) => s.section == slot.section).toList();
  if (sectionStudents.isEmpty) return const [];

  final result = <AttendanceSeedBundle>[];
  for (var week = 1; week <= 4; week++) {
    final records = <AttendanceRecord>[];
    for (var i = 0; i < sectionStudents.length; i++) {
      final student = sectionStudents[i];
      final status = _attendancePatternFor(i, week);
      records.add(AttendanceRecord(
        id: 'AR_${slot.id}_W${week}_${student.id}',
        sessionId: 'AS_${slot.id}_W$week',
        slotId: slot.id,
        studentId: student.id,
        studentName: student.name,
        programId: slot.programId,
        programName: slot.program,
        departmentId: slot.departmentId,
        section: slot.section,
        weekNo: week,
        sessionDate: _sessionDateForWeek(week),
        status: status,
        checkIn: status.countsAsAttended ? slot.startTime : '-',
        remarks: status.isExempt ? 'Dikecualikan untuk demo' : '',
        createdBy: slot.lecturerId,
      ));
    }

    final summary = _summaryFor(records);
    final session = AttendanceSession(
      id: 'AS_${slot.id}_W$week',
      slotId: slot.id,
      sessionDate: _sessionDateForWeek(week),
      weekNo: week,
      academicSession: slot.academicSessionId ??
          TimetableCsvTemplate.defaultAcademicSessionId,
      semester: slot.semester,
      programId: slot.programId ?? slot.program,
      programName: slot.program,
      departmentId: slot.departmentId,
      section: slot.section,
      subjectCode: slot.subjectCode,
      subjectName: slot.subjectName,
      lecturerId: slot.lecturerId,
      lecturerName: slot.lecturerName,
      status: 'submitted',
      totalStudents: sectionStudents.length,
      presentCount: summary.present,
      lateCount: summary.late,
      absentCount: summary.absent,
      mcCount: summary.mc,
      ckCount: summary.ck,
      attendancePercentage: summary.percentage,
      duplicateKey: '${slot.id}_${_sessionDateForWeek(week)}_$week',
      createdBy: slot.lecturerId,
      submittedAt: '${_sessionDateForWeek(week)} 12:00',
    );
    result.add(AttendanceSeedBundle(session: session, records: records));
  }
  return result;
}

ProgramCode _programById(String programId) =>
    programs.firstWhere((program) => program.id == programId);

SubjectCourse _subjectById(String subjectId) =>
    subjectsForSeed.firstWhere((subject) => subject.subjectId == subjectId);

List<SubjectCourse> _subjectsForProgram(String programId) {
  final subjects = subjectsForSeed
      .where((subject) => subject.programId == programId)
      .toList(growable: false);
  if (subjects.isNotEmpty) return subjects;
  return generatedDemoSubjects
      .where((subject) => subject.programId == programId)
      .toList(growable: false);
}

int _semesterForSection(String section) {
  final digit = int.tryParse(section.substring(0, 1)) ?? 1;
  return digit;
}

int _demoAttendancePercentage(int studentIndex) {
  return switch (studentIndex) {
    0 => 98,
    1 => 95,
    2 => 90,
    3 => 78,
    4 => 100,
    _ => 86 + (studentIndex % 12),
  };
}

const _demoDays = ['Isnin', 'Selasa', 'Rabu', 'Khamis', 'Jumaat'];
const _timeBlocks = [
  ['08:00', '10:00'],
  ['10:00', '12:00'],
  ['14:00', '16:00'],
  ['16:00', '18:00'],
];

const _roomCycle = [
  'BILIK KULIAH DED 1',
  'BILIK KULIAH DED 2',
  'ELEC MACHINE LAB',
  'ELEC PRINCPLE LAB',
  'PLC LAB',
  'SMART CLASSROOM',
  'COMP. LAB 1',
  'COMP. LAB 2',
  'BK1 DPP',
  'BK2 DPP',
  'SMI BILIK KULIAH 1',
  'SMI PLC LAB',
  'SLR 1A',
  'SLR LAB 2',
  'BAS LAB',
  'POWER E LAB',
];

String _roomForIndex(int index) => _roomCycle[index % _roomCycle.length];

String _roomId(String roomName) => roomName.replaceAll(RegExp(r'[/\\.]'), '_');

TimetableSlot _slot({
  required String id,
  required String programId,
  required String sectionSuffix,
  required SubjectCourse subject,
  required String day,
  required String startTime,
  required String endTime,
  required String roomName,
  required String slotType,
  required String sourceUploadId,
  String lecturerProgramId = '',
}) {
  final program = _programById(programId);
  final classId = '$programId $sectionSuffix';
  final assignedLecturer = lecturerProgramId.isEmpty
      ? _realAssignmentForSlot(
          programId: programId,
          classId: classId,
          subjectCode: subject.subjectCode,
        )
      : null;
  final lecturerId = assignedLecturer?.lecturerId ??
      (lecturerProgramId.isEmpty ? 'L_$programId' : 'L_$lecturerProgramId');
  final lecturerName = assignedLecturer?.lecturerName ??
      (lecturerProgramId.isEmpty
          ? _demoLecturerName(programId)
          : _demoLecturerName(lecturerProgramId));
  final lecturerEmail = assignedLecturer?.lecturerEmail ??
      'pensyarah_${(lecturerProgramId.isEmpty ? programId : lecturerProgramId).toLowerCase()}@tvetmara.edu.my';
  final lecturerProfileId = assignedLecturer?.lecturerId;
  return TimetableSlot(
    id: id,
    timetableSlotId: id,
    academicSessionId: TimetableCsvTemplate.defaultAcademicSessionId,
    programId: programId,
    departmentId: program.departmentId,
    classId: classId,
    subjectId: subject.subjectId,
    session: TimetableCsvTemplate.defaultAcademicSessionId,
    semester: _semesterForSection(sectionSuffix),
    program: program.name,
    section: classId,
    subjectCode: subject.subjectCode,
    subjectName: subject.subjectName,
    lecturerId: lecturerId,
    lecturerName: lecturerName,
    lecturerEmail: lecturerEmail,
    lecturerProfileId: lecturerProfileId,
    roomId: _roomId(roomName),
    roomName: roomName,
    day: day,
    date: '2026-05-18',
    dayOfWeek: day,
    startTime: startTime,
    endTime: endTime,
    weekStart: '1',
    weekEnd: '18',
    room: roomName,
    enrolled: classId == 'DED 1A' ? 20 : 15,
    capacity: 30,
    classType: 'Teori/Amali',
    slotType: slotType,
    status: 'active',
    sourceUploadId: sourceUploadId,
    createdBy: 'seed_demo',
  );
}

lecturer_seed.LecturerCourseAssignmentSeed? _realAssignmentForSlot({
  required String programId,
  required String classId,
  required String subjectCode,
}) {
  final normalizedClass = classId.replaceAll(' ', '').toUpperCase();
  final exact = lecturerCourseAssignmentsForSeed
      .where((assignment) =>
          assignment.programId == programId &&
          assignment.subjectCode == subjectCode &&
          assignment.classId.replaceAll(' ', '').toUpperCase() ==
              normalizedClass)
      .firstOrNull;
  if (exact != null) return exact;

  return lecturerCourseAssignmentsForSeed
      .where((assignment) =>
          assignment.programId == programId &&
          assignment.subjectCode == subjectCode)
      .firstOrNull;
}

List<TimetableSlot> _conflictDemoSlots() {
  final dedSubjects = _subjectsForProgram('DED');
  final dcpSubjects = _subjectsForProgram('DCP');
  final dgsSubjects = _subjectsForProgram('DGS');
  return [
    _slot(
      id: 'CONFLICT_ROOM_DED1B',
      programId: 'DED',
      sectionSuffix: '1B',
      subject: dedSubjects[1],
      day: 'Rabu',
      startTime: '14:00',
      endTime: '16:00',
      roomName: 'SMART CLASSROOM',
      slotType: 'Intentional Demo Conflict - Room',
      sourceUploadId: 'seed_conflict_demo',
    ),
    _slot(
      id: 'CONFLICT_ROOM_DCP1A',
      programId: 'DCP',
      sectionSuffix: '1A',
      subject: dcpSubjects[1],
      day: 'Rabu',
      startTime: '15:00',
      endTime: '17:00',
      roomName: 'SMART CLASSROOM',
      slotType: 'Intentional Demo Conflict - Room',
      sourceUploadId: 'seed_conflict_demo',
    ),
    _slot(
      id: 'CONFLICT_LECT_DED1A',
      programId: 'DED',
      sectionSuffix: '1A',
      subject: dedSubjects[2],
      day: 'Jumaat',
      startTime: '14:00',
      endTime: '16:00',
      roomName: 'BILIK KULIAH DED 1',
      slotType: 'Intentional Demo Conflict - Lecturer',
      sourceUploadId: 'seed_conflict_demo',
      lecturerProgramId: 'DED',
    ),
    _slot(
      id: 'CONFLICT_LECT_DCP1A',
      programId: 'DCP',
      sectionSuffix: '1A',
      subject: dcpSubjects[2],
      day: 'Jumaat',
      startTime: '15:00',
      endTime: '17:00',
      roomName: 'PLC LAB',
      slotType: 'Intentional Demo Conflict - Lecturer',
      sourceUploadId: 'seed_conflict_demo',
      lecturerProgramId: 'DED',
    ),
    _slot(
      id: 'CONFLICT_CLASS_DGS1A_A',
      programId: 'DGS',
      sectionSuffix: '1A',
      subject: dgsSubjects[1],
      day: 'Selasa',
      startTime: '14:00',
      endTime: '16:00',
      roomName: 'BILIK KULIAH DED 2',
      slotType: 'Intentional Demo Conflict - Class',
      sourceUploadId: 'seed_conflict_demo',
    ),
    _slot(
      id: 'CONFLICT_CLASS_DGS1A_B',
      programId: 'DGS',
      sectionSuffix: '1A',
      subject: dgsSubjects[2],
      day: 'Selasa',
      startTime: '15:00',
      endTime: '17:00',
      roomName: 'ELEC PRINCPLE LAB',
      slotType: 'Intentional Demo Conflict - Class',
      sourceUploadId: 'seed_conflict_demo',
    ),
  ];
}

String _studentIdForClass(String classId, int oneBasedIndex) {
  final classStudents =
      students.where((student) => student.section == classId).toList();
  if (classStudents.isEmpty) return '';
  return classStudents[(oneBasedIndex - 1).clamp(0, classStudents.length - 1)]
      .id;
}

String _studentNameForClass(String classId, int oneBasedIndex) {
  final classStudents =
      students.where((student) => student.section == classId).toList();
  if (classStudents.isEmpty) return '';
  return classStudents[(oneBasedIndex - 1).clamp(0, classStudents.length - 1)]
      .name;
}

String _sessionDateForWeek(int week) =>
    '2026-01-${(12 + ((week - 1) * 7)).toString().padLeft(2, '0')}';

AttendanceStatus _attendancePatternFor(int studentIndex, int week) {
  if (studentIndex == 0) return AttendanceStatus.present;
  if (studentIndex == 1) {
    return week == 4 ? AttendanceStatus.absent : AttendanceStatus.present;
  }
  if (studentIndex == 2) {
    return week == 3 ? AttendanceStatus.absent : AttendanceStatus.late;
  }
  if (studentIndex == 3) {
    return week == 1 ? AttendanceStatus.present : AttendanceStatus.absent;
  }
  if (studentIndex == 4) {
    return week.isEven ? AttendanceStatus.mc : AttendanceStatus.ck;
  }
  return switch ((studentIndex + week) % 6) {
    0 => AttendanceStatus.absent,
    1 => AttendanceStatus.late,
    _ => AttendanceStatus.present,
  };
}

AttendanceSummary _summaryFor(List<AttendanceRecord> records) {
  var summary =
      const AttendanceSummary(present: 0, late: 0, absent: 0, mc: 0, ck: 0);
  for (final record in records) {
    summary = summary.add(record.status);
  }
  return summary;
}
