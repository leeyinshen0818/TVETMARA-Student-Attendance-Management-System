// ignore_for_file: constant_identifier_names

import '../core/constants/firestore_constants.dart';

enum UserRole {
  pentadbir,
  ketua_program,
  ketua_jabatan,
  pensyarah;

  String get firestoreValue => switch (this) {
        UserRole.pentadbir => AppRoles.pentadbir,
        UserRole.ketua_program => AppRoles.ketuaProgram,
        UserRole.ketua_jabatan => AppRoles.ketuaJabatan,
        UserRole.pensyarah => AppRoles.pensyarah,
      };

  static UserRole fromFirestore(String? value) {
    return switch (value) {
      AppRoles.pentadbir || 'admin' => UserRole.pentadbir,
      AppRoles.ketuaProgram || 'ketuaProgram' => UserRole.ketua_program,
      AppRoles.ketuaJabatan || 'ketuaJabatan' => UserRole.ketua_jabatan,
      AppRoles.pensyarah || 'lecturer' => UserRole.pensyarah,
      _ => UserRole.pensyarah,
    };
  }
}

enum AttendanceStatus { present, absent, mc, ck, late }

extension AttendanceStatusRules on AttendanceStatus {
  String get label => switch (this) {
        AttendanceStatus.present => 'Hadir',
        AttendanceStatus.late => 'Lewat',
        AttendanceStatus.absent => 'Tidak Hadir',
        AttendanceStatus.mc => 'MC',
        AttendanceStatus.ck => 'CK',
      };

  bool get countsAsAttended =>
      this == AttendanceStatus.present || this == AttendanceStatus.late;
  bool get isExempt =>
      this == AttendanceStatus.mc || this == AttendanceStatus.ck;
  bool get countsInDenominator => !isExempt;
}

class AttendanceSummary {
  const AttendanceSummary({
    required this.present,
    required this.late,
    required this.absent,
    required this.mc,
    required this.ck,
  });

  final int present;
  final int late;
  final int absent;
  final int mc;
  final int ck;

  int get attended => present + late;
  int get denominator => present + late + absent;
  int get percentage =>
      denominator == 0 ? 100 : ((attended / denominator) * 100).round();

  AttendanceSummary add(AttendanceStatus status) {
    return AttendanceSummary(
      present: present + (status == AttendanceStatus.present ? 1 : 0),
      late: late + (status == AttendanceStatus.late ? 1 : 0),
      absent: absent + (status == AttendanceStatus.absent ? 1 : 0),
      mc: mc + (status == AttendanceStatus.mc ? 1 : 0),
      ck: ck + (status == AttendanceStatus.ck ? 1 : 0),
    );
  }
}

class AttendanceSession {
  const AttendanceSession({
    required this.id,
    required this.slotId,
    required this.sessionDate,
    required this.weekNo,
    required this.academicSession,
    required this.semester,
    required this.programId,
    required this.programName,
    this.departmentId,
    required this.section,
    required this.subjectCode,
    required this.subjectName,
    required this.lecturerId,
    required this.lecturerName,
    required this.status,
    required this.totalStudents,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
    required this.mcCount,
    required this.ckCount,
    required this.attendancePercentage,
    required this.duplicateKey,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.submittedAt,
  });

  final String id;
  final String slotId;
  final String sessionDate;
  final int weekNo;
  final String academicSession;
  final int semester;
  final String programId;
  final String programName;
  final String? departmentId;
  final String section;
  final String subjectCode;
  final String subjectName;
  final String lecturerId;
  final String lecturerName;
  final String status;
  final int totalStudents;
  final int presentCount;
  final int lateCount;
  final int absentCount;
  final int mcCount;
  final int ckCount;
  final int attendancePercentage;
  final String duplicateKey;
  final String createdBy;
  final String? createdAt;
  final String? updatedAt;
  final String? submittedAt;

  int get attendedCount => presentCount + lateCount;
  int get denominator => presentCount + lateCount + absentCount;
}

class Department {
  const Department({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

class ProgramCode {
  const ProgramCode({
    required this.id,
    required this.name,
    this.departmentId,
  });

  final String id;
  final String name;
  final String? departmentId;
}

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.programId,
    this.departmentId,
    this.phoneNumber,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? programId;
  final String? departmentId;
  final String? phoneNumber;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  // Temporary compatibility aliases for modules not included in Phase 1.
  String get id => uid;
  String? get program => programId;
  String? get department => departmentId;
  bool get active => isActive;
  String get lastLogin => updatedAt ?? '';
}

class Student {
  const Student({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.program,
    required this.semester,
    required this.section,
    required this.attendance,
    this.active = true,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String program;
  final int semester;
  final String section;
  final int attendance;
  final bool active;
}

class RoomResource {
  const RoomResource({
    required this.name,
    required this.block,
    required this.type,
    this.capacity,
  });

  final String name;
  final String block;
  final String type;
  final int? capacity;
}

class Lecturer {
  const Lecturer({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.subjects,
  });

  final String id;
  final String name;
  final String email;
  final String department;
  final List<String> subjects;
}

class SubjectCourse {
  const SubjectCourse({
    required this.subjectId,
    required this.programId,
    required this.subjectCode,
    required this.subjectName,
  });

  final String subjectId;
  final String programId;
  final String subjectCode;
  final String subjectName;
}

class TimetableSlot {
  const TimetableSlot({
    required this.id,
    String? timetableSlotId,
    this.academicSessionId,
    this.programId,
    this.departmentId,
    this.classId,
    this.subjectId,
    required this.session,
    required this.semester,
    required this.program,
    required this.section,
    required this.subjectCode,
    required this.subjectName,
    required this.lecturerId,
    required this.lecturerName,
    this.roomId,
    this.roomName,
    required this.day,
    required this.date,
    this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.weekStart,
    this.weekEnd,
    required this.room,
    required this.enrolled,
    required this.capacity,
    required this.classType,
    required this.slotType,
    required this.status,
    this.sourceUploadId,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  }) : timetableSlotId = timetableSlotId ?? id;

  final String id;
  final String timetableSlotId;
  final String? academicSessionId;
  final String? programId;
  final String? departmentId;
  final String? classId;
  final String? subjectId;
  final String session;
  final int semester;
  final String program;
  final String section;
  final String subjectCode;
  final String subjectName;
  final String lecturerId;
  final String lecturerName;
  final String? roomId;
  final String? roomName;
  final String day;
  final String date;
  final String? dayOfWeek;
  final String startTime;
  final String endTime;
  final String? weekStart;
  final String? weekEnd;
  final String room;
  final int enrolled;
  final int capacity;
  final String classType;
  final String slotType;
  final String status;
  final String? sourceUploadId;
  final String? createdBy;
  final String? createdAt;
  final String? updatedAt;

  TimetableSlot copyWith({String? status, String? slotType}) {
    return TimetableSlot(
      id: id,
      timetableSlotId: timetableSlotId,
      academicSessionId: academicSessionId,
      programId: programId,
      departmentId: departmentId,
      classId: classId,
      subjectId: subjectId,
      session: session,
      semester: semester,
      program: program,
      section: section,
      subjectCode: subjectCode,
      subjectName: subjectName,
      lecturerId: lecturerId,
      lecturerName: lecturerName,
      roomId: roomId,
      roomName: roomName,
      day: day,
      date: date,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      weekStart: weekStart,
      weekEnd: weekEnd,
      room: room,
      enrolled: enrolled,
      capacity: capacity,
      classType: classType,
      slotType: slotType ?? this.slotType,
      status: status ?? this.status,
      sourceUploadId: sourceUploadId,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class AttendanceRecord {
  const AttendanceRecord({
    required this.slotId,
    required this.studentId,
    required this.status,
    required this.checkIn,
    required this.remarks,
    this.id,
    this.sessionId,
    this.studentName,
    this.programId,
    this.programName,
    this.departmentId,
    this.section,
    this.weekNo,
    this.sessionDate,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String? sessionId;
  final String slotId;
  final String studentId;
  final String? studentName;
  final String? programId;
  final String? programName;
  final String? departmentId;
  final String? section;
  final int? weekNo;
  final String? sessionDate;
  final AttendanceStatus status;
  final String checkIn;
  final String remarks;
  final String? createdBy;
  final String? createdAt;
  final String? updatedAt;

  bool get countsAsAttended => status.countsAsAttended;
  bool get countsInDenominator => status.countsInDenominator;
  bool get isExempt => status.isExempt;

  AttendanceRecord copyWith({
    String? id,
    String? sessionId,
    String? slotId,
    String? studentId,
    String? studentName,
    String? programId,
    String? programName,
    String? departmentId,
    String? section,
    int? weekNo,
    String? sessionDate,
    AttendanceStatus? status,
    String? checkIn,
    String? remarks,
    String? createdBy,
    String? createdAt,
    String? updatedAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      slotId: slotId ?? this.slotId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      programId: programId ?? this.programId,
      programName: programName ?? this.programName,
      departmentId: departmentId ?? this.departmentId,
      section: section ?? this.section,
      weekNo: weekNo ?? this.weekNo,
      sessionDate: sessionDate ?? this.sessionDate,
      status: status ?? this.status,
      checkIn: checkIn ?? this.checkIn,
      remarks: remarks ?? this.remarks,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class DisciplineReport {
  const DisciplineReport({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.section,
    required this.subject,
    required this.lecturer,
    required this.date,
    required this.issueType,
    required this.severity,
    required this.description,
    required this.followUp,
    required this.status,
    this.programId,
    this.programName,
    this.departmentId,
    this.subjectCode,
    this.subjectName,
    this.slotId,
    this.createdBy,
    this.createdByName,
    this.assignedReviewerIds = const [],
    this.assignedReviewerRoles = const [],
    this.createdAt,
    this.updatedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.actionTakenAt,
    this.closedAt,
  });

  final String id;
  final String studentId;
  final String studentName;
  final String? programId;
  final String? programName;
  final String? departmentId;
  final String section;
  final String subject;
  final String? subjectCode;
  final String? subjectName;
  final String? slotId;
  final String lecturer;
  final String? createdBy;
  final String? createdByName;
  final List<String> assignedReviewerIds;
  final List<String> assignedReviewerRoles;
  final String date;
  final String issueType;
  final String severity;
  final String description;
  final bool followUp;
  final String status;
  final String? createdAt;
  final String? updatedAt;
  final String? reviewedAt;
  final String? reviewedBy;
  final String? actionTakenAt;
  final String? closedAt;

  DisciplineReport copyWith({
    String? status,
    String? programId,
    String? programName,
    String? departmentId,
    String? subjectCode,
    String? subjectName,
    String? slotId,
    String? createdBy,
    String? createdByName,
    List<String>? assignedReviewerIds,
    List<String>? assignedReviewerRoles,
    String? createdAt,
    String? updatedAt,
    String? reviewedAt,
    String? reviewedBy,
    String? actionTakenAt,
    String? closedAt,
  }) {
    return DisciplineReport(
      id: id,
      studentId: studentId,
      studentName: studentName,
      programId: programId ?? this.programId,
      programName: programName ?? this.programName,
      departmentId: departmentId ?? this.departmentId,
      section: section,
      subject: subject,
      subjectCode: subjectCode ?? this.subjectCode,
      subjectName: subjectName ?? this.subjectName,
      slotId: slotId ?? this.slotId,
      lecturer: lecturer,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      assignedReviewerIds:
          assignedReviewerIds ?? List<String>.from(this.assignedReviewerIds),
      assignedReviewerRoles: assignedReviewerRoles ??
          List<String>.from(this.assignedReviewerRoles),
      date: date,
      issueType: issueType,
      severity: severity,
      description: description,
      followUp: followUp,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      actionTakenAt: actionTakenAt ?? this.actionTakenAt,
      closedAt: closedAt ?? this.closedAt,
    );
  }
}

class BookingRequest {
  const BookingRequest({
    required this.id,
    required this.lecturerId,
    required this.lecturerName,
    required this.subject,
    required this.section,
    required this.originalDate,
    required this.originalTime,
    required this.replacementDate,
    required this.replacementStart,
    required this.replacementEnd,
    required this.room,
    required this.reason,
    required this.remarks,
    required this.status,
  });

  final String id;
  final String lecturerId;
  final String lecturerName;
  final String subject;
  final String section;
  final String originalDate;
  final String originalTime;
  final String replacementDate;
  final String replacementStart;
  final String replacementEnd;
  final String room;
  final String reason;
  final String remarks;
  final String status;

  BookingRequest copyWith({String? status}) {
    return BookingRequest(
      id: id,
      lecturerId: lecturerId,
      lecturerName: lecturerName,
      subject: subject,
      section: section,
      originalDate: originalDate,
      originalTime: originalTime,
      replacementDate: replacementDate,
      replacementStart: replacementStart,
      replacementEnd: replacementEnd,
      room: room,
      reason: reason,
      remarks: remarks,
      status: status ?? this.status,
    );
  }
}
