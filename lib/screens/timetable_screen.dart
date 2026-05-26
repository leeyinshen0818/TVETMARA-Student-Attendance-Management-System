import 'package:flutter/material.dart';

import '../core/constants/timetable_template.dart';
import '../models/app_models.dart';
import '../models/timetable_import_result.dart';
import '../models/timetable_import_write_result.dart';
import '../models/timetable_master_validation_result.dart';
import '../services/timetable_firestore_import_service.dart';
import '../services/timetable_import_service.dart';
import '../services/timetable_file_io.dart';
import '../services/timetable_master_validation_service.dart';
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
  static const _legacyExportColumns = [
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

  TimetableMasterValidationResult? _previewResult;
  String? _previewFileName;
  String? _importError;
  TimetableImportWriteResult? _lastImportResult;
  bool _processingImport = false;
  bool _importing = false;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.currentUser!;
    final canUploadTimetable = user.role == UserRole.ketua_jabatan ||
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
          title: user.role == UserRole.ketua_program
              ? 'Pengurusan Jadual Program'
              : 'Pengurusan Jadual Jabatan',
          subtitle:
              'Muat naik CSV, semak pratonton dan ralat, kemudian import pada fasa seterusnya.',
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
                onPressed:
                    _processingImport ? null : () => _pickAndPreviewFile(state),
                icon: const Icon(Icons.upload_file),
                label: Text(_processingImport ? 'Memproses...' : 'Pilih CSV'),
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
          title: 'Format CSV Jadual',
          subtitle:
              'CSV sahaja. Sediakan jadual dalam Excel jika perlu, kemudian export sebagai CSV sebelum dimuat naik.',
          child: _TemplateHelper(),
        ),
        const SizedBox(height: 16),
        if (_processingImport) ...[
          const AppPanel(
            title: 'Memproses CSV',
            child: LinearProgressIndicator(),
          ),
          const SizedBox(height: 16),
        ],
        if (_importError != null) ...[
          AppPanel(
            title: 'Ralat Fail',
            child: Text(
              _importError!,
              style: const TextStyle(color: Color(0xffb91c1c)),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_previewResult != null) ...[
          _PreviewSummary(result: _previewResult!),
          const SizedBox(height: 16),
          AppPanel(
            title: 'Pratonton CSV',
            subtitle:
                '${_previewResult!.totalRows} baris daripada ${_previewFileName ?? 'fail dipilih'}',
            trailing: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _processingImport ? null : _clearPreview,
                  icon: const Icon(Icons.close),
                  label: const Text('Reset'),
                ),
                FilledButton.icon(
                  onPressed: _canImportPreview
                      ? () => _confirmAndImportPreview(state)
                      : null,
                  icon: _importing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(
                    _importing ? 'Mengimport...' : 'Import Importable Rows',
                  ),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_previewResult!.validationWarnings.isNotEmpty) ...[
                  _MessageList(
                    title: 'Amaran Fail',
                    messages: _previewResult!.validationWarnings,
                    color: const Color(0xff92400e),
                  ),
                  const SizedBox(height: 16),
                ],
                _PreviewTable(rows: _previewResult!.previewRows),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_lastImportResult != null) ...[
          _ImportSuccessPanel(result: _lastImportResult!),
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

  bool get _canImportPreview {
    final result = _previewResult;
    return !_processingImport &&
        !_importing &&
        result != null &&
        result.importableRows > 0;
  }

  void _clearPreview() {
    setState(() {
      _previewResult = null;
      _previewFileName = null;
      _importError = null;
      _lastImportResult = null;
    });
  }

  Future<void> _pickAndPreviewFile(AppState state) async {
    final file = await pickTimetableFile();
    if (file == null) {
      setState(() {
        _importError =
            'Tiada fail dipilih. Pada Android, pemilihan fail belum tersedia dalam fasa ini.';
      });
      return;
    }

    if (!file.name.toLowerCase().endsWith('.csv')) {
      setState(() {
        _previewResult = null;
        _previewFileName = file.name;
        _importError =
            'Hanya fail CSV disokong. Simpan fail Excel sebagai .csv dahulu.';
        _lastImportResult = null;
      });
      return;
    }

    try {
      setState(() {
        _processingImport = true;
        _previewResult = null;
        _previewFileName = file.name;
        _importError = null;
        _lastImportResult = null;
      });
      final parsed =
          const TimetableImportService().parseAndValidate(file.content);
      final preview = await TimetableMasterValidationService(
        FirestoreTimetableMasterDataSource(),
      ).preparePreview(parsed);
      setState(() {
        _previewResult = preview;
        _previewFileName = file.name;
        _importError = preview.validationErrors.isEmpty
            ? null
            : preview.validationErrors.join('\n');
      });
    } catch (e) {
      setState(() {
        _previewResult = null;
        _previewFileName = file.name;
        _importError = e.toString().replaceFirst('Exception: ', '');
        _lastImportResult = null;
      });
    } finally {
      if (mounted) setState(() => _processingImport = false);
    }
  }

  Future<void> _confirmAndImportPreview(AppState state) async {
    final preview = _previewResult;
    final user = state.currentUser;
    if (preview == null) return;
    if (user == null) {
      setState(() => _importError = 'Sesi pengguna tidak dijumpai.');
      return;
    }
    if (preview.importableRows == 0) {
      setState(() => _importError = 'Tiada baris valid untuk diimport.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Jadual CSV'),
        content: Text(
          '${preview.importableRows} baris valid/warning akan diimport. '
          '${preview.duplicateRows} duplicate dan ${preview.errorRows} error akan diskip.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _importing = true;
      _importError = null;
      _lastImportResult = null;
    });

    try {
      final result = await TimetableFirestoreImportService().importPreview(
        preview: preview,
        fileName: _previewFileName ?? 'jadual.csv',
        uploadedBy: user,
      );
      await state.loadData();
      if (!mounted) return;
      setState(() {
        _lastImportResult = result;
        _previewResult = null;
        _previewFileName = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.slotsCreated} slot jadual berjaya diimport.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _importError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  void _downloadTemplate(AppState state) {
    final sampleProgramId = _sampleProgramId(state);
    final sampleLecturer = _sampleLecturer(state, sampleProgramId);
    final sampleRoomName = _sampleRoomName(state, sampleProgramId);
    final rows = [
      TimetableCsvTemplate.fullHeader,
      [
        TimetableCsvTemplate.defaultAcademicSessionId,
        sampleProgramId,
        _sampleSection(state),
        'DED10044',
        'Wiring and Installation Practice',
        '${sampleProgramId}_DED10044',
        sampleLecturer.email,
        sampleLecturer.name,
        _roomIdForTemplate(sampleRoomName),
        sampleRoomName,
        'Isnin',
        '08:00',
        '12:00',
        '1',
        '18',
        'active',
        '',
      ],
    ];

    downloadTextFile(
      filename: 'templat_jadual_ketua.csv',
      content: _toCsv(rows),
    );
  }

  void _exportTimetable(List<TimetableSlot> timetable) {
    final rows = [
      _legacyExportColumns,
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

  String _sampleProgramId(AppState state) {
    final user = state.currentUser;
    if (user?.programId != null) return user!.programId!;
    final departmentProgram = state.programs
        .where((program) => program.departmentId == user?.departmentId)
        .firstOrNull;
    return departmentProgram?.id ?? 'DED';
  }

  String _sampleSection(AppState state) {
    if (state.scopedTimetable.isNotEmpty) {
      return state.scopedTimetable.first.section;
    }
    final user = state.currentUser;
    return '${user?.programId ?? 'DED'} 1A';
  }

  String _sampleRoomName(AppState state, String programId) {
    final preferredNames = switch (programId) {
      'DED' => const [
          'BILIK KULIAH DED 1',
          'ELEC MACHINE LAB',
          'ELEC PRINCPLE LAB',
        ],
      'DGS' => const [
          'SMART CLASSROOM',
          'BK A',
          'BAS LAB',
        ],
      _ => const [
          'BILIK KULIAH DED 1',
          'BK A',
          'SMART CLASSROOM',
        ],
    };
    for (final name in preferredNames) {
      if (state.roomResources.any((room) => room.name == name)) {
        return name;
      }
    }
    if (state.roomResources.isNotEmpty) return state.roomResources.first.name;
    return 'BILIK KULIAH DED 1';
  }

  String _roomIdForTemplate(String roomName) {
    return roomName.replaceAll(RegExp(r'[/\\.]'), '_');
  }

  Lecturer _sampleLecturer(AppState state, String programId) {
    final scopedLecturer = state.lecturers.where((lecturer) {
      final user = state.currentUser;
      if (user?.role == UserRole.ketua_jabatan) {
        return lecturer.department == user!.departmentId;
      }
      return lecturer.id == 'L_${user?.programId}';
    }).firstOrNull;
    if (scopedLecturer != null) return scopedLecturer;
    return Lecturer(
      id: 'L_$programId',
      name: 'Pensyarah $programId',
      email: 'pensyarah_${programId.toLowerCase()}@tvetmara.edu.my',
      department: state.currentUser?.departmentId ?? '',
      subjects: const [],
    );
  }
}

class _TemplateHelper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          TimetableCsvTemplate.fullHeader.join(','),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: Color(0xff334155),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            const _InfoPill('CSV sahaja'),
            const _InfoPill('Excel export sebagai CSV'),
            const _InfoPill('weekStart/weekEnd: 1-18'),
            _InfoPill(
                'dayOfWeek: ${TimetableCsvTemplate.allowedDayOfWeekValues.join(', ')}'),
            const _InfoPill('time: ${TimetableCsvTemplate.expectedTimeFormat}'),
          ],
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        border: Border.all(color: const Color(0xffcbd5e1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xff334155)),
        ),
      ),
    );
  }
}

class _PreviewSummary extends StatelessWidget {
  const _PreviewSummary({required this.result});

  final TimetableMasterValidationResult result;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: 'Ringkasan Pratonton',
      subtitle: result.canImport
          ? 'Baris valid dan warning boleh diimport pada Phase 5.'
          : 'Tiada import dibuat dalam fasa ini.',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _SummaryTile('Total', result.totalRows, const Color(0xff334155)),
          _SummaryTile('Valid', result.validRows, const Color(0xff166534)),
          _SummaryTile('Warning', result.warningRows, const Color(0xff92400e)),
          _SummaryTile(
              'Duplicate', result.duplicateRows, const Color(0xff7c2d12)),
          _SummaryTile('Error', result.errorRows, const Color(0xff991b1b)),
          _SummaryTile(
              'Importable', result.importableRows, const Color(0xff0f766e)),
          _SummaryTile('Subject Draft', result.subjectUpsertDraftsCount,
              const Color(0xff1d4ed8)),
          _SummaryTile('Class Draft', result.classCreateDraftsCount,
              const Color(0xff6d28d9)),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xff475569)),
          ),
        ],
      ),
    );
  }
}

class _PreviewTable extends StatelessWidget {
  const _PreviewTable({required this.rows});

  final List<TimetablePreviewRow> rows;

  @override
  Widget build(BuildContext context) {
    return AppDataTable(
      columns: const [
        DataColumn(label: Text('Row')),
        DataColumn(label: Text('Program')),
        DataColumn(label: Text('Class')),
        DataColumn(label: Text('Kod')),
        DataColumn(label: Text('Subjek')),
        DataColumn(label: Text('Pensyarah')),
        DataColumn(label: Text('Bilik')),
        DataColumn(label: Text('Hari')),
        DataColumn(label: Text('Masa')),
        DataColumn(label: Text('Minggu')),
        DataColumn(label: Text('Result')),
        DataColumn(label: Text('Errors / Warnings')),
      ],
      rows: rows.map((row) {
        final source = row.sourceRow.draft;
        final draft = row.slotDraft;
        return DataRow(cells: [
          DataCell(Text('${row.rowNumber}')),
          DataCell(Text(draft?.programId ?? source?.programId ?? '-')),
          DataCell(Text(draft?.classId ?? source?.classId ?? '-')),
          DataCell(Text(draft?.subjectCode ?? source?.subjectCode ?? '-')),
          DataCell(SizedBox(
            width: 180,
            child: Text(draft?.subjectName ?? source?.subjectName ?? '-'),
          )),
          DataCell(SizedBox(
            width: 160,
            child: Text(draft?.lecturerName ??
                source?.lecturerName ??
                source?.lecturerEmail ??
                '-'),
          )),
          DataCell(SizedBox(
            width: 140,
            child: Text(
                draft?.roomName ?? source?.roomName ?? source?.roomId ?? '-'),
          )),
          DataCell(Text(draft?.dayOfWeek ?? source?.dayOfWeek ?? '-')),
          DataCell(Text(
              '${draft?.startTime ?? source?.startTime ?? '-'}-${draft?.endTime ?? source?.endTime ?? '-'}')),
          DataCell(Text(draft != null
              ? '${draft.weekStart}-${draft.weekEnd}'
              : source != null
                  ? '${source.weekStart}-${source.weekEnd}'
                  : '-')),
          DataCell(_RowStatusChip(row.status)),
          DataCell(SizedBox(
            width: 220,
            child: _RowMessages(
              rowNumber: row.rowNumber,
              errors: row.errors,
              warnings: row.warnings,
            ),
          )),
        ]);
      }).toList(),
    );
  }
}

class _RowStatusChip extends StatelessWidget {
  const _RowStatusChip(this.status);

  final TimetableImportRowStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      TimetableImportRowStatus.valid => ('Valid', const Color(0xff166534)),
      TimetableImportRowStatus.warning => ('Warning', const Color(0xff92400e)),
      TimetableImportRowStatus.duplicate => (
          'Duplicate',
          const Color(0xff7c2d12)
        ),
      TimetableImportRowStatus.error => ('Error', const Color(0xff991b1b)),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RowMessages extends StatelessWidget {
  const _RowMessages({
    required this.rowNumber,
    required this.errors,
    required this.warnings,
  });

  final int rowNumber;
  final List<String> errors;
  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    if (errors.isEmpty && warnings.isEmpty) {
      return const Text('-', style: TextStyle(color: Color(0xff64748b)));
    }

    final color =
        errors.isNotEmpty ? const Color(0xff991b1b) : const Color(0xff92400e);
    final summary = _summaryText();

    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          foregroundColor: color,
          minimumSize: const Size(0, 32),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () => _showDetails(context),
        child: SizedBox(
          width: 210,
          child: Text(
            '$summary\nView details',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  String _summaryText() {
    if (errors.isNotEmpty) {
      final errorLabel =
          errors.length == 1 ? '1 error' : '${errors.length} errors';
      if (warnings.isEmpty) return errorLabel;
      final warningLabel =
          warnings.length == 1 ? '1 warning' : '${warnings.length} warnings';
      return '$errorLabel, $warningLabel';
    }

    final friendlyWarnings = warnings.map(_friendlyMessage).toSet().toList();
    if (friendlyWarnings.length <= 2) {
      return friendlyWarnings.join('; ');
    }
    return '${warnings.length} warnings';
  }

  String _friendlyMessage(String message) {
    if (message.startsWith('subjectId ')) {
      return 'New subject will be created';
    }
    if (message.startsWith('classId ')) {
      return 'New class will be created';
    }
    if (message.startsWith('Academic session ')) {
      return 'Academic session should be checked';
    }
    if (message.startsWith('lecturerName is blank')) {
      return 'Lecturer name will be resolved';
    }
    if (message.startsWith('roomName is blank')) {
      return 'Room name will be resolved';
    }
    return message;
  }

  void _showDetails(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Row $rowNumber Details'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (errors.isNotEmpty)
                  _MessageDetailSection(
                    title: 'Errors',
                    color: const Color(0xff991b1b),
                    messages: errors,
                    friendlyMessage: _friendlyMessage,
                  ),
                if (errors.isNotEmpty && warnings.isNotEmpty)
                  const SizedBox(height: 16),
                if (warnings.isNotEmpty)
                  _MessageDetailSection(
                    title: 'Warnings',
                    color: const Color(0xff92400e),
                    messages: warnings,
                    friendlyMessage: _friendlyMessage,
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _MessageDetailSection extends StatelessWidget {
  const _MessageDetailSection({
    required this.title,
    required this.color,
    required this.messages,
    required this.friendlyMessage,
  });

  final String title;
  final Color color;
  final List<String> messages;
  final String Function(String message) friendlyMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        for (final message in messages) ...[
          Text(
            friendlyMessage(message),
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (friendlyMessage(message) != message) ...[
            const SizedBox(height: 2),
            SelectableText(
              message,
              style: const TextStyle(
                color: Color(0xff475569),
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.title,
    required this.messages,
    required this.color,
  });

  final String title;
  final List<String> messages;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            for (final message in messages)
              Text(message, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _ImportSuccessPanel extends StatelessWidget {
  const _ImportSuccessPanel({required this.result});

  final TimetableImportWriteResult result;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: 'Import Selesai',
      subtitle: 'Upload ID: ${result.uploadId}',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _SummaryTile(
              'Slots Created', result.slotsCreated, const Color(0xff166534)),
          _SummaryTile('Subjects Upserted', result.subjectsUpserted,
              const Color(0xff1d4ed8)),
          _SummaryTile('Classes Created', result.classesCreated,
              const Color(0xff6d28d9)),
          _SummaryTile('Duplicates Skipped', result.duplicatesSkipped,
              const Color(0xff7c2d12)),
          _SummaryTile(
              'Errors Skipped', result.errorsSkipped, const Color(0xff991b1b)),
          _SummaryTile(
              'Total Skipped', result.skippedRows, const Color(0xff475569)),
        ],
      ),
    );
  }
}

class _TimetableTable extends StatelessWidget {
  const _TimetableTable({
    required this.slots,
    this.onEdit,
    this.onDelete,
  });

  final List<TimetableSlot> slots;
  final void Function(TimetableSlot slot)? onEdit;
  final void Function(TimetableSlot slot)? onDelete;

  @override
  Widget build(BuildContext context) {
    return AppDataTable(
      columns: const [
        DataColumn(label: Text('Kod')),
        DataColumn(label: Text('Subjek')),
        DataColumn(label: Text('Kelas')),
        DataColumn(label: Text('Program')),
        DataColumn(label: Text('Sesi')),
        DataColumn(label: Text('Hari')),
        DataColumn(label: Text('Tarikh')),
        DataColumn(label: Text('Masa')),
        DataColumn(label: Text('Bilik')),
        DataColumn(label: Text('Kapasiti')),
        DataColumn(label: Text('Jenis')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Tindakan')),
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
