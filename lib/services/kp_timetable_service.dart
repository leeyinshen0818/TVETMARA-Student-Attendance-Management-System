import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_models.dart'; // Verified mapping against app_models.dart

class KpTimetableService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AppUser currentKpOops; // Tied directly to the logged-in user profile

  int _selectedWeek = 1;
  String _selectedSection = 'All Classes';
  List<TimetableSlot> _allSlots = [];
  List<String> _availableSections = ['All Classes'];
  bool _isLoading = false;

  KpTimetableService({required this.currentKpOops}) {
    fetchTimetableSlots();
  }

  // Getters
  int get selectedWeek => _selectedWeek;
  String get selectedSection => _selectedSection;
  List<String> get availableSections => _availableSections;
  bool get isLoading => _isLoading;

  // Setters that trigger UI updates
  void changeWeek(int week) {
    _selectedWeek = week;
    notifyListeners();
  }

  void changeSection(String section) {
    _selectedSection = section;
    notifyListeners();
  }

  /// Read-only Query targeting /timetable_slots/ collection scoped to KP's program
  Future<void> fetchTimetableSlots() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Constraint: Filter where programId matches the KP and session equals 'JAN_JUN_2026'
      final querySnapshot = await _firestore
          .collection('timetable_slots')
          .where('programId', isEqualTo: currentKpOops.programId)
          .where('session', isEqualTo: 'JAN_JUN_2026')
          .get();

      _allSlots = querySnapshot.docs.map((doc) {
        final data = doc.data();

        // Accurate factory mapping matching your complete TimetableSlot property structure
        return TimetableSlot(
          id: doc.id,
          timetableSlotId: doc.id,
          academicSessionId: data['academicSessionId'] as String?,
          programId: data['programId'] as String?,
          departmentId: data['departmentId'] as String?,
          classId: data['classId'] as String?,
          subjectId: data['subjectId'] as String?,
          session: data['session'] as String? ?? 'JAN_JUN_2026',
          semester: (data['semester'] as num? ?? 1).toInt(),
          program: data['program'] as String? ?? '',
          section: data['section'] as String? ?? '',
          subjectCode: data['subjectCode'] as String? ??
              data['courseCode'] as String? ??
              '',
          subjectName: data['subjectName'] as String? ??
              data['courseName'] as String? ??
              '',
          lecturerId: data['lecturerId'] as String? ?? '',
          lecturerName: data['lecturerName'] as String? ?? '',
          lecturerEmail: data['lecturerEmail'] as String?,
          lecturerProfileId: data['lecturerProfileId'] as String?,
          roomId: data['roomId'] as String?,
          roomName: data['roomName'] as String?,
          day: data['day'] as String? ?? 'ISNIN',
          date: data['date'] as String? ?? '',
          startTime: data['startTime'] as String? ?? '',
          endTime: data['endTime'] as String? ?? '',
          room: data['room'] as String? ?? data['roomId'] as String? ?? '',
          enrolled: (data['enrolled'] as num? ?? 0).toInt(),
          capacity: (data['capacity'] as num? ?? 0).toInt(),
          classType: data['classType'] as String? ?? 'Kuliah',
          slotType: data['slotType'] as String? ?? 'Regular',
          status: data['status'] as String? ?? 'Active',
          sourceUploadId: data['period']?.toString(),
        );
      }).toList();

      // Dynamically isolate available sections within the KP's program
      final sections = _allSlots.map((slot) => slot.section).toSet().toList();
      sections.sort();
      _availableSections = ['All Classes', ...sections];
    } catch (e) {
      debugPrint('Error retrieving consolidated program slots: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filters retrieved items locally by active academic Week, selected section, Day, and Period block
  List<TimetableSlot> getFilteredSlotsForCell(String day, int period) {
    return _allSlots.where((slot) {
      bool matchesWeek = true;
      if (slot.weekStart != null && slot.weekEnd != null) {
        int start = int.tryParse(slot.weekStart!) ?? 1;
        int end = int.tryParse(slot.weekEnd!) ?? 18;
        matchesWeek = _selectedWeek >= start && _selectedWeek <= end;
      }

      bool matchesSection =
          _selectedSection == 'All Classes' || slot.section == _selectedSection;
      bool matchesDay = slot.day.toUpperCase() == day.toUpperCase();

      bool matchesPeriod = false;
      if (slot.sourceUploadId != null) {
        matchesPeriod = int.tryParse(slot.sourceUploadId!) == period;
      } else {
        matchesPeriod = _determinePeriodByTime(slot.startTime) == period;
      }

      return matchesWeek && matchesSection && matchesDay && matchesPeriod;
    }).toList();
  }

  int _determinePeriodByTime(String startTime) {
    if (startTime.startsWith('08:00') || startTime.startsWith('8:00')) return 1;
    if (startTime.startsWith('09:00') || startTime.startsWith('9:00')) return 2;
    if (startTime.startsWith('10:00')) return 3;
    if (startTime.startsWith('11:00')) return 4;
    if (startTime.startsWith('12:00')) return 5;
    if (startTime.startsWith('14:00') || startTime.startsWith('2:00')) return 6;
    if (startTime.startsWith('15:00') || startTime.startsWith('3:00')) return 7;
    if (startTime.startsWith('16:00') || startTime.startsWith('4:00')) return 8;
    return 1;
  }
}
