import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../state/app_scope.dart';
import '../widgets/app_layout.dart';
import '../widgets/status_chip.dart';

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
  int _selectedTab = 0;

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
    final canReviewDiscipline = user.role == UserRole.ketua_jabatan ||
        user.role == UserRole.ketua_program;
    if (!isPensyarah && !canReviewDiscipline) {
      return const PageHeader(
        title: 'Akses Tidak Dibenarkan',
        subtitle:
            'Hanya Pensyarah boleh melapor disiplin. Ketua Jabatan dan Ketua Program boleh membuat semakan mengikut skop.',
      );
    }

    final visibleReports = state.scopedDisciplineReports;
    final actionRequiredReports = visibleReports
        .where((report) => _isActionRequiredStatus(report.status))
        .toList();
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

    final tabLabels = isPensyarah
        ? const ['Lapor Disiplin Baharu', 'Semua Laporan Saya']
        : const ['Tindakan Diperlukan', 'Semua Laporan'];
    if (_selectedTab >= tabLabels.length) _selectedTab = 0;

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
          trailing: StatusChip('${visibleReports.length} laporan'),
        ),
        const SizedBox(height: 12),
        _DisciplineTabSelector(
          selectedIndex: _selectedTab,
          labels: tabLabels,
          onChanged: (index) => setState(() => _selectedTab = index),
        ),
        const SizedBox(height: 16),
        if (isPensyarah && _selectedTab == 0)
          _NewDisciplineReportPanel(
            slots: slots,
            studentsList: studentsList,
            selectedSlot: selectedSlot,
            selectedStudentId: selectedStudentId,
            issueType: issueType,
            severity: severity,
            descriptionController: _descCtrl,
            submitting: _submitting,
            onSlotChanged: (value) => setState(() {
              selectedSlotId = value;
              selectedStudentId = null;
            }),
            onStudentChanged: (value) =>
                setState(() => selectedStudentId = value),
            onIssueTypeChanged: (value) =>
                setState(() => issueType = value ?? issueType),
            onSeverityChanged: (value) =>
                setState(() => severity = value ?? severity),
            onSubmit: () => _submitReport(
              state: state,
              user: user,
              studentsList: studentsList,
              selectedSlot: selectedSlot,
            ),
          )
        else if (isPensyarah)
          _DisciplineReportListPanel(
            title: 'Semua Laporan Saya',
            subtitle: 'Sejarah laporan disiplin yang telah anda hantar.',
            reports: visibleReports,
            canReview: false,
            emptyText: 'Tiada laporan disiplin ditemui.',
            onViewDetails: (report) => _showReportDetails(report),
            onTakeAction: (report) => _showTakeActionDialog(state, report),
            onReject: (report) => _showRejectDialog(state, report),
            onClose: (report) => _showCloseDialog(state, report),
          )
        else if (_selectedTab == 0)
          _DisciplineReportListPanel(
            title: 'Tindakan Diperlukan',
            subtitle: 'Laporan baharu atau menunggu semakan dalam skop anda.',
            reports: actionRequiredReports,
            canReview: canReviewDiscipline,
            emptyText: 'Tiada laporan yang memerlukan tindakan.',
            onViewDetails: (report) => _showReportDetails(report),
            onTakeAction: (report) => _showTakeActionDialog(state, report),
            onReject: (report) => _showRejectDialog(state, report),
            onClose: (report) => _showCloseDialog(state, report),
          )
        else
          _DisciplineReportListPanel(
            title: 'Semua Laporan',
            subtitle:
                'Semua laporan disiplin dalam skop peranan dan program anda.',
            reports: visibleReports,
            canReview: canReviewDiscipline,
            emptyText: 'Tiada laporan disiplin ditemui.',
            onViewDetails: (report) => _showReportDetails(report),
            onTakeAction: (report) => _showTakeActionDialog(state, report),
            onReject: (report) => _showRejectDialog(state, report),
            onClose: (report) => _showCloseDialog(state, report),
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
      _selectedTab = 1;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan disiplin telah dihantar.')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showReportDetails(DisciplineReport report) {
    return showDialog<void>(
      context: context,
      builder: (context) => _DisciplineDetailDialog(report: report),
    );
  }

  Future<void> _showTakeActionDialog(
    dynamic state,
    DisciplineReport report,
  ) async {
    final result = await showDialog<_ReviewActionResult>(
      context: context,
      builder: (context) => const _TakeActionDialog(),
    );
    if (result == null) return;
    try {
      await state.updateDiscipline(
        report.id,
        'action_taken',
        reviewerNotes: result.reviewerNotes,
        actionTaken: result.actionTaken,
        actionTakenNote: result.actionTaken,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Tindakan laporan disiplin telah direkodkan.'),
      ));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal merekod tindakan: $error'),
      ));
    }
  }

  Future<void> _showRejectDialog(
    dynamic state,
    DisciplineReport report,
  ) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => const _RejectReportDialog(),
    );
    if (reason == null || reason.trim().isEmpty) return;
    try {
      await state.updateDiscipline(
        report.id,
        'rejected',
        rejectionReason: reason.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Laporan disiplin telah ditolak.'),
      ));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal menolak laporan: $error'),
      ));
    }
  }

  Future<void> _showCloseDialog(
    dynamic state,
    DisciplineReport report,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tutup Laporan?'),
        content: const Text(
          'Laporan ini akan ditandakan sebagai ditutup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Tutup Laporan'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await state.updateDiscipline(report.id, 'closed');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Laporan disiplin telah ditutup.'),
      ));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal menutup laporan: $error'),
      ));
    }
  }
}

class _DisciplineTabSelector extends StatelessWidget {
  const _DisciplineTabSelector({
    required this.selectedIndex,
    required this.labels,
    required this.onChanged,
  });

  final int selectedIndex;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var index = 0; index < labels.length; index++)
          ChoiceChip(
            label: Text(labels[index]),
            selected: selectedIndex == index,
            onSelected: (_) => onChanged(index),
          ),
      ],
    );
  }
}

class _NewDisciplineReportPanel extends StatelessWidget {
  const _NewDisciplineReportPanel({
    required this.slots,
    required this.studentsList,
    required this.selectedSlot,
    required this.selectedStudentId,
    required this.issueType,
    required this.severity,
    required this.descriptionController,
    required this.submitting,
    required this.onSlotChanged,
    required this.onStudentChanged,
    required this.onIssueTypeChanged,
    required this.onSeverityChanged,
    required this.onSubmit,
  });

  final List<TimetableSlot> slots;
  final List<Student> studentsList;
  final TimetableSlot? selectedSlot;
  final String? selectedStudentId;
  final String issueType;
  final String severity;
  final TextEditingController descriptionController;
  final bool submitting;
  final ValueChanged<String?> onSlotChanged;
  final ValueChanged<String?> onStudentChanged;
  final ValueChanged<String?> onIssueTypeChanged;
  final ValueChanged<String?> onSeverityChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: 'Lapor Disiplin Baharu',
      subtitle: studentsList.isNotEmpty
          ? 'Pilih kelas, pelajar dan nyatakan isu yang berlaku.'
          : 'Tiada pelajar dijumpai untuk kelas anda. Sila semak jadual atau hubungi pentadbir.',
      child: studentsList.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Sila muat naik jadual untuk menghubungkan pelajar dengan kelas anda.',
                  style: TextStyle(color: Color(0xff94a3b8)),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (selectedSlot != null) ...[
                  _ClassSummary(slot: selectedSlot!),
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
                        decoration: const InputDecoration(labelText: 'Kelas'),
                        items: slots
                            .map((slot) => DropdownMenuItem(
                                  value: slot.id,
                                  child: Text(
                                    '${slot.subjectCode} - ${slot.section}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: onSlotChanged,
                      ),
                    ),
                    SizedBox(
                      width: 320,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: selectedStudentId,
                        decoration:
                            const InputDecoration(labelText: 'Pilih Pelajar'),
                        items: studentsList
                            .map((s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(
                                    '${s.name} (${s.section})',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: onStudentChanged,
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
                            .map((i) =>
                                DropdownMenuItem(value: i, child: Text(i)))
                            .toList(),
                        onChanged: onIssueTypeChanged,
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: severity,
                        decoration: const InputDecoration(labelText: 'Tahap'),
                        items: ['Low', 'Medium', 'High']
                            .map((i) =>
                                DropdownMenuItem(value: i, child: Text(i)))
                            .toList(),
                        onChanged: onSeverityChanged,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
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
                    onPressed: submitting ? null : onSubmit,
                    icon: submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label:
                        Text(submitting ? 'Menghantar...' : 'Hantar Laporan'),
                  ),
                ),
              ],
            ),
    );
  }
}

class _DisciplineReportListPanel extends StatelessWidget {
  const _DisciplineReportListPanel({
    required this.title,
    required this.subtitle,
    required this.reports,
    required this.canReview,
    required this.emptyText,
    required this.onViewDetails,
    required this.onTakeAction,
    required this.onReject,
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final List<DisciplineReport> reports;
  final bool canReview;
  final String emptyText;
  final ValueChanged<DisciplineReport> onViewDetails;
  final ValueChanged<DisciplineReport> onTakeAction;
  final ValueChanged<DisciplineReport> onReject;
  final ValueChanged<DisciplineReport> onClose;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: title,
      subtitle: subtitle,
      child: Column(
        children: [
          for (final report in reports)
            _DisciplineReportItem(
              report: report,
              status: _normalizeDisciplineStatus(report.status),
              canApprove: canReview,
              onViewDetails: () => onViewDetails(report),
              onTakeAction: () => onTakeAction(report),
              onReject: () => onReject(report),
              onClose: () => onClose(report),
            ),
          if (reports.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  emptyText,
                  style: const TextStyle(color: Color(0xff64748b)),
                ),
              ),
            ),
        ],
      ),
    );
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
    required this.onViewDetails,
    required this.onTakeAction,
    required this.onReject,
    required this.onClose,
  });

  final DisciplineReport report;
  final String status;
  final bool canApprove;
  final VoidCallback onViewDetails;
  final VoidCallback onTakeAction;
  final VoidCallback onReject;
  final VoidCallback onClose;

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
              _ReportMeta(
                  label: 'Tarikh', value: report.createdAt ?? report.date),
              _ReportMeta(label: 'Reviewer', value: reviewers),
            ],
          ),
          if (_reviewSummary(report).isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xfff1f5f9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _reviewSummary(report),
                style: const TextStyle(color: Color(0xff334155)),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _DisciplineCardActions(
            status: status,
            canReview: canApprove,
            onViewDetails: onViewDetails,
            onTakeAction: onTakeAction,
            onReject: onReject,
            onClose: onClose,
          ),
        ],
      ),
    );
  }

  String _reviewSummary(DisciplineReport report) {
    final lines = <String>[];
    final reviewer = report.reviewedByName ?? report.actionTakenByName;
    if (reviewer != null && reviewer.trim().isNotEmpty) {
      lines.add('Disemak oleh: $reviewer');
    }
    final notes = report.reviewerNotes;
    if (notes != null && notes.trim().isNotEmpty) {
      lines.add('Catatan semakan: $notes');
    }
    final action = report.actionTaken ?? report.actionTakenNote;
    if (action != null && action.trim().isNotEmpty) {
      lines.add('Tindakan: $action');
    }
    final rejection = report.rejectionReason;
    if (rejection != null && rejection.trim().isNotEmpty) {
      lines.add('Sebab penolakan: $rejection');
    }
    return lines.join('\n');
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

class _DisciplineCardActions extends StatelessWidget {
  const _DisciplineCardActions({
    required this.status,
    required this.canReview,
    required this.onViewDetails,
    required this.onTakeAction,
    required this.onReject,
    required this.onClose,
  });

  final String status;
  final bool canReview;
  final VoidCallback onViewDetails;
  final VoidCallback onTakeAction;
  final VoidCallback onReject;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: onViewDetails,
          icon: const Icon(Icons.visibility_outlined, size: 18),
          label: const Text('Lihat Butiran'),
        ),
        if (canReview && status == 'pending') ...[
          FilledButton.icon(
            onPressed: onTakeAction,
            icon: const Icon(Icons.task_alt_outlined, size: 18),
            label: const Text('Ambil Tindakan'),
          ),
          OutlinedButton.icon(
            onPressed: onReject,
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Tolak'),
          ),
        ],
        if (canReview && status == 'action_taken')
          OutlinedButton.icon(
            onPressed: onClose,
            icon: const Icon(Icons.lock_outline, size: 18),
            label: const Text('Tutup Laporan'),
          ),
      ],
    );
  }
}

class _DisciplineDetailDialog extends StatelessWidget {
  const _DisciplineDetailDialog({required this.report});

  final DisciplineReport report;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Butiran Laporan Disiplin'),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailSection(
                title: 'Maklumat Laporan',
                rows: [
                  ('ID Laporan', report.id),
                  ('Status', _statusLabel(report.status)),
                  ('Tahap', report.severity),
                  ('Jenis Isu', report.issueType),
                  ('Tarikh Laporan', report.createdAt ?? report.date),
                  ('Catatan', report.description),
                ],
              ),
              _DetailSection(
                title: 'Maklumat Pelajar',
                rows: [
                  ('Nama Pelajar', report.studentName),
                  ('ID Pelajar', report.studentId),
                  ('Kelas / Seksyen', report.section),
                  ('Program', report.programName ?? report.programId ?? '-'),
                ],
              ),
              _DetailSection(
                title: 'Maklumat Kelas / Subjek',
                rows: [
                  ('Kod Subjek', report.subjectCode ?? '-'),
                  ('Nama Subjek', report.subjectName ?? report.subject),
                  ('Dilapor Oleh', report.createdByName ?? report.lecturer),
                ],
              ),
              _DetailSection(
                title: 'Maklumat Semakan',
                rows: [
                  ('Disemak Oleh', report.reviewedByName ?? '-'),
                  ('Peranan Penyemak', report.reviewerRole ?? '-'),
                  ('Tarikh Semakan', report.reviewedAt ?? '-'),
                  ('Catatan Semakan', report.reviewerNotes ?? '-'),
                  (
                    'Tindakan Diambil',
                    report.actionTaken ?? report.actionTakenNote ?? '-'
                  ),
                  ('Sebab Penolakan', report.rejectionReason ?? '-'),
                  ('Tarikh Ditutup', report.closedAt ?? '-'),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xff0f172a),
            ),
          ),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xffe2e8f0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                for (final row in rows)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 150,
                          child: Text(
                            row.$1,
                            style: const TextStyle(
                              color: Color(0xff64748b),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(
                            child: Text(row.$2.trim().isEmpty ? '-' : row.$2)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewActionResult {
  const _ReviewActionResult({
    required this.actionTaken,
    required this.reviewerNotes,
  });

  final String actionTaken;
  final String reviewerNotes;
}

class _TakeActionDialog extends StatefulWidget {
  const _TakeActionDialog();

  @override
  State<_TakeActionDialog> createState() => _TakeActionDialogState();
}

class _TakeActionDialogState extends State<_TakeActionDialog> {
  final _notesCtrl = TextEditingController();
  final _actionCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    _actionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ambil Tindakan'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan Semakan',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _actionCtrl,
              maxLines: 3,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Tindakan Diambil',
                hintText: 'Contoh: Kaunseling pelajar dan hubungi penjaga.',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            final action = _actionCtrl.text.trim();
            if (action.isEmpty) return;
            Navigator.of(context).pop(_ReviewActionResult(
              actionTaken: action,
              reviewerNotes: _notesCtrl.text.trim(),
            ));
          },
          child: const Text('Simpan Tindakan'),
        ),
      ],
    );
  }
}

class _RejectReportDialog extends StatefulWidget {
  const _RejectReportDialog();

  @override
  State<_RejectReportDialog> createState() => _RejectReportDialogState();
}

class _RejectReportDialogState extends State<_RejectReportDialog> {
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tolak Laporan'),
      content: SizedBox(
        width: 520,
        child: TextField(
          controller: _reasonCtrl,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Sebab Penolakan',
            hintText: 'Nyatakan sebab laporan ditolak.',
            alignLabelWithHint: true,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            final reason = _reasonCtrl.text.trim();
            if (reason.isEmpty) return;
            Navigator.of(context).pop(reason);
          },
          child: const Text('Tolak Laporan'),
        ),
      ],
    );
  }
}

bool _isActionRequiredStatus(String status) {
  return _normalizeDisciplineStatus(status) == 'pending';
}

String _normalizeDisciplineStatus(String status) {
  final normalized = status.trim().toLowerCase().replaceAll(' ', '_');
  return switch (normalized) {
    'new' ||
    'submitted' ||
    'pending' ||
    'menunggu' ||
    'menunggu_semakan' =>
      'pending',
    'under_review' || 'reviewed' || 'disemak' => 'reviewed',
    'approved' ||
    'resolved' ||
    'action_taken' ||
    'tindakan_diambil' =>
      'action_taken',
    'closed' || 'ditutup' => 'closed',
    'rejected' || 'ditolak' => 'rejected',
    _ => normalized,
  };
}

String _statusLabel(String status) {
  return switch (_normalizeDisciplineStatus(status)) {
    'pending' => 'Menunggu Semakan',
    'reviewed' => 'Disemak',
    'action_taken' => 'Tindakan Diambil',
    'closed' => 'Ditutup',
    'rejected' => 'Ditolak',
    _ => status,
  };
}
