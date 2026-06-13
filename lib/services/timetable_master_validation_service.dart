import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_constants.dart';
import '../models/app_models.dart';
import '../models/timetable_import_result.dart';
import '../models/timetable_master_validation_result.dart';

class TimetableRoomMaster {
  const TimetableRoomMaster({
    required this.roomId,
    required this.name,
  });

  final String roomId;
  final String name;
}

class TimetableUploadScope {
  const TimetableUploadScope({
    required this.allowedProgramIds,
    required this.scopeLabel,
  });

  final Set<String> allowedProgramIds;
  final String scopeLabel;

  factory TimetableUploadScope.forUser(
    AppUser user,
    Iterable<ProgramCode> programs,
  ) {
    final programList = programs.toList();
    if (user.role == UserRole.pentadbir) {
      return TimetableUploadScope(
        allowedProgramIds: programList.map((program) => program.id).toSet(),
        scopeLabel: 'Pentadbir',
      );
    }
    if (user.role == UserRole.ketua_jabatan) {
      final allowed = programList
          .where((program) => program.departmentId == user.departmentId)
          .map((program) => program.id)
          .toSet();
      return TimetableUploadScope(
        allowedProgramIds: allowed,
        scopeLabel: _departmentScopeLabel(user.departmentId),
      );
    }
    if (user.role == UserRole.ketua_program && user.programId != null) {
      return TimetableUploadScope(
        allowedProgramIds: {user.programId!},
        scopeLabel: 'Program ${user.programId}',
      );
    }
    return const TimetableUploadScope(
      allowedProgramIds: {},
      scopeLabel: 'pengguna ini',
    );
  }

  bool allows(String programId) =>
      allowedProgramIds.contains(programId.trim().toUpperCase());

  String errorMessageFor(String programId) {
    final normalizedProgramId = programId.trim().toUpperCase();
    if (allowedProgramIds.isEmpty) {
      return 'Program $normalizedProgramId bukan dalam skop $scopeLabel. Tiada program dibenarkan untuk muat naik jadual.';
    }
    return 'Program $normalizedProgramId bukan dalam skop $scopeLabel. Skop dibenarkan: ${allowedProgramIds.join(', ')}.';
  }

  static String _departmentScopeLabel(String? departmentId) {
    return switch (departmentId) {
      'elektrik' => 'Jabatan Elektrik',
      'mekanikal' => 'Jabatan Mekanikal',
      'automotif' => 'Jabatan Automotif',
      null || '' => 'jabatan pengguna',
      _ => 'Jabatan $departmentId',
    };
  }
}

abstract class TimetableMasterDataSource {
  Future<Map<String, ProgramCode>> getProgramsById(Set<String> programIds);
  Future<Map<String, AppUser>> getLecturersByEmail(Set<String> emails);
  Future<Map<String, TimetableRoomMaster>> getRoomsById(Set<String> roomIds);
  Future<Set<String>> getExistingSubjectIds(Set<String> subjectIds);
  Future<Set<String>> getExistingClassIds(Set<String> classIds);
  Future<Set<String>> getExistingAcademicSessionIds(Set<String> sessionIds);
  Future<Set<String>> getExistingTimetableDuplicateKeys();
}

class FirestoreTimetableMasterDataSource implements TimetableMasterDataSource {
  FirestoreTimetableMasterDataSource({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<Map<String, ProgramCode>> getProgramsById(Set<String> programIds) {
    return _getDocsById(programIds, FirestoreCollections.programs, (id, data) {
      return ProgramCode(
        id: id,
        name: data['name'] as String? ?? id,
        departmentId: data['departmentId'] as String?,
      );
    });
  }

  @override
  Future<Map<String, AppUser>> getLecturersByEmail(Set<String> emails) async {
    final result = <String, AppUser>{};
    for (final email in emails) {
      final normalizedEmail = email.trim().toLowerCase();
      if (normalizedEmail.isEmpty) continue;
      final snap = await _db
          .collection(FirestoreCollections.users)
          .where(UserFields.email, isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) continue;
      final doc = snap.docs.first;
      final data = doc.data();
      result[normalizedEmail] = AppUser(
        uid: data[UserFields.uid] as String? ?? doc.id,
        name: data[UserFields.name] as String? ?? '',
        email: data[UserFields.email] as String? ?? normalizedEmail,
        role: UserRole.fromFirestore(data[UserFields.role] as String?),
        programId: data[UserFields.programId] as String?,
        departmentId: data[UserFields.departmentId] as String?,
        phoneNumber: data[UserFields.phoneNumber] as String?,
        lecturerProfileId: data[UserFields.lecturerProfileId] as String?,
        isActive: data[UserFields.isActive] as bool? ?? true,
      );
    }
    return result;
  }

  @override
  Future<Map<String, TimetableRoomMaster>> getRoomsById(Set<String> roomIds) {
    return _getDocsById(roomIds, FirestoreCollections.rooms, (id, data) {
      return TimetableRoomMaster(
        roomId: id,
        name: data['name'] as String? ?? id,
      );
    });
  }

  @override
  Future<Set<String>> getExistingSubjectIds(Set<String> subjectIds) {
    return _getExistingIds(subjectIds, FirestoreCollections.subjects);
  }

  @override
  Future<Set<String>> getExistingClassIds(Set<String> classIds) {
    return _getExistingIds(classIds, FirestoreCollections.classes);
  }

  @override
  Future<Set<String>> getExistingAcademicSessionIds(Set<String> sessionIds) {
    return _getExistingIds(sessionIds, FirestoreCollections.academicSessions);
  }

  @override
  Future<Set<String>> getExistingTimetableDuplicateKeys() async {
    final snap =
        await _db.collection(FirestoreCollections.timetableSlots).get();
    return snap.docs
        .map((doc) => _duplicateKeyFromTimetableData(doc.data()))
        .whereType<String>()
        .toSet();
  }

  Future<Map<String, T>> _getDocsById<T>(
    Set<String> ids,
    String collection,
    T Function(String id, Map<String, dynamic> data) mapper,
  ) async {
    final result = <String, T>{};
    for (final id in ids) {
      final normalizedId = id.trim();
      if (normalizedId.isEmpty) continue;
      final doc = await _db.collection(collection).doc(normalizedId).get();
      if (!doc.exists) continue;
      result[normalizedId] = mapper(normalizedId, doc.data()!);
    }
    return result;
  }

  Future<Set<String>> _getExistingIds(
      Set<String> ids, String collection) async {
    final result = <String>{};
    for (final id in ids) {
      final normalizedId = id.trim();
      if (normalizedId.isEmpty) continue;
      final doc = await _db.collection(collection).doc(normalizedId).get();
      if (doc.exists) result.add(normalizedId);
    }
    return result;
  }

  String? _duplicateKeyFromTimetableData(Map<String, dynamic> data) {
    final academicSessionId =
        data['academicSessionId'] as String? ?? data['session'] as String?;
    final programId =
        data['programId'] as String? ?? data['program'] as String?;
    final classId = data['classId'] as String? ?? data['section'] as String?;
    final subjectCode = data['subjectCode'] as String?;
    final lecturerId = data['lecturerId'] as String?;
    final dayOfWeek = data['dayOfWeek'] as String? ?? data['day'] as String?;
    final startTime = data['startTime'] as String?;
    final endTime = data['endTime'] as String?;
    final roomId = data['roomId'] as String? ?? data['room'] as String?;
    final weekStart = data['weekStart']?.toString() ?? data['date'] as String?;
    final weekEnd = data['weekEnd']?.toString() ?? data['date'] as String?;

    if ([
      academicSessionId,
      programId,
      classId,
      subjectCode,
      lecturerId,
      dayOfWeek,
      startTime,
      endTime,
      roomId,
      weekStart,
      weekEnd,
    ].any((value) => value == null || value.isEmpty)) {
      return null;
    }

    return TimetableMasterValidationService.duplicateKey(
      academicSessionId: academicSessionId!,
      programId: programId!,
      classId: classId!,
      subjectCode: subjectCode!,
      lecturerId: lecturerId!,
      dayOfWeek: dayOfWeek!,
      startTime: startTime!,
      endTime: endTime!,
      roomId: roomId!,
      weekStart: weekStart!,
      weekEnd: weekEnd!,
    );
  }
}

class TimetableMasterValidationService {
  const TimetableMasterValidationService(this._dataSource);

  final TimetableMasterDataSource _dataSource;

  Future<TimetableMasterValidationResult> preparePreview(
      TimetableImportResult importResult,
      {TimetableUploadScope? uploadScope}) async {
    if (importResult.hasFileErrors) {
      return TimetableMasterValidationResult(
        totalRows: importResult.totalRows,
        validRows: 0,
        warningRows: 0,
        duplicateRows: 0,
        errorRows: 0,
        subjectUpsertDrafts: const [],
        classCreateDrafts: const [],
        previewRows: const [],
        validationErrors: importResult.validationErrors,
        validationWarnings: importResult.validationWarnings,
      );
    }

    final draftRows = importResult.parsedRows
        .where((row) => row.draft != null)
        .map((row) => row.draft!)
        .toList();
    final programIds = draftRows.map((draft) => draft.programId).toSet();
    final emails = draftRows.map((draft) => draft.lecturerEmail).toSet();
    final roomIds = draftRows.map((draft) => draft.roomId).toSet();
    final subjectIds = draftRows.map((draft) => draft.subjectId).toSet();
    final classIds = draftRows.map((draft) => draft.classId).toSet();
    final sessionIds =
        draftRows.map((draft) => draft.academicSessionId).toSet();

    final programs = await _dataSource.getProgramsById(programIds);
    final lecturers = await _dataSource.getLecturersByEmail(emails);
    final rooms = await _dataSource.getRoomsById(roomIds);
    final existingSubjects =
        await _dataSource.getExistingSubjectIds(subjectIds);
    final existingClasses = await _dataSource.getExistingClassIds(classIds);
    final existingSessions =
        await _dataSource.getExistingAcademicSessionIds(sessionIds);
    final existingDuplicateKeys =
        await _dataSource.getExistingTimetableDuplicateKeys();

    final previewRows = <TimetablePreviewRow>[];
    final subjectDraftsById = <String, TimetableSubjectUpsertDraft>{};
    final classDraftsById = <String, TimetableClassCreateDraft>{};
    final outOfScopeProgramIds = <String>{};

    for (final row in importResult.parsedRows) {
      final errors = [...row.errors];
      final warnings = [...row.warnings];
      TimetablePreviewSlotDraft? slotDraft;
      var status = row.status;
      final draft = row.draft;

      if (draft != null) {
        final program = programs[draft.programId];
        final lecturer = lecturers[draft.lecturerEmail.toLowerCase()];
        final room = rooms[draft.roomId];

        if (program == null) {
          errors.add('programId "${draft.programId}" does not exist.');
        }

        if (uploadScope != null && !uploadScope.allows(draft.programId)) {
          outOfScopeProgramIds.add(draft.programId);
          errors.add(uploadScope.errorMessageFor(draft.programId));
        }

        if (lecturer == null) {
          errors.add(
            'lecturerEmail "${draft.lecturerEmail}" was not found in users.',
          );
        } else if (lecturer.role != UserRole.pensyarah) {
          errors.add(
            'lecturerEmail "${draft.lecturerEmail}" does not belong to a pensyarah account.',
          );
        } else if (!lecturer.isActive) {
          errors.add(
            'lecturerEmail "${draft.lecturerEmail}" belongs to an inactive account.',
          );
        }

        if (room == null) {
          errors.add('roomId "${draft.roomId}" does not exist.');
        }

        if (!existingSubjects.contains(draft.subjectId)) {
          warnings.add(
            'subjectId "${draft.subjectId}" does not exist and will be prepared for creation later.',
          );
          subjectDraftsById[draft.subjectId] = TimetableSubjectUpsertDraft(
            subjectId: draft.subjectId,
            programId: draft.programId,
            subjectCode: draft.subjectCode,
            subjectName: draft.subjectName,
          );
        }

        if (!existingClasses.contains(draft.classId)) {
          warnings.add(
            'classId "${draft.classId}" does not exist and can be prepared for creation later.',
          );
          classDraftsById[draft.classId] = TimetableClassCreateDraft(
            classId: draft.classId,
            programId: draft.programId,
            academicSessionId: draft.academicSessionId,
          );
        }

        // Missing academic sessions are warnings for this phase. This avoids
        // blocking preview while the academic_sessions module is still partial.
        if (!existingSessions.contains(draft.academicSessionId)) {
          warnings.add(
            'Academic session "${draft.academicSessionId}" was not found. Please seed or create this session before import.',
          );
        }

        if (program != null &&
            lecturer != null &&
            lecturer.role == UserRole.pensyarah &&
            lecturer.isActive &&
            room != null) {
          slotDraft = TimetablePreviewSlotDraft(
            academicSessionId: draft.academicSessionId,
            programId: draft.programId,
            programName: program.name,
            departmentId: program.departmentId,
            classId: draft.classId,
            subjectId: draft.subjectId,
            subjectCode: draft.subjectCode,
            subjectName: draft.subjectName,
            lecturerId: lecturer.uid,
            lecturerEmail: draft.lecturerEmail,
            lecturerProfileId: lecturer.lecturerProfileId,
            lecturerName: lecturer.name,
            roomId: draft.roomId,
            roomName: room.name,
            dayOfWeek: draft.dayOfWeek,
            startTime: draft.startTime,
            endTime: draft.endTime,
            weekStart: draft.weekStart,
            weekEnd: draft.weekEnd,
            status: draft.status,
            remarks: draft.remarks,
          );

          final key = duplicateKey(
            academicSessionId: slotDraft.academicSessionId,
            programId: slotDraft.programId,
            classId: slotDraft.classId,
            subjectCode: slotDraft.subjectCode,
            lecturerId: slotDraft.lecturerId,
            dayOfWeek: slotDraft.dayOfWeek,
            startTime: slotDraft.startTime,
            endTime: slotDraft.endTime,
            roomId: slotDraft.roomId,
            weekStart: slotDraft.weekStart.toString(),
            weekEnd: slotDraft.weekEnd.toString(),
          );
          if (existingDuplicateKeys.contains(key)) {
            errors.add(
              'Timetable slot already exists in Firestore and should be skipped or blocked during import.',
            );
          }
        }
      }

      if (errors.isNotEmpty) {
        status = row.status == TimetableImportRowStatus.duplicate ||
                errors.any((error) =>
                    error.startsWith('Duplicate') ||
                    error.contains('already exists'))
            ? TimetableImportRowStatus.duplicate
            : TimetableImportRowStatus.error;
      } else if (warnings.isNotEmpty) {
        status = TimetableImportRowStatus.warning;
      } else {
        status = TimetableImportRowStatus.valid;
      }

      previewRows.add(
        TimetablePreviewRow(
          rowNumber: row.rowNumber,
          status: status,
          errors: List.unmodifiable(errors),
          warnings: List.unmodifiable(warnings),
          slotDraft: slotDraft,
          sourceRow: row,
        ),
      );
    }

    return TimetableMasterValidationResult(
      totalRows: previewRows.length,
      validRows: previewRows
          .where((row) => row.status == TimetableImportRowStatus.valid)
          .length,
      warningRows: previewRows
          .where((row) => row.status == TimetableImportRowStatus.warning)
          .length,
      duplicateRows: previewRows
          .where((row) => row.status == TimetableImportRowStatus.duplicate)
          .length,
      errorRows: previewRows
          .where((row) => row.status == TimetableImportRowStatus.error)
          .length,
      subjectUpsertDrafts: List.unmodifiable(subjectDraftsById.values),
      classCreateDrafts: List.unmodifiable(classDraftsById.values),
      previewRows: List.unmodifiable(previewRows),
      validationErrors: importResult.validationErrors,
      validationWarnings: [
        ...importResult.validationWarnings,
        if (outOfScopeProgramIds.isNotEmpty)
          'Fail CSV mengandungi program luar skop pengguna: ${(outOfScopeProgramIds.toList()..sort()).join(', ')}. Sila muat naik jadual mengikut skop yang betul.',
      ],
    );
  }

  static String duplicateKey({
    required String academicSessionId,
    required String programId,
    required String classId,
    required String subjectCode,
    required String lecturerId,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
    required String roomId,
    required String weekStart,
    required String weekEnd,
  }) {
    return [
      academicSessionId,
      programId,
      classId,
      subjectCode,
      lecturerId,
      dayOfWeek,
      startTime,
      endTime,
      roomId,
      weekStart,
      weekEnd,
    ].map((value) => value.trim().toLowerCase()).join('|');
  }
}
