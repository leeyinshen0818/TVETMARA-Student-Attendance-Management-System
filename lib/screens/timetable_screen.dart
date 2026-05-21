import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../state/app_scope.dart';
import '../widgets/app_layout.dart';
import '../widgets/status_chip.dart';
import 'add_timetable_screen.dart';

class TimetableScreen extends StatelessWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final admin = state.currentUser?.role == UserRole.admin;
    final timetable = state.scopedTimetable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: admin ? 'Slot Jadual' : 'Jadual Saya',
          subtitle:
              'Jadual kelas yang dipautkan kepada pensyarah, bilik, kursus dan sesi kehadiran.',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusChip('${timetable.length} slot'),
              if (!admin) ...[
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddTimetableScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Jadual'),
                ),
              ],
            ],
          ),
        ),
        AppPanel(
          title: 'Jadual Sesi',
          subtitle: 'Jan - Jun 2026',
          child: AppDataTable(
            columns: const [
              DataColumn(label: Text('Kod')),
              DataColumn(label: Text('Subjek')),
              DataColumn(label: Text('Kelas')),
              DataColumn(label: Text('Program')),
              DataColumn(label: Text('Sesi')),
              DataColumn(label: Text('Hari')),
              DataColumn(label: Text('Tarikh')),
              DataColumn(label: Text('Masa')),
              DataColumn(label: Text('Bilik')),
              DataColumn(label: Text('Kapasiti')),
              DataColumn(label: Text('Jenis')),
              DataColumn(label: Text('Status')),
            ],
            rows: timetable.map((slot) {
              return DataRow(cells: [
                DataCell(Text(slot.subjectCode)),
                DataCell(Text(slot.subjectName)),
                DataCell(Text(slot.section)),
                DataCell(Text(slot.program)),
                DataCell(Text(slot.session)),
                DataCell(Text(slot.day)),
                DataCell(Text(slot.date)),
                DataCell(Text('${slot.startTime}-${slot.endTime}')),
                DataCell(Text(slot.room)),
                DataCell(Text('${slot.enrolled}/${slot.capacity}')),
                DataCell(StatusChip(slot.slotType)),
                DataCell(StatusChip(slot.status)),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }
}
