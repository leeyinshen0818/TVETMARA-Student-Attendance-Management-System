import 'package:firebase_auth/firebase_auth.dart';

import '../data/mock_data.dart' as mock;
import '../services/firestore_service.dart';

/// One-time function to upload all mock data into Firestore and create
/// Firebase Auth accounts for the demo users.
///
/// Call this once (e.g. from a hidden admin button), then never again.
/// It checks whether seeding is needed by looking for a marker document.
Future<bool> seedFirestore() async {
  final fs = FirestoreService.instance;

  // ------------------------------------------------------------------
  // Guard: skip if already seeded
  // ------------------------------------------------------------------
  final marker = await fs.db.collection('_meta').doc('seed').get();
  if (marker.exists) {
    return false; // already seeded
  }

  // ------------------------------------------------------------------
  // 1. Run migrations and structural seeding (programs, departments)
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
  // 2. Create Firebase Auth accounts for demo users
  // ------------------------------------------------------------------
  final demoAccounts = <Map<String, String>>[
    {'email': 'admin@tvetmara.edu.my', 'password': 'admin123'},
    {'email': 'kj_elektrik@tvetmara.edu.my', 'password': 'password123'},
    {'email': 'kp_ded@tvetmara.edu.my', 'password': 'password123'},
    {'email': 'lecturer@tvetmara.edu.my', 'password': 'lecturer123'},
    {'email': 'zarina@tvetmara.edu.my', 'password': 'lecturer123'},
  ];

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
  // 3. Mark as seeded
  // ------------------------------------------------------------------
  await fs.db
      .collection('_meta')
      .doc('seed')
      .set({'seededAt': DateTime.now().toIso8601String()});

  return true; // seeding was performed
}
