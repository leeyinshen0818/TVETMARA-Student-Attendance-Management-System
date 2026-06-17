import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_constants.dart';
import '../core/constants/timetable_template.dart';
import '../data/mock_data.dart' as mock;
import '../models/app_models.dart';

/// Centralized service for all Firestore read / write operations.
class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  final _db = FirebaseFirestore.instance;

  /// Public accessor for the raw Firestore instance (used by seed script).
  FirebaseFirestore get db => _db;

  // ---------------------------------------------------------------------------
  // Collection references
  // ---------------------------------------------------------------------------
  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _db.collection(FirestoreCollections.users);
  CollectionReference<Map<String, dynamic>> get _studentsCol =>
      _db.collection(FirestoreCollections.students);
  CollectionReference<Map<String, dynamic>> get _lecturersCol =>
      _db.collection('lecturers');
  CollectionReference<Map<String, dynamic>> get _roomsCol =>
      _db.collection(FirestoreCollections.rooms);
  CollectionReference<Map<String, dynamic>> get _timetableCol =>
      _db.collection(FirestoreCollections.timetableSlots);
  CollectionReference<Map<String, dynamic>> get _timetableUploadsCol =>
      _db.collection(FirestoreCollections.timetableUploads);
  CollectionReference<Map<String, dynamic>> get _attendanceSessionsCol =>
      _db.collection(FirestoreCollections.attendanceSessions);
  CollectionReference<Map<String, dynamic>> get _attendanceCol =>
      _db.collection(FirestoreCollections.attendanceRecords);
  CollectionReference<Map<String, dynamic>> get _disciplineCol =>
      _db.collection(FirestoreCollections.disciplineReports);
  CollectionReference<Map<String, dynamic>> get _bookingsCol =>
      _db.collection(FirestoreCollections.legacyBookings);
  CollectionReference<Map<String, dynamic>> get _departmentsCol =>
      _db.collection(FirestoreCollections.departments);
  CollectionReference<Map<String, dynamic>> get _programsCol =>
      _db.collection(FirestoreCollections.programs);
  CollectionReference<Map<String, dynamic>> get _academicSessionsCol =>
      _db.collection(FirestoreCollections.academicSessions);
  CollectionReference<Map<String, dynamic>> get _subjectsCol =>
      _db.collection(FirestoreCollections.subjects);

  // ---------------------------------------------------------------------------
  // Account Registration
  // ---------------------------------------------------------------------------
  Future<void> createUserProfile(AppUser user) async {
    await _usersCol.doc(user.uid).set(_userToMap(user));
  }

  Future<AppUser?> getUserByEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    final snap = await _usersCol
        .where(UserFields.email, isEqualTo: normalizedEmail)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return _docToAppUser(snap.docs.first);
  }

  Future<void> updateUserProfile(AppUser user) async {
    await _usersCol.doc(user.uid).set({
      UserFields.uid: user.uid,
      UserFields.name: user.name,
      UserFields.email: user.email.toLowerCase(),
      UserFields.role: user.role.firestoreValue,
      UserFields.programId: user.programId,
      UserFields.departmentId: user.departmentId,
      UserFields.phoneNumber: user.phoneNumber,
      UserFields.lecturerProfileId: user.lecturerProfileId,
      UserFields.isActive: user.isActive,
      UserFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // Users
  // ---------------------------------------------------------------------------
  Future<AppUser?> getUserById(String id) async {
    final snap = await _usersCol.doc(id).get();
    if (!snap.exists) return null;
    return _docToAppUser(snap);
  }

  Future<List<AppUser>> getUsers() async {
    final snap = await _usersCol.get();
    return snap.docs.map(_docToAppUser).toList();
  }

  Future<void> updateLastLogin(String userId) async {
    await _usersCol.doc(userId).update({
      UserFields.updatedAt: FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------------
  // Students
  // ---------------------------------------------------------------------------
  Future<List<Student>> getStudents() async {
    final snap = await _studentsCol.orderBy('name').get();
    return snap.docs.map(_docToStudent).toList();
  }

  Future<StudentDashboardSummary> getStudentDashboardSummary({
    required Set<String> programIds,
    required int attendanceThreshold,
  }) async {
    if (programIds.isEmpty) return const StudentDashboardSummary.empty();

    var total = 0;
    var belowThreshold = 0;
    var below95 = 0;
    var below90 = 0;
    var below85 = 0;
    var below80 = 0;
    for (final programId in programIds) {
      // Keep this dashboard query single-field so demo Firestore projects do
      // not need a composite index before the Ketua dashboard can load.
      final snap =
          await _studentsCol.where('programId', isEqualTo: programId).get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final active =
            data['active'] as bool? ?? data['isActive'] as bool? ?? true;
        if (!active) continue;
        total++;
        final attendance = data['attendance'] as int? ?? 100;
        if (attendance < attendanceThreshold) belowThreshold++;
        if (attendance < 95) below95++;
        if (attendance < 90) below90++;
        if (attendance < 85) below85++;
        if (attendance < 80) below80++;
      }
    }

    return StudentDashboardSummary(
      totalStudents: total,
      belowThresholdStudents: belowThreshold,
      meetsThresholdStudents: total - belowThreshold,
      below95Students: below95,
      below90Students: below90,
      below85Students: below85,
      below80Students: below80,
    );
  }

  Stream<List<Student>> studentsStream() {
    return _studentsCol.orderBy('name').snapshots().map(
          (snap) => snap.docs.map(_docToStudent).toList(),
        );
  }

  // ---------------------------------------------------------------------------
  // Lecturers
  // ---------------------------------------------------------------------------
  Future<List<Lecturer>> getLecturers() async {
    final snap = await _lecturersCol.get();
    return snap.docs.map(_docToLecturer).toList();
  }

  // ---------------------------------------------------------------------------
  // Room resources
  // ---------------------------------------------------------------------------
  Future<List<RoomResource>> getRoomResources() async {
    final snap = await _roomsCol.orderBy('name').get();
    return snap.docs.map(_docToRoom).toList();
  }

  // ---------------------------------------------------------------------------
  // Timetable
  // ---------------------------------------------------------------------------
  Future<List<TimetableSlot>> getTimetableSlots() async {
    final snap = await _timetableCol.get();
    return snap.docs.map(_docToSlot).toList();
  }

  Future<List<TimetableUploadRecord>> getTimetableUploads() async {
    final snap = await _timetableUploadsCol
        .orderBy('uploadedAt', descending: true)
        .get();
    return snap.docs.map(_docToTimetableUpload).toList();
  }

  Future<List<Map<String, dynamic>>> getLecturerCourseAssignments() async {
    final snap = await _db.collection('lecturer_course_assignments').get();
    return snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Stream<List<TimetableSlot>> timetableStream() {
    return _timetableCol.snapshots().map(
          (snap) => snap.docs.map(_docToSlot).toList(),
        );
  }

  Future<void> updateSlotStatus(String slotId, String status) async {
    await _timetableCol.doc(slotId).update({'status': status});
  }

  /// [sourceBookingId] tags a generated "Ganti" slot with the booking that
  /// produced it. Written straight onto the document (not a typed
  /// TimetableSlot field) so every existing call site stays unaffected.
  Future<void> addTimetableSlot(
    TimetableSlot slot, {
    String? sourceBookingId,
  }) async {
    final data = _slotToMap(slot);
    if (sourceBookingId != null) {
      data['sourceBookingId'] = sourceBookingId;
    }
    await _timetableCol.doc(slot.id).set(data);
  }

  Future<void> updateTimetableSlot(TimetableSlot slot) async {
    await _timetableCol.doc(slot.id).set(
        _slotToMap(slot, includeCreatedAt: false), SetOptions(merge: true));
  }

  Future<void> updateTimetableSlotsStatus(
    List<String> slotIds,
    String status,
  ) async {
    for (final chunk in _chunks(slotIds, 450)) {
      final batch = _db.batch();
      for (final slotId in chunk) {
        batch.update(_timetableCol.doc(slotId), {
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  Future<void> publishTimetableSlots(
    List<String> slotIds, {
    required AppUser publishedBy,
  }) async {
    for (final chunk in _chunks(slotIds, 450)) {
      final batch = _db.batch();
      for (final slotId in chunk) {
        batch.update(_timetableCol.doc(slotId), {
          'status': 'active',
          'importStatus': 'official',
          'isOfficial': true,
          'hasConflict': false,
          'conflictTypes': <String>[],
          'publishedBy': publishedBy.uid,
          'publishedByName': publishedBy.name,
          'publishedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  Future<void> deleteTimetableSlot(String slotId) async {
    await _timetableCol.doc(slotId).delete();
  }

  Future<void> deleteTimetableSlots(List<String> slotIds) async {
    for (final chunk in _chunks(slotIds, 450)) {
      final batch = _db.batch();
      for (final slotId in chunk) {
        batch.delete(_timetableCol.doc(slotId));
      }
      await batch.commit();
    }
  }

  // ---------------------------------------------------------------------------
  // Hierarchy (Departments & Programs)
  // ---------------------------------------------------------------------------
  Future<List<Department>> getDepartments() async {
    final snap = await _departmentsCol.get();
    return snap.docs.map((doc) {
      final d = doc.data();
      return Department(id: doc.id, name: d['name'] as String);
    }).toList();
  }

  Future<List<ProgramCode>> getPrograms() async {
    final snap = await _programsCol.get();
    return snap.docs.map((doc) {
      final d = doc.data();
      return ProgramCode(
        id: doc.id,
        name: d['name'] as String,
        departmentId: d['departmentId'] as String?,
      );
    }).toList();
  }

  Future<List<AcademicSession>> getAcademicSessions() async {
    final snap = await _academicSessionsCol.get();
    return snap.docs.map(_docToAcademicSession).toList();
  }

  Future<void> createAcademicSession(
    AcademicSession session, {
    String? createdBy,
  }) async {
    await _academicSessionsCol.doc(session.academicSessionId).set({
      'academicSessionId': session.academicSessionId,
      'name': session.name,
      'startDate': session.startDate,
      'endDate': session.endDate,
      'status': session.status,
      'isActive': session.isActive,
      if (createdBy != null) 'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateAcademicSession(AcademicSession session) async {
    await _academicSessionsCol.doc(session.academicSessionId).set({
      'academicSessionId': session.academicSessionId,
      'name': session.name,
      'startDate': session.startDate,
      'endDate': session.endDate,
      'status': session.status,
      'isActive': session.isActive,
      if (session.createdAt != null) 'createdAt': session.createdAt,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> archiveAcademicSession(String academicSessionId) async {
    await _academicSessionsCol.doc(academicSessionId).set({
      'status': 'archived',
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // Attendance
  // ---------------------------------------------------------------------------
  String attendanceSessionIdFor({
    required String slotId,
    required String sessionDate,
    required int weekNo,
  }) {
    return '${_safeDocSegment(slotId)}_${_safeDocSegment(sessionDate)}_W$weekNo';
  }

  String attendanceDuplicateKey({
    required String slotId,
    required String sessionDate,
    required int weekNo,
  }) {
    return '$slotId|$sessionDate|$weekNo';
  }

  Future<AttendanceSession?> getAttendanceSessionById(String sessionId) async {
    final snap = await _attendanceSessionsCol.doc(sessionId).get();
    if (!snap.exists) return null;
    return _docToAttendanceSession(snap);
  }

  Future<AttendanceSession?> getAttendanceSessionForSlotDateWeek({
    required String slotId,
    required String sessionDate,
    required int weekNo,
  }) async {
    final sessionId = attendanceSessionIdFor(
      slotId: slotId,
      sessionDate: sessionDate,
      weekNo: weekNo,
    );
    final byId = await getAttendanceSessionById(sessionId);
    if (byId != null) return byId;

    final duplicateKey = attendanceDuplicateKey(
      slotId: slotId,
      sessionDate: sessionDate,
      weekNo: weekNo,
    );
    final byDuplicateKey = await _attendanceSessionsCol
        .where('duplicateKey', isEqualTo: duplicateKey)
        .limit(1)
        .get();
    if (byDuplicateKey.docs.isNotEmpty) {
      return _docToAttendanceSession(byDuplicateKey.docs.first);
    }

    final bySlot =
        await _attendanceSessionsCol.where('slotId', isEqualTo: slotId).get();
    for (final doc in bySlot.docs) {
      final session = _docToAttendanceSession(doc);
      if (session.sessionDate == sessionDate && session.weekNo == weekNo) {
        return session;
      }
    }

    return null;
  }

  Future<void> saveAttendanceSessionWithRecords({
    required AttendanceSession session,
    required List<AttendanceRecord> records,
    bool preventOverwrite = false,
  }) async {
    final expectedId = attendanceSessionIdFor(
      slotId: session.slotId,
      sessionDate: session.sessionDate,
      weekNo: session.weekNo,
    );
    final sessionId = session.id == expectedId ? session.id : expectedId;
    final sessionRef = _attendanceSessionsCol.doc(sessionId);

    await _db.runTransaction((transaction) async {
      final existing = await transaction.get(sessionRef);
      if (preventOverwrite && existing.exists) {
        throw StateError(
            'Attendance session already exists for this slot, date, and week.');
      }

      final recordWrites = <_AttendanceRecordWrite>[];
      for (final record in records) {
        final recordId =
            record.id ?? '${_safeDocSegment(sessionId)}_${record.studentId}';
        final ref = _attendanceCol.doc(recordId);
        final existingRecord = await transaction.get(ref);
        final enriched = record.copyWith(
          id: recordId,
          sessionId: sessionId,
          slotId: session.slotId,
          programId: record.programId ?? session.programId,
          programName: record.programName ?? session.programName,
          departmentId: record.departmentId ?? session.departmentId,
          section: record.section ?? session.section,
          weekNo: record.weekNo ?? session.weekNo,
          sessionDate: record.sessionDate ?? session.sessionDate,
          createdBy: record.createdBy ?? session.createdBy,
        );
        recordWrites.add(_AttendanceRecordWrite(
          ref: ref,
          record: enriched,
          exists: existingRecord.exists,
        ));
      }

      transaction.set(
        sessionRef,
        _attendanceSessionToMap(
          session,
          id: sessionId,
          existing: existing.exists,
        ),
        SetOptions(merge: true),
      );

      for (final write in recordWrites) {
        transaction.set(
          write.ref,
          _attendanceRecordToMap(write.record, existing: write.exists),
          SetOptions(merge: true),
        );
      }
    });
  }

  Future<void> saveAttendanceSession(
    AttendanceSession session, {
    bool preventOverwrite = false,
  }) async {
    final sessionId = attendanceSessionIdFor(
      slotId: session.slotId,
      sessionDate: session.sessionDate,
      weekNo: session.weekNo,
    );
    final sessionRef = _attendanceSessionsCol.doc(sessionId);

    await _db.runTransaction((transaction) async {
      final existing = await transaction.get(sessionRef);
      if (preventOverwrite && existing.exists) {
        throw StateError(
            'Attendance session already exists for this slot, date, and week.');
      }
      transaction.set(
        sessionRef,
        _attendanceSessionToMap(
          session,
          id: sessionId,
          existing: existing.exists,
        ),
        SetOptions(merge: true),
      );
    });
  }

  Future<List<AttendanceRecord>> getAttendanceRecordsForSession(
      String sessionId) async {
    final snap =
        await _attendanceCol.where('sessionId', isEqualTo: sessionId).get();
    return snap.docs.map(_docToAttendanceRecord).toList();
  }

  Future<void> resetAttendanceCollections() async {
    await _deleteCollection(_attendanceCol);
    await _deleteCollection(_attendanceSessionsCol);
  }

  Future<List<AttendanceSession>> getAttendanceSessionsForSlot(
      String slotId) async {
    final snap = await _attendanceSessionsCol
        .where('slotId', isEqualTo: slotId)
        .orderBy('weekNo')
        .get();
    return snap.docs.map(_docToAttendanceSession).toList();
  }

  Future<List<AttendanceSession>> getAttendanceSessions() async {
    final snap = await _attendanceSessionsCol.get();
    return snap.docs.map(_docToAttendanceSession).toList();
  }

  Future<Map<String, List<AttendanceRecord>>>
      getAllSessionAttendanceRecords() async {
    final snap = await _attendanceCol.get();
    final result = <String, List<AttendanceRecord>>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      if (!data.containsKey('sessionId') || !data.containsKey('status')) {
        continue;
      }
      final record = _docToAttendanceRecord(doc);
      final sessionId = record.sessionId;
      if (sessionId == null || sessionId.isEmpty) continue;
      result.putIfAbsent(sessionId, () => []).add(record);
    }
    return result;
  }

  Future<void> _deleteCollection(
      CollectionReference<Map<String, dynamic>> collection) async {
    while (true) {
      final snap = await collection.limit(400).get();
      if (snap.docs.isEmpty) return;
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Future<Map<String, List<AttendanceRecord>>> getAllAttendance() async {
    final snap = await _attendanceCol.get();
    final result = <String, List<AttendanceRecord>>{};
    for (final doc in snap.docs) {
      final slotId = doc.id;
      final recordsSnap =
          await _attendanceCol.doc(slotId).collection('records').get();
      result[slotId] =
          recordsSnap.docs.map((d) => _docToAttendance(slotId, d)).toList();
    }
    return result;
  }

  Future<List<AttendanceRecord>> getAttendanceForSlot(String slotId) async {
    final snap = await _attendanceCol.doc(slotId).collection('records').get();
    return snap.docs.map((d) => _docToAttendance(slotId, d)).toList();
  }

  Future<void> saveAttendance(
      String slotId, List<AttendanceRecord> records) async {
    final batch = _db.batch();
    // Create or update the parent document
    batch.set(_attendanceCol.doc(slotId), {'slotId': slotId});
    for (final record in records) {
      final ref = _attendanceCol
          .doc(slotId)
          .collection('records')
          .doc(record.studentId);
      batch.set(ref, {
        'status': record.status.name,
        'checkIn': record.checkIn,
        'remarks': record.remarks,
      });
    }
    await batch.commit();
  }

  // ---------------------------------------------------------------------------
  // Discipline reports
  // ---------------------------------------------------------------------------
  Future<List<String>> reviewerIdsForProgram({
    required String programId,
    String? departmentId,
  }) async {
    final reviewers = await reviewerRoutingForProgram(
      programId: programId,
      departmentId: departmentId,
    );
    return reviewers.map((user) => user.uid).toList();
  }

  Future<List<AppUser>> reviewerRoutingForProgram({
    required String programId,
    String? departmentId,
  }) async {
    final users = await getUsers();
    final reviewers = <AppUser>[];

    reviewers.addAll(users.where(
      (user) =>
          user.role == UserRole.ketua_program &&
          user.programId == programId &&
          user.isActive,
    ));

    if (departmentId != null && departmentId.isNotEmpty) {
      reviewers.addAll(users.where(
        (user) =>
            user.role == UserRole.ketua_jabatan &&
            user.departmentId == departmentId &&
            user.isActive,
      ));
    }

    final unique = <String, AppUser>{};
    for (final reviewer in reviewers) {
      unique[reviewer.uid] = reviewer;
    }
    return unique.values.toList();
  }

  Future<DisciplineReport> prepareDisciplineReportRouting(
      DisciplineReport report) async {
    final programId = report.programId;
    if (programId == null || programId.isEmpty) return report;

    final reviewers = await reviewerRoutingForProgram(
      programId: programId,
      departmentId: report.departmentId,
    );
    return report.copyWith(
      assignedReviewerIds: reviewers.map((user) => user.uid).toList(),
      assignedReviewerRoles:
          reviewers.map((user) => user.role.firestoreValue).toSet().toList(),
    );
  }

  Future<List<DisciplineReport>> getDisciplineReports() async {
    final snap = await _disciplineCol.orderBy('date', descending: true).get();
    return snap.docs.map(_docToReport).toList();
  }

  Stream<List<DisciplineReport>> disciplineStream() {
    return _disciplineCol
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_docToReport).toList());
  }

  Future<void> addDisciplineReport(DisciplineReport report) async {
    final routed = await prepareDisciplineReportRouting(report);
    await _disciplineCol
        .doc(routed.id)
        .set(_disciplineReportToMap(routed, existing: false));
  }

  Future<void> updateDisciplineStatus(
    String id,
    String status, {
    String? actionTakenBy,
    String? actionTakenByName,
    String? actionTakenNote,
    String? reviewedBy,
    String? reviewedByName,
    String? reviewerRole,
    String? reviewerNotes,
    String? actionTaken,
    String? rejectionReason,
  }) async {
    final normalizedStatus = _normalizeDisciplineStatus(status);
    final updates = <String, dynamic>{
      'status': normalizedStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (reviewedBy != null) updates['reviewedBy'] = reviewedBy;
    if (reviewedByName != null) updates['reviewedByName'] = reviewedByName;
    if (reviewerRole != null) updates['reviewerRole'] = reviewerRole;
    if (reviewerNotes != null) updates['reviewerNotes'] = reviewerNotes;
    if (normalizedStatus == 'reviewed') {
      updates['reviewedAt'] = FieldValue.serverTimestamp();
    } else if (normalizedStatus == 'action_taken') {
      updates['reviewedAt'] = FieldValue.serverTimestamp();
      updates['actionTakenAt'] = FieldValue.serverTimestamp();
      updates['actionTakenBy'] = actionTakenBy;
      updates['actionTakenByName'] = actionTakenByName;
      updates['actionTaken'] = actionTaken;
      updates['actionTakenNote'] = actionTakenNote;
    } else if (normalizedStatus == 'rejected') {
      updates['reviewedAt'] = FieldValue.serverTimestamp();
      updates['rejectionReason'] = rejectionReason;
    } else if (normalizedStatus == 'closed') {
      updates['closedAt'] = FieldValue.serverTimestamp();
    }
    await _disciplineCol.doc(id).update(updates);
  }

  // ---------------------------------------------------------------------------
  // Bookings
  // ---------------------------------------------------------------------------
  Future<List<BookingRequest>> getBookings() async {
    final snap = await _bookingsCol.get();
    return snap.docs.map(_docToBooking).toList();
  }

  Stream<List<BookingRequest>> bookingsStream() {
    return _bookingsCol
        .snapshots()
        .map((snap) => snap.docs.map(_docToBooking).toList());
  }

  Future<void> addBooking(BookingRequest booking) async {
    await _bookingsCol.doc(booking.id).set({
      'lecturerId': booking.lecturerId,
      'lecturerName': booking.lecturerName,
      'programId': booking.programId,
      'departmentId': booking.departmentId,
      'subject': booking.subject,
      'section': booking.section,
      'originalDate': booking.originalDate,
      'originalTime': booking.originalTime,
      'replacementDate': booking.replacementDate,
      'replacementStart': booking.replacementStart,
      'replacementEnd': booking.replacementEnd,
      'roomId': booking.roomId,
      'roomName': booking.roomName ?? booking.room,
      'room': booking.room,
      'reason': booking.reason,
      'remarks': booking.remarks,
      'status': booking.status,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateBookingStatus(
    String id,
    String status, {
    String? reviewedBy,
    String? reviewedByName,
    String? rejectionReason,
  }) async {
    final updates = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      'reviewedAt': FieldValue.serverTimestamp(),
    };
    if (reviewedBy != null) updates['reviewedBy'] = reviewedBy;
    if (reviewedByName != null) updates['reviewedByName'] = reviewedByName;
    if (rejectionReason != null) updates['rejectionReason'] = rejectionReason;
    await _bookingsCol.doc(id).update(updates);
  }

  /// Writes the generated replacement slot id back onto the source booking
  /// so the approval trail is traceable from the booking document.
  Future<void> linkBookingReplacementSlot(
    String bookingId,
    String slotId,
  ) async {
    await _bookingsCol.doc(bookingId).update({
      'replacementSlotId': slotId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------------
  // Seeding helpers
  // ---------------------------------------------------------------------------
  Future<void> seedUsers(List<AppUser> users) async {
    final batch = _db.batch();
    for (final user in users) {
      batch.set(_usersCol.doc(user.uid), _userToMap(user));
    }
    await batch.commit();
  }

  Future<void> seedStudents(List<Student> students) async {
    // Firestore batch is limited to 500 writes; split if needed.
    for (var i = 0; i < students.length; i += 400) {
      final batch = _db.batch();
      final chunk = students.sublist(
          i, i + 400 > students.length ? students.length : i + 400);
      for (final s in chunk) {
        final programId = s.section.split(' ').first;
        batch.set(_studentsCol.doc(s.id), {
          'studentId': s.id,
          'name': s.name,
          'email': s.email,
          'phone': s.phone,
          'program': s.program,
          'programId': programId,
          'semester': s.semester,
          'section': s.section,
          'classId': s.section,
          'attendance': s.attendance,
          'active': s.active,
          'isActive': s.active,
          'dataSource': 'generated_demo',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  Future<void> seedLecturers(List<Lecturer> lecturers) async {
    final batch = _db.batch();
    for (final l in lecturers) {
      batch.set(_lecturersCol.doc(l.id), {
        'name': l.name,
        'email': l.email,
        'department': l.department,
        'subjects': l.subjects,
      });
    }
    await batch.commit();
  }

  Future<void> seedRooms(List<RoomResource> rooms) async {
    for (var i = 0; i < rooms.length; i += 400) {
      final batch = _db.batch();
      final chunk =
          rooms.sublist(i, i + 400 > rooms.length ? rooms.length : i + 400);
      for (final r in chunk) {
        final docId = r.name.replaceAll(RegExp(r'[/\\.]'), '_');
        batch.set(_roomsCol.doc(docId), {
          'roomId': docId,
          'name': r.name,
          'block': r.block,
          'type': r.type,
          'capacity': r.capacity,
        });
      }
      await batch.commit();
    }
  }

  Future<void> seedTimetable(List<TimetableSlot> slots) async {
    final batch = _db.batch();
    for (final slot in slots) {
      batch.set(_timetableCol.doc(slot.id), _slotToMap(slot));
    }
    await batch.commit();
  }

  Future<void> seedDisciplineReports(List<DisciplineReport> reports) async {
    final batch = _db.batch();
    for (final r in reports) {
      final data = _disciplineReportToMap(r, existing: false)
        ..['dataSource'] = 'generated_demo';
      batch.set(_disciplineCol.doc(r.id), data);
    }
    await batch.commit();
  }

  Future<void> seedBookings(List<BookingRequest> bookings) async {
    final batch = _db.batch();
    for (final b in bookings) {
      batch.set(_bookingsCol.doc(b.id), {
        'lecturerId': b.lecturerId,
        'lecturerName': b.lecturerName,
        'programId': b.programId,
        'departmentId': b.departmentId,
        'subject': b.subject,
        'section': b.section,
        'originalDate': b.originalDate,
        'originalTime': b.originalTime,
        'replacementDate': b.replacementDate,
        'replacementStart': b.replacementStart,
        'replacementEnd': b.replacementEnd,
        'roomId': b.roomId,
        'roomName': b.roomName ?? b.room,
        'room': b.room,
        'reason': b.reason,
        'remarks': b.remarks,
        'status': b.status,
        'dataSource': 'generated_demo',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> seedHierarchy(
      List<Department> departments, List<ProgramCode> programs) async {
    final batch = _db.batch();
    for (final dept in departments) {
      batch.set(_departmentsCol.doc(dept.id), {'name': dept.name});
    }
    for (final prog in programs) {
      batch.set(_programsCol.doc(prog.id), {
        'name': prog.name,
        'departmentId': prog.departmentId,
      });
    }
    await batch.commit();
  }

  Future<void> seedAcademicSessions([List<AcademicSession>? sessions]) async {
    final values = sessions ??
        const [
          AcademicSession(
            academicSessionId: TimetableCsvTemplate.defaultAcademicSessionId,
            name: TimetableCsvTemplate.defaultAcademicSessionName,
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
    final batch = _db.batch();
    for (final session in values) {
      batch.set(_academicSessionsCol.doc(session.academicSessionId), {
        'academicSessionId': session.academicSessionId,
        'name': session.name,
        'startDate': session.startDate,
        'endDate': session.endDate,
        'status': session.status,
        'isActive': session.isActive,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> seedSubjects(List<SubjectCourse> subjects) async {
    for (var i = 0; i < subjects.length; i += 400) {
      final batch = _db.batch();
      final chunk = subjects.sublist(
          i, i + 400 > subjects.length ? subjects.length : i + 400);
      for (final subject in chunk) {
        batch.set(_subjectsCol.doc(subject.subjectId), {
          'subjectId': subject.subjectId,
          'programId': subject.programId,
          'subjectCode': subject.subjectCode,
          'subjectName': subject.subjectName,
          'academicSessionId': TimetableCsvTemplate.defaultAcademicSessionId,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  Future<void> migrateOldUsers() async {
    final snap = await _usersCol.get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      final data = doc.data();
      final updates = <String, dynamic>{};
      final role = data[UserFields.role] as String?;
      if (role != null) {
        updates[UserFields.role] = UserRole.fromFirestore(role).firestoreValue;
      }
      if (!data.containsKey(UserFields.uid)) {
        updates[UserFields.uid] = doc.id;
      }
      if (data.containsKey('program') &&
          !data.containsKey(UserFields.programId)) {
        updates[UserFields.programId] = data['program'];
      }
      if (data.containsKey('department') &&
          !data.containsKey(UserFields.departmentId)) {
        updates[UserFields.departmentId] = data['department'];
      }
      if (data.containsKey('active') &&
          !data.containsKey(UserFields.isActive)) {
        updates[UserFields.isActive] = data['active'];
      }
      updates[UserFields.updatedAt] = FieldValue.serverTimestamp();
      if (updates.isNotEmpty) {
        batch.update(doc.reference, {
          ...updates,
        });
      }
    }
    await batch.commit();
  }

  Future<void> runMigrationAndSeed() async {
    await migrateOldUsers();

    final depts = [
      const Department(id: 'elektrik', name: 'Jabatan Elektrik'),
      const Department(id: 'mekanikal', name: 'Jabatan Mekanikal'),
      const Department(id: 'automotif', name: 'Jabatan Automotif'),
    ];

    await seedHierarchy(depts, mock.programs);
    await seedAcademicSessions();
  }

  // ---------------------------------------------------------------------------
  // Document → Model converters
  // ---------------------------------------------------------------------------
  AppUser _docToAppUser(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;

    return AppUser(
      uid: d[UserFields.uid] as String? ?? doc.id,
      name: d[UserFields.name] as String? ?? '',
      email: d[UserFields.email] as String? ?? '',
      role: UserRole.fromFirestore(d[UserFields.role] as String?),
      programId: d[UserFields.programId] as String? ?? d['program'] as String?,
      departmentId:
          d[UserFields.departmentId] as String? ?? d['department'] as String?,
      phoneNumber: d[UserFields.phoneNumber] as String?,
      lecturerProfileId: d[UserFields.lecturerProfileId] as String?,
      isActive: d[UserFields.isActive] as bool? ?? d['active'] as bool? ?? true,
      createdAt: _readTimestamp(d[UserFields.createdAt]),
      updatedAt: _readTimestamp(d[UserFields.updatedAt]) ??
          _readTimestamp(d['lastLogin']),
    );
  }

  Student _docToStudent(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Student(
      id: doc.id,
      name: d['name'] as String,
      email: d['email'] as String,
      phone: d['phone'] as String,
      program: d['program'] as String,
      semester: d['semester'] as int,
      section: d['section'] as String,
      attendance: d['attendance'] as int,
      active: d['active'] as bool? ?? true,
    );
  }

  Lecturer _docToLecturer(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Lecturer(
      id: doc.id,
      name: d['name'] as String,
      email: d['email'] as String,
      department: d['department'] as String,
      subjects: List<String>.from(d['subjects'] as List),
    );
  }

  RoomResource _docToRoom(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return RoomResource(
      name: d['name'] as String,
      block: d['block'] as String,
      type: d['type'] as String,
      capacity: d['capacity'] as int?,
    );
  }

  AcademicSession _docToAcademicSession(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return AcademicSession(
      academicSessionId: d['academicSessionId'] as String? ?? doc.id,
      name: d['name'] as String? ?? doc.id,
      isActive: d['isActive'] as bool? ?? true,
      status: d['status'] as String? ??
          ((d['isActive'] as bool? ?? true) ? 'active' : 'archived'),
      startDate: d['startDate'] as String?,
      endDate: d['endDate'] as String?,
      createdAt: _readTimestamp(d['createdAt']),
      updatedAt: _readTimestamp(d['updatedAt']),
    );
  }

  TimetableSlot _docToSlot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final timetableSlotId = d['timetableSlotId'] as String? ?? doc.id;
    final academicSessionId =
        d['academicSessionId'] as String? ?? d['session'] as String?;
    final programId = d['programId'] as String? ?? d['program'] as String?;
    final classId = d['classId'] as String? ?? d['section'] as String?;
    final roomId = d['roomId'] as String? ?? d['room'] as String?;
    final roomName = d['roomName'] as String? ?? d['room'] as String?;
    final dayOfWeek = d['dayOfWeek'] as String? ?? d['day'] as String?;
    final weekStart = d['weekStart'] as String? ?? d['date'] as String?;
    final weekEnd = d['weekEnd'] as String? ?? d['date'] as String?;

    return TimetableSlot(
      id: doc.id,
      timetableSlotId: timetableSlotId,
      academicSessionId: academicSessionId,
      programId: programId,
      departmentId: d['departmentId'] as String?,
      classId: classId,
      subjectId: d['subjectId'] as String?,
      session: academicSessionId ?? '',
      semester: d['semester'] as int? ?? 1,
      program: d['program'] as String? ?? programId ?? '',
      section: d['section'] as String? ?? classId ?? '',
      subjectCode: d['subjectCode'] as String? ?? '',
      subjectName: d['subjectName'] as String? ?? '',
      lecturerId: d['lecturerId'] as String? ?? '',
      lecturerName: d['lecturerName'] as String? ?? '',
      lecturerEmail: d['lecturerEmail'] as String?,
      lecturerProfileId: d['lecturerProfileId'] as String?,
      roomId: roomId,
      roomName: roomName,
      day: d['day'] as String? ?? dayOfWeek ?? '',
      date: d['date'] as String? ?? weekStart ?? '',
      dayOfWeek: dayOfWeek,
      startTime: d['startTime'] as String? ?? '',
      endTime: d['endTime'] as String? ?? '',
      weekStart: weekStart,
      weekEnd: weekEnd,
      room: d['room'] as String? ?? roomName ?? roomId ?? '',
      enrolled: d['enrolled'] as int? ?? 0,
      capacity: d['capacity'] as int? ?? 0,
      classType: d['classType'] as String? ?? '',
      slotType: d['slotType'] as String? ?? 'Kelas Biasa',
      status: d['status'] as String? ?? 'draft',
      sourceUploadId: d['sourceUploadId'] as String?,
      importStatus: d['importStatus'] as String?,
      isOfficial: d['isOfficial'] as bool? ?? true,
      hasConflict: d['hasConflict'] as bool? ?? false,
      conflictTypes: List<String>.from(d['conflictTypes'] as List? ?? const []),
      createdBy: d['createdBy'] as String?,
      createdAt: _readTimestamp(d['createdAt']),
      updatedAt: _readTimestamp(d['updatedAt']),
    );
  }

  TimetableUploadRecord _docToTimetableUpload(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return TimetableUploadRecord(
      uploadId: d['uploadId'] as String? ?? doc.id,
      fileName: d['fileName'] as String? ?? '-',
      academicSessionId: d['academicSessionId'] as String? ?? 'unknown',
      uploadedBy: d['uploadedBy'] as String? ?? '',
      uploadedByName: d['uploadedByName'] as String? ?? '-',
      uploadedAt: _readTimestamp(d['uploadedAt']) ?? '-',
      status: d['status'] as String? ?? 'unknown',
      savedAs: d['savedAs'] as String?,
      totalRows: d['totalRows'] as int? ?? 0,
      successRows: d['successRows'] as int? ?? 0,
      skippedRows: d['skippedRows'] as int? ?? 0,
      duplicateRows: d['duplicateRows'] as int? ?? 0,
      errorRows: d['errorRows'] as int? ?? 0,
      warningRows: d['warningRows'] as int? ?? 0,
      conflictRows: d['conflictRows'] as int? ?? 0,
      roomConflicts: d['roomConflicts'] as int? ?? 0,
      lecturerConflicts: d['lecturerConflicts'] as int? ?? 0,
      classConflicts: d['classConflicts'] as int? ?? 0,
      validationErrors:
          List<String>.from(d['validationErrors'] as List? ?? const []),
      validationWarnings:
          List<String>.from(d['validationWarnings'] as List? ?? const []),
    );
  }

  AttendanceRecord _docToAttendance(
      String slotId, DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return AttendanceRecord(
      slotId: slotId,
      studentId: doc.id,
      status: AttendanceStatus.values.byName(d['status'] as String),
      checkIn: d['checkIn'] as String,
      remarks: d['remarks'] as String? ?? '',
    );
  }

  AttendanceSession _docToAttendanceSession(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return AttendanceSession(
      id: d['id'] as String? ?? doc.id,
      slotId: d['slotId'] as String? ?? '',
      sessionDate: d['sessionDate'] as String? ?? '',
      weekNo: d['weekNo'] as int? ?? 0,
      academicSession: d['academicSession'] as String? ?? '',
      semester: d['semester'] as int? ?? 0,
      programId: d['programId'] as String? ?? '',
      programName: d['programName'] as String? ?? d['program'] as String? ?? '',
      departmentId: d['departmentId'] as String?,
      section: d['section'] as String? ?? '',
      subjectCode: d['subjectCode'] as String? ?? '',
      subjectName: d['subjectName'] as String? ?? '',
      lecturerId: d['lecturerId'] as String? ?? '',
      lecturerName: d['lecturerName'] as String? ?? '',
      status: d['status'] as String? ?? 'submitted',
      totalStudents: d['totalStudents'] as int? ?? 0,
      presentCount: d['presentCount'] as int? ?? 0,
      lateCount: d['lateCount'] as int? ?? 0,
      absentCount: d['absentCount'] as int? ?? 0,
      mcCount: d['mcCount'] as int? ?? 0,
      ckCount: d['ckCount'] as int? ?? 0,
      attendancePercentage: d['attendancePercentage'] as int? ?? 100,
      duplicateKey: d['duplicateKey'] as String? ??
          attendanceDuplicateKey(
            slotId: d['slotId'] as String? ?? '',
            sessionDate: d['sessionDate'] as String? ?? '',
            weekNo: d['weekNo'] as int? ?? 0,
          ),
      createdBy: d['createdBy'] as String? ?? '',
      createdAt: _readTimestamp(d['createdAt']),
      updatedAt: _readTimestamp(d['updatedAt']),
      submittedAt: _readTimestamp(d['submittedAt']),
      updatedBy: d['updatedBy'] as String?,
      updatedByName: d['updatedByName'] as String?,
      editReason: d['editReason'] as String?,
      editHistory: _readAttendanceEditHistory(d['editHistory']),
    );
  }

  AttendanceRecord _docToAttendanceRecord(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return AttendanceRecord(
      id: d['id'] as String? ?? doc.id,
      sessionId: d['sessionId'] as String?,
      slotId: d['slotId'] as String? ?? '',
      studentId: d['studentId'] as String? ?? doc.id,
      studentName: d['studentName'] as String?,
      programId: d['programId'] as String?,
      programName: d['programName'] as String?,
      departmentId: d['departmentId'] as String?,
      section: d['section'] as String?,
      weekNo: d['weekNo'] as int?,
      sessionDate: d['sessionDate'] as String?,
      status: AttendanceStatus.values.byName(d['status'] as String),
      checkIn: d['checkIn'] as String? ?? '',
      remarks: d['remarks'] as String? ?? d['remark'] as String? ?? '',
      createdBy: d['createdBy'] as String?,
      createdAt: _readTimestamp(d['createdAt']),
      updatedAt: _readTimestamp(d['updatedAt']),
      updatedBy: d['updatedBy'] as String?,
      updatedByName: d['updatedByName'] as String?,
      editReason: d['editReason'] as String?,
      originalStatus: _nullableAttendanceStatusFromName(
        d['originalStatus'] as String?,
      ),
      newStatus: _nullableAttendanceStatusFromName(
        d['newStatus'] as String?,
      ),
    );
  }

  DisciplineReport _docToReport(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return DisciplineReport(
      id: doc.id,
      studentId: d['studentId'] as String,
      studentName: d['studentName'] as String,
      programId: d['programId'] as String?,
      programName: d['programName'] as String?,
      departmentId: d['departmentId'] as String?,
      section: d['section'] as String,
      subject: d['subject'] as String,
      subjectCode: d['subjectCode'] as String?,
      subjectName: d['subjectName'] as String?,
      slotId: d['slotId'] as String?,
      lecturer: d['lecturer'] as String,
      createdBy: d['createdBy'] as String?,
      createdByName: d['createdByName'] as String?,
      assignedReviewerIds:
          List<String>.from(d['assignedReviewerIds'] as List? ?? const []),
      assignedReviewerRoles:
          List<String>.from(d['assignedReviewerRoles'] as List? ?? const []),
      date: d['date'] as String,
      issueType: d['issueType'] as String,
      severity: d['severity'] as String,
      description: d['description'] as String,
      followUp: d['followUp'] as bool,
      status: d['status'] as String,
      createdAt: _readTimestamp(d['createdAt']),
      updatedAt: _readTimestamp(d['updatedAt']),
      reviewedAt: _readTimestamp(d['reviewedAt']),
      reviewedBy: d['reviewedBy'] as String?,
      reviewedByName: d['reviewedByName'] as String?,
      reviewerRole: d['reviewerRole'] as String?,
      reviewerNotes: d['reviewerNotes'] as String?,
      actionTakenAt: _readTimestamp(d['actionTakenAt']),
      actionTakenBy: d['actionTakenBy'] as String?,
      actionTakenByName: d['actionTakenByName'] as String?,
      actionTaken: d['actionTaken'] as String?,
      actionTakenNote: d['actionTakenNote'] as String?,
      rejectionReason: d['rejectionReason'] as String?,
      closedAt: _readTimestamp(d['closedAt']),
    );
  }

  BookingRequest _docToBooking(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return BookingRequest(
      id: doc.id,
      lecturerId: d['lecturerId'] as String,
      lecturerName: d['lecturerName'] as String,
      programId: d['programId'] as String?,
      departmentId: d['departmentId'] as String?,
      subject: d['subject'] as String,
      section: d['section'] as String,
      originalDate: d['originalDate'] as String,
      originalTime: d['originalTime'] as String,
      replacementDate: d['replacementDate'] as String,
      replacementStart: d['replacementStart'] as String,
      replacementEnd: d['replacementEnd'] as String,
      roomId: d['roomId'] as String?,
      roomName: d['roomName'] as String?,
      room: d['room'] as String,
      reason: d['reason'] as String,
      remarks: d['remarks'] as String,
      status: d['status'] as String,
      createdAt: _readTimestamp(d['createdAt']),
      updatedAt: _readTimestamp(d['updatedAt']),
      reviewedBy: d['reviewedBy'] as String?,
      reviewedByName: d['reviewedByName'] as String?,
      reviewedAt: _readTimestamp(d['reviewedAt']),
      rejectionReason: d['rejectionReason'] as String?,
    );
  }

  // ---------------------------------------------------------------------------
  // Model → Map converters
  // ---------------------------------------------------------------------------
  Map<String, dynamic> _slotToMap(
    TimetableSlot slot, {
    bool includeCreatedAt = true,
  }) {
    final data = <String, dynamic>{
      'timetableSlotId': slot.timetableSlotId,
      'academicSessionId': slot.academicSessionId ?? slot.session,
      'programId': slot.programId ?? slot.program,
      'departmentId': slot.departmentId,
      'classId': slot.classId ?? slot.section,
      'subjectId': slot.subjectId,
      'subjectCode': slot.subjectCode,
      'subjectName': slot.subjectName,
      'lecturerId': slot.lecturerId,
      'lecturerName': slot.lecturerName,
      'lecturerEmail': slot.lecturerEmail,
      'lecturerProfileId': slot.lecturerProfileId,
      'roomId': slot.roomId ?? slot.room,
      'roomName': slot.roomName ?? slot.room,
      'dayOfWeek': slot.dayOfWeek ?? slot.day,
      'startTime': slot.startTime,
      'endTime': slot.endTime,
      'weekStart': slot.weekStart ?? slot.date,
      'weekEnd': slot.weekEnd ?? slot.date,
      'status': slot.status,
      'sourceUploadId': slot.sourceUploadId,
      'importStatus': slot.importStatus,
      'isOfficial': slot.isOfficial,
      'hasConflict': slot.hasConflict,
      'conflictTypes': slot.conflictTypes,
      'createdBy': slot.createdBy,
      'updatedAt': FieldValue.serverTimestamp(),

      // Temporary display aliases for existing timetable, attendance,
      // booking, discipline, and reporting screens. Remove only after those
      // modules read normalized timetable fields.
      'session': slot.session,
      'semester': slot.semester,
      'program': slot.program,
      'section': slot.section,
      'day': slot.day,
      'date': slot.date,
      'room': slot.room,
      'enrolled': slot.enrolled,
      'capacity': slot.capacity,
      'classType': slot.classType,
      'slotType': slot.slotType,
    };
    if (includeCreatedAt) {
      data['createdAt'] = slot.createdAt ?? FieldValue.serverTimestamp();
    } else if (slot.createdAt != null) {
      data['createdAt'] = slot.createdAt;
    }
    return data;
  }

  Map<String, dynamic> _attendanceSessionToMap(
    AttendanceSession session, {
    required String id,
    required bool existing,
  }) =>
      {
        'id': id,
        'slotId': session.slotId,
        'sessionDate': session.sessionDate,
        'weekNo': session.weekNo,
        'academicSession': session.academicSession,
        'semester': session.semester,
        'programId': session.programId,
        'programName': session.programName,
        'departmentId': session.departmentId,
        'section': session.section,
        'subjectCode': session.subjectCode,
        'subjectName': session.subjectName,
        'lecturerId': session.lecturerId,
        'lecturerName': session.lecturerName,
        'status': session.status,
        'totalStudents': session.totalStudents,
        'presentCount': session.presentCount,
        'lateCount': session.lateCount,
        'absentCount': session.absentCount,
        'mcCount': session.mcCount,
        'ckCount': session.ckCount,
        'attendancePercentage': session.attendancePercentage,
        'duplicateKey': attendanceDuplicateKey(
          slotId: session.slotId,
          sessionDate: session.sessionDate,
          weekNo: session.weekNo,
        ),
        'createdBy': session.createdBy,
        'updatedBy': session.updatedBy,
        'updatedByName': session.updatedByName,
        'editReason': session.editReason,
        'editHistory':
            session.editHistory.map(_attendanceEditEntryToMap).toList(),
        if (!existing) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (session.submittedAt != null) 'submittedAt': session.submittedAt,
      };

  List<AttendanceEditEntry> _readAttendanceEditHistory(Object? value) {
    final items = value is List ? value : const [];
    return items.whereType<Map>().map((item) {
      final changes = (item['changes'] is List
              ? item['changes'] as List
              : const [])
          .whereType<Map>()
          .map((change) => AttendanceEditChange(
                studentId: change['studentId'] as String? ?? '',
                studentName: change['studentName'] as String? ?? '',
                originalStatus: _attendanceStatusFromName(
                    change['originalStatus'] as String?),
                newStatus:
                    _attendanceStatusFromName(change['newStatus'] as String?),
              ))
          .toList();
      return AttendanceEditEntry(
        editedAt: _readTimestamp(item['editedAt']) ??
            item['editedAt'] as String? ??
            '',
        editedBy: item['editedBy'] as String? ?? '',
        editedByName: item['editedByName'] as String? ?? '',
        reason: item['reason'] as String? ?? '',
        changes: changes,
      );
    }).toList();
  }

  AttendanceStatus _attendanceStatusFromName(String? value) {
    if (value == null) return AttendanceStatus.present;
    return AttendanceStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => AttendanceStatus.present,
    );
  }

  AttendanceStatus? _nullableAttendanceStatusFromName(String? value) {
    if (value == null || value.isEmpty) return null;
    return AttendanceStatus.values
        .where((status) => status.name == value)
        .firstOrNull;
  }

  Map<String, dynamic> _attendanceEditEntryToMap(AttendanceEditEntry entry) {
    return {
      'editedAt': entry.editedAt,
      'editedBy': entry.editedBy,
      'editedByName': entry.editedByName,
      'reason': entry.reason,
      'changes': entry.changes
          .map((change) => {
                'studentId': change.studentId,
                'studentName': change.studentName,
                'originalStatus': change.originalStatus.name,
                'newStatus': change.newStatus.name,
              })
          .toList(),
    };
  }

  Map<String, dynamic> _attendanceRecordToMap(
    AttendanceRecord record, {
    required bool existing,
  }) =>
      {
        'id': record.id,
        'sessionId': record.sessionId,
        'slotId': record.slotId,
        'studentId': record.studentId,
        'studentName': record.studentName,
        'programId': record.programId,
        'programName': record.programName,
        'departmentId': record.departmentId,
        'section': record.section,
        'weekNo': record.weekNo,
        'sessionDate': record.sessionDate,
        'status': record.status.name,
        'checkIn': record.checkIn,
        'remarks': record.remarks,
        'remark': record.remarks,
        'countsAsAttended': record.countsAsAttended,
        'countsInDenominator': record.countsInDenominator,
        'isExempt': record.isExempt,
        'createdBy': record.createdBy,
        if (record.updatedBy != null) 'updatedBy': record.updatedBy,
        if (record.updatedByName != null) 'updatedByName': record.updatedByName,
        if (record.editReason != null) 'editReason': record.editReason,
        if (record.originalStatus != null)
          'originalStatus': record.originalStatus!.name,
        if (record.newStatus != null) 'newStatus': record.newStatus!.name,
        if (!existing) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  Map<String, dynamic> _disciplineReportToMap(
    DisciplineReport report, {
    required bool existing,
  }) =>
      {
        'studentId': report.studentId,
        'studentName': report.studentName,
        'programId': report.programId,
        'programName': report.programName,
        'departmentId': report.departmentId,
        'section': report.section,
        'subject': report.subject,
        'subjectCode': report.subjectCode,
        'subjectName': report.subjectName,
        'slotId': report.slotId,
        'lecturer': report.lecturer,
        'createdBy': report.createdBy,
        'createdByName': report.createdByName,
        'assignedReviewerIds': report.assignedReviewerIds,
        'assignedReviewerRoles': report.assignedReviewerRoles,
        'date': report.date,
        'issueType': report.issueType,
        'severity': report.severity,
        'description': report.description,
        'followUp': report.followUp,
        'status': _normalizeDisciplineStatus(report.status),
        if (!existing) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (report.reviewedAt != null) 'reviewedAt': report.reviewedAt,
        if (report.reviewedBy != null) 'reviewedBy': report.reviewedBy,
        if (report.reviewedByName != null)
          'reviewedByName': report.reviewedByName,
        if (report.reviewerRole != null) 'reviewerRole': report.reviewerRole,
        if (report.reviewerNotes != null) 'reviewerNotes': report.reviewerNotes,
        if (report.actionTakenAt != null) 'actionTakenAt': report.actionTakenAt,
        if (report.actionTakenBy != null) 'actionTakenBy': report.actionTakenBy,
        if (report.actionTakenByName != null)
          'actionTakenByName': report.actionTakenByName,
        if (report.actionTaken != null) 'actionTaken': report.actionTaken,
        if (report.actionTakenNote != null)
          'actionTakenNote': report.actionTakenNote,
        if (report.rejectionReason != null)
          'rejectionReason': report.rejectionReason,
        if (report.closedAt != null) 'closedAt': report.closedAt,
      };

  Map<String, dynamic> _userToMap(AppUser user) => {
        UserFields.uid: user.uid,
        UserFields.name: user.name,
        UserFields.email: user.email.toLowerCase(),
        UserFields.role: user.role.firestoreValue,
        UserFields.programId: user.programId,
        UserFields.departmentId: user.departmentId,
        UserFields.phoneNumber: user.phoneNumber,
        UserFields.lecturerProfileId: user.lecturerProfileId,
        UserFields.isActive: user.isActive,
        UserFields.createdAt: user.createdAt ?? FieldValue.serverTimestamp(),
        UserFields.updatedAt: FieldValue.serverTimestamp(),
      };

  String? _readTimestamp(Object? value) {
    if (value is Timestamp) {
      return value
          .toDate()
          .toIso8601String()
          .substring(0, 16)
          .replaceFirst('T', ' ');
    }
    return value as String?;
  }

  String _safeDocSegment(String value) {
    return value.replaceAll(RegExp(r'[/\\\s]+'), '_');
  }

  String _normalizeDisciplineStatus(String status) {
    final normalized = status.trim().toLowerCase().replaceAll(' ', '_');
    return switch (normalized) {
      'new' ||
      'submitted' ||
      'pending' ||
      'menunggu' ||
      'menunggu_semakan' =>
        'pending',
      'under_review' || 'reviewed' || 'disemak' => 'reviewed',
      'approved' ||
      'resolved' ||
      'action_taken' ||
      'tindakan_diambil' =>
        'action_taken',
      'closed' || 'ditutup' => 'closed',
      'rejected' || 'ditolak' => 'rejected',
      _ => normalized,
    };
  }

  Iterable<List<T>> _chunks<T>(List<T> items, int size) sync* {
    for (var i = 0; i < items.length; i += size) {
      final end = i + size > items.length ? items.length : i + size;
      yield items.sublist(i, end);
    }
  }
}

class _AttendanceRecordWrite {
  const _AttendanceRecordWrite({
    required this.ref,
    required this.record,
    required this.exists,
  });

  final DocumentReference<Map<String, dynamic>> ref;
  final AttendanceRecord record;
  final bool exists;
}
