import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../state/app_scope.dart';
import '../widgets/app_layout.dart';
import '../widgets/app_theme.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Page header ──
        PageHeader(
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
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
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
  List<TimetableSlot> _getSlots(dynamic state, dynamic user) {
    final personal = state.scopedTimetable as List<TimetableSlot>;
    if (personal.isNotEmpty) return personal;
    final code = user.programId as String?;
    if (code == null || code.isEmpty) {
      return state.timetable as List<TimetableSlot>;
    }
    return (state.timetable as List<TimetableSlot>).where((s) {
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
                'Bilik yang dipilih tidak tersedia pada masa tersebut. Sila pilih bilik atau masa lain.'),
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
                  _SectionLabel('Kelas Asal'),
                  const SizedBox(height: 8),
                  if (slots.isEmpty)
                    const Text(
                      'Tiada slot jadual ditemui untuk program anda.',
                      style: TextStyle(color: Color(0xff64748b)),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedSlotId,
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
                  _SectionLabel('Tarikh & Masa Ganti'),
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
                  _SectionLabel('Pilihan Bilik'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 160,
                        child: DropdownButtonFormField<String>(
                          value: _block,
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
                            value: filteredRooms.any((r) => r.name == _room)
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
                  if (canCheck && !available)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: const [
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
                  _SectionLabel('Sebab & Catatan'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 260,
                        child: DropdownButtonFormField<String>(
                          value: _reason,
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
            AppPanel(
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
                    .map((b) => _BookingApprovalCard(booking: b))
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
            AppPanel(
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
// Booking card
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: .035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Wrap(
            spacing: 24,
            runSpacing: 6,
            children: [
              _DetailItem(
                  icon: Icons.person_outline,
                  label: 'Pensyarah',
                  value: booking.lecturerName),
              _DetailItem(
                  icon: Icons.event_outlined,
                  label: 'Kelas Asal',
                  value: '${booking.originalDate}  ${booking.originalTime}'),
              _DetailItem(
                  icon: Icons.swap_horiz,
                  label: 'Ganti',
                  value:
                      '${booking.replacementDate}  ${booking.replacementStart}–${booking.replacementEnd}'),
              _DetailItem(
                  icon: Icons.door_front_door_outlined,
                  label: 'Bilik',
                  value: booking.room),
              _DetailItem(
                  icon: Icons.info_outline,
                  label: 'Sebab',
                  value: booking.reason),
              _DetailItem(
                  icon: Icons.circle_outlined,
                  label: 'Ketersediaan',
                  value: avail ? '✓ Tersedia' : '✗ Tidak Tersedia'),
              if (booking.remarks.isNotEmpty)
                _DetailItem(
                    icon: Icons.notes_outlined,
                    label: 'Catatan',
                    value: booking.remarks),
            ],
          ),
          if (!avail)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppColors.warning, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Bilik telah ditempah pada masa ini.',
                    style: TextStyle(color: AppColors.warning, fontSize: 12),
                  ),
                ],
              ),
            ),
          if (showActions) ...[
            const SizedBox(height: 12),
            _ApproveRejectButtons(bookingId: booking.id),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Approve / Reject button pair
// ─────────────────────────────────────────────────────────────────────────────

class _ApproveRejectButtons extends StatelessWidget {
  const _ApproveRejectButtons({required this.bookingId});
  final String bookingId;

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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('✓ Permohonan telah diluluskan.'),
                    backgroundColor: Colors.green),
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
            final confirmed = await _confirmReject(context);
            if (confirmed == true && context.mounted) {
              await state.updateBooking(bookingId, 'Rejected');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Permohonan telah ditolak.'),
                      backgroundColor: Colors.red),
                );
              }
            }
          },
          icon: const Icon(Icons.close, size: 16),
          label: const Text('Tolak'),
        ),
      ],
    );
  }

  Future<bool?> _confirmReject(BuildContext ctx) {
    return showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Tolak Permohonan'),
        content: const Text('Adakah anda pasti ingin menolak permohonan ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xffdc2626)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tolak'),
          ),
        ],
      ),
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
    return const PageHeader(
      title: 'Akses Tidak Dibenarkan',
      subtitle: 'Hanya Pensyarah boleh memohon tempahan. '
          'Ketua Program dan Ketua Jabatan boleh meluluskan '
          'permohonan mengikut skop.',
    );
  }
}
//test
//run
//test2