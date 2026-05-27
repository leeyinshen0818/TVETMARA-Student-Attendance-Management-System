import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../state/app_scope.dart';
import '../widgets/app_layout.dart';
import '../widgets/status_chip.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.currentUser!;
    final isAdmin = user.role == UserRole.pentadbir;
    final isManagement = user.role == UserRole.ketua_jabatan ||
        user.role == UserRole.ketua_program;
    if (!isAdmin && !isManagement) {
      return const PageHeader(
        title: 'Akses Tidak Dibenarkan',
        subtitle:
            'Hanya Pentadbir, Ketua Jabatan dan Ketua Program boleh melihat rekod pelajar.',
      );
    }
    final students = state.scopedStudents;
    final validLecturerIds =
        state.scopedTimetable.map((t) => t.lecturerId).toSet();
    final visibleLecturers = isAdmin
        ? state.lecturers
        : state.lecturers
            .where((l) => validLecturerIds.contains(l.id))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Rekod Pelajar & Pensyarah',
          subtitle: 'Kedudukan kehadiran pelajar dan tugasan pensyarah-kursus.',
          trailing: StatusChip('${students.length} pelajar'),
        ),
        AppPanel(
          title: 'Rekod Pelajar',
          subtitle: 'Status kehadiran menggunakan had 80%.',
          child: AppDataTable(
            columns: const [
              DataColumn(label: Text('ID Pelajar')),
              DataColumn(label: Text('Nama')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Telefon')),
              DataColumn(label: Text('Program')),
              DataColumn(label: Text('Kelas')),
              DataColumn(label: Text('Semester')),
              DataColumn(label: Text('Kehadiran')),
              DataColumn(label: Text('Status')),
            ],
            rows: students.map((student) {
              final summary = state.attendanceSummaryForStudent(student);
              final risk = state.attendanceRiskForStudent(student);
              return DataRow(cells: [
                DataCell(Text(student.id)),
                DataCell(Text(student.name)),
                DataCell(Text(student.email)),
                DataCell(Text(student.phone)),
                DataCell(Text(student.program)),
                DataCell(Text(student.section)),
                DataCell(Text('${student.semester}')),
                DataCell(Text('${summary.percentage}%')),
                DataCell(StatusChip(student.active ? risk : 'Inactive')),
              ]);
            }).toList(),
          ),
        ),
        if (isManagement) ...[
          const SizedBox(height: 20),
          AppPanel(
            title: 'Tugasan Pensyarah',
            subtitle: 'Pemilikan kursus untuk akses jadual dan kehadiran.',
            child: AppDataTable(
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Nama')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Jabatan')),
                DataColumn(label: Text('Subjek')),
              ],
              rows: visibleLecturers.map((lecturer) {
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
        ],
      ],
    );
  }
}
