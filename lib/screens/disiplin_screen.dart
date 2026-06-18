import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../state/app_scope.dart';
import '../widgets/app_layout.dart';
import '../widgets/app_theme.dart';
import '../widgets/mobile_components.dart';
import '../widgets/responsive.dart';
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
  String _filterStatus = 'Semua';

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
      return const AppPageHeader(
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

    if (context.isMobile) {
      final reviewedCount = visibleReports
          .where((report) =>
              _normalizeDisciplineStatus(report.status) == 'reviewed' ||
              _normalizeDisciplineStatus(report.status) == 'action_taken' ||
              _normalizeDisciplineStatus(report.status) == 'closed')
          .length;
      return AppPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MobileHeroCard(
              icon: Icons.report_problem_outlined,
              title: isPensyarah ? 'Laporan Disiplin Saya' : 'Laporan Disiplin',
              subtitle: isPensyarah
                  ? 'Hantar dan semak laporan disiplin pelajar anda.'
                  : 'Semak kes disiplin dan rekod tindakan mengikut skop.',
              accentColor: AppColors.danger,
              chips: [
                StatusChip('${actionRequiredReports.length} Menunggu'),
                StatusChip('$reviewedCount Disemak'),
                StatusChip('${visibleReports.length} Laporan'),
              ],
            ),
            const SizedBox(height: 14),
            MobileSegmentedControl(
              labels: tabLabels,
              selectedIndex: _selectedTab,
              onChanged: (index) => setState(() {
                _selectedTab = index;
                _filterStatus = 'Semua';
              }),
            ),
            const SizedBox(height: 14),
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
                filterStatus: _filterStatus,
                onFilterChanged: (v) => setState(() => _filterStatus = v),
                onViewDetails: (report) => _showReportDetails(report),
                onTakeAction: (report) => _showTakeActionDialog(state, report),
                onReject: (report) => _showRejectDialog(state, report),
                onClose: (report) => _showCloseDialog(state, report),
              )
            else if (_selectedTab == 0)
              _DisciplineReportListPanel(
                title: 'Tindakan Diperlukan',
                subtitle:
                    'Laporan baharu atau menunggu semakan dalam skop anda.',
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
                filterStatus: _filterStatus,
                onFilterChanged: (v) => setState(() => _filterStatus = v),
                onViewDetails: (report) => _showReportDetails(report),
                onTakeAction: (report) => _showTakeActionDialog(state, report),
                onReject: (report) => _showRejectDialog(state, report),
                onClose: (report) => _showCloseDialog(state, report),
              ),
          ],
        ),
      );
    }

    return AppPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppPageHeader(
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
            onChanged: (index) => setState(() {
              _selectedTab = index;
              _filterStatus = 'Semua';
            }),
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
              filterStatus: _filterStatus,
              onFilterChanged: (v) => setState(() => _filterStatus = v),
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
              subtitle: 'Sejarah laporan kes disiplin dalam skop anda.',
              reports: visibleReports,
              canReview: canReviewDiscipline,
              emptyText: 'Tiada laporan disiplin ditemui.',
              filterStatus: _filterStatus,
              onFilterChanged: (v) => setState(() => _filterStatus = v),
              onViewDetails: (report) => _showReportDetails(report),
              onTakeAction: (report) => _showTakeActionDialog(state, report),
              onReject: (report) => _showRejectDialog(state, report),
              onClose: (report) => _showCloseDialog(state, report),
            ),
        ],
      ),
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
    if (context.isMobile) {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => MobileBottomSheet(
          title: 'Butiran Laporan Disiplin',
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * .72,
            ),
            child: SingleChildScrollView(
              child: _DisciplineDetailContent(report: report),
            ),
          ),
        ),
      );
    }
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: index == 0 ? 0 : 6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(9),
                  onTap: () => onChanged(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: selectedIndex == index
                          ? AppColors.primary.withValues(alpha: .12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      labels[index],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selectedIndex == index
                            ? AppColors.primary
                            : AppColors.muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
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
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 760;
                final fieldWidth = isWide
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;
                final submitButton = FilledButton.icon(
                  onPressed: submitting ? null : onSubmit,
                  icon: submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(submitting ? 'Menghantar...' : 'Hantar Laporan'),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FormSectionTitle('Maklumat Sesi'),
                    if (selectedSlot != null)
                      _ClassSummary(slot: selectedSlot!)
                    else
                      const _EmptySessionSummary(),
                    const SizedBox(height: 18),
                    const _FormSectionTitle('Butiran Laporan'),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: fieldWidth,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: selectedSlot?.id,
                            decoration:
                                const InputDecoration(labelText: 'Kelas'),
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
                          width: fieldWidth,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: selectedStudentId,
                            decoration: const InputDecoration(
                                labelText: 'Pilih Pelajar'),
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
                          width: fieldWidth,
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
                          width: fieldWidth,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: severity,
                            decoration: const InputDecoration(
                                labelText: 'Tahap Keseriusan'),
                            items: ['Low', 'Medium', 'High']
                                .map((i) => DropdownMenuItem(
                                    value: i, child: Text(_severityLabel(i))))
                                .toList(),
                            onChanged: onSeverityChanged,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const _FormSectionTitle('Keterangan'),
                    TextField(
                      controller: descriptionController,
                      minLines: 4,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Keterangan / Catatan',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Contoh: Pelajar tidak hadir 4 minggu berturut-turut tanpa sebab.',
                      style: TextStyle(color: Color(0xff64748b), fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: isWide
                          ? submitButton
                          : SizedBox(
                              width: double.infinity,
                              child: submitButton,
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _FormSectionTitle extends StatelessWidget {
  const _FormSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xff0f172a),
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
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
    this.filterStatus = 'Semua',
    this.onFilterChanged,
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
  final String filterStatus;
  final ValueChanged<String>? onFilterChanged;

  static const _filterValues = ['Semua', 'pending', 'reviewed', 'action_taken', 'closed', 'rejected'];
  static const _filterLabels = ['Semua', 'Menunggu', 'Disemak', 'Tindakan Diambil', 'Ditutup', 'Ditolak'];

  @override
  Widget build(BuildContext context) {
    final filteredReports = filterStatus == 'Semua'
        ? reports
        : reports
            .where((r) => _normalizeDisciplineStatus(r.status) == filterStatus)
            .toList();

    final filterWidget = onFilterChanged != null
        ? Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_filterValues.length, (i) {
                final val = _filterValues[i];
                final label = _filterLabels[i];
                final active = filterStatus == val;
                return FilterChip(
                  label: Text(label),
                  selected: active,
                  onSelected: (_) => onFilterChanged!(val),
                  selectedColor: const Color(0xffdbeafe),
                  checkmarkColor: const Color(0xff1d4ed8),
                );
              }),
            ),
          )
        : const SizedBox.shrink();

    if (context.isMobile) {
      return MobileSection(
        title: title,
        subtitle: subtitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onFilterChanged != null) filterWidget,
            if (filteredReports.isEmpty)
              MobileEmptyState(
                icon: Icons.inbox_outlined,
                title: emptyText,
                subtitle: 'Tiada rekod untuk paparan semasa.',
              )
            else
              Column(
                children: [
                  for (final report in filteredReports)
                    _DisciplineReportItem(
                      report: report,
                      status: _normalizeDisciplineStatus(report.status),
                      canApprove: canReview,
                      onViewDetails: () => onViewDetails(report),
                      onTakeAction: () => onTakeAction(report),
                      onReject: () => onReject(report),
                      onClose: () => onClose(report),
                    ),
                ],
              ),
          ],
        ),
      );
    }

    return AppPanel(
      title: title,
      subtitle: subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onFilterChanged != null) filterWidget,
          for (final report in filteredReports)
            _DisciplineReportItem(
              report: report,
              status: _normalizeDisciplineStatus(report.status),
              canApprove: canReview,
              onViewDetails: () => onViewDetails(report),
              onTakeAction: () => onTakeAction(report),
              onReject: () => onReject(report),
              onClose: () => onClose(report),
            ),
          if (filteredReports.isEmpty)
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        border: Border.all(color: const Color(0xffdbeafe)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _SessionSummaryItem(
            icon: Icons.menu_book_outlined,
            label: 'Subjek',
            value: '${slot.subjectCode} - ${slot.subjectName}',
          ),
          _SessionSummaryItem(
            icon: Icons.groups_outlined,
            label: 'Kelas',
            value: slot.section,
          ),
          _SessionSummaryItem(
            icon: Icons.schedule,
            label: 'Masa',
            value: '${slot.startTime}-${slot.endTime}',
          ),
          _SessionSummaryItem(
            icon: Icons.meeting_room_outlined,
            label: 'Bilik',
            value: slot.room,
          ),
        ],
      ),
    );
  }
}

class _EmptySessionSummary extends StatelessWidget {
  const _EmptySessionSummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        border: Border.all(color: const Color(0xffe2e8f0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Pilih kelas untuk melihat maklumat sesi.',
        style: TextStyle(color: Color(0xff64748b)),
      ),
    );
  }
}

class _SessionSummaryItem extends StatelessWidget {
  const _SessionSummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xffeff6ff),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: const Color(0xff2563eb)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xff64748b),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '-' : value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff0f172a),
                    fontWeight: FontWeight.w800,
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
    final severityTone = _severityTone(report.severity);
    final statusTone = _statusTone(status);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: .035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
              ),
              padding: context.isMobile
                  ? const EdgeInsets.fromLTRB(16, 12, 12, 12)
                  : const EdgeInsets.fromLTRB(18, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (context.isMobile) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            report.studentName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _DisciplineToneChip(
                          label: _statusLabel(status),
                          tone: statusTone,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${report.programId ?? '-'}  ·  ${report.section}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Subjek: $subject',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.report_problem_outlined,
                            size: 14, color: severityTone.color),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${report.issueType} · ${_severityLabel(report.severity)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: severityTone.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _DisciplineCardActions(
                      status: status,
                      canReview: canApprove,
                      onViewDetails: onViewDetails,
                      onTakeAction: onTakeAction,
                      onReject: onReject,
                      onClose: onClose,
                    ),
                  ] else ...[
                    // Desktop layout
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
                                  color: AppColors.primaryDark,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${report.programName ?? report.programId ?? '-'} | ${report.section} | $subject',
                                style: const TextStyle(color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.end,
                          children: [
                            _DisciplineToneChip(
                              label: _severityLabel(report.severity),
                              tone: severityTone,
                              icon: Icons.priority_high_rounded,
                            ),
                            _DisciplineToneChip(
                              label: _statusLabel(status),
                              tone: statusTone,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.report_problem_outlined,
                          size: 17,
                          color: severityTone.color,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            report.issueType,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.description.isEmpty ? '-' : report.description,
                      style: const TextStyle(color: Color(0xff334155)),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _ReportMeta(label: 'Laporan', value: report.id),
                        _ReportMeta(
                          label: 'Dilapor oleh',
                          value: report.createdByName ?? report.lecturer,
                        ),
                        _ReportMeta(
                          label: 'Tarikh',
                          value: report.createdAt ?? report.date,
                        ),
                        _ReportMeta(label: 'Reviewer', value: reviewers),
                      ],
                    ),
                    if (_reviewSummary(report).isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceTint,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
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
                ],
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: Container(color: severityTone.color),
            ),
          ],
        ),
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

class _DisciplineTone {
  const _DisciplineTone({
    required this.color,
    required this.background,
    required this.border,
  });

  final Color color;
  final Color background;
  final Color border;
}

class _DisciplineToneChip extends StatelessWidget {
  const _DisciplineToneChip({
    required this.label,
    required this.tone,
    this.icon,
  });

  final String label;
  final _DisciplineTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.background,
        border: Border.all(color: tone.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: tone.color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: tone.color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

String _severityLabel(String severity) {
  return switch (severity.trim().toLowerCase()) {
    'low' || 'rendah' => 'Rendah',
    'medium' || 'sederhana' => 'Sederhana',
    'high' || 'tinggi' => 'Tinggi',
    _ => severity,
  };
}

_DisciplineTone _severityTone(String severity) {
  return switch (severity.trim().toLowerCase()) {
    'high' || 'tinggi' => const _DisciplineTone(
        color: Color(0xffdc2626),
        background: Color(0xfffff1f2),
        border: Color(0xfffecdd3),
      ),
    'medium' || 'sederhana' => const _DisciplineTone(
        color: Color(0xffb45309),
        background: Color(0xfffffbeb),
        border: Color(0xfffde68a),
      ),
    'low' || 'rendah' => const _DisciplineTone(
        color: Color(0xff15803d),
        background: Color(0xfff0fdf4),
        border: Color(0xffbbf7d0),
      ),
    _ => const _DisciplineTone(
        color: Color(0xff475569),
        background: Color(0xfff8fafc),
        border: Color(0xffe2e8f0),
      ),
  };
}

_DisciplineTone _statusTone(String status) {
  return switch (_normalizeDisciplineStatus(status)) {
    'pending' => const _DisciplineTone(
        color: Color(0xffb45309),
        background: Color(0xfffffbeb),
        border: Color(0xfffde68a),
      ),
    'reviewed' => const _DisciplineTone(
        color: Color(0xff4338ca),
        background: Color(0xffeef2ff),
        border: Color(0xffc7d2fe),
      ),
    'action_taken' => const _DisciplineTone(
        color: Color(0xff1d4ed8),
        background: Color(0xffeff6ff),
        border: Color(0xffbfdbfe),
      ),
    'closed' => const _DisciplineTone(
        color: Color(0xff166534),
        background: Color(0xfff0fdf4),
        border: Color(0xffbbf7d0),
      ),
    'rejected' => const _DisciplineTone(
        color: Color(0xffdc2626),
        background: Color(0xfffff1f2),
        border: Color(0xfffecdd3),
      ),
    _ => const _DisciplineTone(
        color: Color(0xff475569),
        background: Color(0xfff8fafc),
        border: Color(0xffe2e8f0),
      ),
  };
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
            child: _DisciplineDetailContent(report: report)),
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

class _DisciplineDetailContent extends StatelessWidget {
  const _DisciplineDetailContent({required this.report});

  final DisciplineReport report;

  @override
  Widget build(BuildContext context) {
    return Column(
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
