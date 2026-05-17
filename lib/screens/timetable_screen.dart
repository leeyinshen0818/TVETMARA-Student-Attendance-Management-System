import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../state/app_scope.dart';
import '../widgets/status_chip.dart';

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
        Text(admin ? 'Showing Timetable Slot' : 'My Timetable', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Code')),
                DataColumn(label: Text('Subject')),
                DataColumn(label: Text('Section')),
                DataColumn(label: Text('Program')),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Time')),
                DataColumn(label: Text('Room')),
                DataColumn(label: Text('Capacity')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Status')),
              ],
              rows: timetable.map((slot) {
                return DataRow(cells: [
                  DataCell(Text(slot.subjectCode)),
                  DataCell(Text(slot.subjectName)),
                  DataCell(Text(slot.section)),
                  DataCell(Text(slot.program)),
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
        ),
      ],
    );
  }
}
