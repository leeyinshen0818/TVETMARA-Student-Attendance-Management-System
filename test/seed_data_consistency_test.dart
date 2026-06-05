import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tvetmara_student_attendance/data/mock_data.dart' as mock;
import 'package:tvetmara_student_attendance/models/app_models.dart';
import 'package:tvetmara_student_attendance/services/timetable_import_service.dart';

String _roomId(String roomName) => roomName.replaceAll(RegExp(r'[/\\.]'), '_');

int _minutes(String value) {
  final parts = value.split(':');
  if (parts.length != 2) return -1;
  return (int.tryParse(parts.first) ?? -1) * 60 +
      (int.tryParse(parts.last) ?? -1);
}

String _programFromClass(String classId) {
  return classId.trim().split(RegExp(r'\s+')).first;
}

AttendanceSummary _summaryFor(List<AttendanceRecord> records) {
  var summary =
      const AttendanceSummary(present: 0, late: 0, absent: 0, mc: 0, ck: 0);
  for (final record in records) {
    summary = summary.add(record.status);
  }
  return summary;
}

void main() {
  setUpAll(mock.initializeMockData);

  test('real lecturer seed excludes workbook heading artifacts', () {
    const invalidNames = {
      'SEM',
      'SEM 1',
      'SEM 2',
      'SEMESTER 1',
      'SEMESTER 2',
    };
    final userNames = mock.realLecturerUsers
        .map((user) => user.name.trim().toUpperCase())
        .toSet();
    final lecturerNames = mock.lecturers
        .map((lecturer) => lecturer.name.trim().toUpperCase())
        .toSet();
    final assignmentNames = mock.lecturerCourseAssignmentsForSeed
        .map((assignment) => assignment.lecturerName.trim().toUpperCase())
        .toSet();

    for (final invalid in invalidNames) {
      expect(userNames, isNot(contains(invalid)));
      expect(lecturerNames, isNot(contains(invalid)));
      expect(assignmentNames, isNot(contains(invalid)));
    }
  });

  test('lecturer emails are unique and demo login accounts are preserved', () {
    final emails = mock.users.map((user) => user.email).toList();
    expect(emails.toSet().length, emails.length);
    expect(emails, contains('pensyarah_ded@tvetmara.edu.my'));
    expect(emails, contains('pensyarah_dcp@tvetmara.edu.my'));
    expect(emails, contains('pensyarah_dcb@tvetmara.edu.my'));
    expect(emails, contains('pensyarah_dgs@tvetmara.edu.my'));

    final dedDemo = mock.users.singleWhere(
      (user) => user.email == 'pensyarah_ded@tvetmara.edu.my',
    );
    final dgsDemo = mock.users.singleWhere(
      (user) => user.email == 'pensyarah_dgs@tvetmara.edu.my',
    );
    expect(dedDemo.uid, 'L_DED');
    expect(dedDemo.name, mock.demoLecturerDedName);
    expect(dgsDemo.uid, 'L_DGS');
    expect(dgsDemo.name, mock.demoLecturerDgsName);
    expect(dedDemo.name, 'Pensyarah DED (Demo)');
    expect(dgsDemo.name, 'Pensyarah DGS (Demo)');

    final syarifah = mock.users.singleWhere(
      (user) => user.email == 'lecturer046@tvetmara.edu.my',
    );
    final zabhin = mock.users.singleWhere(
      (user) => user.email == 'lecturer001@tvetmara.edu.my',
    );
    expect(syarifah.name, 'SYARIFAH BINTI ABDUL RAHIM');
    expect(syarifah.lecturerProfileId, 'REAL_L_046');
    expect(zabhin.name, 'Zabhin bin Mohd Arbai');
    expect(zabhin.lecturerProfileId, 'REAL_L_001');
  });

  test('timetable seed keeps normalized master-data links consistent', () {
    final programs = {for (final program in mock.programs) program.id: program};
    final sessions = mock.academicSessions
        .map((session) => session.academicSessionId)
        .toSet();
    final classes = {for (final item in mock.demoClasses) item.classId: item};
    final rooms = {
      for (final room in mock.roomResources) room.name,
      for (final room in mock.roomResources) _roomId(room.name),
    };
    final users = {for (final user in mock.users) user.uid};
    final lecturers = {for (final lecturer in mock.lecturers) lecturer.id};
    final validDays = {
      'Isnin',
      'Selasa',
      'Rabu',
      'Khamis',
      'Jumaat',
      'Sabtu',
      'Ahad',
    };

    for (final slot in mock.timetable) {
      final programId = slot.programId ?? slot.program;
      final classId = slot.classId ?? slot.section;
      expect(programs, contains(programId), reason: slot.id);
      expect(sessions, contains(slot.academicSessionId ?? slot.session),
          reason: slot.id);
      expect(classes, contains(classId), reason: slot.id);
      expect(classes[classId]!.programId, programId, reason: slot.id);
      expect(slot.departmentId, programs[programId]!.departmentId,
          reason: slot.id);
      expect(rooms, contains(slot.roomId ?? slot.room), reason: slot.id);
      expect(slot.lecturerName.trim(), isNotEmpty, reason: slot.id);
      expect(
          users.contains(slot.lecturerId) ||
              lecturers.contains(slot.lecturerId),
          isTrue,
          reason: slot.id);
      expect(validDays, contains(slot.dayOfWeek ?? slot.day), reason: slot.id);
      expect(_minutes(slot.startTime), greaterThanOrEqualTo(0),
          reason: slot.id);
      expect(_minutes(slot.endTime), greaterThan(_minutes(slot.startTime)),
          reason: slot.id);
      expect(int.tryParse(slot.weekStart ?? ''), isNotNull, reason: slot.id);
      expect(int.tryParse(slot.weekEnd ?? ''), isNotNull, reason: slot.id);
      expect(int.parse(slot.weekStart!),
          lessThanOrEqualTo(int.parse(slot.weekEnd!)),
          reason: slot.id);
    }
  });

  test('timetable subjects match the slot programme or are marked demo', () {
    final subjectKeys = mock.subjectsForSeed
        .map((subject) => '${subject.programId}|${subject.subjectCode}')
        .toSet();

    for (final slot in mock.timetable) {
      final programId = slot.programId ?? slot.program;
      final key = '$programId|${slot.subjectCode}';
      final isDemoSubject = slot.subjectId?.contains('_DEMO') ?? false;
      expect(subjectKeys.contains(key) || isDemoSubject, isTrue,
          reason: '${slot.id} uses $key');
    }
  });

  test('generic demo lecturers do not teach unrelated programmes accidentally',
      () {
    for (final slot in mock.timetable) {
      if (!slot.lecturerName.startsWith('Pensyarah ')) continue;
      final match =
          RegExp(r'^Pensyarah\s+([A-Z0-9]+)').firstMatch(slot.lecturerName);
      final lecturerProgram = match?.group(1);
      final slotProgram = slot.programId ?? slot.program;
      final isIntentionalConflict =
          slot.sourceUploadId == 'seed_conflict_demo' &&
              slot.slotType.contains('Intentional Demo Conflict');

      expect(lecturerProgram == slotProgram || isIntentionalConflict, isTrue,
          reason:
              '${slot.id}: ${slot.lecturerName} should not teach $slotProgram');
    }
  });

  test('discipline seed uses normalized status values and valid links', () {
    const allowedStatuses = {
      'pending',
      'reviewed',
      'action_taken',
      'closed',
      'rejected',
    };
    final students = {for (final student in mock.students) student.id: student};
    final programs = {for (final program in mock.programs) program.id: program};
    final users = {for (final user in mock.users) user.uid};

    for (final report in mock.disciplineReports) {
      expect(allowedStatuses, contains(report.status), reason: report.id);
      expect(students, contains(report.studentId), reason: report.id);
      expect(report.studentName, students[report.studentId]!.name,
          reason: report.id);
      expect(report.section, students[report.studentId]!.section,
          reason: report.id);
      final programId = _programFromClass(report.section);
      expect(report.programId, programId, reason: report.id);
      expect(report.departmentId, programs[programId]!.departmentId,
          reason: report.id);
      expect(users, contains(report.createdBy), reason: report.id);
    }
  });

  test('booking seed has valid requester, room, programme, class, and status',
      () {
    const allowedStatuses = {'Pending', 'Approved', 'Rejected'};
    final users = {for (final user in mock.users) user.uid: user};
    final programs = {for (final program in mock.programs) program.id: program};
    final classes = {for (final item in mock.demoClasses) item.classId: item};
    final rooms = {
      for (final room in mock.roomResources) room.name,
      for (final room in mock.roomResources) _roomId(room.name),
    };

    for (final booking in mock.bookings) {
      expect(users, contains(booking.lecturerId), reason: booking.id);
      expect(booking.lecturerName, users[booking.lecturerId]!.name,
          reason: booking.id);
      expect(programs, contains(booking.programId), reason: booking.id);
      expect(booking.departmentId, programs[booking.programId]!.departmentId,
          reason: booking.id);
      expect(classes, contains(booking.section), reason: booking.id);
      expect(classes[booking.section]!.programId, booking.programId,
          reason: booking.id);
      expect(rooms, contains(booking.roomId), reason: booking.id);
      expect(allowedStatuses, contains(booking.status), reason: booking.id);
      expect(_minutes(booking.replacementEnd),
          greaterThan(_minutes(booking.replacementStart)),
          reason: booking.id);
      if (booking.status == 'Approved' || booking.status == 'Rejected') {
        expect(booking.updatedAt, isNotNull, reason: booking.id);
      }
    }
  });

  test('attendance seed summaries match records and valid timetable/students',
      () {
    final slotIds = mock.timetable.map((slot) => slot.id).toSet();
    final students = {for (final student in mock.students) student.id: student};

    for (final slot in mock.timetable) {
      for (final bundle in mock.attendanceBundlesForSlot(slot)) {
        expect(slotIds, contains(bundle.session.slotId),
            reason: bundle.session.id);
        final seenStudentIds = <String>{};
        for (final record in bundle.records) {
          expect(students, contains(record.studentId),
              reason: bundle.session.id);
          expect(seenStudentIds.add(record.studentId), isTrue,
              reason: bundle.session.id);
          expect(students[record.studentId]!.section, bundle.session.section,
              reason: bundle.session.id);
        }

        final summary = _summaryFor(bundle.records);
        expect(bundle.session.presentCount, summary.present,
            reason: bundle.session.id);
        expect(bundle.session.lateCount, summary.late,
            reason: bundle.session.id);
        expect(bundle.session.absentCount, summary.absent,
            reason: bundle.session.id);
        expect(bundle.session.mcCount, summary.mc, reason: bundle.session.id);
        expect(bundle.session.ckCount, summary.ck, reason: bundle.session.id);
        expect(bundle.session.attendancePercentage, summary.percentage,
            reason: bundle.session.id);
      }
    }
  });

  test('clean no-conflict timetable CSV parses and has no core conflicts', () {
    final file = File('demo_data/clean_no_conflict_timetable_JAN_JUN_2026.csv');
    expect(file.existsSync(), isTrue);
    final result = const TimetableImportService()
        .parseAndValidate(file.readAsStringSync());
    expect(result.validationErrors, isEmpty);
    expect(result.errorRows, 0);
    expect(result.duplicateRows, 0);
    expect(result.parsedRows.length, greaterThanOrEqualTo(30));

    final lecturerEmails = mock.users.map((user) => user.email).toSet();
    final rooms = {
      for (final room in mock.roomResources)
        room.name.replaceAll(RegExp(r'[/\\.]'), '_'),
    };
    final classes = mock.demoClasses.map((item) => item.classId).toSet();
    final conflictKeys = <String>{};
    for (final row in result.parsedRows) {
      final draft = row.draft!;
      expect(lecturerEmails, contains(draft.lecturerEmail));
      expect(rooms, contains(draft.roomId));
      expect(classes, contains(draft.classId));
      final scheduleKey = [
        draft.academicSessionId,
        draft.dayOfWeek,
        draft.startTime,
        draft.endTime,
        draft.weekStart,
        draft.weekEnd,
      ].join('|');
      expect(conflictKeys.add('room|$scheduleKey|${draft.roomId}'), isTrue);
      expect(conflictKeys.add('lecturer|$scheduleKey|${draft.lecturerEmail}'),
          isTrue);
      expect(conflictKeys.add('class|$scheduleKey|${draft.classId}'), isTrue);
    }
  });
}
