import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../state/app_scope.dart';
import '../widgets/app_layout.dart';
import '../widgets/status_chip.dart';

/// Laporan Disiplin screen — Pensyarah creates discipline reports,
/// KJ reviews / approves them.
class DisiplinScreen extends StatefulWidget {
  const DisiplinScreen({super.key});

  @override
  State<DisiplinScreen> createState() => _DisiplinScreenState();
}

class _DisiplinScreenState extends State<DisiplinScreen> {
  String? selectedStudentId;
  String issueType = 'Kerap Tidak Hadir';
  String severity = 'Medium';
  final _descCtrl = TextEditingController(text: '');

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.currentUser!;
    final isPensyarah = user.role == UserRole.pensyarah;
    final canApproveDiscipline = user.role == UserRole.ketuaJabatan;
    final visibleDiscipline = state.scopedDisciplineReports;

    // For Pensyarah: use scopedStudents (which now has a fallback)
    final studentsList = state.scopedStudents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: isPensyarah
              ? 'Laporan Disiplin Saya'
              : 'Semakan Laporan Disiplin',
          subtitle: isPensyarah
              ? 'Laporkan masalah kehadiran atau tingkah laku pelajar anda.'
              : 'Semak dan ambil tindakan ke atas laporan disiplin.',
          trailing: StatusChip('${visibleDiscipline.length} laporan'),
        ),

        // ── Create Form (Pensyarah only — ALWAYS shown) ──
        if (isPensyarah) ...[
          AppPanel(
            title: 'Lapor Disiplin Baharu',
            subtitle: studentsList.isNotEmpty
                ? 'Pilih pelajar dan nyatakan isu yang berlaku.'
                : 'Tiada pelajar dijumpai. Sila hubungi pentadbir.',
            child: studentsList.isNotEmpty
                ? Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 300,
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: selectedStudentId ??
                              studentsList.firstOrNull?.id,
                          decoration: const InputDecoration(
                              labelText: 'Pilih Pelajar'),
                          items: studentsList
                              .map((s) => DropdownMenuItem(
                                  value: s.id,
                                  child:
                                      Text('${s.name} (${s.section})')))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => selectedStudentId = value),
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: issueType,
                          decoration: const InputDecoration(
                              labelText: 'Jenis Isu'),
                          items: [
                            'Kerap Tidak Hadir',
                            'Ponteng Kelas',
                            'Masalah Tingkah Laku',
                            'Lain-lain'
                          ]
                              .map((i) => DropdownMenuItem(
                                  value: i, child: Text(i)))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => issueType = value!),
                        ),
                      ),
                      SizedBox(
                        width: 150,
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: severity,
                          decoration: const InputDecoration(
                              labelText: 'Tahap (Severity)'),
                          items: ['Low', 'Medium', 'High']
                              .map((i) => DropdownMenuItem(
                                  value: i, child: Text(i)))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => severity = value!),
                        ),
                      ),
                      SizedBox(
                        width: 300,
                        child: TextField(
                          controller: _descCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Keterangan / Catatan'),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () {
                          final targetId = selectedStudentId ??
                              studentsList.firstOrNull?.id;
                          if (targetId == null) return;
                          final student = studentsList
                              .firstWhere((s) => s.id == targetId);

                          state.addDiscipline(DisciplineReport(
                            id: 'D${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
                            studentId: student.id,
                            studentName: student.name,
                            section: student.section,
                            subject: '-',
                            lecturer: user.name,
                            date: DateTime.now()
                                .toIso8601String()
                                .substring(0, 10),
                            issueType: issueType,
                            severity: severity,
                            description: _descCtrl.text.trim(),
                            followUp: false,
                            status: 'New',
                          ));
                          _descCtrl.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Laporan disiplin telah dihantar.')));
                        },
                        icon: const Icon(Icons.send),
                        label: const Text('Hantar Laporan'),
                      ),
                    ],
                  )
                : const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Sila muat naik jadual untuk menghubungkan pelajar dengan kelas anda.',
                        style: TextStyle(color: Color(0xff94a3b8)),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Discipline History / Approval Table ──
        AppPanel(
          title: 'Senarai Laporan Disiplin',
          subtitle: 'Item susulan daripada semakan kehadiran dan tingkah laku.',
          child: AppDataTable(
            columns: const [
              DataColumn(label: Text('ID Laporan')),
              DataColumn(label: Text('Pelajar')),
              DataColumn(label: Text('Isu')),
              DataColumn(label: Text('Tahap')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Semakan')),
            ],
            rows: visibleDiscipline.map((report) {
              return DataRow(cells: [
                DataCell(Text(report.id)),
                DataCell(Text(report.studentName)),
                DataCell(Text(report.issueType)),
                DataCell(StatusChip(report.severity)),
                DataCell(StatusChip(report.status)),
                DataCell(canApproveDiscipline &&
                        (report.status == 'New' ||
                            report.status == 'Under Review')
                    ? IconButton(
                        onPressed: () =>
                            state.updateDiscipline(report.id, 'Approved'),
                        icon:
                            const Icon(Icons.check, color: Colors.green))
                    : const Text('-')),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }
}
