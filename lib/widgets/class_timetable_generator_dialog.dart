import 'package:flutter/material.dart';

import '../models/app_models.dart';

typedef ClassOptionsBuilder = List<String> Function(
  String academicSessionId,
  String programId,
);

typedef ClassSlotsBuilder = List<TimetableSlot> Function(
  String academicSessionId,
  String programId,
  String classId,
);

typedef ClassTimetableExportCallback = void Function(
  String academicSessionId,
  String programId,
  String classId,
  List<TimetableSlot> slots,
);

class ClassTimetableGeneratorDialog extends StatefulWidget {
  const ClassTimetableGeneratorDialog({
    super.key,
    required this.sessionOptions,
    required this.initialSessionId,
    required this.programOptions,
    required this.initialProgramId,
    required this.programLabelFor,
    required this.classOptionsFor,
    required this.slotsFor,
    required this.onExport,
    this.lockProgram = false,
  });

  final List<String> sessionOptions;
  final String initialSessionId;
  final List<String> programOptions;
  final String? initialProgramId;
  final String Function(String programId) programLabelFor;
  final ClassOptionsBuilder classOptionsFor;
  final ClassSlotsBuilder slotsFor;
  final ClassTimetableExportCallback onExport;
  final bool lockProgram;

  @override
  State<ClassTimetableGeneratorDialog> createState() =>
      _ClassTimetableGeneratorDialogState();
}

class _ClassTimetableGeneratorDialogState
    extends State<ClassTimetableGeneratorDialog> {
  late String _selectedSessionId;
  String? _selectedProgramId;
  String? _selectedClassId;

  @override
  void initState() {
    super.initState();
    _selectedSessionId = widget.sessionOptions.contains(widget.initialSessionId)
        ? widget.initialSessionId
        : widget.sessionOptions.firstOrNull ?? widget.initialSessionId;
    _selectedProgramId = widget.initialProgramId ??
        (widget.programOptions.length == 1
            ? widget.programOptions.first
            : null);
    _syncClassSelection();
  }

  void _syncClassSelection() {
    final programId = _selectedProgramId;
    if (programId == null) {
      _selectedClassId = null;
      return;
    }
    final classOptions = widget.classOptionsFor(_selectedSessionId, programId);
    if (_selectedClassId == null || !classOptions.contains(_selectedClassId)) {
      _selectedClassId = classOptions.firstOrNull;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final maxWidth = size.width < 1040 ? size.width - 32 : 1040.0;
    final maxHeight = size.height < 760 ? size.height - 32 : 720.0;
    final programId = _selectedProgramId;
    final classOptions = programId == null
        ? <String>[]
        : widget.classOptionsFor(_selectedSessionId, programId);
    final slots = programId == null || _selectedClassId == null
        ? <TimetableSlot>[]
        : widget.slotsFor(_selectedSessionId, programId, _selectedClassId!);

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jana Jadual Kelas / Seksyen',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Pilih program dan kelas untuk menjana jadual mingguan yang boleh dikongsi dengan pelajar.',
                          style: TextStyle(color: Color(0xff64748b)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: 220,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _selectedSessionId,
                            decoration: const InputDecoration(
                              labelText: 'Sesi Akademik',
                            ),
                            items: widget.sessionOptions
                                .map((value) => DropdownMenuItem(
                                      value: value,
                                      child: _DropdownLabel(value),
                                    ))
                                .toList(),
                            selectedItemBuilder: (context) => widget
                                .sessionOptions
                                .map(_DropdownLabel.new)
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _selectedSessionId = value;
                                _syncClassSelection();
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          width: 260,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _selectedProgramId,
                            decoration:
                                const InputDecoration(labelText: 'Program'),
                            items: widget.programOptions
                                .map((value) => DropdownMenuItem(
                                      value: value,
                                      child: Tooltip(
                                        message: widget.programLabelFor(value),
                                        child: _DropdownLabel(
                                          widget.programLabelFor(value),
                                        ),
                                      ),
                                    ))
                                .toList(),
                            selectedItemBuilder: (context) => widget
                                .programOptions
                                .map((value) => Tooltip(
                                      message: widget.programLabelFor(value),
                                      child: _DropdownLabel(
                                        widget.programLabelFor(value),
                                      ),
                                    ))
                                .toList(),
                            onChanged: widget.lockProgram
                                ? null
                                : (value) {
                                    setState(() {
                                      _selectedProgramId = value;
                                      _selectedClassId = null;
                                      _syncClassSelection();
                                    });
                                  },
                          ),
                        ),
                        SizedBox(
                          width: 240,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _selectedClassId,
                            decoration: const InputDecoration(
                              labelText: 'Kelas / Seksyen',
                            ),
                            items: classOptions
                                .map((value) => DropdownMenuItem(
                                      value: value,
                                      child: _DropdownLabel(value),
                                    ))
                                .toList(),
                            selectedItemBuilder: (context) =>
                                classOptions.map(_DropdownLabel.new).toList(),
                            onChanged: (value) =>
                                setState(() => _selectedClassId = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClassTimetableGridPreview(
                      academicSessionId: _selectedSessionId,
                      programLabel: programId == null
                          ? '-'
                          : widget.programLabelFor(programId),
                      classId: _selectedClassId ?? '-',
                      slots: slots,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Tutup'),
                  ),
                  FilledButton.icon(
                    onPressed: programId == null || _selectedClassId == null
                        ? null
                        : () => widget.onExport(
                              _selectedSessionId,
                              programId,
                              _selectedClassId!,
                              slots,
                            ),
                    icon: const Icon(Icons.ios_share_outlined),
                    label: const Text('Eksport Jadual Kelas'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownLabel extends StatelessWidget {
  const _DropdownLabel(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
    );
  }
}

class ClassTimetableGridPreview extends StatelessWidget {
  const ClassTimetableGridPreview({
    super.key,
    required this.academicSessionId,
    required this.programLabel,
    required this.classId,
    required this.slots,
  });

  static const _days = ['Isnin', 'Selasa', 'Rabu', 'Khamis', 'Jumaat'];
  static const _blocks = [
    ('08:00', '10:00'),
    ('10:00', '12:00'),
    ('14:00', '16:00'),
    ('16:00', '18:00'),
  ];

  final String academicSessionId;
  final String programLabel;
  final String classId;
  final List<TimetableSlot> slots;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffe2e8f0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              color: const Color(0xff0f172a),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'JADUAL WAKTU KELAS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$programLabel | $classId | $academicSessionId',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xffcbd5e1)),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const _GridHeaderCell(label: 'Masa', width: 112),
                      for (final day in _days)
                        _GridHeaderCell(label: day, width: 190),
                    ],
                  ),
                  for (final block in _blocks)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TimeCell('${block.$1}-${block.$2}'),
                        for (final day in _days)
                          _SlotCell(
                            slots: slots
                                .where((slot) =>
                                    _normalMalayDay(
                                          slot.dayOfWeek ?? slot.day,
                                        ) ==
                                        day &&
                                    slot.startTime == block.$1 &&
                                    slot.endTime == block.$2)
                                .toList(),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridHeaderCell extends StatelessWidget {
  const _GridHeaderCell({required this.label, required this.width});

  final String label;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xfff8fafc),
        border: Border(
          right: BorderSide(color: Color(0xffe2e8f0)),
          bottom: BorderSide(color: Color(0xffe2e8f0)),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _TimeCell extends StatelessWidget {
  const _TimeCell(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      constraints: const BoxConstraints(minHeight: 116),
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Color(0xffe2e8f0)),
          bottom: BorderSide(color: Color(0xffe2e8f0)),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _SlotCell extends StatelessWidget {
  const _SlotCell({required this.slots});

  final List<TimetableSlot> slots;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      constraints: const BoxConstraints(minHeight: 116),
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Color(0xffe2e8f0)),
          bottom: BorderSide(color: Color(0xffe2e8f0)),
        ),
      ),
      child: slots.isEmpty
          ? const Align(
              alignment: Alignment.topLeft,
              child: Text('-', style: TextStyle(color: Color(0xff94a3b8))),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final slot in slots) ...[
                  _SlotPreviewCard(slot: slot),
                  if (slot != slots.last) const SizedBox(height: 6),
                ],
              ],
            ),
    );
  }
}

class _SlotPreviewCard extends StatelessWidget {
  const _SlotPreviewCard({required this.slot});

  final TimetableSlot slot;

  @override
  Widget build(BuildContext context) {
    final room = _slotRoomValue(slot);
    final week = 'Minggu ${slot.weekStart ?? '1'}-${slot.weekEnd ?? '18'}';
    final tooltip = [
      slot.subjectCode,
      slot.subjectName,
      slot.lecturerName,
      room,
      week,
    ].where((value) => value.trim().isNotEmpty).join('\n');
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xffeff6ff),
          border: Border.all(color: const Color(0xffbfdbfe)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slot.subjectCode,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: Color(0xff1d4ed8),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              slot.subjectName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, height: 1.15),
            ),
            const SizedBox(height: 5),
            Text(
              slot.lecturerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xff475569),
              ),
            ),
            Text(
              room,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xff475569),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              week,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xff64748b),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _slotRoomValue(TimetableSlot slot) {
  final normalized = (slot.roomName ?? '').trim();
  if (normalized.isNotEmpty) return normalized;
  final legacy = slot.room.trim();
  return legacy.isEmpty ? '-' : legacy;
}

String _normalMalayDay(String? value) {
  final key = (value ?? '').trim().toLowerCase();
  const map = {
    'isnin': 'Isnin',
    'monday': 'Isnin',
    'selasa': 'Selasa',
    'tuesday': 'Selasa',
    'rabu': 'Rabu',
    'wednesday': 'Rabu',
    'khamis': 'Khamis',
    'thursday': 'Khamis',
    'jumaat': 'Jumaat',
    'friday': 'Jumaat',
  };
  return map[key] ?? (value ?? '-');
}
