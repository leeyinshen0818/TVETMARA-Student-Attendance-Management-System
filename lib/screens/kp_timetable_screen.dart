import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../services/timetable_file_io.dart';
import '../services/timetable_view_export_service.dart';
import '../services/timetable_xlsx_export_service.dart';
import '../state/app_scope.dart';
import '../widgets/app_layout.dart';
import '../widgets/class_timetable_generator_dialog.dart';
import '../widgets/status_chip.dart';

class KpTimetableScreen extends StatefulWidget {
  const KpTimetableScreen({super.key, required this.kpUser});

  final AppUser kpUser;

  @override
  State<KpTimetableScreen> createState() => _KpTimetableScreenState();
}

class _KpTimetableScreenState extends State<KpTimetableScreen> {
  String? _selectedSession;
  String? _selectedClassId;
  String? _subjectFilter;
  String? _lecturerFilter;
  String? _roomFilter;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final programId = widget.kpUser.programId ?? '';
    final program =
        state.programs.where((item) => item.id == programId).firstOrNull;
    final sessionOptions = _sessionOptions(state);
    final activeSession = _selectedSession ??
        (sessionOptions.contains(state.session)
            ? state.session
            : sessionOptions.firstOrNull);
    final scopedSlots = state.scopedTimetable
        .where((slot) =>
            slot.programId == programId && _slotSession(slot) == activeSession)
        .toList()
      ..sort(_slotSorter);
    final classOptions = _sortedUnique(scopedSlots.map(_slotClassId));
    if (_selectedClassId != null && !classOptions.contains(_selectedClassId)) {
      _selectedClassId = null;
    }
    final visibleSlots = scopedSlots.where((slot) {
      final subject = '${slot.subjectCode} - ${slot.subjectName}';
      final lecturer = slot.lecturerName;
      final room = _slotRoom(slot);
      return (_subjectFilter == null || subject == _subjectFilter) &&
          (_lecturerFilter == null || lecturer == _lecturerFilter) &&
          (_roomFilter == null || room == _roomFilter);
    }).toList();

    final titleProgram = programId.isEmpty ? 'Program' : programId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPageHeader(
          title: 'Jadual Program',
          subtitle:
              'Lihat jadual rasmi untuk program $titleProgram sahaja. Gunakan eksport untuk berkongsi jadual dengan pelajar.',
          trailing: StatusChip('Program: $titleProgram'),
        ),
        AppPanel(
          title: 'Skop Paparan',
          subtitle:
              'Paparan ini adalah baca sahaja. Muat naik, edit dan tindakan batch diurus oleh Ketua Jabatan.',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(
                  'Program',
                  program == null
                      ? titleProgram
                      : '${program.id} - ${program.name}'),
              _InfoChip('Sesi', activeSession ?? '-'),
              _InfoChip('Kelas', '${classOptions.length} seksyen'),
              _InfoChip('Slot', '${scopedSlots.length} slot'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ProgramSlotList(
          slots: visibleSlots,
          subjectFilter: _subjectFilter,
          lecturerFilter: _lecturerFilter,
          roomFilter: _roomFilter,
          subjectOptions: _sortedUnique(scopedSlots
              .map((slot) => '${slot.subjectCode} - ${slot.subjectName}')),
          lecturerOptions:
              _sortedUnique(scopedSlots.map((slot) => slot.lecturerName)),
          roomOptions: _sortedUnique(scopedSlots.map(_slotRoom)),
          onSubjectChanged: (value) => setState(() => _subjectFilter = value),
          onLecturerChanged: (value) => setState(() => _lecturerFilter = value),
          onRoomChanged: (value) => setState(() => _roomFilter = value),
          onReset: () => setState(() {
            _subjectFilter = null;
            _lecturerFilter = null;
            _roomFilter = null;
          }),
        ),
        const SizedBox(height: 16),
        _ClassTimetableSecondaryAction(
          enabled: classOptions.isNotEmpty && activeSession != null,
          onOpen: () => _showClassTimetableGeneratorDialog(
            programId: programId,
            programName: program?.name ?? programId,
            sessionOptions: sessionOptions,
            selectedSession: activeSession ?? '',
          ),
        ),
      ],
    );
  }

  List<String> _sessionOptions(dynamic state) {
    final values = state.academicSessions
        .map<String>((session) => session.academicSessionId as String)
        .toSet()
        .toList()
      ..sort();
    if (values.isEmpty) values.add(state.session as String);
    return values;
  }

  Future<void> _showClassTimetableGeneratorDialog({
    required String programId,
    required String programName,
    required List<String> sessionOptions,
    required String selectedSession,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => ClassTimetableGeneratorDialog(
        sessionOptions: sessionOptions,
        initialSessionId: selectedSession,
        programOptions: [programId],
        initialProgramId: programId,
        lockProgram: true,
        programLabelFor: (value) => '$value - $programName',
        classOptionsFor: (academicSessionId, value) {
          final state = AppScope.of(context);
          final scopedSlots = state.scopedTimetable
              .where((slot) =>
                  slot.programId == value &&
                  _slotSession(slot) == academicSessionId)
              .toList();
          return _sortedUnique(scopedSlots.map(_slotClassId));
        },
        slotsFor: (academicSessionId, value, classId) {
          final state = AppScope.of(context);
          final scopedSlots = state.scopedTimetable
              .where((slot) =>
                  slot.programId == value &&
                  _slotSession(slot) == academicSessionId)
              .toList();
          return filterClassTimetableSlots(
            scopedSlots,
            programId: value,
            classId: classId,
            academicSessionId: academicSessionId,
          );
        },
        onExport: (academicSessionId, value, classId, slots) {
          _selectedSession = academicSessionId;
          _selectedClassId = classId;
          _exportClassTimetable(
            programId: value,
            programName: programName,
            classId: classId,
            academicSessionId: academicSessionId,
            generatedBy: widget.kpUser.name,
            slots: slots,
          );
        },
      ),
    );
  }

  void _exportClassTimetable({
    required String programId,
    required String programName,
    required String classId,
    required String academicSessionId,
    required String generatedBy,
    required List<TimetableSlot> slots,
  }) {
    final state = AppScope.of(context);
    final program = state.programs.where((p) => p.id == programId).firstOrNull;
    downloadBinaryFile(
      filename:
          'jadual_kelas_${_safeFileSegment(classId)}_${_safeFileSegment(academicSessionId)}.xlsx',
      bytes: buildClassTimetableXlsx(
        programId: programId,
        programName: program?.name ?? programId,
        classId: classId,
        academicSessionId: academicSessionId,
        generatedBy: state.currentUser?.name ?? '-',
        generatedAt: DateTime.now(),
        slots: slots,
      ),
    );
  }
}

class _ClassTimetableSecondaryAction extends StatelessWidget {
  const _ClassTimetableSecondaryAction({
    required this.enabled,
    required this.onOpen,
  });

  final bool enabled;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: 'Jana / Eksport Jadual Kelas',
      subtitle:
          'Alat sokongan untuk berkongsi jadual kelas kepada pelajar. Senarai Slot Program kekal sebagai paparan utama.',
      trailing: OutlinedButton.icon(
        onPressed: enabled ? onOpen : null,
        icon: const Icon(Icons.view_week_outlined),
        label: const Text('Jana / Eksport Jadual Kelas'),
      ),
      child: const Text(
        'Pilih tindakan ini untuk menjana jadual satu kelas atau seksyen dalam skop program anda.',
        style: TextStyle(color: Color(0xff64748b)),
      ),
    );
  }
}

class _ProgramSlotList extends StatelessWidget {
  const _ProgramSlotList({
    required this.slots,
    required this.subjectFilter,
    required this.lecturerFilter,
    required this.roomFilter,
    required this.subjectOptions,
    required this.lecturerOptions,
    required this.roomOptions,
    required this.onSubjectChanged,
    required this.onLecturerChanged,
    required this.onRoomChanged,
    required this.onReset,
  });

  final List<TimetableSlot> slots;
  final String? subjectFilter;
  final String? lecturerFilter;
  final String? roomFilter;
  final List<String> subjectOptions;
  final List<String> lecturerOptions;
  final List<String> roomOptions;
  final ValueChanged<String?> onSubjectChanged;
  final ValueChanged<String?> onLecturerChanged;
  final ValueChanged<String?> onRoomChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: 'Senarai Slot Program',
      subtitle: 'Senarai sokongan untuk semakan subjek, pensyarah dan bilik.',
      trailing: OutlinedButton.icon(
        onPressed: onReset,
        icon: const Icon(Icons.refresh),
        label: const Text('Reset Penapis'),
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _FilterSelect(
                label: 'Subjek',
                value: subjectFilter,
                options: subjectOptions,
                onChanged: onSubjectChanged,
              ),
              _FilterSelect(
                label: 'Pensyarah',
                value: lecturerFilter,
                options: lecturerOptions,
                onChanged: onLecturerChanged,
              ),
              _FilterSelect(
                label: 'Bilik',
                value: roomFilter,
                options: roomOptions,
                onChanged: onRoomChanged,
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppDataTable(
            columns: const [
              DataColumn(label: Text('Kod')),
              DataColumn(label: Text('Subjek')),
              DataColumn(label: Text('Kelas')),
              DataColumn(label: Text('Pensyarah')),
              DataColumn(label: Text('Hari & Masa')),
              DataColumn(label: Text('Bilik')),
              DataColumn(label: Text('Minggu')),
            ],
            rows: slots
                .map(
                  (slot) => DataRow(cells: [
                    DataCell(Text(slot.subjectCode)),
                    DataCell(Text(slot.subjectName)),
                    DataCell(Text(_slotClassId(slot))),
                    DataCell(Text(slot.lecturerName)),
                    DataCell(Text(
                        '${_normalDay(slot.dayOfWeek ?? slot.day)} ${slot.startTime}-${slot.endTime}')),
                    DataCell(Text(_slotRoom(slot))),
                    DataCell(Text(
                        '${slot.weekStart ?? '1'}-${slot.weekEnd ?? '18'}')),
                  ]),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _FilterSelect extends StatelessWidget {
  const _FilterSelect({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          const DropdownMenuItem<String>(value: null, child: Text('Semua')),
          ...options.map(
            (option) => DropdownMenuItem(value: option, child: Text(option)),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        border: Border.all(color: const Color(0xffe2e8f0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$label: $value'),
    );
  }
}

String _slotSession(TimetableSlot slot) =>
    slot.academicSessionId ?? slot.session;
String _slotClassId(TimetableSlot slot) => slot.classId ?? slot.section;
String _slotRoom(TimetableSlot slot) => slot.roomName ?? slot.room;

String _normalDay(String value) {
  final upper = value.trim().toUpperCase();
  return switch (upper) {
    'MONDAY' || 'ISNIN' => 'Isnin',
    'TUESDAY' || 'SELASA' => 'Selasa',
    'WEDNESDAY' || 'RABU' => 'Rabu',
    'THURSDAY' || 'KHAMIS' => 'Khamis',
    'FRIDAY' || 'JUMAAT' => 'Jumaat',
    'SATURDAY' || 'SABTU' => 'Sabtu',
    'SUNDAY' || 'AHAD' => 'Ahad',
    _ => value,
  };
}

List<String> _sortedUnique(Iterable<String> values) {
  return values
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
}

int _slotSorter(TimetableSlot a, TimetableSlot b) {
  final day = _dayOrder(_normalDay(a.dayOfWeek ?? a.day))
      .compareTo(_dayOrder(_normalDay(b.dayOfWeek ?? b.day)));
  if (day != 0) return day;
  final time = a.startTime.compareTo(b.startTime);
  if (time != 0) return time;
  return _slotClassId(a).compareTo(_slotClassId(b));
}

int _dayOrder(String day) {
  return switch (day) {
    'Isnin' => 1,
    'Selasa' => 2,
    'Rabu' => 3,
    'Khamis' => 4,
    'Jumaat' => 5,
    'Sabtu' => 6,
    'Ahad' => 7,
    _ => 99,
  };
}

String _safeFileSegment(String value) {
  return value.trim().replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
}
