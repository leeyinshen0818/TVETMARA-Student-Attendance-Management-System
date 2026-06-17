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