// lib/services/lecturer_timetable_service.dart
//
// READ-ONLY service for Module 5: Timetable Slot Display (Lecturer View).
// Fetches timetable slots for the currently logged-in lecturer from Firestore.
// Does NOT write, create, or modify any Firestore documents.

import 'package:cloud_firestore/cloud_firestore.dart';

/// Lightweight model representing one cell in the timetable grid.
///
/// Field names mirror the ACTUAL Firestore document schema in /timetable_slots/
/// as confirmed from the Firebase console:
///
///   lecturerId   – e.g. "REAL_L_044"   (seeded lecturer ID, NOT Auth UID)
///   lecturerName – e.g. "NORHATINI BINTI IBRAHIM"
///   programId    – e.g. "DED" | "DGS"  (used to scope demo queries)
///   session      – e.g. "JAN_JUN_2026" (NOT academicSession)
///   section      – e.g. "DED 1A"
///   classType    – e.g. "Client Sample DED 1A"
///   day          – e.g. "ISNIN" (Malay uppercase)
///   startTime    – e.g. "08:00"
///   endTime      – e.g. "10:00"
///   subjectCode  – e.g. "DEB10012"
///   subjectName  – e.g. "KOMUNIKASI DALAM BAHASA INGGERIS"
///   room / roomId / roomName – room identifiers
///   semester     – int
class LecturerSlot {
  const LecturerSlot({
    required this.slotId,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.subjectCode,
    required this.subjectName,
    required this.section,
    required this.roomId,
    required this.programId,
    required this.lecturerName,
    this.classType = '',
  });

  final String slotId;

  /// Day string in Malay uppercase, e.g. 'ISNIN', 'SELASA', 'RABU',
  /// 'KHAMIS', 'JUMAAT'.
  final String day;

  /// e.g. "08:00"
  final String startTime;

  /// e.g. "10:00"
  final String endTime;

  /// e.g. "DEB10012"
  final String subjectCode;

  /// e.g. "KOMUNIKASI DALAM BAHASA INGGERIS"
  final String subjectName;

  /// e.g. "DED 1A"
  final String section;

  /// Room identifier — prefers roomId, falls back to roomName then room.
  final String roomId;

  /// e.g. "DED" | "DGS"
  final String programId;

  final String lecturerName;

  /// e.g. "Client Sample DED 1A" — informational only
  final String classType;

  factory LecturerSlot.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;

    // Room: Firestore has 'room', 'roomId', and 'roomName' — use whichever
    // is non-empty, in priority order.
    final room = (d['roomId'] as String?)?.isNotEmpty == true
        ? d['roomId'] as String
        : (d['roomName'] as String?)?.isNotEmpty == true
            ? d['roomName'] as String
            : (d['room'] as String? ?? '');

    return LecturerSlot(
      slotId: doc.id,
      day: (d['day'] as String? ?? '').toUpperCase().trim(),
      startTime: d['startTime'] as String? ?? '',
      endTime: d['endTime'] as String? ?? '',
      // Firestore uses 'subjectCode' / 'subjectName' in seeded data.
      // Fall back to 'courseCode' / 'courseName' for any older documents.
      subjectCode: (d['subjectCode'] as String?)?.isNotEmpty == true
          ? d['subjectCode'] as String
          : (d['courseCode'] as String? ?? ''),
      subjectName: (d['subjectName'] as String?)?.isNotEmpty == true
          ? d['subjectName'] as String
          : (d['courseName'] as String? ?? ''),
      section: d['section'] as String? ?? '',
      roomId: room,
      programId: d['programId'] as String? ?? '',
      lecturerName: d['lecturerName'] as String? ?? '',
      classType: d['classType'] as String? ?? '',
    );
  }
}

/// Service responsible for all READ operations related to the lecturer's
/// timetable grid.  No writes are performed here.
class LecturerTimetableService {
  LecturerTimetableService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _collection = 'timetable_slots';

  /// Firestore field name for the session — confirmed from Firebase console.
  static const String _sessionField = 'session';
  static const String _targetSession = 'JAN_JUN_2026';

  /// Returns a stream of slots for the given lecturer.
  ///
  /// Query strategy (handles both real and seeded demo data):
  ///
  /// 1. PRIMARY: filter by `lecturerId` == [lecturerId] (the seeded ID like
  ///    "REAL_L_044", or a real Auth UID if the admin stored it that way).
  ///
  /// 2. FALLBACK: if [programId] is non-empty and the primary stream emits
  ///    zero results, automatically re-query by `programId` == [programId].
  ///    This covers the demo seed where `lecturerId` is an opaque string that
  ///    won't match the Firebase Auth UID of the demo account.
  ///
  /// Both queries are scoped to `session == 'JAN_JUN_2026'`.
  Stream<List<LecturerSlot>> watchSlots({
    required String lecturerId,
    required String programId,
  }) {
    final primaryStream = _queryStream(
      field: 'lecturerId',
      value: lecturerId,
    );

    // If programId is unknown we can't fall back, so return primary only.
    if (programId.isEmpty) return primaryStream;

    final fallbackStream = _queryStream(
      field: 'programId',
      value: programId,
    );

    // Use switchMap-style logic: listen to primary, and if it emits empty
    // switch to fallback. Implemented via asyncExpand on a combined stream.
    return primaryStream.asyncExpand((primarySlots) {
      if (primarySlots.isNotEmpty) {
        // Primary has data — emit it and keep listening to primary.
        return Stream.value(primarySlots);
      }
      // Primary is empty — transparently fall through to programId query.
      return fallbackStream;
    });
  }

  Query<Map<String, dynamic>> _baseQuery() => _firestore
      .collection(_collection)
      .where(_sessionField, isEqualTo: _targetSession);

  Stream<List<LecturerSlot>> _queryStream({
    required String field,
    required String value,
  }) {
    return _baseQuery()
        .where(field, isEqualTo: value)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => LecturerSlot.fromFirestore(d)).toList());
  }
}