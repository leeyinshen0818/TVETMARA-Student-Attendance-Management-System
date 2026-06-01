import '../models/app_models.dart';
import '../data/mock_data.dart' as mock;
import '../services/user_timetable_service.dart';

enum TimetableSlotViewMode { weekly, list }

class TimetableSlotsController {
  TimetableSlotsController({
    required this.currentUser,
    UserTimetableService? timetableService,
  }) : service = timetableService ?? UserTimetableService();

  final AppUser currentUser;
  final UserTimetableService service;

  TimetableSlotViewMode viewMode = TimetableSlotViewMode.weekly;
  String searchQuery = '';
  String? selectedAcademicSession;
  String? selectedProgramId;
  String? selectedClassId;
  String? selectedLecturerId;
  String? selectedDayOfWeek;
  String? selectedSubject;
  String? selectedRoomId;

  Stream<List<TimetableSlot>> get slotsStream {
    if (currentUser.role == UserRole.pentadbir) {
      return Stream.value(mock.timetable);
    }

    return service.getFilteredTimetableStream(currentUser);
  }

  bool get hideLecturerFilter => currentUser.role == UserRole.pensyarah;
  bool get hideProgramFilter =>
      currentUser.role == UserRole.ketua_program ||
      currentUser.role == UserRole.pensyarah;

  void resetFilters() {
    selectedAcademicSession = null;
    selectedProgramId = null;
    selectedClassId = null;
    selectedLecturerId = null;
    selectedDayOfWeek = null;
    selectedSubject = null;
    selectedRoomId = null;
    searchQuery = '';
  }

  List<TimetableSlot> filterSlots(List<TimetableSlot> slots) {
    final query = searchQuery.trim().toLowerCase();
    return slots.where((slot) {
      if (selectedAcademicSession != null && selectedAcademicSession!.isNotEmpty) {
        final sessionValue = (slot.academicSessionId ?? slot.session).toLowerCase();
        if (sessionValue != selectedAcademicSession!.toLowerCase()) {
          return false;
        }
      }

      if (selectedProgramId != null && selectedProgramId!.isNotEmpty) {
        final programId = (slot.programId ?? slot.program).toLowerCase();
        if (programId != selectedProgramId!.toLowerCase()) {
          return false;
        }
      }

      if (selectedClassId != null && selectedClassId!.isNotEmpty) {
        final classId = (slot.classId ?? slot.section).toLowerCase();
        if (classId != selectedClassId!.toLowerCase()) {
          return false;
        }
      }

      if (!hideLecturerFilter &&
          selectedLecturerId != null &&
          selectedLecturerId!.isNotEmpty) {
        if (slot.lecturerId.toLowerCase() != selectedLecturerId!.toLowerCase()) {
          return false;
        }
      }

      if (selectedDayOfWeek != null && selectedDayOfWeek!.isNotEmpty) {
        final normalized = _canonicalDay(slot.dayOfWeek ?? slot.day);
        if (normalized.toLowerCase() != selectedDayOfWeek!.toLowerCase()) {
          return false;
        }
      }

      if (selectedSubject != null && selectedSubject!.isNotEmpty) {
        final subjectCode = slot.subjectCode.toLowerCase();
        final subjectName = slot.subjectName.toLowerCase();
        if (subjectCode != selectedSubject!.toLowerCase() &&
            subjectName != selectedSubject!.toLowerCase()) {
          return false;
        }
      }

      if (selectedRoomId != null && selectedRoomId!.isNotEmpty) {
        final roomId = (slot.roomId ?? slot.roomName ?? slot.room).toLowerCase();
        if (roomId != selectedRoomId!.toLowerCase()) {
          return false;
        }
      }

      if (query.isNotEmpty) {
        final haystack = <String>[
          slot.subjectCode,
          slot.subjectName,
          slot.lecturerName,
          slot.roomName ?? slot.room,
          slot.room,
          slot.program,
          slot.programId ?? '',
          slot.classId ?? slot.section,
          slot.section,
          slot.dayOfWeek ?? slot.day,
          slot.status,
        ].join(' ').toLowerCase();
        if (!haystack.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  List<String> academicSessionOptions(List<TimetableSlot> slots) {
    return uniqueValues(slots
        .map((slot) => slot.academicSessionId ?? slot.session)
        .where((value) => value.isNotEmpty)
        .cast<String>());
  }

  List<String> programmeOptions(List<TimetableSlot> slots) {
    return uniqueValues(slots
        .map((slot) => slot.programId ?? slot.program)
        .where((value) => value.isNotEmpty)
        .cast<String>());
  }

  List<String> classOptions(List<TimetableSlot> slots) {
    return uniqueValues(slots
        .map((slot) => slot.classId ?? slot.section)
        .where((value) => value.isNotEmpty)
        .cast<String>());
  }

  List<String> lecturerOptions(List<TimetableSlot> slots) {
    return uniqueValues(slots
        .map((slot) => slot.lecturerId.isNotEmpty
            ? '${slot.lecturerId}::${slot.lecturerName}'
            : null)
        .where((value) => value != null && value.isNotEmpty)
        .cast<String>())
      .map((composite) => composite.split('::').first)
      .toList();
  }

  List<String> subjectOptions(List<TimetableSlot> slots) {
    return uniqueValues(slots
        .map((slot) => slot.subjectCode.isNotEmpty
            ? slot.subjectCode
            : slot.subjectName)
        .where((value) => value.isNotEmpty)
        .cast<String>());
  }

  List<String> roomOptions(List<TimetableSlot> slots) {
    return uniqueValues(slots
        .map((slot) => slot.roomId ?? slot.roomName ?? slot.room)
        .where((value) => value.isNotEmpty)
        .cast<String>());
  }

  List<String> dayOfWeekOptions(List<TimetableSlot> slots) {
    return uniqueValues(slots
        .map((slot) => _canonicalDay(slot.dayOfWeek ?? slot.day))
        .where((value) => value.isNotEmpty)
        .cast<String>())
      .where((value) => _weekdayOrder.contains(value))
      .toList();
  }

  List<TimetableSlot> sortByStartTime(List<TimetableSlot> slots) {
    final items = [...slots];
    items.sort((a, b) => a.startTime.compareTo(b.startTime));
    return items;
  }

  String normalizedDayLabel(String dayOfWeek) {
    final normalized = canonicalDay(dayOfWeek);
    return _dayLabels[normalized] ?? dayOfWeek;
  }

  String canonicalDay(String? value) {
    return _canonicalDay(value);
  }

  String _canonicalDay(String? value) {
    if (value == null || value.isEmpty) return '';
    final key = value.trim().toLowerCase();
    if (_dayEquivalents.containsKey(key)) {
      return _dayEquivalents[key]!;
    }
    return value;
  }

  List<String> uniqueValues(Iterable<String> values) {
    final set = <String>{};
    for (final value in values) {
      final normalized = value.trim();
      if (normalized.isNotEmpty) {
        set.add(normalized);
      }
    }
    return set.toList()..sort();
  }

  static const Map<String, String> _dayEquivalents = {
    'monday': 'Monday',
    'tuesday': 'Tuesday',
    'wednesday': 'Wednesday',
    'thursday': 'Thursday',
    'friday': 'Friday',
    'saturday': 'Saturday',
    'sunday': 'Sunday',
    'isnin': 'Monday',
    'selasa': 'Tuesday',
    'rabu': 'Wednesday',
    'khamis': 'Thursday',
    'jumaat': 'Friday',
    'sabtu': 'Saturday',
    'ahad': 'Sunday',
  };

  static const Map<String, String> _dayLabels = {
    'Monday': 'Isnin',
    'Tuesday': 'Selasa',
    'Wednesday': 'Rabu',
    'Thursday': 'Khamis',
    'Friday': 'Jumaat',
    'Saturday': 'Sabtu',
    'Sunday': 'Ahad',
  };

  static const List<String> _weekdayOrder = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];
}
