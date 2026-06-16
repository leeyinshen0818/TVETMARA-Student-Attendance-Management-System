import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_constants.dart';
import '../models/app_models.dart';
import '../models/timetable_import_result.dart';
import '../models/timetable_import_write_result.dart';
import '../models/timetable_master_validation_result.dart';
import '../models/timetable_preview_conflict.dart';
import 'timetable_master_validation_service.dart';

enum TimetableImportSaveMode { draft, official }

class TimetableFirestoreImportService {
  TimetableFirestoreImportService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const _batchLimit = 400;

  Future<TimetableImportWriteResult> importPreview({
    required TimetableMasterValidationResult preview,
    required String fileName,
    required AppUser uploadedBy,
    TimetableImportSaveMode saveMode = TimetableImportSaveMode.official,
    TimetablePreviewConflictSummary conflictSummary =
        const TimetablePreviewConflictSummary.empty(),
  }) async {
    final uploadRef =
        _db.collection(FirestoreCollections.timetableUploads).doc();
    final uploadId = uploadRef.id;
    final plan = buildPlan(preview);
    if (!plan.hasImportableRows) {
      throw StateError('Tiada baris valid untuk diimport.');
    }

    final existingDuplicateKeys = await _loadExistingDuplicateKeys();
    final rowsToImport = <TimetablePreviewRow>[];
    var duplicateRows = plan.duplicateRows;
    for (final row in importableRows(preview)) {
      final draft = row.slotDraft!;
      final key = TimetableMasterValidationService.duplicateKey(
        academicSessionId: draft.academicSessionId,
        programId: draft.programId,
        classId: draft.classId,
        subjectCode: draft.subjectCode,
        lecturerId: draft.lecturerId,
        dayOfWeek: draft.dayOfWeek,
        startTime: draft.startTime,
        endTime: draft.endTime,
        roomId: draft.roomId,
        weekStart: draft.weekStart.toString(),
        weekEnd: draft.weekEnd.toString(),
      );
      if (existingDuplicateKeys.contains(key)) {
        duplicateRows++;
      } else {
        rowsToImport.add(row);
        existingDuplicateKeys.add(key);
      }
    }

    final adjustedSkippedRows = preview.totalRows - rowsToImport.length;
    final adjustedStatus = saveMode == TimetableImportSaveMode.draft
        ? 'conflict_pending'
        : statusForSummary(
            successRows: rowsToImport.length,
            warningRows: plan.warningRows,
            duplicateRows: duplicateRows,
            errorRows: plan.errorRows,
            validationWarnings: plan.validationWarnings,
          );
    final savedAs =
        saveMode == TimetableImportSaveMode.draft ? 'draft' : 'official';

    final uploadData = {
      'uploadId': uploadId,
      'fileName': fileName,
      'academicSessionId': plan.academicSessionId,
      'uploadedBy': uploadedBy.uid,
      'uploadedByName': uploadedBy.name,
      'uploadedAt': FieldValue.serverTimestamp(),
      'status': adjustedStatus,
      'savedAs': savedAs,
      'totalRows': preview.totalRows,
      'successRows': rowsToImport.length,
      'skippedRows': adjustedSkippedRows,
      'duplicateRows': duplicateRows,
      'errorRows': plan.errorRows,
      'warningRows': plan.warningRows,
      'conflictRows': conflictSummary.conflicts
          .expand((conflict) => conflict.previewRowNumbers)
          .toSet()
          .length,
      'roomConflicts': conflictSummary.roomConflicts,
      'lecturerConflicts': conflictSummary.lecturerConflicts,
      'classConflicts': conflictSummary.classConflicts,
      'validationErrors': plan.validationErrors,
      'validationWarnings': plan.validationWarnings,
    };

    final writes = <_PendingWrite>[
      _PendingWrite(uploadRef, uploadData, SetOptions(merge: true)),
    ];

    final subjectDrafts = subjectDraftsForRows(preview, rowsToImport);
    final classDrafts = classDraftsForRows(preview, rowsToImport);

    for (final subject in subjectDrafts) {
      writes.add(
        _PendingWrite(
          _db.collection(FirestoreCollections.subjects).doc(subject.subjectId),
          {
            'subjectId': subject.subjectId,
            'programId': subject.programId,
            'subjectCode': subject.subjectCode,
            'subjectName': subject.subjectName,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        ),
      );
    }

    for (final classDraft in classDrafts) {
      writes.add(
        _PendingWrite(
          _db.collection(FirestoreCollections.classes).doc(classDraft.classId),
          {
            'classId': classDraft.classId,
            'programId': classDraft.programId,
            'academicSessionId': classDraft.academicSessionId,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        ),
      );
    }

    for (final row in rowsToImport) {
      final docRef = _db.collection(FirestoreCollections.timetableSlots).doc();
      writes.add(
        _PendingWrite(
          docRef,
          _slotMap(
            timetableSlotId: docRef.id,
            uploadId: uploadId,
            createdBy: uploadedBy.uid,
            draft: row.slotDraft!,
            saveMode: saveMode,
            conflictTypes: conflictSummary.conflictTypes,
          ),
          SetOptions(merge: true),
        ),
      );
    }

    await _commitInChunks(writes);

    return TimetableImportWriteResult(
      uploadId: uploadId,
      fileName: fileName,
      status: adjustedStatus,
      savedAs: savedAs,
      slotsCreated: rowsToImport.length,
      subjectsUpserted: subjectDrafts.length,
      classesCreated: classDrafts.length,
      duplicatesSkipped: duplicateRows,
      errorsSkipped: plan.errorRows,
      skippedRows: adjustedSkippedRows,
      conflictRows: conflictSummary.conflicts
          .expand((conflict) => conflict.previewRowNumbers)
          .toSet()
          .length,
      roomConflicts: conflictSummary.roomConflicts,
      lecturerConflicts: conflictSummary.lecturerConflicts,
      classConflicts: conflictSummary.classConflicts,
    );
  }

  static TimetableImportWritePlan buildPlan(
    TimetableMasterValidationResult preview,
  ) {
    final successRows = importableRows(preview).length;
    return TimetableImportWritePlan(
      academicSessionId: academicSessionIdFor(preview),
      status: statusForSummary(
        successRows: successRows,
        warningRows: preview.warningRows,
        duplicateRows: preview.duplicateRows,
        errorRows: preview.errorRows,
        validationWarnings: preview.validationWarnings,
      ),
      totalRows: preview.totalRows,
      successRows: successRows,
      skippedRows: preview.totalRows - successRows,
      duplicateRows: preview.duplicateRows,
      errorRows: preview.errorRows,
      warningRows: preview.warningRows,
      subjectUpsertDraftsCount: preview.subjectUpsertDraftsCount,
      classCreateDraftsCount: preview.classCreateDraftsCount,
      validationErrors: preview.validationErrors,
      validationWarnings: preview.validationWarnings,
    );
  }

  static List<TimetablePreviewRow> importableRows(
    TimetableMasterValidationResult preview,
  ) {
    return preview.previewRows
        .where((row) =>
            row.slotDraft != null &&
            (row.status == TimetableImportRowStatus.valid ||
                row.status == TimetableImportRowStatus.warning))
        .toList();
  }

  static List<TimetableSubjectUpsertDraft> subjectDraftsForRows(
    TimetableMasterValidationResult preview,
    List<TimetablePreviewRow> rows,
  ) {
    final subjectIds = rows.map((row) => row.slotDraft!.subjectId).toSet();
    return preview.subjectUpsertDrafts
        .where((draft) => subjectIds.contains(draft.subjectId))
        .toList();
  }

  static List<TimetableClassCreateDraft> classDraftsForRows(
    TimetableMasterValidationResult preview,
    List<TimetablePreviewRow> rows,
  ) {
    final classIds = rows.map((row) => row.slotDraft!.classId).toSet();
    return preview.classCreateDrafts
        .where((draft) => classIds.contains(draft.classId))
        .toList();
  }

  static String academicSessionIdFor(TimetableMasterValidationResult preview) {
    final sessions = importableRows(preview)
        .map((row) => row.slotDraft!.academicSessionId)
        .toSet();
    if (sessions.length == 1) return sessions.single;
    if (sessions.isEmpty) return 'unknown';
    return 'mixed';
  }

  static String statusForSummary({
    required int successRows,
    required int warningRows,
    required int duplicateRows,
    required int errorRows,
    required List<String> validationWarnings,
  }) {
    if (successRows == 0) return 'failed';
    if (warningRows > 0 ||
        duplicateRows > 0 ||
        errorRows > 0 ||
        validationWarnings.isNotEmpty) {
      return 'completed_with_warnings';
    }
    return 'completed';
  }

  Map<String, dynamic> _slotMap({
    required String timetableSlotId,
    required String uploadId,
    required String createdBy,
    required TimetablePreviewSlotDraft draft,
    required TimetableImportSaveMode saveMode,
    required List<String> conflictTypes,
  }) {
    final isDraft = saveMode == TimetableImportSaveMode.draft;
    return {
      'timetableSlotId': timetableSlotId,
      'academicSessionId': draft.academicSessionId,
      'programId': draft.programId,
      'departmentId': draft.departmentId,
      'classId': draft.classId,
      'subjectId': draft.subjectId,
      'subjectCode': draft.subjectCode,
      'subjectName': draft.subjectName,
      'lecturerId': draft.lecturerId,
      'lecturerEmail': draft.lecturerEmail,
      'lecturerProfileId': draft.lecturerProfileId,
      'lecturerName': draft.lecturerName,
      'roomId': draft.roomId,
      'roomName': draft.roomName,
      'dayOfWeek': draft.dayOfWeek,
      'startTime': draft.startTime,
      'endTime': draft.endTime,
      'weekStart': draft.weekStart.toString(),
      'weekEnd': draft.weekEnd.toString(),
      'status': isDraft ? 'draft' : 'active',
      'importStatus': isDraft ? 'conflict_pending' : 'official',
      'isOfficial': !isDraft,
      'hasConflict': isDraft && conflictTypes.isNotEmpty,
      'conflictTypes': conflictTypes,
      'sourceUploadId': uploadId,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),

      // Temporary aliases for existing timetable/attendance/booking screens.
      'program': draft.programName,
      'section': draft.classId,
      'room': draft.roomName,
      'day': draft.dayOfWeek,
      'session': draft.academicSessionId,
      'date': draft.weekStart.toString(),
      'semester': 1,
      'enrolled': 0,
      'capacity': 0,
      'classType': 'Imported',
      'slotType': 'Kelas Biasa',
    };
  }

  Future<Set<String>> _loadExistingDuplicateKeys() async {
    final snap =
        await _db.collection(FirestoreCollections.timetableSlots).get();
    return snap.docs
        .map((doc) => _duplicateKeyFromTimetableData(doc.data()))
        .whereType<String>()
        .toSet();
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

  Future<void> _commitInChunks(List<_PendingWrite> writes) async {
    for (var i = 0; i < writes.length; i += _batchLimit) {
      final batch = _db.batch();
      final end =
          i + _batchLimit > writes.length ? writes.length : i + _batchLimit;
      for (final write in writes.sublist(i, end)) {
        batch.set(write.ref, write.data, write.options);
      }
      await batch.commit();
    }
  }
}

class _PendingWrite {
  const _PendingWrite(this.ref, this.data, this.options);

  final DocumentReference<Map<String, dynamic>> ref;
  final Map<String, dynamic> data;
  final SetOptions options;
}
