import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/app_models.dart';

class DisciplineWarningLetterPdfService {
  const DisciplineWarningLetterPdfService();

  String fileNameFor(DisciplineReport report) {
    final safeStudentId = _safeFilePart(report.studentId);
    final safeReportId = _safeFilePart(report.id);
    return 'surat_amaran_${safeStudentId}_$safeReportId.pdf';
  }

  Future<Uint8List> buildWarningLetterPdf({
    required DisciplineReport report,
    required String generatedBy,
    required DateTime generatedAt,
  }) async {
    final document = pw.Document(
      title: 'Surat Amaran Disiplin',
      author: generatedBy,
      subject: 'Surat amaran untuk ${report.studentName}',
      compress: false,
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(48, 42, 48, 42),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Dijana melalui Sistem Kehadiran TVETMARA | Muka ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.blueGrey500,
            ),
          ),
        ),
        build: (context) => [
          _buildHeader(),
          pw.SizedBox(height: 28),
          _buildMeta(report, generatedAt),
          pw.SizedBox(height: 22),
          pw.Text(
            'SURAT AMARAN DISIPLIN PELAJAR',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 24),
          _paragraph('Kepada:'),
          pw.SizedBox(height: 6),
          pw.Text(
            report.studentName,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('No. Pelajar: ${_dash(report.studentId)}'),
          pw.Text(
              'Program/Kelas: ${_dash(report.programName ?? report.programId)} / ${_dash(report.section)}'),
          pw.SizedBox(height: 20),
          _paragraph('Dengan segala hormatnya perkara di atas adalah dirujuk.'),
          pw.SizedBox(height: 12),
          _paragraph(
            'Dimaklumkan bahawa satu laporan disiplin telah direkodkan terhadap pelajar seperti butiran berikut:',
          ),
          pw.SizedBox(height: 12),
          _buildDetailsTable(report),
          pw.SizedBox(height: 18),
          _paragraph(
            'Pihak pengurusan telah menyemak laporan ini dan tindakan berikut telah direkodkan:',
          ),
          pw.SizedBox(height: 10),
          _noticeBox(report.actionTaken ?? report.actionTakenNote ?? '-'),
          if ((report.reviewerNotes ?? '').trim().isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _paragraph('Catatan semakan:'),
            pw.SizedBox(height: 8),
            _noticeBox(report.reviewerNotes!),
          ],
          pw.SizedBox(height: 18),
          _paragraph(
            'Sehubungan itu, pelajar diminta mengambil serius teguran ini dan memastikan perkara yang sama tidak berulang. Kegagalan mematuhi arahan atau berulangnya kesalahan boleh menyebabkan tindakan lanjut mengikut peraturan institusi.',
          ),
          pw.SizedBox(height: 18),
          _paragraph('Sekian, terima kasih.'),
          pw.SizedBox(height: 30),
          _buildSignature(report, generatedBy),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _buildHeader() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey900,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'TVETMARA',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Sistem Kehadiran dan Pengurusan Pelajar',
            style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMeta(DisciplineReport report, DateTime generatedAt) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _metaText('Rujukan', report.id),
        ),
        pw.Expanded(
          child: _metaText('Tarikh Surat', _formatDate(generatedAt)),
        ),
      ],
    );
  }

  pw.Widget _buildDetailsTable(DisciplineReport report) {
    final rows = [
      ('Tarikh Laporan', report.createdAt ?? report.date),
      ('Jenis Kesalahan', report.issueType),
      ('Tahap', report.severity),
      (
        'Subjek/Kelas',
        report.subjectName ?? report.subjectCode ?? report.subject
      ),
      ('Dilapor Oleh', report.createdByName ?? report.lecturer),
      ('Keterangan', report.description),
      (
        'Disemak Oleh',
        report.reviewedByName ?? report.actionTakenByName ?? '-'
      ),
      ('Tarikh Tindakan', report.actionTakenAt ?? report.reviewedAt ?? '-'),
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.blueGrey100, width: 0.6),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.2),
        1: pw.FlexColumnWidth(2.8),
      },
      children: [
        for (final row in rows)
          pw.TableRow(
            children: [
              pw.Container(
                color: PdfColors.grey100,
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  row.$1,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  _dash(row.$2),
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
            ],
          ),
      ],
    );
  }

  pw.Widget _buildSignature(DisciplineReport report, String generatedBy) {
    final signer = report.actionTakenByName ??
        report.reviewedByName ??
        (generatedBy.trim().isEmpty ? '-' : generatedBy);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Yang menjalankan amanah,'),
        pw.SizedBox(height: 42),
        pw.Container(width: 180, height: 1, color: PdfColors.blueGrey400),
        pw.SizedBox(height: 6),
        pw.Text(
          signer,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(_roleLabel(report.reviewerRole)),
      ],
    );
  }

  pw.Widget _metaText(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.blueGrey500),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          _dash(value),
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  pw.Widget _noticeBox(String text) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber50,
        border: pw.Border.all(color: PdfColors.amber200),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: _paragraph(text),
    );
  }

  pw.Widget _paragraph(String text) {
    return pw.Text(
      text,
      textAlign: pw.TextAlign.justify,
      style: const pw.TextStyle(fontSize: 10.5, lineSpacing: 3),
    );
  }

  String _safeFilePart(String value) {
    final safe = value
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return safe.isEmpty ? 'rekod' : safe;
  }

  String _dash(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? '-' : trimmed;
  }

  String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  String _roleLabel(String? role) {
    return switch (role?.trim().toLowerCase()) {
      'ketua_jabatan' => 'Ketua Jabatan',
      'ketua_program' => 'Ketua Program',
      _ => 'Penyemak Disiplin',
    };
  }
}
