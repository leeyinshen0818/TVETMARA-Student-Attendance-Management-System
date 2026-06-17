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

import '../models/app_models.dart';
import '../state/app_scope.dart';
import '../state/lecturer_timetable_controller.dart';
import '../services/lecturer_timetable_service.dart';
import '../services/lecturer_export_service.dart';

import '../widgets/app_components.dart';
import '../widgets/app_layout.dart';
import '../widgets/app_theme.dart';
import '../widgets/mobile_components.dart';
import '../widgets/responsive.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Colour tokens
// ─────────────────────────────────────────────────────────────────────────────

const Color _kTableHead = Color(0xFFF5F0E8);
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

  List<LecturerSlot> _cachedSlots(List<TimetableSlot> timetable) {
    final normalizedEmail = widget.lecturerEmail.trim().toLowerCase();
    return timetable.where((slot) {
      if (!slot.isOfficial) return false;
      final session = slot.academicSessionId ?? slot.session;
      if (session.isNotEmpty && session != AppScope.of(context).session) {
        return false;
      }
      final slotEmail = slot.lecturerEmail?.trim().toLowerCase();
      if (slot.lecturerId == widget.lecturerId) return true;
      if (normalizedEmail.isNotEmpty && slotEmail == normalizedEmail) {
        return true;
      }
      if (widget.lecturerProfileId != null &&
          widget.lecturerProfileId!.isNotEmpty &&
          slot.lecturerProfileId == widget.lecturerProfileId) {
        return true;
      }
      final hasStableIdentity = slot.lecturerId.isNotEmpty ||
          (slotEmail != null && slotEmail.isNotEmpty) ||
          (slot.lecturerProfileId != null &&
              slot.lecturerProfileId!.isNotEmpty);
      return !hasStableIdentity && slot.lecturerName == widget.lecturerName;
    }).map((slot) {
      final room = slot.roomId?.isNotEmpty == true
          ? slot.roomId!
          : slot.roomName?.isNotEmpty == true
              ? slot.roomName!
              : slot.room;
      return LecturerSlot(
        slotId: slot.id,
        day: (slot.day.isNotEmpty ? slot.day : slot.dayOfWeek ?? '')
            .toUpperCase()
            .trim(),
        startTime: slot.startTime,
        endTime: slot.endTime,
        subjectCode: slot.subjectCode,
        subjectName: slot.subjectName,
        section: slot.section.isNotEmpty ? slot.section : slot.classId ?? '',
        roomId: room,
        programId: slot.programId ?? slot.program,
        lecturerName: slot.lecturerName,
        classType: slot.classType,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final week = 'M${widget.controller.selectedWeek}';
    final state = AppScope.of(context);
    final loading =
        state.isCollectionLoading('timetable') && state.timetable.isEmpty;
    final allSlots = _cachedSlots(state.timetable);
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

    final filterBar = _FilterBar(
      course: _filterCourse,
      section: _filterSection,
      searchQuery: _searchQuery,
      courseOptions: courses,
      sectionOptions: sections,
      onCourseChanged: (v) => setState(() => _filterCourse = v),
      onSectionChanged: (v) => setState(() => _filterSection = v),
      onSearchChanged: (v) => setState(() => _searchQuery = v),
    );

    return AppPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppPageHeader(
            title: 'Jadual Waktu Pensyarah',
            subtitle: 'Paparan jadual waktu rasmi.',
          ),
          const SizedBox(height: 16),
          if (context.isMobile) ...[
            Row(
              children: [
                Expanded(
                  child: AppStatCard(
                    icon: Icons.calendar_month_outlined,
                    label: 'Kelas',
                    value: '${allSlots.length}',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppStatCard(
                    icon: Icons.people_outline,
                    label: 'Seksyen',
                    value: '$uniqueSections',
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            filterBar,
            const SizedBox(height: 16),
          ] else ...[
            // Web uses a compact summary strip right above the table
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _CompactStat(
                      icon: Icons.calendar_month_outlined,
                      label: 'Kelas',
                      value: '${allSlots.length}'),
                  const SizedBox(width: 24),
                  _CompactStat(
                      icon: Icons.people_outline,
                      label: 'Seksyen',
                      value: '$uniqueSections'),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: loading
                ? const _LoadingState()
                : _OfficialTable(
                    slots: filtered,
                    week: week,
                    lecturerName: widget.lecturerName,
                    lecturerEmail: widget.lecturerEmail,
                    programId: widget.programId,
                    onSlotSelected: widget.onSlotSelected,
                    onNavigateToAttendance: widget.onNavigateToAttendance,
                    onNavigateToTempahan: widget.onNavigateToTempahan,
                    filterBar: context.isMobile ? null : filterBar,
                  ),
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page header  (title + week selector)
// ─────────────────────────────────────────────────────────────────────────────

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
    final activeFilters = [
      if (course != 'Semua Kursus') course,
      if (section != 'Semua Seksyen') section,
    ].length;

    if (context.isMobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: TextField(
                  onChanged: onSearchChanged,
                  style: const TextStyle(fontSize: 14, color: _kText),
                  decoration: InputDecoration(
                    hintText: 'Cari jadual...',
                    hintStyle:
                        const TextStyle(fontSize: 14, color: Color(0xFFBDD0DA)),
                    prefixIcon: const Icon(Icons.search_rounded,
                        size: 20, color: _kMuted),
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: _kCardBg,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: _kBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 44,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (sheetContext) => MobileBottomSheet(
                      title: 'Tapis Jadual',
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _FilterDropdown(
                            label: 'Kursus',
                            value: course,
                            options: courseOptions,
                            onChanged: (v) {
                              onCourseChanged(v);
                              Navigator.pop(sheetContext);
                            },
                          ),
                          const SizedBox(height: 12),
                          _FilterDropdown(
                            label: 'Seksyen',
                            value: section,
                            options: sectionOptions,
                            onChanged: (v) {
                              onSectionChanged(v);
                              Navigator.pop(sheetContext);
                            },
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton.icon(
                            onPressed: () {
                              onCourseChanged('Semua Kursus');
                              onSectionChanged('Semua Seksyen');
                              Navigator.pop(sheetContext);
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset Penapis'),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.tune_outlined, size: 18),
                label: Text(
                    activeFilters > 0 ? 'Tapis ($activeFilters)' : 'Tapis'),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: LayoutBuilder(builder: (context, c) {
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
                          padding: const EdgeInsets.only(right: 10), child: w),
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
                borderSide: const BorderSide(color: AppColors.primary),
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
    this.filterBar,
  });

  final List<LecturerSlot> slots;
  final String week;
  final String lecturerName;
  final String lecturerEmail;
  final String programId;
  final void Function(String slotId, String week)? onSlotSelected;
  final VoidCallback? onNavigateToAttendance;
  final VoidCallback? onNavigateToTempahan;
  final Widget? filterBar;

  @override
  State<_OfficialTable> createState() => _OfficialTableState();
}

class _OfficialTableState extends State<_OfficialTable> {
  bool _exportingPdf = false;

  LecturerExportMeta get _meta => LecturerExportMeta(
        lecturerName: widget.lecturerName,
        lecturerEmail: widget.lecturerEmail,
        academicSession: 'JAN – JUN 2026',
        generatedAt: DateTime.now(),
      );

  Future<void> _onExportPdf() async {
    if (_exportingPdf) return;
    setState(() => _exportingPdf = true);
    try {
      await exportLecturerTimetableAsPdf(slots: widget.slots, meta: _meta);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Eksport PDF gagal: $e'),
          backgroundColor: Colors.red.shade700,
        ));
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < 600) {
      // ── Mobile: same card shell as web, horizontal-scrolling grid, PDF button
      return _MobileOfficialTable(
        slots: widget.slots,
        week: widget.week,
        lecturerName: widget.lecturerName,
        lecturerEmail: widget.lecturerEmail,
        programId: widget.programId,
        exportingPdf: _exportingPdf,
        onExportPdf: _onExportPdf,
        onSlotSelected: widget.onSlotSelected,
        onNavigateToAttendance: widget.onNavigateToAttendance,
        onNavigateToTempahan: widget.onNavigateToTempahan,
      );
    }
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
                const Icon(Icons.table_chart_outlined,
                    size: 16, color: AppColors.primary),
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
                // ── Export button (only when there are slots) ──
                if (widget.slots.isNotEmpty) ...[
                  _ExportButton(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'Eksport PDF',
                    loading: _exportingPdf,
                    color: const Color(0xFFDC2626),
                    onTap: _onExportPdf,
                    tooltip:
                        'Muat turun jadual waktu rasmi sebagai PDF secara terus',
                  ),
                ],
              ],
            ),
          ),
          if (widget.filterBar != null) widget.filterBar!,
          const Divider(height: 1, color: _kBorder),

          if (widget.slots.isEmpty)
            _EmptyState(
                lecturerName: widget.lecturerName, programId: widget.programId)
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DataTable(
                      slots: widget.slots,
                      week: widget.week,
                      onSlotSelected: widget.onSlotSelected,
                      onNavigateToAttendance: widget.onNavigateToAttendance,
                      onNavigateToTempahan: widget.onNavigateToTempahan,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile official table  (replaces old stacked-card layout on width < 600)
//
// Matches the web card shell exactly:
//   • Same outer Container decoration (rounded card, shadow)
//   • Same header row with record count + "Eksport PDF" button
//   • Same dark navy title / sub-title banners
//   • _DataTable wrapped in SingleChildScrollView(horizontal) so users can
//     pan left–right through all columns without overflow
// ─────────────────────────────────────────────────────────────────────────────

class _MobileOfficialTable extends StatelessWidget {
  const _MobileOfficialTable({
    required this.slots,
    required this.week,
    required this.lecturerName,
    required this.lecturerEmail,
    required this.programId,
    required this.exportingPdf,
    required this.onExportPdf,
    required this.onSlotSelected,
    this.onNavigateToAttendance,
    this.onNavigateToTempahan,
  });

  final List<LecturerSlot> slots;
  final String week;
  final String lecturerName;
  final String lecturerEmail;
  final String programId;
  final bool exportingPdf;
  final VoidCallback onExportPdf;
  final void Function(String slotId, String week)? onSlotSelected;
  final VoidCallback? onNavigateToAttendance;
  final VoidCallback? onNavigateToTempahan;

  @override
  Widget build(BuildContext context) {
    return Container(
      // ── Same card shell as the web layout ──────────────────────────────
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
          // ── Card header — title + record count + PDF button ────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.table_chart_outlined,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Jadual waktu rasmi',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kText),
                  ),
                ),
                Text('${slots.length} rekod',
                    style: const TextStyle(fontSize: 12, color: _kMuted)),
                // ── PDF export button — same path as web ────────────────
                if (slots.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  _ExportButton(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'Eksport PDF',
                    loading: exportingPdf,
                    color: const Color(0xFFDC2626),
                    onTap: onExportPdf,
                    tooltip:
                        'Muat turun jadual waktu rasmi sebagai PDF secara terus',
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: _kBorder),

          // ── Empty state ───────────────────────────────────────────────
          if (slots.isEmpty)
            _EmptyState(lecturerName: lecturerName, programId: programId)
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  for (final slot in slots)
                    _MobileSlotCard(
                      slot: slot,
                      week: week,
                      onSlotSelected: onSlotSelected,
                      onNavigateToAttendance: onNavigateToAttendance,
                      onNavigateToTempahan: onNavigateToTempahan,
                    ),
                ],
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
        1: FixedColumnWidth(95), // CODE
        2: FixedColumnWidth(240), // NAMA KURSUS
        3: FixedColumnWidth(100), // SEKSYEN
        4: FixedColumnWidth(100), // PROGRAM
        5: FixedColumnWidth(152), // HARI/MASA LOKASI
        6: FixedColumnWidth(110), // STATUS
        7: FixedColumnWidth(250), // TINDAKAN
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
            _th('HARI/MASA LOKASI'),
            _th('STATUS'),
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
            color: AppColors.primary.withValues(alpha: 0.10),
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
        _td(Text(slot.programId.split(' ').first.split('-').first.trim(),
            style: _cellStyle)),
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
                  style: _cellStyle.copyWith(
                      color: AppColors.primary, fontSize: 10)),
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
            color: AppColors.primary,
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
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
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
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_today_outlined,
                  color: AppColors.primary, size: 28),
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

class _MobileSlotCard extends StatelessWidget {
  const _MobileSlotCard({
    required this.slot,
    required this.week,
    this.onSlotSelected,
    this.onNavigateToAttendance,
    this.onNavigateToTempahan,
  });

  final LecturerSlot slot;
  final String week;
  final void Function(String slotId, String week)? onSlotSelected;
  final VoidCallback? onNavigateToAttendance;
  final VoidCallback? onNavigateToTempahan;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${slot.subjectCode} · ${slot.subjectName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${slot.section} · ${slot.day} ${slot.startTime}–${slot.endTime}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${slot.roomId} · $week',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                  ),
                  onPressed: () {
                    onSlotSelected?.call(slot.slotId, week);
                    onNavigateToAttendance?.call();
                  },
                  icon:
                      const Icon(Icons.check_circle_outline_rounded, size: 16),
                  label: const Text('Ambil Kehadiran',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor:
                        const Color(0xFFE67E22).withValues(alpha: 0.1),
                    foregroundColor: const Color(0xFFE67E22),
                    elevation: 0,
                  ),
                  onPressed: () {
                    onNavigateToTempahan?.call();
                  },
                  icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                  label:
                      const Text('Ganti Kelas', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  const _CompactStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: _kMuted, fontWeight: FontWeight.w600)),
            Text(value,
                style: const TextStyle(
                    fontSize: 14, color: _kText, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }
}
