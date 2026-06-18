import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/app_models.dart';
import '../services/reports_pdf_export_service.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../widgets/app_layout.dart';
import '../widgets/mobile_components.dart';
import '../widgets/responsive.dart';
import '../widgets/status_chip.dart';

import '../widgets/app_components.dart';
import '../widgets/app_theme.dart';

// ─── Colour tokens ────────────────────────────────────────────────────────────

const _kCard = Colors.white;
const _kBorder = Color(0xFFE2E8EF);
const _kText = Color(0xFF1A2E3F);
const _kMuted = Color(0xFF5C7A8A);
const _kTeal = Color(0xFF1B8CA6);
const _kGreen = Color(0xFF16A34A);
const _kAmber = Color(0xFFD97706);
const _kRed = Color(0xFFDC2626);

// ─── Entry point ──────────────────────────────────────────────────────────────

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const _allGroupsKey = 'all';
  static const _allDisciplineKey = 'all';
  static const _hasDisciplineKey = 'has';
  static const _noDisciplineKey = 'none';

  String _search = '';
  String _selectedGroup = _allGroupsKey;
  int? _selectedWeek;
  int? _selectedThresholdFilter;
  String _selectedDisciplineFilter = _allDisciplineKey;

  bool get _hasActiveFilter =>
      _search.isNotEmpty ||
      _selectedGroup != _allGroupsKey ||
      _selectedThresholdFilter != null ||
      _selectedDisciplineFilter != _allDisciplineKey ||
      _selectedWeek != null;

  void _clearFilters() => setState(() {
        _search = '';
        _selectedGroup = _allGroupsKey;
        _selectedWeek = null;
        _selectedThresholdFilter = null;
        _selectedDisciplineFilter = _allDisciplineKey;
      });

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _groupKey(Student s) => '${s.program}||${s.section}';

  String _groupLabel(String key) {
    if (key == _allGroupsKey) return 'Semua Program / Kelas';
    final parts = key.split('||');
    final program = parts.first;
    final section = parts.length > 1 ? parts[1] : '';
    if (program.isEmpty) return section.isEmpty ? '-' : section;
    return '$program / $section';
  }

  String _programCodeForStudent(Student s) =>
      _extractProgramCode(s.section) ??
      _extractProgramCode(s.program) ??
      s.program;

  String? _extractProgramCode(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    const knownCodes = {
      'DED',
      'DCP',
      'DCB',
      'DGS',
      'DPP',
      'DEK',
      'DGM',
      'SMK',
      'ITW',
      'SLR',
      'SMI',
      'IMF',
      'SMM',
      'DMM',
    };
    final firstToken = text.split(RegExp(r'\s+')).first.toUpperCase();
    if (knownCodes.contains(firstToken)) return firstToken;
    for (final match
        in RegExp(r'\(([A-Z]{2,4})\)').allMatches(text).toList().reversed) {
      final code = match.group(1);
      if (code != null && knownCodes.contains(code)) return code;
    }
    final normalized = text.toUpperCase();
    return knownCodes.contains(normalized) ? normalized : null;
  }

  static String weeklyRisk(int percentage, int threshold) {
    if (percentage >= threshold) return 'Selamat';
    if (percentage >= 75) return 'Amaran';
    return 'Kritikal';
  }

  static String translateSeverity(String severity) =>
      switch (severity.toLowerCase()) {
        'high' => 'Tinggi',
        'medium' => 'Sederhana',
        'low' => 'Rendah',
        _ => severity,
      };

  static Color riskColor(String risk) => switch (risk.toLowerCase()) {
        'kritikal' || 'critical' => _kRed,
        'amaran' || 'warning' => _kAmber,
        _ => _kGreen,
      };

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.currentUser!;

    if (user.role != UserRole.ketua_jabatan &&
        user.role != UserRole.ketua_program &&
        user.role != UserRole.pensyarah) {
      return const AppPageHeader(
        title: 'Akses Tidak Dibenarkan',
        subtitle:
            'Hanya Ketua Jabatan, Ketua Program dan Pensyarah boleh menyemak laporan.',
      );
    }

    final students = state.scopedStudents;
    final timetable = state.scopedTimetable;

    final groupKeys = students.map(_groupKey).toSet().toList()
      ..sort((a, b) => _groupLabel(a).compareTo(_groupLabel(b)));
    final availableGroups = [_allGroupsKey, ...groupKeys];
    final selectedGroup = availableGroups.contains(_selectedGroup)
        ? _selectedGroup
        : _allGroupsKey;

    final groupFiltered = students
        .where((s) =>
            selectedGroup == _allGroupsKey || _groupKey(s) == selectedGroup)
        .toList();

    final filteredStudents = groupFiltered.where((s) {
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        if (!s.name.toLowerCase().contains(q) &&
            !s.id.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (_selectedThresholdFilter != null) {
        final summary = _selectedWeek == null
            ? state.attendanceSummaryForStudent(s)
            : state.attendanceSummaryForStudentWeek(s, _selectedWeek!);
        final pass = _selectedThresholdFilter == 80
            ? summary.percentage <= 80
            : summary.percentage < _selectedThresholdFilter!;
        if (!pass) return false;
      }
      final dr =
          state.disciplineReports.where((r) => r.studentId == s.id).toList();
      if (_selectedDisciplineFilter == _hasDisciplineKey) return dr.isNotEmpty;
      if (_selectedDisciplineFilter == _noDisciplineKey) return dr.isEmpty;
      return true;
    }).toList();

    final isAllWeeks = _selectedWeek == null;
    final summaries = filteredStudents
        .map((s) => isAllWeeks
            ? state.attendanceSummaryForStudent(s)
            : state.attendanceSummaryForStudentWeek(s, _selectedWeek!))
        .toList();

    final percentages = summaries.map((s) => s.percentage).toList();
    final avg = percentages.isEmpty
        ? 0
        : percentages.reduce((a, b) => a + b) ~/ percentages.length;
    final belowThreshold =
        summaries.where((s) => s.percentage < state.attendanceThreshold).length;
    final completed =
        timetable.where((slot) => slot.status == 'Attendance Completed').length;
    final frequencyLabel = switch (state.reportFrequency) {
      'Weekly' => 'Mingguan',
      'Daily' => 'Harian',
      'Monthly' => 'Bulanan',
      _ => state.reportFrequency,
    };

    Future<void> exportCurrentView() async {
      final critical = filteredStudents.where((s) {
        final sum = isAllWeeks
            ? state.attendanceSummaryForStudent(s)
            : state.attendanceSummaryForStudentWeek(s, _selectedWeek!);
        return sum.percentage < state.attendanceThreshold;
      }).toList();
      await _exportPdf(
        context: context,
        state: state,
        user: user,
        students: filteredStudents,
        criticalStudents: critical,
        averageAttendance: avg,
        completedSessions: completed,
      );
    }

    if (context.isMobile) {
      return _MobileReportsContent(
        totalStudents: filteredStudents.length,
        belowThreshold: belowThreshold,
        threshold: state.attendanceThreshold,
        averageAttendance: avg,
        completedSessions: completed,
        frequencyLabel: frequencyLabel,
        students: filteredStudents,
        summaries: summaries,
        state: state,
        selectedWeek: _selectedWeek,
        filterSection: _FilterSection(
          search: _search,
          selectedThreshold: _selectedThresholdFilter,
          selectedGroup: selectedGroup,
          selectedWeek: _selectedWeek,
          selectedDiscipline: _selectedDisciplineFilter,
          availableGroups: availableGroups,
          groupLabel: _groupLabel,
          allDisciplineKey: _allDisciplineKey,
          hasDisciplineKey: _hasDisciplineKey,
          noDisciplineKey: _noDisciplineKey,
          hasActiveFilter: _hasActiveFilter,
          onSearchChanged: (v) => setState(() => _search = v),
          onThresholdChanged: (v) =>
              setState(() => _selectedThresholdFilter = v),
          onGroupChanged: (v) => setState(() => _selectedGroup = v),
          onWeekChanged: (v) => setState(() => _selectedWeek = v),
          onDisciplineChanged: (v) =>
              setState(() => _selectedDisciplineFilter = v),
          onClear: _clearFilters,
        ),
        onExport: exportCurrentView,
        onExportStudent: (student, summary) async {
          await _exportPdf(
            context: context,
            state: state,
            user: user,
            students: [student],
            criticalStudents: [student],
            averageAttendance: summary.percentage,
            completedSessions: completed,
          );
        },
      );
    }

    return AppPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Banner ──────────────────────────────────────────────────────────
          _PageBanner(
            totalStudents: filteredStudents.length,
            belowThreshold: belowThreshold,
            threshold: state.attendanceThreshold,
            averageAttendance: avg,
            onExport: exportCurrentView,
          ),
          const SizedBox(height: 24),
          // ── Filters ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _FilterSection(
              search: _search,
              selectedThreshold: _selectedThresholdFilter,
              selectedGroup: selectedGroup,
              selectedWeek: _selectedWeek,
              selectedDiscipline: _selectedDisciplineFilter,
              availableGroups: availableGroups,
              groupLabel: _groupLabel,
              allDisciplineKey: _allDisciplineKey,
              hasDisciplineKey: _hasDisciplineKey,
              noDisciplineKey: _noDisciplineKey,
              hasActiveFilter: _hasActiveFilter,
              onSearchChanged: (v) => setState(() => _search = v),
              onThresholdChanged: (v) =>
                  setState(() => _selectedThresholdFilter = v),
              onGroupChanged: (v) => setState(() => _selectedGroup = v),
              onWeekChanged: (v) => setState(() => _selectedWeek = v),
              onDisciplineChanged: (v) =>
                  setState(() => _selectedDisciplineFilter = v),
              onClear: _clearFilters,
            ),
          ),
          // ── Table ───────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: AppPanel(
              title: isAllWeeks
                  ? 'Laporan Kehadiran Keseluruhan'
                  : 'Laporan Kehadiran Kritikal $frequencyLabel',
              subtitle: isAllWeeks
                  ? 'Sesi ${state.session} · Semua minggu · '
                      'Menunjukkan ${filteredStudents.length} pelajar'
                  : 'Sesi ${state.session} · '
                      'Menunjukkan ${filteredStudents.length} pelajar',
              trailing: const Icon(Icons.picture_as_pdf_outlined, color: _kRed),
              child: _ReportsTable(
                students: filteredStudents,
                summaries: summaries,
                state: state,
                selectedWeek: _selectedWeek,
                programCodeForStudent: _programCodeForStudent,
                onExportStudent: (student, summary) async {
                  await _exportPdf(
                    context: context,
                    state: state,
                    user: user,
                    students: [student],
                    criticalStudents: [student],
                    averageAttendance: summary.percentage,
                    completedSessions: completed,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── PDF export ─────────────────────────────────────────────────────────────

  Future<void> _exportPdf({
    required BuildContext context,
    required AppState state,
    required AppUser user,
    required List<Student> students,
    required List<Student> criticalStudents,
    required int averageAttendance,
    required int completedSessions,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    const exportService = ReportsPdfExportService();
    final thresholdLabel = _selectedThresholdFilter == null
        ? 'Tunjuk Semua'
        : 'Bawah $_selectedThresholdFilter%';
    final groupLabel = _selectedGroup == _allGroupsKey
        ? 'Semua Program / Kelas'
        : _groupLabel(_selectedGroup);
    final disciplineLabel = _selectedDisciplineFilter == _hasDisciplineKey
        ? 'Ada Disiplin'
        : _selectedDisciplineFilter == _noDisciplineKey
            ? 'Tiada Disiplin'
            : 'Semua';
    final report = CriticalAttendancePdfReport(
      academicSessionId: state.session,
      generatedAt: DateTime.now(),
      generatedBy: user.name,
      scopeLabel: _scopeLabel(state, user),
      threshold: state.attendanceThreshold,
      totalStudents: students.length,
      averageAttendance: averageAttendance,
      completedSessions: completedSessions,
      selectedWeek: _selectedWeek,
      thresholdFilterLabel: thresholdLabel,
      groupFilterLabel: groupLabel,
      disciplineFilterLabel: disciplineLabel,
      rows: criticalStudents.map((s) {
        final summary = _selectedWeek == null
            ? state.attendanceSummaryForStudent(s)
            : state.attendanceSummaryForStudentWeek(s, _selectedWeek!);
        return CriticalAttendanceReportRow(
          student: s,
          summary: summary,
          programCode: _programCodeForStudent(s),
          disciplineCount:
              state.disciplineReports.where((r) => r.studentId == s.id).length,
          isEligibleForPromotion: summary.percentage >= 80,
        );
      }).toList(),
    );
    try {
      final bytes = await exportService.buildCriticalAttendancePdf(report);
      await Printing.sharePdf(
        bytes: bytes,
        filename: exportService.fileNameFor(
          state.session,
          selectedWeek: _selectedWeek,
        ),
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Laporan PDF berjaya dijana.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Gagal menjana PDF laporan. Sila cuba lagi.')),
      );
    }
  }

  String _scopeLabel(AppState state, AppUser user) => switch (user.role) {
        UserRole.ketua_jabatan => _departmentScopeLabel(state, user),
        UserRole.ketua_program => _programScopeLabel(state, user),
        UserRole.pentadbir => 'Pentadbir - Semua Program',
        UserRole.pensyarah => 'Pensyarah - ${user.name}',
      };

  String _departmentScopeLabel(AppState state, AppUser user) {
    final departmentName = state.departments
        .where((d) => d.id == user.departmentId)
        .map((d) => d.name)
        .firstOrNull;
    final programIds = state.scopedPrograms.map((p) => p.id).join('/');
    final label = departmentName ?? user.departmentId ?? 'Jabatan';
    return programIds.isEmpty
        ? 'Ketua Jabatan - $label'
        : '$label ($programIds)';
  }

  String _programScopeLabel(AppState state, AppUser user) {
    final program =
        state.programs.where((p) => p.id == user.programId).firstOrNull;
    return program == null
        ? 'Ketua Program - ${user.programId ?? 'Program'}'
        : '${program.id} - ${program.name}';
  }
}

// ─── Page banner ──────────────────────────────────────────────────────────────

class _MobileReportsContent extends StatelessWidget {
  const _MobileReportsContent({
    required this.totalStudents,
    required this.belowThreshold,
    required this.threshold,
    required this.averageAttendance,
    required this.completedSessions,
    required this.frequencyLabel,
    required this.students,
    required this.summaries,
    required this.state,
    required this.selectedWeek,
    required this.filterSection,
    required this.onExport,
    required this.onExportStudent,
  });

  final int totalStudents;
  final int belowThreshold;
  final int threshold;
  final int averageAttendance;
  final int completedSessions;
  final String frequencyLabel;
  final List<Student> students;
  final List<AttendanceSummary> summaries;
  final AppState state;
  final int? selectedWeek;
  final Widget filterSection;
  final VoidCallback onExport;
  final Future<void> Function(Student, AttendanceSummary) onExportStudent;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MobileReportsHeader(
            totalStudents: totalStudents,
            frequencyLabel: frequencyLabel,
            onExport: onExport,
          ),
          const SizedBox(height: 12),
          filterSection,
          const SizedBox(height: 12),
          _MobileReportStats(
            totalStudents: totalStudents,
            belowThreshold: belowThreshold,
            threshold: threshold,
            averageAttendance: averageAttendance,
            completedSessions: completedSessions,
          ),
          const SizedBox(height: 12),
          MobileSection(
            title: 'Senarai Pelajar',
            subtitle:
                '${selectedWeek == null ? 'Semua Minggu' : 'Minggu $selectedWeek'} - paparan kad dioptimumkan untuk telefon.',
            child: _MobileReportsList(
              students: students,
              summaries: summaries,
              state: state,
              selectedWeek: selectedWeek,
              onExportStudent: onExportStudent,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileReportsHeader extends StatelessWidget {
  const _MobileReportsHeader({
    required this.totalStudents,
    required this.frequencyLabel,
    required this.onExport,
  });

  final int totalStudents;
  final String frequencyLabel;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return MobileHeroCard(
      icon: Icons.assessment_outlined,
      title: 'Laporan',
      subtitle: 'Semakan kehadiran dan risiko pelajar dalam skop anda.',
      chips: [StatusChip('$frequencyLabel - $totalStudents pelajar')],
      primaryAction: FilledButton.icon(
        onPressed: onExport,
        icon: const Icon(Icons.download, size: 16),
        label: const Text('Eksport PDF'),
        style: FilledButton.styleFrom(
          backgroundColor: _kTeal,
          minimumSize: const Size(0, 44),
        ),
      ),
    );
  }
}

class _MobileReportStats extends StatelessWidget {
  const _MobileReportStats({
    required this.totalStudents,
    required this.belowThreshold,
    required this.threshold,
    required this.averageAttendance,
    required this.completedSessions,
  });

  final int totalStudents;
  final int belowThreshold;
  final int threshold;
  final int averageAttendance;
  final int completedSessions;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MobileMetricData(
        icon: Icons.people_outline,
        label: 'Pelajar',
        value: '$totalStudents',
        color: _kTeal,
      ),
      _MobileMetricData(
        icon: Icons.percent_rounded,
        label: 'Purata Kehadiran',
        value: '$averageAttendance%',
        color: averageAttendance >= threshold ? _kGreen : _kRed,
      ),
      _MobileMetricData(
        icon: Icons.warning_amber_rounded,
        label: 'Bawah $threshold%',
        value: '$belowThreshold',
        color: belowThreshold > 0 ? _kAmber : _kGreen,
      ),
      _MobileMetricData(
        icon: Icons.check_circle_outline,
        label: 'Sesi Selesai',
        value: '$completedSessions',
        color: _kGreen,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        const columns = 2;
        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards)
              SizedBox(
                width: width,
                child: _MobileMetricCard(data: card),
              ),
          ],
        );
      },
    );
  }
}

class _MobileMetricData {
  const _MobileMetricData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
}

class _MobileMetricCard extends StatelessWidget {
  const _MobileMetricCard({required this.data});

  final _MobileMetricData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, color: data.color, size: 24),
          const SizedBox(height: 10),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileReportsList extends StatelessWidget {
  const _MobileReportsList({
    required this.students,
    required this.summaries,
    required this.state,
    required this.selectedWeek,
    required this.onExportStudent,
  });

  final List<Student> students;
  final List<AttendanceSummary> summaries;
  final AppState state;
  final int? selectedWeek;
  final Future<void> Function(Student, AttendanceSummary) onExportStudent;

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return const _EmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            for (var i = 0; i < students.length; i++) ...[
              if (i > 0)
                const Divider(height: 1, thickness: 1, color: _kBorder),
              _MobileReportCard(
                student: students[i],
                summary: summaries[i],
                state: state,
                selectedWeek: selectedWeek,
                onExport: () => onExportStudent(students[i], summaries[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MobileReportCard extends StatelessWidget {
  const _MobileReportCard({
    required this.student,
    required this.summary,
    required this.state,
    required this.selectedWeek,
    required this.onExport,
  });

  final Student student;
  final AttendanceSummary summary;
  final AppState state;
  final int? selectedWeek;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final risk = _ReportsScreenState.weeklyRisk(
      summary.percentage,
      state.attendanceThreshold,
    );
    final color = _ReportsScreenState.riskColor(risk);
    final disciplineCount =
        state.disciplineReports.where((r) => r.studentId == student.id).length;

    return InkWell(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => _StudentDetailDialog(
          student: student,
          state: state,
          selectedWeek: selectedWeek,
          onExport: onExport,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: dot · name · percentage
            Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    student.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${summary.percentage}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            // Bottom: indented 17px — subtitle + discipline count + progress bar
            Padding(
              padding: const EdgeInsets.only(left: 17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${student.id} · ${student.section}',
                          style: const TextStyle(fontSize: 12, color: _kMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (disciplineCount > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '$disciplineCount disiplin',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _kRed,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: summary.percentage / 100,
                      minHeight: 3,
                      backgroundColor: color.withValues(alpha: .15),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  if (selectedWeek == null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          summary.percentage >= 80
                              ? Icons.check_circle
                              : Icons.cancel,
                          size: 13,
                          color: summary.percentage >= 80 ? _kGreen : _kRed,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          summary.percentage >= 80
                              ? 'Layak Naik Semester'
                              : 'Tidak Layak Naik Semester',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: summary.percentage >= 80 ? _kGreen : _kRed,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageBanner extends StatelessWidget {
  const _PageBanner({
    required this.totalStudents,
    required this.belowThreshold,
    required this.threshold,
    required this.averageAttendance,
    required this.onExport,
  });

  final int totalStudents;
  final int belowThreshold;
  final int threshold;
  final int averageAttendance;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPageHeader(
          title: 'Laporan',
          subtitle:
              'Semakan kehadiran mingguan pelajar. MC dan CK dikecualikan daripada peratus kehadiran.',
          trailing: FilledButton.icon(
            onPressed: onExport,
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Eksport PDF'),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: AppStatCard(
                icon: Icons.people_outline,
                label: 'Jumlah Pelajar',
                value: '$totalStudents',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppStatCard(
                icon: Icons.warning_amber_rounded,
                label: 'Bawah Had Kehadiran',
                value: '$belowThreshold',
                color:
                    belowThreshold > 0 ? AppColors.danger : AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppStatCard(
                icon: Icons.bar_chart_rounded,
                label: 'Had Kehadiran',
                value: '$threshold%',
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppStatCard(
                icon: Icons.percent_rounded,
                label: 'Purata Kehadiran',
                value: '$averageAttendance%',
                color: averageAttendance >= threshold
                    ? AppColors.success
                    : AppColors.danger,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Filter section ───────────────────────────────────────────────────────────

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.search,
    required this.selectedThreshold,
    required this.selectedGroup,
    required this.selectedWeek,
    required this.selectedDiscipline,
    required this.availableGroups,
    required this.groupLabel,
    required this.allDisciplineKey,
    required this.hasDisciplineKey,
    required this.noDisciplineKey,
    required this.hasActiveFilter,
    required this.onSearchChanged,
    required this.onThresholdChanged,
    required this.onGroupChanged,
    required this.onWeekChanged,
    required this.onDisciplineChanged,
    required this.onClear,
  });

  final String search;
  final int? selectedThreshold;
  final String selectedGroup;
  final int? selectedWeek;
  final String selectedDiscipline;
  final List<String> availableGroups;
  final String Function(String) groupLabel;
  final String allDisciplineKey;
  final String hasDisciplineKey;
  final String noDisciplineKey;
  final bool hasActiveFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int?> onThresholdChanged;
  final ValueChanged<String> onGroupChanged;
  final ValueChanged<int?> onWeekChanged;
  final ValueChanged<String> onDisciplineChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return AppFilterPanel(
      children: [
        SizedBox(
          width: context.isMobile ? double.infinity : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: search + clear button
              if (context.isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ReportsSearchField(onChanged: onSearchChanged),
                    if (hasActiveFilter) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: onClear,
                        icon:
                            const Icon(Icons.filter_alt_off_outlined, size: 15),
                        label: const Text('Padam Penapis'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kMuted,
                          side: const BorderSide(color: _kBorder),
                        ),
                      ),
                    ],
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                        child: _ReportsSearchField(onChanged: onSearchChanged)),
                    if (hasActiveFilter) ...[
                      const SizedBox(width: 10),
                      TextButton.icon(
                        onPressed: onClear,
                        icon:
                            const Icon(Icons.filter_alt_off_outlined, size: 15),
                        label: const Text('Padam Penapis',
                            style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(foregroundColor: _kMuted),
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 12),
              // Row 2: threshold chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final t in [95, 90, 85, 80])
                    _ThresholdChip(
                      label: 'Bawah $t%',
                      selected: selectedThreshold == t,
                      onTap: () => onThresholdChanged(t),
                    ),
                  _ThresholdChip(
                    label: 'Tunjuk Semua',
                    selected: selectedThreshold == null,
                    onTap: () => onThresholdChanged(null),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Row 3: dropdowns
              LayoutBuilder(builder: (context, c) {
                final isWide = c.maxWidth > 560;
                final drops = <Widget>[
                  _FilterDropdown(
                    label: 'Program / Kelas',
                    value: selectedGroup,
                    items: availableGroups,
                    labelFor: groupLabel,
                    onChanged: onGroupChanged,
                  ),
                  _FilterDropdown(
                    label: 'Minggu',
                    value: selectedWeek?.toString() ?? 'all',
                    items: ['all', ...List.generate(18, (i) => '${i + 1}')],
                    labelFor: (v) => v == 'all' ? 'Semua Minggu' : 'Minggu $v',
                    onChanged: (v) =>
                        onWeekChanged(v == 'all' ? null : int.parse(v)),
                  ),
                  _FilterDropdown(
                    label: 'Status Disiplin',
                    value: selectedDiscipline,
                    items: [
                      allDisciplineKey,
                      hasDisciplineKey,
                      noDisciplineKey
                    ],
                    labelFor: (v) {
                      if (v == hasDisciplineKey) return 'Ada Disiplin';
                      if (v == noDisciplineKey) return 'Tiada Disiplin';
                      return 'Semua';
                    },
                    onChanged: onDisciplineChanged,
                  ),
                ];
                if (context.isMobile) {
                  return Column(
                    children: [
                      for (final dropdown in drops) ...[
                        dropdown,
                        if (dropdown != drops.last) const SizedBox(height: 10),
                      ],
                    ],
                  );
                }
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
                  children:
                      drops.map((w) => SizedBox(width: 200, child: w)).toList(),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThresholdChip extends StatelessWidget {
  const _ThresholdChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? _kTeal.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: selected ? _kTeal.withValues(alpha: 0.50) : _kBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? _kTeal : _kMuted,
          ),
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.labelFor,
    required this.onChanged,
  });
  final String label;
  final String value;
  final List<String> items;
  final String Function(String) labelFor;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final safeValue = items.contains(value) ? value : items.first;
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
              items: items
                  .map((o) =>
                      DropdownMenuItem(value: o, child: Text(labelFor(o))))
                  .toList(),
              onChanged: (v) => onChanged(v ?? items.first),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportsSearchField extends StatelessWidget {
  const _ReportsSearchField({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13, color: _kText),
        decoration: InputDecoration(
          hintText: 'Cari nama atau ID pelajar...',
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBDD0DA)),
          prefixIcon:
              const Icon(Icons.search_rounded, size: 17, color: _kMuted),
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

// ─── Reports table ────────────────────────────────────────────────────────────

class _ReportsTable extends StatelessWidget {
  const _ReportsTable({
    required this.students,
    required this.summaries,
    required this.state,
    required this.selectedWeek,
    required this.programCodeForStudent,
    required this.onExportStudent,
  });

  final List<Student> students;
  final List<AttendanceSummary> summaries;
  final AppState state;
  final int? selectedWeek;
  final String Function(Student) programCodeForStudent;
  final Future<void> Function(Student, AttendanceSummary) onExportStudent;

  Widget _disciplineChip(List<DisciplineReport> reports) {
    if (reports.isEmpty) {
      return const SizedBox(
        width: 44,
        child: Center(child: Text('-', style: TextStyle(color: _kMuted))),
      );
    }
    final latest =
        reports.reduce((a, b) => a.date.compareTo(b.date) >= 0 ? a : b);
    final sev = _ReportsScreenState.translateSeverity(latest.severity);
    final bg = switch (latest.severity.toLowerCase()) {
      'high' => _kRed.withValues(alpha: .15),
      'medium' => _kAmber.withValues(alpha: .15),
      'low' => _kGreen.withValues(alpha: .15),
      _ => _kBorder,
    };
    final fg = switch (latest.severity.toLowerCase()) {
      'high' => _kRed,
      'medium' => _kAmber,
      'low' => _kGreen,
      _ => _kText,
    };
    return Tooltip(
      message: '${reports.length} Laporan (Terbaru: $sev)',
      child: SizedBox(
        width: 44,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            constraints: const BoxConstraints(minWidth: 24),
            alignment: Alignment.center,
            child: Text(
              '${reports.length}',
              maxLines: 1,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800, color: fg),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return const _EmptyState();
    }
    final isAllWeeks = selectedWeek == null;
    return AppDataTable(
      columns: [
        const DataColumn(label: Text('ID Pelajar')),
        const DataColumn(label: Text('Nama')),
        const DataColumn(label: Text('Program')),
        const DataColumn(label: Text('Kelas')),
        const DataColumn(label: Text('Disiplin')),
        const DataColumn(
            label: SizedBox(width: 30, child: Center(child: Text('P')))),
        const DataColumn(
            label: SizedBox(width: 30, child: Center(child: Text('L')))),
        const DataColumn(
            label: SizedBox(width: 30, child: Center(child: Text('A')))),
        const DataColumn(
            label: SizedBox(width: 30, child: Center(child: Text('MC')))),
        const DataColumn(
            label: SizedBox(width: 30, child: Center(child: Text('CK')))),
        const DataColumn(label: Text('Kehadiran')),
        if (isAllWeeks) const DataColumn(label: Text('Naik Sem.')),
        const DataColumn(label: Text('Tindakan')),
      ],
      rows: List<DataRow>.generate(students.length, (i) {
        final student = students[i];
        final summary = summaries[i];
        final pct = summary.percentage;
        final risk =
            _ReportsScreenState.weeklyRisk(pct, state.attendanceThreshold);
        final colour = _ReportsScreenState.riskColor(risk);
        final studentReports = state.disciplineReports
            .where((r) => r.studentId == student.id)
            .toList();
        final programCode = programCodeForStudent(student);

        return DataRow(cells: [
          DataCell(Text(student.id,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: _kMuted))),
          DataCell(Text(student.name,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _kText))),
          DataCell(
            Tooltip(
              message: student.program,
              child: SizedBox(
                width: 56,
                child: Text(programCode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ),
          ),
          DataCell(Text(student.section,
              style: const TextStyle(fontSize: 12, color: _kText))),
          DataCell(_disciplineChip(studentReports)),
          DataCell(_numCell(summary.present)),
          DataCell(_numCell(summary.late)),
          DataCell(_numCell(summary.absent)),
          DataCell(_numCell(summary.mc)),
          DataCell(_numCell(summary.ck)),
          // Attendance progress bar
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
                        style: const TextStyle(fontSize: 10, color: _kMuted)),
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
          if (isAllWeeks)
            DataCell(
              Icon(
                pct >= 80 ? Icons.check_circle : Icons.cancel,
                color: pct >= 80 ? _kGreen : _kRed,
                size: 20,
              ),
            ),
          DataCell(
            _LihatButiranButton(
              student: student,
              state: state,
              selectedWeek: selectedWeek,
              onExport: () => onExportStudent(student, summary),
            ),
          ),
        ]);
      }),
    );
  }

  Widget _numCell(int v) => SizedBox(
        width: 30,
        child: Text('$v',
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Text(
          'Tiada pelajar ditemui untuk penapis semasa.',
          style: TextStyle(color: _kMuted, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ─── Lihat Butiran button ─────────────────────────────────────────────────────

class _LihatButiranButton extends StatelessWidget {
  const _LihatButiranButton({
    required this.student,
    required this.state,
    required this.selectedWeek,
    required this.onExport,
  });
  final Student student;
  final AppState state;
  final int? selectedWeek;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => _StudentDetailDialog(
          student: student,
          state: state,
          selectedWeek: selectedWeek,
          onExport: onExport,
        ),
      ),
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _kTeal.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: _kTeal.withValues(alpha: 0.35)),
        ),
        child: const Tooltip(
          message: 'Lihat Butiran',
          child: Icon(Icons.person_search_outlined, size: 16, color: _kTeal),
        ),
      ),
    );
  }
}

// ─── Student detail dialog ────────────────────────────────────────────────────

class _StudentDetailDialog extends StatelessWidget {
  const _StudentDetailDialog({
    required this.student,
    required this.state,
    required this.selectedWeek,
    required this.onExport,
  });

  final Student student;
  final AppState state;
  final int? selectedWeek;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final weekSummary = selectedWeek == null
        ? state.attendanceSummaryForStudent(student)
        : state.attendanceSummaryForStudentWeek(student, selectedWeek!);
    final overallSummary = state.attendanceSummaryForStudent(student);
    final riskMalay = _ReportsScreenState.weeklyRisk(
        weekSummary.percentage, state.attendanceThreshold);
    final riskColour = _ReportsScreenState.riskColor(riskMalay);
    final weekly = state.weeklyAttendanceForStudent(student);

    final disciplineLogs = state.scopedDisciplineReports
        .where((r) => r.studentId == student.id)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final warnings = <String>[];
    if (weekSummary.percentage < state.attendanceThreshold) {
      final weekLabel =
          selectedWeek == null ? 'Keseluruhan' : 'Minggu $selectedWeek';
      warnings.add(
          'Kehadiran ${weekSummary.percentage}% ($weekLabel) adalah di bawah had '
          '${state.attendanceThreshold}%. Tindakan segera diperlukan.');
    }
    if (overallSummary.absent >= 3) {
      warnings.add(
          'Pelajar telah tidak hadir ${overallSummary.absent} kali secara keseluruhan.');
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
              // Header
              _DialogHeader(
                student: student,
                riskLabel: riskMalay,
                riskColour: riskColour,
                weekSummary: weekSummary,
                selectedWeek: selectedWeek,
              ),
              // Scrollable body
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
                        label: 'Ringkasan Kehadiran Mingguan (M1 – M18)',
                      ),
                      const SizedBox(height: 10),
                      _WeeklyGrid(
                        weekly: weekly,
                        threshold: state.attendanceThreshold,
                        highlightedWeek: selectedWeek,
                      ),
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
              // Footer
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: _kBorder)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(foregroundColor: _kMuted),
                      child: const Text('Tutup'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onExport();
                      },
                      style: FilledButton.styleFrom(backgroundColor: _kTeal),
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Eksport PDF'),
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
    required this.riskLabel,
    required this.riskColour,
    required this.weekSummary,
    required this.selectedWeek,
  });

  final Student student;
  final String riskLabel;
  final Color riskColour;
  final AttendanceSummary weekSummary;
  final int? selectedWeek;

  @override
  Widget build(BuildContext context) {
    final pct = weekSummary.percentage;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: riskColour.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        border: Border(
            bottom: BorderSide(color: riskColour.withValues(alpha: 0.2))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
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
                student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
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
                      child: Text(student.name,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _kText)),
                    ),
                    StatusChip(riskLabel),
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
                    _InfoPill(
                        Icons.layers_outlined, 'Semester ${student.semester}'),
                    _InfoPill(
                        Icons.calendar_today_outlined,
                        selectedWeek == null
                            ? 'Semua Minggu'
                            : 'Minggu $selectedWeek'),
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
              const Text('Kehadiran',
                  style: TextStyle(fontSize: 11, color: _kMuted)),
              Text(selectedWeek == null ? 'Semua' : 'M$selectedWeek',
                  style: const TextStyle(fontSize: 10, color: _kMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Weekly grid M1–M18 ───────────────────────────────────────────────────────

class _WeeklyGrid extends StatelessWidget {
  const _WeeklyGrid({
    required this.weekly,
    required this.threshold,
    this.highlightedWeek,
  });
  final List<AttendanceSummary> weekly;
  final int threshold;
  final int? highlightedWeek;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(18, (i) {
        final w = weekly[i];
        final pct = w.percentage;
        final hasData = w.denominator > 0;
        final isHighlighted = highlightedWeek == i + 1;
        final colour = !hasData
            ? _kBorder
            : pct >= threshold
                ? _kGreen
                : pct >= 75
                    ? _kAmber
                    : _kRed;

        return Tooltip(
          message: hasData
              ? 'M${i + 1}: $pct%  (Hadir ${w.attended}/${w.denominator})'
              : 'M${i + 1}: Tiada data',
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colour.withValues(alpha: hasData ? 0.12 : 0.4),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: isHighlighted
                    ? colour
                    : colour.withValues(alpha: hasData ? 0.4 : 0.3),
                width: isHighlighted ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('M${i + 1}',
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

// ─── Shared helper widgets ────────────────────────────────────────────────────

class _InfoPill extends StatelessWidget {
  const _InfoPill(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: _kMuted),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: _kMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

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
                    fontSize: 12, fontWeight: FontWeight.w600, color: _kRed)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: _kTeal),
        const SizedBox(width: 7),
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: _kText)),
      ],
    );
  }
}

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
          Text(message, style: const TextStyle(fontSize: 12, color: _kMuted)),
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
        'high' || 'tinggi' => _kRed,
        'medium' || 'sederhana' => _kAmber,
        _ => _kTeal,
      };

  String get _statusMalay => switch (report.status.toLowerCase()) {
        'pending' => 'Menunggu',
        'reviewed' => 'Disemak',
        'action taken' => 'Tindakan Diambil',
        'closed' => 'Ditutup',
        'rejected' => 'Ditolak',
        _ => report.status,
      };

  @override
  Widget build(BuildContext context) {
    final c = _sevColour;
    final sevMalay = _ReportsScreenState.translateSeverity(report.severity);
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
          // Severity colour bar
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
                    _InfoPill(Icons.flag_outlined, sevMalay),
                    if (report.lecturer.isNotEmpty)
                      _InfoPill(Icons.person_outline, report.lecturer),
                  ],
                ),
                if (report.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(report.description,
                      style: const TextStyle(fontSize: 12, color: _kMuted),
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
