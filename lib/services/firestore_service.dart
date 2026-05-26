import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_constants.dart';
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

  // ---------------------------------------------------------------------------
  // Account Registration
  // ---------------------------------------------------------------------------
  Future<void> createUserProfile(AppUser user) async {
    await _usersCol.doc(user.uid).set(_userToMap(user));
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

  Stream<List<TimetableSlot>> timetableStream() {
    return _timetableCol.snapshots().map(
          (snap) => snap.docs.map(_docToSlot).toList(),
        );
  }

  Future<void> updateSlotStatus(String slotId, String status) async {
    await _timetableCol.doc(slotId).update({'status': status});
  }

  Future<void> addTimetableSlot(TimetableSlot slot) async {
    await _timetableCol.doc(slot.id).set(_slotToMap(slot));
  }

  Future<void> updateTimetableSlot(TimetableSlot slot) async {
    await _timetableCol
        .doc(slot.id)
        .set(_slotToMap(slot), SetOptions(merge: true));
  }

  Future<void> deleteTimetableSlot(String slotId) async {
    await _timetableCol.doc(slotId).delete();
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

  // ---------------------------------------------------------------------------
  // Attendance
  // ---------------------------------------------------------------------------
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
    await _disciplineCol.doc(report.id).set({
      'studentId': report.studentId,
      'studentName': report.studentName,
      'section': report.section,
      'subject': report.subject,
      'lecturer': report.lecturer,
      'date': report.date,
      'issueType': report.issueType,
      'severity': report.severity,
      'description': report.description,
      'followUp': report.followUp,
      'status': report.status,
    });
  }

  Future<void> updateDisciplineStatus(String id, String status) async {
    await _disciplineCol.doc(id).update({'status': status});
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
      'subject': booking.subject,
      'section': booking.section,
      'originalDate': booking.originalDate,
      'originalTime': booking.originalTime,
      'replacementDate': booking.replacementDate,
      'replacementStart': booking.replacementStart,
      'replacementEnd': booking.replacementEnd,
      'room': booking.room,
      'reason': booking.reason,
      'remarks': booking.remarks,
      'status': booking.status,
    });
  }

  Future<void> updateBookingStatus(String id, String status) async {
    await _bookingsCol.doc(id).update({'status': status});
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
        batch.set(_studentsCol.doc(s.id), {
          'name': s.name,
          'email': s.email,
          'phone': s.phone,
          'program': s.program,
          'semester': s.semester,
          'section': s.section,
          'attendance': s.attendance,
          'active': s.active,
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
      batch.set(_disciplineCol.doc(r.id), {
        'studentId': r.studentId,
        'studentName': r.studentName,
        'section': r.section,
        'subject': r.subject,
        'lecturer': r.lecturer,
        'date': r.date,
        'issueType': r.issueType,
        'severity': r.severity,
        'description': r.description,
        'followUp': r.followUp,
        'status': r.status,
      });
    }
    await batch.commit();
  }

  Future<void> seedBookings(List<BookingRequest> bookings) async {
    final batch = _db.batch();
    for (final b in bookings) {
      batch.set(_bookingsCol.doc(b.id), {
        'lecturerId': b.lecturerId,
        'lecturerName': b.lecturerName,
        'subject': b.subject,
        'section': b.section,
        'originalDate': b.originalDate,
        'originalTime': b.originalTime,
        'replacementDate': b.replacementDate,
        'replacementStart': b.replacementStart,
        'replacementEnd': b.replacementEnd,
        'room': b.room,
        'reason': b.reason,
        'remarks': b.remarks,
        'status': b.status,
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

  TimetableSlot _docToSlot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return TimetableSlot(
      id: doc.id,
      session: d['session'] as String,
      semester: d['semester'] as int,
      program: d['program'] as String,
      section: d['section'] as String,
      subjectCode: d['subjectCode'] as String,
      subjectName: d['subjectName'] as String,
      lecturerId: d['lecturerId'] as String,
      lecturerName: d['lecturerName'] as String,
      day: d['day'] as String,
      date: d['date'] as String,
      startTime: d['startTime'] as String,
      endTime: d['endTime'] as String,
      room: d['room'] as String,
      enrolled: d['enrolled'] as int,
      capacity: d['capacity'] as int,
      classType: d['classType'] as String,
      slotType: d['slotType'] as String,
      status: d['status'] as String,
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

  DisciplineReport _docToReport(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return DisciplineReport(
      id: doc.id,
      studentId: d['studentId'] as String,
      studentName: d['studentName'] as String,
      section: d['section'] as String,
      subject: d['subject'] as String,
      lecturer: d['lecturer'] as String,
      date: d['date'] as String,
      issueType: d['issueType'] as String,
      severity: d['severity'] as String,
      description: d['description'] as String,
      followUp: d['followUp'] as bool,
      status: d['status'] as String,
    );
  }

  BookingRequest _docToBooking(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return BookingRequest(
      id: doc.id,
      lecturerId: d['lecturerId'] as String,
      lecturerName: d['lecturerName'] as String,
      subject: d['subject'] as String,
      section: d['section'] as String,
      originalDate: d['originalDate'] as String,
      originalTime: d['originalTime'] as String,
      replacementDate: d['replacementDate'] as String,
      replacementStart: d['replacementStart'] as String,
      replacementEnd: d['replacementEnd'] as String,
      room: d['room'] as String,
      reason: d['reason'] as String,
      remarks: d['remarks'] as String,
      status: d['status'] as String,
    );
  }

  // ---------------------------------------------------------------------------
  // Model → Map converters
  // ---------------------------------------------------------------------------
  Map<String, dynamic> _slotToMap(TimetableSlot slot) => {
        'session': slot.session,
        'semester': slot.semester,
        'program': slot.program,
        'section': slot.section,
        'subjectCode': slot.subjectCode,
        'subjectName': slot.subjectName,
        'lecturerId': slot.lecturerId,
        'lecturerName': slot.lecturerName,
        'day': slot.day,
        'date': slot.date,
        'startTime': slot.startTime,
        'endTime': slot.endTime,
        'room': slot.room,
        'enrolled': slot.enrolled,
        'capacity': slot.capacity,
        'classType': slot.classType,
        'slotType': slot.slotType,
        'status': slot.status,
      };

  Map<String, dynamic> _userToMap(AppUser user) => {
        UserFields.uid: user.uid,
        UserFields.name: user.name,
        UserFields.email: user.email.toLowerCase(),
        UserFields.role: user.role.firestoreValue,
        UserFields.programId: user.programId,
        UserFields.departmentId: user.departmentId,
        UserFields.phoneNumber: user.phoneNumber,
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
}
