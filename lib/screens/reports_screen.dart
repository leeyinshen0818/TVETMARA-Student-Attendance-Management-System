import 'package:flutter/material.dart';

import '../state/app_scope.dart';
import '../widgets/stat_tile.dart';
import '../widgets/status_chip.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final students = state.scopedStudents;
    final timetable = state.scopedTimetable;
    final avg = students.isEmpty ? 0 : students.map((student) => student.attendance).reduce((a, b) => a + b) ~/ students.length;
    final below = students.where((student) => student.attendance < state.attendanceThreshold).toList();
    final completed = timetable.where((slot) => slot.status == 'Attendance Completed').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reporting Module', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.sizeOf(context).width > 1100 ? 4 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            StatTile(label: 'Students', value: '${students.length}', icon: Icons.people_outline),
            StatTile(label: 'Average Attendance', value: '$avg%', icon: Icons.percent),
            StatTile(label: 'Below Threshold', value: '${below.length}', icon: Icons.warning_amber, color: Colors.red),
            StatTile(label: 'Completed Sessions', value: '$completed', icon: Icons.check_circle_outline, color: Colors.green),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Student ID')),
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Program')),
                DataColumn(label: Text('Section')),
                DataColumn(label: Text('Attendance')),
                DataColumn(label: Text('Status')),
              ],
              rows: below.map((student) {
                return DataRow(cells: [
                  DataCell(Text(student.id)),
                  DataCell(Text(student.name)),
                  DataCell(Text(student.program)),
                  DataCell(Text(student.section)),
                  DataCell(Text('${student.attendance}%')),
                  const DataCell(StatusChip('Below 80%')),
                ]);
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
