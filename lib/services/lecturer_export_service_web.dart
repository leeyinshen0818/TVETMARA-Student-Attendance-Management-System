// lib/services/lecturer_export_service_web.dart
//
// Web-only implementation.
// Uses dart:html to trigger browser downloads — no extra pub packages needed.
//
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import '../services/lecturer_timetable_service.dart';
import 'lecturer_export_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Day ordering helper
// ─────────────────────────────────────────────────────────────────────────────

const _dayOrder = {
  'ISNIN': 0,
  'SELASA': 1,
  'RABU': 2,
  'KHAMIS': 3,
  'JUMAAT': 4,
};

int _dayIndex(String day) => _dayOrder[day.toUpperCase().trim()] ?? 99;

// ─────────────────────────────────────────────────────────────────────────────
// HTML export — opens a print-ready page in a new browser tab
// ─────────────────────────────────────────────────────────────────────────────

Future<void> exportLecturerTimetableAsHtml({
  required List<LecturerSlot> slots,
  required LecturerExportMeta meta,
}) async {
  final sorted = List<LecturerSlot>.from(slots)
    ..sort((a, b) {
      final dc = _dayIndex(a.day).compareTo(_dayIndex(b.day));
      if (dc != 0) return dc;
      return a.startTime.compareTo(b.startTime);
    });

  final rows = sorted.asMap().entries.map((e) {
    final i = e.key + 1;
    final s = e.value;
    return '''
      <tr class="${i.isEven ? 'even' : 'odd'}">
        <td class="center">$i</td>
        <td class="center">${_esc(s.day)}</td>
        <td class="center">${_esc(s.startTime)} – ${_esc(s.endTime)}</td>
        <td><span class="code">${_esc(s.subjectCode)}</span></td>
        <td>${_esc(s.subjectName)}</td>
        <td class="center">${_esc(s.section)}</td>
        <td class="center">${_esc(s.programId)}</td>
        <td class="center">${_esc(s.roomId.isNotEmpty ? s.roomId : '–')}</td>
      </tr>''';
  }).join('\n');

  final html0 = '''<!DOCTYPE html>
<html lang="ms">
<head>
  <meta charset="UTF-8"/>
  <title>Jadual Waktu – ${_esc(meta.lecturerName)}</title>
  <style>
    @page { size: A4 landscape; margin: 18mm 14mm; }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: "Segoe UI", Arial, sans-serif; font-size: 11px;
           color: #1a2e3f; background: #fff; }

    /* ── Header banner ─────────────────────────────────────────── */
    .banner { background: #0d1b2a; color: #fff; padding: 14px 20px 10px; }
    .banner h1 { font-size: 16px; font-weight: 800; letter-spacing: .3px; }
    .banner h2 { font-size: 11px; font-weight: 600; color: #7ba7bc;
                 margin-top: 3px; letter-spacing: .4px; }

    /* ── Meta grid ──────────────────────────────────────────────── */
    .meta { display: grid; grid-template-columns: 1fr 1fr; gap: 0;
            border: 1px solid #c8d4dd; border-top: none; }
    .meta-cell { padding: 7px 14px; border-bottom: 1px solid #e2e8ef; }
    .meta-cell:nth-child(odd) { border-right: 1px solid #e2e8ef; }
    .meta-label { font-size: 9px; font-weight: 700; color: #5c7a8a;
                  letter-spacing: .4px; text-transform: uppercase; }
    .meta-value { font-size: 11.5px; font-weight: 600; margin-top: 2px; }

    /* ── Table ──────────────────────────────────────────────────── */
    .tbl-wrap { margin-top: 18px; border: 1px solid #c8d4dd;
                border-radius: 4px; overflow: hidden; }
    table { width: 100%; border-collapse: collapse; }
    thead tr { background: #f5f0e8; }
    thead th { padding: 9px 10px; font-size: 9.5px; font-weight: 700;
               color: #6b5e3e; text-transform: uppercase; letter-spacing: .3px;
               text-align: left; border-bottom: 1.5px solid #c8d4dd; }
    thead th.center, tbody td.center { text-align: center; }
    tbody tr.odd  { background: #fff; }
    tbody tr.even { background: #f9fbfc; }
    tbody tr:last-child td { border-bottom: none; }
    tbody td { padding: 8px 10px; border-bottom: 1px solid #e8eef3;
               font-size: 10.5px; vertical-align: middle; }
    .code { display: inline-block; background: #d6f0f7; color: #0d6e87;
            font-weight: 800; font-size: 10px; padding: 2px 6px;
            border-radius: 4px; letter-spacing: .2px; }

    /* ── Footer ─────────────────────────────────────────────────── */
    .footer { margin-top: 14px; font-size: 9px; color: #8aa2b0;
              display: flex; justify-content: space-between; }
    .footer strong { color: #5c7a8a; }

    /* ── Print overrides ─────────────────────────────────────────── */
    @media print {
      body { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
      .banner { -webkit-print-color-adjust: exact; }
      thead tr { -webkit-print-color-adjust: exact; }
    }
  </style>
</head>
<body>
  <div class="banner">
    <h1>JADUAL WAKTU PENSYARAH &mdash; SESI ${_esc(meta.academicSession)}</h1>
    <h2>SISTEM KEHADIRAN PELAJAR &bull; TVETMARA</h2>
  </div>

  <div class="meta">
    <div class="meta-cell">
      <div class="meta-label">Nama Pensyarah</div>
      <div class="meta-value">${_esc(meta.lecturerName)}</div>
    </div>
    <div class="meta-cell">
      <div class="meta-label">Emel</div>
      <div class="meta-value">${_esc(meta.lecturerEmail)}</div>
    </div>
    <div class="meta-cell">
      <div class="meta-label">Sesi Akademik</div>
      <div class="meta-value">${_esc(meta.academicSession)}</div>
    </div>
    <div class="meta-cell">
      <div class="meta-label">Tarikh Jana</div>
      <div class="meta-value">${_esc(meta.formattedDate)}</div>
    </div>
  </div>

  <div class="tbl-wrap">
    <table>
      <thead>
        <tr>
          <th class="center" style="width:36px">Bil.</th>
          <th class="center" style="width:72px">Hari</th>
          <th class="center" style="width:120px">Masa</th>
          <th style="width:90px">Kod Kursus</th>
          <th>Nama Kursus</th>
          <th class="center" style="width:80px">Seksyen</th>
          <th class="center" style="width:72px">Program</th>
          <th class="center" style="width:80px">Bilik</th>
        </tr>
      </thead>
      <tbody>
$rows
      </tbody>
    </table>
  </div>

  <div class="footer">
    <span>Jana oleh: <strong>${_esc(meta.lecturerName)}</strong> &bull; ${_esc(meta.formattedDate)}</span>
    <span>Jumlah Slot: <strong>${slots.length}</strong> &bull; SULIT – UNTUK KEGUNAAN DALAMAN SAHAJA</span>
  </div>

  <script>
    // Auto-trigger print dialog so the user can save as PDF immediately.
    window.onload = function() { window.print(); };
  </script>
</body>
</html>''';

  final blob = html.Blob([html0], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  // Revoke after a short delay so the new tab has time to load the blob URL.
  Future.delayed(const Duration(seconds: 5), () {
    html.Url.revokeObjectUrl(url);
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// CSV export — triggers a direct file download
// ─────────────────────────────────────────────────────────────────────────────

Future<void> exportLecturerTimetableAsCsv({
  required List<LecturerSlot> slots,
  required LecturerExportMeta meta,
}) async {
  final sorted = List<LecturerSlot>.from(slots)
    ..sort((a, b) {
      final dc = _dayIndex(a.day).compareTo(_dayIndex(b.day));
      if (dc != 0) return dc;
      return a.startTime.compareTo(b.startTime);
    });

  final buf = StringBuffer();
  // --- Document header block ---
  buf.writeln('JADUAL WAKTU PENSYARAH');
  buf.writeln('Sesi Akademik,${_csvVal(meta.academicSession)}');
  buf.writeln('Nama Pensyarah,${_csvVal(meta.lecturerName)}');
  buf.writeln('Emel,${_csvVal(meta.lecturerEmail)}');
  buf.writeln('Tarikh Jana,${_csvVal(meta.formattedDate)}');
  buf.writeln();

  // --- Column header ---
  buf.writeln('Bil.,Hari,Masa Mula,Masa Tamat,Kod Kursus,Nama Kursus,Seksyen,Program,Bilik,Jenis Kelas');

  // --- Data rows ---
  for (var i = 0; i < sorted.length; i++) {
    final s = sorted[i];
    buf.writeln([
      '${i + 1}',
      _csvVal(s.day),
      _csvVal(s.startTime),
      _csvVal(s.endTime),
      _csvVal(s.subjectCode),
      _csvVal(s.subjectName),
      _csvVal(s.section),
      _csvVal(s.programId),
      _csvVal(s.roomId.isNotEmpty ? s.roomId : '-'),
      _csvVal(s.classType.isNotEmpty ? s.classType : 'Normal Class'),
    ].join(','));
  }

  // --- Filename: jadual_<name>_<date>.csv ---
  final safeName = meta.lecturerName.replaceAll(RegExp(r'[^\w]'), '_');
  final d = meta.generatedAt;
  final dateStr =
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
  final filename = 'jadual_${safeName}_$dateStr.csv';

  final blob = html.Blob(['\uFEFF${buf.toString()}'], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none'
    ..click();
  html.Url.revokeObjectUrl(url);
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// HTML-escape a string for safe embedding in HTML attributes/text.
String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

/// Wrap a CSV field in quotes if it contains commas, quotes, or newlines.
String _csvVal(String s) {
  if (s.contains(',') || s.contains('"') || s.contains('\n')) {
    return '"${s.replaceAll('"', '""')}"';
  }
  return s;
}