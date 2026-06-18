// lib/screens/records_screen.dart
//
// Module M5 â€“ Phase 2: Upgraded Ketua Rekod Pelajar
//
// Features:
//   â€¢ Strict data scoping via AppState.scopedStudents (KJ = dept, KP = programme)
//   â€¢ Search bar (Name / Student ID)
//   â€¢ Dropdown filters: Programme, Class/Section, Semester, Status, Attendance Risk
//   â€¢ Attendance progress bar per student row
//   â€¢ "Lihat Butiran" dialog: weekly W1â€“W18 grid + discipline log + risk warning
//
// All user-facing labels and status chips are in Malay.
// No hardcoded dummy data â€” all values come from AppState.

import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../widgets/app_components.dart';
import '../widgets/app_layout.dart';
import '../widgets/app_theme.dart';
import '../widgets/status_chip.dart';

// â”€â”€â”€ Entry point â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  String _search = '';
  String _filterProgram = 'Semua Program';
  String _filterClass = 'Semua Kelas';
  String _filterSem = 'Semua Semester';
  String _filterStatus = 'Semua Status';
  String _filterRisk = 'Semua Risiko';

  static final _riskDropdownItems = [
    'Semua Risiko',
    'Selamat',
    'Amaran',
    'Kritikal',
  ];

  static final _riskToInternal = {
    'Selamat': 'Safe',
    'Amaran': 'Warning',
    'Kritikal': 'Critical',
  };

  static String _riskLabel(String internal) => switch (internal) {
        'Critical' => 'Kritikal',
        'Warning' => 'Amaran',
        _ => 'Selamat',
      };

  static Color _riskColour(String internal) => switch (internal) {
        'Critical' => AppColors.danger,
        'Warning' => AppColors.warning,
        _ => AppColors.success,
      };

  List<Student> _applyFilters(List<Student> all, AppState state) {
    return all.where((s) {
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        if (!s.name.toLowerCase().contains(q) &&
            !s.id.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (_filterProgram != 'Semua Program' && s.program != _filterProgram) {
        return false;
      }
      if (_filterClass != 'Semua Kelas' && s.section != _filterClass) {
        return false;
      }
      if (_filterSem != 'Semua Semester' &&
          s.semester.toString() != _filterSem) {
        return false;
      }
      if (_filterStatus == 'Aktif' && !s.active) {
        return false;
      }
      if (_filterStatus == 'Tidak Aktif' && s.active) {
        return false;
      }
      if (_filterRisk != 'Semua Risiko') {
        final internal = _riskToInternal[_filterRisk] ?? _filterRisk;
        if (state.attendanceRiskForStudent(s) != internal) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  bool get _hasActiveFilter =>
      _search.isNotEmpty ||
      _filterProgram != 'Semua Program' ||
      _filterClass != 'Semua Kelas' ||
      _filterSem != 'Semua Semester' ||
      _filterStatus != 'Semua Status' ||
      _filterRisk != 'Semua Risiko';

  void _clearFilters() => setState(() {
        _search = _filterProgram =
            _filterClass = _filterSem = _filterStatus = _filterRisk = '';
        _filterProgram = 'Semua Program';
        _filterClass = 'Semua Kelas';
        _filterSem = 'Semua Semester';
        _filterStatus = 'Semua Status';
        _filterRisk = 'Semua Risiko';
        _search = '';
      });

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.currentUser!;
    final isAdmin = user.role == UserRole.pentadbir;
    final isManagement = user.role == UserRole.ketua_jabatan ||
        user.role == UserRole.ketua_program;

    if (!isAdmin && !isManagement) {
      return const AppPageHeader(
        title: 'Akses Tidak Dibenarkan',
        subtitle:
            'Hanya Pentadbir, Ketua Jabatan dan Ketua Program boleh melihat rekod pelajar.',
      );
    }

    final allStudents = state.scopedStudents;
    final filtered = _applyFilters(allStudents, state);

    final programSet = <String>{};
    final classSet = <String>{};
    final semSet = <String>{};
    for (final s in allStudents) {
      programSet.add(s.program);
      classSet.add(s.section);
      semSet.add(s.semester.toString());
    }
    final programs = ['Semua Program', ...programSet.toList()..sort()];
    final classes = ['Semua Kelas', ...classSet.toList()..sort()];
    final semesters = ['Semua Semester', ...semSet.toList()..sort()];

    final scopeLabel = switch (user.role) {
      UserRole.ketua_jabatan => 'Jabatan ${user.departmentId ?? ''}',
      UserRole.ketua_program => 'Program ${user.programId ?? ''}',
      _ => 'Semua Program',
    };

    final criticalCount = allStudents
        .where((s) => state.attendanceRiskForStudent(s) == 'Critical')
        .length;

    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return AppPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPageHeader(
            title: 'Rekod Pelajar',
            subtitle:
                'Paparan kehadiran dan status pelajar â€” $scopeLabel sahaja.',
          ),
          const SizedBox(height: 16),
          if (isMobile)
            Row(
              children: [
                Expanded(
                    child: _MiniStat(
                        icon: Icons.group_outlined,
                        label: 'Jumlah',
                        value: '${allStudents.length}',
                        color: AppColors.primary)),
                const SizedBox(width: 8),
                Expanded(
                    child: _MiniStat(
                        icon: Icons.warning_amber_rounded,
                        label: 'Kritikal',
                        value: '$criticalCount',
                        color: criticalCount > 0
                            ? AppColors.danger
                            : AppColors.success)),
                const SizedBox(width: 8),
                Expanded(
                    child: _MiniStat(
                        icon: Icons.bar_chart_rounded,
                        label: 'Had',
                        value: '${state.attendanceThreshold}%',
                        color: AppColors.warning)),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: AppStatCard(
                    icon: Icons.group_outlined,
                    label: 'Jumlah Pelajar',
                    value: '${allStudents.length}',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppStatCard(
                    icon: Icons.warning_amber_rounded,
                    label: 'Risiko Kritikal',
                    value: '$criticalCount',
                    color: criticalCount > 0
                        ? AppColors.danger
                        : AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppStatCard(
                    icon: Icons.bar_chart_rounded,
                    label: 'Had Kehadiran',
                    value: '${state.attendanceThreshold}%',
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _FilterBar(
              search: _search,
              filterProgram: _filterProgram,
              filterClass: _filterClass,
              filterSem: _filterSem,
              filterStatus: _filterStatus,
              filterRisk: _filterRisk,
              programOptions: programs,
              classOptions: classes,
              semesterOptions: semesters,
              riskOptions: _riskDropdownItems,
              hasActiveFilter: _hasActiveFilter,
              onSearchChanged: (v) => setState(() => _search = v),
              onProgramChanged: (v) => setState(() {
                _filterProgram = v;
                _filterClass = 'Semua Kelas';
              }),
              onClassChanged: (v) => setState(() => _filterClass = v),
              onSemChanged: (v) => setState(() => _filterSem = v),
              onStatusChanged: (v) => setState(() => _filterStatus = v),
              onRiskChanged: (v) => setState(() => _filterRisk = v),
              onClear: _clearFilters,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: AppPanel(
              title: 'Rekod Pelajar',
              subtitle: 'Had kehadiran: ${state.attendanceThreshold}% Â· '
                  'Menunjukkan ${filtered.length} daripada ${allStudents.length} pelajar ($scopeLabel)',
              trailing: filtered.isEmpty
                  ? null
                  : StatusChip('${filtered.length} pelajar'),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: filtered
                          .map((s) => _MobileStudentCard(
                                student: s,
                                state: state,
                                riskLabel: _riskLabel(
                                    state.attendanceRiskForStudent(s)),
                                riskColour: _riskColour(
                                    state.attendanceRiskForStudent(s)),
                              ))
                          .toList(),
                    )
                  : _StudentTable(
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
}

// â”€â”€â”€ Filter bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _FilterBar extends StatefulWidget {
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
  final bool hasActiveFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onProgramChanged;
  final ValueChanged<String> onClassChanged;
  final ValueChanged<String> onSemChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onRiskChanged;
  final VoidCallback onClear;

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
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
              Expanded(child: _SearchField(onChanged: widget.onSearchChanged)),
              if (MediaQuery.sizeOf(context).width < 600) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('Tapis'),
                ),
              ],
              if (widget.hasActiveFilter &&
                  MediaQuery.sizeOf(context).width >= 600) ...[
                const SizedBox(width: 10),
                TextButton.icon(
                  onPressed: widget.onClear,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 15),
                  label: const Text('Padam Penapis',
                      style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.muted),
                ),
              ],
            ],
          ),
          LayoutBuilder(builder: (context, c) {
            final isWide = c.maxWidth > 680;
            final isMobile = MediaQuery.sizeOf(context).width < 600;

            if (isMobile && !_expanded) {
              return const SizedBox.shrink();
            }

            final drops = [
              _Dropdown(
                  label: 'Program',
                  value: widget.filterProgram,
                  options: widget.programOptions,
                  onChanged: widget.onProgramChanged),
              _Dropdown(
                  label: 'Kelas',
                  value: widget.filterClass,
                  options: widget.classOptions,
                  onChanged: widget.onClassChanged),
              _Dropdown(
                  label: 'Semester',
                  value: widget.filterSem,
                  options: widget.semesterOptions,
                  onChanged: widget.onSemChanged),
              _Dropdown(
                label: 'Status',
                value: widget.filterStatus,
                options: const ['Semua Status', 'Aktif', 'Tidak Aktif'],
                onChanged: widget.onStatusChanged,
              ),
              _Dropdown(
                  label: 'Risiko',
                  value: widget.filterRisk,
                  options: widget.riskOptions,
                  onChanged: widget.onRiskChanged),
            ];

            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isWide)
                    Row(
                      children: drops
                          .map((w) => Expanded(
                                child: Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: w),
                              ))
                          .toList(),
                    )
                  else
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: drops
                          .map((w) => SizedBox(width: 180, child: w))
                          .toList(),
                    ),
                  if (isMobile && widget.hasActiveFilter) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: widget.onClear,
                        icon:
                            const Icon(Icons.filter_alt_off_outlined, size: 15),
                        label: const Text('Padam Penapis',
                            style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.muted),
                      ),
                    ),
                  ],
                ],
              ),
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
        style: const TextStyle(fontSize: 13, color: AppColors.primaryDark),
        decoration: InputDecoration(
          hintText: 'Cari nama atau ID pelajarâ€¦',
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBDD0DA)),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 17, color: AppColors.muted),
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: AppColors.surface,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: AppColors.primary),
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
                fontSize: 11,
                color: AppColors.muted,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: safeValue,
              isExpanded: true,
              isDense: true,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w500),
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

// â”€â”€â”€ Student table â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _StudentTable extends StatelessWidget {
  const _StudentTable({
    required this.students,
    required this.state,
    required this.riskLabel,
    required this.riskColour,
  });

  final List<Student> students;
  final AppState state;
  final String Function(String) riskLabel;
  final Color Function(String) riskColour;

  String _programCodeForStudent(Student s) =>
      _extractProgramCode(s.section) ??
      _extractProgramCode(s.program) ??
      s.program;

  String? _extractProgramCode(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    const knownCodes = {
      'DED', 'DCP', 'DCB', 'DGS', 'DPP', 'DEK', 'DGM', 'SMK', 'ITW', 'SLR',
      'SMI', 'IMF', 'SMM', 'DMM',
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
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Tindakan')),
      ],
      rows: students.map((s) {
        final summary = state.attendanceSummaryForStudent(s);
        final risk = state.attendanceRiskForStudent(s);
        final pct = summary.percentage;
        final colour = riskColour(risk);

        return DataRow(cells: [
          DataCell(Text(s.id,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted))),
          DataCell(Text(s.name,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark))),
          DataCell(
            Tooltip(
              message: s.program,
              child: SizedBox(
                width: 60,
                child: Text(_programCodeForStudent(s),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.primaryDark)),
              ),
            ),
          ),
          DataCell(Text(s.section,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.primaryDark))),
          DataCell(Text('${s.semester}',
              style:
                  const TextStyle(fontSize: 12, color: AppColors.primaryDark))),
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
                            fontSize: 10, color: AppColors.muted)),
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
          DataCell(StatusChip(s.active ? 'Aktif' : 'Tidak Aktif')),
          DataCell(_LihatButiranButton(student: s, state: state)),
        ]);
      }).toList(),
    );
  }
}

// â”€â”€â”€ Lihat Butiran button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _LihatButiranButton extends StatelessWidget {
  const _LihatButiranButton({required this.student, required this.state});
  final Student student;
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
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: const Tooltip(
          message: 'Lihat Butiran',
          child: Icon(Icons.person_search_outlined, size: 16, color: AppColors.primary),
        ),
      ),
    );
  }
}

// â”€â”€â”€ Student Detail Dialog â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _StudentDetailDialog extends StatelessWidget {
  const _StudentDetailDialog({required this.student, required this.state});
  final Student student;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final summary = state.attendanceSummaryForStudent(student);
    final risk = state.attendanceRiskForStudent(student);
    final weekly = state.weeklyAttendanceForStudent(student);
    final riskColour = _RecordsScreenState._riskColour(risk);
    final riskMalay = _RecordsScreenState._riskLabel(risk);

    final disciplineLogs = state.scopedDisciplineReports
        .where((r) => r.studentId == student.id)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final warnings = <String>[];
    if (summary.percentage < state.attendanceThreshold) {
      warnings.add('Kehadiran ${summary.percentage}% adalah di bawah had '
          '${state.attendanceThreshold}%. Tindakan segera diperlukan.');
    }
    if (summary.absent >= 3) {
      warnings.add('Pelajar telah tidak hadir ${summary.absent} kali.');
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780, maxHeight: 720),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
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
                student: student,
                summary: summary,
                riskMalay: riskMalay,
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
                        label: 'Ringkasan Kehadiran Mingguan (W1 â€“ W18)',
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.muted),
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

// â”€â”€â”€ Dialog header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    required this.student,
    required this.summary,
    required this.riskMalay,
    required this.riskColour,
  });
  final Student student;
  final AttendanceSummary summary;
  final String riskMalay;
  final Color riskColour;

  @override
  Widget build(BuildContext context) {
    final pct = summary.percentage;
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
                      child: Text(
                        student.name,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark),
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
                    _InfoPill(
                        Icons.layers_outlined, 'Semester ${student.semester}'),
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
                  style: TextStyle(fontSize: 11, color: AppColors.muted)),
              Text('${summary.attended}/${summary.denominator} sesi',
                  style: const TextStyle(fontSize: 10, color: AppColors.muted)),
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
  final String text;

  @override
  Widget build(BuildContext context) {
    // Text.rich treats the icon and the text as inline spans, so the parent
    // Wrap widget can break this pill onto the next line at any character
    // boundary â€” including mid-word if the text is very long (e.g. full
    // programme names like "DIPLOMA LANJUTAN KEJURUTERAAN ELEKTRIK...").
    // A Row with mainAxisSize.min would instead negotiate an unconstrained
    // width and overflow past the screen edge on narrow viewports.
    return Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(icon, size: 12, color: AppColors.muted),
            ),
          ),
          TextSpan(
            text: text,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
      // softWrap + no overflow clip means long text runs to the next line
      // within whatever width the Wrap cell provides.
      softWrap: true,
      overflow: TextOverflow.visible,
    );
  }
}

// â”€â”€â”€ Warning banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 16, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Section title â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 7),
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark)),
      ],
    );
  }
}

// â”€â”€â”€ Weekly grid W1â€“W18 â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _WeeklyGrid extends StatelessWidget {
  const _WeeklyGrid({required this.weekly});
  final List<AttendanceSummary> weekly;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(18, (i) {
        final w = weekly[i];
        final pct = w.percentage;
        final hasData = w.denominator > 0;
        final colour = !hasData
            ? const Color(0xFFE2E8EF)
            : pct >= 80
                ? AppColors.success
                : pct >= 75
                    ? AppColors.warning
                    : AppColors.danger;

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
                  color: colour.withValues(alpha: hasData ? 0.4 : 0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('W${i + 1}',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: hasData ? colour : AppColors.muted)),
                Text(hasData ? '$pct%' : 'â€”',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: hasData ? colour : AppColors.muted)),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// â”€â”€â”€ Empty in section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 28, color: Color(0xFF94A3B8)),
          const SizedBox(height: 6),
          Text(message,
              style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Discipline log tile â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _DisciplineTile extends StatelessWidget {
  const _DisciplineTile({required this.report});
  final DisciplineReport report;

  Color get _sevColour => switch (report.severity.toLowerCase()) {
        'high' || 'tinggi' => AppColors.danger,
        'medium' || 'sederhana' => AppColors.warning,
        _ => AppColors.primary,
      };

  String get _sevMalay => switch (report.severity.toLowerCase()) {
        'high' => 'Tinggi',
        'medium' => 'Sederhana',
        'low' => 'Rendah',
        _ => report.severity,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.border),
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
                              color: AppColors.primaryDark)),
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
                      style:
                          const TextStyle(fontSize: 12, color: AppColors.muted),
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

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style:
                        const TextStyle(fontSize: 11, color: AppColors.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileStudentCard extends StatelessWidget {
  const _MobileStudentCard({
    required this.student,
    required this.state,
    required this.riskLabel,
    required this.riskColour,
  });

  final Student student;
  final AppState state;
  final String riskLabel;
  final Color riskColour;

  @override
  Widget build(BuildContext context) {
    final summary = state.attendanceSummaryForStudent(student);
    final pct = summary.percentage;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                        '${student.id} · ${student.program} · ${student.section}',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              StatusChip(riskLabel),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$pct%',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: riskColour)),
                        Text('${summary.attended}/${summary.denominator}',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.muted)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct / 100,
                        minHeight: 6,
                        backgroundColor: riskColour.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(riskColour),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _LihatButiranButton(student: student, state: state),
            ],
          ),
        ],
      ),
    );
  }
}
