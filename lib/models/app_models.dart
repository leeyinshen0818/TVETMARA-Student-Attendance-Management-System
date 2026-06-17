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
    this.updatedBy,
    this.updatedByName,
    this.editReason,
    this.editHistory = const [],
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
  final String? updatedBy;
  final String? updatedByName;
  final String? editReason;
  final List<AttendanceEditEntry> editHistory;

  int get attendedCount => presentCount + lateCount;
  int get denominator => presentCount + lateCount + absentCount;

  AttendanceSession copyWith({
    String? id,
    String? slotId,
    String? sessionDate,
    int? weekNo,
    String? academicSession,
    int? semester,
    String? programId,
    String? programName,
    String? departmentId,
    String? section,
    String? subjectCode,
    String? subjectName,
    String? lecturerId,
    String? lecturerName,
    String? status,
    int? totalStudents,
    int? presentCount,
    int? lateCount,
    int? absentCount,
    int? mcCount,
    int? ckCount,
    int? attendancePercentage,
    String? duplicateKey,
    String? createdBy,
    String? createdAt,
    String? updatedAt,
    String? submittedAt,
    String? updatedBy,
    String? updatedByName,
    String? editReason,
    List<AttendanceEditEntry>? editHistory,
  }) {
    return AttendanceSession(
      id: id ?? this.id,
      slotId: slotId ?? this.slotId,
      sessionDate: sessionDate ?? this.sessionDate,
      weekNo: weekNo ?? this.weekNo,
      academicSession: academicSession ?? this.academicSession,
      semester: semester ?? this.semester,
      programId: programId ?? this.programId,
      programName: programName ?? this.programName,
      departmentId: departmentId ?? this.departmentId,
      section: section ?? this.section,
      subjectCode: subjectCode ?? this.subjectCode,
      subjectName: subjectName ?? this.subjectName,
      lecturerId: lecturerId ?? this.lecturerId,
      lecturerName: lecturerName ?? this.lecturerName,
      status: status ?? this.status,
      totalStudents: totalStudents ?? this.totalStudents,
      presentCount: presentCount ?? this.presentCount,
      lateCount: lateCount ?? this.lateCount,
      absentCount: absentCount ?? this.absentCount,
      mcCount: mcCount ?? this.mcCount,
      ckCount: ckCount ?? this.ckCount,
      attendancePercentage: attendancePercentage ?? this.attendancePercentage,
      duplicateKey: duplicateKey ?? this.duplicateKey,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedByName: updatedByName ?? this.updatedByName,
      editReason: editReason ?? this.editReason,
      editHistory: editHistory ?? this.editHistory,
    );
  }
}

class AttendanceEditChange {
  const AttendanceEditChange({
    required this.studentId,
    required this.studentName,
    required this.originalStatus,
    required this.newStatus,
  });

  final String studentId;
  final String studentName;
  final AttendanceStatus originalStatus;
  final AttendanceStatus newStatus;
}

class AttendanceEditEntry {
  const AttendanceEditEntry({
    required this.editedAt,
    required this.editedBy,
    required this.editedByName,
    required this.reason,
    required this.changes,
  });

  final String editedAt;
  final String editedBy;
  final String editedByName;
  final String reason;
  final List<AttendanceEditChange> changes;
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

class AcademicSession {
  const AcademicSession({
    required this.academicSessionId,
    required this.name,
    required this.isActive,
    this.status = 'active',
    this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
  });

  final String academicSessionId;
  final String name;
  final bool isActive;
  final String status;
  final String? startDate;
  final String? endDate;
  final String? createdAt;
  final String? updatedAt;

  AcademicSession copyWith({
    String? name,
    bool? isActive,
    String? status,
    String? startDate,
    String? endDate,
    String? createdAt,
    String? updatedAt,
  }) {
    return AcademicSession(
      academicSessionId: academicSessionId,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.programId,
    this.departmentId,
    this.lecturerProfileId,
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
  final String? lecturerProfileId;
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

class StudentDashboardSummary {
  const StudentDashboardSummary({
    required this.totalStudents,
    required this.belowThresholdStudents,
    required this.meetsThresholdStudents,
    required this.below95Students,
    required this.below90Students,
    required this.below85Students,
    required this.below80Students,
  });

  const StudentDashboardSummary.empty()
      : totalStudents = 0,
        belowThresholdStudents = 0,
        meetsThresholdStudents = 0,
        below95Students = 0,
        below90Students = 0,
        below85Students = 0,
        below80Students = 0;

  final int totalStudents;
  final int belowThresholdStudents;
  final int meetsThresholdStudents;
  final int below95Students;
  final int below90Students;
  final int below85Students;
  final int below80Students;
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
    this.lecturerEmail,
    this.lecturerProfileId,
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
    this.importStatus,
    this.isOfficial = true,
    this.hasConflict = false,
    this.conflictTypes = const [],
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
  final String? lecturerEmail;
  final String? lecturerProfileId;
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
  final String? importStatus;
  final bool isOfficial;
  final bool hasConflict;
  final List<String> conflictTypes;
  final String? createdBy;
  final String? createdAt;
  final String? updatedAt;

  TimetableSlot copyWith({
    String? status,
    String? slotType,
    String? importStatus,
    bool? isOfficial,
    bool? hasConflict,
    List<String>? conflictTypes,
  }) {
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
      lecturerEmail: lecturerEmail,
      lecturerProfileId: lecturerProfileId,
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
      importStatus: importStatus ?? this.importStatus,
      isOfficial: isOfficial ?? this.isOfficial,
      hasConflict: hasConflict ?? this.hasConflict,
      conflictTypes: conflictTypes ?? this.conflictTypes,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class TimetableUploadRecord {
  const TimetableUploadRecord({
    required this.uploadId,
    required this.fileName,
    required this.academicSessionId,
    required this.uploadedBy,
    required this.uploadedByName,
    required this.uploadedAt,
    required this.status,
    this.savedAs,
    required this.totalRows,
    required this.successRows,
    required this.skippedRows,
    required this.duplicateRows,
    required this.errorRows,
    required this.warningRows,
    this.conflictRows = 0,
    this.roomConflicts = 0,
    this.lecturerConflicts = 0,
    this.classConflicts = 0,
    required this.validationErrors,
    required this.validationWarnings,
  });

  final String uploadId;
  final String fileName;
  final String academicSessionId;
  final String uploadedBy;
  final String uploadedByName;
  final String uploadedAt;
  final String status;
  final String? savedAs;
  final int totalRows;
  final int successRows;
  final int skippedRows;
  final int duplicateRows;
  final int errorRows;
  final int warningRows;
  final int conflictRows;
  final int roomConflicts;
  final int lecturerConflicts;
  final int classConflicts;
  final List<String> validationErrors;
  final List<String> validationWarnings;
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
    this.updatedBy,
    this.updatedByName,
    this.editReason,
    this.originalStatus,
    this.newStatus,
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
  final String? updatedBy;
  final String? updatedByName;
  final String? editReason;
  final AttendanceStatus? originalStatus;
  final AttendanceStatus? newStatus;

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
    String? updatedBy,
    String? updatedByName,
    String? editReason,
    AttendanceStatus? originalStatus,
    AttendanceStatus? newStatus,
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
      updatedBy: updatedBy ?? this.updatedBy,
      updatedByName: updatedByName ?? this.updatedByName,
      editReason: editReason ?? this.editReason,
      originalStatus: originalStatus ?? this.originalStatus,
      newStatus: newStatus ?? this.newStatus,
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
    this.reviewedByName,
    this.reviewerRole,
    this.reviewerNotes,
    this.actionTakenAt,
    this.actionTakenBy,
    this.actionTakenByName,
    this.actionTaken,
    this.actionTakenNote,
    this.rejectionReason,
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
  final String? reviewedByName;
  final String? reviewerRole;
  final String? reviewerNotes;
  final String? actionTakenAt;
  final String? actionTakenBy;
  final String? actionTakenByName;
  final String? actionTaken;
  final String? actionTakenNote;
  final String? rejectionReason;
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
    String? reviewedByName,
    String? reviewerRole,
    String? reviewerNotes,
    String? actionTakenAt,
    String? actionTakenBy,
    String? actionTakenByName,
    String? actionTaken,
    String? actionTakenNote,
    String? rejectionReason,
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
      reviewedByName: reviewedByName ?? this.reviewedByName,
      reviewerRole: reviewerRole ?? this.reviewerRole,
      reviewerNotes: reviewerNotes ?? this.reviewerNotes,
      actionTakenAt: actionTakenAt ?? this.actionTakenAt,
      actionTakenBy: actionTakenBy ?? this.actionTakenBy,
      actionTakenByName: actionTakenByName ?? this.actionTakenByName,
      actionTaken: actionTaken ?? this.actionTaken,
      actionTakenNote: actionTakenNote ?? this.actionTakenNote,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      closedAt: closedAt ?? this.closedAt,
    );
  }
}

class BookingRequest {
  const BookingRequest({
    required this.id,
    required this.lecturerId,
    required this.lecturerName,
    this.programId,
    this.departmentId,
    required this.subject,
    required this.section,
    required this.originalDate,
    required this.originalTime,
    required this.replacementDate,
    required this.replacementStart,
    required this.replacementEnd,
    this.roomId,
    this.roomName,
    required this.room,
    required this.reason,
    required this.remarks,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.reviewedBy,
    this.reviewedByName,
    this.reviewedAt,
    this.rejectionReason,
  });

  final String id;
  final String lecturerId;
  final String lecturerName;
  final String? programId;
  final String? departmentId;
  final String subject;
  final String section;
  final String originalDate;
  final String originalTime;
  final String replacementDate;
  final String replacementStart;
  final String replacementEnd;
  final String? roomId;
  final String? roomName;
  final String room;
  final String reason;
  final String remarks;
  final String status;
  final String? createdAt;
  final String? updatedAt;
  final String? reviewedBy;
  final String? reviewedByName;
  final String? reviewedAt;
  final String? rejectionReason;

  BookingRequest copyWith({
    String? status,
    String? reviewedBy,
    String? reviewedByName,
    String? reviewedAt,
    String? rejectionReason,
  }) {
    return BookingRequest(
      id: id,
      lecturerId: lecturerId,
      lecturerName: lecturerName,
      programId: programId,
      departmentId: departmentId,
      subject: subject,
      section: section,
      originalDate: originalDate,
      originalTime: originalTime,
      replacementDate: replacementDate,
      replacementStart: replacementStart,
      replacementEnd: replacementEnd,
      roomId: roomId,
      roomName: roomName,
      room: room,
      reason: reason,
      remarks: remarks,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedByName: reviewedByName ?? this.reviewedByName,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
