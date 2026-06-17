import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/timetable_template.dart';
import '../models/app_models.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AttendanceDemoSeedResult {
  const AttendanceDemoSeedResult({
    required this.sessionsCreated,
    required this.recordsCreated,
    required this.classesProcessed,
    required this.classesSkipped,
  });

  final int sessionsCreated;
  final int recordsCreated;
  final int classesProcessed;
  final int classesSkipped;
}

class AttendanceSessionAlreadyExistsException implements Exception {
  const AttendanceSessionAlreadyExistsException(this.session);

  final AttendanceSession session;
}

class AppState extends ChangeNotifier {
  AppUser? currentUser;
  List<AppUser> users = [];
  List<Student> students = [];
  List<Lecturer> lecturers = [];
  List<RoomResource> roomResources = [];
  List<TimetableSlot> timetable = [];
  List<TimetableUploadRecord> timetableUploads = [];
  List<AttendanceSession> attendanceSessions = [];
  List<DisciplineReport> disciplineReports = [];
  List<BookingRequest> bookings = [];
  List<Map<String, dynamic>> lecturerCourseAssignments = [];
  final attendance = <String, List<AttendanceRecord>>{};
  final sessionAttendance = <String, List<AttendanceRecord>>{};

  List<ProgramCode> programs = [];
  List<Department> departments = [];
  List<AcademicSession> academicSessions = [];
  StudentDashboardSummary studentDashboardSummary =
      const StudentDashboardSummary.empty();

  int attendanceThreshold = 80;
  String reportFrequency = 'Weekly';
  String session = TimetableCsvTemplate.defaultAcademicSessionId;
  int semester = 2;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  String? _loginError;
  String? get loginError => _loginError;

  late final FirestoreService _fs = FirestoreService.instance;
  final _loadedCollections = <String>{};
  final _loadingCollections = <String>{};
  final _pendingLoads = <String, Future<void>>{};

  bool isCollectionLoading(String key) => _loadingCollections.contains(key);

  bool get isBootstrapLoaded =>
      _loadedCollections.containsAll(['programs', 'departments', 'sessions']);

  List<AcademicSession> get selectableAcademicSessions {
    final values = academicSessions
        .where(
            (item) => item.isActive && item.status.toLowerCase() != 'archived')
        .toList()
      ..sort((a, b) => a.academicSessionId.compareTo(b.academicSessionId));
    final defaultIndex = values.indexWhere((item) =>
        item.academicSessionId ==
        TimetableCsvTemplate.defaultAcademicSessionId);
    if (defaultIndex > 0) {
      final defaultSession = values.removeAt(defaultIndex);
      values.insert(0, defaultSession);
    }
    return values;
  }

  bool get canManageAcademicSessions {
    final user = currentUser;
    if (user == null) return false;
    return user.role == UserRole.pentadbir;
  }

  bool get isTimetableDataLoaded =>
      _loadedCollections.containsAll(['timetable', 'uploads', 'rooms']);

  bool get isLecturerCourseAssignmentsLoaded =>
      _loadedCollections.contains('lecturerCourseAssignments');

  bool get isAdminUserManagementDataLoaded => _loadedCollections.containsAll(
      ['users', 'students', 'lecturerCourseAssignments', 'timetable']);

  bool get isBookingDataLoaded =>
      _loadedCollections.containsAll(['bookings', 'rooms', 'timetable']);

  bool get isDisciplineDataLoaded =>
      _loadedCollections.containsAll(['discipline', 'students', 'timetable']);

  bool get isStudentRecordDataLoaded =>
      _loadedCollections.containsAll(['students', 'timetable', 'lecturers']);

  bool get isAttendanceDataLoaded => _loadedCollections.containsAll(
      ['students', 'timetable', 'attendance', 'sessionAttendance']);

  bool get isDashboardDataLoaded {
    final requiredCollections = [
      'timetable',
      'bookings',
      'discipline',
      'sessionAttendance',
      if (_currentUserNeedsStudentDashboardSummary) 'studentDashboardSummary',
      if (currentUser?.role == UserRole.pentadbir) ...[
        'users',
        'students',
        'lecturers',
      ],
    ];
    return _loadedCollections.containsAll(requiredCollections);
  }

  bool get isDashboardDataLoading {
    final loadingCollections = [
      'timetable',
      'bookings',
      'discipline',
      'sessionAttendance',
      if (_currentUserNeedsStudentDashboardSummary) 'studentDashboardSummary',
      if (currentUser?.role == UserRole.pentadbir) ...[
        'users',
        'students',
        'lecturers',
      ],
    ];
    return loadingCollections.any(isCollectionLoading);
  }

  bool get _currentUserNeedsStudentDashboardSummary {
    final user = currentUser;
    return user?.role == UserRole.ketua_jabatan ||
        user?.role == UserRole.ketua_program;
  }

  /// Load all data from Firestore.
  /// Call once after Firebase is initialised and the user is authenticated.
  Future<void> loadData() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _fs.getUsers(),
        _fs.getStudents(),
        _fs.getLecturers(),
        _fs.getRoomResources(),
        _fs.getTimetableSlots(),
        _fs.getTimetableUploads(),
        _fs.getDisciplineReports(),
        _fs.getBookings(),
        _fs.getAllAttendance(),
        _fs.getPrograms(),
        _fs.getDepartments(),
        _fs.getAttendanceSessions(),
        _fs.getAllSessionAttendanceRecords(),
        _fs.getAcademicSessions(),
      ]);

      users = results[0] as List<AppUser>;
      students = results[1] as List<Student>;
      lecturers = results[2] as List<Lecturer>;
      roomResources = results[3] as List<RoomResource>;
      timetable = results[4] as List<TimetableSlot>;
      timetableUploads = results[5] as List<TimetableUploadRecord>;
      disciplineReports = results[6] as List<DisciplineReport>;
      bookings = results[7] as List<BookingRequest>;

      final attendanceMap = results[8] as Map<String, List<AttendanceRecord>>;
      attendance
        ..clear()
        ..addAll(attendanceMap);

      programs = results[9] as List<ProgramCode>;
      departments = results[10] as List<Department>;
      attendanceSessions = results[11] as List<AttendanceSession>;

      final sessionAttendanceMap =
          results[12] as Map<String, List<AttendanceRecord>>;
      sessionAttendance
        ..clear()
        ..addAll(sessionAttendanceMap);
      academicSessions = results[13] as List<AcademicSession>;
      _ensureSelectedAcademicSession();
      _loadedCollections.addAll([
        'users',
        'students',
        'lecturers',
        'rooms',
        'timetable',
        'uploads',
        'discipline',
        'bookings',
        'attendance',
        'programs',
        'departments',
        'attendanceSessions',
        'sessionAttendance',
        'sessions',
      ]);
    } catch (e) {
      _error = e.toString();
      debugPrint('=== ERROR LOADING DATA ===');
      debugPrint('$e');
      debugPrint('==========================');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadBootstrapDataIfNeeded() async {
    await Future.wait([
      _loadCollection(
          'programs', () async => programs = await _fs.getPrograms()),
      _loadCollection(
          'departments', () async => departments = await _fs.getDepartments()),
      _loadCollection('sessions',
          () async => academicSessions = await _fs.getAcademicSessions()),
    ]);
    _ensureSelectedAcademicSession();
  }

  Future<void> loadDashboardDataIfNeeded() async {
    await loadBootstrapDataIfNeeded();
    await Future.wait([
      loadTimetableIfNeeded(),
      loadBookingsIfNeeded(),
      loadDisciplineIfNeeded(),
      loadSessionAttendanceIfNeeded(),
      if (_currentUserNeedsStudentDashboardSummary)
        loadStudentDashboardSummaryIfNeeded(),
      if (currentUser?.role == UserRole.pentadbir) ...[
        loadUsersIfNeeded(),
        loadStudentsIfNeeded(),
        loadLecturersIfNeeded(),
      ],
    ]);
  }

  Future<void> loadAdminUserManagementDataIfNeeded({
    bool forceRefresh = false,
  }) async {
    await loadBootstrapDataIfNeeded();
    await Future.wait([
      loadUsersIfNeeded(forceRefresh: forceRefresh),
      loadStudentsIfNeeded(forceRefresh: forceRefresh),
      loadLecturerCourseAssignmentsIfNeeded(forceRefresh: forceRefresh),
      loadTimetableIfNeeded(forceRefresh: forceRefresh),
    ]);
  }

  Future<void> loadTimetableDataIfNeeded() async {
    await loadBootstrapDataIfNeeded();
    await Future.wait([
      loadTimetableIfNeeded(),
      loadTimetableUploadsIfNeeded(),
      loadRoomsIfNeeded(),
      loadLecturersIfNeeded(),
    ]);
  }

  Future<void> loadAttendanceDataIfNeeded() async {
    await loadBootstrapDataIfNeeded();
    await Future.wait([
      loadTimetableIfNeeded(),
      loadStudentsIfNeeded(),
      loadLegacyAttendanceIfNeeded(),
      loadAttendanceSessionsIfNeeded(),
      loadSessionAttendanceIfNeeded(),
    ]);
  }

  Future<void> loadBookingDataIfNeeded() async {
    await loadBootstrapDataIfNeeded();
    await Future.wait([
      loadTimetableIfNeeded(),
      loadBookingsIfNeeded(),
      loadRoomsIfNeeded(),
    ]);
  }

  Future<void> loadDisciplineDataIfNeeded() async {
    await loadBootstrapDataIfNeeded();
    await Future.wait([
      loadDisciplineIfNeeded(),
      loadStudentsIfNeeded(),
      loadTimetableIfNeeded(),
    ]);
  }

  Future<void> loadStudentRecordDataIfNeeded() async {
    await loadBootstrapDataIfNeeded();
    await Future.wait([
      loadStudentsIfNeeded(),
      loadTimetableIfNeeded(),
      loadLecturersIfNeeded(),
      loadSessionAttendanceIfNeeded(),
    ]);
  }

  Future<void> refreshStudentRecordData() async {
    _loadedCollections.removeAll([
      'students',
      'timetable',
      'lecturers',
      'sessionAttendance',
    ]);
    await loadStudentRecordDataIfNeeded();
  }

  Future<void> loadStudentDashboardSummaryIfNeeded() =>
      _loadCollection('studentDashboardSummary', () async {
        final programIds = scopedPrograms.map((program) => program.id).toSet();
        studentDashboardSummary = await _fs.getStudentDashboardSummary(
          programIds: programIds,
          attendanceThreshold: attendanceThreshold,
        );
      });

  Future<void> refreshTimetableData() async {
    _loadedCollections.removeAll(['timetable', 'uploads', 'rooms']);
    await loadTimetableDataIfNeeded();
  }

  Future<void> refreshBookings() async {
    _loadedCollections.remove('bookings');
    await loadBookingsIfNeeded();
  }

  Future<void> loadUsersIfNeeded({bool forceRefresh = false}) =>
      _loadCollection('users', () async => users = await _fs.getUsers(),
          forceRefresh: forceRefresh);

  Future<void> loadStudentsIfNeeded(
          {bool forceRefresh = false}) =>
      _loadCollection(
          'students', () async => students = await _fs.getStudents(),
          forceRefresh: forceRefresh);

  Future<void> loadLecturersIfNeeded({bool forceRefresh = false}) =>
      _loadCollection(
          'lecturers', () async => lecturers = await _fs.getLecturers(),
          forceRefresh: forceRefresh);

  Future<void> loadRoomsIfNeeded({bool forceRefresh = false}) =>
      _loadCollection(
          'rooms', () async => roomResources = await _fs.getRoomResources(),
          forceRefresh: forceRefresh);

  Future<void> loadTimetableIfNeeded({bool forceRefresh = false}) =>
      _loadCollection(
          'timetable', () async => timetable = await _fs.getTimetableSlots(),
          forceRefresh: forceRefresh);

  Future<void> loadTimetableUploadsIfNeeded({bool forceRefresh = false}) =>
      _loadCollection('uploads',
          () async => timetableUploads = await _fs.getTimetableUploads(),
          forceRefresh: forceRefresh);

  Future<void> loadDisciplineIfNeeded({bool forceRefresh = false}) =>
      _loadCollection('discipline',
          () async => disciplineReports = await _fs.getDisciplineReports(),
          forceRefresh: forceRefresh);

  Future<void> loadBookingsIfNeeded(
          {bool forceRefresh = false}) =>
      _loadCollection(
          'bookings', () async => bookings = await _fs.getBookings(),
          forceRefresh: forceRefresh);

  Future<void> loadLecturerCourseAssignmentsIfNeeded({
    bool forceRefresh = false,
  }) =>
      _loadCollection(
        'lecturerCourseAssignments',
        () async => lecturerCourseAssignments =
            await _fs.getLecturerCourseAssignments(),
        forceRefresh: forceRefresh,
      );

  Future<void> loadLegacyAttendanceIfNeeded() =>
      _loadCollection('attendance', () async {
        final attendanceMap = await _fs.getAllAttendance();
        attendance
          ..clear()
          ..addAll(attendanceMap);
      });

  Future<void> loadAttendanceSessionsIfNeeded() => _loadCollection(
      'attendanceSessions',
      () async => attendanceSessions = await _fs.getAttendanceSessions());

  Future<void> refreshAcademicSessions() async {
    _loadedCollections.remove('sessions');
    await loadBootstrapDataIfNeeded();
  }

  Future<void> loadSessionAttendanceIfNeeded() =>
      _loadCollection('sessionAttendance', () async {
        final sessionAttendanceMap = await _fs.getAllSessionAttendanceRecords();
        sessionAttendance
          ..clear()
          ..addAll(sessionAttendanceMap);
      });

  String attendanceSessionIdFor({
    required String slotId,
    required String sessionDate,
    required int weekNo,
  }) {
    return _fs.attendanceSessionIdFor(
      slotId: slotId,
      sessionDate: sessionDate,
      weekNo: weekNo,
    );
  }

  AttendanceSession? attendanceSessionForSlotDateWeek({
    required String slotId,
    required String sessionDate,
    required int weekNo,
  }) {
    final sessionId = _fs.attendanceSessionIdFor(
      slotId: slotId,
      sessionDate: sessionDate,
      weekNo: weekNo,
    );
    final duplicateKey = _fs.attendanceDuplicateKey(
      slotId: slotId,
      sessionDate: sessionDate,
      weekNo: weekNo,
    );
    return attendanceSessions
        .where((session) =>
            session.id == sessionId ||
            session.duplicateKey == duplicateKey ||
            (session.slotId == slotId &&
                session.sessionDate == sessionDate &&
                session.weekNo == weekNo))
        .firstOrNull;
  }

  Future<AttendanceSession?> loadAttendanceSessionForSlotDateWeek({
    required String slotId,
    required String sessionDate,
    required int weekNo,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = attendanceSessionForSlotDateWeek(
        slotId: slotId,
        sessionDate: sessionDate,
        weekNo: weekNo,
      );
      if (cached != null && sessionAttendance.containsKey(cached.id)) {
        return cached;
      }
    }

    final session = await _fs.getAttendanceSessionForSlotDateWeek(
      slotId: slotId,
      sessionDate: sessionDate,
      weekNo: weekNo,
    );
    if (session == null) return null;

    final records = await _fs.getAttendanceRecordsForSession(session.id);
    _upsertAttendanceSession(session, records);
    _loadedCollections.addAll(['attendanceSessions', 'sessionAttendance']);
    notifyListeners();
    return session;
  }

  Future<void> _loadCollection(
    String key,
    Future<void> Function() loader, {
    bool forceRefresh = false,
  }) {
    if (forceRefresh) _loadedCollections.remove(key);
    if (_loadedCollections.contains(key)) return Future.value();
    final pending = _pendingLoads[key];
    if (pending != null) return pending;

    _loadingCollections.add(key);
    notifyListeners();

    final future = loader().then((_) {
      _loadedCollections.add(key);
    }).catchError((Object e) {
      _error = e.toString();
      debugPrint('=== ERROR LOADING $key ===');
      debugPrint('$e');
      debugPrint('==========================');
      throw e;
    }).whenComplete(() {
      _loadingCollections.remove(key);
      _pendingLoads.remove(key);
      notifyListeners();
    });
    _pendingLoads[key] = future;
    return future;
  }

  void markCollectionStale(String key) {
    _loadedCollections.remove(key);
  }

  void clearDataCache() {
    users = [];
    students = [];
    lecturers = [];
    roomResources = [];
    timetable = [];
    timetableUploads = [];
    attendanceSessions = [];
    disciplineReports = [];
    bookings = [];
    lecturerCourseAssignments = [];
    attendance.clear();
    sessionAttendance.clear();
    programs = [];
    departments = [];
    academicSessions = [];
    studentDashboardSummary = const StudentDashboardSummary.empty();
    _loadedCollections.clear();
    _loadingCollections.clear();
    _pendingLoads.clear();
    _error = null;
  }

  /// Authenticate with Firebase Auth, then look up the matching AppUser
  /// profile in Firestore by Firebase Auth UID.
  Future<bool> login(String email, String password) async {
    _loginError = null;
    try {
      final credential = await AuthService.instance.signIn(email, password);
      final uid = credential.user?.uid;
      if (uid == null) {
        await AuthService.instance.signOut();
        _loginError = 'Akaun Firebase tidak sah. Sila cuba semula.';
        return false;
      }

      final appUser = await _fs.getUserById(uid);
      if (appUser == null) {
        await AuthService.instance.signOut();
        _loginError =
            'Profil pengguna tidak dijumpai dalam Firestore. Sila hubungi pentadbir.';
        return false;
      }
      if (!appUser.isActive) {
        await AuthService.instance.signOut();
        _loginError = 'Akaun anda tidak aktif. Sila hubungi pentadbir sistem.';
        return false;
      }

      clearDataCache();
      currentUser = appUser;
      await _fs.updateLastLogin(appUser.uid);
      await loadBootstrapDataIfNeeded();
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _loginError = _messageForAuthError(e);
      return false;
    } catch (_) {
      _loginError = 'Log masuk gagal. Sila semak sambungan dan cuba lagi.';
      return false;
    }
  }

  String _messageForAuthError(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => 'Format emel tidak sah.',
      'wrong-password' ||
      'invalid-credential' =>
        'Emel atau kata laluan tidak betul.',
      'user-not-found' => 'Akaun tidak dijumpai dalam Firebase Auth.',
      'user-disabled' => 'Akaun Firebase ini telah dinyahaktifkan.',
      'network-request-failed' =>
        'Ralat rangkaian. Sila semak sambungan internet anda.',
      'too-many-requests' =>
        'Terlalu banyak cubaan log masuk. Sila cuba semula kemudian.',
      _ => 'Ralat Firebase Auth: ${error.message ?? error.code}',
    };
  }

  void logout() {
    AuthService.instance.signOut();
    currentUser = null;
    clearDataCache();
    notifyListeners();
  }

  bool get currentProgramHasKetuaJabatan {
    final user = currentUser;
    if (user?.role != UserRole.ketua_program || user?.programId == null) {
      return false;
    }
    final program = programs.where((p) => p.id == user!.programId).firstOrNull;
    return program?.departmentId != null;
  }

  bool get currentKetuaProgramInheritsKetuaJabatanTasks {
    final user = currentUser;
    return user?.role == UserRole.ketua_program &&
        !currentProgramHasKetuaJabatan;
  }

  List<ProgramCode> get scopedPrograms {
    final user = currentUser;
    if (user == null) return [];
    if (user.role == UserRole.pentadbir) return programs.toList();
    if (user.role == UserRole.ketua_jabatan) {
      return programs
          .where((program) => program.departmentId == user.departmentId)
          .toList();
    }
    if (user.role == UserRole.ketua_program && user.programId != null) {
      return programs.where((program) => program.id == user.programId).toList();
    }
    if (user.role == UserRole.pensyarah && user.programId != null) {
      return programs.where((program) => program.id == user.programId).toList();
    }
    return [];
  }

  List<TimetableSlot> get scopedTimetable {
    final user = currentUser;
    if (user == null || user.role == UserRole.pentadbir) return [];

    if (user.role == UserRole.ketua_jabatan) {
      final deptProgramIds =
          scopedPrograms.map((program) => program.id).toSet();
      return timetable
          .where((slot) =>
              deptProgramIds.contains(_programIdForTimetableSlot(slot)))
          .toList();
    }

    if (user.role == UserRole.ketua_program) {
      return timetable
          .where((slot) => _programIdForTimetableSlot(slot) == user.programId)
          .toList();
    }

    // Pensyarah scope is assignment-based. New slots match by Auth UID,
    // lecturer email, or master lecturer profile id. Name matching is kept
    // only for legacy rows that have no stable identity fields.
    final userEmail = user.email.trim().toLowerCase();
    final userProfileId = user.lecturerProfileId;
    return timetable.where((slot) {
      if (!slot.isOfficial) return false;
      final slotEmail = slot.lecturerEmail?.trim().toLowerCase();
      if (slot.lecturerId == user.uid) return true;
      if (slotEmail != null && slotEmail == userEmail) return true;
      if (userProfileId != null &&
          userProfileId.isNotEmpty &&
          slot.lecturerProfileId == userProfileId) {
        return true;
      }
      final hasStableIdentity = slot.lecturerId.isNotEmpty ||
          (slotEmail != null && slotEmail.isNotEmpty) ||
          (slot.lecturerProfileId != null &&
              slot.lecturerProfileId!.isNotEmpty);
      return !hasStableIdentity && slot.lecturerName == user.name;
    }).toList();
  }

  List<Student> get scopedStudents {
    final user = currentUser;
    if (user == null) return [];
    if (user.role == UserRole.pentadbir) return students.toList();

    if (user.role == UserRole.ketua_jabatan) {
      final deptProgramIds =
          scopedPrograms.map((program) => program.id).toSet();
      return students
          .where((student) =>
              deptProgramIds.contains(_programIdForStudent(student)))
          .toList();
    }

    if (user.role == UserRole.ketua_program) {
      return students
          .where((student) => _programIdForStudent(student) == user.programId)
          .toList();
    }

    // Pensyarah sees students from sections they teach
    final sections = scopedTimetable.map((slot) => slot.section).toSet();
    return students
        .where((student) => sections.contains(student.section))
        .toList();
  }

  List<DisciplineReport> get scopedDisciplineReports {
    final user = currentUser;
    if (user == null || user.role == UserRole.pentadbir) return [];

    if (user.role == UserRole.ketua_jabatan) {
      final scopedProgramIds =
          scopedPrograms.map((program) => program.id).toSet();
      final scopedStudentIds =
          scopedStudents.map((student) => student.id).toSet();
      return disciplineReports
          .where((report) =>
              report.departmentId == user.departmentId ||
              (report.departmentId == null &&
                  (scopedProgramIds
                          .contains(_programIdForDisciplineReport(report)) ||
                      scopedStudentIds.contains(report.studentId))))
          .toList();
    }

    if (user.role == UserRole.ketua_program) {
      final scopedStudentIds =
          scopedStudents.map((student) => student.id).toSet();
      return disciplineReports
          .where((report) =>
              report.programId == user.programId ||
              (report.programId == null &&
                  (scopedStudentIds.contains(report.studentId) ||
                      _programIdForDisciplineReport(report) == user.programId)))
          .toList();
    }

    // Pensyarah. Fallbacks are kept only for older reports that have no
    // createdBy yet.
    return disciplineReports.where((report) {
      if (report.createdBy != null && report.createdBy!.isNotEmpty) {
        return report.createdBy == user.uid;
      }
      return report.createdByName == user.name || report.lecturer == user.name;
    }).toList();
  }

  List<BookingRequest> get scopedBookings {
    final user = currentUser;
    if (user == null || user.role == UserRole.pentadbir) return [];

    if (user.role == UserRole.ketua_jabatan) {
      final deptProgramIds = programs
          .where((program) => program.departmentId == user.departmentId)
          .map((program) => program.id)
          .toSet();
      return bookings
          .where((booking) =>
              deptProgramIds.contains(_programIdForBooking(booking)))
          .toList();
    }

    if (user.role == UserRole.ketua_program) {
      return bookings
          .where((booking) => _programIdForBooking(booking) == user.programId)
          .toList();
    }

    // Pensyarah
    return bookings.where((b) => b.lecturerId == user.uid).toList();
  }

  List<AttendanceSession> get scopedAttendanceSessions {
    final user = currentUser;
    if (user == null) return [];
    if (user.role == UserRole.pentadbir) return attendanceSessions.toList();
    if (user.role == UserRole.ketua_jabatan ||
        user.role == UserRole.ketua_program) {
      final scopedProgramIds =
          scopedPrograms.map((program) => program.id).toSet();
      return attendanceSessions
          .where((session) => scopedProgramIds.contains(session.programId))
          .toList();
    }
    return attendanceSessions
        .where((session) => session.lecturerId == user.uid)
        .toList();
  }

  Future<void> saveAttendance(
    String slotId,
    List<AttendanceRecord> records, {
    String? sessionDate,
    int? weekNo,
  }) async {
    final index = timetable.indexWhere((slot) => slot.id == slotId);
    final slot = index == -1 ? null : timetable[index];

    if (slot != null) {
      final resolvedSessionDate = sessionDate ?? slot.date;
      final resolvedWeekNo = weekNo ?? _weekNoForSlot(slot);
      final existingSession = await loadAttendanceSessionForSlotDateWeek(
        slotId: slot.id,
        sessionDate: resolvedSessionDate,
        weekNo: resolvedWeekNo,
        forceRefresh: true,
      );
      if (existingSession != null) {
        throw AttendanceSessionAlreadyExistsException(existingSession);
      }

      final session = _buildAttendanceSession(
        slot,
        records,
        sessionDate: resolvedSessionDate,
        weekNo: resolvedWeekNo,
      );
      final enrichedRecords = records
          .map((record) => _buildAttendanceRecord(
                record: record,
                slot: slot,
                session: session,
              ))
          .toList();

      try {
        await _fs.saveAttendanceSessionWithRecords(
          session: session,
          records: enrichedRecords,
          preventOverwrite: true,
        );
      } catch (error) {
        if (!_isAttendanceDuplicateError(error)) {
          rethrow;
        }
        final submittedSession = await loadAttendanceSessionForSlotDateWeek(
          slotId: slot.id,
          sessionDate: resolvedSessionDate,
          weekNo: resolvedWeekNo,
          forceRefresh: true,
        );
        if (submittedSession != null) {
          throw AttendanceSessionAlreadyExistsException(submittedSession);
        }
        _upsertAttendanceSession(session, enrichedRecords);
        throw AttendanceSessionAlreadyExistsException(session);
      }
      _upsertAttendanceSession(session, enrichedRecords);
    }

    // Keep the legacy write path for screens/reports still reading old data.
    await _fs.saveAttendance(slotId, records);
    await _fs.updateSlotStatus(slotId, 'Attendance Completed');

    attendance[slotId] = records;
    if (index != -1) {
      timetable[index] =
          timetable[index].copyWith(status: 'Attendance Completed');
    }
    notifyListeners();
  }

  AttendanceSession markAttendanceSessionSubmittedLocally(
    String slotId,
    List<AttendanceRecord> records, {
    required String sessionDate,
    required int weekNo,
  }) {
    final index = timetable.indexWhere((slot) => slot.id == slotId);
    if (index == -1) {
      throw StateError('Timetable slot not found.');
    }
    final slot = timetable[index];
    final session = _buildAttendanceSession(
      slot,
      records,
      sessionDate: sessionDate,
      weekNo: weekNo,
    );
    final enrichedRecords = records
        .map((record) => _buildAttendanceRecord(
              record: record,
              slot: slot,
              session: session,
            ))
        .toList();
    _upsertAttendanceSession(session, enrichedRecords);
    notifyListeners();
    return session;
  }

  Future<void> editAttendance(
    String slotId,
    List<AttendanceRecord> records, {
    required String sessionDate,
    required int weekNo,
    required String editReason,
  }) async {
    final reason = editReason.trim();
    if (reason.isEmpty) {
      throw ArgumentError('Attendance edit reason is required.');
    }

    final index = timetable.indexWhere((slot) => slot.id == slotId);
    if (index == -1) {
      throw StateError('Timetable slot not found.');
    }
    final slot = timetable[index];
    final sessionId = _fs.attendanceSessionIdFor(
      slotId: slot.id,
      sessionDate: sessionDate,
      weekNo: weekNo,
    );
    var existingSession = attendanceSessions
        .where((session) => session.id == sessionId)
        .firstOrNull;
    existingSession ??= await _fs.getAttendanceSessionForSlotDateWeek(
      slotId: slot.id,
      sessionDate: sessionDate,
      weekNo: weekNo,
    );
    if (existingSession == null) {
      throw StateError('Attendance session must be submitted before editing.');
    }
    final submittedSession = existingSession;

    final cachedPreviousRecords = sessionAttendance[sessionId];
    var previousRecords = cachedPreviousRecords ??
        await _fs.getAttendanceRecordsForSession(sessionId);
    if (previousRecords.isEmpty) {
      previousRecords = attendance[slot.id] ?? const <AttendanceRecord>[];
    }
    final previousByStudent = {
      for (final record in previousRecords) record.studentId: record,
    };
    final changes = <AttendanceEditChange>[];
    for (final record in records) {
      final previous = previousByStudent[record.studentId];
      if (previous != null && previous.status != record.status) {
        final student = students
            .where((student) => student.id == record.studentId)
            .firstOrNull;
        changes.add(AttendanceEditChange(
          studentId: record.studentId,
          studentName: record.studentName ?? student?.name ?? record.studentId,
          originalStatus: previous.status,
          newStatus: record.status,
        ));
      }
    }
    if (changes.isEmpty) {
      throw StateError('Tiada perubahan status untuk disimpan.');
    }

    final rebuilt = _buildAttendanceSession(
      slot,
      records,
      sessionDate: sessionDate,
      weekNo: weekNo,
    );
    final user = currentUser;
    final editedAt = DateTime.now().toIso8601String();
    final editEntry = AttendanceEditEntry(
      editedAt: editedAt,
      editedBy: user?.uid ?? submittedSession.lecturerId,
      editedByName: user?.name ?? submittedSession.lecturerName,
      reason: reason,
      changes: changes,
    );
    final session = rebuilt.copyWith(
      createdBy: submittedSession.createdBy,
      createdAt: submittedSession.createdAt,
      submittedAt: submittedSession.submittedAt,
      updatedAt: editedAt,
      updatedBy: user?.uid ?? submittedSession.lecturerId,
      updatedByName: user?.name ?? submittedSession.lecturerName,
      editReason: reason,
      editHistory: [...submittedSession.editHistory, editEntry],
    );
    final enrichedRecords = records.map((record) {
      final previous = previousByStudent[record.studentId];
      final changed = previous != null && previous.status != record.status;
      final auditedRecord = changed
          ? record.copyWith(
              updatedAt: editedAt,
              updatedBy: user?.uid ?? submittedSession.lecturerId,
              updatedByName: user?.name ?? submittedSession.lecturerName,
              editReason: reason,
              originalStatus: previous.status,
              newStatus: record.status,
            )
          : record;
      return _buildAttendanceRecord(
        record: auditedRecord,
        slot: slot,
        session: session,
      );
    }).toList();

    await _fs.saveAttendanceSessionWithRecords(
      session: session,
      records: enrichedRecords,
    );

    // Keep the legacy write path aligned while older screens still read it.
    await _fs.saveAttendance(slot.id, records);
    attendance[slot.id] = records;
    _upsertAttendanceSession(session, enrichedRecords);
    notifyListeners();
  }

  Future<void> upsertTimetableSlot(TimetableSlot slot) async {
    final index = timetable.indexWhere((item) => item.id == slot.id);
    if (index == -1) {
      timetable.add(slot);
    } else {
      timetable[index] = slot;
    }
    notifyListeners();
    await _fs.updateTimetableSlot(slot);
  }

  Future<void> upsertTimetableSlots(List<TimetableSlot> slots) async {
    for (final slot in slots) {
      final index = timetable.indexWhere((item) => item.id == slot.id);
      if (index == -1) {
        timetable.add(slot);
      } else {
        timetable[index] = slot;
      }
    }
    notifyListeners();
    for (final slot in slots) {
      await _fs.updateTimetableSlot(slot);
    }
  }

  Future<void> updateTimetableSlotsStatus(
    List<String> slotIds,
    String status,
  ) async {
    final idSet = slotIds.toSet();
    for (var i = 0; i < timetable.length; i++) {
      final slot = timetable[i];
      if (idSet.contains(slot.id)) {
        timetable[i] = slot.copyWith(status: status);
      }
    }
    notifyListeners();
    await _fs.updateTimetableSlotsStatus(slotIds, status);
  }

  Future<void> publishTimetableSlots(List<TimetableSlot> slots) async {
    final user = currentUser;
    if (user == null || slots.isEmpty) return;
    final slotIds = slots.map((slot) => slot.id).toSet();
    for (var i = 0; i < timetable.length; i++) {
      final slot = timetable[i];
      if (slotIds.contains(slot.id)) {
        timetable[i] = slot.copyWith(
          status: 'active',
          importStatus: 'official',
          isOfficial: true,
          hasConflict: false,
          conflictTypes: const [],
        );
      }
    }
    notifyListeners();
    await _fs.publishTimetableSlots(slotIds.toList(), publishedBy: user);
  }

  Future<void> deleteTimetableSlot(String slotId) async {
    timetable.removeWhere((slot) => slot.id == slotId);
    attendance.remove(slotId);
    notifyListeners();
    await _fs.deleteTimetableSlot(slotId);
  }

  Future<void> deleteTimetableSlots(List<String> slotIds) async {
    final idSet = slotIds.toSet();
    timetable.removeWhere((slot) => idSet.contains(slot.id));
    for (final slotId in slotIds) {
      attendance.remove(slotId);
    }
    notifyListeners();
    await _fs.deleteTimetableSlots(slotIds);
  }

  Future<void> addDiscipline(DisciplineReport report) async {
    final enriched = _buildDisciplineReport(report);
    final routed = await _fs.prepareDisciplineReportRouting(enriched);
    disciplineReports.insert(0, routed);
    notifyListeners();
    await _fs.addDisciplineReport(routed);
  }

  Future<void> updateDiscipline(
    String id,
    String status, {
    String? actionTakenNote,
    String? reviewerNotes,
    String? actionTaken,
    String? rejectionReason,
  }) async {
    final normalizedStatus = _normalizeDisciplineStatus(status);
    final index = disciplineReports.indexWhere((report) => report.id == id);
    final user = currentUser;
    final scoped = scopedDisciplineReports.any((report) => report.id == id);
    if ((user?.role == UserRole.ketua_jabatan ||
            user?.role == UserRole.ketua_program) &&
        !scoped) {
      throw StateError('Laporan disiplin di luar skop pengguna.');
    }
    if (index != -1) {
      disciplineReports[index] = disciplineReports[index].copyWith(
        status: normalizedStatus,
        reviewedBy: user?.uid,
        reviewedByName: user?.name,
        reviewerRole: user?.role.firestoreValue,
        reviewerNotes: reviewerNotes,
        actionTakenBy: normalizedStatus == 'action_taken'
            ? user?.uid
            : disciplineReports[index].actionTakenBy,
        actionTakenByName: normalizedStatus == 'action_taken'
            ? user?.name
            : disciplineReports[index].actionTakenByName,
        actionTaken: normalizedStatus == 'action_taken' ? actionTaken : null,
        actionTakenNote: normalizedStatus == 'action_taken'
            ? (actionTakenNote ?? actionTaken)
            : disciplineReports[index].actionTakenNote,
        rejectionReason: normalizedStatus == 'rejected'
            ? rejectionReason
            : disciplineReports[index].rejectionReason,
      );
    }
    notifyListeners();
    await _fs.updateDisciplineStatus(
      id,
      normalizedStatus,
      actionTakenBy: user?.uid,
      actionTakenByName: user?.name,
      actionTakenNote: actionTakenNote ?? actionTaken,
      reviewedBy: user?.uid,
      reviewedByName: user?.name,
      reviewerRole: user?.role.firestoreValue,
      reviewerNotes: reviewerNotes,
      actionTaken: actionTaken,
      rejectionReason: rejectionReason,
    );
  }

  Future<void> addBooking(BookingRequest booking) async {
    if (!isRoomAvailable(
      room: booking.room,
      date: booking.replacementDate,
      start: booking.replacementStart,
      end: booking.replacementEnd,
      ignoreBookingId: booking.id,
    )) {
      return;
    }
    bookings.insert(0, booking);
    notifyListeners();
    await _fs.addBooking(booking);
  }

  Future<void> updateBooking(
    String id,
    String status, {
    String? rejectionReason,
  }) async {
    final index = bookings.indexWhere((booking) => booking.id == id);
    if (index == -1) return;

    final reviewer = currentUser;
    final now = DateTime.now().toIso8601String();

    bookings[index] = bookings[index].copyWith(
      status: status,
      reviewedBy: reviewer?.uid,
      reviewedByName: reviewer?.name,
      reviewedAt: now,
      rejectionReason: status == 'Rejected' ? rejectionReason : null,
    );

    if (status == 'Approved') {
      final booking = bookings[index];
      // Booking conflict helper: re-check room availability before approving
      if (!isRoomAvailable(
        room: booking.room,
        date: booking.replacementDate,
        start: booking.replacementStart,
        end: booking.replacementEnd,
        ignoreBookingId: booking.id,
      )) {
        // Auto-reject if room no longer available
        bookings[index] = booking.copyWith(
          status: 'Rejected',
          reviewedBy: reviewer?.uid,
          reviewedByName: reviewer?.name,
          reviewedAt: now,
          rejectionReason: 'Bilik tidak lagi tersedia pada masa ini.',
        );
        notifyListeners();
        await _fs.updateBookingStatus(
          id,
          'Rejected',
          reviewedBy: reviewer?.uid,
          reviewedByName: reviewer?.name,
          rejectionReason: 'Bilik tidak lagi tersedia pada masa ini.',
        );
        return;
      }

      // Prefer a source slot taught by the *same* lecturer for this section
      // so subjectCode / classType / program carry over correctly; fall
      // back to any slot in the section if no exact match exists.
      final source = timetable
              .where((slot) =>
                  slot.section == booking.section &&
                  slot.lecturerId == booking.lecturerId)
              .firstOrNull ??
          timetable
              .where((slot) => slot.section == booking.section)
              .firstOrNull;

      // Best-effort: fills lecturerEmail / lecturerProfileId from the user
      // record even when no matching source slot was found. Falls back
      // silently to source's values if `users` hasn't been loaded yet.
      final lecturerUser =
          users.where((u) => u.uid == booking.lecturerId).firstOrNull;

      final resolvedProgramId =
          _programIdForBooking(booking) ?? source?.programId;
      final resolvedDepartmentId = booking.departmentId ??
          source?.departmentId ??
          _programForId(resolvedProgramId)?.departmentId;
      final resolvedSessionId =
          source?.academicSessionId ?? source?.session ?? session;

      final newSlotId = 'T${DateTime.now().millisecondsSinceEpoch}';
      final newSlot = TimetableSlot(
        id: newSlotId,
        academicSessionId: resolvedSessionId,
        session: resolvedSessionId,
        semester: semester,
        programId: resolvedProgramId,
        program: source?.program ?? '',
        departmentId: resolvedDepartmentId,
        classId: booking.section,
        section: booking.section,
        subjectCode: source?.subjectCode ?? 'REP',
        subjectName: booking.subject,
        lecturerId: booking.lecturerId,
        lecturerName: booking.lecturerName,
        lecturerEmail: lecturerUser?.email ?? source?.lecturerEmail,
        lecturerProfileId:
            lecturerUser?.lecturerProfileId ?? source?.lecturerProfileId,
        roomId: booking.roomId ?? booking.room,
        roomName: booking.roomName ?? booking.room,
        room: booking.room,
        day: 'Ganti',
        date: booking.replacementDate,
        startTime: booking.replacementStart,
        endTime: booking.replacementEnd,
        enrolled: source?.enrolled ?? 0,
        capacity: source?.capacity ?? 0,
        classType: source?.classType ?? 'Teori',
        slotType: 'Ganti',
        status: 'active',
        isOfficial: true,
        createdBy: reviewer?.uid,
      );
      timetable.add(newSlot);
      await _fs.addTimetableSlot(newSlot, sourceBookingId: booking.id);
      await _fs.linkBookingReplacementSlot(booking.id, newSlotId);
    }

    notifyListeners();
    await _fs.updateBookingStatus(
      id,
      status,
      reviewedBy: reviewer?.uid,
      reviewedByName: reviewer?.name,
      rejectionReason: status == 'Rejected' ? rejectionReason : null,
    );
  }

  void updateAttendanceThreshold(int value) {
    attendanceThreshold = value;
    _loadedCollections.remove('studentDashboardSummary');
    studentDashboardSummary = const StudentDashboardSummary.empty();
    notifyListeners();
  }

  void updateSemester(int value) {
    semester = value;
    notifyListeners();
  }

  void updateAcademicSession(String value) {
    session = value;
    notifyListeners();
  }

  Future<void> createAcademicSession(AcademicSession academicSession) async {
    await _fs.createAcademicSession(
      academicSession,
      createdBy: currentUser?.uid,
    );
    academicSessions.add(academicSession);
    _ensureSelectedAcademicSession();
    notifyListeners();
  }

  Future<void> updateAcademicSessionRecord(
      AcademicSession academicSession) async {
    await _fs.updateAcademicSession(academicSession);
    final index = academicSessions.indexWhere(
      (item) => item.academicSessionId == academicSession.academicSessionId,
    );
    if (index == -1) {
      academicSessions.add(academicSession);
    } else {
      academicSessions[index] = academicSession;
    }
    _ensureSelectedAcademicSession();
    notifyListeners();
  }

  Future<void> archiveAcademicSession(String academicSessionId) async {
    await _fs.archiveAcademicSession(academicSessionId);
    final index = academicSessions.indexWhere(
      (item) => item.academicSessionId == academicSessionId,
    );
    if (index != -1) {
      academicSessions[index] = academicSessions[index].copyWith(
        status: 'archived',
        isActive: false,
      );
    }
    _ensureSelectedAcademicSession();
    notifyListeners();
  }

  void updateReportFrequency(String value) {
    reportFrequency = value;
    notifyListeners();
  }

  AttendanceSummary attendanceSummaryForStudent(Student student) {
    var summary = sessionAttendanceSummaryForStudent(student);

    for (final records in attendance.values) {
      for (final record
          in records.where((record) => record.studentId == student.id)) {
        summary = summary.add(record.status);
      }
    }
    return summary;
  }

  AttendanceSummary sessionAttendanceSummaryForStudent(Student student) {
    var summary =
        const AttendanceSummary(present: 0, late: 0, absent: 0, mc: 0, ck: 0);
    for (final records in sessionAttendance.values) {
      for (final record
          in records.where((record) => record.studentId == student.id)) {
        summary = summary.add(record.status);
      }
    }
    return summary;
  }

  List<AttendanceSummary> weeklyAttendanceForStudent(Student student) {
    return List.generate(18, (index) {
      final weekNo = index + 1;
      var summary =
          const AttendanceSummary(present: 0, late: 0, absent: 0, mc: 0, ck: 0);
      for (final records in sessionAttendance.values) {
        for (final record in records.where((record) =>
            record.studentId == student.id && record.weekNo == weekNo)) {
          summary = summary.add(record.status);
        }
      }
      return summary;
    });
  }

  AttendanceSummary attendanceSummaryForStudentWeek(
    Student student,
    int weekNo,
  ) {
    if (weekNo < 1 || weekNo > 18) {
      return const AttendanceSummary(
          present: 0, late: 0, absent: 0, mc: 0, ck: 0);
    }
    return weeklyAttendanceForStudent(student)[weekNo - 1];
  }

  int attendancePercentageForStudent(Student student) {
    return attendanceSummaryForStudent(student).percentage;
  }

  String attendanceRiskForStudent(Student student) {
    final percentage = attendancePercentageForStudent(student);
    if (percentage >= attendanceThreshold) return 'Safe';
    if (percentage >= 75) return 'Warning';
    return 'Critical';
  }

  List<Student> get criticalStudents {
    return scopedStudents
        .where((student) =>
            attendancePercentageForStudent(student) < attendanceThreshold)
        .toList();
  }

  bool isRoomAvailable({
    required String room,
    required String date,
    required String start,
    required String end,
    String? ignoreBookingId,
  }) {
    String getMalayDayName(String dateStr) {
      try {
        final parsedDate = DateTime.parse(dateStr);
        switch (parsedDate.weekday) {
          case 1:
            return 'Isnin';
          case 2:
            return 'Selasa';
          case 3:
            return 'Rabu';
          case 4:
            return 'Khamis';
          case 5:
            return 'Jumaat';
          case 6:
            return 'Sabtu';
          case 7:
            return 'Ahad';
          default:
            return '';
        }
      } catch (_) {
        return '';
      }
    }

    String cleanRoom(String name) {
      return name.replaceAll(RegExp(r'\s*\(.*?\)\s*'), '').trim().toLowerCase();
    }

    final targetDay = getMalayDayName(date);
    final targetRoomClean = cleanRoom(room);

    final matchingSlots = timetable.where((slot) {
      if (cleanRoom(slot.room) != targetRoomClean) return false;
      final dayMatch = slot.day.toLowerCase() == targetDay.toLowerCase() ||
          slot.dayOfWeek?.toLowerCase() == targetDay.toLowerCase();
      final dateMatch = slot.date == date;
      return dayMatch || dateMatch;
    });
    for (final slot in matchingSlots) {
      if (_timesOverlap(start, end, slot.startTime, slot.endTime)) return false;
    }

    final approvedBookings = bookings.where(
      (booking) =>
          booking.id != ignoreBookingId &&
          (booking.status == 'Approved' || booking.status == 'Lulus') &&
          cleanRoom(booking.room) == targetRoomClean &&
          booking.replacementDate == date,
    );
    for (final booking in approvedBookings) {
      if (_timesOverlap(
          start, end, booking.replacementStart, booking.replacementEnd)) {
        return false;
      }
    }
    return true;
  }

  bool _timesOverlap(String startA, String endA, String startB, String endB) {
    final aStart = _minutes(startA);
    final aEnd = _minutes(endA);
    final bStart = _minutes(startB);
    final bEnd = _minutes(endB);
    return aStart < bEnd && bStart < aEnd;
  }

  Future<AttendanceDemoSeedResult> resetAndSeedM1DemoAttendance() async {
    final slots = _demoAttendanceSlots();
    if (slots.isEmpty) {
      throw StateError(
          'Tiada slot jadual ditemui untuk menjana data demo kehadiran.');
    }

    await _fs.resetAttendanceCollections();
    attendanceSessions.clear();
    sessionAttendance.clear();

    var generatedSessions = 0;
    var generatedRecords = 0;
    var processedClasses = 0;
    var skippedClasses = 0;
    var editedExampleAdded = false;
    for (final slot in slots) {
      final slotStudents = _studentsForSlot(slot);
      if (slotStudents.isEmpty) {
        skippedClasses++;
        continue;
      }
      processedClasses++;

      final weekOneDate = _demoWeekOneDate(slot);
      for (var week = 1; week <= 6; week++) {
        final sessionDate =
            _isoDate(weekOneDate.add(Duration(days: 7 * (week - 1))));
        final draftRecords = <AttendanceRecord>[];
        final shouldAddEditExample =
            !editedExampleAdded && week == 2 && slotStudents.isNotEmpty;

        for (var index = 0; index < slotStudents.length; index++) {
          final student = slotStudents[index];
          final status = shouldAddEditExample && index == 0
              ? AttendanceStatus.present
              : _demoAttendanceStatus(index, week);
          final isPresentOrLate = status == AttendanceStatus.present ||
              status == AttendanceStatus.late;
          var record = AttendanceRecord(
            slotId: slot.id,
            studentId: student.id,
            status: status,
            checkIn: isPresentOrLate ? slot.startTime : '-',
            remarks: status == AttendanceStatus.mc
                ? 'Demo MC'
                : status == AttendanceStatus.ck
                    ? 'Demo CK'
                    : '',
          );
          if (shouldAddEditExample && index == 0) {
            final editorId = currentUser?.uid ?? slot.lecturerId;
            final editorName = currentUser?.name ?? slot.lecturerName;
            record = record.copyWith(
              originalStatus: AttendanceStatus.absent,
              newStatus: AttendanceStatus.present,
              updatedBy: editorId,
              updatedByName: editorName,
              editReason:
                  'Demo pembetulan: pelajar hadir tetapi tersalah tanda tidak hadir.',
            );
          }
          draftRecords.add(record);
        }

        var session = _buildAttendanceSession(
          slot,
          draftRecords,
          sessionDate: sessionDate,
          weekNo: week,
        );
        if (shouldAddEditExample) {
          final editedStudent = slotStudents.first;
          final editorId = currentUser?.uid ?? slot.lecturerId;
          final editorName = currentUser?.name ?? slot.lecturerName;
          session = session.copyWith(
            updatedBy: editorId,
            updatedByName: editorName,
            editReason:
                'Demo pembetulan: pelajar hadir tetapi tersalah tanda tidak hadir.',
            editHistory: [
              AttendanceEditEntry(
                editedAt: DateTime.now().toIso8601String(),
                editedBy: editorId,
                editedByName: editorName,
                reason:
                    'Demo pembetulan: pelajar hadir tetapi tersalah tanda tidak hadir.',
                changes: [
                  AttendanceEditChange(
                    studentId: editedStudent.id,
                    studentName: editedStudent.name,
                    originalStatus: AttendanceStatus.absent,
                    newStatus: AttendanceStatus.present,
                  ),
                ],
              ),
            ],
          );
          editedExampleAdded = true;
        }
        final enrichedRecords = draftRecords
            .map((record) => _buildAttendanceRecord(
                  record: record,
                  slot: slot,
                  session: session,
                ))
            .toList();

        await _fs.saveAttendanceSessionWithRecords(
          session: session,
          records: enrichedRecords,
        );
        _upsertAttendanceSession(session, enrichedRecords);
        generatedSessions++;
        generatedRecords += enrichedRecords.length;
      }
    }

    if (generatedSessions == 0) {
      throw StateError(
          'Tiada data demo dijana kerana pelajar tidak sepadan dengan section slot jadual.');
    }

    _loadedCollections.removeAll(['attendanceSessions', 'sessionAttendance']);
    await Future.wait([
      loadAttendanceSessionsIfNeeded(),
      loadSessionAttendanceIfNeeded(),
    ]);
    notifyListeners();
    return AttendanceDemoSeedResult(
      sessionsCreated: generatedSessions,
      recordsCreated: generatedRecords,
      classesProcessed: processedClasses,
      classesSkipped: skippedClasses,
    );
  }

  List<TimetableSlot> _demoAttendanceSlots() {
    final selectedByGroup = <String, TimetableSlot>{};
    for (final slot in timetable) {
      selectedByGroup.putIfAbsent(_demoSlotGroupKey(slot), () => slot);
    }
    return selectedByGroup.values.toList();
  }

  List<Student> _studentsForSlot(TimetableSlot slot) {
    final keys = _slotSectionKeys(slot);
    final sectionMatches = students.where((student) {
      return keys.contains(_normalizedSection(student.section));
    }).toList();
    if (sectionMatches.isNotEmpty) return sectionMatches;

    final slotProgramId = _programIdForTimetableSlot(slot);
    if (slotProgramId == null || slotProgramId.isEmpty) return const [];

    return students.where((student) {
      return _programIdForStudent(student) == slotProgramId;
    }).toList();
  }

  Set<String> _slotSectionKeys(TimetableSlot slot) {
    return {
      _normalizedSection(slot.section),
      if ((slot.classId ?? '').isNotEmpty) _normalizedSection(slot.classId!),
    }..removeWhere((value) => value.isEmpty);
  }

  String _demoSlotGroupKey(TimetableSlot slot) {
    final programId = _programIdForTimetableSlot(slot) ??
        slot.programId ??
        _normalizedSection(slot.program);
    final section = _normalizedSection(
        slot.section.isNotEmpty ? slot.section : (slot.classId ?? 'kelas'));
    final subjectCode = _normalizedSection(
        slot.subjectCode.isNotEmpty ? slot.subjectCode : slot.subjectName);
    return '$programId|$section|$subjectCode';
  }

  DateTime _demoWeekOneDate(TimetableSlot slot) {
    final slotDate = DateTime.tryParse(slot.date);
    if (slotDate != null) {
      return slotDate.subtract(Duration(days: 7 * (_weekNoForSlot(slot) - 1)));
    }

    final sessionId = slot.academicSessionId ?? slot.session;
    final academicSession = academicSessions
        .where((item) => item.academicSessionId == sessionId)
        .firstOrNull;
    return DateTime.tryParse(academicSession?.startDate ?? '') ??
        DateTime(2026, 1, 1);
  }

  String _normalizedSection(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  AttendanceStatus _demoAttendanceStatus(int studentIndex, int weekNo) {
    final studentNumber = studentIndex + 1;
    if (studentNumber <= 3) {
      return weekNo == studentNumber + 1
          ? AttendanceStatus.late
          : AttendanceStatus.present;
    }
    if (studentNumber <= 6) {
      return weekNo == studentNumber - 3
          ? AttendanceStatus.absent
          : AttendanceStatus.present;
    }
    if (studentNumber <= 8) {
      return weekNo == 2 || weekNo == 5
          ? AttendanceStatus.absent
          : AttendanceStatus.present;
    }
    if (studentNumber == 9) {
      return weekNo == 1 || weekNo == 3 || weekNo == 6
          ? AttendanceStatus.absent
          : AttendanceStatus.present;
    }
    if (studentNumber == 10) {
      return weekNo.isEven ? AttendanceStatus.ck : AttendanceStatus.mc;
    }
    if (studentNumber == 11) {
      return switch (weekNo) {
        1 => AttendanceStatus.present,
        2 => AttendanceStatus.absent,
        _ => AttendanceStatus.mc,
      };
    }
    if (studentNumber == 12) {
      return weekNo == 1 ? AttendanceStatus.late : AttendanceStatus.ck;
    }

    return switch (studentIndex % 5) {
      0 => weekNo == 4 ? AttendanceStatus.absent : AttendanceStatus.present,
      1 => weekNo == 2 || weekNo == 6
          ? AttendanceStatus.absent
          : AttendanceStatus.present,
      2 => weekNo == 3 ? AttendanceStatus.late : AttendanceStatus.present,
      3 => weekNo == 5 ? AttendanceStatus.mc : AttendanceStatus.present,
      _ => weekNo == 1 || weekNo == 6
          ? AttendanceStatus.absent
          : AttendanceStatus.present,
    };
  }

  String _isoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  int _minutes(String text) {
    final parts = text.split(':');
    if (parts.length != 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  AttendanceSession _buildAttendanceSession(
    TimetableSlot slot,
    List<AttendanceRecord> records, {
    String? sessionDate,
    int? weekNo,
  }) {
    final summary = _summaryForRecords(records);
    final program = _programForName(slot.program);
    final resolvedWeekNo = weekNo ?? _weekNoForSlot(slot);
    final resolvedSessionDate = sessionDate ?? slot.date;
    final sessionId = _fs.attendanceSessionIdFor(
      slotId: slot.id,
      sessionDate: resolvedSessionDate,
      weekNo: resolvedWeekNo,
    );

    return AttendanceSession(
      id: sessionId,
      slotId: slot.id,
      sessionDate: resolvedSessionDate,
      weekNo: resolvedWeekNo,
      academicSession: slot.session,
      semester: slot.semester,
      programId: program?.id ?? slot.program,
      programName: program?.name ?? slot.program,
      departmentId: program?.departmentId,
      section: slot.section,
      subjectCode: slot.subjectCode,
      subjectName: slot.subjectName,
      lecturerId: slot.lecturerId,
      lecturerName: slot.lecturerName,
      status: 'submitted',
      totalStudents: records.length,
      presentCount: summary.present,
      lateCount: summary.late,
      absentCount: summary.absent,
      mcCount: summary.mc,
      ckCount: summary.ck,
      attendancePercentage: summary.percentage,
      duplicateKey: _fs.attendanceDuplicateKey(
        slotId: slot.id,
        sessionDate: resolvedSessionDate,
        weekNo: resolvedWeekNo,
      ),
      createdBy: currentUser?.uid ?? slot.lecturerId,
    );
  }

  AttendanceRecord _buildAttendanceRecord({
    required AttendanceRecord record,
    required TimetableSlot slot,
    required AttendanceSession session,
  }) {
    final student =
        students.where((student) => student.id == record.studentId).firstOrNull;
    return record.copyWith(
      id: '${session.id}_${record.studentId}',
      sessionId: session.id,
      slotId: slot.id,
      studentName: student?.name,
      programId: session.programId,
      programName: session.programName,
      departmentId: session.departmentId,
      section: student?.section ?? session.section,
      weekNo: session.weekNo,
      sessionDate: session.sessionDate,
      createdBy: currentUser?.uid ?? session.createdBy,
    );
  }

  void _upsertAttendanceSession(
    AttendanceSession session,
    List<AttendanceRecord> records,
  ) {
    final index =
        attendanceSessions.indexWhere((item) => item.id == session.id);
    if (index == -1) {
      attendanceSessions.add(session);
    } else {
      attendanceSessions[index] = session;
    }
    sessionAttendance[session.id] = records;
  }

  bool _isAttendanceDuplicateError(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('attendance session already exists') ||
        text.contains('already exists for this slot') ||
        text.contains('sudah wujud');
  }

  AttendanceSummary _summaryForRecords(List<AttendanceRecord> records) {
    var summary =
        const AttendanceSummary(present: 0, late: 0, absent: 0, mc: 0, ck: 0);
    for (final record in records) {
      summary = summary.add(record.status);
    }
    return summary;
  }

  DisciplineReport _buildDisciplineReport(DisciplineReport report) {
    final user = currentUser;
    final student =
        students.where((student) => student.id == report.studentId).firstOrNull;
    final slot = _slotForDisciplineReport(report, student);
    final slotProgramId = slot?.programId != null && slot!.programId!.isNotEmpty
        ? slot.programId
        : null;
    final slotDepartmentId =
        slot?.departmentId != null && slot!.departmentId!.isNotEmpty
            ? slot.departmentId
            : null;
    final program = _programForId(slotProgramId) ??
        _programForId(report.programId) ??
        _programForId(user?.programId) ??
        _programForName(report.programName) ??
        _programForName(student?.program) ??
        _programForName(slot?.program);
    final programName = report.programName ??
        program?.name ??
        student?.program ??
        slot?.program;

    return report.copyWith(
      status: _normalizeDisciplineStatus(report.status),
      programId: report.programId ?? slotProgramId ?? program?.id,
      programName: programName ?? program?.name,
      departmentId:
          report.departmentId ?? slotDepartmentId ?? program?.departmentId,
      subjectCode: report.subjectCode ?? slot?.subjectCode,
      subjectName: report.subjectName ??
          (report.subject == '-' ? slot?.subjectName : report.subject),
      slotId: report.slotId ?? slot?.id,
      createdBy: report.createdBy ?? user?.uid,
      createdByName: report.createdByName ?? user?.name ?? report.lecturer,
      createdAt: report.createdAt,
      updatedAt: report.updatedAt,
    );
  }

  TimetableSlot? _slotForDisciplineReport(
    DisciplineReport report,
    Student? student,
  ) {
    if (report.slotId != null) {
      final byId =
          timetable.where((slot) => slot.id == report.slotId).firstOrNull;
      if (byId != null) return byId;
    }
    final user = currentUser;
    final section = student?.section ?? report.section;
    return timetable
        .where((slot) =>
            slot.section == section &&
            (user == null || slot.lecturerId == user.uid))
        .firstOrNull;
  }

  ProgramCode? _programForName(String? programName) {
    if (programName == null || programName.isEmpty) return null;
    return programs.where((program) => program.name == programName).firstOrNull;
  }

  ProgramCode? _programForId(String? programId) {
    if (programId == null || programId.isEmpty) return null;
    return programs.where((program) => program.id == programId).firstOrNull;
  }

  void _ensureSelectedAcademicSession() {
    final selectable = selectableAcademicSessions;
    if (selectable.any((item) => item.academicSessionId == session)) return;
    final defaultSession = selectable
        .where((item) =>
            item.academicSessionId ==
            TimetableCsvTemplate.defaultAcademicSessionId)
        .firstOrNull;
    session = defaultSession?.academicSessionId ??
        selectable.firstOrNull?.academicSessionId ??
        TimetableCsvTemplate.defaultAcademicSessionId;
  }

  String? _programIdForTimetableSlot(TimetableSlot slot) {
    if (slot.programId != null && slot.programId!.isNotEmpty) {
      return slot.programId;
    }
    final sectionProgram = _programIdFromSection(slot.section);
    if (sectionProgram != null) return sectionProgram;
    return _programForName(slot.program)?.id;
  }

  String? _programIdForStudent(Student student) {
    final sectionProgram = _programIdFromSection(student.section);
    if (sectionProgram != null) return sectionProgram;
    return _programForName(student.program)?.id;
  }

  String? _programIdForDisciplineReport(DisciplineReport report) {
    if (report.programId != null && report.programId!.isNotEmpty) {
      return report.programId;
    }
    final sectionProgram = _programIdFromSection(report.section);
    if (sectionProgram != null) return sectionProgram;
    final student =
        students.where((student) => student.id == report.studentId).firstOrNull;
    if (student != null) return _programIdForStudent(student);
    return _programForName(report.programName)?.id;
  }

  String _normalizeDisciplineStatus(String status) {
    final normalized = status.trim().toLowerCase().replaceAll(' ', '_');
    return switch (normalized) {
      'new' ||
      'submitted' ||
      'pending' ||
      'menunggu' ||
      'menunggu_semakan' =>
        'pending',
      'under_review' || 'reviewed' || 'disemak' => 'reviewed',
      'approved' ||
      'resolved' ||
      'action_taken' ||
      'tindakan_diambil' =>
        'action_taken',
      'closed' || 'ditutup' => 'closed',
      'rejected' || 'ditolak' => 'rejected',
      _ => normalized,
    };
  }

  String? _programIdForBooking(BookingRequest booking) {
    if (booking.programId != null && booking.programId!.isNotEmpty) {
      return booking.programId;
    }
    final sectionProgram = _programIdFromSection(booking.section);
    if (sectionProgram != null) return sectionProgram;
    final matchingSlot =
        timetable.where((slot) => slot.section == booking.section).firstOrNull;
    return matchingSlot?.programId ??
        _programForName(matchingSlot?.program)?.id;
  }

  String? _programIdFromSection(String? section) {
    if (section == null || section.trim().isEmpty) return null;
    final sectionPrefix = section.trim().split(RegExp(r'\s+')).firstOrNull;
    if (programs.any((program) => program.id == sectionPrefix)) {
      return sectionPrefix;
    }
    return null;
  }

  int _weekNoForSlot(TimetableSlot slot) {
    final slotDate = DateTime.tryParse(slot.date);
    if (slotDate == null) return 1;

    final sessionId = slot.academicSessionId ?? slot.session;
    final academicSession = academicSessions
        .where((item) => item.academicSessionId == sessionId)
        .firstOrNull;
    final startDate = DateTime.tryParse(academicSession?.startDate ?? '');
    if (startDate == null) return 1;

    final calculated = (slotDate.difference(startDate).inDays ~/ 7) + 1;
    return calculated.clamp(1, 18).toInt();
  }
}
