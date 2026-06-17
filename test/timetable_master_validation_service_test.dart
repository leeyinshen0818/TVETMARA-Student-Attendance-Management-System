import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tvetmara_student_attendance/data/mock_data.dart' as mock;
import 'package:tvetmara_student_attendance/models/app_models.dart';
import 'package:tvetmara_student_attendance/models/timetable_import_result.dart';
import 'package:tvetmara_student_attendance/services/timetable_import_service.dart';
import 'package:tvetmara_student_attendance/services/timetable_master_validation_service.dart';

const _header =
    'academicSessionId,programId,programName,classId,subjectCode,subjectName,subjectId,lecturerEmail,lecturerName,roomId,roomName,dayOfWeek,startTime,endTime,weekStart,weekEnd,status,remarks';

String _row({
  String academicSessionId = '2026_S1',
  String programId = 'DED',
  String programName = 'DIPLOMA TEKNOLOGI KEJURUTERAAN ELEKTRIK (DED)',
  String classId = 'DED_1A',
  String subjectCode = 'DED10044',
  String subjectName = 'Wiring and Installation Practice',
  String subjectId = 'DED_DED10044',
  String lecturerEmail = 'pensyarah_ded@tvetmara.edu.my',
  String lecturerName = 'Pensyarah DED',
  String roomId = 'BILIK_KULIAH_1',
  String roomName = 'BILIK KULIAH 1',
  String dayOfWeek = 'Isnin',
  String startTime = '08:00',
  String endTime = '10:00',
  String weekStart = '1',
  String weekEnd = '18',
  String status = 'active',
  String remarks = '',
}) {
  return [
    academicSessionId,
    programId,
    programName,
    classId,
    subjectCode,
    subjectName,
    subjectId,
    lecturerEmail,
    lecturerName,
    roomId,
    roomName,
    dayOfWeek,
    startTime,
    endTime,
    weekStart,
    weekEnd,
    status,
    remarks,
  ].join(',');
}

TimetableImportResult _parse(String row) {
  return const TimetableImportService().parseAndValidate('$_header\n$row');
}

TimetableImportResult _parseRows(List<String> rows) {
  return const TimetableImportService()
      .parseAndValidate('$_header\n${rows.join('\n')}');
}

class _FakeMasterDataSource implements TimetableMasterDataSource {
  _FakeMasterDataSource({
    Map<String, ProgramCode>? programs,
    Map<String, AppUser>? lecturers,
    Map<String, TimetableRoomMaster>? rooms,
    Set<String>? subjectIds,
    Set<String>? classIds,
    Set<String>? academicSessionIds,
    Set<String>? duplicateKeys,
  })  : programs = programs ?? _defaultPrograms,
        lecturers = lecturers ?? _defaultLecturers,
        rooms = rooms ?? _defaultRooms,
        subjectIds = subjectIds ?? {'DED_DED10044'},
        classIds = classIds ?? {'DED_1A'},
        academicSessionIds = academicSessionIds ?? {'2026_S1'},
        duplicateKeys = duplicateKeys ?? {};

  final Map<String, ProgramCode> programs;
  final Map<String, AppUser> lecturers;
  final Map<String, TimetableRoomMaster> rooms;
  final Set<String> subjectIds;
  final Set<String> classIds;
  final Set<String> academicSessionIds;
  final Set<String> duplicateKeys;

  static const _defaultPrograms = {
    'DED': ProgramCode(id: 'DED', name: 'Elektrik', departmentId: 'elektrik'),
    'DCP': ProgramCode(id: 'DCP', name: 'DCP', departmentId: 'elektrik'),
    'DCB': ProgramCode(id: 'DCB', name: 'DCB', departmentId: 'elektrik'),
    'DGS': ProgramCode(id: 'DGS', name: 'Gas', departmentId: null),
    'ITW': ProgramCode(id: 'ITW', name: 'ITW', departmentId: 'mekanikal'),
    'SLR': ProgramCode(id: 'SLR', name: 'SLR', departmentId: 'mekanikal'),
    'SMI': ProgramCode(id: 'SMI', name: 'SMI', departmentId: 'mekanikal'),
    'IMF': ProgramCode(id: 'IMF', name: 'IMF', departmentId: 'automotif'),
    'SMM': ProgramCode(id: 'SMM', name: 'SMM', departmentId: 'automotif'),
    'DMM': ProgramCode(id: 'DMM', name: 'DMM', departmentId: 'automotif'),
  };

  static const _defaultLecturers = {
    'pensyarah_ded@tvetmara.edu.my': AppUser(
      uid: 'UID_DED',
      name: 'Pensyarah DED',
      email: 'pensyarah_ded@tvetmara.edu.my',
      role: UserRole.pensyarah,
      programId: 'DED',
      departmentId: 'elektrik',
      lecturerProfileId: 'REAL_L_046',
      isActive: true,
    ),
    'pensyarah_dgs@tvetmara.edu.my': AppUser(
      uid: 'UID_DGS',
      name: 'Pensyarah DGS',
      email: 'pensyarah_dgs@tvetmara.edu.my',
      role: UserRole.pensyarah,
      programId: 'DGS',
      isActive: true,
    ),
  };

  static const _defaultRooms = {
    'BILIK_KULIAH_1': TimetableRoomMaster(
      roomId: 'BILIK_KULIAH_1',
      name: 'BILIK KULIAH 1',
    ),
  };

  @override
  Future<Map<String, ProgramCode>> getProgramsById(Set<String> programIds) {
    return Future.value({
      for (final id in programIds)
        if (programs[id] != null) id: programs[id]!,
    });
  }

  @override
  Future<Map<String, AppUser>> getLecturersByEmail(Set<String> emails) {
    return Future.value({
      for (final email in emails)
        if (lecturers[email.toLowerCase()] != null)
          email.toLowerCase(): lecturers[email.toLowerCase()]!,
    });
  }

  @override
  Future<Map<String, TimetableRoomMaster>> getRoomsById(Set<String> roomIds) {
    return Future.value({
      for (final id in roomIds)
        if (rooms[id] != null) id: rooms[id]!,
    });
  }

  @override
  Future<Set<String>> getExistingSubjectIds(Set<String> subjectIds) {
    return Future.value(subjectIds.intersection(this.subjectIds));
  }

  @override
  Future<Set<String>> getExistingClassIds(Set<String> classIds) {
    return Future.value(classIds.intersection(this.classIds));
  }

  @override
  Future<Set<String>> getExistingAcademicSessionIds(Set<String> sessionIds) {
    return Future.value(sessionIds.intersection(academicSessionIds));
  }

  @override
  Future<Set<String>> getExistingTimetableDuplicateKeys() {
    return Future.value(duplicateKeys);
  }
}

class _MockMasterDataSource implements TimetableMasterDataSource {
  const _MockMasterDataSource();

  @override
  Future<Map<String, ProgramCode>> getProgramsById(Set<String> programIds) {
    final programs = {for (final program in mock.programs) program.id: program};
    return Future.value({
      for (final id in programIds)
        if (programs[id] != null) id: programs[id]!,
    });
  }

  @override
  Future<Map<String, AppUser>> getLecturersByEmail(Set<String> emails) {
    final users = {
      for (final user in mock.users) user.email.toLowerCase(): user,
    };
    return Future.value({
      for (final email in emails)
        if (users[email.toLowerCase()] != null)
          email.toLowerCase(): users[email.toLowerCase()]!,
    });
  }

  @override
  Future<Map<String, TimetableRoomMaster>> getRoomsById(Set<String> roomIds) {
    final rooms = {
      for (final room in mock.roomResources)
        room.name.replaceAll(RegExp(r'[/\\.]'), '_'): TimetableRoomMaster(
          roomId: room.name.replaceAll(RegExp(r'[/\\.]'), '_'),
          name: room.name,
        ),
    };
    return Future.value({
      for (final id in roomIds)
        if (rooms[id] != null) id: rooms[id]!,
    });
  }

  @override
  Future<Set<String>> getExistingSubjectIds(Set<String> subjectIds) {
    final ids =
        mock.subjectsForSeed.map((subject) => subject.subjectId).toSet();
    return Future.value(subjectIds.intersection(ids));
  }

  @override
  Future<Set<String>> getExistingClassIds(Set<String> classIds) {
    final ids = mock.demoClasses.map((item) => item.classId).toSet();
    return Future.value(classIds.intersection(ids));
  }

  @override
  Future<Set<String>> getExistingAcademicSessionIds(Set<String> sessionIds) {
    final ids = mock.academicSessions
        .map((session) => session.academicSessionId)
        .toSet();
    return Future.value(sessionIds.intersection(ids));
  }

  @override
  Future<Set<String>> getExistingTimetableDuplicateKeys() {
    return Future.value({});
  }
}

const _kjElektrik = AppUser(
  uid: 'KJ_ELEKTRIK',
  name: 'KJ Elektrik',
  email: 'kj_elektrik@tvetmara.edu.my',
  role: UserRole.ketua_jabatan,
  departmentId: 'elektrik',
  isActive: true,
);

const _kjMekanikal = AppUser(
  uid: 'KJ_MEKANIKAL',
  name: 'KJ Mekanikal',
  email: 'kj_mekanikal@tvetmara.edu.my',
  role: UserRole.ketua_jabatan,
  departmentId: 'mekanikal',
  isActive: true,
);

const _kjAutomotif = AppUser(
  uid: 'KJ_AUTOMOTIF',
  name: 'KJ Automotif',
  email: 'kj_automotif@tvetmara.edu.my',
  role: UserRole.ketua_jabatan,
  departmentId: 'automotif',
  isActive: true,
);

const _kpDgs = AppUser(
  uid: 'KP_DGS',
  name: 'KP DGS',
  email: 'kp_dgs@tvetmara.edu.my',
  role: UserRole.ketua_program,
  programId: 'DGS',
  isActive: true,
);

TimetableUploadScope _scopeFor(AppUser user, _FakeMasterDataSource source) {
  return TimetableUploadScope.forUser(user, source.programs.values);
}

void main() {
  setUpAll(mock.initializeMockData);

  test('prepares valid preview row with existing program, lecturer, and room',
      () async {
    final result = await TimetableMasterValidationService(
      _FakeMasterDataSource(),
    ).preparePreview(_parse(_row()));

    expect(result.validRows, 1);
    expect(result.previewRows.single.warnings, isEmpty);
    expect(result.canImport, isTrue);
    final draft = result.previewRows.single.slotDraft!;
    expect(draft.programId, 'DED');
    expect(draft.departmentId, 'elektrik');
    expect(draft.lecturerId, 'UID_DED');
    expect(draft.lecturerEmail, 'pensyarah_ded@tvetmara.edu.my');
    expect(draft.lecturerProfileId, 'REAL_L_046');
    expect(draft.lecturerName, 'Pensyarah DED');
    expect(draft.roomName, 'BILIK KULIAH 1');
  });

  test('missing program marks row as error', () async {
    final result = await TimetableMasterValidationService(
      _FakeMasterDataSource(),
    ).preparePreview(_parse(_row(programId: 'MISSING')));

    expect(result.errorRows, 1);
    expect(result.previewRows.single.errors.single, contains('programId'));
  });

  test('missing lecturer marks row as error', () async {
    final result = await TimetableMasterValidationService(
      _FakeMasterDataSource(),
    ).preparePreview(_parse(_row(lecturerEmail: 'missing@tvetmara.edu.my')));

    expect(result.errorRows, 1);
    expect(result.previewRows.single.errors.single, contains('lecturerEmail'));
  });

  test('inactive lecturer marks row as error', () async {
    final result = await TimetableMasterValidationService(
      _FakeMasterDataSource(
        lecturers: {
          'inactive@tvetmara.edu.my': const AppUser(
            uid: 'UID_INACTIVE',
            name: 'Inactive Lecturer',
            email: 'inactive@tvetmara.edu.my',
            role: UserRole.pensyarah,
            isActive: false,
          ),
        },
      ),
    ).preparePreview(_parse(_row(lecturerEmail: 'inactive@tvetmara.edu.my')));

    expect(result.errorRows, 1);
    expect(result.previewRows.single.errors.single, contains('inactive'));
  });

  test('wrong lecturer role marks row as error', () async {
    final result = await TimetableMasterValidationService(
      _FakeMasterDataSource(
        lecturers: {
          'kp@tvetmara.edu.my': const AppUser(
            uid: 'UID_KP',
            name: 'KP DED',
            email: 'kp@tvetmara.edu.my',
            role: UserRole.ketua_program,
            isActive: true,
          ),
        },
      ),
    ).preparePreview(_parse(_row(lecturerEmail: 'kp@tvetmara.edu.my')));

    expect(result.errorRows, 1);
    expect(result.previewRows.single.errors.single, contains('pensyarah'));
  });

  test('missing room marks row as error', () async {
    final result = await TimetableMasterValidationService(
      _FakeMasterDataSource(),
    ).preparePreview(_parse(_row(roomId: 'MISSING_ROOM')));

    expect(result.errorRows, 1);
    expect(result.previewRows.single.errors.single, contains('roomId'));
  });

  test('missing subject creates warning and upsert draft', () async {
    final result = await TimetableMasterValidationService(
      _FakeMasterDataSource(subjectIds: {}),
    ).preparePreview(_parse(_row()));

    expect(result.warningRows, 1);
    expect(result.subjectUpsertDraftsCount, 1);
    expect(result.subjectUpsertDrafts.single.subjectId, 'DED_DED10044');
  });

  test('missing class creates warning and class draft', () async {
    final result = await TimetableMasterValidationService(
      _FakeMasterDataSource(classIds: {}),
    ).preparePreview(_parse(_row()));

    expect(result.warningRows, 1);
    expect(result.classCreateDraftsCount, 1);
    expect(result.classCreateDrafts.single.classId, 'DED_1A');
  });

  test('missing academic session is a warning, not an error', () async {
    final result = await TimetableMasterValidationService(
      _FakeMasterDataSource(academicSessionIds: {}),
    ).preparePreview(_parse(_row()));

    expect(result.warningRows, 1);
    expect(result.errorRows, 0);
    expect(result.previewRows.single.warnings.single,
        contains('Academic session'));
  });

  test('DGS programme allows null departmentId', () async {
    final result = await TimetableMasterValidationService(
      _FakeMasterDataSource(
        subjectIds: {'DGS_DGS10044'},
        classIds: {'DGS_1A'},
      ),
    ).preparePreview(_parse(_row(
      programId: 'DGS',
      classId: 'DGS_1A',
      subjectCode: 'DGS10044',
      subjectId: 'DGS_DGS10044',
      lecturerEmail: 'pensyarah_dgs@tvetmara.edu.my',
    )));

    expect(result.validRows, 1);
    expect(result.previewRows.single.slotDraft!.departmentId, isNull);
  });

  test('existing Firestore duplicate marks row as duplicate', () async {
    final duplicateKey = TimetableMasterValidationService.duplicateKey(
      academicSessionId: '2026_S1',
      programId: 'DED',
      classId: 'DED_1A',
      subjectCode: 'DED10044',
      lecturerId: 'UID_DED',
      dayOfWeek: 'Isnin',
      startTime: '08:00',
      endTime: '10:00',
      roomId: 'BILIK_KULIAH_1',
      weekStart: '1',
      weekEnd: '18',
    );

    final result = await TimetableMasterValidationService(
      _FakeMasterDataSource(duplicateKeys: {duplicateKey}),
    ).preparePreview(_parse(_row()));

    expect(result.duplicateRows, 1);
    expect(result.canImport, isFalse);
    expect(result.importableRows, 0);
    expect(
        result.previewRows.single.status, TimetableImportRowStatus.duplicate);
  });

  test('CSV duplicate remains duplicate after master validation', () async {
    final result = await TimetableMasterValidationService(
      _FakeMasterDataSource(),
    ).preparePreview(_parseRows([_row(), _row()]));

    expect(result.validRows, 1);
    expect(result.duplicateRows, 1);
    expect(result.errorRows, 0);
    expect(result.previewRows.last.status, TimetableImportRowStatus.duplicate);
  });

  test('KJ Elektrik accepts DED, DCP, and DCB upload rows', () async {
    final source = _FakeMasterDataSource();
    final result =
        await TimetableMasterValidationService(source).preparePreview(
      _parseRows([
        _row(programId: 'DED'),
        _row(programId: 'DCP', subjectId: 'DCP_MEP20012'),
        _row(programId: 'DCB', subjectId: 'DCB_MEB10023'),
      ]),
      uploadScope: _scopeFor(_kjElektrik, source),
    );

    expect(result.errorRows, 0);
    expect(result.importableRows, 3);
  });

  test('KJ Elektrik rejects DGS, ITW, and SMM upload rows', () async {
    final source = _FakeMasterDataSource();
    final result =
        await TimetableMasterValidationService(source).preparePreview(
      _parseRows([
        _row(programId: 'DGS'),
        _row(programId: 'ITW'),
        _row(programId: 'SMM'),
      ]),
      uploadScope: _scopeFor(_kjElektrik, source),
    );

    expect(result.errorRows, 3);
    expect(result.importableRows, 0);
    expect(result.previewRows.first.errors.join(' '), contains('DGS'));
    expect(
        result.previewRows.first.errors.join(' '), contains('DED, DCP, DCB'));
    expect(result.validationWarnings.single, contains('DGS, ITW, SMM'));
  });

  test('KP DGS accepts DGS and rejects Elektrik programmes', () async {
    final source = _FakeMasterDataSource();
    final result =
        await TimetableMasterValidationService(source).preparePreview(
      _parseRows([
        _row(programId: 'DGS'),
        _row(programId: 'DED'),
        _row(programId: 'DCP'),
        _row(programId: 'DCB'),
      ]),
      uploadScope: _scopeFor(_kpDgs, source),
    );

    expect(result.importableRows, 1);
    expect(result.errorRows, 3);
    expect(result.previewRows.first.errors, isEmpty);
    expect(result.previewRows[1].errors.join(' '), contains('Program DED'));
    expect(result.previewRows[1].errors.join(' '),
        contains('Skop dibenarkan: DGS'));
  });

  test('KJ Mekanikal accepts ITW, SLR, and SMI upload rows', () async {
    final source = _FakeMasterDataSource();
    final result =
        await TimetableMasterValidationService(source).preparePreview(
      _parseRows([
        _row(programId: 'ITW'),
        _row(programId: 'SLR'),
        _row(programId: 'SMI'),
      ]),
      uploadScope: _scopeFor(_kjMekanikal, source),
    );

    expect(result.errorRows, 0);
    expect(result.importableRows, 3);
  });

  test('KJ Automotif accepts IMF, SMM, and DMM upload rows', () async {
    final source = _FakeMasterDataSource();
    final result =
        await TimetableMasterValidationService(source).preparePreview(
      _parseRows([
        _row(programId: 'IMF'),
        _row(programId: 'SMM'),
        _row(programId: 'DMM'),
      ]),
      uploadScope: _scopeFor(_kjAutomotif, source),
    );

    expect(result.errorRows, 0);
    expect(result.importableRows, 3);
  });

  test('scoped clean CSV files pass for the correct Ketua users', () async {
    const source = _MockMasterDataSource();

    final elektrik =
        await const TimetableMasterValidationService(source).preparePreview(
      const TimetableImportService().parseAndValidate(
        File('demo_data/clean_no_conflict_timetable_ELEKTRIK_JAN_JUN_2026.csv')
            .readAsStringSync(),
      ),
      uploadScope: TimetableUploadScope.forUser(_kjElektrik, mock.programs),
    );
    final dgs =
        await const TimetableMasterValidationService(source).preparePreview(
      const TimetableImportService().parseAndValidate(
        File('demo_data/clean_no_conflict_timetable_DGS_JAN_JUN_2026.csv')
            .readAsStringSync(),
      ),
      uploadScope: TimetableUploadScope.forUser(_kpDgs, mock.programs),
    );

    expect(elektrik.errorRows, 0);
    expect(elektrik.importableRows, 30);
    expect(dgs.errorRows, 0);
    expect(dgs.importableRows, 10);
  });

  test('Elektrik conflict demo CSV is valid for KJ Elektrik upload', () async {
    final content = File(
      'demo_data/demo_conflict_timetable_ELEKTRIK_JAN_JUN_2026.csv',
    ).readAsStringSync();
    final result = await const TimetableMasterValidationService(
      _MockMasterDataSource(),
    ).preparePreview(
      const TimetableImportService().parseAndValidate(content),
      uploadScope: TimetableUploadScope.forUser(_kjElektrik, mock.programs),
    );

    expect(result.errorRows, 0);
    expect(result.duplicateRows, 0);
    expect(result.importableRows, 30);
  });

  test('mixed legacy CSV fails scope validation for KJ Elektrik', () async {
    final result = await const TimetableMasterValidationService(
      _MockMasterDataSource(),
    ).preparePreview(
      const TimetableImportService().parseAndValidate(
        File('demo_data/clean_no_conflict_timetable_JAN_JUN_2026.csv')
            .readAsStringSync(),
      ),
      uploadScope: TimetableUploadScope.forUser(_kjElektrik, mock.programs),
    );

    expect(result.errorRows, greaterThan(0));
    expect(result.importableRows, lessThan(result.totalRows));
    expect(result.validationWarnings.join(' '), contains('DGS'));
  });
}
