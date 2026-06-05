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
    final timetablePanelTitle = user.role == UserRole.pensyarah
        ? 'Slot Jadual Saya'
        : 'Ringkasan Slot Jadual';
    final timetablePanelSubtitle = user.role == UserRole.pensyarah
        ? 'Senarai ringkas slot jadual yang ditugaskan kepada anda untuk sesi akademik dipilih.'
        : 'Senarai ringkas slot jadual dalam skop semasa untuk sesi akademik dipilih.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: user.role == UserRole.pensyarah
              ? 'Selamat kembali, ${user.name}'
              : 'Selamat kembali, ${user.name.split(' ').first}',
          subtitle: switch (user.role) {
            UserRole.pentadbir =>
              'Ringkasan pentadbir dan tetapan asas sistem.',
            UserRole.ketua_jabatan =>
              'Pemantauan jabatan untuk jadual, disiplin, kehadiran dan laporan.',
            UserRole.ketua_program =>
              'Pemantauan program untuk kehadiran, laporan dan kelulusan tempahan.',
            UserRole.pensyarah =>
              'Pantau jadual mengajar, kehadiran, laporan disiplin dan permohonan bilik anda.',
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
                icon: Icons.school_outlined,
                helper: 'Jumlah pelajar dalam kelas ditugaskan'),
            StatTile(
                label: 'Slot Jadual',
                value: '${timetable.length}',
                icon: Icons.calendar_month_outlined,
                helper: 'Slot mengajar aktif'),
            StatTile(
                label: 'Bawah ${state.attendanceThreshold}%',
                value: '$below',
                icon: Icons.report_problem_outlined,
                color: Colors.red,
                helper: 'Pelajar berisiko kehadiran'),
            StatTile(
                label: 'Tindakan Menunggu',
                value:
                    '${pending + bookings.where((b) => b.status == 'Pending').length}',
                icon: Icons.pending_actions_outlined,
                color: Colors.orange,
                helper: 'Kehadiran / laporan belum selesai'),
          ],
        ),
        const SizedBox(height: 20),
        AppPanel(
          title: timetablePanelTitle,
          subtitle: timetablePanelSubtitle,
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
