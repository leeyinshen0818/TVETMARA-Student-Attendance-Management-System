import 'app_models.dart';
import 'timetable_master_validation_result.dart';

class TimetablePreviewConflict {
  const TimetablePreviewConflict({
    required this.type,
    required this.target,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.weekStart,
    required this.weekEnd,
    required this.previewRowNumbers,
    required this.existingSlotIds,
    required this.subjectSummary,
    required this.classSummary,
    required this.lecturerSummary,
    required this.roomSummary,
  });

  final String type;
  final String target;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final int weekStart;
  final int weekEnd;
  final List<int> previewRowNumbers;
  final List<String> existingSlotIds;
  final String subjectSummary;
  final String classSummary;
  final String lecturerSummary;
  final String roomSummary;

  bool get involvesExistingSlot => existingSlotIds.isNotEmpty;
}

class TimetablePreviewConflictSummary {
  const TimetablePreviewConflictSummary({
    required this.conflicts,
  });

  const TimetablePreviewConflictSummary.empty() : conflicts = const [];

  final List<TimetablePreviewConflict> conflicts;

  int get total => conflicts.length;
  int get roomConflicts =>
      conflicts.where((conflict) => conflict.type == 'room').length;
  int get lecturerConflicts =>
      conflicts.where((conflict) => conflict.type == 'lecturer').length;
  int get classConflicts =>
      conflicts.where((conflict) => conflict.type == 'class').length;
  bool get hasConflicts => conflicts.isNotEmpty;

  List<String> get conflictTypes {
    final types = <String>{};
    if (roomConflicts > 0) types.add('room');
    if (lecturerConflicts > 0) types.add('lecturer');
    if (classConflicts > 0) types.add('class');
    return types.toList(growable: false);
  }
}

class TimetablePreviewConflictSlot {
  const TimetablePreviewConflictSlot({
    required this.previewRowNumber,
    required this.existingSlotId,
    required this.academicSessionId,
    required this.classId,
    required this.subjectCode,
    required this.subjectName,
    required this.lecturerKey,
    required this.lecturerName,
    required this.roomKey,
    required this.roomName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.weekStart,
    required this.weekEnd,
    required this.status,
  });

  factory TimetablePreviewConflictSlot.fromPreviewRow(
    TimetablePreviewRow row,
  ) {
    final draft = row.slotDraft!;
    return TimetablePreviewConflictSlot(
      previewRowNumber: row.rowNumber,
      existingSlotId: null,
      academicSessionId: draft.academicSessionId,
      classId: draft.classId,
      subjectCode: draft.subjectCode,
      subjectName: draft.subjectName,
      lecturerKey: draft.lecturerId.isNotEmpty
          ? draft.lecturerId
          : draft.lecturerEmail.toLowerCase(),
      lecturerName: draft.lecturerName,
      roomKey: draft.roomId,
      roomName: draft.roomName,
      dayOfWeek: draft.dayOfWeek,
      startTime: draft.startTime,
      endTime: draft.endTime,
      weekStart: draft.weekStart,
      weekEnd: draft.weekEnd,
      status: draft.status,
    );
  }

  factory TimetablePreviewConflictSlot.fromExistingSlot(TimetableSlot slot) {
    final weekStartText = slot.weekStart ?? slot.date;
    final weekStart = int.tryParse(weekStartText) ?? 1;
    return TimetablePreviewConflictSlot(
      previewRowNumber: null,
      existingSlotId: slot.timetableSlotId,
      academicSessionId: slot.academicSessionId ?? slot.session,
      classId: slot.classId ?? slot.section,
      subjectCode: slot.subjectCode,
      subjectName: slot.subjectName,
      lecturerKey: slot.lecturerId.isNotEmpty
          ? slot.lecturerId
          : (slot.lecturerEmail ?? '').toLowerCase(),
      lecturerName: slot.lecturerName,
      roomKey: slot.roomId ?? slot.room,
      roomName: slot.roomName ?? slot.room,
      dayOfWeek: slot.dayOfWeek ?? slot.day,
      startTime: slot.startTime,
      endTime: slot.endTime,
      weekStart: weekStart,
      weekEnd: int.tryParse(slot.weekEnd ?? slot.date) ?? weekStart,
      status: slot.status,
    );
  }

  final int? previewRowNumber;
  final String? existingSlotId;
  final String academicSessionId;
  final String classId;
  final String subjectCode;
  final String subjectName;
  final String lecturerKey;
  final String lecturerName;
  final String roomKey;
  final String roomName;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final int weekStart;
  final int weekEnd;
  final String status;

  bool get isPreview => previewRowNumber != null;
}
