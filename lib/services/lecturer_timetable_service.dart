// lib/services/lecturer_timetable_service.dart
//
// Read-only service for the lecturer timetable grid.

import 'package:cloud_firestore/cloud_firestore.dart';

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
  final String day;
  final String startTime;
  final String endTime;
  final String subjectCode;
  final String subjectName;
  final String section;
  final String roomId;
  final String programId;
  final String lecturerName;
  final String classType;

  factory LecturerSlot.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    final room = (d['roomId'] as String?)?.isNotEmpty == true
        ? d['roomId'] as String
        : (d['roomName'] as String?)?.isNotEmpty == true
            ? d['roomName'] as String
            : (d['room'] as String? ?? '');

    return LecturerSlot(
      slotId: doc.id,
      day: (d['day'] as String? ?? d['dayOfWeek'] as String? ?? '')
          .toUpperCase()
          .trim(),
      startTime: d['startTime'] as String? ?? '',
      endTime: d['endTime'] as String? ?? '',
      subjectCode: (d['subjectCode'] as String?)?.isNotEmpty == true
          ? d['subjectCode'] as String
          : (d['courseCode'] as String? ?? ''),
      subjectName: (d['subjectName'] as String?)?.isNotEmpty == true
          ? d['subjectName'] as String
          : (d['courseName'] as String? ?? ''),
      section: d['section'] as String? ?? d['classId'] as String? ?? '',
      roomId: room,
      programId: d['programId'] as String? ?? '',
      lecturerName: d['lecturerName'] as String? ?? '',
      classType: d['classType'] as String? ?? '',
    );
  }
}

class LecturerTimetableService {
  LecturerTimetableService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _collection = 'timetable_slots';
  static const String _sessionField = 'session';
  static const String _targetSession = 'JAN_JUN_2026';

  Stream<List<LecturerSlot>> watchSlots({
    required String lecturerId,
    required String lecturerEmail,
    String? lecturerProfileId,
  }) {
    final normalizedEmail = lecturerEmail.trim().toLowerCase();
    return _baseQuery().snapshots().map((snap) {
      return snap.docs
          .where((doc) => (doc.data()['isOfficial'] as bool? ?? true))
          .where((doc) => _matchesLecturer(
                doc.data(),
                lecturerId: lecturerId,
                lecturerEmail: normalizedEmail,
                lecturerProfileId: lecturerProfileId,
              ))
          .map(LecturerSlot.fromFirestore)
          .toList();
    });
  }

  Query<Map<String, dynamic>> _baseQuery() => _firestore
      .collection(_collection)
      .where(_sessionField, isEqualTo: _targetSession);

  bool _matchesLecturer(
    Map<String, dynamic> data, {
    required String lecturerId,
    required String lecturerEmail,
    String? lecturerProfileId,
  }) {
    final slotEmail = (data['lecturerEmail'] as String?)?.trim().toLowerCase();
    if (data['lecturerId'] == lecturerId) return true;
    if (lecturerEmail.isNotEmpty && slotEmail == lecturerEmail) return true;
    if (lecturerProfileId != null &&
        lecturerProfileId.isNotEmpty &&
        data['lecturerProfileId'] == lecturerProfileId) {
      return true;
    }
    return false;
  }
}
