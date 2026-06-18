import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../widgets/app_layout.dart';
import '../widgets/app_theme.dart';
import '../widgets/mobile_components.dart';
import '../widgets/responsive.dart';
import '../widgets/status_chip.dart';

// ─────────────────────────────────────────────────────────────────────────────
// M6 – Booking Module (Tempahan Bilik)
// ─────────────────────────────────────────────────────────────────────────────

class TempahanScreen extends StatefulWidget {
  const TempahanScreen({super.key});

  @override
  State<TempahanScreen> createState() => _TempahanScreenState();
}

class _TempahanScreenState extends State<TempahanScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  String _filterStatus = 'Semua';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    // PATCH 1: listener forces rebuild when tab changes so if/else below works
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.currentUser!;

    final isPensyarah = user.role == UserRole.pensyarah;
    final isApprover = user.role == UserRole.ketua_program ||
        user.role == UserRole.ketua_jabatan;

    if (!isPensyarah && !isApprover) {
      return const _AccessDenied();
    }

    final visibleBookings = state.scopedBookings;
    final pendingCount =
        visibleBookings.where((b) => b.status == 'Pending').length;

    final tabLabels = [
      isPensyarah ? 'Permohonan Baharu' : 'Tindakan',
      'Semua',
    ];

    if (context.isMobile) {
      return AppPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MobileHeroCard(
              icon: Icons.event_available_outlined,
              title: isPensyarah ? 'Tempahan Bilik' : 'Kelulusan Tempahan',
              subtitle: isPensyarah
                  ? 'Mohon bilik ganti.'
                  : 'Semak permohonan kelas ganti.',
              accentColor: AppColors.warning,
              chips: [
                if (pendingCount > 0) StatusChip('$pendingCount Menunggu'),
                StatusChip('${visibleBookings.length} Permohonan'),
              ],
            ),
            const SizedBox(height: 14),
            MobileSegmentedControl(
              labels: tabLabels,
              selectedIndex: _tabCtrl.index,
              onChanged: (index) => setState(() => _tabCtrl.animateTo(index)),
            ),
            const SizedBox(height: 14),
            if (_tabCtrl.index == 0)
              isPensyarah
                  ? _NewRequestTab(onSubmitted: () => _tabCtrl.animateTo(1))
                  : _ApproverActionTab(
                      filterStatus: _filterStatus,
                      onFilterChanged: (v) => setState(() => _filterStatus = v),
                    )
            else
              _AllBookingsTab(
                filterStatus: _filterStatus,
                onFilterChanged: (v) => setState(() => _filterStatus = v),
                isApprover: isApprover,
              ),
          ],
        ),
      );
    }

    return AppPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page header ──
          AppPageHeader(
            title: isPensyarah
                ? 'Permohonan Tempahan Bilik'
                : 'Kelulusan Tempahan Bilik',
            subtitle: isPensyarah
                ? 'Mohon bilik kelas ganti berdasarkan ruang yang tersedia.'
                : 'Semak dan luluskan permohonan kelas ganti mengikut skop anda.',
            trailing: pendingCount > 0
                ? StatusChip('$pendingCount Menunggu')
                : StatusChip('${visibleBookings.length} permohonan'),
          ),

          // ── Tab bar ──
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: .035),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(14),
              ),
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.muted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w900),
              unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.w700),
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(4),
              tabs: [
                Tab(
                    text: isPensyarah
                        ? 'Permohonan Baharu'
                        : 'Tindakan Diperlukan'),
                const Tab(text: 'Semua Permohonan'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // PATCH 1: plain if/else using _tabCtrl.index — listener above
          // ensures setState fires on every tab change so this always re-renders.
          if (_tabCtrl.index == 0)
            isPensyarah
                ? _NewRequestTab(onSubmitted: () => _tabCtrl.animateTo(1))
                : _ApproverActionTab(
                    filterStatus: _filterStatus,
                    onFilterChanged: (v) => setState(() => _filterStatus = v),
                  )
          else
            _AllBookingsTab(
              filterStatus: _filterStatus,
              onFilterChanged: (v) => setState(() => _filterStatus = v),
              isApprover: isApprover,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 0 (Pensyarah) – New request form
// ─────────────────────────────────────────────────────────────────────────────

class _NewRequestTab extends StatefulWidget {
  const _NewRequestTab({required this.onSubmitted});
  final VoidCallback onSubmitted;

  @override
  State<_NewRequestTab> createState() => _NewRequestTabState();
}

class _NewRequestTabState extends State<_NewRequestTab> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedSlotId;
  String _block = 'All';
  String _room = '';
  String _replacementDate = '';
  String _startTime = '';
  String _endTime = '';
  String _reason = 'Latihan / Mesyuarat';
  String _remarks = '';

  final _dateCtrl = TextEditingController();
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  bool _submitting = false;

  static const _reasons = [
    'Latihan / Mesyuarat',
    'Kelas Ganti',
    'Aktiviti Pelajar',
    'Penggunaan Makmal',
    'Lain-lain',
  ];

  @override
  void dispose() {
    _dateCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  // PATCH 2: fallback to program slots when Pensyarah has no personal slots
  List<TimetableSlot> _getSlots(AppState state, AppUser user) {
    final personal = state.scopedTimetable;
    if (personal.isNotEmpty) return personal;
    final code = user.programId;
    if (code == null || code.isEmpty) {
      return state.timetable;
    }
    return state.timetable.where((s) {
      if (s.programId == code) return true;
      final prefix = s.section.trim().split(RegExp(r'\s+')).firstOrNull ?? '';
      return prefix == code;
    }).toList();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (picked != null) {
      setState(() {
        _replacementDate =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        _dateCtrl.text = _replacementDate;
      });
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart
        ? const TimeOfDay(hour: 8, minute: 0)
        : const TimeOfDay(hour: 10, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) {
          _startTime = formatted;
          _startCtrl.text = formatted;
        } else {
          _endTime = formatted;
          _endCtrl.text = formatted;
        }
      });
    }
  }

  Future<void> _submit(BuildContext ctx) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _formKey.currentState!.save();

    final state = AppScope.of(ctx);
    final user = state.currentUser!;
    final slots = _getSlots(state, user);
    final selected = slots.where((s) => s.id == _selectedSlotId).firstOrNull;

    final available = state.isRoomAvailable(
      room: _room,
      date: _replacementDate,
      start: _startTime,
      end: _endTime,
    );
    if (!available) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
            content: Text(
                'Slot masa yang dipilih bertindih dengan slot yang telah diisi. Sila pilih waktu lain.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _submitting = true);

    // Resolve programId: slot.programId → section prefix → user.programId
    final section = selected?.section ?? '-';
    final prefix = section.trim().split(RegExp(r'\s+')).firstOrNull ?? '';
    String? programId;
    if (selected?.programId != null && selected!.programId!.isNotEmpty) {
      programId = selected.programId;
    } else if (state.programs.any((p) => p.id == prefix)) {
      programId = prefix;
    } else {
      programId = user.programId;
    }

    String? deptId = selected?.departmentId ?? user.departmentId;
    if (deptId == null && programId != null) {
      deptId = state.programs
          .where((p) => p.id == programId)
          .firstOrNull
          ?.departmentId;
    }

    debugPrint(
        '=== SUBMIT === programId=$programId deptId=$deptId section=$section');

    final booking = BookingRequest(
      id: 'BK${DateTime.now().millisecondsSinceEpoch}',
      lecturerId: user.uid,
      lecturerName: user.name,
      programId: programId,
      departmentId: deptId,
      subject: selected?.subjectName ?? '-',
      section: section,
      originalDate: selected?.date ?? _replacementDate,
      originalTime: selected != null
          ? '${selected.startTime} – ${selected.endTime}'
          : '-',
      replacementDate: _replacementDate,
      replacementStart: _startTime,
      replacementEnd: _endTime,
      roomId: _room.replaceAll(RegExp(r'[/\\.]'), '_'),
      roomName: _room,
      room: _room,
      reason: _reason,
      remarks: _remarks,
      status: 'Pending',
    );

    await state.addBooking(booking);
    setState(() => _submitting = false);

    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('✓ Permohonan tempahan telah dihantar.'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onSubmitted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.currentUser!;
    final slots = _getSlots(state, user); // PATCH 2: use _getSlots

    final blocks = [
      'All',
      ...state.roomResources.map((r) => r.block).toSet().toList()..sort(),
    ];
    final filteredRooms = state.roomResources
        .where((r) => _block == 'All' || r.block == _block)
        .toList();

    if (filteredRooms.isNotEmpty &&
        !filteredRooms.any((r) => r.name == _room)) {
      _room = filteredRooms.first.name;
    }

    _selectedSlotId ??= slots.firstOrNull?.id;
    final selected = slots.where((s) => s.id == _selectedSlotId).firstOrNull;

    final canCheck = _room.isNotEmpty &&
        _replacementDate.isNotEmpty &&
        _startTime.isNotEmpty &&
        _endTime.isNotEmpty;
    final available = canCheck &&
        state.isRoomAvailable(
          room: _room,
          date: _replacementDate,
          start: _startTime,
          end: _endTime,
        );

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selected != null) _InfoBanner(slot: selected),
            const SizedBox(height: 16),
            AppPanel(
              title: 'Butiran Permohonan',
              subtitle: 'Isi semua maklumat kelas ganti yang diperlukan.',
              trailing: canCheck
                  ? StatusChip(available ? 'Tersedia' : 'Tidak Tersedia')
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('Kelas Asal'),
                  const SizedBox(height: 8),
                  if (slots.isEmpty)
                    const Text(
                      'Tiada slot jadual ditemui untuk program anda.',
                      style: TextStyle(color: Color(0xff64748b)),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSlotId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                          labelText: 'Pilih Kelas / Slot'),
                      items: slots
                          .map((s) => DropdownMenuItem<String>(
                                value: s.id,
                                child: Text(
                                  '[${s.programId ?? s.section.split(' ').first}] '
                                  '${s.subjectCode} – ${s.section}  '
                                  '(${s.day}, ${s.startTime}–${s.endTime})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedSlotId = v),
                      validator: (v) => v == null ? 'Sila pilih kelas.' : null,
                    ),
                  const SizedBox(height: 20),
                  const _SectionLabel('Tarikh & Masa Ganti'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 200,
                        child: TextFormField(
                          controller: _dateCtrl,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Tarikh Ganti',
                            suffixIcon: Icon(Icons.calendar_today, size: 18),
                          ),
                          onTap: _pickDate,
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Pilih tarikh.' : null,
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        child: TextFormField(
                          controller: _startCtrl,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Masa Mula',
                            suffixIcon: Icon(Icons.schedule, size: 18),
                          ),
                          onTap: () => _pickTime(true),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Pilih masa mula.'
                              : null,
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        child: TextFormField(
                          controller: _endCtrl,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Masa Tamat',
                            suffixIcon: Icon(Icons.schedule, size: 18),
                          ),
                          onTap: () => _pickTime(false),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Pilih masa tamat.';
                            }
                            if (_startTime.isNotEmpty &&
                                _endTime.isNotEmpty &&
                                _endTime.compareTo(_startTime) <= 0) {
                              return 'Masa tamat mesti selepas mula.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _SectionLabel('Pilihan Bilik'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 160,
                        child: DropdownButtonFormField<String>(
                          initialValue: _block,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Blok'),
                          items: blocks
                              .map((b) => DropdownMenuItem<String>(
                                    value: b,
                                    child: Text(b == 'All' ? 'Semua Blok' : b),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _block = v ?? _block),
                        ),
                      ),
                      if (filteredRooms.isNotEmpty)
                        SizedBox(
                          width: 300,
                          child: DropdownButtonFormField<String>(
                            initialValue:
                                filteredRooms.any((r) => r.name == _room)
                                    ? _room
                                    : null,
                            isExpanded: true,
                            decoration:
                                const InputDecoration(labelText: 'Bilik'),
                            items: filteredRooms
                                .map((r) => DropdownMenuItem<String>(
                                      value: r.name,
                                      child: Row(
                                        children: [
                                          Expanded(
                                              child: Text(
                                                  '${r.name} (${r.type})')),
                                          if (canCheck &&
                                              _replacementDate.isNotEmpty &&
                                              _startTime.isNotEmpty &&
                                              _endTime.isNotEmpty)
                                            _MiniAvailDot(
                                              available: state.isRoomAvailable(
                                                room: r.name,
                                                date: _replacementDate,
                                                start: _startTime,
                                                end: _endTime,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _room = v ?? _room),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Sila pilih bilik.'
                                : null,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _RoomTimeSlotAvailabilitySelector(
                    room: _room,
                    date: _replacementDate,
                    selectedStartTime: _startTime,
                    selectedEndTime: _endTime,
                    state: state,
                    onSlotSelected: (start, end) {
                      setState(() {
                        _startTime = start;
                        _endTime = end;
                        _startCtrl.text = start;
                        _endCtrl.text = end;
                      });
                    },
                  ),
                  if (canCheck && !available)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.orange, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Bilik ini tidak tersedia pada masa yang dipilih.',
                            style:
                                TextStyle(color: Colors.orange, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  const _SectionLabel('Sebab & Catatan'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 260,
                        child: DropdownButtonFormField<String>(
                          initialValue: _reason,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Sebab'),
                          items: _reasons
                              .map((r) => DropdownMenuItem<String>(
                                  value: r, child: Text(r)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _reason = v ?? _reason),
                        ),
                      ),
                      SizedBox(
                        width: 340,
                        child: TextFormField(
                          controller: _remarksCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Catatan Tambahan (pilihan)'),
                          maxLines: 1,
                          onSaved: (v) => _remarks = v ?? '',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: _submitting ? null : () => _submit(context),
                        icon: _submitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send),
                        label: const Text('Hantar Permohonan'),
                      ),
                      const SizedBox(width: 12),
                      if (canCheck && !available)
                        const Text(
                          'Bilik tidak tersedia',
                          style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _RoomAvailabilityHelper(
              date: _replacementDate,
              rooms: state.roomResources,
              state: state,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 0 (Approver) – pending items only
// ─────────────────────────────────────────────────────────────────────────────

class _ApproverActionTab extends StatelessWidget {
  const _ApproverActionTab({
    required this.filterStatus,
    required this.onFilterChanged,
  });

  final String filterStatus;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final pending =
        state.scopedBookings.where((b) => b.status == 'Pending').toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          if (pending.isEmpty)
            const AppPanel(
              child: _EmptyState(
                icon: Icons.check_circle_outline,
                message: 'Tiada permohonan menunggu kelulusan.',
                color: Colors.green,
              ),
            )
          else
            AppPanel(
              title: 'Menunggu Kelulusan',
              subtitle: '${pending.length} permohonan memerlukan tindakan.',
              child: Column(
                children: pending
                    .map((b) => _BookingApprovalCard(
                          booking: b,
                          showActions: b.status == 'Pending',
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 – all bookings with filter
// ─────────────────────────────────────────────────────────────────────────────

class _AllBookingsTab extends StatelessWidget {
  const _AllBookingsTab({
    required this.filterStatus,
    required this.onFilterChanged,
    required this.isApprover,
  });

  final String filterStatus;
  final ValueChanged<String> onFilterChanged;
  final bool isApprover;

  static const _filterValues = ['Semua', 'Pending', 'Approved', 'Rejected'];
  static const _filterLabels = ['Semua', 'Menunggu', 'Diluluskan', 'Ditolak'];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final all = state.scopedBookings;
    final filtered = filterStatus == 'Semua'
        ? all
        : all.where((b) => b.status == filterStatus).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: List.generate(_filterValues.length, (i) {
              final val = _filterValues[i];
              final label = _filterLabels[i];
              final active = filterStatus == val;
              return FilterChip(
                label: Text(label),
                selected: active,
                onSelected: (_) => onFilterChanged(val),
                selectedColor: const Color(0xffdbeafe),
                checkmarkColor: const Color(0xff1d4ed8),
              );
            }),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const AppPanel(
              child: _EmptyState(
                icon: Icons.inbox_outlined,
                message: 'Tiada rekod ditemui.',
                color: Colors.grey,
              ),
            )
          else
            AppPanel(
              title: 'Senarai Permohonan',
              subtitle: '${filtered.length} rekod ditemui.',
              child: Column(
                children: filtered
                    .map((b) => _BookingApprovalCard(
                          booking: b,
                          showActions: isApprover && b.status == 'Pending',
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Booking card — with Lihat Butiran (Phase 1)
// ─────────────────────────────────────────────────────────────────────────────

class _BookingApprovalCard extends StatelessWidget {
  const _BookingApprovalCard({required this.booking, this.showActions = true});
  final BookingRequest booking;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final avail = state.isRoomAvailable(
      room: booking.room,
      date: booking.replacementDate,
      start: booking.replacementStart,
      end: booking.replacementEnd,
      ignoreBookingId: booking.id,
    );

    final statusLabel = switch (booking.status) {
      'Pending' => 'Menunggu',
      'Approved' => 'Diluluskan',
      'Rejected' => 'Ditolak',
      _ => booking.status,
    };

    // Left border colour reflects status
    final leftBorderColor = switch (booking.status) {
      'Approved' => AppColors.success,
      'Rejected' => AppColors.danger,
      _ => AppColors.warning,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        // NOTE: borderRadius lives here only, with no border on this layer.
        // A `Border` with mixed per-side colours (the old `leftBorderColor`
        // vs `AppColors.border`) cannot be combined with `borderRadius` —
        // Flutter requires every BorderSide to share the same colour and
        // width when borderRadius is set, otherwise it throws "A
        // borderRadius can only be given on borders with uniform colors.".
        // The coloured left edge is rendered as a separate Positioned strip
        // below (a Stack, not Row+IntrinsicHeight — IntrinsicHeight's
        // measured height can come out a couple pixels short of what Wrap
        // children actually need once laid out, causing a bottom overflow).
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
                  // ── Header row ──
                  if (context.isMobile) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            booking.subject,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusChip(statusLabel),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${booking.programId ?? '-'}  ·  ${booking.section}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bilik: ${booking.room}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.event_available,
                            size: 14, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text(
                          '${booking.replacementDate}  ${booking.replacementStart}–${booking.replacementEnd}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        const Icon(Icons.meeting_room_outlined,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${booking.subject}  ·  ${booking.section}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        StatusChip(statusLabel),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ── Key details ──
                    Wrap(
                      spacing: 24,
                      runSpacing: 6,
                      children: [
                        _DetailItem(
                            icon: Icons.swap_horiz,
                            label: 'Ganti',
                            value:
                                '${booking.replacementDate}  ${booking.replacementStart}–${booking.replacementEnd}'),
                        _DetailItem(
                            icon: Icons.door_front_door_outlined,
                            label: 'Bilik',
                            value: booking.room),
                      ],
                    ),
                  ],

                  // ── Conflict warning ──
                  if (!avail)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: AppColors.warning, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Bilik telah ditempah pada masa ini.',
                            style: TextStyle(
                                color: AppColors.warning, fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                  // ── Reviewer metadata (if already reviewed) ──
                  if (booking.reviewedBy != null ||
                      booking.reviewedByName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user_outlined,
                              size: 13, color: Color(0xff64748b)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              booking.status == 'Rejected'
                                  ? 'Disemak oleh: ${booking.reviewedByName ?? "Penyelia"}. Sebab: ${booking.rejectionReason ?? "Tiada alasan diberikan"}'
                                  : 'Disemak oleh: ${booking.reviewedByName ?? booking.reviewedBy ?? "Penyelia"}',
                              style: TextStyle(
                                fontSize: 11,
                                color: booking.status == 'Rejected'
                                    ? AppColors.danger
                                    : const Color(0xff64748b),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // ── Action row ──
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Lihat Butiran — always visible
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        onPressed: () => BookingDetailsDialog.show(
                          context,
                          booking: booking,
                          avail: avail,
                          showActions: showActions,
                        ),
                        icon: const Icon(Icons.info_outline, size: 16),
                        label: const Text('Lihat Butiran'),
                      ),
                      if (showActions)
                        _ApproveRejectButtons(bookingId: booking.id),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: Container(color: leftBorderColor),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lihat Butiran dialog (Phase 1)
// ─────────────────────────────────────────────────────────────────────────────

class BookingDetailsDialog extends StatelessWidget {
  const BookingDetailsDialog({
    super.key,
    required this.booking,
    required this.avail,
    required this.showActions,
    this.isMobileSheet = false,
  });

  final BookingRequest booking;
  final bool avail;
  final bool showActions;
  final bool isMobileSheet;

  static void show(
    BuildContext context, {
    required BookingRequest booking,
    required bool avail,
    required bool showActions,
  }) {
    if (context.isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => MobileBottomSheet(
          title: 'Butiran Permohonan',
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.75,
            ),
            child: SingleChildScrollView(
              child: BookingDetailsDialog(
                booking: booking,
                avail: avail,
                showActions: showActions,
                isMobileSheet: true,
              ),
            ),
          ),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => BookingDetailsDialog(
        booking: booking,
        avail: avail,
        showActions: showActions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    // Booking conflict helper: collect all overlapping items for this room+date
    // We use isRoomAvailable per-slot to identify conflicts without accessing private methods
    final allSlotsOnDate = state.timetable
        .where(
            (s) => s.room == booking.room && s.date == booking.replacementDate)
        .toList();
    final conflictSlots = allSlotsOnDate.where((s) {
      // A slot conflicts if checking availability without it would still pass,
      // but it overlaps with our requested time window — use time string compare
      final aS = booking.replacementStart;
      final aE = booking.replacementEnd;
      final bS = s.startTime;
      final bE = s.endTime;
      // Overlap: aStart < bEnd AND bStart < aEnd
      return aS.compareTo(bE) < 0 && bS.compareTo(aE) < 0;
    }).toList();

    final conflictBookings = state.bookings.where((b) {
      if (b.id == booking.id) return false;
      if (b.room != booking.room) return false;
      if (b.replacementDate != booking.replacementDate) return false;
      if (b.status != 'Approved') return false;
      final aS = booking.replacementStart;
      final aE = booking.replacementEnd;
      final bS = b.replacementStart;
      final bE = b.replacementEnd;
      return aS.compareTo(bE) < 0 && bS.compareTo(aE) < 0;
    }).toList();

    final statusLabel = switch (booking.status) {
      'Pending' => 'Menunggu Kelulusan',
      'Approved' => 'Diluluskan',
      'Rejected' => 'Ditolak',
      _ => booking.status,
    };

    final statusColor = switch (booking.status) {
      'Approved' => AppColors.success,
      'Rejected' => AppColors.danger,
      _ => AppColors.warning,
    };

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMobileSheet) ...[
          // ── Dialog title ──
          Row(
            children: [
              const Icon(Icons.meeting_room_outlined,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Butiran Permohonan Tempahan',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, size: 20),
                tooltip: 'Tutup',
              ),
            ],
          ),
          const Divider(height: 24),
        ],

        // ── Scrollable body ──
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status banner
                _StatusBanner(label: statusLabel, color: statusColor),
                const SizedBox(height: 16),

                // Section: Pemohon
                _DetailSection(
                  title: 'Maklumat Pemohon',
                  icon: Icons.person_outline,
                  rows: [
                    _Row('Nama', booking.lecturerName),
                    _Row('Program', booking.programId ?? '-'),
                    _Row('Sebab Permohonan', booking.reason),
                    if (booking.remarks.isNotEmpty)
                      _Row('Catatan', booking.remarks),
                  ],
                ),
                const SizedBox(height: 14),

                // Section: Kelas Asal
                _DetailSection(
                  title: 'Kelas Asal',
                  icon: Icons.class_outlined,
                  rows: [
                    _Row('Subjek', booking.subject),
                    _Row('Seksyen', booking.section),
                    _Row('Tarikh Asal', booking.originalDate),
                    _Row('Masa Asal', booking.originalTime),
                  ],
                ),
                const SizedBox(height: 14),

                // Section: Slot Ganti
                _DetailSection(
                  title: 'Slot Ganti Yang Dimohon',
                  icon: Icons.swap_horiz,
                  rows: [
                    _Row('Tarikh Ganti', booking.replacementDate),
                    _Row('Masa',
                        '${booking.replacementStart} – ${booking.replacementEnd}'),
                    _Row('Bilik', booking.room),
                    _Row(
                      'Ketersediaan Bilik',
                      avail
                          ? '✓ Tersedia pada masa ini'
                          : '✗ Bilik tidak tersedia',
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Section: Konflik (Booking conflict helper results)
                if (conflictSlots.isNotEmpty ||
                    conflictBookings.isNotEmpty) ...[
                  _DetailSection(
                    title: 'Konflik Dikesan',
                    icon: Icons.warning_amber_rounded,
                    iconColor: AppColors.danger,
                    rows: [
                      ...conflictSlots.map((s) => _Row(
                            'Jadual Tetap',
                            '${s.section} · ${s.startTime}–${s.endTime} · ${s.room}',
                          )),
                      ...conflictBookings.map((b) => _Row(
                            'Tempahan Diluluskan',
                            '${b.section} · ${b.replacementStart}–${b.replacementEnd} · ${b.room}',
                          )),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],

                // Section: Maklumat Semakan (if reviewed)
                if (booking.reviewedBy != null ||
                    booking.reviewedByName != null) ...[
                  _DetailSection(
                    title: 'Maklumat Semakan',
                    icon: Icons.verified_user_outlined,
                    rows: [
                      _Row('Disemak Oleh',
                          booking.reviewedByName ?? booking.reviewedBy ?? '-'),
                      if (booking.reviewedAt != null)
                        _Row('Tarikh Semakan', booking.reviewedAt!),
                      if (booking.rejectionReason != null)
                        _Row('Sebab Penolakan', booking.rejectionReason!),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),
        ),

        const Divider(height: 24),

        // ── Footer buttons ──
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (showActions) ...[
              _ApproveRejectButtons(
                  bookingId: booking.id,
                  onDone: () => Navigator.of(context).pop()),
              const SizedBox(width: 8),
            ],
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ],
    );

    if (isMobileSheet) {
      return content;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: content,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        border: Border.all(color: color.withValues(alpha: .25)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 9, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.rows,
    this.iconColor = AppColors.primary,
  });
  final String title;
  final IconData icon;
  final List<_Row> rows;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: iconColor,
                letterSpacing: .3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xfff8fafc),
            border: Border.all(color: const Color(0xffe2e8f0)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: rows,
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xff64748b),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xff0f172a),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Approve / Reject buttons — with mandatory rejection reason (Phase 1)
// ─────────────────────────────────────────────────────────────────────────────

class _ApproveRejectButtons extends StatelessWidget {
  const _ApproveRejectButtons({
    required this.bookingId,
    this.onDone,
  });
  final String bookingId;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Wrap(
      spacing: 8,
      children: [
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.success,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          onPressed: () async {
            await state.updateBooking(bookingId, 'Approved');
            if (context.mounted) {
              onDone?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      '✓ Permohonan diluluskan. Slot kelas ganti telah dicipta.'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          icon: const Icon(Icons.check, size: 16),
          label: const Text('Luluskan'),
        ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.danger,
            side: const BorderSide(color: AppColors.danger),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          onPressed: () async {
            final reason = await _showRejectionDialog(context);
            if (reason == null) return; // user cancelled
            if (!context.mounted) return;
            await state.updateBooking(
              bookingId,
              'Rejected',
              rejectionReason: reason,
            );
            if (context.mounted) {
              onDone?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Permohonan telah ditolak.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          icon: const Icon(Icons.close, size: 16),
          label: const Text('Tolak'),
        ),
      ],
    );
  }

  /// Shows rejection reason dialog. Returns the reason string, or null if cancelled.
  Future<String?> _showRejectionDialog(BuildContext ctx) async {
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.danger, size: 20),
            SizedBox(width: 8),
            Text('Tolak Permohonan',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sila nyatakan sebab penolakan. Maklumat ini akan disimpan dan '
                  'dipaparkan kepada Pensyarah.',
                  style: TextStyle(fontSize: 13, color: Color(0xff475569)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: ctrl,
                  maxLines: 3,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Sebab Penolakan',
                    hintText:
                        'Contoh: Bilik telah ditempah, masa bertindih dengan kelas lain...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Sebab penolakan wajib diisi.';
                    }
                    if (v.trim().length < 10) {
                      return 'Sila berikan sebab yang lebih terperinci (minimum 10 aksara).';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, ctrl.text.trim());
              }
            },
            child: const Text('Sahkan Tolak'),
          ),
        ],
      ),
    );
  }
}

class _RoomTimeSlotAvailabilitySelector extends StatelessWidget {
  const _RoomTimeSlotAvailabilitySelector({
    required this.room,
    required this.date,
    required this.selectedStartTime,
    required this.selectedEndTime,
    required this.state,
    required this.onSlotSelected,
  });

  final String room;
  final String date;
  final String selectedStartTime;
  final String selectedEndTime;
  final dynamic state;
  final Function(String start, String end) onSlotSelected;

  static const _standardSlots = [
    {'start': '08:00', 'end': '10:00'},
    {'start': '10:00', 'end': '12:00'},
    {'start': '12:00', 'end': '14:00'},
    {'start': '14:00', 'end': '16:00'},
    {'start': '16:00', 'end': '18:00'},
    {'start': '18:00', 'end': '20:00'},
  ];

  bool _timesOverlap(String startA, String endA, String startB, String endB) {
    int minutes(String text) {
      final parts = text.split(':');
      if (parts.length != 2) return 0;
      return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
    }

    final aStart = minutes(startA);
    final aEnd = minutes(endA);
    final bStart = minutes(startB);
    final bEnd = minutes(endB);
    return aStart < bEnd && bStart < aEnd;
  }

  @override
  Widget build(BuildContext context) {
    if (room.isEmpty || date.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xfff8fafc),
          border: Border.all(color: const Color(0xffe2e8f0)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xff64748b), size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sila pilih Tarikh Ganti dan Bilik untuk melihat ketersediaan slot masa.',
                style: TextStyle(color: Color(0xff64748b), fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    String getMalayDayName(String dateStr) {
      try {
        final parsedDate = DateTime.parse(dateStr);
        switch (parsedDate.weekday) {
          case 1:
            return 'Isnin';
          case 2:
            return 'Selasa';
          case 3:
            return 'Rabu';
          case 4:
            return 'Khamis';
          case 5:
            return 'Jumaat';
          case 6:
            return 'Sabtu';
          case 7:
            return 'Ahad';
          default:
            return '';
        }
      } catch (_) {
        return '';
      }
    }

    String cleanRoom(String name) {
      return name.replaceAll(RegExp(r'\s*\(.*?\)\s*'), '').trim().toLowerCase();
    }

    final targetDay = getMalayDayName(date);
    final targetRoomClean = cleanRoom(room);

    final timetable = state.timetable as List;
    final bookings = state.bookings as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Jadual Ketersediaan Slot Masa'),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: context.isMobile ? 2.6 : 5.0,
          ),
          itemCount: _standardSlots.length,
          itemBuilder: (context, index) {
            final slot = _standardSlots[index];
            final start = slot['start']!;
            final end = slot['end']!;

            final hasJadualConflict = timetable.any((s) {
              if (cleanRoom(s.room) != targetRoomClean) return false;
              final dayMatch = s.day.toLowerCase() == targetDay.toLowerCase() ||
                  s.dayOfWeek?.toLowerCase() == targetDay.toLowerCase();
              final dateMatch = s.date == date;
              if (!dayMatch && !dateMatch) return false;
              return _timesOverlap(start, end, s.startTime, s.endTime);
            });

            final hasBookingConflict = bookings.any((b) {
              if (cleanRoom(b.room) != targetRoomClean ||
                  b.replacementDate != date) return false;
              final isApproved = b.status == 'Approved' || b.status == 'Lulus';
              if (!isApproved) return false;
              return _timesOverlap(
                  start, end, b.replacementStart, b.replacementEnd);
            });

            final isSelected =
                selectedStartTime == start && selectedEndTime == end;

            String label = 'Kosong';
            Color bgColor = const Color(0xffdcfce7);
            Color borderColor = const Color(0xff86efac);
            Color textColor = const Color(0xff166534);
            IconData icon = Icons.check_circle_outline;
            bool isOccupied = false;

            if (hasJadualConflict) {
              label = 'Jadual';
              bgColor = const Color(0xfffee2e2);
              borderColor = const Color(0xfffca5a5);
              textColor = const Color(0xff991b1b);
              icon = Icons.calendar_month_outlined;
              isOccupied = true;
            } else if (hasBookingConflict) {
              label = 'Tempahan Diluluskan';
              bgColor = const Color(0xfffff7ed);
              borderColor = const Color(0xfffed7aa);
              textColor = const Color(0xffc2410c);
              icon = Icons.lock_outline;
              isOccupied = true;
            } else if (isSelected) {
              label = 'Boleh Ditempah (Dipilih)';
              bgColor = const Color(0xff15803d);
              borderColor = const Color(0xff166534);
              textColor = Colors.white;
              icon = Icons.check_circle;
            }

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isOccupied
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Slot $start - $end telah diisi ($label). Sila pilih slot yang kosong.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    : () => onSlotSelected(start, end),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border.all(
                        color: borderColor, width: isSelected ? 2 : 1),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: .2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: textColor, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$start - $end',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              label,
                              style: TextStyle(
                                color: textColor.withValues(
                                    alpha: isSelected ? 0.9 : 0.8),
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Room availability helper panel
// ─────────────────────────────────────────────────────────────────────────────

class _RoomAvailabilityHelper extends StatelessWidget {
  const _RoomAvailabilityHelper({
    required this.date,
    required this.rooms,
    required this.state,
  });

  final String date;
  final List<RoomResource> rooms;
  final dynamic state;

  @override
  Widget build(BuildContext context) {
    if (date.isEmpty || rooms.isEmpty) return const SizedBox.shrink();

    final blocks = rooms.map((r) => r.block).toSet().toList()..sort();

    return AppPanel(
      title: 'Ketersediaan Bilik – $date',
      subtitle:
          'Hijau = tersedia (tiada jadual), Merah = ada jadual / tempahan diluluskan.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: blocks.map((block) {
          final blockRooms = rooms.where((r) => r.block == block).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'Blok $block',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Color(0xff334155),
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: blockRooms.map((r) {
                  final slotCount = (state.timetable as List)
                      .where((s) => s.room == r.name && s.date == date)
                      .length;
                  final bookedCount = (state.bookings as List)
                      .where((b) =>
                          b.room == r.name &&
                          b.replacementDate == date &&
                          b.status == 'Approved')
                      .length;
                  final busy = slotCount + bookedCount > 0;
                  return _RoomBadge(
                      name: r.name,
                      type: r.type,
                      capacity: r.capacity,
                      busy: busy,
                      slotCount: slotCount + bookedCount);
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.slot});
  final TimetableSlot slot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xffdbeafe),
        border: Border.all(color: const Color(0xff93c5fd)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xff1d4ed8), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Kelas asal: ${slot.subjectCode} – ${slot.subjectName}  '
              '·  ${slot.section}  ·  ${slot.day} ${slot.startTime}–${slot.endTime}  '
              '·  ${slot.room}',
              style: const TextStyle(color: Color(0xff1e3a8a), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 12,
        color: Color(0xff475569),
        letterSpacing: .3,
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xff64748b)),
        const SizedBox(width: 4),
        Text('$label: ',
            style: const TextStyle(fontSize: 12, color: Color(0xff64748b))),
        Text(value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xff0f172a))),
      ],
    );
  }
}

class _RoomBadge extends StatelessWidget {
  const _RoomBadge({
    required this.name,
    required this.type,
    this.capacity,
    required this.busy,
    required this.slotCount,
  });
  final String name;
  final String type;
  final int? capacity;
  final bool busy;
  final int slotCount;

  @override
  Widget build(BuildContext context) {
    final color = busy ? Colors.red : Colors.green;
    return Tooltip(
      message: busy
          ? '$slotCount sesi dijadualkan / ditempah'
          : 'Tiada sesi pada tarikh ini',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          border: Border.all(color: color.withValues(alpha: .3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              busy ? Icons.lock_outline : Icons.door_front_door_outlined,
              size: 13,
              color: color,
            ),
            const SizedBox(width: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color)),
                Text(
                  capacity != null ? '$type · $capacity org' : type,
                  style: TextStyle(
                      fontSize: 10, color: color.withValues(alpha: .8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniAvailDot extends StatelessWidget {
  const _MiniAvailDot({required this.available});
  final bool available;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: available ? Colors.green : Colors.red,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(
      {required this.icon, required this.message, required this.color});
  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Icon(icon, size: 42, color: color.withValues(alpha: .5)),
          const SizedBox(height: 10),
          Text(message,
              style: const TextStyle(color: Color(0xff64748b), fontSize: 13)),
        ],
      ),
    );
  }
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied();

  @override
  Widget build(BuildContext context) {
    return const AppPageHeader(
      title: 'Akses Tidak Dibenarkan',
      subtitle: 'Hanya Pensyarah boleh memohon tempahan. '
          'Pengurusan boleh membuat kelulusan mengikut skop.',
    );
  }
}
//test
//run
//test2
