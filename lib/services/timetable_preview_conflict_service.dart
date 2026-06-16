import '../models/app_models.dart';
import '../models/timetable_import_result.dart';
import '../models/timetable_master_validation_result.dart';
import '../models/timetable_preview_conflict.dart';

class TimetablePreviewConflictService {
  const TimetablePreviewConflictService();

  TimetablePreviewConflictSummary detect({
    required TimetableMasterValidationResult preview,
    required List<TimetableSlot> existingSlots,
  }) {
    if (preview.validationErrors.isNotEmpty || preview.errorRows > 0) {
      return const TimetablePreviewConflictSummary.empty();
    }

    final previewSlots = preview.previewRows
        .where((row) =>
            row.slotDraft != null &&
            (row.status == TimetableImportRowStatus.valid ||
                row.status == TimetableImportRowStatus.warning))
        .map(TimetablePreviewConflictSlot.fromPreviewRow)
        .where(_isConflictRelevant)
        .toList();
    final officialSlots = existingSlots
        .where((slot) => _isConflictRelevant(
              TimetablePreviewConflictSlot.fromExistingSlot(slot),
            ))
        .where(_isOfficialExistingSlot)
        .map(TimetablePreviewConflictSlot.fromExistingSlot)
        .toList();

    final conflicts = <TimetablePreviewConflict>[];
    final seen = <String>{};

    for (var i = 0; i < previewSlots.length; i++) {
      for (var j = i + 1; j < previewSlots.length; j++) {
        _addConflicts(conflicts, seen, previewSlots[i], previewSlots[j]);
      }
    }

    for (final previewSlot in previewSlots) {
      for (final existingSlot in officialSlots) {
        _addConflicts(conflicts, seen, previewSlot, existingSlot);
      }
    }

    return TimetablePreviewConflictSummary(
      conflicts: List.unmodifiable(conflicts),
    );
  }

  bool _isOfficialExistingSlot(TimetableSlot slot) {
    final importStatus = slot.importStatus?.toLowerCase();
    if (slot.isOfficial == false || importStatus == 'conflict_pending') {
      return false;
    }
    return true;
  }

  bool _isConflictRelevant(TimetablePreviewConflictSlot slot) {
    final status = slot.status.toLowerCase();
    return status != 'inactive' &&
        status != 'cancelled' &&
        status != 'canceled' &&
        status != 'draft';
  }

  void _addConflicts(
    List<TimetablePreviewConflict> conflicts,
    Set<String> seen,
    TimetablePreviewConflictSlot a,
    TimetablePreviewConflictSlot b,
  ) {
    if (!_sameWindow(a, b)) return;
    _addConflictIfSame(conflicts, seen, 'room', a.roomKey, a, b);
    _addConflictIfSame(conflicts, seen, 'lecturer', a.lecturerKey, a, b);
    _addConflictIfSame(conflicts, seen, 'class', a.classId, a, b);
  }

  void _addConflictIfSame(
    List<TimetablePreviewConflict> conflicts,
    Set<String> seen,
    String type,
    String target,
    TimetablePreviewConflictSlot a,
    TimetablePreviewConflictSlot b,
  ) {
    final valueA = switch (type) {
      'room' => a.roomKey,
      'lecturer' => a.lecturerKey,
      'class' => a.classId,
      _ => target,
    };
    final valueB = switch (type) {
      'room' => b.roomKey,
      'lecturer' => b.lecturerKey,
      'class' => b.classId,
      _ => target,
    };
    if (valueA.trim().isEmpty || valueA != valueB) return;

    final key = [
      type,
      valueA,
      a.previewRowNumber ?? a.existingSlotId,
      b.previewRowNumber ?? b.existingSlotId,
    ].join('|');
    if (!seen.add(key)) return;

    conflicts.add(
      TimetablePreviewConflict(
        type: type,
        target: _targetLabel(type, a, b),
        dayOfWeek: a.dayOfWeek,
        startTime: _minTime(a.startTime, b.startTime),
        endTime: _maxTime(a.endTime, b.endTime),
        weekStart: a.weekStart < b.weekStart ? a.weekStart : b.weekStart,
        weekEnd: a.weekEnd > b.weekEnd ? a.weekEnd : b.weekEnd,
        previewRowNumbers: [
          if (a.previewRowNumber != null) a.previewRowNumber!,
          if (b.previewRowNumber != null) b.previewRowNumber!,
        ],
        existingSlotIds: [
          if (a.existingSlotId != null) a.existingSlotId!,
          if (b.existingSlotId != null) b.existingSlotId!,
        ],
        subjectSummary: '${a.subjectCode} / ${b.subjectCode}',
        classSummary: '${a.classId} / ${b.classId}',
        lecturerSummary: '${a.lecturerName} / ${b.lecturerName}',
        roomSummary: '${a.roomName} / ${b.roomName}',
      ),
    );
  }

  String _targetLabel(
    String type,
    TimetablePreviewConflictSlot a,
    TimetablePreviewConflictSlot b,
  ) {
    return switch (type) {
      'room' => a.roomName.isNotEmpty ? a.roomName : a.roomKey,
      'lecturer' => a.lecturerName.isNotEmpty ? a.lecturerName : b.lecturerName,
      'class' => a.classId,
      _ => '-',
    };
  }

  bool _sameWindow(
    TimetablePreviewConflictSlot a,
    TimetablePreviewConflictSlot b,
  ) {
    if (a.academicSessionId != b.academicSessionId ||
        a.dayOfWeek != b.dayOfWeek) {
      return false;
    }
    final startA = _minutes(a.startTime);
    final endA = _minutes(a.endTime);
    final startB = _minutes(b.startTime);
    final endB = _minutes(b.endTime);
    if (startA == null || endA == null || startB == null || endB == null) {
      return false;
    }
    return startA < endB &&
        startB < endA &&
        a.weekStart <= b.weekEnd &&
        b.weekStart <= a.weekEnd;
  }

  String _minTime(String a, String b) {
    final minutesA = _minutes(a) ?? 0;
    final minutesB = _minutes(b) ?? 0;
    return minutesA <= minutesB ? a : b;
  }

  String _maxTime(String a, String b) {
    final minutesA = _minutes(a) ?? 0;
    final minutesB = _minutes(b) ?? 0;
    return minutesA >= minutesB ? a : b;
  }

  int? _minutes(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return (hour * 60) + minute;
  }
}
