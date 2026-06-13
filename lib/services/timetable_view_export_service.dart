import '../models/app_models.dart';

List<TimetableSlot> filterClassTimetableSlots(
  Iterable<TimetableSlot> slots, {
  required String programId,
  required String classId,
  required String? academicSessionId,
}) {
  return slots
      .where((slot) =>
          (slot.programId ?? '') == programId &&
          (slot.classId ?? slot.section) == classId &&
          (academicSessionId == null ||
              academicSessionId.isEmpty ||
              (slot.academicSessionId ?? slot.session) == academicSessionId))
      .toList()
    ..sort(_slotSorter);
}

String buildClassTimetableCsv({
  required String programId,
  required String programName,
  required String classId,
  required String academicSessionId,
  required String generatedBy,
  required DateTime generatedAt,
  required List<TimetableSlot> slots,
}) {
  final rows = <List<String>>[
    ['JADUAL WAKTU KELAS'],
    ['Program', '$programId - $programName'],
    ['Kelas', classId],
    ['Sesi Akademik', academicSessionId],
    ['Dijana Oleh', generatedBy],
    ['Tarikh Jana', generatedAt.toIso8601String()],
    [],
    [
      'Masa',
      'Hari',
      'Kod Kursus',
      'Nama Kursus',
      'Pensyarah',
      'Bilik',
      'Minggu',
      'Jenis Slot',
      'Status',
    ],
    ...slots.map((slot) => [
          '${slot.startTime}-${slot.endTime}',
          _normalDay(slot.dayOfWeek ?? slot.day),
          slot.subjectCode,
          slot.subjectName,
          slot.lecturerName,
          slot.roomName ?? slot.room,
          '${slot.weekStart ?? '1'}-${slot.weekEnd ?? '18'}',
          slot.slotType,
          slot.status,
        ]),
  ];
  return rowsToCsv(rows);
}

String rowsToCsv(List<List<String>> rows) {
  return rows.map((row) => row.map(_escapeCsvCell).join(',')).join('\n');
}

String _escapeCsvCell(String value) {
  final escaped = value.replaceAll('"', '""');
  return '"$escaped"';
}

int _slotSorter(TimetableSlot a, TimetableSlot b) {
  final day = _dayOrder(_normalDay(a.dayOfWeek ?? a.day))
      .compareTo(_dayOrder(_normalDay(b.dayOfWeek ?? b.day)));
  if (day != 0) return day;
  final time = a.startTime.compareTo(b.startTime);
  if (time != 0) return time;
  return (a.classId ?? a.section).compareTo(b.classId ?? b.section);
}

String _normalDay(String value) {
  final upper = value.trim().toUpperCase();
  return switch (upper) {
    'MONDAY' || 'ISNIN' => 'Isnin',
    'TUESDAY' || 'SELASA' => 'Selasa',
    'WEDNESDAY' || 'RABU' => 'Rabu',
    'THURSDAY' || 'KHAMIS' => 'Khamis',
    'FRIDAY' || 'JUMAAT' => 'Jumaat',
    'SATURDAY' || 'SABTU' => 'Sabtu',
    'SUNDAY' || 'AHAD' => 'Ahad',
    _ => value,
  };
}

int _dayOrder(String day) {
  return switch (day) {
    'Isnin' => 1,
    'Selasa' => 2,
    'Rabu' => 3,
    'Khamis' => 4,
    'Jumaat' => 5,
    'Sabtu' => 6,
    'Ahad' => 7,
    _ => 99,
  };
}
