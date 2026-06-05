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
  String? selectedSlotId;
  String issueType = 'Kerap Tidak Hadir';
  String severity = 'Medium';
  final _descCtrl = TextEditingController(text: '');
  bool _submitting = false;

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
    final canApproveDiscipline = user.role == UserRole.ketua_jabatan ||
        user.role == UserRole.ketua_program;
    if (!isPensyarah && !canApproveDiscipline) {
      return const PageHeader(
        title: 'Akses Tidak Dibenarkan',
        subtitle:
            'Hanya Pensyarah boleh melapor disiplin. Ketua Jabatan dan Ketua Program boleh membuat semakan mengikut skop.',
      );
    }
    final visibleDiscipline = state.scopedDisciplineReports;

    final slots = state.scopedTimetable;
    selectedSlotId ??= slots.firstOrNull?.id;
    final selectedSlot =
        slots.where((slot) => slot.id == selectedSlotId).firstOrNull;
    final studentsList = selectedSlot == null
        ? state.scopedStudents
        : state.scopedStudents
            .where((student) => student.section == selectedSlot.section)
            .toList();
    if (selectedStudentId == null ||
        !studentsList.any((student) => student.id == selectedStudentId)) {
      selectedStudentId = studentsList.firstOrNull?.id;
    }

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
                ? 'Pilih kelas, pelajar dan nyatakan isu yang berlaku.'
                : 'Tiada pelajar dijumpai untuk kelas anda. Sila semak jadual atau hubungi pentadbir.',
            child: studentsList.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (selectedSlot != null) ...[
                        _ClassSummary(slot: selectedSlot),
                        const SizedBox(height: 16),
                      ],
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: 320,
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: selectedSlot?.id,
                              decoration:
                                  const InputDecoration(labelText: 'Kelas'),
                              items: slots
                                  .map((slot) => DropdownMenuItem(
                                        value: slot.id,
                                        child: Text(
                                            '${slot.subjectCode} - ${slot.section}'),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedSlotId = value;
                                  selectedStudentId = null;
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            width: 320,
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: selectedStudentId,
                              decoration: const InputDecoration(
                                  labelText: 'Pilih Pelajar'),
                              items: studentsList
                                  .map((s) => DropdownMenuItem(
                                      value: s.id,
                                      child: Text('${s.name} (${s.section})')))
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => selectedStudentId = value),
                            ),
                          ),
                          SizedBox(
                            width: 220,
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: issueType,
                              decoration:
                                  const InputDecoration(labelText: 'Jenis Isu'),
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
                            width: 160,
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: severity,
                              decoration:
                                  const InputDecoration(labelText: 'Tahap'),
                              items: ['Low', 'Medium', 'High']
                                  .map((i) => DropdownMenuItem(
                                      value: i, child: Text(i)))
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => severity = value!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Keterangan / Catatan',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: _submitting
                              ? null
                              : () => _submitReport(
                                    state: state,
                                    user: user,
                                    studentsList: studentsList,
                                    selectedSlot: selectedSlot,
                                  ),
                          icon: _submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send),
                          label: Text(_submitting
                              ? 'Menghantar...'
                              : 'Hantar Laporan'),
                        ),
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
          child: Column(
            children: [
              for (final report in visibleDiscipline)
                _DisciplineReportItem(
                  report: report,
                  status: _normalizedStatus(report.status),
                  canApprove: canApproveDiscipline,
                  onStatusChanged: (nextStatus, {actionTakenNote}) =>
                      state.updateDiscipline(
                    report.id,
                    nextStatus,
                    actionTakenNote: actionTakenNote,
                  ),
                ),
              if (visibleDiscipline.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Text(
                      'Tiada laporan disiplin ditemui.',
                      style: TextStyle(color: Color(0xff64748b)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submitReport({
    required dynamic state,
    required AppUser user,
    required List<Student> studentsList,
    required TimetableSlot? selectedSlot,
  }) async {
    final targetId = selectedStudentId ?? studentsList.firstOrNull?.id;
    final description = _descCtrl.text.trim();
    if (targetId == null) return;
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sila isi keterangan sebelum menghantar laporan.')));
      return;
    }

    final student = studentsList.firstWhere((s) => s.id == targetId);
    setState(() => _submitting = true);
    try {
      await state.addDiscipline(DisciplineReport(
        id: 'D${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
        studentId: student.id,
        studentName: student.name,
        programId: selectedSlot?.programId,
        programName: selectedSlot?.program ?? student.program,
        departmentId: selectedSlot?.departmentId,
        section: student.section,
        subject: selectedSlot?.subjectName ?? '-',
        subjectCode: selectedSlot?.subjectCode,
        subjectName: selectedSlot?.subjectName,
        slotId: selectedSlot?.id,
        lecturer: user.name,
        createdBy: user.uid,
        createdByName: user.name,
        date: DateTime.now().toIso8601String().substring(0, 10),
        issueType: issueType,
        severity: severity,
        description: description,
        followUp: false,
        status: 'pending',
      ));
      _descCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan disiplin telah dihantar.')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _normalizedStatus(String status) {
    return switch (status) {
      'New' => 'pending',
      'Submitted' => 'pending',
      'Under Review' => 'reviewed',
      'Approved' => 'action_taken',
      _ => status,
    };
  }
}

class _ClassSummary extends StatelessWidget {
  const _ClassSummary({required this.slot});

  final TimetableSlot slot;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MiniChip(Icons.groups_outlined, slot.section),
        _MiniChip(Icons.menu_book_outlined, slot.subjectCode),
        _MiniChip(Icons.schedule, '${slot.startTime}-${slot.endTime}'),
        _MiniChip(Icons.meeting_room_outlined, slot.room),
      ],
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xffeff6ff),
        border: Border.all(color: const Color(0xffbfdbfe)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: const Color(0xff2563eb)),
          const SizedBox(width: 7),
          Text(
            label.isEmpty ? '-' : label,
            style: const TextStyle(
              color: Color(0xff1e3a8a),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DisciplineReportItem extends StatelessWidget {
  const _DisciplineReportItem({
    required this.report,
    required this.status,
    required this.canApprove,
    required this.onStatusChanged,
  });

  final DisciplineReport report;
  final String status;
  final bool canApprove;
  final Future<void> Function(String status, {String? actionTakenNote})
      onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final subject = report.subjectName ??
        report.subjectCode ??
        (report.subject == '-' ? 'Tiada subjek' : report.subject);
    final reviewers = report.assignedReviewerRoles.isEmpty
        ? '-'
        : report.assignedReviewerRoles.join(', ');
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        border: Border.all(color: const Color(0xffe2e8f0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.studentName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xff0f172a),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${report.programName ?? report.programId ?? '-'} | ${report.section} | $subject',
                      style: const TextStyle(color: Color(0xff64748b)),
                    ),
                  ],
                ),
              ),
              StatusChip(_statusLabel(status)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${report.issueType} (${report.severity})',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xff334155),
            ),
          ),
          const SizedBox(height: 4),
          Text(report.description.isEmpty ? '-' : report.description),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _ReportMeta(label: 'Laporan', value: report.id),
              _ReportMeta(
                  label: 'Dilapor oleh',
                  value: report.createdByName ?? report.lecturer),
              _ReportMeta(label: 'Tarikh', value: report.createdAt ?? report.date),
              _ReportMeta(label: 'Reviewer', value: reviewers),
            ],
          ),
          if (report.actionTakenNote != null &&
              report.actionTakenNote!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xfff1f5f9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Tindakan: ${report.actionTakenNote}'
                '${report.actionTakenByName == null ? '' : ' (${report.actionTakenByName})'}',
                style: const TextStyle(color: Color(0xff334155)),
              ),
            ),
          ],
          if (canApprove) ...[
            const SizedBox(height: 12),
            _DisciplineStatusActions(
              status: status,
              onChanged: onStatusChanged,
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    return switch (status) {
      'pending' => 'Pending',
      'reviewed' => 'Reviewed',
      'action_taken' => 'Action Taken',
      'closed' => 'Closed',
      'rejected' => 'Rejected',
      _ => status,
    };
  }
}

class _ReportMeta extends StatelessWidget {
  const _ReportMeta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: $value',
      style: const TextStyle(color: Color(0xff64748b), fontSize: 12),
    );
  }
}

class _DisciplineStatusActions extends StatelessWidget {
  const _DisciplineStatusActions({
    required this.status,
    required this.onChanged,
  });

  final String status;
  final Future<void> Function(String status, {String? actionTakenNote})
      onChanged;

  @override
  Widget build(BuildContext context) {
    final actions = switch (status) {
      'pending' => const [
          _StatusAction('reviewed', 'Reviewed', Icons.rate_review_outlined),
          _StatusAction('rejected', 'Rejected', Icons.close),
        ],
      'reviewed' => const [
          _StatusAction(
              'action_taken', 'Action Taken', Icons.task_alt_outlined),
          _StatusAction('rejected', 'Rejected', Icons.close),
        ],
      'action_taken' => const [
          _StatusAction('closed', 'Closed', Icons.lock_outline),
        ],
      _ => const <_StatusAction>[],
    };

    if (actions.isEmpty) return const Text('-');
    return Wrap(
      spacing: 6,
      children: [
        for (final action in actions)
          IconButton(
            tooltip: action.label,
            onPressed: () => _handleAction(context, action.status),
            icon: Icon(action.icon, size: 20),
          ),
      ],
    );
  }

  Future<void> _handleAction(BuildContext context, String nextStatus) async {
    if (nextStatus != 'action_taken') {
      await onChanged(nextStatus);
      return;
    }

    final note = await showDialog<String>(
      context: context,
      builder: (context) => const _ActionTakenDialog(),
    );
    if (note == null || note.trim().isEmpty) return;
    await onChanged(nextStatus, actionTakenNote: note.trim());
  }
}

class _ActionTakenDialog extends StatefulWidget {
  const _ActionTakenDialog();

  @override
  State<_ActionTakenDialog> createState() => _ActionTakenDialogState();
}

class _ActionTakenDialogState extends State<_ActionTakenDialog> {
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Catatan Tindakan'),
      content: TextField(
        controller: _noteCtrl,
        maxLines: 4,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Tindakan yang diambil',
          hintText: 'Contoh: Kaunseling pelajar dan hubungi penjaga.',
          alignLabelWithHint: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            final note = _noteCtrl.text.trim();
            if (note.isEmpty) return;
            Navigator.of(context).pop(note);
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class _StatusAction {
  const _StatusAction(this.status, this.label, this.icon);

  final String status;
  final String label;
  final IconData icon;
}
