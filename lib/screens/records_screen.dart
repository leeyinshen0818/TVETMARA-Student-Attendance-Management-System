// lib/screens/records_screen.dart
//
// Module M5 – Phase 2: Upgraded Ketua Rekod Pelajar
//
// Features:
//   • Strict data scoping via AppState.scopedStudents (KJ = dept, KP = programme)
//   • Search bar (Name / Student ID)
//   • Dropdown filters: Programme, Class/Section, Semester, Status, Attendance Risk
//   • Attendance progress bar per student row
//   • "Lihat Butiran" dialog: weekly W1–W18 grid + discipline log + risk warning
//
// All user-facing labels and status chips are in Malay.
// No hardcoded dummy data — all values come from AppState.

import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../widgets/app_layout.dart';
import '../widgets/app_theme.dart';
import '../widgets/mobile_components.dart';
import '../widgets/responsive.dart';
import '../widgets/status_chip.dart';

// ─── Colour tokens (match existing app palette) ──────────────────────────────

const _kBg     = Color(0xFFF7F9FB);
const _kCard   = Colors.white;
const _kBorder = Color(0xFFE2E8EF);
const _kText   = Color(0xFF1A2E3F);
const _kMuted  = Color(0xFF5C7A8A);
const _kTeal   = Color(0xFF1B8CA6);
const _kGreen  = Color(0xFF16A34A);
const _kAmber  = Color(0xFFD97706);
const _kRed    = Color(0xFFDC2626);

// ─── Entry point ─────────────────────────────────────────────────────────────

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  String _search        = '';
  String _filterProgram = 'Semua Program';
  String _filterClass   = 'Semua Kelas';
  String _filterSem     = 'Semua Semester';
  String _filterStatus  = 'Semua Status';
  String _filterRisk    = 'Semua Risiko';

  static const _riskDropdownItems = [
    'Semua Risiko', 'Selamat', 'Amaran', 'Kritikal',
  ];

  static const _riskToInternal = {
    'Selamat': 'Safe', 'Amaran': 'Warning', 'Kritikal': 'Critical',
  };

  static String _riskLabel(String internal) => switch (internal) {
        'Critical' => 'Kritikal',
        'Warning'  => 'Amaran',
        _          => 'Selamat',
      };

  static Color _riskColour(String internal) => switch (internal) {
        'Critical' => _kRed,
        'Warning'  => _kAmber,
        _          => _kGreen,
      };

  List<Student> _applyFilters(List<Student> all, AppState state) {
    return all.where((s) {
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        if (!s.name.toLowerCase().contains(q) &&
            !s.id.toLowerCase().contains(q)) return false;
      }
      if (_filterProgram != 'Semua Program' && s.program != _filterProgram) {
        return false;
      }
      if (_filterClass != 'Semua Kelas' && s.section != _filterClass) {
        return false;
      }
      if (_filterSem != 'Semua Semester' &&
          s.semester.toString() != _filterSem) return false;
      if (_filterStatus == 'Aktif' && !s.active) return false;
      if (_filterStatus == 'Tidak Aktif' && s.active) return false;
      if (_filterRisk != 'Semua Risiko') {
        final internal = _riskToInternal[_filterRisk] ?? _filterRisk;
        if (state.attendanceRiskForStudent(s) != internal) return false;
      }
      return true;
    }).toList();
  }

  bool get _hasActiveFilter =>
      _search.isNotEmpty ||
      _filterProgram != 'Semua Program' ||
      _filterClass   != 'Semua Kelas'   ||
      _filterSem     != 'Semua Semester' ||
      _filterStatus  != 'Semua Status'  ||
      _filterRisk    != 'Semua Risiko';

  void _clearFilters() => setState(() {
        _search = _filterProgram = _filterClass =
            _filterSem = _filterStatus = _filterRisk = '';
        _filterProgram = 'Semua Program';
        _filterClass   = 'Semua Kelas';
        _filterSem     = 'Semua Semester';
        _filterStatus  = 'Semua Status';
        _filterRisk    = 'Semua Risiko';
        _search        = '';
      });

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user  = state.currentUser!;
    final isAdmin = user.role == UserRole.pentadbir;
    final isManagement = user.role == UserRole.ketua_jabatan ||
        user.role == UserRole.ketua_program;

    if (!isAdmin && !isManagement) {
      return const PageHeader(
        title: 'Akses Tidak Dibenarkan',
        subtitle: 'Hanya Pentadbir, Ketua Jabatan dan Ketua Program boleh melihat rekod pelajar.',
      );
    }

    final allStudents = state.scopedStudents;
    final filtered    = _applyFilters(allStudents, state);

    final programSet  = <String>{};
    final classSet    = <String>{};
    final semSet      = <String>{};
    for (final s in allStudents) {
      programSet.add(s.program);
      classSet.add(s.section);
      semSet.add(s.semester.toString());
    }
    final programs  = ['Semua Program',  ...programSet.toList()..sort()];
    final classes   = ['Semua Kelas',    ...classSet.toList()..sort()];
    final semesters = ['Semua Semester', ...semSet.toList()..sort()];

    final scopeLabel = switch (user.role) {
      UserRole.ketua_jabatan => 'Jabatan ${user.departmentId ?? ''}',
      UserRole.ketua_program => 'Program ${user.programId ?? ''}',
      _                      => 'Semua Program',
    };

    final criticalCount = allStudents
        .where((s) => state.attendanceRiskForStudent(s) == 'Critical')
        .length;

    if (context.isMobile) {
      return _buildMobileRecords(
        context: context,
        state: state,
        allStudents: allStudents,
        filtered: filtered,
        scopeLabel: scopeLabel,
        criticalCount: criticalCount,
        programs: programs,
        classes: classes,
        semesters: semesters,
      );
    }

    return ColoredBox(
      color: _kBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PageBanner(
            scopeLabel: scopeLabel,
            totalStudents: allStudents.length,
            criticalCount: criticalCount,
            threshold: state.attendanceThreshold,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: _FilterBar(
              search:          _search,
              filterProgram:   _filterProgram,
              filterClass:     _filterClass,
              filterSem:       _filterSem,
              filterStatus:    _filterStatus,
              filterRisk:      _filterRisk,
              programOptions:  programs,
              classOptions:    classes,
              semesterOptions: semesters,
              riskOptions:     _riskDropdownItems,
              hasActiveFilter: _hasActiveFilter,
              onSearchChanged:  (v) => setState(() => _search        = v),
              onProgramChanged: (v) => setState(() { _filterProgram = v; _filterClass = 'Semua Kelas'; }),
              onClassChanged:   (v) => setState(() => _filterClass   = v),
              onSemChanged:     (v) => setState(() => _filterSem     = v),
              onStatusChanged:  (v) => setState(() => _filterStatus  = v),
              onRiskChanged:    (v) => setState(() => _filterRisk    = v),
              onClear:          _clearFilters,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: AppPanel(
              title: 'Rekod Pelajar',
              subtitle: 'Had kehadiran: ${state.attendanceThreshold}% · '
                  'Menunjukkan ${filtered.length} daripada ${allStudents.length} pelajar ($scopeLabel)',
              trailing: filtered.isEmpty ? null : StatusChip('${filtered.length} pelajar'),
              child: _StudentTable(
                students: filtered,
                state: state,
                riskLabel: _riskLabel,
                riskColour: _riskColour,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileRecords({
    required BuildContext context,
    required AppState state,
    required List<Student> allStudents,
    required List<Student> filtered,
    required String scopeLabel,
    required int criticalCount,
    required List<String> programs,
    required List<String> classes,
    required List<String> semesters,
  }) {
    final below95 = allStudents
        .where((student) =>
            state.attendanceSummaryForStudent(student).percentage < 95)
        .length;
    final below90 = allStudents
        .where((student) =>
            state.attendanceSummaryForStudent(student).percentage < 90)
        .length;
    final below80 = allStudents
        .where((student) =>
            state.attendanceSummaryForStudent(student).percentage < 80)
        .length;
    final assignments = _mobileAssignmentGroups(state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MobileHeroCard(
          icon: Icons.people_outline_rounded,
          title: 'Rekod Pelajar',
          subtitle: 'Semak pelajar dan tugasan pensyarah mengikut skop anda.',
          chips: [
            StatusChip(scopeLabel),
            StatusChip('${allStudents.length} Pelajar'),
            StatusChip('Had ${state.attendanceThreshold}%'),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: 158,
              child: MobileStatCard(
                icon: Icons.group_outlined,
                value: '${allStudents.length}',
                label: 'Jumlah Pelajar',
                color: AppColors.primary,
              ),
            ),
            SizedBox(
              width: 158,
              child: MobileStatCard(
                icon: Icons.warning_amber_rounded,
                value: '$below95',
                label: 'Bawah 95%',
                color: AppColors.warning,
              ),
            ),
            SizedBox(
              width: 158,
              child: MobileStatCard(
                icon: Icons.trending_down_rounded,
                value: '$below90',
                label: 'Bawah 90%',
                color: const Color(0xffea580c),
              ),
            ),
            SizedBox(
              width: 158,
              child: MobileStatCard(
                icon: Icons.dangerous_outlined,
                value: '$below80',
                label: 'Bawah 80%',
                color: AppColors.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        MobileFilterCard(
          subtitle:
              'Cari pelajar dan tapis mengikut program, kelas dan risiko.',
          onReset: _hasActiveFilter ? _clearFilters : null,
          children: [
            _SearchField(onChanged: (v) => setState(() => _search = v)),
            _Dropdown(
              label: 'Program',
              value: _filterProgram,
              options: programs,
              onChanged: (v) => setState(() {
                _filterProgram = v;
                _filterClass = 'Semua Kelas';
              }),
            ),
            _Dropdown(
              label: 'Kelas',
              value: _filterClass,
              options: classes,
              onChanged: (v) => setState(() => _filterClass = v),
            ),
            _Dropdown(
              label: 'Semester',
              value: _filterSem,
              options: semesters,
              onChanged: (v) => setState(() => _filterSem = v),
            ),
            _Dropdown(
              label: 'Risiko Kehadiran',
              value: _filterRisk,
              options: _riskDropdownItems,
              onChanged: (v) => setState(() => _filterRisk = v),
            ),
          ],
        ),
        const SizedBox(height: 14),
        MobileSection(
          title: 'Senarai Pelajar',
          subtitle:
              '${filtered.length} daripada ${allStudents.length} pelajar dipaparkan.',
          child: filtered.isEmpty
              ? const MobileEmptyState(
                  icon: Icons.search_off_outlined,
                  title: 'Tiada rekod pelajar',
                  subtitle: 'Cuba ubah carian atau reset penapis.',
                )
              : Column(
                  children: [
                    for (final student in filtered) ...[
                      _MobileStudentCard(
                        student: student,
                        state: state,
                        statusLabel: _mobileAttendanceStatusLabel,
                        statusColor: _mobileAttendanceStatusColor,
                        onTap: () =>
                            _showMobileStudentDetails(context, state, student),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 14),
        MobileSection(
          title: 'Tugasan Pensyarah',
          subtitle: '${assignments.length} pensyarah dalam skop semasa.',
          child: assignments.isEmpty
              ? const MobileEmptyState(
                  icon: Icons.person_off_outlined,
                  title: 'Tiada tugasan pensyarah',
                  subtitle: 'Tiada jadual rasmi dalam sesi semasa.',
                )
              : Column(
                  children: [
                    for (final group in assignments) ...[
                      _MobileLecturerAssignmentCard(
                        group: group,
                        compactList: _mobileCompactList,
                        onTap: () => _showMobileAssignmentDetails(
                          context,
                          state,
                          group,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  List<_LecturerAssignmentGroup> _mobileAssignmentGroups(AppState state) {
    final selectedSession = state.session;
    final slots = state.scopedTimetable.where((slot) {
      final slotSession = slot.academicSessionId ?? slot.session;
      final status = slot.status.toLowerCase();
      return slotSession == selectedSession &&
          slot.isOfficial &&
          status != 'inactive' &&
          status != 'cancelled' &&
          status != 'canceled';
    }).toList()
      ..sort(_mobileCompareAssignments);

    final groups = <String, _LecturerAssignmentGroup>{};
    for (final slot in slots) {
      final key = _mobileLecturerGroupKey(slot);
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
    return groups.values.toList()
      ..sort((a, b) => a.lecturerName.compareTo(b.lecturerName));
  }

  String _mobileLecturerGroupKey(TimetableSlot slot) {
    final email = slot.lecturerEmail?.trim().toLowerCase();
    if (email != null && email.isNotEmpty) return 'email:$email';
    final profileId = slot.lecturerProfileId?.trim();
    if (profileId != null && profileId.isNotEmpty) return 'profile:$profileId';
    if (slot.lecturerId.trim().isNotEmpty) return 'id:${slot.lecturerId}';
    return 'name:${slot.lecturerName.trim().toLowerCase()}';
  }

  int _mobileCompareAssignments(TimetableSlot a, TimetableSlot b) {
    final lecturerCompare = a.lecturerName.compareTo(b.lecturerName);
    if (lecturerCompare != 0) return lecturerCompare;
    final classCompare = a.section.compareTo(b.section);
    if (classCompare != 0) return classCompare;
    return a.startTime.compareTo(b.startTime);
  }

  String _mobileCompactList(Iterable<String> values) {
    final unique = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    if (unique.isEmpty) return '-';
    if (unique.length <= 3) return unique.join(', ');
    return '${unique.take(3).join(', ')} +${unique.length - 3} lagi';
  }

  String _mobileStudentProgramId(Student student) {
    final prefix = student.section.trim().split(RegExp(r'\s+')).first;
    return prefix.isNotEmpty ? prefix : student.program;
  }

  String _mobileAttendanceStatusLabel(int percentage) {
    if (percentage >= 95) return 'Selamat';
    if (percentage >= 90) return 'Bawah 95%';
    if (percentage >= 85) return 'Bawah 90%';
    if (percentage >= 80) return 'Bawah 85%';
    return 'Bawah 80%';
  }

  Color _mobileAttendanceStatusColor(int percentage) {
    if (percentage >= 95) return AppColors.success;
    if (percentage >= 90) return AppColors.warning;
    if (percentage >= 85) return const Color(0xffc2410c);
    if (percentage >= 80) return const Color(0xffea580c);
    return AppColors.danger;
  }

  void _showMobileStudentDetails(
    BuildContext context,
    AppState state,
    Student student,
  ) {
    final summary = state.attendanceSummaryForStudent(student);
    final reports = state.scopedDisciplineReports
        .where((report) => report.studentId == student.id)
        .toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => MobileBottomSheet(
        title: 'Butiran Pelajar',
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * .72,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _StudentDetailRow(label: 'ID Pelajar', value: student.id),
                _StudentDetailRow(label: 'Nama', value: student.name),
                _StudentDetailRow(label: 'Email', value: student.email),
                _StudentDetailRow(label: 'Telefon', value: student.phone),
                _StudentDetailRow(
                    label: 'Program', value: _mobileStudentProgramId(student)),
                _StudentDetailRow(label: 'Kelas', value: student.section),
                _StudentDetailRow(
                    label: 'Semester', value: '${student.semester}'),
                _StudentDetailRow(
                  label: 'Kehadiran',
                  value:
                      '${summary.percentage}% (${_mobileAttendanceStatusLabel(summary.percentage)})',
                ),
                _StudentDetailRow(
                  label: 'Laporan Disiplin',
                  value: reports.isEmpty ? 'Tiada rekod' : '${reports.length}',
                ),
                _StudentDetailRow(
                  label: 'Rekod Kehadiran',
                  value:
                      'Hadir ${summary.present}, Lewat ${summary.late}, Tidak Hadir ${summary.absent}, MC ${summary.mc}, CK ${summary.ck}',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMobileAssignmentDetails(
    BuildContext context,
    AppState state,
    _LecturerAssignmentGroup group,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => MobileBottomSheet(
        title: 'Butiran Tugasan Pensyarah',
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * .72,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _StudentDetailRow(
                    label: 'Nama Pensyarah', value: group.lecturerName),
                _StudentDetailRow(
                    label: 'Email', value: group.lecturerEmail ?? '-'),
                _StudentDetailRow(
                    label: 'Kelas Diajar',
                    value: _mobileCompactList(group.classes)),
                _StudentDetailRow(
                    label: 'Kod Kursus',
                    value: _mobileCompactList(group.subjectCodes)),
                _StudentDetailRow(
                    label: 'Bilangan Tugasan', value: '${group.slots.length}'),
                const SizedBox(height: 12),
                for (final slot in group.slots)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: MobileInfoCard(
                      title: '${slot.subjectCode} - ${slot.subjectName}',
                      subtitle:
                          '${slot.section} - ${slot.day} ${slot.startTime}-${slot.endTime}',
                      metadata: [
                        MobileMetaPill(
                          icon: Icons.school_outlined,
                          label: slot.programId ?? slot.program,
                        ),
                        MobileMetaPill(
                          icon: Icons.meeting_room_outlined,
                          label: slot.roomName ?? slot.room,
                        ),
                        MobileMetaPill(
                          icon: Icons.event_outlined,
                          label: slot.academicSessionId ?? slot.session,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileStudentCard extends StatelessWidget {
  const _MobileStudentCard({
    required this.student,
    required this.state,
    required this.statusLabel,
    required this.statusColor,
    required this.onTap,
  });

  final Student student;
  final AppState state;
  final String Function(int percentage) statusLabel;
  final Color Function(int percentage) statusColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final summary = state.attendanceSummaryForStudent(student);
    final color = statusColor(summary.percentage);
    final programCode = student.section.trim().split(RegExp(r'\s+')).first;
    return MobileInfoCard(
      leadingIcon: Icons.person_outline,
      title: student.name,
      subtitle: '${student.id} - ${student.section}',
      chips: [
        _AttendanceRiskChip(
          label: statusLabel(summary.percentage),
          color: color,
        ),
      ],
      metadata: [
        MobileMetaPill(
          icon: Icons.school_outlined,
          label: programCode.isEmpty ? student.program : programCode,
        ),
        MobileMetaPill(
          icon: Icons.layers_outlined,
          label: 'Semester ${student.semester}',
        ),
        MobileMetaPill(
          icon: Icons.percent_outlined,
          label: '${summary.percentage}% Kehadiran',
          color: color,
        ),
        MobileMetaPill(
          icon: Icons.event_available_outlined,
          label: '${summary.attended}/${summary.denominator} sesi',
        ),
      ],
      actions: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: (summary.percentage / 100).clamp(0, 1).toDouble(),
          minHeight: 7,
          backgroundColor: color.withValues(alpha: .14),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
      onTap: onTap,
    );
  }
}

class _MobileLecturerAssignmentCard extends StatelessWidget {
  const _MobileLecturerAssignmentCard({
    required this.group,
    required this.compactList,
    required this.onTap,
  });

  final _LecturerAssignmentGroup group;
  final String Function(Iterable<String> values) compactList;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MobileInfoCard(
      leadingIcon: Icons.co_present_outlined,
      title: group.lecturerName,
      subtitle: group.lecturerEmail ?? 'Pensyarah dalam skop semasa',
      chips: [StatusChip('${group.slots.length} Tugasan')],
      metadata: [
        MobileMetaPill(
          icon: Icons.groups_outlined,
          label: compactList(group.classes),
        ),
        MobileMetaPill(
          icon: Icons.menu_book_outlined,
          label: compactList(group.subjectCodes),
        ),
      ],
      actions: Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.visibility_outlined, size: 18),
          label: const Text('Lihat Butiran'),
        ),
      ),
      onTap: onTap,
    );
  }
}

// ─── Page banner ─────────────────────────────────────────────────────────────

class _PageBanner extends StatelessWidget {
  const _PageBanner({
    required this.scopeLabel,
    required this.totalStudents,
    required this.criticalCount,
    required this.threshold,
  });
  final String scopeLabel;
  final int totalStudents;
  final int criticalCount;
  final int threshold;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kCard,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.people_outline_rounded, size: 26, color: _kTeal),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rekod Pelajar',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _kText)),
                    const SizedBox(height: 3),
                    Text(
                      'Paparan kehadiran dan status pelajar — $scopeLabel sahaja.',
                      style: const TextStyle(fontSize: 13, color: _kMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _StatCard(
                icon: Icons.group_outlined,
                label: 'Jumlah Pelajar',
                value: '$totalStudents',
                color: _kTeal,
              ),
              const SizedBox(width: 12),
              _StatCard(
                icon: Icons.warning_amber_rounded,
                label: 'Risiko Kritikal',
                value: '$criticalCount',
                color: criticalCount > 0 ? _kRed : _kGreen,
              ),
              const SizedBox(width: 12),
              _StatCard(
                icon: Icons.bar_chart_rounded,
                label: 'Had Kehadiran',
                value: '$threshold%',
                color: _kAmber,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color,
                          letterSpacing: 0.3)),
                  Text(value,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: color,
                          height: 1.1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Filter bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.search,
    required this.filterProgram,
    required this.filterClass,
    required this.filterSem,
    required this.filterStatus,
    required this.filterRisk,
    required this.programOptions,
    required this.classOptions,
    required this.semesterOptions,
    required this.riskOptions,
    required this.hasActiveFilter,
    required this.onSearchChanged,
    required this.onProgramChanged,
    required this.onClassChanged,
    required this.onSemChanged,
    required this.onStatusChanged,
    required this.onRiskChanged,
    required this.onClear,
  });

  final String search;
  final String filterProgram;
  final String filterClass;
  final String filterSem;
  final String filterStatus;
  final String filterRisk;
  final List<String> programOptions;
  final List<String> classOptions;
  final List<String> semesterOptions;
  final List<String> riskOptions;
  final bool         hasActiveFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onProgramChanged;
  final ValueChanged<String> onClassChanged;
  final ValueChanged<String> onSemChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onRiskChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _SearchField(onChanged: onSearchChanged)),
              if (hasActiveFilter) ...[
                const SizedBox(width: 10),
                TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 15),
                  label: const Text('Padam Penapis',
                      style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: _kMuted),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, c) {
            final isWide = c.maxWidth > 680;
            final drops = [
              _Dropdown(label: 'Program',  value: filterProgram, options: programOptions,  onChanged: onProgramChanged),
              _Dropdown(label: 'Kelas',    value: filterClass,   options: classOptions,    onChanged: onClassChanged),
              _Dropdown(label: 'Semester', value: filterSem,     options: semesterOptions, onChanged: onSemChanged),
              _Dropdown(
                label: 'Status',
                value: filterStatus,
                options: const ['Semua Status', 'Aktif', 'Tidak Aktif'],
                onChanged: onStatusChanged,
              ),
              _Dropdown(label: 'Risiko',   value: filterRisk,    options: riskOptions,     onChanged: onRiskChanged),
            ];
            if (isWide) {
              return Row(
                children: drops
                    .map((w) => Expanded(
                          child: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: w),
                        ))
                    .toList(),
              );
            }
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: drops.map((w) => SizedBox(width: 180, child: w)).toList(),
            );
          }),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13, color: _kText),
        decoration: InputDecoration(
          hintText: 'Cari nama atau ID pelajar…',
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBDD0DA)),
          prefixIcon: const Icon(Icons.search_rounded, size: 17, color: _kMuted),
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: _kCard,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: _kBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: _kTeal),
          ),
        ),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final safeValue = options.contains(value) ? value : options.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: _kMuted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: _kBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: safeValue,
              isExpanded: true,
              isDense: true,
              style: const TextStyle(
                  fontSize: 12, color: _kText, fontWeight: FontWeight.w500),
              items: options
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: (v) => onChanged(v ?? options.first),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Student table ────────────────────────────────────────────────────────────

class _StudentTable extends StatelessWidget {
  const _StudentTable({
    required this.students,
    required this.state,
    required this.riskLabel,
    required this.riskColour,
  });

  final List<Student>            students;
  final AppState                 state;
  final String Function(String)  riskLabel;
  final Color  Function(String)  riskColour;

  @override
  Widget build(BuildContext context) {
    return AppDataTable(
      columns: const [
        DataColumn(label: Text('ID Pelajar')),
        DataColumn(label: Text('Nama Pelajar')),
        DataColumn(label: Text('Program')),
        DataColumn(label: Text('Kelas')),
        DataColumn(label: Text('Sem')),
        DataColumn(label: Text('Kehadiran')),
        DataColumn(label: Text('Risiko')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Tindakan')),
      ],
      rows: students.map((s) {
        final summary = state.attendanceSummaryForStudent(s);
        final risk    = state.attendanceRiskForStudent(s);
        final pct     = summary.percentage;
        final colour  = riskColour(risk);

        return DataRow(cells: [
          DataCell(Text(s.id,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kMuted))),
          DataCell(Text(s.name,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _kText))),
          DataCell(Text(s.program,
              style: const TextStyle(fontSize: 12, color: _kText))),
          DataCell(Text(s.section,
              style: const TextStyle(fontSize: 12, color: _kText))),
          DataCell(Text('${s.semester}',
              style: const TextStyle(fontSize: 12, color: _kText))),
          // Attendance progress bar + fraction
          DataCell(SizedBox(
            width: 130,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$pct%',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colour)),
                    Text('${summary.attended}/${summary.denominator}',
                        style: const TextStyle(
                            fontSize: 10, color: _kMuted)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 7,
                    backgroundColor: colour.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(colour),
                  ),
                ),
              ],
            ),
          )),
          DataCell(StatusChip(riskLabel(risk))),
          DataCell(StatusChip(s.active ? 'Aktif' : 'Tidak Aktif')),
          DataCell(_LihatButiranButton(student: s, state: state)),
        ]);
      }).toList(),
    );
  }
}

// ─── Lihat Butiran button ─────────────────────────────────────────────────────

class _LihatButiranButton extends StatelessWidget {
  const _LihatButiranButton({required this.student, required this.state});
  final Student  student;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => _StudentDetailDialog(student: student, state: state),
      ),
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _kTeal.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: _kTeal.withValues(alpha: 0.35)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search_outlined, size: 13, color: _kTeal),
            SizedBox(width: 5),
            Text('Lihat Butiran',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _kTeal)),
          ],
        ),
      ),
    );
  }
}

// ─── Student Detail Dialog ────────────────────────────────────────────────────

class _StudentDetailDialog extends StatelessWidget {
  const _StudentDetailDialog({required this.student, required this.state});
  final Student  student;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final summary    = state.attendanceSummaryForStudent(student);
    final risk       = state.attendanceRiskForStudent(student);
    final weekly     = state.weeklyAttendanceForStudent(student);
    final riskColour = _RecordsScreenState._riskColour(risk);
    final riskMalay  = _RecordsScreenState._riskLabel(risk);

    final disciplineLogs = state.scopedDisciplineReports
        .where((r) => r.studentId == student.id)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final warnings = <String>[];
    if (summary.percentage < state.attendanceThreshold) {
      warnings.add(
          'Kehadiran ${summary.percentage}% adalah di bawah had '
          '${state.attendanceThreshold}%. Tindakan segera diperlukan.');
    }
    if (summary.absent >= 3) {
      warnings.add(
          'Pelajar telah tidak hadir ${summary.absent} kali.');
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780, maxHeight: 720),
        child: Container(
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              _DialogHeader(
                student:    student,
                summary:    summary,
                riskMalay:  riskMalay,
                riskColour: riskColour,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (warnings.isNotEmpty) ...[
                        ...warnings.map((w) => _WarningBanner(message: w)),
                        const SizedBox(height: 16),
                      ],
                      const _SectionTitle(
                        icon: Icons.calendar_month_outlined,
                        label: 'Ringkasan Kehadiran Mingguan (W1 – W18)',
                      ),
                      const SizedBox(height: 10),
                      _WeeklyGrid(weekly: weekly),
                      const SizedBox(height: 20),
                      _SectionTitle(
                        icon: Icons.gavel_rounded,
                        label: 'Log Disiplin (${disciplineLogs.length})',
                      ),
                      const SizedBox(height: 10),
                      if (disciplineLogs.isEmpty)
                        const _EmptyInSection(
                            message: 'Tiada rekod disiplin dijumpai.')
                      else
                        ...disciplineLogs
                            .map((r) => _DisciplineTile(report: r)),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(
                      top: BorderSide(color: _kBorder)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                          foregroundColor: _kMuted),
                      child: const Text('Tutup'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Dialog header ────────────────────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    required this.student,
    required this.summary,
    required this.riskMalay,
    required this.riskColour,
  });
  final Student           student;
  final AttendanceSummary summary;
  final String            riskMalay;
  final Color             riskColour;

  @override
  Widget build(BuildContext context) {
    final pct = summary.percentage;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: riskColour.withValues(alpha: 0.05),
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(14)),
        border: Border(
            bottom:
                BorderSide(color: riskColour.withValues(alpha: 0.2))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar initial
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: riskColour.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                  color: riskColour.withValues(alpha: 0.4), width: 2),
            ),
            child: Center(
              child: Text(
                student.name.isNotEmpty
                    ? student.name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: riskColour),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        student.name,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _kText),
                      ),
                    ),
                    StatusChip(riskMalay),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    _InfoPill(Icons.badge_outlined, student.id),
                    _InfoPill(Icons.school_outlined, student.program),
                    _InfoPill(Icons.groups_outlined, student.section),
                    _InfoPill(Icons.layers_outlined,
                        'Semester ${student.semester}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$pct%',
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: riskColour)),
              Text('Kehadiran',
                  style: const TextStyle(
                      fontSize: 11, color: _kMuted)),
              Text(
                  '${summary.attended}/${summary.denominator} sesi',
                  style: const TextStyle(
                      fontSize: 10, color: _kMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill(this.icon, this.text);
  final IconData icon;
  final String   text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: _kMuted),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: _kMuted)),
      ],
    );
  }
}

// ─── Warning banner ───────────────────────────────────────────────────────────

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kRed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kRed.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 16, color: _kRed),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kRed)),
          ),
        ],
      ),
    );
  }
}

// ─── Section title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});
  final IconData icon;
  final String   label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: _kTeal),
        const SizedBox(width: 7),
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _kText)),
      ],
    );
  }
}

// ─── Weekly grid W1–W18 ───────────────────────────────────────────────────────

class _WeeklyGrid extends StatelessWidget {
  const _WeeklyGrid({required this.weekly});
  final List<AttendanceSummary> weekly;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(18, (i) {
        final w       = weekly[i];
        final pct     = w.percentage;
        final hasData = w.denominator > 0;
        final colour  = !hasData
            ? const Color(0xFFE2E8EF)
            : pct >= 80
                ? _kGreen
                : pct >= 75
                    ? _kAmber
                    : _kRed;

        return Tooltip(
          message: hasData
              ? 'W${i + 1}: $pct%  (Hadir ${w.attended}/${w.denominator})'
              : 'W${i + 1}: Tiada data',
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colour.withValues(alpha: hasData ? 0.12 : 0.5),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                  color: colour.withValues(
                      alpha: hasData ? 0.4 : 0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('W${i + 1}',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: hasData ? colour : _kMuted)),
                Text(hasData ? '$pct%' : '—',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: hasData ? colour : _kMuted)),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ─── Empty in section ─────────────────────────────────────────────────────────

class _EmptyInSection extends StatelessWidget {
  const _EmptyInSection({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 28, color: Color(0xFF94A3B8)),
          const SizedBox(height: 6),
          Text(message,
              style: const TextStyle(fontSize: 12, color: _kMuted)),
        ],
      ),
    );
  }
}

// ─── Discipline log tile ──────────────────────────────────────────────────────

class _DisciplineTile extends StatelessWidget {
  const _DisciplineTile({required this.report});
  final DisciplineReport report;

  Color get _sevColour => switch (report.severity.toLowerCase()) {
        'high' || 'tinggi'      => _kRed,
        'medium' || 'sederhana' => _kAmber,
        _                       => _kTeal,
      };

  String get _sevMalay => switch (report.severity.toLowerCase()) {
        'high'   => 'Tinggi',
        'medium' => 'Sederhana',
        'low'    => 'Rendah',
        _        => report.severity,
      };

  String get _statusMalay => switch (report.status.toLowerCase()) {
        'pending'      => 'Menunggu',
        'reviewed'     => 'Disemak',
        'action taken' => 'Tindakan Diambil',
        'closed'       => 'Ditutup',
        'rejected'     => 'Ditolak',
        _              => report.status,
      };

  @override
  Widget build(BuildContext context) {
    final c = _sevColour;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Severity bar
          Container(
            width: 4,
            height: 56,
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(report.issueType,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _kText)),
                    ),
                    StatusChip(_statusMalay),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 2,
                  children: [
                    _InfoPill(Icons.calendar_today_outlined, report.date),
                    _InfoPill(Icons.subject_outlined,
                        report.subjectCode ?? report.subject),
                    _InfoPill(Icons.flag_outlined, _sevMalay),
                    if (report.lecturer.isNotEmpty)
                      _InfoPill(Icons.person_outline, report.lecturer),
                  ],
                ),
                if (report.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(report.description,
                      style: const TextStyle(
                          fontSize: 12, color: _kMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Lecturer Assignment Group (mobile grouping model) ────────────────────────

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

// ─── Student Detail Row (mobile bottom-sheet / dialog detail row) ─────────────

class _StudentDetailRow extends StatelessWidget {
  const _StudentDetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _kText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Attendance Risk Chip (mobile student card chip) ──────────────────────────

class _AttendanceRiskChip extends StatelessWidget {
  const _AttendanceRiskChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}