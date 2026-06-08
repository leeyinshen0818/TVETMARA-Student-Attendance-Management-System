import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tvetmara_student_attendance/models/app_models.dart';
import 'package:tvetmara_student_attendance/services/reports_pdf_export_service.dart';

void main() {
  const service = ReportsPdfExportService();

  CriticalAttendancePdfReport buildReport({
    List<CriticalAttendanceReportRow>? rows,
  }) {
    return CriticalAttendancePdfReport(
      academicSessionId: 'JAN_JUN_2026',
      generatedAt: DateTime(2026, 5, 19, 9, 30),
      generatedBy: 'KJ Elektrik',
      scopeLabel: 'Elektrik (DED/DCP/DCB)',
      threshold: 80,
      totalStudents: 35,
      averageAttendance: 76,
      completedSessions: 12,
      rows: rows ??
          [
            const CriticalAttendanceReportRow(
              student: Student(
                id: 'DED001',
                name: 'Pelajar DED 001',
                email: 'ded001@student.tvetmara.edu.my',
                phone: '0100000001',
                program: 'DED',
                semester: 1,
                section: 'DED 1A',
                attendance: 74,
              ),
              summary: AttendanceSummary(
                present: 8,
                late: 1,
                absent: 3,
                mc: 1,
                ck: 0,
              ),
            ),
          ],
    );
  }

  test('builds non-empty critical attendance PDF bytes', () async {
    final bytes = await service.buildCriticalAttendancePdf(buildReport());

    expect(bytes, isNotEmpty);
    expect(ascii.decode(bytes.take(4).toList()), '%PDF');
  });

  test('PDF includes report metadata and row content in uncompressed bytes',
      () async {
    final bytes = await service.buildCriticalAttendancePdf(buildReport());
    final content = latin1.decode(bytes, allowInvalid: true);

    expect(content, contains('Laporan Kehadiran Kritikal Mingguan'));
    expect(content, contains('JAN_JUN_2026'));
    expect(content, contains('DED001'));
    expect(content, contains('Pelajar'));
  });

  test('empty critical report still generates a PDF', () async {
    final bytes = await service.buildCriticalAttendancePdf(
      buildReport(rows: const []),
    );
    final content = latin1.decode(bytes, allowInvalid: true);

    expect(bytes, isNotEmpty);
    expect(content, contains('Tiada'));
    expect(content, contains('kehadiran'));
  });

  test('uses stable report filename for academic session', () {
    expect(
      service.fileNameFor('JAN_JUN_2026'),
      'laporan_kehadiran_kritikal_JAN_JUN_2026.pdf',
    );
  });
}
