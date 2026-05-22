import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../state/app_scope.dart';
import '../widgets/app_layout.dart';
import '../widgets/stat_tile.dart';
import '../widgets/status_chip.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.currentUser!;
    if (user.role != UserRole.ketuaJabatan &&
        user.role != UserRole.ketuaProgram) {
      return const PageHeader(
        title: 'Akses Tidak Dibenarkan',
        subtitle:
            'Hanya Ketua Jabatan dan Ketua Program boleh menyemak laporan.',
      );
    }
    final students = state.scopedStudents;
    final timetable = state.scopedTimetable;
    final percentages =
        students.map(state.attendancePercentageForStudent).toList();
    final avg = percentages.isEmpty
        ? 0
        : percentages.reduce((a, b) => a + b) ~/ percentages.length;
    final below = state.criticalStudents;
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Laporan PDF dijana untuk semakan mingguan.')),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Eksport PDF'),
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
                value: '${students.length}',
                icon: Icons.people_outline),
            StatTile(
                label: 'Purata Kehadiran', value: '$avg%', icon: Icons.percent),
            StatTile(
                label: 'Bawah Had',
                value: '${below.length}',
                icon: Icons.warning_amber,
                color: Colors.red),
            StatTile(
                label: 'Sesi Selesai',
                value: '$completed',
                icon: Icons.check_circle_outline,
                color: Colors.green),
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
            rows: below.map((student) {
              final summary = state.attendanceSummaryForStudent(student);
              final risk = state.attendanceRiskForStudent(student);
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
            }).toList(),
          ),
        ),
      ],
    );
  }
}
