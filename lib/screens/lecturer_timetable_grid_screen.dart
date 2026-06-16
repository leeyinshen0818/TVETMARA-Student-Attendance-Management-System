// lib/screens/lecturer_timetable_grid_screen.dart
//
// Module 5 – Timetable Slot Display  |  Lecturer (Pensyarah) View
// Author : Farra
//
// FIX: Removed nested Scaffold that caused unbounded-height layout crash.
// The screen is now a plain widget that can be embedded inside the app's
// home shell (which already owns the Scaffold/AppBar).
//
// READ-ONLY — no writes, no attendance forms, no upload code.
// Placeholder hook: onSlotSelected(slotId, week) → Yee Wen's module.

import 'package:flutter/material.dart';

import '../state/lecturer_timetable_controller.dart';
import '../services/lecturer_timetable_service.dart';
import '../services/lecturer_export_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Colour tokens
// ─────────────────────────────────────────────────────────────────────────────

const Color _kTeal = Color(0xFF1B8CA6);
const Color _kTableHead = Color(0xFFF5F0E8);
const Color _kPageBg = Color(0xFFF7F9FB);
const Color _kCardBg = Colors.white;
const Color _kBorder = Color(0xFFE2E8EF);
const Color _kText = Color(0xFF1A2E3F);
const Color _kMuted = Color(0xFF5C7A8A);

// ─────────────────────────────────────────────────────────────────────────────
// Entry-point widget
// ─────────────────────────────────────────────────────────────────────────────

class LecturerTimetableGridScreen extends StatefulWidget {
  const LecturerTimetableGridScreen({
    super.key,
    required this.lecturerId,
    required this.lecturerName,
    required this.lecturerEmail,
    required this.programId,
    this.lecturerProfileId,
    this.onSlotSelected,
    this.onNavigateToAttendance,
    this.onNavigateToTempahan,
  });

  final String lecturerId;
  final String lecturerName;
  final String lecturerEmail;
  final String programId;
  final String? lecturerProfileId;

  /// Placeholder callback — Yee Wen wires attendance-taking here.
  final void Function(String slotId, String week)? onSlotSelected;

  /// Callback to switch to Attendance tab in parent shell
  final VoidCallback? onNavigateToAttendance;

  /// Callback to switch to Tempahan tab in parent shell
  final VoidCallback? onNavigateToTempahan;

  @override
  State<LecturerTimetableGridScreen> createState() =>
      _LecturerTimetableGridScreenState();
}

class _LecturerTimetableGridScreenState
    extends State<LecturerTimetableGridScreen> {
  late final LecturerTimetableController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LecturerTimetableController(
      service: LecturerTimetableService(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LecturerTimetableScope(
      controller: _controller,
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => _LecturerTimetableBody(
          lecturerId: widget.lecturerId,
          lecturerName: widget.lecturerName,
          lecturerEmail: widget.lecturerEmail,
          programId: widget.programId,
          lecturerProfileId: widget.lecturerProfileId,
          onSlotSelected: widget.onSlotSelected,
          onNavigateToAttendance: widget.onNavigateToAttendance,
          onNavigateToTempahan: widget.onNavigateToTempahan,
          controller: _controller,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body — a plain scrollable Column; NO nested Scaffold
// ─────────────────────────────────────────────────────────────────────────────

class _LecturerTimetableBody extends StatefulWidget {
  const _LecturerTimetableBody({
    required this.lecturerId,
    required this.lecturerName,
    required this.lecturerEmail,
    required this.programId,
    required this.lecturerProfileId,
    required this.onSlotSelected,
    required this.controller,
    this.onNavigateToAttendance,
    this.onNavigateToTempahan,
  });

  final String lecturerId;
  final String lecturerName;
  final String lecturerEmail;
  final String programId;
  final String? lecturerProfileId;
  final void Function(String slotId, String week)? onSlotSelected;
  final LecturerTimetableController controller;
  final VoidCallback? onNavigateToAttendance;
  final VoidCallback? onNavigateToTempahan;

  @override
  State<_LecturerTimetableBody> createState() => _LecturerTimetableBodyState();
}

class _LecturerTimetableBodyState extends State<_LecturerTimetableBody> {
  String _filterCourse = 'Semua Kursus';
  String _filterSection = 'Semua Seksyen';
  String _searchQuery = '';

  List<LecturerSlot> _applyFilters(List<LecturerSlot> raw) {
    return raw.where((s) {
      if (_filterCourse != 'Semua Kursus' && s.subjectCode != _filterCourse) {
        return false;
      }
      if (_filterSection != 'Semua Seksyen' && s.section != _filterSection) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!s.subjectCode.toLowerCase().contains(q) &&
            !s.subjectName.toLowerCase().contains(q) &&
            !s.roomId.toLowerCase().contains(q) &&
            !s.section.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final week = 'M${widget.controller.selectedWeek}';

    return ColoredBox(
      color: _kPageBg,
      child: StreamBuilder<List<LecturerSlot>>(
        stream: widget.controller.slotsStream(
          lecturerId: widget.lecturerId,
          lecturerEmail: widget.lecturerEmail,
          lecturerProfileId: widget.lecturerProfileId,
        ),
        builder: (context, snapshot) {
          final loading = snapshot.connectionState == ConnectionState.waiting;
          final allSlots = snapshot.data ?? [];
          final filtered = _applyFilters(allSlots);
          final courses = [
            'Semua Kursus',
            ...{...allSlots.map((s) => s.subjectCode)}
          ];
          final sections = [
            'Semua Seksyen',
            ...{...allSlots.map((s) => s.section)}
          ];
          final uniqueSections = {...allSlots.map((s) => s.section)}.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _PageHeader(week: week, controller: widget.controller),
              _StatCardRow(
                totalSlots: allSlots.length,
                sections: uniqueSections,
              ),
              _FilterBar(
                course: _filterCourse,
                section: _filterSection,
                searchQuery: _searchQuery,
                courseOptions: courses,
                sectionOptions: sections,
                onCourseChanged: (v) => setState(() => _filterCourse = v),
                onSectionChanged: (v) => setState(() => _filterSection = v),
                onSearchChanged: (v) => setState(() => _searchQuery = v),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: loading
                    ? const _LoadingState()
                    : snapshot.hasError
                        ? _ErrorState(error: snapshot.error.toString())
                        : _OfficialTable(
                            slots: filtered,
                            week: week,
                            lecturerName: widget.lecturerName,
                            lecturerEmail: widget.lecturerEmail,
                            programId: widget.programId,
                            onSlotSelected: widget.onSlotSelected,
                            onNavigateToAttendance:
                                widget.onNavigateToAttendance,
                            onNavigateToTempahan: widget.onNavigateToTempahan,
                          ),
              ),
              const SizedBox(height: 36),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page header  (title + week selector)
// ─────────────────────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.week, required this.controller});
  final String week;
  final LecturerTimetableController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kCardBg,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jadual Waktu Pensyarah',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _kText,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat card row
// ─────────────────────────────────────────────────────────────────────────────

class _StatCardRow extends StatelessWidget {
  const _StatCardRow({required this.totalSlots, required this.sections});
  final int totalSlots;
  final int sections;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kCardBg,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          Expanded(child: _StatCard(label: 'KELAS', value: '$totalSlots')),
          const SizedBox(width: 12),
          const Expanded(child: _StatCard(label: 'KELAS GANTI', value: '6')),
          const SizedBox(width: 12),
          Expanded(child: _StatCard(label: 'SECTION', value: '$sections')),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kMuted,
                  letterSpacing: 0.4)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _kText,
                  height: 1)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter bar
// ─────────────────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.course,
    required this.section,
    required this.searchQuery,
    required this.courseOptions,
    required this.sectionOptions,
    required this.onCourseChanged,
    required this.onSectionChanged,
    required this.onSearchChanged,
  });

  final String course;
  final String section;
  final String searchQuery;
  final List<String> courseOptions;
  final List<String> sectionOptions;
  final ValueChanged<String> onCourseChanged;
  final ValueChanged<String> onSectionChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, c) {
            final isWide = c.maxWidth > 560;
            final widgets = [
              _FilterDropdown(
                label: 'Kursus',
                value: course,
                options: courseOptions,
                onChanged: onCourseChanged,
              ),
              _FilterDropdown(
                label: 'Seksyen',
                value: section,
                options: sectionOptions,
                onChanged: onSectionChanged,
              ),
              _SearchField(
                hint: 'Kod, subjek, bilik',
                onChanged: onSearchChanged,
              ),
            ];
            if (isWide) {
              return Row(
                children: widgets
                    .map((w) => Expanded(
                          child: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: w),
                        ))
                    .toList(),
              );
            }
            return Column(
              children: widgets
                  .map((w) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: w,
                      ))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final safeValue = options.contains(value) ? value : options.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: _kMuted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: _kBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: safeValue,
              isExpanded: true,
              isDense: true,
              style: const TextStyle(
                  fontSize: 13, color: _kText, fontWeight: FontWeight.w500),
              items: options
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: (v) => onChanged(v ?? 'All'),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.hint, required this.onChanged});
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Carian',
            style: TextStyle(
                fontSize: 11, color: _kMuted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        SizedBox(
          height: 38,
          child: TextField(
            onChanged: onChanged,
            style: const TextStyle(fontSize: 13, color: _kText),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  const TextStyle(fontSize: 13, color: Color(0xFFBDD0DA)),
              prefixIcon:
                  const Icon(Icons.search_rounded, size: 17, color: _kMuted),
              contentPadding: EdgeInsets.zero,
              filled: true,
              fillColor: _kCardBg,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: const BorderSide(color: _kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: const BorderSide(color: _kTeal),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Official Timetable Table  (outer card)
// ─────────────────────────────────────────────────────────────────────────────

class _OfficialTable extends StatefulWidget {
  const _OfficialTable({
    required this.slots,
    required this.week,
    required this.lecturerName,
    required this.lecturerEmail,
    required this.programId,
    required this.onSlotSelected,
    this.onNavigateToAttendance,
    this.onNavigateToTempahan,
  });

  final List<LecturerSlot> slots;
  final String week;
  final String lecturerName;
  final String lecturerEmail;
  final String programId;
  final void Function(String slotId, String week)? onSlotSelected;
  final VoidCallback? onNavigateToAttendance;
  final VoidCallback? onNavigateToTempahan;

  @override
  State<_OfficialTable> createState() => _OfficialTableState();
}

class _OfficialTableState extends State<_OfficialTable> {
  bool _exportingHtml = false;
  bool _exportingCsv = false;

  LecturerExportMeta get _meta => LecturerExportMeta(
        lecturerName: widget.lecturerName,
        lecturerEmail: widget.lecturerEmail,
        academicSession: 'JAN – JUN 2026',
        generatedAt: DateTime.now(),
      );

  Future<void> _onExportHtml() async {
    if (_exportingHtml) return;
    setState(() => _exportingHtml = true);
    try {
      await exportLecturerTimetableAsHtml(
          slots: widget.slots, meta: _meta);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Eksport gagal: $e'),
          backgroundColor: Colors.red.shade700,
        ));
      }
    } finally {
      if (mounted) setState(() => _exportingHtml = false);
    }
  }

  Future<void> _onExportCsv() async {
    if (_exportingCsv) return;
    setState(() => _exportingCsv = true);
    try {
      await exportLecturerTimetableAsCsv(
          slots: widget.slots, meta: _meta);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Muat turun gagal: $e'),
          backgroundColor: Colors.red.shade700,
        ));
      }
    } finally {
      if (mounted) setState(() => _exportingCsv = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Card header row ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.table_chart_outlined, size: 16, color: _kTeal),
                const SizedBox(width: 8),
                const Text('Jadual waktu rasmi',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kText)),
                const Spacer(),
                Text('${widget.slots.length} rekod',
                    style: const TextStyle(fontSize: 12, color: _kMuted)),
                const SizedBox(width: 12),
                // ── Export buttons (only when there are slots) ──
                if (widget.slots.isNotEmpty) ...[
                  _ExportButton(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'Eksport PDF',
                    loading: _exportingHtml,
                    color: const Color(0xFFDC2626),
                    onTap: _onExportHtml,
                    tooltip:
                        'Jana jadual rasmi sebagai PDF (buka tab baharu → Cetak → Simpan sebagai PDF)',
                  ),
                  const SizedBox(width: 8),
                  _ExportButton(
                    icon: Icons.download_outlined,
                    label: 'Muat turun CSV',
                    loading: _exportingCsv,
                    color: const Color(0xFF16A34A),
                    onTap: _onExportCsv,
                    tooltip: 'Muat turun jadual dalam format CSV',
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: _kBorder),
          Container(
            width: double.infinity,
            color: const Color(0xFF0D1B2A),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: const Text(
              'JADUAL WAKTU SEMESTER SESI 2025/2026',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.4),
            ),
          ),
          Container(
            width: double.infinity,
            color: const Color(0xFF16293D),
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: const Text(
              'PAPARAN SLOT JADUAL',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Color(0xFF7BA7BC),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: 0.5),
            ),
          ),
          if (widget.slots.isEmpty)
            _EmptyState(
                lecturerName: widget.lecturerName,
                programId: widget.programId)
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _DataTable(
                slots: widget.slots,
                week: widget.week,
                onSlotSelected: widget.onSlotSelected,
                onNavigateToAttendance: widget.onNavigateToAttendance,
                onNavigateToTempahan: widget.onNavigateToTempahan,
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Export button widget
// ─────────────────────────────────────────────────────────────────────────────

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.icon,
    required this.label,
    required this.loading,
    required this.color,
    required this.onTap,
    this.tooltip = '',
  });

  final IconData icon;
  final String label;
  final bool loading;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              loading
                  ? SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data table
// ─────────────────────────────────────────────────────────────────────────────

class _DataTable extends StatelessWidget {
  const _DataTable({
    required this.slots,
    required this.week,
    required this.onSlotSelected,
    this.onNavigateToAttendance,
    this.onNavigateToTempahan,
  });

  final List<LecturerSlot> slots;
  final String week;
  final void Function(String slotId, String week)? onSlotSelected;
  final VoidCallback? onNavigateToAttendance;
  final VoidCallback? onNavigateToTempahan;

  static const _hdrStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: Color(0xFF6B5E3E),
    letterSpacing: 0.3,
  );
  static const _cellStyle = TextStyle(
    fontSize: 12,
    color: _kText,
    fontWeight: FontWeight.w500,
  );

  @override
  Widget build(BuildContext context) {
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: FixedColumnWidth(44), // NO.
        1: FixedColumnWidth(76), // CODE
        2: FixedColumnWidth(200), // NAMA KURSUS
        3: FixedColumnWidth(110), // SEKSYEN
        4: FixedColumnWidth(150), // PROGRAM
        5: FixedColumnWidth(80), // CAPACITY
        6: FixedColumnWidth(152), // HARI/MASA LOKASI
        7: FixedColumnWidth(120), // JENIS
        8: FixedColumnWidth(250), // TINDAKAN
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: _kTableHead),
          children: [
            _th('NO.'),
            _th('KOD'),
            _th('NAMA KURSUS'),
            _th('SEKSYEN'),
            _th('PROGRAM'),
            _th('KAPASITI'),
            _th('HARI/MASA LOKASI'),
            _th('JENIS'),
            _th('TINDAKAN'),
          ],
        ),
        for (int i = 0; i < slots.length; i++) _buildRow(i, slots[i]),
      ],
    );
  }

  TableRow _buildRow(int index, LecturerSlot slot) {
    final bg = index.isEven ? Colors.white : const Color(0xFFFAFCFD);
    return TableRow(
      decoration: BoxDecoration(
        color: bg,
        border: const Border(bottom: BorderSide(color: _kBorder, width: 0.8)),
      ),
      children: [
        _td(Text('${index + 1}.', style: _cellStyle.copyWith(color: _kMuted))),
        _td(Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: _kTeal.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(slot.subjectCode,
              style: _cellStyle.copyWith(
                  color: const Color(0xFF0D6E87),
                  fontWeight: FontWeight.w800,
                  fontSize: 11)),
        )),
        _td(Text(slot.subjectName,
            style: _cellStyle, maxLines: 2, overflow: TextOverflow.ellipsis)),
        _td(Text(slot.section, style: _cellStyle)),
        _td(Text(slot.programId, style: _cellStyle)),
        _td(Text('-', style: _cellStyle.copyWith(color: _kMuted))),
        _td(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(slot.day,
                style: _cellStyle.copyWith(
                    fontWeight: FontWeight.w700, fontSize: 11)),
            Text('${slot.startTime}-${slot.endTime}',
                style: _cellStyle.copyWith(color: _kMuted, fontSize: 11)),
            if (slot.roomId.isNotEmpty)
              Text(slot.roomId,
                  style: _cellStyle.copyWith(color: _kTeal, fontSize: 10)),
          ],
        )),
        _td(_JenisChip(
            label:
                slot.classType.isNotEmpty ? slot.classType : 'Normal Class')),
        _td(_ActionButtons(
          slot: slot,
          week: week,
          onTake: onSlotSelected,
          onNavigateToAttendance: onNavigateToAttendance,
          onNavigateToTempahan: onNavigateToTempahan,
        )),
      ],
    );
  }

  static Widget _th(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Text(text, style: _hdrStyle),
      );

  static Widget _td(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: child,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Jenis chip
// ─────────────────────────────────────────────────────────────────────────────

class _JenisChip extends StatelessWidget {
  const _JenisChip({required this.label});
  final String label;

  String _display() {
    final l = label.toLowerCase();
    if (l.contains('normal') || l.contains('kelas')) return 'Normal Class';
    if (l.contains('replace') || l.contains('ganti')) return 'Replacement';
    if (l.contains('lab')) return 'Lab Class';
    if (l.contains('tutorial')) return 'Tutorial';
    return label;
  }

  @override
  Widget build(BuildContext context) {
    final isReplace = label.toLowerCase().contains('replace') ||
        label.toLowerCase().contains('ganti');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isReplace ? const Color(0xFFFFF3CD) : const Color(0xFFDFF3EC),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _display(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isReplace ? const Color(0xFF856404) : const Color(0xFF186A44),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action buttons  (Take · Replace)
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButtons extends StatefulWidget {
  const _ActionButtons({
    required this.slot,
    required this.week,
    required this.onTake,
    this.onNavigateToAttendance,
    this.onNavigateToTempahan,
  });
  final LecturerSlot slot;
  final String week;
  final void Function(String slotId, String week)? onTake;
  final VoidCallback? onNavigateToAttendance;
  final VoidCallback? onNavigateToTempahan;

  @override
  State<_ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends State<_ActionButtons>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 110));
    _scale = Tween(begin: 1.0, end: 0.91)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _onTake() async {
    await _anim.forward();
    await _anim.reverse();
    widget.onTake?.call(widget.slot.slotId, widget.week);
    widget.onNavigateToAttendance
        ?.call(); // Menukar tab paparan induk kepada Kehadiran
  }

  Future<void> _onReplace() async {
    widget.onNavigateToTempahan
        ?.call(); // Menukar tab paparan induk kepada Tempahan Bilik
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: _scale,
          child: _OutlineBtn(
            icon: Icons.check_circle_outline_rounded,
            label: 'Ambil Kehadiran',
            color: _kTeal,
            onTap: _onTake,
          ),
        ),
        const SizedBox(width: 6),
        _OutlineBtn(
          icon: Icons.swap_horiz_rounded,
          label: 'Ganti Kelas',
          color: const Color(0xFFE67E22),
          onTap: _onReplace,
        ),
      ],
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// State widgets  (Loading · Empty · Error)
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 220,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_kTeal),
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text('Memuatkan jadual waktu…',
                  style: TextStyle(color: _kMuted, fontSize: 14)),
            ],
          ),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.lecturerName, required this.programId});
  final String lecturerName;
  final String programId;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _kTeal.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_today_outlined,
                  color: _kTeal, size: 28),
            ),
            const SizedBox(height: 14),
            const Text('Tiada Slot Dijumpai',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: _kText)),
            const SizedBox(height: 8),
            Text(
              lecturerName.isNotEmpty
                  ? 'Tiada slot ditetapkan untuk $lecturerName'
                      '${programId.isNotEmpty ? ' (Program $programId)' : ''}'
                      '\nbagi sesi JAN–JUN 2026.'
                  : 'Tiada rekod dijumpai untuk carian / penapis ini.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kMuted, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  color: Colors.red, size: 28),
            ),
            const SizedBox(height: 14),
            const Text('Ralat Sambungan',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: _kText)),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _kMuted, fontSize: 12),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Cuba Semula'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kTeal,
                side: const BorderSide(color: _kTeal),
              ),
            ),
          ],
        ),
      ),
    );
  }
}