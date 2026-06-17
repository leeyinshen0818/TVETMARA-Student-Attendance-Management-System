// lib/services/lecturer_export_service_web.dart
//
// Web-only export implementation.
// Produces a silent PDF download using html2pdf.js (CDN) inside a hidden
// off-screen iframe — no new tab, no print dialog, no CSV.
//
// Pipeline:
//   1. Build a self-contained A4-landscape HTML string (styled, sorted).
//   2. Inject html2pdf.js from cdnjs CDN into the <head>.
//   3. Append an invisible <iframe> to document.body.
//   4. Write the HTML into the iframe's srcdoc.
//   5. html2pdf runs inside the iframe on window.onload, silently saves the PDF.
//   6. After a safe delay the iframe is removed from the DOM.
//
// SCOPE: caller passes only pre-filtered slots already matched to the
// logged-in lecturer. No Firestore query happens here.
//
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import '../services/lecturer_timetable_service.dart';
import 'lecturer_export_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Day ordering helpers
// ─────────────────────────────────────────────────────────────────────────────

const _kDayOrder = {
  'ISNIN': 0,
  'MONDAY': 0,
  'SELASA': 1,
  'TUESDAY': 1,
  'RABU': 2,
  'WEDNESDAY': 2,
  'KHAMIS': 3,
  'THURSDAY': 3,
  'JUMAAT': 4,
  'FRIDAY': 4,
  'SABTU': 5,
  'SATURDAY': 5,
  'AHAD': 6,
  'SUNDAY': 6,
};

int _dayIndex(String day) => _kDayOrder[day.toUpperCase().trim()] ?? 99;

String _normalDay(String v) => switch (v.trim().toUpperCase()) {
      'MONDAY' || 'ISNIN' => 'Isnin',
      'TUESDAY' || 'SELASA' => 'Selasa',
      'WEDNESDAY' || 'RABU' => 'Rabu',
      'THURSDAY' || 'KHAMIS' => 'Khamis',
      'FRIDAY' || 'JUMAAT' => 'Jumaat',
      'SATURDAY' || 'SABTU' => 'Sabtu',
      'SUNDAY' || 'AHAD' => 'Ahad',
      _ => v,
    };

// ─────────────────────────────────────────────────────────────────────────────
// PDF export — silent download via hidden iframe + html2pdf.js
// ─────────────────────────────────────────────────────────────────────────────

Future<void> exportLecturerTimetableAsPdf({
  required List<LecturerSlot> slots,
  required LecturerExportMeta meta,
}) async {
  // ── 1. Sort slots by day → start time ────────────────────────────────────
  final sorted = List<LecturerSlot>.from(slots)
    ..sort((a, b) {
      final dc = _dayIndex(a.day).compareTo(_dayIndex(b.day));
      if (dc != 0) return dc;
      return a.startTime.compareTo(b.startTime);
    });

  // ── 2. Build table rows ───────────────────────────────────────────────────
  final rows = sorted.asMap().entries.map((e) {
    final i = e.key + 1;
    final s = e.value;
    return '''
      <tr class="${i.isEven ? 'even' : 'odd'}">
        <td class="ctr">$i</td>
        <td class="ctr">${_esc(_normalDay(s.day))}</td>
        <td class="ctr">${_esc(s.startTime)} – ${_esc(s.endTime)}</td>
        <td><span class="code">${_esc(s.subjectCode)}</span></td>
        <td>${_esc(s.subjectName)}</td>
        <td class="ctr">${_esc(s.section)}</td>
        <td class="ctr">${_esc(s.programId)}</td>
        <td class="ctr">${_esc(s.roomId.isNotEmpty ? s.roomId : '–')}</td>
        <td class="ctr">${_esc(s.classType.isNotEmpty ? s.classType : 'Normal Class')}</td>
      </tr>''';
  }).join('\n');

  // ── 3. Safe PDF filename ──────────────────────────────────────────────────
  final safeName = meta.lecturerName.replaceAll(RegExp(r'[^\w]'), '_');
  final d = meta.generatedAt;
  final ds = '${d.year}${_p(d.month)}${_p(d.day)}';
  final pdfFilename = 'jadual_${safeName}_$ds.pdf';

  // ── 4. Build the full HTML payload ───────────────────────────────────────
  //
  //  • html2pdf.js loaded from cdnjs CDN — no backend, no build step.
  //  • window.print() is intentionally ABSENT.
  //  • html2pdf() runs silently on window.onload, saves the PDF, then
  //    posts a message to the parent so the iframe can be removed.
  //
  final htmlPayload = '''<!DOCTYPE html>
<html lang="ms">
<head>
  <meta charset="UTF-8"/>
  <title>Jadual Waktu – ${_esc(meta.lecturerName)}</title>

  <!-- html2pdf.js — client-side HTML→PDF, no server needed -->
  <script src="https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js"></script>

  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: "Segoe UI", Arial, sans-serif; font-size: 11px;
           color: #1a2e3f; background: #fff; padding: 0; margin: 0; }

    /* ── Banner ──────────────────────────────────────────────── */
    .banner { background: #0d1b2a; color: #fff; padding: 13px 18px 10px; }
    .banner h1 { font-size: 15px; font-weight: 800; letter-spacing: .3px; }
    .banner h2 { font-size: 10px; font-weight: 600; color: #7ba7bc;
                 margin-top: 3px; letter-spacing: .5px; }

    /* ── Meta grid ───────────────────────────────────────────── */
    .meta { display: grid; grid-template-columns: 1fr 1fr;
            border: 1px solid #c8d4dd; border-top: none; }
    .mc  { padding: 6px 14px; border-bottom: 1px solid #e2e8ef; }
    .mc:nth-child(odd) { border-right: 1px solid #e2e8ef; }
    .ml  { font-size: 8.5px; font-weight: 700; color: #5c7a8a;
           letter-spacing: .4px; text-transform: uppercase; }
    .mv  { font-size: 11px; font-weight: 600; margin-top: 2px; }

    /* ── Table ───────────────────────────────────────────────── */
    .tw  { margin-top: 16px; border: 1px solid #c8d4dd;
           border-radius: 4px; overflow: hidden; }
    table { width: 100%; border-collapse: collapse; }
    thead tr { background: #f5f0e8; }
    thead th { padding: 8px 9px; font-size: 9px; font-weight: 700;
               color: #6b5e3e; text-transform: uppercase;
               letter-spacing: .3px; text-align: left;
               border-bottom: 1.5px solid #c8d4dd; }
    thead th.ctr, tbody td.ctr { text-align: center; }
    tbody tr.odd  { background: #fff; }
    tbody tr.even { background: #f9fbfc; }
    tbody tr:last-child td { border-bottom: none; }
    tbody td { padding: 7px 9px; border-bottom: 1px solid #e8eef3;
               font-size: 10px; vertical-align: middle; }
    .code { display: inline-block; background: #d6f0f7; color: #0d6e87;
            font-weight: 800; font-size: 9.5px; padding: 2px 5px;
            border-radius: 4px; letter-spacing: .2px; }

    /* ── Footer ──────────────────────────────────────────────── */
    .foot { margin-top: 12px; font-size: 8.5px; color: #8aa2b0;
            display: flex; justify-content: space-between; }
    .foot strong { color: #5c7a8a; }
  </style>
</head>
<body>
  <div class="banner">
    <h1>JADUAL WAKTU PENSYARAH &mdash; SESI ${_esc(meta.academicSession)}</h1>
    <h2>SISTEM KEHADIRAN PELAJAR &bull; TVETMARA</h2>
  </div>

  <div class="meta">
    <div class="mc">
      <div class="ml">Nama Pensyarah</div>
      <div class="mv">${_esc(meta.lecturerName)}</div>
    </div>
    <div class="mc">
      <div class="ml">Emel</div>
      <div class="mv">${_esc(meta.lecturerEmail)}</div>
    </div>
    <div class="mc">
      <div class="ml">Sesi Akademik</div>
      <div class="mv">${_esc(meta.academicSession)}</div>
    </div>
    <div class="mc">
      <div class="ml">Tarikh Jana</div>
      <div class="mv">${_esc(meta.formattedDate)}</div>
    </div>
  </div>

  <div class="tw">
    <table>
      <thead>
        <tr>
          <th class="ctr" style="width:34px">Bil.</th>
          <th class="ctr" style="width:68px">Hari</th>
          <th class="ctr" style="width:110px">Masa</th>
          <th style="width:86px">Kod Kursus</th>
          <th>Nama Kursus</th>
          <th class="ctr" style="width:76px">Seksyen</th>
          <th class="ctr" style="width:68px">Program</th>
          <th class="ctr" style="width:76px">Bilik</th>
          <th class="ctr" style="width:88px">Jenis</th>
        </tr>
      </thead>
      <tbody>
$rows
      </tbody>
    </table>
  </div>

  <div class="foot">
    <span>Jana oleh: <strong>${_esc(meta.lecturerName)}</strong>
          &bull; ${_esc(meta.formattedDate)}</span>
    <span>Jumlah Slot: <strong>${sorted.length}</strong>
          &bull; SULIT – UNTUK KEGUNAAN DALAMAN SAHAJA</span>
  </div>

  <script>
    // Silent PDF generation — no print dialog, no new tab.
    // html2pdf.js renders document.body into a PDF and triggers a direct
    // browser download. On completion the parent window is notified so the
    // hosting iframe can be cleaned up.
    window.onload = function() {
      var element = document.body;
      var opt = {
        margin:      [10, 10, 10, 10],
        filename:    '$pdfFilename',
        image:       { type: 'jpeg', quality: 0.98 },
        html2canvas: { scale: 2, useCORS: true },
        jsPDF:       { unit: 'mm', format: 'a4', orientation: 'landscape' }
      };
      html2pdf()
        .set(opt)
        .from(element)
        .save()
        .then(function() {
          // Notify parent to remove the iframe after download is triggered.
          if (window.parent && window.parent !== window) {
            window.parent.postMessage('pdf-done', '*');
          }
        });
    };
  </script>
</body>
</html>''';

  // ── 5. Mount an invisible off-screen iframe ───────────────────────────────
  final iframe = html.IFrameElement()
    ..style.position = 'fixed'
    ..style.top = '-9999px'
    ..style.left = '-9999px'
    ..style.width = '1px'
    ..style.height = '1px'
    ..style.opacity = '0'
    ..style.border = 'none'
    ..style.pointerEvents = 'none'
    ..setAttribute(
        'sandbox', 'allow-scripts allow-same-origin allow-downloads');

  html.document.body!.append(iframe);

  // ── 6. Write the payload into the iframe ─────────────────────────────────
  //
  // srcdoc is the safest way to inject HTML — avoids navigation and keeps
  // the iframe's origin aligned with the parent for postMessage.
  iframe.srcdoc = htmlPayload;

  // ── 7. Listen for completion and clean up ─────────────────────────────────
  //
  // html2pdf posts 'pdf-done' when .save() resolves. We also set a hard
  // 30-second safety timeout so the iframe is never left dangling if the
  // CDN script fails to load (e.g. offline).
  final completer = _IframeCompleter();

  final sub = html.window.onMessage.listen((event) {
    if (event.data == 'pdf-done') {
      completer.complete();
    }
  });

  // Safety timeout — remove iframe even if postMessage never fires.
  Future.delayed(const Duration(seconds: 30), () {
    if (!completer.isCompleted) completer.complete();
  });

  await completer.future;

  sub.cancel();
  iframe.remove();
}

// ─────────────────────────────────────────────────────────────────────────────
// Minimal completer wrapper — avoids importing dart:async explicitly
// ─────────────────────────────────────────────────────────────────────────────

class _IframeCompleter {
  _IframeCompleter() {
    _future = Future<void>(() async {
      while (!_done) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });
  }

  late final Future<void> _future;
  bool _done = false;
  bool get isCompleted => _done;

  Future<void> get future => _future;

  void complete() => _done = true;
}

// ─────────────────────────────────────────────────────────────────────────────
// HTML escape helper
// ─────────────────────────────────────────────────────────────────────────────

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

String _p(int n) => n.toString().padLeft(2, '0');
