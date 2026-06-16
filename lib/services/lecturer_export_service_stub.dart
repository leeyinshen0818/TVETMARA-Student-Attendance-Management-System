// lib/services/lecturer_export_service_stub.dart
//
// Non-web stub — export is unsupported on native platforms in this version.
// Replace with a pdf/excel implementation (e.g. printing or pdf packages) when
// targeting Android/iOS/Desktop.

import '../services/lecturer_timetable_service.dart';
import 'lecturer_export_service.dart';

Future<void> exportLecturerTimetableAsHtml({
  required List<LecturerSlot> slots,
  required LecturerExportMeta meta,
}) async {
  throw UnsupportedError(
    'Eksport jadual hanya disokong pada platform web buat masa ini.',
  );
}

Future<void> exportLecturerTimetableAsCsv({
  required List<LecturerSlot> slots,
  required LecturerExportMeta meta,
}) async {
  throw UnsupportedError(
    'Muat turun fail hanya disokong pada platform web buat masa ini.',
  );
}