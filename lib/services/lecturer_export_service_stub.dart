// lib/services/lecturer_export_service_stub.dart
//
// Non-web stub — PDF export is unsupported on native platforms in this version.
// Replace with a pdf/printing implementation for Android/iOS/Desktop when needed.

import '../services/lecturer_timetable_service.dart';
import 'lecturer_export_service.dart';

Future<void> exportLecturerTimetableAsPdf({
  required List<LecturerSlot> slots,
  required LecturerExportMeta meta,
}) async {
  throw UnsupportedError(
    'Eksport PDF jadual hanya disokong pada platform web buat masa ini.',
  );
}
