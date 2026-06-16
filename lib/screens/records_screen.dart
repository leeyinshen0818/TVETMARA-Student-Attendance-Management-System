import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../widgets/app_layout.dart';
import '../widgets/status_chip.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final _searchController = TextEditingController();
  final _assignmentSearchController = TextEditingController();
  String _query = '';
  String _assignmentQuery = '';
  String? _programFilter;
  String? _classFilter;
  String? _assignmentProgramFilter;
  String? _assignmentClassFilter;
  String? _assignmentLecturerFilter;
  int? _semesterFilter;
  int? _attendanceThresholdFilter;
  bool _requestedRecordsLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestedRecordsLoad) return;
    _requestedRecordsLoad = true;
    final state = AppScope.of(context);
    Future.microtask(state.loadStudentRecordDataIfNeeded);
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
    _assignmentSearchController.addListener(() {
      setState(() => _assignmentQuery =
          _assignmentSearchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _assignmentSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.currentUser!;
    final isManagement = user.role == UserRole.ketua_jabatan ||
        user.role == UserRole.ketua_program;
    if (!isManagement) {
      return const PageHeader(
        title: 'Akses Tidak Dibenarkan',
        subtitle:
            'Hanya Ketua Jabatan dan Ketua Program boleh melihat rekod pelajar.',
      );
    }

    final isLoadingRecords = state.isCollectionLoading('students') ||
        state.isCollectionLoading('timetable') ||
        state.isCollectionLoading('lecturers') ||
        state.isCollectionLoading('sessionAttendance');
    if (!state.isStudentRecordDataLoaded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Rekod Pelajar & Pensyarah',
            subtitle:
                'Kedudukan kehadiran pelajar dan tugasan pensyarah-kursus.',
          ),
          AppPanel(
            title: 'Memuatkan Rekod Pelajar',
            subtitle:
                'Data pelajar dimuatkan apabila halaman ini dibuka supaya log masuk kekal pantas.',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: isLoadingRecords
                    ? const CircularProgressIndicator()
                    : FilledButton.icon(
                        onPressed: state.loadStudentRecordDataIfNeeded,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Muatkan Rekod'),
                      ),
              ),
            ),
          ),
        ],
      );
    }

    final scopedStudents = state.scopedStudents;
    final programOptions =
        _sorted(scopedStudents.map((student) => _studentProgramId(student)));
    final classOptions = _sorted(scopedStudents
        .where((student) =>
            _programFilter == null ||
            _studentProgramId(student) == _programFilter)
        .map((s) => s.section));
    final semesterOptions = scopedStudents.map((s) => s.semester).toSet()
      ..removeWhere((value) => value <= 0);
    final filteredStudents = scopedStudents.where((student) {
      final summary = state.attendanceSummaryForStudent(student);
      final haystack = [
        student.id,
        student.name,
        student.email,
        student.phone,
        student.program,
        student.section,
        _studentProgramId(student),
      ].join(' ').toLowerCase();
      if (_query.isNotEmpty && !haystack.contains(_query)) return false;
      if (_programFilter != null &&
          _studentProgramId(student) != _programFilter) {
        return false;
      }
      if (_classFilter != null && student.section != _classFilter) {
        return false;
      }
      if (_semesterFilter != null && student.semester != _semesterFilter) {
        return false;
      }
      if (_attendanceThresholdFilter != null &&
          summary.percentage >= _attendanceThresholdFilter!) {
        return false;
      }
      return true;
    }).toList();

    final assignments = state.scopedTimetable
        .where((slot) => _isOfficialAssignment(slot, state.session))
        .toList()
      ..sort(_compareAssignments);
    final assignmentProgramOptions =
        _sorted(assignments.map(_assignmentProgramId));
    final assignmentClassOptions = _sorted(assignments
        .where((slot) =>
            _assignmentProgramFilter == null ||
            _assignmentProgramId(slot) == _assignmentProgramFilter)
        .map((slot) => slot.section));
    final assignmentLecturerOptions =
        _sorted(assignments.map((slot) => slot.lecturerName));
    final filteredAssignments = assignments.where((slot) {
      final haystack = [
        slot.lecturerName,
        slot.lecturerEmail ?? '',
        slot.subjectCode,
        slot.subjectName,
        _assignmentProgramId(slot),
        slot.section,
        slot.dayOfWeek ?? slot.day,
        slot.roomName ?? slot.room,
      ].join(' ').toLowerCase();
      if (_assignmentQuery.isNotEmpty && !haystack.contains(_assignmentQuery)) {
        return false;
      }
      if (_assignmentProgramFilter != null &&
          _assignmentProgramId(slot) != _assignmentProgramFilter) {
        return false;
      }
      if (_assignmentClassFilter != null &&
          slot.section != _assignmentClassFilter) {
        return false;
      }
      if (_assignmentLecturerFilter != null &&
          slot.lecturerName != _assignmentLecturerFilter) {
        return false;
      }
      return true;
    }).toList();
    final assignmentGroups = _groupAssignments(filteredAssignments);
    final hasDraftScopedAssignments = state.scopedTimetable.any((slot) {
      final slotSession = slot.academicSessionId ?? slot.session;
      return slotSession == state.session && !slot.isOfficial;
    });
    final hasAnyScopedSessionSlots = state.scopedTimetable.any((slot) {
      final slotSession = slot.academicSessionId ?? slot.session;
      return slotSession == state.session;
    });
    final lecturerProfiles = {
      for (final lecturer in state.lecturers) lecturer.id: lecturer,
      for (final lecturer in state.lecturers)
        lecturer.email.toLowerCase(): lecturer,
    };
    final lecturerUsers = {
      for (final user in state.users.where((u) => u.role == UserRole.pensyarah))
        user.uid: user,
      for (final user in state.users.where((u) => u.role == UserRole.pensyarah))
        user.email.toLowerCase(): user,
      for (final user in state.users.where((u) =>
          u.role == UserRole.pensyarah &&
          (u.lecturerProfileId ?? '').isNotEmpty))
        user.lecturerProfileId!: user,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Rekod Pelajar & Pensyarah',
          subtitle: 'Kedudukan kehadiran pelajar dan tugasan pensyarah-kursus.',
          trailing: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusChip('${filteredStudents.length} pelajar'),
              OutlinedButton.icon(
                onPressed: state.refreshStudentRecordData,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Muat Semula'),
              ),
            ],
          ),
        ),
        AppPanel(
          title: 'Penapis Rekod Pelajar',
          subtitle: 'Cari dan tapis pelajar dalam skop anda sahaja.',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 260,
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Cari pelajar',
                    hintText: 'Nama, ID, email atau kelas',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              _filterDropdown<String>(
                label: 'Program',
                value: _programFilter,
                items: programOptions,
                labelFor: (value) => value,
                onChanged: (value) => setState(() {
                  _programFilter = value;
                  final nextClassOptions = _sorted(scopedStudents
                      .where((student) =>
                          value == null || _studentProgramId(student) == value)
                      .map((student) => student.section));
                  if (_classFilter != null &&
                      !nextClassOptions.contains(_classFilter)) {
                    _classFilter = null;
                  }
                }),
              ),
              _filterDropdown<String>(
                label: 'Kelas',
                value: _classFilter,
                items: classOptions,
                labelFor: (value) => value,
                onChanged: (value) => setState(() => _classFilter = value),
              ),
              _filterDropdown<int>(
                label: 'Semester',
                value: _semesterFilter,
                items: semesterOptions.toList()..sort(),
                labelFor: (value) => '$value',
                onChanged: (value) => setState(() => _semesterFilter = value),
              ),
              _filterDropdown<int>(
                label: 'Kehadiran',
                value: _attendanceThresholdFilter,
                items: const [95, 90, 85, 80],
                labelFor: (value) => 'Bawah $value%',
                emptyLabel: 'Semua Kehadiran',
                onChanged: (value) =>
                    setState(() => _attendanceThresholdFilter = value),
              ),
              OutlinedButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset Penapis'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppPanel(
          title: 'Rekod Pelajar',
          subtitle:
              'Senarai ringkas pelajar dalam skop anda. Maklumat penuh tersedia melalui butiran.',
          child: filteredStudents.isEmpty
              ? const _RecordsEmptyState()
              : AppDataTable(
                  columns: const [
                    DataColumn(label: Text('ID Pelajar')),
                    DataColumn(label: Text('Nama')),
                    DataColumn(label: Text('Program')),
                    DataColumn(label: Text('Kelas')),
                    DataColumn(label: Text('Semester')),
                    DataColumn(label: Text('Kehadiran %')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Tindakan')),
                  ],
                  rows: filteredStudents.map((student) {
                    final summary = state.attendanceSummaryForStudent(student);
                    return DataRow(cells: [
                      DataCell(Text(student.id)),
                      DataCell(Text(student.name)),
                      DataCell(Text(_studentProgramId(student))),
                      DataCell(Text(student.section)),
                      DataCell(Text('${student.semester}')),
                      DataCell(Text('${summary.percentage}%')),
                      DataCell(_AttendanceRiskChip(
                        label: _attendanceStatusLabel(summary.percentage),
                        color: _attendanceStatusColor(summary.percentage),
                      )),
                      DataCell(
                        TextButton.icon(
                          onPressed: () =>
                              _showStudentDetails(context, state, student),
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: const Text('Lihat Butiran'),
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
        ),
        const SizedBox(height: 20),
        AppPanel(
          title: 'Tugasan Pensyarah',
          subtitle:
              'Tugasan rasmi berdasarkan slot jadual sesi akademik dipilih.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 260,
                    child: TextField(
                      controller: _assignmentSearchController,
                      decoration: const InputDecoration(
                        labelText: 'Cari tugasan',
                        hintText: 'Pensyarah, kursus atau kelas',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  _filterDropdown<String>(
                    label: 'Program',
                    value: _assignmentProgramFilter,
                    items: assignmentProgramOptions,
                    labelFor: (value) => value,
                    onChanged: (value) => setState(() {
                      _assignmentProgramFilter = value;
                      final nextClassOptions = _sorted(assignments
                          .where((slot) =>
                              value == null ||
                              _assignmentProgramId(slot) == value)
                          .map((slot) => slot.section));
                      if (_assignmentClassFilter != null &&
                          !nextClassOptions.contains(_assignmentClassFilter)) {
                        _assignmentClassFilter = null;
                      }
                    }),
                  ),
                  _filterDropdown<String>(
                    label: 'Kelas',
                    value: _assignmentClassFilter,
                    items: assignmentClassOptions,
                    labelFor: (value) => value,
                    onChanged: (value) =>
                        setState(() => _assignmentClassFilter = value),
                  ),
                  _filterDropdown<String>(
                    label: 'Pensyarah',
                    value: _assignmentLecturerFilter,
                    items: assignmentLecturerOptions,
                    labelFor: (value) => value,
                    onChanged: (value) =>
                        setState(() => _assignmentLecturerFilter = value),
                  ),
                  OutlinedButton.icon(
                    onPressed: _resetAssignmentFilters,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset Tugasan'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (assignmentGroups.isEmpty)
                _AssignmentsEmptyState(
                  hasDraftSlots: hasDraftScopedAssignments,
                  hasAnySessionSlots: hasAnyScopedSessionSlots,
                )
              else
                AppDataTable(
                  columns: const [
                    DataColumn(label: Text('Pensyarah')),
                    DataColumn(label: Text('Kelas Diajar')),
                    DataColumn(label: Text('Kod Kursus')),
                    DataColumn(label: Text('Bilangan Tugasan')),
                    DataColumn(label: Text('Tindakan')),
                  ],
                  rows: assignmentGroups.map((group) {
                    return DataRow(cells: [
                      DataCell(Text(group.lecturerName)),
                      DataCell(Text(_compactList(group.classes))),
                      DataCell(Text(_compactList(group.subjectCodes))),
                      DataCell(Text('${group.slots.length}')),
                      DataCell(
                        TextButton.icon(
                          onPressed: () => _showAssignmentDetails(
                            context,
                            state,
                            group,
                            lecturerProfiles,
                            lecturerUsers,
                          ),
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: const Text('Lihat Butiran'),
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<String> _sorted(Iterable<String> values) {
    final set = values.where((value) => value.trim().isNotEmpty).toSet();
    return set.toList()..sort();
  }

  Widget _filterDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T value) labelFor,
    required ValueChanged<T?> onChanged,
    String? emptyLabel,
  }) {
    return SizedBox(
      width: 190,
      child: DropdownButtonFormField<T?>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          DropdownMenuItem<T?>(
            value: null,
            child: Text(emptyLabel ?? 'Semua $label'),
          ),
          ...items.map(
            (item) => DropdownMenuItem<T?>(
              value: item,
              child: Text(
                labelFor(item),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _query = '';
      _programFilter = null;
      _classFilter = null;
      _semesterFilter = null;
      _attendanceThresholdFilter = null;
      _searchController.clear();
    });
  }

  void _resetAssignmentFilters() {
    setState(() {
      _assignmentQuery = '';
      _assignmentProgramFilter = null;
      _assignmentClassFilter = null;
      _assignmentLecturerFilter = null;
      _assignmentSearchController.clear();
    });
  }

  bool _isOfficialAssignment(TimetableSlot slot, String selectedSession) {
    final slotSession = slot.academicSessionId ?? slot.session;
    final status = slot.status.toLowerCase();
    return slotSession == selectedSession &&
        slot.isOfficial &&
        status != 'inactive' &&
        status != 'cancelled' &&
        status != 'canceled';
  }

  int _compareAssignments(TimetableSlot a, TimetableSlot b) {
    final lecturerCompare = a.lecturerName.compareTo(b.lecturerName);
    if (lecturerCompare != 0) return lecturerCompare;
    final dayCompare = _dayOrder(a).compareTo(_dayOrder(b));
    if (dayCompare != 0) return dayCompare;
    final timeCompare = a.startTime.compareTo(b.startTime);
    if (timeCompare != 0) return timeCompare;
    return a.section.compareTo(b.section);
  }

  int _dayOrder(TimetableSlot slot) {
    return switch ((slot.dayOfWeek ?? slot.day).toLowerCase()) {
      'isnin' => 1,
      'selasa' => 2,
      'rabu' => 3,
      'khamis' => 4,
      'jumaat' => 5,
      'sabtu' => 6,
      'ahad' => 7,
      _ => 99,
    };
  }

  String _assignmentProgramId(TimetableSlot slot) {
    final programId = slot.programId?.trim();
    if (programId != null && programId.isNotEmpty) return programId;
    final sectionPrefix = slot.section.trim().split(RegExp(r'\s+')).first;
    if (sectionPrefix.isNotEmpty) return sectionPrefix;
    return slot.program;
  }

  String _assignmentSchedule(TimetableSlot slot) {
    final day = slot.dayOfWeek ?? slot.day;
    return '$day, ${slot.startTime}-${slot.endTime}';
  }

  String _assignmentWeek(TimetableSlot slot) {
    final start = slot.weekStart ?? 1;
    final end = slot.weekEnd ?? 18;
    return 'Minggu $start-$end';
  }

  String _studentProgramId(Student student) {
    final sectionPrefix = student.section.trim().split(RegExp(r'\s+')).first;
    return sectionPrefix.isNotEmpty ? sectionPrefix : student.program;
  }

  String _attendanceStatusLabel(int percentage) {
    if (percentage >= 95) return 'Selamat';
    if (percentage >= 90) return 'Bawah 95%';
    if (percentage >= 85) return 'Bawah 90%';
    if (percentage >= 80) return 'Bawah 85%';
    return 'Bawah 80%';
  }

  Color _attendanceStatusColor(int percentage) {
    if (percentage >= 95) return const Color(0xff15803d);
    if (percentage >= 90) return const Color(0xffb45309);
    if (percentage >= 85) return const Color(0xffc2410c);
    if (percentage >= 80) return const Color(0xffea580c);
    return const Color(0xffdc2626);
  }

  String _programFullName(AppState state, Student student) {
    final programId = _studentProgramId(student);
    final match =
        state.programs.where((program) => program.id == programId).firstOrNull;
    return match?.name ?? student.program;
  }

  List<_LecturerAssignmentGroup> _groupAssignments(
    List<TimetableSlot> slots,
  ) {
    final groups = <String, _LecturerAssignmentGroup>{};
    for (final slot in slots) {
      final key = _lecturerGroupKey(slot);
      groups.putIfAbsent(
        key,
        () => _LecturerAssignmentGroup(
          lecturerName: slot.lecturerName,
          lecturerId: slot.lecturerId,
          lecturerEmail: slot.lecturerEmail,
          lecturerProfileId: slot.lecturerProfileId,
          slots: <TimetableSlot>[],
        ),
      );
      groups[key]!.slots.add(slot);
    }

    final values = groups.values.toList()
      ..sort((a, b) => a.lecturerName.compareTo(b.lecturerName));
    for (final group in values) {
      group.slots.sort(_compareAssignments);
    }
    return values;
  }

  String _lecturerGroupKey(TimetableSlot slot) {
    final email = slot.lecturerEmail?.trim().toLowerCase();
    if (email != null && email.isNotEmpty) return 'email:$email';

    final profileId = slot.lecturerProfileId?.trim();
    if (profileId != null && profileId.isNotEmpty) return 'profile:$profileId';

    final lecturerId = slot.lecturerId.trim();
    if (lecturerId.isNotEmpty) return 'id:$lecturerId';

    return 'name:${slot.lecturerName.trim().toLowerCase()}';
  }

  String _compactList(List<String> values) {
    final unique = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    if (unique.isEmpty) return '-';
    if (unique.length <= 4) return unique.join(', ');
    return '${unique.take(4).join(', ')} +${unique.length - 4} lagi';
  }

  String _assignmentProgramLabel(AppState state, TimetableSlot slot) {
    final programId = _assignmentProgramId(slot);
    final program =
        state.programs.where((program) => program.id == programId).firstOrNull;
    return program == null ? programId : '$programId - ${program.name}';
  }

  void _showStudentDetails(
    BuildContext context,
    AppState state,
    Student student,
  ) {
    final summary = state.attendanceSummaryForStudent(student);
    final reports = state.scopedDisciplineReports
        .where((report) => report.studentId == student.id)
        .toList();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Butiran Pelajar'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StudentDetailRow(label: 'ID Pelajar', value: student.id),
                _StudentDetailRow(label: 'Nama', value: student.name),
                _StudentDetailRow(label: 'Email', value: student.email),
                _StudentDetailRow(label: 'Telefon', value: student.phone),
                _StudentDetailRow(
                    label: 'Program', value: _programFullName(state, student)),
                _StudentDetailRow(
                    label: 'Program ID', value: _studentProgramId(student)),
                _StudentDetailRow(label: 'Kelas', value: student.section),
                _StudentDetailRow(
                    label: 'Semester', value: '${student.semester}'),
                _StudentDetailRow(
                    label: 'Kehadiran',
                    value:
                        '${summary.percentage}% (${_attendanceStatusLabel(summary.percentage)})'),
                _StudentDetailRow(
                    label: 'Laporan Disiplin',
                    value: reports.isEmpty
                        ? 'Tiada rekod dalam skop semasa'
                        : '${reports.length} rekod'),
                _StudentDetailRow(
                  label: 'Rekod Kehadiran',
                  value:
                      'Hadir ${summary.present}, Lewat ${summary.late}, Tidak Hadir ${summary.absent}, MC ${summary.mc}, CK ${summary.ck}',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showAssignmentDetails(
    BuildContext context,
    AppState state,
    _LecturerAssignmentGroup group,
    Map<String, Lecturer> lecturerProfiles,
    Map<String, AppUser> lecturerUsers,
  ) {
    final lecturerEmailKey = group.lecturerEmail?.toLowerCase() ?? '';
    final lecturerUser = lecturerUsers[group.lecturerId] ??
        lecturerUsers[lecturerEmailKey] ??
        lecturerUsers[group.lecturerProfileId ?? ''];
    final lecturerProfile = lecturerProfiles[group.lecturerId] ??
        lecturerProfiles[lecturerEmailKey] ??
        lecturerProfiles[group.lecturerProfileId ?? ''];
    final lecturerEmail = group.lecturerEmail ??
        lecturerUser?.email ??
        lecturerProfile?.email ??
        '-';
    final lecturerId = group.lecturerProfileId ??
        lecturerProfile?.id ??
        (group.lecturerId.isNotEmpty ? group.lecturerId : '-');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Butiran Tugasan Pensyarah'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StudentDetailRow(
                    label: 'Nama Pensyarah', value: group.lecturerName),
                _StudentDetailRow(
                    label: 'Email Pensyarah', value: lecturerEmail),
                _StudentDetailRow(label: 'Lecturer ID', value: lecturerId),
                _StudentDetailRow(
                    label: 'Kelas Diajar', value: _compactList(group.classes)),
                _StudentDetailRow(
                    label: 'Kod Kursus',
                    value: _compactList(group.subjectCodes)),
                _StudentDetailRow(
                    label: 'Bilangan Tugasan', value: '${group.slots.length}'),
                const SizedBox(height: 16),
                const Text(
                  'Senarai Tugasan',
                  style: TextStyle(
                    color: Color(0xff0f172a),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                for (final slot in group.slots)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xfff8fafc),
                      border: Border.all(color: const Color(0xffe2e8f0)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        _StudentDetailRow(
                            label: 'Kod Kursus', value: slot.subjectCode),
                        _StudentDetailRow(
                            label: 'Nama Subjek', value: slot.subjectName),
                        _StudentDetailRow(
                            label: 'Program',
                            value: _assignmentProgramLabel(state, slot)),
                        _StudentDetailRow(label: 'Kelas', value: slot.section),
                        _StudentDetailRow(
                            label: 'Hari & Masa',
                            value: _assignmentSchedule(slot)),
                        _StudentDetailRow(
                            label: 'Bilik', value: slot.roomName ?? slot.room),
                        _StudentDetailRow(
                            label: 'Minggu', value: _assignmentWeek(slot)),
                        _StudentDetailRow(
                            label: 'Sesi Akademik',
                            value: slot.academicSessionId ?? slot.session),
                        _StudentDetailRow(
                            label: 'Status Slot',
                            value: _assignmentStatusLabel(slot)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  String _assignmentStatusLabel(TimetableSlot slot) {
    final status = slot.status.toLowerCase();
    if (slot.isOfficial && status == 'active') return 'Rasmi';
    if (status == 'inactive') return 'Tidak Aktif';
    if (status == 'cancelled' || status == 'canceled') return 'Dibatalkan';
    return slot.status;
  }
}

class _LecturerAssignmentGroup {
  _LecturerAssignmentGroup({
    required this.lecturerName,
    required this.lecturerId,
    required this.lecturerEmail,
    required this.lecturerProfileId,
    required this.slots,
  });

  final String lecturerName;
  final String lecturerId;
  final String? lecturerEmail;
  final String? lecturerProfileId;
  final List<TimetableSlot> slots;

  List<String> get classes => slots.map((slot) => slot.section).toList();

  List<String> get subjectCodes =>
      slots.map((slot) => slot.subjectCode).toList();
}

class _AttendanceRiskChip extends StatelessWidget {
  const _AttendanceRiskChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StudentDetailRow extends StatelessWidget {
  const _StudentDetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xff64748b),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: Color(0xff0f172a),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentsEmptyState extends StatelessWidget {
  const _AssignmentsEmptyState({
    required this.hasDraftSlots,
    required this.hasAnySessionSlots,
  });

  final bool hasDraftSlots;
  final bool hasAnySessionSlots;

  @override
  Widget build(BuildContext context) {
    final message = hasDraftSlots
        ? 'Tiada tugasan pensyarah rasmi untuk sesi ini. Sila terbitkan jadual terlebih dahulu.'
        : hasAnySessionSlots
            ? 'Tiada tugasan rasmi sepadan dengan penapis semasa.'
            : 'Tiada tugasan pensyarah rasmi untuk sesi akademik dipilih.';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xff64748b),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RecordsEmptyState extends StatelessWidget {
  const _RecordsEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Text(
          'Tiada rekod pelajar ditemui untuk penapis semasa.',
          style: TextStyle(
            color: Color(0xff64748b),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
