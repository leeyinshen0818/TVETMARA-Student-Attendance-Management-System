import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/lecturer_seed_data.dart';
import '../data/mock_data.dart' as mock;
import '../models/app_models.dart';
import '../services/firestore_service.dart';

/// One-time function to upload all mock data into Firestore and create
/// Firebase Auth accounts for the demo users.
///
/// Call this only from an explicit debug/demo trigger. It rebuilds demo data
/// and does not run automatically during app startup.
Future<bool> seedFirestore() async {
  mock.initializeMockData();
  final fs = FirestoreService.instance;

  // Development helper for rebuilding mock Firestore data when run manually.

  // ------------------------------------------------------------------
  // 1. Wipe existing collections to prevent conflicts with old test data
  // ------------------------------------------------------------------
  final cols = [
    'users',
    'students',
    'lecturers',
    'rooms',
    'timetable_slots',
    'discipline_reports',
    'bookings',
    'departments',
    'programs',
    'academic_sessions',
    'subjects',
    'classes',
    'attendance_sessions',
    'attendance_records',
    'timetable_uploads',
    'booking_requests',
    'lecturer_course_assignments',
    'notifications',
  ];
  for (final col in cols) {
    final snap = await fs.db.collection(col).get();
    final batch = fs.db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ------------------------------------------------------------------
  // 2. Run migrations and structural seeding (programs, departments)
  // ------------------------------------------------------------------
  await fs.runMigrationAndSeed();
  await fs.seedAcademicSessions(mock.academicSessions);

  // ------------------------------------------------------------------
  // 3. Create Firebase Auth accounts and align users/{uid}
  // ------------------------------------------------------------------
  final authUidByMockId = <String, String>{};
  for (final user in [...mock.demoAuthUsers, ...mock.realLecturerLoginUsers]) {
    final password =
        user.role == UserRole.pentadbir ? 'admin123' : 'password123';
    UserCredential credential;
    try {
      credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: user.email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code != 'email-already-in-use') rethrow;
      credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: user.email,
        password: password,
      );
    }
    final uid = credential.user?.uid;
    if (uid != null) authUidByMockId[user.uid] = uid;
  }

  final seededUsers = mock.users
      .map((user) => AppUser(
            uid: authUidByMockId[user.uid] ?? user.uid,
            name: user.name,
            email: user.email,
            role: user.role,
            programId: user.programId,
            departmentId: user.departmentId,
            phoneNumber: user.phoneNumber,
            lecturerProfileId: user.lecturerProfileId,
            isActive: user.isActive,
            createdAt: user.createdAt,
            updatedAt: user.updatedAt,
          ))
      .toList();

  final seededLecturers = mock.lecturers
      .map((lecturer) => Lecturer(
            id: lecturer.id.startsWith('REAL_L_')
                ? lecturer.id
                : authUidByMockId[lecturer.id] ?? lecturer.id,
            name: lecturer.name,
            email: lecturer.email,
            department: lecturer.department,
            subjects: lecturer.subjects,
          ))
      .toList();

  final seededTimetable = mock.timetable
      .map((slot) => TimetableSlot(
            id: slot.id,
            timetableSlotId: slot.timetableSlotId,
            academicSessionId: slot.academicSessionId,
            programId: slot.programId,
            departmentId: slot.departmentId,
            classId: slot.classId,
            subjectId: slot.subjectId,
            session: slot.session,
            semester: slot.semester,
            program: slot.program,
            section: slot.section,
            subjectCode: slot.subjectCode,
            subjectName: slot.subjectName,
            lecturerId: authUidByMockId[slot.lecturerId] ?? slot.lecturerId,
            lecturerName: slot.lecturerName,
            lecturerEmail: slot.lecturerEmail,
            lecturerProfileId: slot.lecturerProfileId,
            roomId: slot.roomId,
            roomName: slot.roomName,
            day: slot.day,
            date: slot.date,
            dayOfWeek: slot.dayOfWeek,
            startTime: slot.startTime,
            endTime: slot.endTime,
            weekStart: slot.weekStart,
            weekEnd: slot.weekEnd,
            room: slot.room,
            enrolled: slot.enrolled,
            capacity: slot.capacity,
            classType: slot.classType,
            slotType: slot.slotType,
            status: slot.status,
            sourceUploadId: slot.sourceUploadId,
            createdBy: slot.createdBy,
            createdAt: slot.createdAt,
            updatedAt: slot.updatedAt,
          ))
      .toList();

  final seededBookings = mock.bookings
      .map((booking) => BookingRequest(
            id: booking.id,
            lecturerId:
                authUidByMockId[booking.lecturerId] ?? booking.lecturerId,
            lecturerName: booking.lecturerName,
            programId: booking.programId,
            departmentId: booking.departmentId,
            subject: booking.subject,
            section: booking.section,
            originalDate: booking.originalDate,
            originalTime: booking.originalTime,
            replacementDate: booking.replacementDate,
            replacementStart: booking.replacementStart,
            replacementEnd: booking.replacementEnd,
            roomId: booking.roomId,
            roomName: booking.roomName,
            room: booking.room,
            reason: booking.reason,
            remarks: booking.remarks,
            status: booking.status,
            createdAt: booking.createdAt,
            updatedAt: booking.updatedAt,
          ))
      .toList();

  // ------------------------------------------------------------------
  // 4. Seed collections
  // ------------------------------------------------------------------
  await fs.seedUsers(seededUsers);
  await fs.seedStudents(mock.students);
  await fs.seedLecturers(seededLecturers);
  await fs.seedRooms(mock.roomResources);
  await fs.seedSubjects(mock.subjectsForSeed);
  await _seedLecturerCourseAssignments(
      fs, mock.lecturerCourseAssignmentsForSeed);
  await _seedClasses(fs, mock.demoClasses);
  await fs.seedTimetable(seededTimetable);
  await fs.seedDisciplineReports(mock.disciplineReports);
  await fs.seedBookings(seededBookings);

  // Seed normalized attendance sessions for reporting plus a compatible
  // legacy attendance snapshot for existing attendance views.
  for (final slot in seededTimetable) {
    final bundles = mock.attendanceBundlesForSlot(slot);
    if (bundles.isEmpty) continue;
    for (final bundle in bundles) {
      await fs.saveAttendanceSessionWithRecords(
        session: bundle.session,
        records: bundle.records,
      );
    }
    await fs.saveAttendance(slot.id, bundles.first.records);
  }

  // Sign out after creating accounts.
  await FirebaseAuth.instance.signOut();

  // ------------------------------------------------------------------
  // 5. Mark as seeded
  // ------------------------------------------------------------------
  await fs.db
      .collection('_meta')
      .doc('seed')
      .set({'seededAt': DateTime.now().toIso8601String()});

  return true; // seeding was performed
}

Future<void> _seedClasses(
  FirestoreService fs,
  List<mock.DemoClass> classes,
) async {
  for (var i = 0; i < classes.length; i += 400) {
    final batch = fs.db.batch();
    final chunk =
        classes.sublist(i, i + 400 > classes.length ? classes.length : i + 400);
    for (final item in chunk) {
      batch.set(fs.db.collection('classes').doc(item.classId), {
        'classId': item.classId,
        'programId': item.programId,
        'academicSessionId': item.academicSessionId,
        'semester': item.semester,
        'section': item.section,
        'displayName': item.displayName,
        'isActive': item.isActive,
        'dataSource': 'generated_demo',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}

Future<void> _seedLecturerCourseAssignments(
  FirestoreService fs,
  List<LecturerCourseAssignmentSeed> assignments,
) async {
  for (var i = 0; i < assignments.length; i += 400) {
    final batch = fs.db.batch();
    final chunk = assignments.sublist(
        i, i + 400 > assignments.length ? assignments.length : i + 400);
    for (final item in chunk) {
      batch.set(
        fs.db.collection('lecturer_course_assignments').doc(item.assignmentId),
        {
          'assignmentId': item.assignmentId,
          'academicSessionId': item.academicSessionId,
          'lecturerId': item.lecturerId,
          'lecturerName': item.lecturerName,
          'lecturerEmail': item.lecturerEmail,
          'programId': item.programId,
          'classId': item.classId,
          'subjectId': item.subjectId,
          'subjectCode': item.subjectCode,
          'subjectName': item.subjectName,
          'isActive': item.isActive,
          'dataSource': 'client_workbook_generated_demo_email',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    }
    await batch.commit();
  }
}
