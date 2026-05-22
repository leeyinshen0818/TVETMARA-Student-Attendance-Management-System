import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../state/app_scope.dart';
import '../widgets/app_layout.dart';
import '../widgets/stat_tile.dart';
import '../widgets/status_chip.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.currentUser!;
    final timetable = state.scopedTimetable;
    final students = state.scopedStudents;
    final bookings = state.scopedBookings;
    final below = state.criticalStudents.length;
    final pending = timetable
        .where((slot) =>
            slot.status.contains('Not Taken') ||
            slot.status == 'Attendance Pending')
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Selamat kembali, ${user.name.split(' ').first}',
          subtitle: switch (user.role) {
            UserRole.admin => 'Ringkasan pentadbir dan tetapan asas sistem.',
            UserRole.ketuaJabatan =>
              'Pemantauan jabatan untuk jadual, disiplin, kehadiran dan laporan.',
            UserRole.ketuaProgram =>
              'Pemantauan program untuk kehadiran, laporan dan kelulusan tempahan.',
            UserRole.pensyarah =>
              'Kelas anda, penghantaran kehadiran, laporan disiplin dan permohonan bilik.',
          },
          trailing: const StatusChip('Jan - Jun 2026'),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.sizeOf(context).width > 1100 ? 4 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.4,
          children: [
            StatTile(
                label: 'Pelajar',
                value: '${students.length}',
                icon: Icons.school_outlined),
            StatTile(
                label: 'Slot Jadual',
                value: '${timetable.length}',
                icon: Icons.calendar_month_outlined),
            StatTile(
                label: 'Bawah ${state.attendanceThreshold}%',
                value: '$below',
                icon: Icons.report_problem_outlined,
                color: Colors.red),
            StatTile(
                label: 'Tindakan Menunggu',
                value:
                    '${pending + bookings.where((b) => b.status == 'Pending').length}',
                icon: Icons.pending_actions_outlined,
                color: Colors.orange),
          ],
        ),
        const SizedBox(height: 20),
        AppPanel(
          title: 'Slot Jadual Terkini',
          subtitle:
              'Semakan ringkas sesi kelas akan datang dan yang telah selesai.',
          child: AppDataTable(
            columns: const [
              DataColumn(label: Text('Tarikh')),
              DataColumn(label: Text('Masa')),
              DataColumn(label: Text('Kelas')),
              DataColumn(label: Text('Subjek')),
              DataColumn(label: Text('Pensyarah')),
              DataColumn(label: Text('Status')),
            ],
            rows: timetable.take(8).map((slot) {
              return DataRow(cells: [
                DataCell(Text(slot.date)),
                DataCell(Text('${slot.startTime}-${slot.endTime}')),
                DataCell(Text(slot.section)),
                DataCell(Text(slot.subjectName)),
                DataCell(Text(slot.lecturerName)),
                DataCell(StatusChip(slot.status)),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }
}
