import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/app_models.dart';
import '../services/reports_pdf_export_service.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../widgets/app_layout.dart';
import '../widgets/stat_tile.dart';
import '../widgets/status_chip.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const _allGroupsKey = 'all';
  String _selectedGroup = _allGroupsKey;
  int _selectedWeek = 1;
  int? _selectedThresholdFilter;

  String _groupKey(Student student) => '${student.program}||${student.section}';

  String _groupLabel(String groupKey) {
    if (groupKey == _allGroupsKey) {
      return 'Semua Program / Kelas';
    }
    final parts = groupKey.split('||');
    final program = parts.first;
    final section = parts.length > 1 ? parts[1] : '';
    if (program.isEmpty) return section.isEmpty ? '-' : section;
    return '$program / $section';
  }

  

  String _weeklyRisk(int percentage, int threshold) {
    if (percentage >= threshold) return 'Safe';
    if (percentage >= 75) return 'Warning';
    return 'Critical';
  }

  void _showStudentDetails(BuildContext context, AppState state, Student student) {
    final weeklyData = state.weeklyAttendanceForStudent(student);
    final disciplineReports = state.scopedDisciplineReports
        .where((report) => report.studentId == student.id)
        .toList();
    final risk = state.attendanceRiskForStudent(student);

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Butiran Pelajar - ${student.name}'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Risk: $risk'),
                  const SizedBox(height: 12),
                  Text('Kehadiran 18 Minggu',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  DataTable(
                    columns: const [
                      DataColumn(label: Text('M')),
                      DataColumn(label: Text('P')),
                      DataColumn(label: Text('L')),
                      DataColumn(label: Text('A')),
                      DataColumn(label: Text('MC')),
                      DataColumn(label: Text('CK')),
                      DataColumn(label: Text('%')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: List<DataRow>.generate(
                      weeklyData.length,
                      (index) {
                        final summary = weeklyData[index];
                        final status = _weeklyRisk(
                          summary.percentage,
                          state.attendanceThreshold,
                        );
                        return DataRow(
                          cells: [
                            DataCell(Text('${index + 1}')),
                            DataCell(Text('${summary.present}')),
                            DataCell(Text('${summary.late}')),
                            DataCell(Text('${summary.absent}')),
                            DataCell(Text('${summary.mc}')),
                            DataCell(Text('${summary.ck}')),
                            DataCell(Text('${summary.percentage}%')),
                            DataCell(Text(status)),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Laporan Disiplin',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (disciplineReports.isEmpty)
                    const Text('Tiada laporan disiplin.'),
                  for (final report in disciplineReports)
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text('${report.issueType} — ${report.severity}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tarikh: ${report.date}'),
                            Text('Subjek: ${report.subject}'),
                            Text('Status: ${report.status}'),
                            if (report.description.isNotEmpty)
                              Text('Keterangan: ${report.description}'),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.currentUser!;
    if (user.role != UserRole.ketua_jabatan &&
        user.role != UserRole.ketua_program &&
        user.role != UserRole.pensyarah) {
      return const PageHeader(
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
    final groupFilteredStudents = students.where((student) {
      return selectedGroup == _allGroupsKey || _groupKey(student) == selectedGroup;
    }).toList();
    final filteredStudents = groupFilteredStudents.where((student) {
      if (_selectedThresholdFilter == null) return true;
      final summary = state.attendanceSummaryForStudentWeek(student, _selectedWeek);
      return _selectedThresholdFilter == 80
          ? summary.percentage <= 80
          : summary.percentage < _selectedThresholdFilter!;
    }).toList();
    final summaries = filteredStudents
        .map((student) => state.attendanceSummaryForStudentWeek(student, _selectedWeek))
        .toList();
    final percentages = summaries.map((summary) => summary.percentage).toList();
    final avg = percentages.isEmpty
        ? 0
        : percentages.reduce((a, b) => a + b) ~/ percentages.length;
    final below95 = summaries.where((summary) => summary.percentage < 95).length;
    final below90 = summaries.where((summary) => summary.percentage < 90).length;
    final below80 = summaries.where((summary) => summary.percentage <= 80).length;
    final completed =
        timetable.where((slot) => slot.status == 'Attendance Completed').length;
    final frequencyLabel = switch (state.reportFrequency) {
      'Weekly' => 'Mingguan',
      'Daily' => 'Harian',
      'Monthly' => 'Bulanan',
      _ => state.reportFrequency,
    };
    

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Laporan',
          subtitle:
              'Semakan PDF mingguan untuk pelajar bawah ${state.attendanceThreshold}%. MC dan CK dikecualikan daripada peratus kehadiran.',
          trailing: FilledButton.icon(
            onPressed: () async {
              final critical = filteredStudents.where((student) {
                final summary = state.attendanceSummaryForStudentWeek(student, _selectedWeek);
                return summary.percentage < state.attendanceThreshold;
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
            },
            icon: const Icon(Icons.download),
            label: const Text('Eksport PDF'),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final threshold in [95, 90, 85, 80])
                      FilledButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.resolveWith(
                            (states) => _selectedThresholdFilter == threshold
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          foregroundColor: WidgetStateProperty.resolveWith(
                            (states) => _selectedThresholdFilter == threshold
                                ? Theme.of(context).colorScheme.onPrimary
                                : null,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedThresholdFilter = threshold;
                          });
                        },
                        child: Text('Bawah $threshold%'),
                      ),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedThresholdFilter = null;
                        });
                      },
                      child: const Text('Tunjuk Semua'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 300,
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedGroup,
                        decoration: const InputDecoration(
                          labelText: 'Program / Kelas',
                          border: OutlineInputBorder(),
                        ),
                        items: availableGroups
                            .map((groupKey) => DropdownMenuItem(
                                  value: groupKey,
                                  child: Text(_groupLabel(groupKey)),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedGroup = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<int>(
                        initialValue: _selectedWeek,
                        decoration: const InputDecoration(
                          labelText: 'Minggu',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(
                          18,
                          (index) => DropdownMenuItem(
                            value: index + 1,
                            child: Text('Minggu ${index + 1}'),
                          ),
                        ),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedWeek = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.sizeOf(context).width > 1100 ? 4 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            StatTile(
              label: 'Pelajar',
              value: '${filteredStudents.length}',
              icon: Icons.people_outline,
            ),
            StatTile(
              label: 'Purata Kehadiran',
              value: '$avg%',
              icon: Icons.percent,
            ),
            StatTile(
              label: 'Bawah 95%',
              value: '$below95',
              icon: Icons.warning_amber,
              color: Colors.yellow.shade700,
            ),
            StatTile(
              label: 'Bawah 90%',
              value: '$below90',
              icon: Icons.warning_amber_outlined,
              color: Colors.orange,
            ),
            StatTile(
              label: '≤ 80%',
              value: '$below80',
              icon: Icons.dangerous,
              color: Colors.red,
            ),
            StatTile(
              label: 'Sesi Selesai',
              value: '$completed',
              icon: Icons.check_circle_outline,
              color: Colors.green,
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppPanel(
          title: 'Laporan Kehadiran Kritikal $frequencyLabel',
          subtitle: 'Sesi ${state.session}',
          trailing: const Icon(Icons.picture_as_pdf_outlined,
              color: Color(0xffdc2626)),
          child: AppDataTable(
            columns: const [
              DataColumn(label: Text('ID Pelajar')),
              DataColumn(label: Text('Nama')),
              DataColumn(label: Text('Program')),
              DataColumn(label: Text('Kelas')),
              DataColumn(label: Text('P')),
              DataColumn(label: Text('L')),
              DataColumn(label: Text('A')),
              DataColumn(label: Text('MC')),
              DataColumn(label: Text('CK')),
              DataColumn(label: Text('Kehadiran')),
              DataColumn(label: Text('Status')),
            ],
            rows: List<DataRow>.generate(
              filteredStudents.length,
              (index) {
                final student = filteredStudents[index];
                final summary = summaries[index];
                final risk = _weeklyRisk(summary.percentage, state.attendanceThreshold);
                return DataRow(
                  onSelectChanged: (_) => _showStudentDetails(context, state, student),
                  cells: [
                    DataCell(Text(student.id)),
                    DataCell(Text(student.name)),
                    DataCell(Text(student.program)),
                    DataCell(Text(student.section)),
                    DataCell(Text('${summary.present}')),
                    DataCell(Text('${summary.late}')),
                    DataCell(Text('${summary.absent}')),
                    DataCell(Text('${summary.mc}')),
                    DataCell(Text('${summary.ck}')),
                    DataCell(Text('${summary.percentage}%')),
                    DataCell(StatusChip(risk)),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

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
    final report = CriticalAttendancePdfReport(
      academicSessionId: state.session,
      generatedAt: DateTime.now(),
      generatedBy: user.name,
      scopeLabel: _scopeLabel(state, user),
      threshold: state.attendanceThreshold,
      totalStudents: students.length,
      averageAttendance: averageAttendance,
      completedSessions: completedSessions,
      rows: criticalStudents
          .map(
            (student) => CriticalAttendanceReportRow(
              student: student,
              summary: state.attendanceSummaryForStudentWeek(student, _selectedWeek),
            ),
          )
          .toList(),
    );

    try {
      final bytes = await exportService.buildCriticalAttendancePdf(report);
      await Printing.sharePdf(
        bytes: bytes,
        filename: exportService.fileNameFor(state.session),
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Laporan PDF berjaya dijana.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Gagal menjana PDF laporan. Sila cuba lagi.'),
        ),
      );
    }
  }

  String _scopeLabel(AppState state, AppUser user) {
    return switch (user.role) {
      UserRole.ketua_jabatan => _departmentScopeLabel(state, user),
      UserRole.ketua_program => _programScopeLabel(state, user),
      UserRole.pentadbir => 'Pentadbir - Semua Program',
      UserRole.pensyarah => 'Pensyarah - ${user.name}',
    };
  }

  String _departmentScopeLabel(AppState state, AppUser user) {
    final departmentName = state.departments
        .where((department) => department.id == user.departmentId)
        .map((department) => department.name)
        .firstOrNull;
    final programIds = state.scopedPrograms.map((program) => program.id).join(
          '/',
        );
    final label = departmentName ?? user.departmentId ?? 'Jabatan';
    return programIds.isEmpty
        ? 'Ketua Jabatan - $label'
        : '$label ($programIds)';
  }

  String _programScopeLabel(AppState state, AppUser user) {
    final program = state.programs
        .where((program) => program.id == user.programId)
        .firstOrNull;
    return program == null
        ? 'Ketua Program - ${user.programId ?? 'Program'}'
        : '${program.id} - ${program.name}';
  }
}
