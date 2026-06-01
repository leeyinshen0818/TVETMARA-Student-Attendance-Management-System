import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../models/app_models.dart';
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

  String _roleLabel(UserRole role) {
    return switch (role) {
      UserRole.pentadbir => 'Pentadbir',
      UserRole.ketua_program => 'Ketua Program',
      UserRole.ketua_jabatan => 'Ketua Jabatan',
      UserRole.pensyarah => 'Pensyarah',
    };
  }

  String _weeklyRisk(int percentage, int threshold) {
    if (percentage >= threshold) return 'Safe';
    if (percentage >= 75) return 'Warning';
    return 'Critical';
  }

  Future<void> _exportPdf(
    BuildContext context,
    AppState state,
    List<Student> students,
    List<AttendanceSummary> summaries,
    int avgPercentage,
    int below95,
    int below90,
    int below80,
    int completed,
    String groupLabel,
  ) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            'Laporan Kehadiran Mingguan',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Text('Tarikh dijana: ${now.toLocal().toString().split('.').first}'),
          pw.Text('Peranan: ${_roleLabel(state.currentUser!.role)}'),
          pw.Text('Nama: ${state.currentUser!.name}'),
          pw.Text('Program / Kelas: $groupLabel'),
          pw.Text('Minggu: $_selectedWeek'),
          pw.SizedBox(height: 16),
          pw.Text('Ringkasan',
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Bullet(text: 'Pelajar: ${students.length}'),
          pw.Bullet(text: 'Purata Kehadiran: $avgPercentage%'),
          pw.Bullet(text: 'Bawah 95%: $below95'),
          pw.Bullet(text: 'Bawah 90%: $below90'),
          pw.Bullet(text: 'Bawah atau sama dengan 80%: $below80'),
          pw.Bullet(text: 'Sesi Selesai: $completed'),
          pw.SizedBox(height: 16),
          pw.Text('Senarai Pelajar',
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headers: const [
              'ID Pelajar',
              'Nama',
              'Program',
              'Kelas',
              'P',
              'L',
              'A',
              'MC',
              'CK',
              'Kehadiran',
              'Status',
            ],
            data: List<List<String>>.generate(
              students.length,
              (index) {
                final student = students[index];
                final summary = summaries[index];
                final status = _weeklyRisk(summary.percentage, state.attendanceThreshold);
                return [
                  student.id,
                  student.name,
                  student.program,
                  student.section,
                  '${summary.present}',
                  '${summary.late}',
                  '${summary.absent}',
                  '${summary.mc}',
                  '${summary.ck}',
                  '${summary.percentage}%',
                  status,
                ];
              },
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
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
    final filteredStudents = students.where((student) {
      return selectedGroup == _allGroupsKey || _groupKey(student) == selectedGroup;
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
    final selectedGroupLabel = _groupLabel(selectedGroup);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Laporan',
          subtitle:
              'Semakan PDF mingguan untuk pelajar bawah ${state.attendanceThreshold}%. MC dan CK dikecualikan daripada peratus kehadiran.',
          trailing: FilledButton.icon(
            onPressed: () async {
              await _exportPdf(
                context,
                state,
                filteredStudents,
                summaries,
                avg,
                below95,
                below90,
                below80,
                completed,
                selectedGroupLabel,
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
            child: Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 300,
                  child: DropdownButtonFormField<String>(
                    value: selectedGroup,
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
                    value: _selectedWeek,
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
                return DataRow(cells: [
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
                ]);
              },
            ),
          ),
        ),
      ],
    );
  }
}
