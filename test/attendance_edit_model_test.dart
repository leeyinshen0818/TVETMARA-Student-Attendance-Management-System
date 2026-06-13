import 'package:flutter_test/flutter_test.dart';
import 'package:tvetmara_student_attendance/models/app_models.dart';

void main() {
  test('MC and CK remain excluded from attendance percentage denominator', () {
    var summary =
        const AttendanceSummary(present: 0, late: 0, absent: 0, mc: 0, ck: 0);
    for (final status in const [
      AttendanceStatus.present,
      AttendanceStatus.absent,
      AttendanceStatus.mc,
      AttendanceStatus.ck,
    ]) {
      summary = summary.add(status);
    }

    expect(summary.denominator, 2);
    expect(summary.percentage, 50);
  });

  test('AttendanceSession preserves edit audit history in copyWith', () {
    const session = AttendanceSession(
      id: 'slot-a_2026-06-13_W1',
      slotId: 'slot-a',
      sessionDate: '2026-06-13',
      weekNo: 1,
      academicSession: 'JAN-JUN 2026',
      semester: 1,
      programId: 'DED',
      programName: 'Diploma Elektrik',
      section: 'DED 1A',
      subjectCode: 'EEE101',
      subjectName: 'Electrical Basics',
      lecturerId: 'lecturer046',
      lecturerName: 'Syarifah',
      status: 'submitted',
      totalStudents: 1,
      presentCount: 1,
      lateCount: 0,
      absentCount: 0,
      mcCount: 0,
      ckCount: 0,
      attendancePercentage: 100,
      duplicateKey: 'slot-a|2026-06-13|1',
      createdBy: 'lecturer046',
    );
    const edit = AttendanceEditEntry(
      editedAt: '2026-06-13T14:00:00.000',
      editedBy: 'lecturer046',
      editedByName: 'Syarifah',
      reason: 'Pelajar menghantar MC selepas kelas.',
      changes: [
        AttendanceEditChange(
          studentId: 'S001',
          studentName: 'Ali',
          originalStatus: AttendanceStatus.absent,
          newStatus: AttendanceStatus.mc,
        ),
      ],
    );

    final updated = session.copyWith(
      updatedBy: 'lecturer046',
      updatedByName: 'Syarifah',
      editReason: edit.reason,
      editHistory: const [edit],
      absentCount: 0,
      mcCount: 1,
      attendancePercentage: 100,
    );

    expect(updated.editReason, edit.reason);
    expect(updated.editHistory, hasLength(1));
    expect(updated.editHistory.single.changes.single.originalStatus,
        AttendanceStatus.absent);
    expect(updated.editHistory.single.changes.single.newStatus,
        AttendanceStatus.mc);
  });
}
