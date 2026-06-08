import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/app_models.dart';
import '../services/reports_pdf_export_service.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../widgets/app_layout.dart';
import '../widgets/stat_tile.dart';
import '../widgets/status_chip.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.currentUser!;
    if (user.role != UserRole.ketua_jabatan &&
        user.role != UserRole.ketua_program) {
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
            onPressed: () => _exportPdf(
              context: context,
              state: state,
              user: user,
              students: students,
              criticalStudents: below,
              averageAttendance: avg,
              completedSessions: completed,
            ),
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

  Future<void> _exportPdf({
    required BuildContext context,
    required AppState state,
    required AppUser user,
    required List<Student> students,
    required List<Student> criticalStudents,
    required int averageAttendance,
    required int completedSessions,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    const exportService = ReportsPdfExportService();
    final report = CriticalAttendancePdfReport(
      academicSessionId: state.session,
      generatedAt: DateTime.now(),
      generatedBy: user.name,
      scopeLabel: _scopeLabel(state, user),
      threshold: state.attendanceThreshold,
      totalStudents: students.length,
      averageAttendance: averageAttendance,
      completedSessions: completedSessions,
      rows: criticalStudents
          .map(
            (student) => CriticalAttendanceReportRow(
              student: student,
              summary: state.attendanceSummaryForStudent(student),
            ),
          )
          .toList(),
    );

    try {
      final bytes = await exportService.buildCriticalAttendancePdf(report);
      await Printing.sharePdf(
        bytes: bytes,
        filename: exportService.fileNameFor(state.session),
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Laporan PDF berjaya dijana.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Gagal menjana PDF laporan. Sila cuba lagi.'),
        ),
      );
    }
  }

  String _scopeLabel(AppState state, AppUser user) {
    return switch (user.role) {
      UserRole.ketua_jabatan => _departmentScopeLabel(state, user),
      UserRole.ketua_program => _programScopeLabel(state, user),
      UserRole.pentadbir => 'Pentadbir - Semua Program',
      UserRole.pensyarah => 'Pensyarah - ${user.name}',
    };
  }

  String _departmentScopeLabel(AppState state, AppUser user) {
    final departmentName = state.departments
        .where((department) => department.id == user.departmentId)
        .map((department) => department.name)
        .firstOrNull;
    final programIds = state.scopedPrograms.map((program) => program.id).join(
          '/',
        );
    final label = departmentName ?? user.departmentId ?? 'Jabatan';
    return programIds.isEmpty
        ? 'Ketua Jabatan - $label'
        : '$label ($programIds)';
  }

  String _programScopeLabel(AppState state, AppUser user) {
    final program = state.programs
        .where((program) => program.id == user.programId)
        .firstOrNull;
    return program == null
        ? 'Ketua Program - ${user.programId ?? 'Program'}'
        : '${program.id} - ${program.name}';
  }
}
