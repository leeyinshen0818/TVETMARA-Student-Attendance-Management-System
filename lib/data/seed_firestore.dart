import 'package:firebase_auth/firebase_auth.dart';

import '../data/mock_data.dart' as mock;
import '../models/app_models.dart';
import '../services/firestore_service.dart';

/// One-time function to upload all mock data into Firestore and create
/// Firebase Auth accounts for the demo users.
///
/// Call this once (e.g. from a hidden admin button), then never again.
/// It checks whether seeding is needed by looking for a marker document.
Future<bool> seedFirestore() async {
  mock.initializeMockData();
  final fs = FirestoreService.instance;

  // Guard removed: Force Seed DB button should always run.

  // ------------------------------------------------------------------
  // 1. Wipe existing collections to prevent conflicts with old test data
  // ------------------------------------------------------------------
  final cols = [
    'users', 'students', 'lecturers', 'rooms', 
    'timetable_slots', 'discipline_reports', 
    'bookings', 'departments', 'programs',
    'attendance_records'
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

  // ------------------------------------------------------------------
  // 2. Seed collections
  // ------------------------------------------------------------------
  await fs.seedUsers(mock.users);
  await fs.seedStudents(mock.students);
  await fs.seedLecturers(mock.lecturers);
  await fs.seedRooms(mock.roomResources);
  await fs.seedTimetable(mock.timetable);
  await fs.seedDisciplineReports(mock.disciplineReports);
  await fs.seedBookings(mock.bookings);

  // Seed attendance for completed slots
  for (final slot
      in mock.timetable.where((s) => s.status == 'Attendance Completed')) {
    final records = mock.attendanceForSlot(slot);
    await fs.saveAttendance(slot.id, records);
  }

  // ------------------------------------------------------------------
  // 3. Create Firebase Auth accounts for demo users
  // ------------------------------------------------------------------
  final demoAccounts = mock.users.map((u) => {
    'email': u.email,
    'password': u.role == UserRole.admin ? 'admin123' : 'password123',
  }).toList();

  for (final account in demoAccounts) {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: account['email']!,
        password: account['password']!,
      );
    } on FirebaseAuthException catch (e) {
      // If account already exists, that's fine — skip it.
      if (e.code != 'email-already-in-use') rethrow;
    }
  }

  // Sign out after creating accounts (we were signed in as the last created user)
  await FirebaseAuth.instance.signOut();

  // ------------------------------------------------------------------
  // 4. Mark as seeded
  // ------------------------------------------------------------------
  await fs.db
      .collection('_meta')
      .doc('seed')
      .set({'seededAt': DateTime.now().toIso8601String()});

  return true; // seeding was performed
}
