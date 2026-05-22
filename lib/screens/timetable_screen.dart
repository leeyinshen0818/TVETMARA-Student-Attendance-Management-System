import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/app_models.dart';
import '../services/timetable_file_io.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../widgets/app_layout.dart';
import '../widgets/status_chip.dart';
import 'add_timetable_screen.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  static const _uuid = Uuid();
  static const _columns = [
    'id',
    'session',
    'semester',
    'program',
    'section',
    'subjectCode',
    'subjectName',
    'lecturerId',
    'lecturerName',
    'day',
    'date',
    'startTime',
    'endTime',
    'room',
    'enrolled',
    'capacity',
    'classType',
    'slotType',
    'status',
  ];

  List<TimetableSlot> _previewSlots = [];
  String? _previewFileName;
  String? _importError;
  bool _savingImport = false;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.currentUser!;
    final canUploadTimetable = user.role == UserRole.ketuaJabatan ||
        state.currentKetuaProgramInheritsKetuaJabatanTasks;
    if (!canUploadTimetable) {
      return const PageHeader(
        title: 'Akses Tidak Dibenarkan',
        subtitle:
            'Hanya Ketua Jabatan atau Ketua Program tanpa Ketua Jabatan boleh memuat naik dan mengurus jadual.',
      );
    }

    final timetable = state.scopedTimetable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: user.role == UserRole.ketuaProgram
              ? 'Pengurusan Jadual Program'
              : 'Pengurusan Jadual Jabatan',
          subtitle:
              'Muat naik CSV daripada Excel, semak pratonton, kemas kini slot, dan eksport jadual semasa.',
          trailing: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              StatusChip('${timetable.length} slot'),
              OutlinedButton.icon(
                onPressed: () => _downloadTemplate(state),
                icon: const Icon(Icons.file_download_outlined),
                label: const Text('Muat Turun Templat'),
              ),
              OutlinedButton.icon(
                onPressed: timetable.isEmpty
                    ? null
                    : () => _exportTimetable(timetable),
                icon: const Icon(Icons.ios_share),
                label: const Text('Eksport CSV'),
              ),
              FilledButton.icon(
                onPressed: () => _pickAndPreviewFile(state),
                icon: const Icon(Icons.upload_file),
                label: const Text('Muat Naik'),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddTimetableScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Tambah Manual'),
              ),
            ],
          ),
        ),
        AppPanel(
          title: 'Format Fail Jadual',
          subtitle:
              'Gunakan templat ini untuk jadual Ketua. Fail Excel perlu disimpan sebagai CSV sebelum dimuat naik.',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _columns
                .map((column) => Chip(
                      label: Text(column),
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        if (_importError != null) ...[
          AppPanel(
            title: 'Ralat Import',
            child: Text(
              _importError!,
              style: const TextStyle(color: Color(0xffb91c1c)),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_previewSlots.isNotEmpty) ...[
          AppPanel(
            title: 'Pratonton Import',
            subtitle:
                '${_previewSlots.length} slot daripada ${_previewFileName ?? 'fail dipilih'}',
            trailing: Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _savingImport ? null : _clearPreview,
                  icon: const Icon(Icons.close),
                  label: const Text('Batal'),
                ),
                FilledButton.icon(
                  onPressed: _savingImport ? null : () => _savePreview(state),
                  icon: _savingImport
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_savingImport ? 'Menyimpan...' : 'Simpan Import'),
                ),
              ],
            ),
            child: _TimetableTable(
              slots: _previewSlots,
              preview: true,
            ),
          ),
          const SizedBox(height: 16),
        ],
        AppPanel(
          title: 'Jadual Sesi',
          subtitle: state.session,
          child: _TimetableTable(
            slots: timetable,
            onEdit: (slot) => _showEditDialog(state, slot),
            onDelete: (slot) => _confirmDelete(state, slot),
          ),
        ),
      ],
    );
  }

  void _clearPreview() {
    setState(() {
      _previewSlots = [];
      _previewFileName = null;
      _importError = null;
    });
  }

  Future<void> _pickAndPreviewFile(AppState state) async {
    final file = await pickTimetableFile();
    if (file == null) return;

    try {
      final slots = _parseSlots(file.content, state);
      setState(() {
        _previewSlots = slots;
        _previewFileName = file.name;
        _importError = null;
      });
    } catch (e) {
      setState(() {
        _previewSlots = [];
        _previewFileName = file.name;
        _importError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _savePreview(AppState state) async {
    setState(() => _savingImport = true);
    await state.upsertTimetableSlots(_previewSlots);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_previewSlots.length} slot jadual disimpan.')),
    );
    setState(() {
      _savingImport = false;
      _previewSlots = [];
      _previewFileName = null;
    });
  }

  void _downloadTemplate(AppState state) {
    final sampleProgram = _sampleProgramName(state);
    final sampleLecturer = _sampleLecturer(state, sampleProgram);
    final rows = [
      _columns,
      [
        '',
        state.session,
        state.semester.toString(),
        sampleProgram,
        _sampleSection(state),
        'DED10044',
        'Wiring and Installation Practice',
        sampleLecturer.id,
        sampleLecturer.name,
        'Isnin',
        '2026-05-18',
        '08:00',
        '12:00',
        state.roomResources.isNotEmpty
            ? state.roomResources.first.name
            : 'WIRING BAY 3',
        '25',
        '30',
        'Amali',
        'Kelas Biasa',
        'Upcoming',
      ],
    ];

    downloadTextFile(
      filename: 'templat_jadual_ketua.csv',
      content: _toCsv(rows),
    );
  }

  void _exportTimetable(List<TimetableSlot> timetable) {
    final rows = [
      _columns,
      ...timetable.map((slot) => _slotToRow(slot)),
    ];
    downloadTextFile(
      filename: 'eksport_jadual_${DateTime.now().millisecondsSinceEpoch}.csv',
      content: _toCsv(rows),
    );
  }

  Future<void> _showEditDialog(AppState state, TimetableSlot slot) async {
    final session = TextEditingController(text: slot.session);
    final semester = TextEditingController(text: slot.semester.toString());
    final program = TextEditingController(text: slot.program);
    final section = TextEditingController(text: slot.section);
    final subjectCode = TextEditingController(text: slot.subjectCode);
    final subjectName = TextEditingController(text: slot.subjectName);
    final lecturerId = TextEditingController(text: slot.lecturerId);
    final lecturerName = TextEditingController(text: slot.lecturerName);
    final day = TextEditingController(text: slot.day);
    final date = TextEditingController(text: slot.date);
    final startTime = TextEditingController(text: slot.startTime);
    final endTime = TextEditingController(text: slot.endTime);
    final room = TextEditingController(text: slot.room);
    final enrolled = TextEditingController(text: slot.enrolled.toString());
    final capacity = TextEditingController(text: slot.capacity.toString());
    final classType = TextEditingController(text: slot.classType);
    final slotType = TextEditingController(text: slot.slotType);
    final status = TextEditingController(text: slot.status);

    final saved = await showDialog<TimetableSlot>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Kemas Kini Slot Jadual'),
          content: SizedBox(
            width: 720,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _field(session, 'Sesi'),
                  _field(semester, 'Semester', number: true),
                  _field(program, 'Program'),
                  _field(section, 'Kelas'),
                  _field(subjectCode, 'Kod Kursus'),
                  _field(subjectName, 'Nama Kursus', wide: true),
                  _field(lecturerId, 'ID Pensyarah'),
                  _field(lecturerName, 'Nama Pensyarah'),
                  _field(day, 'Hari'),
                  _field(date, 'Tarikh'),
                  _field(startTime, 'Masa Mula'),
                  _field(endTime, 'Masa Tamat'),
                  _field(room, 'Bilik'),
                  _field(enrolled, 'Pelajar', number: true),
                  _field(capacity, 'Kapasiti', number: true),
                  _field(classType, 'Jenis Kelas'),
                  _field(slotType, 'Jenis Slot'),
                  _field(status, 'Status'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  TimetableSlot(
                    id: slot.id,
                    session: session.text.trim(),
                    semester:
                        int.tryParse(semester.text.trim()) ?? slot.semester,
                    program: program.text.trim(),
                    section: section.text.trim(),
                    subjectCode: subjectCode.text.trim(),
                    subjectName: subjectName.text.trim(),
                    lecturerId: lecturerId.text.trim(),
                    lecturerName: lecturerName.text.trim(),
                    day: day.text.trim(),
                    date: date.text.trim(),
                    startTime: startTime.text.trim(),
                    endTime: endTime.text.trim(),
                    room: room.text.trim(),
                    enrolled:
                        int.tryParse(enrolled.text.trim()) ?? slot.enrolled,
                    capacity:
                        int.tryParse(capacity.text.trim()) ?? slot.capacity,
                    classType: classType.text.trim(),
                    slotType: slotType.text.trim(),
                    status: status.text.trim(),
                  ),
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    for (final controller in [
      session,
      semester,
      program,
      section,
      subjectCode,
      subjectName,
      lecturerId,
      lecturerName,
      day,
      date,
      startTime,
      endTime,
      room,
      enrolled,
      capacity,
      classType,
      slotType,
      status,
    ]) {
      controller.dispose();
    }

    if (saved == null) return;
    await state.upsertTimetableSlot(saved);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Slot jadual dikemas kini.')),
    );
  }

  Future<void> _confirmDelete(AppState state, TimetableSlot slot) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Padam Slot Jadual'),
        content:
            Text('${slot.subjectCode} untuk ${slot.section} akan dipadam.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Padam'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await state.deleteTimetableSlot(slot.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Slot jadual dipadam.')),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool wide = false,
    bool number = false,
  }) {
    return SizedBox(
      width: wide ? 452 : 220,
      child: TextField(
        controller: controller,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  List<TimetableSlot> _parseSlots(String content, AppState state) {
    final rows = _parseCsv(content)
        .where((row) => row.any((cell) => cell.trim().isNotEmpty))
        .toList();
    if (rows.length < 2) {
      throw Exception(
          'Fail mesti mempunyai baris tajuk dan sekurang-kurangnya satu baris jadual.');
    }

    final headers = rows.first.map((cell) => cell.trim()).toList();
    final missing = _columns
        .where((column) => column != 'id' && !headers.contains(column))
        .toList();
    if (missing.isNotEmpty) {
      throw Exception('Kolum wajib tiada: ${missing.join(', ')}.');
    }

    final allowedPrograms = _allowedProgramNames(state);

    return rows.skip(1).map((row) {
      final item = <String, String>{};
      for (var i = 0; i < headers.length; i++) {
        item[headers[i]] = i < row.length ? row[i].trim() : '';
      }
      final program = item['program'] ?? '';
      if (program.isEmpty || !allowedPrograms.contains(program)) {
        throw Exception(
            'Program "$program" tidak berada dalam skop akaun ini.');
      }
      final id = item['id'] ?? '';
      return TimetableSlot(
        id: id.isEmpty ? 'T${_uuid.v4()}' : id,
        session: item['session']!,
        semester: _readInt(item['semester'], 'semester'),
        program: program,
        section: item['section']!,
        subjectCode: item['subjectCode']!,
        subjectName: item['subjectName']!,
        lecturerId: item['lecturerId']!,
        lecturerName: item['lecturerName']!,
        day: item['day']!,
        date: item['date']!,
        startTime: item['startTime']!,
        endTime: item['endTime']!,
        room: item['room']!,
        enrolled: _readInt(item['enrolled'], 'enrolled'),
        capacity: _readInt(item['capacity'], 'capacity'),
        classType: item['classType']!,
        slotType: item['slotType']!,
        status: item['status']!,
      );
    }).toList();
  }

  int _readInt(String? value, String column) {
    final parsed = int.tryParse(value ?? '');
    if (parsed == null) {
      throw Exception('Nilai "$column" mesti nombor.');
    }
    return parsed;
  }

  List<List<String>> _parseCsv(String content) {
    final rows = <List<String>>[];
    final row = <String>[];
    final cell = StringBuffer();
    var quoted = false;

    for (var i = 0; i < content.length; i++) {
      final char = content[i];
      if (char == '"') {
        if (quoted && i + 1 < content.length && content[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          quoted = !quoted;
        }
      } else if (!quoted && (char == ',' || char == ';' || char == '\t')) {
        row.add(cell.toString());
        cell.clear();
      } else if (!quoted && (char == '\n' || char == '\r')) {
        if (char == '\r' && i + 1 < content.length && content[i + 1] == '\n') {
          i++;
        }
        row.add(cell.toString());
        rows.add(List<String>.from(row));
        row.clear();
        cell.clear();
      } else {
        cell.write(char);
      }
    }

    row.add(cell.toString());
    rows.add(List<String>.from(row));
    return rows;
  }

  List<String> _slotToRow(TimetableSlot slot) {
    return [
      slot.id,
      slot.session,
      slot.semester.toString(),
      slot.program,
      slot.section,
      slot.subjectCode,
      slot.subjectName,
      slot.lecturerId,
      slot.lecturerName,
      slot.day,
      slot.date,
      slot.startTime,
      slot.endTime,
      slot.room,
      slot.enrolled.toString(),
      slot.capacity.toString(),
      slot.classType,
      slot.slotType,
      slot.status,
    ];
  }

  String _toCsv(List<List<String>> rows) {
    return rows
        .map((row) => row.map((cell) {
              final escaped = cell.replaceAll('"', '""');
              return '"$escaped"';
            }).join(','))
        .join('\n');
  }

  String _sampleProgramName(AppState state) {
    if (state.scopedTimetable.isNotEmpty) {
      return state.scopedTimetable.first.program;
    }
    final user = state.currentUser;
    if (user?.role == UserRole.ketuaProgram) {
      final program =
          state.programs.where((p) => p.id == user!.program).firstOrNull;
      if (program != null) return program.name;
    }
    final departmentProgram = state.programs
        .where((program) => program.departmentId == user?.department)
        .firstOrNull;
    return departmentProgram?.name ??
        'DIPLOMA TEKNOLOGI KEJURUTERAAN ELEKTRIK (DOMESTIK INDUSTRI) (DED)';
  }

  Set<String> _allowedProgramNames(AppState state) {
    final user = state.currentUser;
    if (user?.role == UserRole.ketuaProgram) {
      final program =
          state.programs.where((p) => p.id == user!.program).firstOrNull;
      if (program != null) return {program.name};
    }
    if (user?.role == UserRole.ketuaJabatan) {
      return state.programs
          .where((program) => program.departmentId == user!.department)
          .map((program) => program.name)
          .toSet();
    }
    return state.scopedTimetable.map((slot) => slot.program).toSet();
  }

  String _sampleSection(AppState state) {
    if (state.scopedTimetable.isNotEmpty) {
      return state.scopedTimetable.first.section;
    }
    final user = state.currentUser;
    return '${user?.program ?? 'DED'} 1A';
  }

  Lecturer _sampleLecturer(AppState state, String program) {
    final scopedLecturer = state.lecturers.where((lecturer) {
      final user = state.currentUser;
      if (user?.role == UserRole.ketuaJabatan) {
        return lecturer.department == user!.department;
      }
      return lecturer.id == 'L_${user?.program}';
    }).firstOrNull;
    if (scopedLecturer != null) return scopedLecturer;
    return Lecturer(
      id: 'L_${state.currentUser?.program ?? 'DED'}',
      name: 'Pensyarah $program',
      email: '',
      department: state.currentUser?.department ?? '',
      subjects: const [],
    );
  }
}

class _TimetableTable extends StatelessWidget {
  const _TimetableTable({
    required this.slots,
    this.onEdit,
    this.onDelete,
    this.preview = false,
  });

  final List<TimetableSlot> slots;
  final void Function(TimetableSlot slot)? onEdit;
  final void Function(TimetableSlot slot)? onDelete;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    return AppDataTable(
      columns: [
        const DataColumn(label: Text('Kod')),
        const DataColumn(label: Text('Subjek')),
        const DataColumn(label: Text('Kelas')),
        const DataColumn(label: Text('Program')),
        const DataColumn(label: Text('Sesi')),
        const DataColumn(label: Text('Hari')),
        const DataColumn(label: Text('Tarikh')),
        const DataColumn(label: Text('Masa')),
        const DataColumn(label: Text('Bilik')),
        const DataColumn(label: Text('Kapasiti')),
        const DataColumn(label: Text('Jenis')),
        const DataColumn(label: Text('Status')),
        if (!preview) const DataColumn(label: Text('Tindakan')),
      ],
      rows: slots.map((slot) {
        return DataRow(cells: [
          DataCell(Text(slot.subjectCode)),
          DataCell(Text(slot.subjectName)),
          DataCell(Text(slot.section)),
          DataCell(Text(slot.program)),
          DataCell(Text(slot.session)),
          DataCell(Text(slot.day)),
          DataCell(Text(slot.date)),
          DataCell(Text('${slot.startTime}-${slot.endTime}')),
          DataCell(Text(slot.room)),
          DataCell(Text('${slot.enrolled}/${slot.capacity}')),
          DataCell(StatusChip(slot.slotType)),
          DataCell(StatusChip(slot.status)),
          if (!preview)
            DataCell(Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Kemas kini',
                  onPressed: onEdit == null ? null : () => onEdit!(slot),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Padam',
                  onPressed: onDelete == null ? null : () => onDelete!(slot),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            )),
        ]);
      }).toList(),
    );
  }
}
