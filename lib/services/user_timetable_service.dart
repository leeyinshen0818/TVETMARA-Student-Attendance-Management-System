import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_constants.dart';
import '../models/app_models.dart';

/// Service to manage strict role-based and program-aware database query filtering
/// for timetable slots and other related collections.
class UserTimetableService {
  final FirebaseFirestore _db;

  /// Constructor allowing dependency injection of a [FirebaseFirestore] instance.
  UserTimetableService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  /// Helper method to deserialize a Firestore document snapshot into a [TimetableSlot].
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
      createdBy: d['createdBy'] as String?,
      createdAt: _readTimestamp(d['createdAt']),
      updatedAt: _readTimestamp(d['updatedAt']),
    );
  }

  /// Helper method to deserialize a Firestore document snapshot into an [AppUser].
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

  /// Helper method to deserialize a Firestore document snapshot into a [Student].
  Student _docToStudent(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Student(
      id: doc.id,
      name: d['name'] as String? ?? '',
      email: d['email'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      program: d['program'] as String? ?? '',
      semester: d['semester'] as int? ?? 1,
      section: d['section'] as String? ?? '',
      attendance: d['attendance'] as int? ?? 0,
      active: d['active'] as bool? ?? true,
    );
  }

  /// Safe helper method to parse Firestore [Timestamp] or [String] values to ISO/standard date string format.
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

  /// Returns a filtered Firestore Stream from the 'timetable_slots' collection based on user role:
  ///
  /// - If [currentUser.role] == [UserRole.pensyarah], filter where 'lecturerId' == [currentUser.id].
  /// - If [currentUser.role] == [UserRole.ketua_program] (ketuaProgram), filter where 'programId' == [currentUser.program].
  /// - If [currentUser.role] == [UserRole.ketua_jabatan] (ketuaJabatan), filter where 'departmentId' == [currentUser.department].
  /// - If [currentUser.role] == [UserRole.pentadbir] (admin), fetch all documents across the institution without limits.
  ///
  /// Returns an empty stream if critical filtering values are null/empty for restricted roles.
  Stream<List<TimetableSlot>> getFilteredTimetableStream(AppUser currentUser) {
    Query<Map<String, dynamic>> query =
        _db.collection(FirestoreCollections.timetableSlots);

    switch (currentUser.role) {
      case UserRole.pensyarah:
        final lecturerId = currentUser.id;
        if (lecturerId.isEmpty) {
          return Stream.value(<TimetableSlot>[]);
        }
        query = query.where('lecturerId', isEqualTo: lecturerId);
        break;

      case UserRole.ketua_program:
        final program = currentUser.program;
        if (program == null || program.isEmpty) {
          return Stream.value(<TimetableSlot>[]);
        }
        query = query.where('programId', isEqualTo: program);
        break;

      case UserRole.ketua_jabatan:
        final department = currentUser.department;
        if (department == null || department.isEmpty) {
          return Stream.value(<TimetableSlot>[]);
        }
        query = query.where('departmentId', isEqualTo: department);
        break;

      case UserRole.pentadbir:
        // Admin scope: fetch all documents across the institution without query limits.
        break;
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => _docToSlot(doc)).toList();
    });
  }

  /// Helper function to query the 'users' collection (Admin scope requirements).
  Stream<List<AppUser>> getUsersStream() {
    return _db
        .collection(FirestoreCollections.users)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => _docToAppUser(doc)).toList();
    });
  }

  /// Helper function to query the 'students' collection (Admin scope requirements).
  Stream<List<Student>> getStudentsStream() {
    return _db
        .collection(FirestoreCollections.students)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => _docToStudent(doc)).toList();
    });
  }

  /// Helper function to query the 'lecturer_courses' collection (Admin scope requirements).
  /// Maps to raw dynamic maps as there is no specific model for lecturer courses in Phase 1.
  Stream<List<Map<String, dynamic>>> getLecturerCoursesStream() {
    return _db.collection('lecturer_course_assignments').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  /// Asynchronously updates a user's active status in the 'users' collection.
  Future<void> updateUserStatus(String uid, bool isActive) async {
    try {
      await _db.collection(FirestoreCollections.users).doc(uid).update({
        UserFields.isActive: isActive,
        UserFields.updatedAt: FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal mengemas kini status aktif pengguna di Firestore: $e');
    }
  }
}
