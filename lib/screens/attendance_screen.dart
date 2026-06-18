import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../widgets/app_layout.dart';
import '../widgets/app_theme.dart';
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
  String? _requestedExistingSessionKey;
  String? _checkedMissingSessionKey;
  AttendanceSession? _loadedExistingSession;
  bool _saving = false;
  bool _manualSlotOverride = false;
  String? _autoSelectionReason;
  String _studentSearch = '';
  AttendanceStatus? _statusFilter;
  bool _editingSubmittedSession = false;

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
      _requestedExistingSessionKey = null;
      _checkedMissingSessionKey = null;
      _loadedExistingSession = null;
      _editingSubmittedSession = false;
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
      return const AppPageHeader(
        title: 'Akses Tidak Dibenarkan',
        subtitle: 'Hanya Pensyarah boleh mengambil kehadiran kelas.',
      );
    }
    final slots = state.scopedTimetable;
    final slot = slots.where((item) => item.id == slotId).firstOrNull;
    if (slot == null) return const Text('Tiada slot jadual ditetapkan.');
    final resolvedSessionDate = sessionDate ?? slot.date;
    sessionDate = resolvedSessionDate;
    final sessionId = state.attendanceSessionIdFor(
      slotId: slot.id,
      sessionDate: resolvedSessionDate,
      weekNo: weekNo,
    );
    final cachedExistingSession = _existingSessionFor(
      state,
      slot,
      resolvedSessionDate,
      weekNo,
    );
    final loadedExistingSession =
        _loadedExistingSession?.id == sessionId ? _loadedExistingSession : null;
    final existingSession = cachedExistingSession ?? loadedExistingSession;
    final sessionKey = sessionId;
    final isCheckingSelectedSession =
        existingSession == null && _requestedExistingSessionKey == sessionKey;
    if (_shouldLoadExistingSession(sessionKey, existingSession)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadExistingSessionIfNeeded(
          state: state,
          slot: slot,
          sessionDate: resolvedSessionDate,
          weekNo: weekNo,
          sessionKey: sessionKey,
          existingSession: existingSession,
        );
      });
    }
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
    final currentRecords = _recordsForStudents(slot, students);
    final summary = _summaryFor(currentRecords);
    final isEditingSubmitted = existingSession != null;
    final canEditAttendance =
        existingSession == null || _editingSubmittedSession;
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
    final mobile = MediaQuery.sizeOf(context).width < 600;
    final submitButton = FilledButton.icon(
      onPressed: _saving || isCheckingSelectedSession
          ? null
          : () => _saveAttendance(
                state: state,
                slot: slot,
                isEditingSubmitted: isEditingSubmitted,
              ),
      icon: _saving || isCheckingSelectedSession
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(isEditingSubmitted ? Icons.edit_note : Icons.send),
      label: Text(_saving
          ? 'Menyimpan...'
          : isCheckingSelectedSession
              ? 'Menyemak...'
              : isEditingSubmitted
                  ? 'Simpan Pembetulan'
                  : 'Hantar'),
    );

    return AppPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppPageHeader(
            title: 'Ambil Kehadiran',
            subtitle: mobile
                ? 'Tanda kehadiran kelas.'
                : 'Tanda kehadiran kelas dengan MC dan CK sebagai status pengecualian.',
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
            trailing: mobile || !canEditAttendance ? null : submitButton,
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
                    isEditing: _editingSubmittedSession,
                    summary: summary,
                    totalStudents: students.length,
                    onEdit: () =>
                        setState(() => _editingSubmittedSession = true),
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
                if (mobile && canEditAttendance) ...[
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: submitButton),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppPanel(
            title: 'Kehadiran Pelajar',
            subtitle: canEditAttendance
                ? '${visibleStudents.length} dipaparkan daripada ${students.length} pelajar'
                : 'Senarai pelajar disembunyikan selepas kehadiran dihantar.',
            trailing: mobile || !canEditAttendance
                ? null
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _setAllStatus(
                          slot,
                          students,
                          AttendanceStatus.present,
                        ),
                        icon: const Icon(Icons.done_all),
                        label: const Text('Semua Hadir'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _setAllStatus(
                          slot,
                          students,
                          AttendanceStatus.absent,
                        ),
                        icon: const Icon(Icons.block),
                        label: const Text('Semua Tidak Hadir'),
                      ),
                    ],
                  ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!canEditAttendance)
                  _SubmittedStudentListPlaceholder(
                    studentCount: students.length,
                    onEdit: () =>
                        setState(() => _editingSubmittedSession = true),
                  )
                else ...[
                  if (mobile) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _setAllStatus(
                                slot, students, AttendanceStatus.present),
                            icon: const Icon(Icons.done_all, size: 16),
                            label: const Text('Semua Hadir',
                                style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _setAllStatus(
                                slot, students, AttendanceStatus.absent),
                            icon: const Icon(Icons.block, size: 16),
                            label: const Text('Semua Tak Hadir',
                                style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  _StudentAttendanceFilters(
                    statusFilter: _statusFilter,
                    onSearchChanged: (value) =>
                        setState(() => _studentSearch = value),
                    onStatusChanged: (value) =>
                        setState(() => _statusFilter = value),
                  ),
                  const SizedBox(height: 12),
                  if (mobile)
                    Column(
                      children: visibleStudents.map((student) {
                        final index = records.indexWhere(
                            (record) => record.studentId == student.id);
                        final record = _recordForStudent(slot, student);
                        return _MobileAttendanceStudentCard(
                          student: student,
                          percentage:
                              state.attendancePercentageForStudent(student),
                          status: record.status,
                          onChanged: (value) {
                            if (value == null) return;
                            _updateRecordStatus(slot, record, index, value);
                          },
                        );
                      }).toList(),
                    )
                  else
                    AppDataTable(
                      columns: const [
                        DataColumn(label: Text('ID Pelajar')),
                        DataColumn(label: Text('Nama')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Kehadiran %')),
                      ],
                      rows: visibleStudents.map((student) {
                        final index = records.indexWhere(
                            (record) => record.studentId == student.id);
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
              ],
            ),
          ),
          const SizedBox(height: 16),
          _AttendanceHistoryPanel(
            students: students,
            state: state,
          ),
          if (mobile) const SizedBox(height: 80),
        ],
      ),
    );
  }

  AttendanceSession? _existingSessionFor(
    AppState state,
    TimetableSlot slot,
    String sessionDate,
    int weekNo,
  ) {
    return state.attendanceSessionForSlotDateWeek(
      slotId: slot.id,
      sessionDate: sessionDate,
      weekNo: weekNo,
    );
  }

  void _loadExistingSessionIfNeeded({
    required AppState state,
    required TimetableSlot slot,
    required String sessionDate,
    required int weekNo,
    required String sessionKey,
    required AttendanceSession? existingSession,
  }) {
    final recordsLoaded = existingSession != null &&
        state.sessionAttendance.containsKey(existingSession.id);
    if (recordsLoaded ||
        _requestedExistingSessionKey == sessionKey ||
        _checkedMissingSessionKey == sessionKey) {
      return;
    }

    _requestedExistingSessionKey = sessionKey;
    state
        .loadAttendanceSessionForSlotDateWeek(
      slotId: slot.id,
      sessionDate: sessionDate,
      weekNo: weekNo,
    )
        .then((session) {
      if (!mounted) return;
      if (session == null) {
        setState(() {
          if (_requestedExistingSessionKey == sessionKey) {
            _requestedExistingSessionKey = null;
          }
          _checkedMissingSessionKey = sessionKey;
        });
        return;
      }
      setState(() {
        _loadedExistingSession = session;
        _requestedExistingSessionKey = null;
        loadedSessionKey = null;
        _autoSelectionReason = 'Kehadiran telah dihantar';
        _editingSubmittedSession = false;
      });
    }).catchError((_) {
      if (!mounted) return;
      setState(() {
        if (_requestedExistingSessionKey == sessionKey) {
          _requestedExistingSessionKey = null;
        }
        _checkedMissingSessionKey = sessionKey;
      });
    });
  }

  bool _shouldLoadExistingSession(
    String sessionKey,
    AttendanceSession? existingSession,
  ) {
    return existingSession == null &&
        _requestedExistingSessionKey != sessionKey &&
        _checkedMissingSessionKey != sessionKey;
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
                    decoration: const InputDecoration(labelText: 'Sesi Kelas'),
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
      _loadedExistingSession = null;
      _requestedExistingSessionKey = null;
      _checkedMissingSessionKey = null;
      loadedSessionKey = null;
      _editingSubmittedSession = false;
    });
  }

  AttendanceRecord _recordForStudent(TimetableSlot slot, Student student) {
    final record =
        records.where((record) => record.studentId == student.id).firstOrNull;
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
    final messenger = ScaffoldMessenger.of(context);
    if (!isEditingSubmitted) {
      AttendanceSession? existingSession =
          _existingSessionFor(state, slot, resolvedSessionDate, weekNo);
      try {
        existingSession ??= await state.loadAttendanceSessionForSlotDateWeek(
          slotId: slot.id,
          sessionDate: resolvedSessionDate,
          weekNo: weekNo,
          forceRefresh: true,
        );
      } catch (_) {
        existingSession = null;
      }
      if (existingSession != null) {
        if (!mounted) return;
        setState(() {
          _manualSlotOverride = true;
          _loadedExistingSession = existingSession;
          _checkedMissingSessionKey = null;
          _autoSelectionReason = 'Kehadiran telah dihantar';
          loadedSessionKey = null;
          _editingSubmittedSession = false;
        });
        messenger.showSnackBar(const SnackBar(
          content: Text(
            'Sesi kehadiran sedia ada dimuatkan. Anda boleh simpan pembetulan.',
          ),
        ));
        return;
      }
    }

    String? editReason;
    if (isEditingSubmitted) {
      final changes = _attendanceChangesFor(
        state,
        slot,
        resolvedSessionDate,
        weekNo,
      );
      if (changes.isEmpty) {
        messenger.showSnackBar(const SnackBar(
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
      if (!mounted) return;

      AttendanceSession? submittedSessionForUi =
          state.attendanceSessionForSlotDateWeek(
        slotId: slot.id,
        sessionDate: resolvedSessionDate,
        weekNo: weekNo,
      );
      if (!isEditingSubmitted && submittedSessionForUi == null) {
        submittedSessionForUi = state.markAttendanceSessionSubmittedLocally(
          slot.id,
          records,
          sessionDate: resolvedSessionDate,
          weekNo: weekNo,
        );
      }

      setState(() {
        _manualSlotOverride = true;
        _loadedExistingSession =
            submittedSessionForUi ?? _loadedExistingSession;
        _requestedExistingSessionKey = null;
        _checkedMissingSessionKey = null;
        _autoSelectionReason = isEditingSubmitted
            ? 'Pembetulan telah disimpan'
            : 'Kehadiran telah dihantar';
        loadedSessionKey = null;
        _editingSubmittedSession = false;
      });
      messenger.showSnackBar(SnackBar(
        content: Text(isEditingSubmitted
            ? 'Pembetulan kehadiran telah disimpan.'
            : 'Kehadiran telah dihantar.'),
      ));
    } catch (error) {
      if (!mounted) return;
      if (error is AttendanceSessionAlreadyExistsException) {
        _switchToExistingSession(error.session, messenger);
        return;
      }
      if (!isEditingSubmitted) {
        AttendanceSession? existingSession;
        try {
          existingSession = await state.loadAttendanceSessionForSlotDateWeek(
            slotId: slot.id,
            sessionDate: resolvedSessionDate,
            weekNo: weekNo,
            forceRefresh: true,
          );
        } catch (_) {
          existingSession = null;
        }
        if (!mounted) return;
        if (existingSession != null) {
          _switchToExistingSession(existingSession, messenger);
          return;
        }
        if (_isDuplicateAttendanceError(error)) {
          final session = state.markAttendanceSessionSubmittedLocally(
            slot.id,
            records,
            sessionDate: resolvedSessionDate,
            weekNo: weekNo,
          );
          _switchToExistingSession(session, messenger);
          return;
        }
      }
      messenger.showSnackBar(SnackBar(
        content: Text(isEditingSubmitted
            ? error.toString().replaceFirst('Bad state: ', '')
            : 'Kehadiran untuk slot, tarikh dan minggu ini sudah wujud.'),
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _switchToExistingSession(
    AttendanceSession session,
    ScaffoldMessengerState messenger,
  ) {
    if (!mounted) return;
    setState(() {
      _manualSlotOverride = true;
      _loadedExistingSession = session;
      _requestedExistingSessionKey = null;
      _checkedMissingSessionKey = null;
      _autoSelectionReason = 'Kehadiran telah dihantar';
      loadedSessionKey = null;
      _editingSubmittedSession = false;
    });
    messenger.showSnackBar(const SnackBar(
      content: Text(
        'Sesi kehadiran sedia ada dimuatkan. Anda boleh simpan pembetulan.',
      ),
    ));
  }

  bool _isDuplicateAttendanceError(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('attendance session already exists') ||
        text.contains('already exists for this slot') ||
        text.contains('sudah wujud');
  }

  List<AttendanceEditChange> _attendanceChangesFor(
    AppState state,
    TimetableSlot slot,
    String sessionDate,
    int weekNo,
  ) {
    final existingSession =
        _existingSessionFor(state, slot, sessionDate, weekNo);
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
      final student = state.students
          .where((item) => item.id == record.studentId)
          .firstOrNull;
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

    final todaySlots = sorted
        .where((slot) => _sessionDateForSlot(slot, now) == today)
        .toList();

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
    return state.attendanceSessionForSlotDateWeek(
          slotId: slot.id,
          sessionDate: date,
          weekNo: week,
        ) !=
        null;
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

  void _setAllStatus(
    TimetableSlot slot,
    List<Student> students,
    AttendanceStatus status,
  ) {
    setState(() {
      records = students
          .map((student) => _recordForStudent(slot, student).copyWith(
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

  List<AttendanceRecord> _recordsForStudents(
    TimetableSlot slot,
    List<Student> students,
  ) {
    return students.map((student) => _recordForStudent(slot, student)).toList();
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
    final mobile = MediaQuery.sizeOf(context).width < 600;

    if (mobile) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${slot.subjectCode} - ${slot.subjectName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${slot.section} - ${slot.startTime}-${slot.endTime} - ${slot.room}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (reason != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      reason!,
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit_calendar,
                  color: AppColors.primary, size: 20),
              onPressed: onChangeClass,
              tooltip: 'Tukar Sesi',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceTint,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
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
                  color: AppColors.surfaceTint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.fact_check_outlined,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot.subjectCode,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      slot.subjectName,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  if (reason != null)
                    _InfoPill(
                      icon: Icons.auto_awesome,
                      label: reason!,
                      tone: AppColors.success,
                      tinted: true,
                    ),
                  OutlinedButton.icon(
                    onPressed: onChangeClass,
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Tukar Kelas'),
                  ),
                ],
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
                tone: AppColors.muted,
              ),
              _InfoPill(
                icon: Icons.schedule,
                label: '${slot.startTime}-${slot.endTime}',
                tone: AppColors.muted,
              ),
              _InfoPill(
                icon: Icons.meeting_room_outlined,
                label: slot.room,
                tone: AppColors.muted,
              ),
              _InfoPill(
                icon: Icons.event,
                label: sessionDate,
                tone: AppColors.muted,
              ),
              _InfoPill(
                icon: Icons.calendar_view_week_outlined,
                label: 'Minggu $weekNo',
                tone: AppColors.muted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubmittedAttendanceBanner extends StatelessWidget {
  const _SubmittedAttendanceBanner({
    required this.editCount,
    required this.isEditing,
    required this.summary,
    required this.totalStudents,
    required this.onEdit,
  });

  final int editCount;
  final bool isEditing;
  final AttendanceSummary summary;
  final int totalStudents;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    final action = isEditing
        ? const StatusChip('Sedang Edit')
        : OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_note, size: 18),
            label: const Text('Edit Kehadiran'),
          );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xfff0fdf4),
        border: Border.all(color: const Color(0xffdcfce7)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Flex(
        direction: mobile ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment:
            mobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          if (!mobile) ...[
            const Icon(Icons.check_circle_outline, color: Color(0xff16a34a)),
            const SizedBox(width: 10),
          ],
          if (mobile)
            _SubmittedBannerText(summary: summary, totalStudents: totalStudents)
          else
            Expanded(
                child: _SubmittedBannerText(
                    summary: summary, totalStudents: totalStudents)),
          SizedBox(width: mobile ? 0 : 10, height: mobile ? 12 : 0),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (editCount > 0)
                _InfoPill(
                  icon: Icons.history,
                  label: 'Pembetulan: $editCount',
                  tone: const Color(0xff16a34a),
                  tinted: true,
                ),
              action,
            ],
          ),
        ],
      ),
    );
  }
}

class _SubmittedStudentListPlaceholder extends StatelessWidget {
  const _SubmittedStudentListPlaceholder({
    required this.studentCount,
    required this.onEdit,
  });

  final int studentCount;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 600;

    if (mobile) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xfff8fafc),
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Senarai pelajar diringkaskan',
                    style: TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$studentCount pelajar telah dihantar. Klik Edit Kehadiran untuk membuat pembetulan.',
              style: const TextStyle(
                  color: AppColors.muted, fontSize: 11, height: 1.3),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_note, size: 16),
                label: const Text('Edit Kehadiran',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lock_outline, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SubmittedStudentListText(studentCount: studentCount),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_note, size: 18),
            label: const Text('Edit Kehadiran'),
          ),
        ],
      ),
    );
  }
}

class _SubmittedBannerText extends StatelessWidget {
  const _SubmittedBannerText(
      {required this.summary, required this.totalStudents});

  final AttendanceSummary summary;
  final int totalStudents;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kehadiran telah dihantar',
          style: TextStyle(
            color: Color(0xff166534),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$totalStudents pelajar: ${summary.present} hadir, ${summary.late} lewat, ${summary.absent} tidak hadir, ${summary.mc + summary.ck} MC/CK.',
          style: const TextStyle(
            color: Color(0xff166534),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SubmittedStudentListText extends StatelessWidget {
  const _SubmittedStudentListText({required this.studentCount});

  final int studentCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Senarai pelajar telah diringkaskan',
          style: TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$studentCount pelajar telah dihantar. Klik Edit Kehadiran untuk membuka semula senarai dan membuat pembetulan.',
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = MediaQuery.sizeOf(context).width < 600;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: mobile ? double.infinity : 300,
              height: mobile ? 44 : null,
              child: TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, size: 20),
                  labelText: 'Cari pelajar',
                  hintText: 'ID atau nama pelajar',
                  contentPadding: mobile
                      ? const EdgeInsets.symmetric(horizontal: 12)
                      : null,
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            SizedBox(height: mobile ? 8 : 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 6,
                children: [
                  for (final status in statuses)
                    ChoiceChip(
                      label: Text(status?.label ?? 'Semua'),
                      selected: statusFilter == status,
                      onSelected: (_) => onStatusChanged(status),
                      backgroundColor: AppColors.surface,
                      selectedColor: AppColors.primary.withValues(alpha: .1),
                      side: BorderSide(
                        color: statusFilter == status
                            ? AppColors.primary.withValues(alpha: .28)
                            : AppColors.border,
                      ),
                      padding: mobile ? const EdgeInsets.all(4) : null,
                      visualDensity: mobile ? VisualDensity.compact : null,
                      labelStyle: TextStyle(
                        color: statusFilter == status
                            ? AppColors.primary
                            : AppColors.muted,
                        fontSize: mobile ? 12 : 14,
                        fontWeight: statusFilter == status
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
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
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return Container(
      height: mobile ? 40 : 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      constraints: BoxConstraints(maxWidth: mobile ? double.infinity : 132),
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

class _MobileAttendanceStudentCard extends StatelessWidget {
  const _MobileAttendanceStudentCard({
    required this.student,
    required this.percentage,
    required this.status,
    required this.onChanged,
  });

  final Student student;
  final int percentage;
  final AttendanceStatus status;
  final ValueChanged<AttendanceStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${student.id} · $percentage%',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: _AttendanceStatusSelector(
              value: status,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
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
    final mobile = MediaQuery.sizeOf(context).width < 600;

    if (mobile) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xfff8fafc),
          border: Border.all(color: const Color(0xffe2e8f0)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Wrap(
          spacing: 12,
          runSpacing: 10,
          alignment: WrapAlignment.spaceEvenly,
          children: [
            _MobileSummaryItem(
                label: 'Pljr',
                value: '$totalStudents',
                color: const Color(0xff334155)),
            _MobileSummaryItem(
                label: 'Hadir',
                value: '${summary.present}',
                color: const Color(0xff16a34a)),
            _MobileSummaryItem(
                label: 'Lewat',
                value: '${summary.late}',
                color: const Color(0xfff59e0b)),
            _MobileSummaryItem(
                label: 'TH',
                value: '${summary.absent}',
                color: const Color(0xffdc2626)),
            _MobileSummaryItem(
                label: 'MC',
                value: '${summary.mc + summary.ck}',
                color: const Color(0xff64748b)),
            _MobileSummaryItem(
                label: '%',
                value: '${summary.percentage}%',
                color: const Color(0xff2563eb),
                isEmphasized: true),
          ],
        ),
      );
    }

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

class _MobileSummaryItem extends StatelessWidget {
  const _MobileSummaryItem({
    required this.label,
    required this.value,
    required this.color,
    this.isEmphasized = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool isEmphasized;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: isEmphasized ? 16 : 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
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
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return Container(
      width: mobile ? (emphasized ? 136 : 94) : (emphasized ? 154 : 124),
      padding: EdgeInsets.symmetric(
          horizontal: mobile ? 8 : 10, vertical: mobile ? 8 : 9),
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
                    color: AppColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: mobile
                        ? (emphasized ? 18 : 15)
                        : (emphasized ? 20 : 17),
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

class _AttendanceHistoryPanel extends StatelessWidget {
  const _AttendanceHistoryPanel({
    required this.students,
    required this.state,
  });

  final List<Student> students;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: 'Kehadiran Pelajar',
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowHeight: 40,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 52,
                horizontalMargin: 12,
                columns: const [
                  DataColumn(
                      label: Text('Nama',
                          style: TextStyle(fontWeight: FontWeight.w800))),
                  DataColumn(
                      label: Text('ID Pelajar',
                          style: TextStyle(fontWeight: FontWeight.w800))),
                  DataColumn(
                      label: Text('Kehadiran',
                          style: TextStyle(fontWeight: FontWeight.w800))),
                  DataColumn(
                      label: Text('Status',
                          style: TextStyle(fontWeight: FontWeight.w800))),
                  DataColumn(
                      label: Text('Tindakan',
                          style: TextStyle(fontWeight: FontWeight.w800))),
                ],
                rows: students.map((student) {
                  final summary =
                      state.sessionAttendanceSummaryForStudent(student);
                  final weekly = state.weeklyAttendanceForStudent(student);
                  final risk = _attendanceRiskFor(summary);
                  final attendanceText = _attendanceTextFor(summary);
                  return DataRow(
                    cells: [
                      DataCell(Text(student.name,
                          style: const TextStyle(fontWeight: FontWeight.w900))),
                      DataCell(Text(student.id,
                          style: const TextStyle(color: Color(0xff64748b)))),
                      DataCell(Text(attendanceText,
                          style: TextStyle(
                              fontWeight: FontWeight.w900, color: risk.color))),
                      DataCell(_RiskChip(risk: risk)),
                      DataCell(
                        TextButton.icon(
                          onPressed: () =>
                              _showWeeklyDetailsModal(context, student, weekly),
                          icon: const Icon(Icons.calendar_view_week_outlined,
                              size: 16),
                          label: const Text('Lihat Mingguan',
                              style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8)),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
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
    const defaultTone = Color(0xff2563eb);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: tinted ? tone.withValues(alpha: .08) : const Color(0xffeff6ff),
        border: Border.all(
            color:
                tinted ? tone.withValues(alpha: .2) : const Color(0xffbfdbfe)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: tinted ? tone : defaultTone),
          const SizedBox(width: 7),
          Text(
            label.isEmpty ? '-' : label,
            style: TextStyle(
              color: tinted ? tone : const Color(0xff1e3a8a),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

void _showWeeklyDetailsModal(
    BuildContext context, Student student, List<AttendanceSummary> weekly) {
  final isMobile = MediaQuery.sizeOf(context).width < 600;
  final child = SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            student.name,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDark),
          ),
          const SizedBox(height: 4),
          Text(
            student.id,
            style: const TextStyle(
                color: AppColors.muted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          const Text(
            'Kehadiran Mingguan',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _WeeklyMiniGrid(weekly: weekly),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ),
        ],
      ),
    ),
  );

  if (isMobile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => child,
    );
  } else {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: child,
        ),
      ),
    );
  }
}

_AttendanceRisk _attendanceRiskFor(AttendanceSummary summary) {
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

String _attendanceTextFor(AttendanceSummary summary) {
  if (summary.denominator == 0 && (summary.mc + summary.ck) > 0) {
    return 'Pengecualian Sah';
  }
  if (summary.denominator == 0) return 'Tiada Sesi Layak';
  return '${summary.percentage}%';
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
        final text =
            summary.denominator == 0 && summary.mc == 0 && summary.ck == 0
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
