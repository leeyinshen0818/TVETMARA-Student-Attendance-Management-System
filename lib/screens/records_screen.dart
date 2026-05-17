import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../state/app_scope.dart';
import '../widgets/status_chip.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final admin = state.currentUser?.role == UserRole.admin;
    final students = state.scopedStudents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(admin ? 'Student and Lecturer Records' : 'My Students', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Student ID')),
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Phone')),
                DataColumn(label: Text('Program')),
                DataColumn(label: Text('Section')),
                DataColumn(label: Text('Semester')),
                DataColumn(label: Text('Attendance')),
                DataColumn(label: Text('Status')),
              ],
              rows: students.map((student) {
                return DataRow(cells: [
                  DataCell(Text(student.id)),
                  DataCell(Text(student.name)),
                  DataCell(Text(student.email)),
                  DataCell(Text(student.phone)),
                  DataCell(Text(student.program)),
                  DataCell(Text(student.section)),
                  DataCell(Text('${student.semester}')),
                  DataCell(Text('${student.attendance}%')),
                  DataCell(StatusChip(student.active ? 'Active' : 'Inactive')),
                ]);
              }).toList(),
            ),
          ),
        ),
        if (admin) ...[
          const SizedBox(height: 20),
          Text('Lecturers', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Department')),
                  DataColumn(label: Text('Subjects')),
                ],
                rows: state.lecturers.map((lecturer) {
                  return DataRow(cells: [
                    DataCell(Text(lecturer.id)),
                    DataCell(Text(lecturer.name)),
                    DataCell(Text(lecturer.email)),
                    DataCell(Text(lecturer.department)),
                    DataCell(Text(lecturer.subjects.join(', '))),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
