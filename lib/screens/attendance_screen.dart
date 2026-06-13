import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../widgets/app_layout.dart';
import '../widgets/status_chip.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String? slotId;
  String? sessionDate;
  int weekNo = 1;
  var records = <AttendanceRecord>[];
  String? loadedSessionKey;
  bool _saving = false;
  bool _manualSlotOverride = false;
  String? _autoSelectionReason;
  String _studentSearch = '';
  AttendanceStatus? _statusFilter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppScope.of(context);
    final slots = state.scopedTimetable;
    if (slots.isEmpty) return;
    final selectedStillExists = slots.any((slot) => slot.id == slotId);
    if (_manualSlotOverride && selectedStillExists) return;

    final selection = _bestSlotForNow(state, slots);
    final selected = selection?.slot;
    if (slotId != selected?.id) {
      slotId = selected?.id;
      sessionDate = selection?.sessionDate;
      weekNo = selection?.weekNo ?? weekNo;
      _autoSelectionReason = selection?.reason;
      loadedSessionKey = null;
    } else {
      sessionDate ??= selection?.sessionDate;
      weekNo = selection?.weekNo ?? _weekNoForDate(state, sessionDate);
      _autoSelectionReason = selection?.reason;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.currentUser!;
    if (user.role != UserRole.pensyarah) {
      return const PageHeader(
        title: 'Akses Tidak Dibenarkan',
        subtitle: 'Hanya Pensyarah boleh mengambil kehadiran kelas.',
      );
    }
    final slots = state.scopedTimetable;
    final slot = slots.where((item) => item.id == slotId).firstOrNull;
    if (slot == null) return const Text('Tiada slot jadual ditetapkan.');
    final resolvedSessionDate = sessionDate ?? slot.date;
    sessionDate = resolvedSessionDate;
    final existingSession = _existingSessionFor(
      state,
      slot,
      resolvedSessionDate,
      weekNo,
    );
    final sessionKey = '${slot.id}|$resolvedSessionDate|$weekNo';
    if (loadedSessionKey != sessionKey) {
      records = List.of(existingSession == null
          ? state.attendance[slot.id] ?? _defaultRecords(slot, state)
          : state.sessionAttendance[existingSession.id] ??
              state.attendance[slot.id] ??
              _defaultRecords(slot, state));
      loadedSessionKey = sessionKey;
    }
    final students = state.students
        .where((student) => student.section == slot.section)
        .toList();
    final summary = _summaryFor(records);
    final isEditingSubmitted = existingSession != null;
    final selectionReason =
        isEditingSubmitted ? 'Kehadiran telah dihantar' : _autoSelectionReason;
    final visibleStudents = students.where((student) {
      final record = _recordForStudent(slot, student);
      final query = _studentSearch.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          student.id.toLowerCase().contains(query) ||
          student.name.toLowerCase().contains(query);
      final matchesStatus =
          _statusFilter == null || record.status == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Ambil Kehadiran',
          subtitle:
              'Tanda kehadiran kelas dengan MC dan CK sebagai status pengecualian.',
          trailing: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusChip(slot.status),
            ],
          ),
        ),
        AppPanel(
          title: 'Sesi Kehadiran',
          subtitle: '${slot.subjectCode} - ${slot.subjectName}',
          trailing: FilledButton.icon(
            onPressed: _saving
                ? null
                : () => _saveAttendance(
                      state: state,
                      slot: slot,
                      isEditingSubmitted: isEditingSubmitted,
                    ),
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(isEditingSubmitted ? Icons.edit_note : Icons.send),
            label: Text(_saving
                ? 'Menyimpan...'
                : isEditingSubmitted
                    ? 'Simpan Pembetulan'
                    : 'Hantar'),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SelectedClassHeader(
                slot: slot,
                sessionDate: resolvedSessionDate,
                weekNo: weekNo,
                reason: selectionReason,
                onChangeClass: () => _showChangeSessionDialog(
                  state: state,
                  slots: slots,
                  currentSlot: slot,
                ),
              ),
              if (existingSession != null) ...[
                const SizedBox(height: 12),
                _SubmittedAttendanceBanner(
                  editCount: existingSession.editHistory.length,
                ),
              ],
              if (existingSession?.editReason != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xfff8fafc),
                    border: Border.all(color: const Color(0xffe2e8f0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Pembetulan terakhir: ${existingSession!.editReason}',
                    style: const TextStyle(color: Color(0xff475569)),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _AttendanceSummaryStrip(
                summary: summary,
                totalStudents: students.length,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppPanel(
          title: 'Kehadiran Pelajar',
          subtitle:
              '${visibleStudents.length} dipaparkan daripada ${students.length} pelajar',
          trailing: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _setAllStatus(slot, AttendanceStatus.present),
                icon: const Icon(Icons.done_all),
                label: const Text('Semua Hadir'),
              ),
              OutlinedButton.icon(
                onPressed: () => _setAllStatus(slot, AttendanceStatus.absent),
                icon: const Icon(Icons.block),
                label: const Text('Semua Tidak Hadir'),
              ),
            ],
          ),
          child: Column(
            children: [
              _StudentAttendanceFilters(
                statusFilter: _statusFilter,
                onSearchChanged: (value) =>
                    setState(() => _studentSearch = value),
                onStatusChanged: (value) =>
                    setState(() => _statusFilter = value),
              ),
              const SizedBox(height: 12),
              AppDataTable(
                columns: const [
                  DataColumn(label: Text('ID Pelajar')),
                  DataColumn(label: Text('Nama')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Kehadiran %')),
                ],
                rows: visibleStudents.map((student) {
                  final index = records
                      .indexWhere((record) => record.studentId == student.id);
                  final record = _recordForStudent(slot, student);
                  return DataRow(cells: [
                    DataCell(Text(student.id)),
                    DataCell(Text(student.name)),
                    DataCell(_AttendanceStatusSelector(
                      value: record.status,
                      onChanged: (value) {
                        if (value == null) return;
                        _updateRecordStatus(slot, record, index, value);
                      },
                    )),
                    DataCell(Text(
                        '${state.attendancePercentageForStudent(student)}%')),
                  ]);
                }).toList(),
              ),
              if (visibleStudents.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Tiada pelajar sepadan dengan carian atau tapisan.',
                    style: TextStyle(color: Color(0xff64748b)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _AttendanceHistoryPanel(
          students: students,
          state: state,
        ),
      ],
    );
  }

  AttendanceSession? _existingSessionFor(
    AppState state,
    TimetableSlot slot,
    String sessionDate,
    int weekNo,
  ) {
    return state.attendanceSessions
        .where((session) =>
            session.slotId == slot.id &&
            session.sessionDate == sessionDate &&
            session.weekNo == weekNo)
        .firstOrNull;
  }

  Future<void> _pickSessionDate(AppState state, TimetableSlot slot) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(sessionDate ?? slot.date) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (selected == null) return;
    setState(() {
      sessionDate = _dateText(selected);
      weekNo = _weekNoForDate(state, sessionDate);
      _manualSlotOverride = true;
      _autoSelectionReason = 'Pilihan manual';
      loadedSessionKey = null;
    });
  }

  Future<void> _showChangeSessionDialog({
    required AppState state,
    required List<TimetableSlot> slots,
    required TimetableSlot currentSlot,
  }) async {
    var draftSlotId = currentSlot.id;
    var draftDate = sessionDate ?? currentSlot.date;
    var draftWeek = weekNo;

    final result = await showDialog<_ManualSessionSelection>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final draftSlot =
              slots.where((slot) => slot.id == draftSlotId).firstOrNull ??
                  currentSlot;
          return AlertDialog(
            title: const Text('Tukar Kelas'),
            content: SizedBox(
              width: 460,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: draftSlotId,
                    decoration:
                        const InputDecoration(labelText: 'Sesi Kelas'),
                    items: slots
                        .map((slot) => DropdownMenuItem(
                              value: slot.id,
                              child:
                                  Text('${slot.subjectCode} - ${slot.section}'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      final selectedSlot =
                          slots.where((slot) => slot.id == value).firstOrNull;
                      setDialogState(() {
                        draftSlotId = value;
                        draftDate =
                            _sessionDateForSlot(selectedSlot, DateTime.now());
                        draftWeek = _weekNoForDate(state, draftDate);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final selected = await showDatePicker(
                              context: context,
                              initialDate: DateTime.tryParse(draftDate) ??
                                  DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (selected == null) return;
                            setDialogState(() {
                              draftDate = _dateText(selected);
                              draftWeek = _weekNoForDate(state, draftDate);
                            });
                          },
                          icon: const Icon(Icons.event),
                          label: Text(draftDate),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 150,
                        child: DropdownButtonFormField<int>(
                          initialValue: draftWeek,
                          decoration:
                              const InputDecoration(labelText: 'Minggu'),
                          items: List.generate(18, (index) => index + 1)
                              .map((week) => DropdownMenuItem(
                                  value: week, child: Text('Minggu $week')))
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setDialogState(() => draftWeek = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${draftSlot.subjectName} | ${draftSlot.startTime}-${draftSlot.endTime}',
                      style: const TextStyle(color: Color(0xff64748b)),
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
                onPressed: () => Navigator.of(context).pop(
                  _ManualSessionSelection(
                    slotId: draftSlotId,
                    sessionDate: draftDate,
                    weekNo: draftWeek,
                  ),
                ),
                child: const Text('Guna'),
              ),
            ],
          );
        },
      ),
    );

    if (result == null) return;
    setState(() {
      slotId = result.slotId;
      sessionDate = result.sessionDate;
      weekNo = result.weekNo;
      _manualSlotOverride = true;
      _autoSelectionReason = 'Pilihan manual';
      loadedSessionKey = null;
    });
  }

  AttendanceRecord _recordForStudent(TimetableSlot slot, Student student) {
    final record = records
        .where((record) => record.studentId == student.id)
        .firstOrNull;
    return record ??
        AttendanceRecord(
          slotId: slot.id,
          studentId: student.id,
          status: AttendanceStatus.present,
          checkIn: slot.startTime,
          remarks: '',
        );
  }

  Future<void> _saveAttendance({
    required AppState state,
    required TimetableSlot slot,
    required bool isEditingSubmitted,
  }) async {
    final resolvedSessionDate = sessionDate ?? slot.date;
    String? editReason;
    if (isEditingSubmitted) {
      final changes = _attendanceChangesFor(
        state,
        slot,
        resolvedSessionDate,
        weekNo,
      );
      if (changes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tiada perubahan status untuk disimpan.'),
        ));
        return;
      }
      editReason = await _promptEditReason(changes);
      if (editReason == null) return;
    }

    setState(() => _saving = true);
    try {
      if (isEditingSubmitted) {
        await state.editAttendance(
          slot.id,
          records,
          sessionDate: resolvedSessionDate,
          weekNo: weekNo,
          editReason: editReason!,
        );
      } else {
        await state.saveAttendance(
          slot.id,
          records,
          sessionDate: resolvedSessionDate,
          weekNo: weekNo,
        );
      }
      if (!context.mounted) return;
      setState(() {
        _manualSlotOverride = true;
        _autoSelectionReason = isEditingSubmitted
            ? 'Pembetulan telah disimpan'
            : 'Kehadiran telah dihantar';
        loadedSessionKey = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isEditingSubmitted
            ? 'Pembetulan kehadiran telah disimpan.'
            : 'Kehadiran telah dihantar.'),
      ));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isEditingSubmitted
            ? error.toString().replaceFirst('Bad state: ', '')
            : 'Kehadiran untuk slot, tarikh dan minggu ini sudah wujud.'),
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<AttendanceEditChange> _attendanceChangesFor(
    AppState state,
    TimetableSlot slot,
    String sessionDate,
    int weekNo,
  ) {
    final existingSession = _existingSessionFor(state, slot, sessionDate, weekNo);
    if (existingSession == null) return const [];
    final previousRecords = state.sessionAttendance[existingSession.id] ??
        state.attendance[slot.id] ??
        const <AttendanceRecord>[];
    final previousByStudent = {
      for (final record in previousRecords) record.studentId: record,
    };
    final changes = <AttendanceEditChange>[];
    for (final record in records) {
      final previous = previousByStudent[record.studentId];
      if (previous == null || previous.status == record.status) continue;
      final student =
          state.students.where((item) => item.id == record.studentId).firstOrNull;
      changes.add(AttendanceEditChange(
        studentId: record.studentId,
        studentName: record.studentName ?? student?.name ?? record.studentId,
        originalStatus: previous.status,
        newStatus: record.status,
      ));
    }
    return changes;
  }

  Future<String?> _promptEditReason(List<AttendanceEditChange> changes) async {
    final controller = TextEditingController();
    var showError = false;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Sahkan Pembetulan Kehadiran'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${changes.length} perubahan status akan direkodkan dalam audit.',
                  style: const TextStyle(color: Color(0xff475569)),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: changes.length,
                    separatorBuilder: (_, __) => const Divider(height: 12),
                    itemBuilder: (context, index) {
                      final change = changes[index];
                      return Text(
                        '${change.studentName}: ${change.originalStatus.label} -> ${change.newStatus.label}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Sebab pembetulan',
                    hintText: 'Contoh: Pelajar menghantar MC selepas kelas.',
                    errorText:
                        showError ? 'Sebab pembetulan wajib diisi.' : null,
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
            FilledButton.icon(
              onPressed: () {
                final reason = controller.text.trim();
                if (reason.isEmpty) {
                  setDialogState(() => showError = true);
                  return;
                }
                Navigator.of(context).pop(reason);
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Sahkan & Simpan'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return result;
  }

  int _weekNoForDate(AppState state, String? dateText) {
    final date = DateTime.tryParse(dateText ?? '');
    if (date == null) return weekNo.clamp(1, 18).toInt();

    final academicSession = state.academicSessions
        .where((item) => item.academicSessionId == state.session)
        .firstOrNull;
    final startDate = DateTime.tryParse(academicSession?.startDate ?? '');
    if (startDate == null) return weekNo.clamp(1, 18).toInt();

    final calculated = (date.difference(startDate).inDays ~/ 7) + 1;
    return calculated.clamp(1, 18).toInt();
  }

  _SlotSelection? _bestSlotForNow(AppState state, List<TimetableSlot> slots) {
    if (slots.isEmpty) return null;

    final now = DateTime.now();
    final today = _dateText(now);
    final sorted = List<TimetableSlot>.of(slots)
      ..sort((a, b) => _slotStartDateTime(a).compareTo(_slotStartDateTime(b)));

    _SlotSelection selectionFor(TimetableSlot slot, String reason) {
      final date = _sessionDateForSlot(slot, now);
      return _SlotSelection(
        slot: slot,
        sessionDate: date,
        weekNo: _weekNoForDate(state, date),
        reason: reason,
      );
    }

    final todaySlots =
        sorted.where((slot) => _sessionDateForSlot(slot, now) == today).toList();

    final ongoing =
        todaySlots.where((slot) => _isOngoing(slot, now)).firstOrNull;
    if (ongoing != null) {
      return selectionFor(ongoing, 'Kelas sedang berlangsung');
    }

    final startingSoon = todaySlots
        .where((slot) =>
            _startsSoon(slot, now, const Duration(minutes: 30)) &&
            !_hasAttendanceSession(state, slot, today))
        .firstOrNull;
    if (startingSoon != null) {
      return selectionFor(startingSoon, 'Kelas akan bermula sebentar lagi');
    }

    final pastUnsubmitted = todaySlots.reversed
        .where((slot) =>
            _slotEndDateTime(slot).isBefore(now) &&
            !_hasAttendanceSession(state, slot, today))
        .firstOrNull;
    if (pastUnsubmitted != null) {
      return selectionFor(pastUnsubmitted, 'Kehadiran belum dihantar');
    }

    final nextUpcoming = sorted
        .where((slot) => _slotStartDateTime(slot).isAfter(now))
        .firstOrNull;
    if (nextUpcoming != null) {
      return selectionFor(nextUpcoming, 'Kelas seterusnya');
    }

    return selectionFor(sorted.first, 'Slot pertama ditetapkan');
  }

  bool _isOngoing(TimetableSlot slot, DateTime now) {
    final start = _slotStartDateTime(slot);
    final end = _slotEndDateTime(slot);
    return !now.isBefore(start) && now.isBefore(end);
  }

  bool _startsSoon(TimetableSlot slot, DateTime now, Duration window) {
    final start = _slotStartDateTime(slot);
    return start.isAfter(now) && start.difference(now) <= window;
  }

  bool _hasAttendanceSession(
    AppState state,
    TimetableSlot slot,
    String date,
  ) {
    final week = _weekNoForDate(state, date);
    return state.attendanceSessions.any((session) =>
        session.slotId == slot.id &&
        session.sessionDate == date &&
        session.weekNo == week);
  }

  DateTime _slotStartDateTime(TimetableSlot slot) {
    return _combineDateTime(
      _sessionDateForSlot(slot, DateTime.now()),
      slot.startTime,
    );
  }

  DateTime _slotEndDateTime(TimetableSlot slot) {
    return _combineDateTime(
      _sessionDateForSlot(slot, DateTime.now()),
      slot.endTime,
    );
  }

  DateTime _combineDateTime(String dateText, String timeText) {
    final date = DateTime.tryParse(dateText) ?? DateTime.now();
    final parts = timeText.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  String _dateText(DateTime date) {
    return date.toIso8601String().substring(0, 10);
  }

  String _sessionDateForSlot(TimetableSlot? slot, DateTime now) {
    if (slot == null) return _dateText(now);
    final parsed = DateTime.tryParse(slot.date);
    if (parsed != null) return _dateText(parsed);
    final weekStart = DateTime.tryParse(slot.weekStart ?? '');
    if (weekStart != null) return _dateText(weekStart);
    // TODO: Replace this fallback when timetable rows always provide a real date.
    return _dateText(now);
  }

  void _setAllStatus(TimetableSlot slot, AttendanceStatus status) {
    setState(() {
      records = records
          .map((record) => record.copyWith(
                status: status,
                checkIn: _checkInForStatus(slot, status),
              ))
          .toList();
    });
  }

  void _updateRecordStatus(
    TimetableSlot slot,
    AttendanceRecord record,
    int index,
    AttendanceStatus status,
  ) {
    setState(() {
      final updated = record.copyWith(
        status: status,
        checkIn: _checkInForStatus(slot, status),
      );
      if (index == -1) {
        records.add(updated);
      } else {
        records[index] = updated;
      }
    });
  }

  String _checkInForStatus(TimetableSlot slot, AttendanceStatus status) {
    return status == AttendanceStatus.absent ||
            status == AttendanceStatus.mc ||
            status == AttendanceStatus.ck
        ? '-'
        : slot.startTime;
  }

  AttendanceSummary _summaryFor(List<AttendanceRecord> records) {
    var summary =
        const AttendanceSummary(present: 0, late: 0, absent: 0, mc: 0, ck: 0);
    for (final record in records) {
      summary = summary.add(record.status);
    }
    return summary;
  }
}

class _SlotSelection {
  const _SlotSelection({
    required this.slot,
    required this.sessionDate,
    required this.weekNo,
    required this.reason,
  });

  final TimetableSlot slot;
  final String sessionDate;
  final int weekNo;
  final String reason;
}

class _ManualSessionSelection {
  const _ManualSessionSelection({
    required this.slotId,
    required this.sessionDate,
    required this.weekNo,
  });

  final String slotId;
  final String sessionDate;
  final int weekNo;
}

class _SelectedClassHeader extends StatelessWidget {
  const _SelectedClassHeader({
    required this.slot,
    required this.sessionDate,
    required this.weekNo,
    required this.reason,
    required this.onChangeClass,
  });

  final TimetableSlot slot;
  final String sessionDate;
  final int weekNo;
  final String? reason;
  final VoidCallback onChangeClass;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffe2e8f0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xfff1f5f9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.fact_check_outlined,
                  color: Color(0xff475569),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${slot.subjectCode} - ${slot.section}',
                      style: const TextStyle(
                        color: Color(0xff0f172a),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      slot.subjectName,
                      style: const TextStyle(color: Color(0xff64748b)),
                    ),
                  ],
                ),
              ),
              if (reason != null)
                _InfoPill(
                  icon: Icons.auto_awesome,
                  label: reason!,
                  tone: const Color(0xff0f766e),
                  tinted: true,
                ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onChangeClass,
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Tukar Kelas'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(
                icon: Icons.groups_outlined,
                label: slot.section,
                tone: const Color(0xff475569),
              ),
              _InfoPill(
                icon: Icons.schedule,
                label: '${slot.startTime}-${slot.endTime}',
                tone: const Color(0xff475569),
              ),
              _InfoPill(
                icon: Icons.meeting_room_outlined,
                label: slot.room,
                tone: const Color(0xff475569),
              ),
              _InfoPill(
                icon: Icons.event,
                label: sessionDate,
                tone: const Color(0xff475569),
              ),
              _InfoPill(
                icon: Icons.calendar_view_week_outlined,
                label: 'Minggu $weekNo',
                tone: const Color(0xff475569),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubmittedAttendanceBanner extends StatelessWidget {
  const _SubmittedAttendanceBanner({required this.editCount});

  final int editCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xfff0fdf4),
        border: Border.all(color: const Color(0xffdcfce7)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xff16a34a)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Kehadiran telah dihantar untuk sesi ini. Ubah status pelajar dan simpan pembetulan jika perlu.',
              style: TextStyle(
                color: Color(0xff166534),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (editCount > 0)
            _InfoPill(
              icon: Icons.history,
              label: 'Pembetulan: $editCount',
              tone: const Color(0xff16a34a),
              tinted: true,
            ),
        ],
      ),
    );
  }
}

class _StudentAttendanceFilters extends StatelessWidget {
  const _StudentAttendanceFilters({
    required this.statusFilter,
    required this.onSearchChanged,
    required this.onStatusChanged,
  });

  final AttendanceStatus? statusFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<AttendanceStatus?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final statuses = <AttendanceStatus?>[
      null,
      AttendanceStatus.present,
      AttendanceStatus.late,
      AttendanceStatus.absent,
      AttendanceStatus.mc,
      AttendanceStatus.ck,
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 300,
          child: TextField(
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Cari pelajar',
              hintText: 'ID atau nama pelajar',
            ),
          ),
        ),
        for (final status in statuses)
          ChoiceChip(
            label: Text(status?.label ?? 'Semua'),
            selected: statusFilter == status,
            onSelected: (_) => onStatusChanged(status),
            backgroundColor: Colors.white,
            selectedColor: const Color(0xffeef2ff),
            side: BorderSide(
              color: statusFilter == status
                  ? const Color(0xffc7d2fe)
                  : const Color(0xffe2e8f0),
            ),
            labelStyle: TextStyle(
              color: statusFilter == status
                  ? const Color(0xff3730a3)
                  : const Color(0xff475569),
              fontWeight:
                  statusFilter == status ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _AttendanceStatusSelector extends StatelessWidget {
  const _AttendanceStatusSelector({
    required this.value,
    required this.onChanged,
  });

  final AttendanceStatus value;
  final ValueChanged<AttendanceStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(value);
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      constraints: const BoxConstraints(maxWidth: 132),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        border: Border.all(color: const Color(0xffe2e8f0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AttendanceStatus>(
          isDense: true,
          isExpanded: true,
          value: value,
          iconSize: 18,
          items: AttendanceStatus.values
              .map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(
                      status.label,
                      style: TextStyle(
                        color: _statusColor(status),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Color _statusColor(AttendanceStatus status) {
    return switch (status) {
      AttendanceStatus.present => const Color(0xff16a34a),
      AttendanceStatus.late => const Color(0xffd97706),
      AttendanceStatus.absent => const Color(0xffdc2626),
      AttendanceStatus.mc => const Color(0xff64748b),
      AttendanceStatus.ck => const Color(0xff475569),
    };
  }
}

class _AttendanceSummaryStrip extends StatelessWidget {
  const _AttendanceSummaryStrip({
    required this.summary,
    required this.totalStudents,
  });

  final AttendanceSummary summary;
  final int totalStudents;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        border: Border.all(color: const Color(0xffe2e8f0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _SummaryTile(
            label: 'Pelajar',
            value: '$totalStudents',
            icon: Icons.people_alt_outlined,
            color: const Color(0xff334155),
          ),
          _SummaryTile(
            label: 'Hadir',
            value: '${summary.present}',
            icon: Icons.check_circle_outline,
            color: const Color(0xff16a34a),
          ),
          _SummaryTile(
            label: 'Lewat',
            value: '${summary.late}',
            icon: Icons.schedule,
            color: const Color(0xfff59e0b),
          ),
          _SummaryTile(
            label: 'Tidak Hadir',
            value: '${summary.absent}',
            icon: Icons.cancel_outlined,
            color: const Color(0xffdc2626),
          ),
          _SummaryTile(
            label: 'MC/CK',
            value: '${summary.mc + summary.ck}',
            icon: Icons.health_and_safety_outlined,
            color: const Color(0xff64748b),
          ),
          _SummaryTile(
            label: 'Kehadiran',
            value: '${summary.percentage}%',
            icon: Icons.trending_up,
            color: const Color(0xff2563eb),
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: emphasized ? 154 : 124,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffe2e8f0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff64748b),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: emphasized ? 20 : 17,
                    fontWeight: FontWeight.w900,
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

class _AttendanceHistoryPanel extends StatefulWidget {
  const _AttendanceHistoryPanel({
    required this.students,
    required this.state,
  });

  final List<Student> students;
  final AppState state;

  @override
  State<_AttendanceHistoryPanel> createState() =>
      _AttendanceHistoryPanelState();
}

class _AttendanceHistoryPanelState extends State<_AttendanceHistoryPanel> {
  String? _expandedStudentId;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: 'Ringkasan Kehadiran Pelajar',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final cardWidth =
              isWide ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: widget.students.map((student) {
              return SizedBox(
                width: cardWidth,
                child: _StudentAttendanceSummaryCard(
                  student: student,
                  summary:
                      widget.state.sessionAttendanceSummaryForStudent(student),
                  weekly: widget.state.weeklyAttendanceForStudent(student),
                  expanded: _expandedStudentId == student.id,
                  onToggleWeekly: () {
                    setState(() {
                      _expandedStudentId =
                          _expandedStudentId == student.id ? null : student.id;
                    });
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.tone,
    this.tinted = false,
  });

  final IconData icon;
  final String label;
  final Color tone;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tinted ? tone.withValues(alpha: .08) : const Color(0xfff8fafc),
        border: Border.all(
            color: tinted
                ? tone.withValues(alpha: .2)
                : const Color(0xffe2e8f0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: tone),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: tinted ? tone : const Color(0xff334155),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlySessionField extends StatelessWidget {
  const _ReadOnlySessionField({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        border: Border.all(color: const Color(0xffcbd5e1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xff64748b)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xff64748b),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
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

class _StudentAttendanceSummaryCard extends StatelessWidget {
  const _StudentAttendanceSummaryCard({
    required this.student,
    required this.summary,
    required this.weekly,
    required this.expanded,
    required this.onToggleWeekly,
  });

  final Student student;
  final AttendanceSummary summary;
  final List<AttendanceSummary> weekly;
  final bool expanded;
  final VoidCallback onToggleWeekly;

  @override
  Widget build(BuildContext context) {
    final risk = _riskFor(summary);
    final attendanceText = _attendanceText(summary);
    final progressValue = summary.denominator == 0
        ? 0.0
        : summary.percentage.clamp(0, 100) / 100;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
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
                      student.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xff0f172a),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      student.id,
                      style: const TextStyle(color: Color(0xff64748b)),
                    ),
                  ],
                ),
              ),
              _RiskChip(risk: risk),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: progressValue,
                    color: risk.color,
                    backgroundColor: const Color(0xffe5e7eb),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                attendanceText,
                style: TextStyle(
                  color: risk.color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniMetric(label: 'Sesi Hadir', value: '${summary.attended}'),
              _MiniMetric(
                  label: 'Sesi Tidak Hadir', value: '${summary.absent}'),
              _MiniMetric(
                  label: 'MC/CK',
                  value: '${summary.mc + summary.ck}'),
            ],
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: onToggleWeekly,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: Icon(
              expanded ? Icons.expand_less : Icons.calendar_view_week_outlined,
              size: 18,
            ),
            label: Text(expanded ? 'Tutup Mingguan' : 'Lihat Mingguan'),
          ),
          if (expanded) ...[
            const SizedBox(height: 4),
            _WeeklyMiniGrid(weekly: weekly),
          ],
        ],
      ),
    );
  }

  _AttendanceRisk _riskFor(AttendanceSummary summary) {
    if (summary.denominator == 0 && (summary.mc + summary.ck) > 0) {
      return const _AttendanceRisk('Pengecualian Sah', Color(0xff64748b));
    }
    if (summary.denominator == 0) {
      return const _AttendanceRisk('Tiada Sesi Layak', Color(0xff64748b));
    }
    if (summary.denominator < 3) {
      return const _AttendanceRisk('Data Awal', Color(0xff64748b));
    }
    if (summary.percentage >= 90) {
      return const _AttendanceRisk('Baik', Color(0xff16a34a));
    }
    if (summary.percentage >= 80) {
      return const _AttendanceRisk('Perhatian', Color(0xffd97706));
    }
    return const _AttendanceRisk('Kritikal', Color(0xffdc2626));
  }

  String _attendanceText(AttendanceSummary summary) {
    if (summary.denominator == 0 && (summary.mc + summary.ck) > 0) {
      return 'Pengecualian Sah';
    }
    if (summary.denominator == 0) return 'Tiada Sesi Layak';
    return '${summary.percentage}%';
  }
}

class _AttendanceRisk {
  const _AttendanceRisk(this.label, this.color);

  final String label;
  final Color color;
}

class _RiskChip extends StatelessWidget {
  const _RiskChip({required this.risk});

  final _AttendanceRisk risk;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: risk.color.withValues(alpha: .08),
        border: Border.all(color: risk.color.withValues(alpha: .18)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        risk.label,
        style: TextStyle(
          color: risk.color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 106,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffe2e8f0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xff64748b),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xff0f172a),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyMiniGrid extends StatelessWidget {
  const _WeeklyMiniGrid({required this.weekly});

  final List<AttendanceSummary> weekly;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: List.generate(18, (index) {
        final summary = weekly[index];
        final text = summary.denominator == 0 && summary.mc == 0 && summary.ck == 0
            ? '-'
            : '${summary.percentage}%';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xfff8fafc),
            border: Border.all(color: const Color(0xffe2e8f0)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'M${index + 1}',
                style: const TextStyle(
                  color: Color(0xff64748b),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                text,
                style: const TextStyle(
                  color: Color(0xff334155),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Generate blank attendance records (all present) for a slot.
List<AttendanceRecord> _defaultRecords(TimetableSlot slot, dynamic state) {
  final sectionStudents = (state.students as List<Student>)
      .where((s) => s.section == slot.section)
      .toList();
  return sectionStudents
      .map((s) => AttendanceRecord(
            slotId: slot.id,
            studentId: s.id,
            status: AttendanceStatus.present,
            checkIn: slot.startTime,
            remarks: '',
          ))
      .toList();
}
