import 'package:flutter_test/flutter_test.dart';
import 'package:tvetmara_student_attendance/models/app_models.dart';

void main() {
  test('DisciplineReport preserves optional review metadata in copyWith', () {
    const report = DisciplineReport(
      id: 'D_TEST',
      studentId: 'S001',
      studentName: 'Pelajar Demo',
      section: 'DED 1A',
      subject: 'Pemasangan Elektrik',
      lecturer: 'Pensyarah Demo',
      date: '2026-05-01',
      issueType: 'Ponteng Kelas',
      severity: 'High',
      description: 'Tidak hadir tanpa makluman.',
      followUp: false,
      status: 'pending',
    );

    final reviewed = report.copyWith(
      status: 'action_taken',
      reviewedBy: 'kj_elektrik',
      reviewedByName: 'Ketua Jabatan Elektrik',
      reviewerRole: 'ketua_jabatan',
      reviewerNotes: 'Semakan telah dibuat.',
      actionTaken: 'Kaunseling dan hubungi penjaga.',
      actionTakenNote: 'Kaunseling dan hubungi penjaga.',
      rejectionReason: 'Tidak berkaitan',
    );

    expect(reviewed.status, 'action_taken');
    expect(reviewed.reviewedBy, 'kj_elektrik');
    expect(reviewed.reviewedByName, 'Ketua Jabatan Elektrik');
    expect(reviewed.reviewerRole, 'ketua_jabatan');
    expect(reviewed.reviewerNotes, 'Semakan telah dibuat.');
    expect(reviewed.actionTaken, 'Kaunseling dan hubungi penjaga.');
    expect(reviewed.actionTakenNote, 'Kaunseling dan hubungi penjaga.');
    expect(reviewed.rejectionReason, 'Tidak berkaitan');
  });
}
