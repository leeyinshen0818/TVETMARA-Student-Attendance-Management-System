// lib/services/lecturer_export_service.dart
//
// Phase 1 – Pensyarah "Jadual Saya" Styled Export
// Produces:
//   • CSV  – always available (pure Dart, no extra packages)
//   • HTML – rendered as a printable / saveable document (web only)
//
// SCOPE RULE: only slots already filtered to the logged-in lecturer are
// accepted as input.  No Firestore query is performed here; the caller
// (LecturerTimetableGridScreen) passes the already-scoped list.

export 'lecturer_export_service_stub.dart'
    if (dart.library.html) 'lecturer_export_service_web.dart';

// ─── Shared data class ────────────────────────────────────────────────────────

class LecturerExportMeta {
  const LecturerExportMeta({
    required this.lecturerName,
    required this.lecturerEmail,
    required this.academicSession,
    required this.generatedAt,
  });

  final String lecturerName;
  final String lecturerEmail;
  final String academicSession;
  final DateTime generatedAt;

  String get formattedDate {
    final d = generatedAt;
    const months = [
      'Jan',
      'Feb',
      'Mac',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ogo',
      'Sep',
      'Okt',
      'Nov',
      'Dis',
    ];
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year}, $hh:$mm';
  }
}
