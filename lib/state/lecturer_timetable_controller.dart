// lib/state/lecturer_timetable_controller.dart
//
// Controller / ViewModel for LecturerTimetableGridScreen.
// Holds the selected week and exposes the slot lookup helpers.
// Uses plain ChangeNotifier + InheritedWidget — no extra package needed.

import 'package:flutter/material.dart';
import '../services/lecturer_timetable_service.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Ordered list of days shown as grid rows (Malay names, uppercase).
const List<String> kTimetableDays = [
  'ISNIN',
  'SELASA',
  'RABU',
  'KHAMIS',
  'JUMAAT',
];

/// Human-readable labels for each day column header.
const Map<String, String> kDayLabels = {
  'ISNIN': 'Isnin\n(Mon)',
  'SELASA': 'Selasa\n(Tue)',
  'RABU': 'Rabu\n(Wed)',
  'KHAMIS': 'Khamis\n(Thu)',
  'JUMAAT': 'Jumaat\n(Fri)',
};

/// Total number of academic weeks.
const int kTotalWeeks = 18;

// ---------------------------------------------------------------------------
// InheritedWidget — makes the controller accessible to child widgets
// ---------------------------------------------------------------------------

class LecturerTimetableScope extends InheritedWidget {
  const LecturerTimetableScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final LecturerTimetableController controller;

  static LecturerTimetableController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<LecturerTimetableScope>();
    assert(scope != null, 'No LecturerTimetableScope found in context');
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(LecturerTimetableScope old) =>
      controller != old.controller;
}

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

class LecturerTimetableController extends ChangeNotifier {
  LecturerTimetableController({required LecturerTimetableService service})
      : _service = service;

  final LecturerTimetableService _service;

  int _selectedWeek = 1; // 1-based (M1 … M18)
  int get selectedWeek => _selectedWeek;

  void selectWeek(int week) {
    assert(week >= 1 && week <= kTotalWeeks);
    if (_selectedWeek == week) return;
    _selectedWeek = week;
    notifyListeners();
  }

  /// Returns a live stream of slots.
  ///
  Stream<List<LecturerSlot>> slotsStream({
    required String lecturerId,
    required String lecturerEmail,
    String? lecturerProfileId,
  }) =>
      _service.watchSlots(
        lecturerId: lecturerId,
        lecturerEmail: lecturerEmail,
        lecturerProfileId: lecturerProfileId,
      );

  /// Builds a fast lookup map: day → (startTime → LecturerSlot).
  ///
  /// The grid is keyed by startTime string (e.g. "08:00") instead of an
  /// integer period, since the Firestore documents store startTime/endTime
  /// rather than a period number.  The UI derives the column order from the
  /// sorted set of all distinct startTimes across all slots.
  Map<String, Map<String, LecturerSlot>> buildGrid(List<LecturerSlot> slots) {
    final Map<String, Map<String, LecturerSlot>> grid = {
      for (final d in kTimetableDays) d: {},
    };
    for (final slot in slots) {
      if (grid.containsKey(slot.day)) {
        grid[slot.day]![slot.startTime] = slot;
      }
    }
    return grid;
  }

  /// Returns all distinct startTime strings, sorted chronologically.
  /// Used to build the dynamic column headers in the grid.
  List<String> extractTimeCols(List<LecturerSlot> slots) {
    final times = slots.map((s) => s.startTime).toSet().toList();
    times.sort(); // "08:00" < "10:00" etc. — lexicographic == chronological
    return times;
  }
}
