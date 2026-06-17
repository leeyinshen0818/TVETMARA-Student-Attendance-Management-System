import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/app_models.dart';

class CriticalAttendanceReportRow {
  const CriticalAttendanceReportRow({
    required this.student,
    required this.summary,
    this.programCode = '',
    this.disciplineCount = 0,
    this.isEligibleForPromotion = false,
  });

  final Student student;
  final AttendanceSummary summary;
  final String programCode;
  final int disciplineCount;
  final bool isEligibleForPromotion;
}

class CriticalAttendancePdfReport {
  const CriticalAttendancePdfReport({
    required this.academicSessionId,
    required this.generatedAt,
    required this.generatedBy,
    required this.scopeLabel,
    required this.threshold,
    required this.totalStudents,
    required this.averageAttendance,
    required this.completedSessions,
    required this.rows,
    this.selectedWeek,
    this.thresholdFilterLabel = '',
    this.groupFilterLabel = '',
    this.disciplineFilterLabel = '',
  });

  final String academicSessionId;
  final DateTime generatedAt;
  final String generatedBy;
  final String scopeLabel;
  final int threshold;
  final int totalStudents;
  final int averageAttendance;
  final int completedSessions;
  final List<CriticalAttendanceReportRow> rows;
  final int? selectedWeek;
  final String thresholdFilterLabel;
  final String groupFilterLabel;
  final String disciplineFilterLabel;
}

class ReportsPdfExportService {
  const ReportsPdfExportService();

  String fileNameFor(String academicSessionId, {int? selectedWeek}) {
    final safeSession = academicSessionId
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final prefix = selectedWeek == null
        ? 'laporan_kehadiran_keseluruhan'
        : 'laporan_kehadiran_kritikal';
    return '${prefix}_${safeSession.isEmpty ? 'sesi' : safeSession}.pdf';
  }

  Future<Uint8List> buildCriticalAttendancePdf(
    CriticalAttendancePdfReport report,
  ) async {
    final isAllWeeks = report.selectedWeek == null;
    final document = pw.Document(
      title: isAllWeeks
          ? 'Laporan Kehadiran Keseluruhan'
          : 'Laporan Kehadiran Kritikal Mingguan',
      author: report.generatedBy,
      subject: isAllWeeks
          ? 'Laporan kehadiran keseluruhan pelajar'
          : 'Laporan kehadiran pelajar bawah ${report.threshold}%',
      compress: false,
    );

    final rows = report.rows
        .map(
          (row) => [
            row.student.id,
            row.student.name,
            row.programCode.isEmpty ? row.student.program : row.programCode,
            row.student.section,
            '${row.summary.present}',
            '${row.summary.late}',
            '${row.summary.absent}',
            '${row.summary.mc}',
            '${row.summary.ck}',
            '${row.summary.percentage}%',
            '${row.disciplineCount}',
            if (isAllWeeks)
              row.isEligibleForPromotion ? 'Layak' : 'Tidak Layak',
          ],
        )
        .toList();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildHeader(report),
          pw.SizedBox(height: 14),
          _buildSummary(report),
          pw.SizedBox(height: 18),
          if (rows.isEmpty)
            _buildEmptyState()
          else
            _buildTable(rows, isAllWeeks: isAllWeeks),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _buildHeader(CriticalAttendancePdfReport report) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey900,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            report.selectedWeek == null
                ? 'Laporan Kehadiran Keseluruhan'
                : 'Laporan Kehadiran Kritikal Mingguan',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing: 18,
            runSpacing: 5,
            children: [
              _metadataText('Sesi', report.academicSessionId),
              _metadataText('Dijana', _formatDateTime(report.generatedAt)),
              _metadataText('Dijana oleh', report.generatedBy),
              _metadataText('Skop', report.scopeLabel),
              _metadataText('Had', 'Bawah ${report.threshold}%'),
              _metadataText(
                  'Minggu',
                  report.selectedWeek == null
                      ? 'Semua Minggu'
                      : 'Minggu ${report.selectedWeek}'),
              _metadataText('Status', report.thresholdFilterLabel),
              _metadataText('Program/Kelas', report.groupFilterLabel),
              _metadataText('Disiplin', report.disciplineFilterLabel),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummary(CriticalAttendancePdfReport report) {
    final items = [
      ('Jumlah Pelajar', '${report.totalStudents}'),
      ('Purata Kehadiran', '${report.averageAttendance}%'),
      ('Bawah Had', '${report.rows.length}'),
      ('Sesi Selesai', '${report.completedSessions}'),
    ];

    return pw.Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blueGrey100),
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    items[i].$1,
                    style: const pw.TextStyle(
                      color: PdfColors.blueGrey600,
                      fontSize: 8,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    items[i].$2,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _buildTable(List<List<String>> rows, {bool isAllWeeks = false}) {
    final headers = [
      'ID Pelajar',
      'Nama',
      'Program',
      'Kelas',
      'P',
      'L',
      'A',
      'MC',
      'CK',
      'Kehadiran %',
      'Disiplin',
      if (isAllWeeks) 'Naik Semester',
    ];
    final columnWidths = <int, pw.FlexColumnWidth>{
      0: const pw.FlexColumnWidth(1.1),
      1: const pw.FlexColumnWidth(2.4),
      2: const pw.FlexColumnWidth(0.6),
      3: const pw.FlexColumnWidth(0.8),
      4: const pw.FlexColumnWidth(0.45),
      5: const pw.FlexColumnWidth(0.45),
      6: const pw.FlexColumnWidth(0.45),
      7: const pw.FlexColumnWidth(0.55),
      8: const pw.FlexColumnWidth(0.55),
      9: const pw.FlexColumnWidth(0.9),
      10: const pw.FlexColumnWidth(0.6),
      if (isAllWeeks) 11: const pw.FlexColumnWidth(0.9),
    };
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      border: pw.TableBorder.all(color: PdfColors.blueGrey100, width: 0.5),
      columnWidths: columnWidths,
    );
  }

  pw.Widget _buildEmptyState() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        border: pw.Border.all(color: PdfColors.green200),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        'Tiada pelajar di bawah had kehadiran untuk skop ini.',
        style: pw.TextStyle(
          color: PdfColors.green900,
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Sistem Kehadiran TVETMARA',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.blueGrey500),
        ),
        pw.Text(
          'Halaman ${context.pageNumber} / ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.blueGrey500),
        ),
      ],
    );
  }

  pw.Widget _metadataText(String label, String value) {
    return pw.Text(
      '$label: $value',
      style: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
    );
  }

  String _formatDateTime(DateTime value) {
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    final day = twoDigits(value.day);
    final month = twoDigits(value.month);
    final hour = twoDigits(value.hour);
    final minute = twoDigits(value.minute);
    return '$day/$month/${value.year} $hour:$minute';
  }
}
