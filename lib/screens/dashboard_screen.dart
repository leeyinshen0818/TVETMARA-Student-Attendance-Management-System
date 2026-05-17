import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../state/app_scope.dart';
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
    final bookings = user.role == UserRole.lecturer
        ? state.bookings.where((booking) => booking.lecturerId == user.id).toList()
        : state.bookings;
    final below = students.where((student) => student.attendance < state.attendanceThreshold).length;
    final pending = timetable.where((slot) => slot.status.contains('Not Taken') || slot.status == 'Attendance Pending').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome back, ${user.name.split(' ').first}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(user.role == UserRole.admin ? 'Admin overview and approvals.' : 'Your classes, attendance and booking activity.'),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.sizeOf(context).width > 1100 ? 4 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.4,
          children: [
            StatTile(label: 'Students', value: '${students.length}', icon: Icons.school_outlined),
            StatTile(label: 'Timetable Slots', value: '${timetable.length}', icon: Icons.calendar_month_outlined),
            StatTile(label: 'Below ${state.attendanceThreshold}%', value: '$below', icon: Icons.report_problem_outlined, color: Colors.red),
            StatTile(label: 'Pending Actions', value: '${pending + bookings.where((b) => b.status == 'Pending').length}', icon: Icons.pending_actions_outlined, color: Colors.orange),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Latest Timetable Slots', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Time')),
                      DataColumn(label: Text('Section')),
                      DataColumn(label: Text('Subject')),
                      DataColumn(label: Text('Lecturer')),
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
            ),
          ),
        ),
      ],
    );
  }
}
