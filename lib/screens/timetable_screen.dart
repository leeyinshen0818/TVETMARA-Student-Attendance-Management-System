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
  bool _batchProcessing = false;
  int _selectedSection = 0;
  final _searchCtrl = TextEditingController();
  final Set<String> _selectedSlotKeys = <String>{};
  String? _dayFilter;
  String? _statusFilter;
  String? _programFilter;
  String? _classFilter;
  String? _lecturerFilter;
  String? _roomFilter;
  String? _academicSessionFilter;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

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
    final sessionOptions = _academicSessionOptions(state, timetable);
    final selectedSession = _activeAcademicSession(state);
    final filteredTimetable = _filteredTimetable(timetable, selectedSession);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: user.role == UserRole.ketua_program
              ? 'Pengurusan Jadual Program'
              : 'Pengurusan Jadual Jabatan',
          subtitle:
              'Urus jadual rasmi, muat naik jadual CSV, dan semak rekod import mengikut skop pengguna.',
          trailing: StatusChip('${timetable.length} Slot Jadual'),
        ),
        _ScopeSummary(
          state: state,
          slotCount: timetable.length,
          selectedAcademicSession: selectedSession,
          academicSessionOptions: sessionOptions,
          onAcademicSessionChanged: (value) {
            if (value == null) return;
            _updateFilters(() => _academicSessionFilter = value);
          },
        ),
        const SizedBox(height: 12),
        _HeaderActionBar(
          hasTimetable: filteredTimetable.isNotEmpty,
          onUpload: () => setState(() => _selectedSection = 1),
          onDownloadTemplate: () => _downloadTemplate(state),
          onExport: () => _exportTimetable(filteredTimetable),
          onAddManual: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddTimetableScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _SectionTabs(
          selectedIndex: _selectedSection,
          onChanged: (index) => setState(() => _selectedSection = index),
        ),
        const SizedBox(height: 16),
        if (_selectedSection == 0)
          _OfficialTimetableSection(
            state: state,
            slots: filteredTimetable,
            allSlots: timetable,
            searchCtrl: _searchCtrl,
            dayFilter: _dayFilter,
            statusFilter: _statusFilter,
            programFilter: _programFilter,
            classFilter: _classFilter,
            lecturerFilter: _lecturerFilter,
            roomFilter: _roomFilter,
            selectedSlotKeys: _selectedSlotKeys,
            batchProcessing: _batchProcessing,
            onSearchChanged: (_) => _updateFilters(() {}),
            onDayChanged: (value) => _updateFilters(() => _dayFilter = value),
            onStatusChanged: (value) =>
                _updateFilters(() => _statusFilter = value),
            onProgramChanged: (value) =>
                _updateFilters(() => _programFilter = value),
            onClassChanged: (value) =>
                _updateFilters(() => _classFilter = value),
            onLecturerChanged: (value) =>
                _updateFilters(() => _lecturerFilter = value),
            onRoomChanged: (value) => _updateFilters(() => _roomFilter = value),
            onResetFilters: _resetFilters,
            onToggleSelectAllVisible: () =>
                _toggleSelectAllVisible(filteredTimetable),
            onClearSelection: _clearSelection,
            onExportSelected: () => _exportSelected(filteredTimetable),
            onBatchInactive: () =>
                _confirmBatchInactive(state, filteredTimetable),
            onBatchDelete: () => _confirmBatchDelete(state, filteredTimetable),
            onSelectionChanged: _setSlotSelection,
            onDetails: (slot) => _showSlotDetails(state, slot),
            onEdit: (slot) => _showEditDialog(state, slot),
            onDelete: (slot) => _confirmDelete(state, slot),
          )
        else if (_selectedSection == 1)
          _UploadWorkflowSection(
            processingImport: _processingImport,
            importError: _importError,
            previewResult: _previewResult,
            previewFileName: _previewFileName,
            lastImportResult: _lastImportResult,
            importing: _importing,
            canImportPreview: _canImportPreview,
            onPickFile: () => _pickAndPreviewFile(state),
            onDownloadTemplate: () => _downloadTemplate(state),
            onClearPreview: _clearPreview,
            onImportPreview: () => _confirmAndImportPreview(state),
            onViewOfficialTimetable: () => setState(() => _selectedSection = 0),
          )
        else
          _ImportHistorySection(
            records: _filteredUploadHistory(state),
            scopedSlots: timetable,
            onUpload: () => setState(() => _selectedSection = 1),
          ),
      ],
    );
  }

  void _updateFilters(VoidCallback update) {
    setState(() {
      update();
      _selectedSlotKeys.clear();
    });
  }

  List<TimetableSlot> _filteredTimetable(
    List<TimetableSlot> slots,
    String selectedSession,
  ) {
    final query = _searchCtrl.text.trim().toLowerCase();
    return slots.where((slot) {
      if (query.isNotEmpty) {
        final haystack = [
          slot.subjectCode,
          slot.subjectName,
          slot.lecturerName,
          slot.room,
          slot.roomName ?? '',
          slot.section,
          slot.classId ?? '',
          slot.program,
          slot.programId ?? '',
        ].join(' ').toLowerCase();
        if (!haystack.contains(query)) return false;
      }
      if (slot.session != selectedSession) {
        return false;
      }
      if (_dayFilter != null && slot.day != _dayFilter) return false;
      if (_statusFilter != null && slot.status != _statusFilter) return false;
      if (_programFilter != null && slot.program != _programFilter) {
        return false;
      }
      if (_classFilter != null && slot.section != _classFilter) return false;
      if (_lecturerFilter != null && slot.lecturerName != _lecturerFilter) {
        return false;
      }
      if (_roomFilter != null && slot.room != _roomFilter) return false;
      return true;
    }).toList();
  }

  void _resetFilters() {
    setState(() {
      _searchCtrl.clear();
      _dayFilter = null;
      _statusFilter = null;
      _programFilter = null;
      _classFilter = null;
      _lecturerFilter = null;
      _roomFilter = null;
      _academicSessionFilter = null;
      _selectedSlotKeys.clear();
    });
  }

  String _activeAcademicSession(AppState state) {
    return _academicSessionFilter ?? state.session;
  }

  List<String> _academicSessionOptions(
    AppState state,
    List<TimetableSlot> timetable,
  ) {
    final values = <String>{
      state.session,
      ...state.academicSessions.map((session) => session.academicSessionId),
      ...timetable.map((slot) => slot.session),
    }..removeWhere((value) => value.trim().isEmpty);
    final sorted = values.toList()..sort();
    if (sorted.remove(state.session)) sorted.insert(0, state.session);
    return sorted;
  }

  List<TimetableUploadRecord> _filteredUploadHistory(AppState state) {
    final selectedSession = _activeAcademicSession(state);
    return state.timetableUploads
        .where((record) =>
            record.academicSessionId == selectedSession ||
            record.academicSessionId == 'mixed' ||
            record.academicSessionId == 'unknown')
        .toList();
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
      setState(() => _importError = 'Tiada baris layak untuk diimport.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import baris jadual yang layak?'),
        content: Text(
          '${preview.importableRows} baris akan diimport. '
          '${preview.warningRows} baris mempunyai amaran tidak menghalang. '
          '${preview.duplicateRows} pendua dan ${preview.errorRows} ralat akan dilangkau.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import Baris Layak'),
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
      await state.refreshTimetableData();
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

  void _exportTimetable(
    List<TimetableSlot> timetable, {
    String? filename,
  }) {
    final rows = [
      _legacyExportColumns,
      ...timetable.map((slot) => _slotToRow(slot)),
    ];
    downloadTextFile(
      filename: filename ??
          'eksport_jadual_${DateTime.now().millisecondsSinceEpoch}.csv',
      content: _toCsv(rows),
    );
  }

  void _exportSelected(List<TimetableSlot> visibleSlots) {
    final selected = _selectedVisibleSlots(visibleSlots);
    if (selected.isEmpty) return;
    _exportTimetable(
      selected,
      filename: 'jadual_selected_${_dateStamp()}.csv',
    );
  }

  Future<void> _confirmBatchInactive(
    AppState state,
    List<TimetableSlot> visibleSlots,
  ) async {
    final selected = _selectedVisibleSlots(visibleSlots);
    if (selected.isEmpty || _batchProcessing) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nyahaktifkan Slot Jadual?'),
        content: Text(
          'Tindakan ini akan menetapkan ${selected.length} slot jadual sebagai Tidak Aktif. Slot ini tidak akan dipadam.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Nyahaktifkan'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _batchProcessing = true);
    try {
      await state.updateTimetableSlotsStatus(
        selected.map((slot) => slot.id).toList(),
        'inactive',
      );
      await state.refreshTimetableData();
      if (!mounted) return;
      setState(() => _selectedSlotKeys.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${selected.length} slot jadual dinyahaktifkan.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menyahaktifkan slot jadual: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _batchProcessing = false);
    }
  }

  Future<void> _confirmBatchDelete(
    AppState state,
    List<TimetableSlot> visibleSlots,
  ) async {
    final selected = _selectedVisibleSlots(visibleSlots);
    if (selected.isEmpty || _batchProcessing) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Padam Slot Jadual Dipilih?'),
        content: Text(
          'Tindakan ini akan memadam ${selected.length} slot jadual daripada rekod rasmi. Tindakan ini tidak boleh dibuat asal.',
        ),
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
    if (confirmed != true) return;

    setState(() => _batchProcessing = true);
    try {
      await state
          .deleteTimetableSlots(selected.map((slot) => slot.id).toList());
      await state.refreshTimetableData();
      if (!mounted) return;
      setState(() => _selectedSlotKeys.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selected.length} slot jadual dipadam.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memadam slot jadual: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _batchProcessing = false);
    }
  }

  void _toggleSelectAllVisible(List<TimetableSlot> visibleSlots) {
    if (visibleSlots.isEmpty || _batchProcessing) return;
    final visibleKeys = visibleSlots.map(_slotSelectionKey).toSet();
    final allVisibleSelected =
        visibleKeys.every((key) => _selectedSlotKeys.contains(key));
    setState(() {
      if (allVisibleSelected) {
        _selectedSlotKeys.removeAll(visibleKeys);
      } else {
        _selectedSlotKeys.addAll(visibleKeys);
      }
    });
  }

  void _setSlotSelection(TimetableSlot slot, bool selected) {
    final key = _slotSelectionKey(slot);
    setState(() {
      if (selected) {
        _selectedSlotKeys.add(key);
      } else {
        _selectedSlotKeys.remove(key);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedSlotKeys.clear());
  }

  List<TimetableSlot> _selectedVisibleSlots(List<TimetableSlot> visibleSlots) {
    return visibleSlots
        .where((slot) => _selectedSlotKeys.contains(_slotSelectionKey(slot)))
        .toList();
  }

  String _dateStamp() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _ManagementNote(),
                  const SizedBox(height: 14),
                  Wrap(
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
                    timetableSlotId: slot.timetableSlotId,
                    academicSessionId: slot.academicSessionId,
                    programId: slot.programId,
                    departmentId: slot.departmentId,
                    classId: slot.classId,
                    subjectId: slot.subjectId,
                    session: session.text.trim(),
                    semester:
                        int.tryParse(semester.text.trim()) ?? slot.semester,
                    program: program.text.trim(),
                    section: section.text.trim(),
                    subjectCode: subjectCode.text.trim(),
                    subjectName: subjectName.text.trim(),
                    lecturerId: lecturerId.text.trim(),
                    lecturerName: lecturerName.text.trim(),
                    roomId: slot.roomId,
                    roomName: slot.roomName,
                    day: day.text.trim(),
                    date: date.text.trim(),
                    dayOfWeek: slot.dayOfWeek,
                    startTime: startTime.text.trim(),
                    endTime: endTime.text.trim(),
                    weekStart: slot.weekStart,
                    weekEnd: slot.weekEnd,
                    room: room.text.trim(),
                    enrolled:
                        int.tryParse(enrolled.text.trim()) ?? slot.enrolled,
                    capacity:
                        int.tryParse(capacity.text.trim()) ?? slot.capacity,
                    classType: classType.text.trim(),
                    slotType: slotType.text.trim(),
                    status: status.text.trim(),
                    sourceUploadId: slot.sourceUploadId,
                    createdBy: slot.createdBy,
                    createdAt: slot.createdAt,
                    updatedAt: slot.updatedAt,
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
        title: const Text('Padam Slot Jadual?'),
        content: Text(
          'Tindakan ini akan memadam slot jadual ${slot.subjectCode} untuk ${slot.section} daripada rekod rasmi. Tindakan ini tidak boleh dibuat asal.',
        ),
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

  Future<void> _showSlotDetails(AppState state, TimetableSlot slot) async {
    final programName = state.programs
            .where((program) => program.id == slot.programId)
            .firstOrNull
            ?.name ??
        slot.program;
    final source = slot.sourceUploadId == null || slot.sourceUploadId!.isEmpty
        ? 'Tambah/Edit manual'
        : 'Import CSV';

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Butiran Jadual'),
        content: SizedBox(
          width: 680,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailSection(
                  title: 'Maklumat Jadual',
                  rows: [
                    ('Kod kursus', slot.subjectCode),
                    ('Nama subjek', slot.subjectName),
                    (
                      'Program',
                      '${_shortProgramLabel(programName)} - $programName'
                    ),
                    ('Kelas', slot.section),
                    ('Pensyarah', slot.lecturerName),
                    ('Hari', slot.day),
                    ('Masa', '${slot.startTime}-${slot.endTime}'),
                    ('Bilik', slot.room),
                    ('Minggu', _weekTextForSlot(slot)),
                    ('Status', _statusLabel(slot.status)),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailSection(
                  title: 'Maklumat Teknikal',
                  rows: [
                    ('timetableSlotId', slot.timetableSlotId),
                    ('academicSessionId', slot.academicSessionId ?? '-'),
                    ('programId', slot.programId ?? '-'),
                    ('departmentId', slot.departmentId ?? '-'),
                    ('classId', slot.classId ?? '-'),
                    ('subjectId', slot.subjectId ?? '-'),
                    ('lecturerId', slot.lecturerId),
                    ('roomId', slot.roomId ?? '-'),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailSection(
                  title: 'Audit Rekod',
                  rows: [
                    ('Sumber', source),
                    ('sourceUploadId', slot.sourceUploadId ?? '-'),
                    ('createdBy', slot.createdBy ?? '-'),
                    ('createdAt', slot.createdAt ?? '-'),
                    ('updatedAt', slot.updatedAt ?? '-'),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
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

class _ScopeSummary extends StatelessWidget {
  const _ScopeSummary({
    required this.state,
    required this.slotCount,
    required this.selectedAcademicSession,
    required this.academicSessionOptions,
    required this.onAcademicSessionChanged,
  });

  final AppState state;
  final int slotCount;
  final String selectedAcademicSession;
  final List<String> academicSessionOptions;
  final ValueChanged<String?> onAcademicSessionChanged;

  @override
  Widget build(BuildContext context) {
    final user = state.currentUser!;
    final isProgramScope = user.role == UserRole.ketua_program;
    final scopeName = isProgramScope
        ? state.programs
                .where((program) => program.id == user.programId)
                .firstOrNull
                ?.name ??
            user.programId ??
            'Program'
        : state.departments
                .where((department) => department.id == user.departmentId)
                .firstOrNull
                ?.name ??
            user.departmentId ??
            'Jabatan';
    final notice = isProgramScope
        ? 'Program ini tidak mempunyai Ketua Jabatan. Ketua Program mengurus jadual program ini.'
        : 'Anda sedang melihat jadual bagi program di bawah jabatan ini.';

    return AppPanel(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _ContextTile(
            icon: Icons.account_tree_outlined,
            label: 'Skop',
            value:
                isProgramScope ? 'Program: $scopeName' : 'Jabatan: $scopeName',
          ),
          SizedBox(
            width: 240,
            child: DropdownButtonFormField<String>(
              initialValue: selectedAcademicSession,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Sesi Akademik',
                border: OutlineInputBorder(),
                isDense: true,
                prefixIcon: Icon(Icons.event_note_outlined),
              ),
              items: academicSessionOptions
                  .map(
                    (session) => DropdownMenuItem<String>(
                      value: session,
                      child: Text(
                        session,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onAcademicSessionChanged,
            ),
          ),
          _ContextTile(
            icon: Icons.calendar_view_week_outlined,
            label: 'Jumlah Rekod Jadual',
            value: '$slotCount rekod',
          ),
          SizedBox(
            width: 360,
            child: Text(
              notice,
              style: const TextStyle(
                color: Color(0xff475569),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextTile extends StatelessWidget {
  const _ContextTile({
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
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        border: Border.all(color: const Color(0xffe2e8f0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xff1d4ed8)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xff64748b),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff0f172a),
                    fontSize: 13,
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

class _HeaderActionBar extends StatelessWidget {
  const _HeaderActionBar({
    required this.hasTimetable,
    required this.onUpload,
    required this.onDownloadTemplate,
    required this.onExport,
    required this.onAddManual,
  });

  final bool hasTimetable;
  final VoidCallback onUpload;
  final VoidCallback onDownloadTemplate;
  final VoidCallback onExport;
  final VoidCallback onAddManual;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xffffffff),
        border: Border.all(color: const Color(0xffe2e8f0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.upload_file),
              label: const Text('Muat Naik CSV'),
            ),
            OutlinedButton.icon(
              onPressed: onDownloadTemplate,
              icon: const Icon(Icons.file_download_outlined),
              label: const Text('Muat Turun Templat'),
            ),
            Tooltip(
              message:
                  'Mengeksport jadual yang sedang dipaparkan berdasarkan penapis semasa.',
              child: OutlinedButton.icon(
                onPressed: hasTimetable ? onExport : null,
                icon: const Icon(Icons.ios_share),
                label: const Text('Eksport Paparan Semasa'),
              ),
            ),
            OutlinedButton.icon(
              onPressed: onAddManual,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Manual'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagementNote extends StatelessWidget {
  const _ManagementNote();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xfffffbeb),
        border: Border.all(color: const Color(0xfffde68a)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: Color(0xff92400e), size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tambah manual sesuai untuk pembetulan kecil. Untuk jadual penuh, gunakan Muat Naik CSV.',
                style: TextStyle(color: Color(0xff92400e), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTabs extends StatelessWidget {
  const _SectionTabs({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.table_chart_outlined, 'Jadual Rasmi'),
      (Icons.upload_file_outlined, 'Muat Naik Jadual'),
      (Icons.history_outlined, 'Sejarah Import'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < items.length; i++)
          ChoiceChip(
            avatar: Icon(items[i].$1, size: 18),
            label: Text(items[i].$2),
            selected: selectedIndex == i,
            onSelected: (_) => onChanged(i),
            labelStyle: TextStyle(
              fontWeight: FontWeight.w800,
              color: selectedIndex == i
                  ? const Color(0xff0f172a)
                  : const Color(0xff475569),
            ),
          ),
      ],
    );
  }
}

class _OfficialTimetableSection extends StatelessWidget {
  const _OfficialTimetableSection({
    required this.state,
    required this.slots,
    required this.allSlots,
    required this.searchCtrl,
    required this.dayFilter,
    required this.statusFilter,
    required this.programFilter,
    required this.classFilter,
    required this.lecturerFilter,
    required this.roomFilter,
    required this.selectedSlotKeys,
    required this.batchProcessing,
    required this.onSearchChanged,
    required this.onDayChanged,
    required this.onStatusChanged,
    required this.onProgramChanged,
    required this.onClassChanged,
    required this.onLecturerChanged,
    required this.onRoomChanged,
    required this.onResetFilters,
    required this.onToggleSelectAllVisible,
    required this.onClearSelection,
    required this.onExportSelected,
    required this.onBatchInactive,
    required this.onBatchDelete,
    required this.onSelectionChanged,
    required this.onDetails,
    required this.onEdit,
    required this.onDelete,
  });

  final AppState state;
  final List<TimetableSlot> slots;
  final List<TimetableSlot> allSlots;
  final TextEditingController searchCtrl;
  final String? dayFilter;
  final String? statusFilter;
  final String? programFilter;
  final String? classFilter;
  final String? lecturerFilter;
  final String? roomFilter;
  final Set<String> selectedSlotKeys;
  final bool batchProcessing;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onDayChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onProgramChanged;
  final ValueChanged<String?> onClassChanged;
  final ValueChanged<String?> onLecturerChanged;
  final ValueChanged<String?> onRoomChanged;
  final VoidCallback onResetFilters;
  final VoidCallback onToggleSelectAllVisible;
  final VoidCallback onClearSelection;
  final VoidCallback onExportSelected;
  final VoidCallback onBatchInactive;
  final VoidCallback onBatchDelete;
  final void Function(TimetableSlot slot, bool selected) onSelectionChanged;
  final void Function(TimetableSlot slot) onDetails;
  final void Function(TimetableSlot slot) onEdit;
  final void Function(TimetableSlot slot) onDelete;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: 'Jadual Rasmi',
      subtitle:
          '${slots.length} daripada ${allSlots.length} slot dipaparkan untuk ${state.session}.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TimetableFilters(
            slots: allSlots,
            searchCtrl: searchCtrl,
            dayFilter: dayFilter,
            statusFilter: statusFilter,
            programFilter: programFilter,
            classFilter: classFilter,
            lecturerFilter: lecturerFilter,
            roomFilter: roomFilter,
            onSearchChanged: onSearchChanged,
            onDayChanged: onDayChanged,
            onStatusChanged: onStatusChanged,
            onProgramChanged: onProgramChanged,
            onClassChanged: onClassChanged,
            onLecturerChanged: onLecturerChanged,
            onRoomChanged: onRoomChanged,
            onResetFilters: onResetFilters,
          ),
          const SizedBox(height: 16),
          _CoverageSummary(slots: slots),
          const SizedBox(height: 16),
          _ConflictReviewPanel(slots: slots),
          const SizedBox(height: 16),
          if (slots.isNotEmpty) ...[
            _SelectionToolbar(
              visibleCount: slots.length,
              selectedCount: _selectedVisibleCount(slots, selectedSlotKeys),
              allVisibleSelected: _allVisibleSelected(slots, selectedSlotKeys),
              batchProcessing: batchProcessing,
              onToggleSelectAllVisible: onToggleSelectAllVisible,
              onClearSelection: onClearSelection,
            ),
            const SizedBox(height: 10),
          ],
          if (_selectedVisibleCount(slots, selectedSlotKeys) > 0) ...[
            _BatchActionBar(
              selectedCount: _selectedVisibleCount(slots, selectedSlotKeys),
              batchProcessing: batchProcessing,
              onExportSelected: onExportSelected,
              onBatchInactive: onBatchInactive,
              onBatchDelete: onBatchDelete,
              onClearSelection: onClearSelection,
            ),
            const SizedBox(height: 12),
          ],
          _TimetableTable(
            slots: slots,
            selectedSlotKeys: selectedSlotKeys,
            batchProcessing: batchProcessing,
            onSelectionChanged: onSelectionChanged,
            onDetails: onDetails,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }
}

int _selectedVisibleCount(
  List<TimetableSlot> slots,
  Set<String> selectedSlotKeys,
) {
  return slots
      .where((slot) => selectedSlotKeys.contains(_slotSelectionKey(slot)))
      .length;
}

bool _allVisibleSelected(
  List<TimetableSlot> slots,
  Set<String> selectedSlotKeys,
) {
  if (slots.isEmpty) return false;
  return slots
      .every((slot) => selectedSlotKeys.contains(_slotSelectionKey(slot)));
}

class _SelectionToolbar extends StatelessWidget {
  const _SelectionToolbar({
    required this.visibleCount,
    required this.selectedCount,
    required this.allVisibleSelected,
    required this.batchProcessing,
    required this.onToggleSelectAllVisible,
    required this.onClearSelection,
  });

  final int visibleCount;
  final int selectedCount;
  final bool allVisibleSelected;
  final bool batchProcessing;
  final VoidCallback onToggleSelectAllVisible;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Tooltip(
          message: 'Pilih semua slot yang sedang dipaparkan',
          child: OutlinedButton.icon(
            onPressed: batchProcessing ? null : onToggleSelectAllVisible,
            icon: Icon(allVisibleSelected
                ? Icons.check_box
                : Icons.check_box_outline_blank),
            label: Text(
              allVisibleSelected ? 'Kosongkan Paparan' : 'Pilih Semua Paparan',
            ),
          ),
        ),
        Text(
          selectedCount == 0
              ? '$visibleCount slot dipaparkan'
              : '$selectedCount daripada $visibleCount slot dipilih',
          style: const TextStyle(
            color: Color(0xff475569),
            fontWeight: FontWeight.w700,
          ),
        ),
        if (selectedCount > 0)
          TextButton.icon(
            onPressed: batchProcessing ? null : onClearSelection,
            icon: const Icon(Icons.close),
            label: const Text('Batal Pilihan'),
          ),
      ],
    );
  }
}

class _BatchActionBar extends StatelessWidget {
  const _BatchActionBar({
    required this.selectedCount,
    required this.batchProcessing,
    required this.onExportSelected,
    required this.onBatchInactive,
    required this.onBatchDelete,
    required this.onClearSelection,
  });

  final int selectedCount;
  final bool batchProcessing;
  final VoidCallback onExportSelected;
  final VoidCallback onBatchInactive;
  final VoidCallback onBatchDelete;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xffeff6ff),
        border: Border.all(color: const Color(0xffbfdbfe)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusChip('$selectedCount slot dipilih'),
            Tooltip(
              message: 'Export slot dipilih',
              child: OutlinedButton.icon(
                onPressed: batchProcessing ? null : onExportSelected,
                icon: const Icon(Icons.download_outlined),
                label: const Text('Export Dipilih'),
              ),
            ),
            Tooltip(
              message: 'Nyahaktifkan slot dipilih',
              child: OutlinedButton.icon(
                onPressed: batchProcessing ? null : onBatchInactive,
                icon: batchProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.visibility_off_outlined),
                label: const Text('Nyahaktifkan'),
              ),
            ),
            Tooltip(
              message: 'Padam slot dipilih',
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xffb91c1c),
                ),
                onPressed: batchProcessing ? null : onBatchDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Padam'),
              ),
            ),
            TextButton.icon(
              onPressed: batchProcessing ? null : onClearSelection,
              icon: const Icon(Icons.close),
              label: const Text('Batal Pilihan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimetableFilters extends StatelessWidget {
  const _TimetableFilters({
    required this.slots,
    required this.searchCtrl,
    required this.dayFilter,
    required this.statusFilter,
    required this.programFilter,
    required this.classFilter,
    required this.lecturerFilter,
    required this.roomFilter,
    required this.onSearchChanged,
    required this.onDayChanged,
    required this.onStatusChanged,
    required this.onProgramChanged,
    required this.onClassChanged,
    required this.onLecturerChanged,
    required this.onRoomChanged,
    required this.onResetFilters,
  });

  final List<TimetableSlot> slots;
  final TextEditingController searchCtrl;
  final String? dayFilter;
  final String? statusFilter;
  final String? programFilter;
  final String? classFilter;
  final String? lecturerFilter;
  final String? roomFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onDayChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onProgramChanged;
  final ValueChanged<String?> onClassChanged;
  final ValueChanged<String?> onLecturerChanged;
  final ValueChanged<String?> onRoomChanged;
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    final days = _distinct(slots.map((slot) => slot.day));
    final statuses = _distinct(slots.map((slot) => slot.status));
    final programs = _distinct(slots.map((slot) => slot.program));
    final classes = _distinct(slots.map((slot) => slot.section));
    final lecturers = _distinct(slots.map((slot) => slot.lecturerName));
    final rooms = _distinct(slots.map((slot) => slot.room));

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth - 24;
        final isNarrow = available < 560;
        final isMedium = available >= 560 && available < 920;
        final fieldWidth = isNarrow
            ? available
            : isMedium
                ? (available - 10) / 2
                : (available - 40) / 5;
        final searchWidth = isNarrow
            ? available
            : isMedium
                ? available
                : (fieldWidth * 1.35).clamp(280.0, 380.0);

        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xfff8fafc),
            border: Border.all(color: const Color(0xffe2e8f0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: searchWidth,
                  child: TextField(
                    controller: searchCtrl,
                    onChanged: onSearchChanged,
                    decoration: const InputDecoration(
                      labelText: 'Cari jadual',
                      hintText: 'Kod, subjek, pensyarah, bilik atau kelas',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                _FilterDropdown(
                  label: 'Program',
                  value: programFilter,
                  values: programs,
                  width: fieldWidth,
                  labelForValue: _shortProgramLabel,
                  onChanged: onProgramChanged,
                ),
                _FilterDropdown(
                  label: 'Kelas',
                  value: classFilter,
                  values: classes,
                  width: fieldWidth,
                  onChanged: onClassChanged,
                ),
                _FilterDropdown(
                  label: 'Pensyarah',
                  value: lecturerFilter,
                  values: lecturers,
                  width: fieldWidth,
                  onChanged: onLecturerChanged,
                ),
                _FilterDropdown(
                  label: 'Bilik',
                  value: roomFilter,
                  values: rooms,
                  width: fieldWidth,
                  onChanged: onRoomChanged,
                ),
                _FilterDropdown(
                  label: 'Hari',
                  value: dayFilter,
                  values: days,
                  width: fieldWidth,
                  onChanged: onDayChanged,
                ),
                _FilterDropdown(
                  label: 'Status',
                  value: statusFilter,
                  values: statuses,
                  width: fieldWidth,
                  labelForValue: _statusLabel,
                  onChanged: onStatusChanged,
                ),
                SizedBox(
                  width: isNarrow ? available : fieldWidth,
                  child: OutlinedButton.icon(
                    onPressed: onResetFilters,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset Penapis'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<String> _distinct(Iterable<String> values) {
    final result = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return result;
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.width,
    required this.onChanged,
    this.labelForValue,
  });

  final String label;
  final String? value;
  final List<String> values;
  final double width;
  final ValueChanged<String?> onChanged;
  final String Function(String value)? labelForValue;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String?>(
        key: ValueKey('$label-${value ?? 'all'}-${values.length}'),
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        selectedItemBuilder: (context) {
          return [
            const Text(
              'Semua',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            ...values.map(
              (item) => Text(
                labelForValue?.call(item) ?? item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ];
        },
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text(
              'Semua',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ...values.map(
            (item) => DropdownMenuItem<String?>(
              value: item,
              child: Text(
                labelForValue?.call(item) ?? item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _CoverageSummary extends StatelessWidget {
  const _CoverageSummary({required this.slots});

  final List<TimetableSlot> slots;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _CoverageTile(
          label: 'Program',
          value: _count(slots.map((slot) => slot.program)),
          icon: Icons.school_outlined,
        ),
        _CoverageTile(
          label: 'Kelas',
          value: _count(slots.map((slot) => slot.section)),
          icon: Icons.groups_outlined,
        ),
        _CoverageTile(
          label: 'Pensyarah',
          value: _count(slots.map((slot) => slot.lecturerName)),
          icon: Icons.person_outline,
        ),
        _CoverageTile(
          label: 'Bilik',
          value: _count(slots.map((slot) => slot.room)),
          icon: Icons.meeting_room_outlined,
        ),
      ],
    );
  }

  int _count(Iterable<String> values) {
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .length;
  }
}

class _CoverageTile extends StatelessWidget {
  const _CoverageTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffffffff),
        border: Border.all(color: const Color(0xffe2e8f0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xff475569)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  color: Color(0xff0f172a),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Color(0xff64748b), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConflictReviewPanel extends StatelessWidget {
  const _ConflictReviewPanel({required this.slots});

  final List<TimetableSlot> slots;

  @override
  Widget build(BuildContext context) {
    final conflicts = _detectConflicts(slots);
    final roomCount = conflicts.where((item) => item.type == 'Bilik').length;
    final lecturerCount =
        conflicts.where((item) => item.type == 'Pensyarah').length;
    final classCount = conflicts.where((item) => item.type == 'Kelas').length;
    final hasConflicts = conflicts.isNotEmpty;

    return AppPanel(
      title: 'Semakan Konflik',
      subtitle:
          'Semakan tempatan untuk konflik bilik, pensyarah dan kelas dalam paparan semasa.',
      trailing: hasConflicts
          ? OutlinedButton.icon(
              onPressed: () => _showConflictDetails(context, conflicts),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Lihat Konflik'),
            )
          : null,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _SummaryTile('Konflik Bilik', roomCount, const Color(0xff7c2d12)),
          _SummaryTile(
              'Konflik Pensyarah', lecturerCount, const Color(0xff92400e)),
          _SummaryTile('Konflik Kelas', classCount, const Color(0xff991b1b)),
          if (!hasConflicts)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Tiada konflik dikesan.',
                style: TextStyle(
                  color: Color(0xff166534),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<_TimetableConflict> _detectConflicts(List<TimetableSlot> slots) {
    final activeSlots = slots.where(_isConflictRelevant).toList();
    final conflicts = <_TimetableConflict>[];
    for (var i = 0; i < activeSlots.length; i++) {
      for (var j = i + 1; j < activeSlots.length; j++) {
        final a = activeSlots[i];
        final b = activeSlots[j];
        if (!_sameScheduleWindow(a, b)) continue;
        _addConflictIfSame(
          conflicts,
          type: 'Bilik',
          valueA: a.roomId ?? a.room,
          valueB: b.roomId ?? b.room,
          slotA: a,
          slotB: b,
        );
        _addConflictIfSame(
          conflicts,
          type: 'Pensyarah',
          valueA: a.lecturerId,
          valueB: b.lecturerId,
          slotA: a,
          slotB: b,
        );
        _addConflictIfSame(
          conflicts,
          type: 'Kelas',
          valueA: a.classId ?? a.section,
          valueB: b.classId ?? b.section,
          slotA: a,
          slotB: b,
        );
      }
    }
    return conflicts;
  }

  bool _isConflictRelevant(TimetableSlot slot) {
    final status = slot.status.toLowerCase();
    return status != 'inactive' &&
        status != 'cancelled' &&
        status != 'canceled';
  }

  void _addConflictIfSame(
    List<_TimetableConflict> conflicts, {
    required String type,
    required String valueA,
    required String valueB,
    required TimetableSlot slotA,
    required TimetableSlot slotB,
  }) {
    final a = valueA.trim();
    final b = valueB.trim();
    if (a.isEmpty || b.isEmpty || a != b) return;
    conflicts.add(_TimetableConflict(type: type, value: a, a: slotA, b: slotB));
  }

  bool _sameScheduleWindow(TimetableSlot a, TimetableSlot b) {
    final sessionA = a.academicSessionId ?? a.session;
    final sessionB = b.academicSessionId ?? b.session;
    final dayA = a.dayOfWeek ?? a.day;
    final dayB = b.dayOfWeek ?? b.day;
    if (sessionA != sessionB || dayA != dayB) return false;

    final startA = _minutes(a.startTime);
    final endA = _minutes(a.endTime);
    final startB = _minutes(b.startTime);
    final endB = _minutes(b.endTime);
    if (startA == null || endA == null || startB == null || endB == null) {
      return false;
    }
    if (!(startA < endB && startB < endA)) return false;

    final weekStartA = int.tryParse(a.weekStart ?? a.date) ?? 1;
    final weekEndA = int.tryParse(a.weekEnd ?? a.date) ?? weekStartA;
    final weekStartB = int.tryParse(b.weekStart ?? b.date) ?? 1;
    final weekEndB = int.tryParse(b.weekEnd ?? b.date) ?? weekStartB;
    return weekStartA <= weekEndB && weekStartB <= weekEndA;
  }

  int? _minutes(String value) {
    final parts = value.trim().split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return (hour * 60) + minute;
  }

  void _showConflictDetails(
    BuildContext context,
    List<_TimetableConflict> conflicts,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Butiran Konflik Jadual'),
        content: SizedBox(
          width: 760,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final conflict in conflicts) ...[
                  _ConflictCard(conflict: conflict),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}

class _TimetableConflict {
  const _TimetableConflict({
    required this.type,
    required this.value,
    required this.a,
    required this.b,
  });

  final String type;
  final String value;
  final TimetableSlot a;
  final TimetableSlot b;
}

class _ConflictCard extends StatelessWidget {
  const _ConflictCard({required this.conflict});

  final _TimetableConflict conflict;

  @override
  Widget build(BuildContext context) {
    final slot = conflict.a;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xfffffbeb),
        border: Border.all(color: const Color(0xfffde68a)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${conflict.type}: ${conflict.value}',
              style: const TextStyle(
                color: Color(0xff92400e),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${slot.day} · ${slot.startTime}-${slot.endTime} · Minggu ${_weekTextForSlot(slot)}',
              style: const TextStyle(color: Color(0xff92400e), fontSize: 12),
            ),
            const SizedBox(height: 10),
            _ConflictSlotLine(slot: conflict.a),
            const SizedBox(height: 6),
            _ConflictSlotLine(slot: conflict.b),
          ],
        ),
      ),
    );
  }
}

class _ConflictSlotLine extends StatelessWidget {
  const _ConflictSlotLine({required this.slot});

  final TimetableSlot slot;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${slot.subjectCode} · ${slot.section} · ${slot.lecturerName} · ${slot.room}',
      style: const TextStyle(color: Color(0xff0f172a), fontSize: 13),
    );
  }
}

class _UploadWorkflowSection extends StatelessWidget {
  const _UploadWorkflowSection({
    required this.processingImport,
    required this.importError,
    required this.previewResult,
    required this.previewFileName,
    required this.lastImportResult,
    required this.importing,
    required this.canImportPreview,
    required this.onPickFile,
    required this.onDownloadTemplate,
    required this.onClearPreview,
    required this.onImportPreview,
    required this.onViewOfficialTimetable,
  });

  final bool processingImport;
  final String? importError;
  final TimetableMasterValidationResult? previewResult;
  final String? previewFileName;
  final TimetableImportWriteResult? lastImportResult;
  final bool importing;
  final bool canImportPreview;
  final VoidCallback onPickFile;
  final VoidCallback onDownloadTemplate;
  final VoidCallback onClearPreview;
  final VoidCallback onImportPreview;
  final VoidCallback onViewOfficialTimetable;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPanel(
          title: 'Muat Naik Jadual CSV',
          subtitle:
              'Sediakan jadual dalam Excel, kemudian eksport sebagai CSV sebelum dimuat naik.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UploadActions(
                processingImport: processingImport,
                onDownloadTemplate: onDownloadTemplate,
                onPickFile: onPickFile,
              ),
              const SizedBox(height: 16),
              const _UploadSteps(),
              const SizedBox(height: 16),
              const _ExampleValues(),
              const SizedBox(height: 16),
              _TemplateHelper(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (processingImport) ...[
          const AppPanel(
            title: 'Memproses CSV',
            subtitle: 'Sistem sedang membaca fail dan membuat validasi awal.',
            child: LinearProgressIndicator(),
          ),
          const SizedBox(height: 16),
        ],
        if (importError != null) ...[
          AppPanel(
            title: 'Ralat Fail',
            child: Text(
              importError!,
              style: const TextStyle(color: Color(0xffb91c1c)),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (previewResult == null && lastImportResult == null) ...[
          const _EmptyState(
            icon: Icons.upload_file_outlined,
            title: 'Belum ada fail CSV dipilih.',
            subtitle:
                'Pilih fail CSV untuk melihat pratonton. Data hanya disimpan selepas anda mengesahkan import baris layak.',
          ),
        ],
        if (previewResult != null) ...[
          _PreviewSummary(result: previewResult!),
          const SizedBox(height: 16),
          AppPanel(
            title: 'Pratonton CSV',
            subtitle:
                '${previewResult!.totalRows} baris daripada ${previewFileName ?? 'fail dipilih'}',
            trailing: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: processingImport ? null : onClearPreview,
                  icon: const Icon(Icons.close),
                  label: const Text('Reset Pratonton'),
                ),
                FilledButton.icon(
                  onPressed: canImportPreview ? onImportPreview : null,
                  icon: importing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(
                    importing ? 'Mengimport...' : 'Import Baris Layak',
                  ),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (previewResult!.validationWarnings.isNotEmpty) ...[
                  _MessageList(
                    title: 'Amaran Fail',
                    messages: previewResult!.validationWarnings,
                    color: const Color(0xff92400e),
                  ),
                  const SizedBox(height: 16),
                ],
                _PreviewTable(rows: previewResult!.previewRows),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (lastImportResult != null)
          _ImportSuccessPanel(
            result: lastImportResult!,
            onViewOfficialTimetable: onViewOfficialTimetable,
          ),
      ],
    );
  }
}

class _ImportHistorySection extends StatelessWidget {
  const _ImportHistorySection({
    required this.records,
    required this.scopedSlots,
    required this.onUpload,
  });

  final List<TimetableUploadRecord> records;
  final List<TimetableSlot> scopedSlots;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: 'Sejarah Import',
      subtitle:
          'Rekod import dibaca daripada timetable_uploads untuk sesi akademik yang dipilih.',
      trailing: FilledButton.icon(
        onPressed: onUpload,
        icon: const Icon(Icons.upload_file),
        label: const Text('Muat Naik Jadual'),
      ),
      child: records.isEmpty
          ? const _EmptyState(
              icon: Icons.history_outlined,
              title: 'Belum ada rekod import untuk skop ini.',
              subtitle:
                  'Rekod import akan dipaparkan selepas jadual dimuat naik.',
            )
          : AppDataTable(
              columns: const [
                DataColumn(label: Text('Fail')),
                DataColumn(label: Text('Tarikh Import')),
                DataColumn(label: Text('Dimuat Naik Oleh')),
                DataColumn(label: Text('Jumlah Baris')),
                DataColumn(label: Text('Berjaya')),
                DataColumn(label: Text('Amaran')),
                DataColumn(label: Text('Ralat')),
                DataColumn(label: Text('Pendua')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Tindakan')),
              ],
              rows: records.map((record) {
                final slotCount = _slotCountForUpload(record.uploadId);
                return DataRow(
                  cells: [
                    DataCell(SizedBox(
                      width: 180,
                      child: Text(
                        record.fileName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                    DataCell(Text(record.uploadedAt)),
                    DataCell(SizedBox(
                      width: 160,
                      child: Text(
                        record.uploadedByName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                    DataCell(Text('${record.totalRows}')),
                    DataCell(Text('${record.successRows}')),
                    DataCell(Text('${record.warningRows}')),
                    DataCell(Text('${record.errorRows}')),
                    DataCell(Text('${record.duplicateRows}')),
                    DataCell(StatusChip(_uploadStatusLabel(record.status))),
                    DataCell(IconButton(
                      tooltip: 'Lihat Butiran Import',
                      onPressed: () =>
                          _showImportDetails(context, record, slotCount),
                      icon: const Icon(Icons.info_outline),
                    )),
                  ],
                );
              }).toList(),
            ),
    );
  }

  int _slotCountForUpload(String uploadId) {
    return scopedSlots.where((slot) => slot.sourceUploadId == uploadId).length;
  }

  void _showImportDetails(
    BuildContext context,
    TimetableUploadRecord record,
    int slotCount,
  ) {
    final noteMessages = record.validationWarnings
        .where((message) =>
            message.startsWith('subjectId ') || message.startsWith('classId '))
        .toList();
    final warningMessages = record.validationWarnings
        .where((message) => !noteMessages.contains(message))
        .toList();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Butiran Import'),
        content: SizedBox(
          width: 680,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailSection(
                  title: 'Maklumat Import',
                  rows: [
                    ('Fail', record.fileName),
                    ('uploadId', record.uploadId),
                    ('academicSessionId', record.academicSessionId),
                    ('Dimuat naik oleh', record.uploadedByName),
                    ('uploadedBy', record.uploadedBy),
                    ('Tarikh import', record.uploadedAt),
                    ('Status', _uploadStatusLabel(record.status)),
                    ('Slot dijumpai', '$slotCount'),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailSection(
                  title: 'Ringkasan Baris',
                  rows: [
                    ('Jumlah', '${record.totalRows}'),
                    ('Berjaya', '${record.successRows}'),
                    ('Amaran', '${record.warningRows}'),
                    ('Ralat', '${record.errorRows}'),
                    ('Pendua', '${record.duplicateRows}'),
                    ('Dilangkau', '${record.skippedRows}'),
                  ],
                ),
                const SizedBox(height: 16),
                _MessageDetailsList(
                  title: 'Nota Import',
                  messages: noteMessages,
                  emptyText: 'Tiada nota import.',
                  color: const Color(0xff1d4ed8),
                ),
                const SizedBox(height: 16),
                _MessageDetailsList(
                  title: 'Amaran Validasi',
                  messages: warningMessages,
                  emptyText: 'Tiada amaran validasi.',
                  color: const Color(0xff92400e),
                ),
                const SizedBox(height: 16),
                _MessageDetailsList(
                  title: 'Ralat Validasi',
                  messages: record.validationErrors,
                  emptyText: 'Tiada ralat validasi.',
                  color: const Color(0xff991b1b),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}

class _UploadActions extends StatelessWidget {
  const _UploadActions({
    required this.processingImport,
    required this.onDownloadTemplate,
    required this.onPickFile,
  });

  final bool processingImport;
  final VoidCallback onDownloadTemplate;
  final VoidCallback onPickFile;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: processingImport ? null : onPickFile,
          icon: const Icon(Icons.upload_file),
          label: Text(processingImport ? 'Memproses...' : 'Pilih Fail CSV'),
        ),
        OutlinedButton.icon(
          onPressed: onDownloadTemplate,
          icon: const Icon(Icons.file_download_outlined),
          label: const Text('Muat Turun Templat CSV'),
        ),
      ],
    );
  }
}

class _UploadSteps extends StatelessWidget {
  const _UploadSteps();

  @override
  Widget build(BuildContext context) {
    const steps = [
      'Muat turun templat CSV.',
      'Isi jadual dalam Excel dan eksport sebagai CSV.',
      'Muat naik fail CSV, semak pratonton, kemudian import baris layak.',
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xffeff6ff),
        border: Border.all(color: const Color(0xffbfdbfe)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Langkah muat naik',
              style: TextStyle(
                color: Color(0xff1e3a8a),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < steps.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: const Color(0xff1d4ed8),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: const TextStyle(
                        color: Color(0xff1e3a8a),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              if (i != steps.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExampleValues extends StatelessWidget {
  const _ExampleValues();

  @override
  Widget build(BuildContext context) {
    const examples = [
      ('Sesi', TimetableCsvTemplate.defaultAcademicSessionId),
      ('Hari', 'Isnin, Selasa, Rabu, Khamis, Jumaat'),
      ('Masa', '08:00, 10:00, 14:30'),
      ('Bilik', 'BILIK KULIAH DED 1, SMART CLASSROOM'),
      ('Minggu', '1-18'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contoh nilai CSV',
          style: TextStyle(
            color: Color(0xff0f172a),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final example in examples)
              _InfoPill('${example.$1}: ${example.$2}'),
          ],
        ),
      ],
    );
  }
}

class _TemplateHelper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      initiallyExpanded: false,
      title: const Text(
        'Keperluan format CSV',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: const Text('Klik untuk melihat header penuh CSV.'),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SelectableText(
            TimetableCsvTemplate.fullHeader.join(','),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Color(0xff334155),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill('CSV sahaja'),
              _InfoPill('Excel: eksport sebagai CSV'),
              _InfoPill('Minggu: 1-18'),
              _InfoPill(
                  'Sesi: ${TimetableCsvTemplate.defaultAcademicSessionId}'),
              _InfoPill('Hari: Isnin-Ahad'),
              _InfoPill('Masa: HH:mm'),
            ],
          ),
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
          ? 'Baris sah dan baris beramaran tidak menghalang boleh diimport.'
          : 'Selesaikan ralat sebelum import dibuat.',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _SummaryTile(
              'Jumlah Baris', result.totalRows, const Color(0xff334155)),
          _SummaryTile('Sah', result.validRows, const Color(0xff166534)),
          _SummaryTile('Amaran', result.warningRows, const Color(0xff92400e)),
          _SummaryTile('Pendua', result.duplicateRows, const Color(0xff7c2d12)),
          _SummaryTile('Ralat', result.errorRows, const Color(0xff991b1b)),
          _SummaryTile(
              'Layak Import', result.importableRows, const Color(0xff0f766e)),
          _SummaryTile('Subjek Baharu', result.subjectUpsertDraftsCount,
              const Color(0xff1d4ed8)),
          _SummaryTile('Kelas Baharu', result.classCreateDraftsCount,
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
        DataColumn(label: Text('Baris')),
        DataColumn(label: Text('Program')),
        DataColumn(label: Text('Kelas')),
        DataColumn(label: Text('Kod')),
        DataColumn(label: Text('Subjek')),
        DataColumn(label: Text('Pensyarah')),
        DataColumn(label: Text('Bilik')),
        DataColumn(label: Text('Hari')),
        DataColumn(label: Text('Masa')),
        DataColumn(label: Text('Minggu')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Catatan')),
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
      TimetableImportRowStatus.valid => ('Sah', const Color(0xff166534)),
      TimetableImportRowStatus.warning => ('Amaran', const Color(0xff92400e)),
      TimetableImportRowStatus.duplicate => ('Pendua', const Color(0xff7c2d12)),
      TimetableImportRowStatus.error => ('Ralat', const Color(0xff991b1b)),
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
            '$summary\nLihat butiran',
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
          errors.length == 1 ? '1 ralat' : '${errors.length} ralat';
      if (warnings.isEmpty) return errorLabel;
      final warningLabel =
          warnings.length == 1 ? '1 amaran' : '${warnings.length} amaran';
      return '$errorLabel, $warningLabel';
    }

    final friendlyWarnings = warnings.map(_friendlyMessage).toSet().toList();
    if (friendlyWarnings.length <= 2) {
      return friendlyWarnings.join('; ');
    }
    return '${warnings.length} amaran';
  }

  String _friendlyMessage(String message) {
    if (message.startsWith('subjectId ')) {
      return 'Subjek akan dicipta semasa import';
    }
    if (message.startsWith('classId ')) {
      return 'Kelas akan dicipta semasa import';
    }
    if (message.startsWith('Academic session ')) {
      return 'Sesi akademik perlu disemak';
    }
    if (message.startsWith('lecturerName is blank')) {
      return 'Nama pensyarah akan dilengkapkan';
    }
    if (message.startsWith('roomName is blank')) {
      return 'Nama bilik akan dilengkapkan';
    }
    return message;
  }

  void _showDetails(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Butiran Baris $rowNumber'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (errors.isNotEmpty)
                  _MessageDetailSection(
                    title: 'Ralat',
                    color: const Color(0xff991b1b),
                    messages: errors,
                    friendlyMessage: _friendlyMessage,
                  ),
                if (errors.isNotEmpty && warnings.isNotEmpty)
                  const SizedBox(height: 16),
                if (warnings.isNotEmpty)
                  _MessageDetailSection(
                    title: 'Amaran',
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
            child: const Text('Tutup'),
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

class _MessageDetailsList extends StatelessWidget {
  const _MessageDetailsList({
    required this.title,
    required this.messages,
    required this.emptyText,
    required this.color,
  });

  final String title;
  final List<String> messages;
  final String emptyText;
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
            const SizedBox(height: 8),
            if (messages.isEmpty)
              Text(
                emptyText,
                style: const TextStyle(color: Color(0xff64748b), fontSize: 12),
              )
            else
              for (final message in messages)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: SelectableText(
                    message,
                    style: TextStyle(color: color, fontSize: 12),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _ImportSuccessPanel extends StatelessWidget {
  const _ImportSuccessPanel({
    required this.result,
    required this.onViewOfficialTimetable,
  });

  final TimetableImportWriteResult result;
  final VoidCallback onViewOfficialTimetable;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: 'Import Jadual Berjaya',
      subtitle: 'Rekod upload telah dicipta: ${result.uploadId}',
      trailing: OutlinedButton.icon(
        onPressed: onViewOfficialTimetable,
        icon: const Icon(Icons.table_chart_outlined),
        label: const Text('Lihat Jadual Rasmi'),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _SummaryTile(
              'Slot Dicipta', result.slotsCreated, const Color(0xff166534)),
          _SummaryTile('Subjek Dikemas Kini', result.subjectsUpserted,
              const Color(0xff1d4ed8)),
          _SummaryTile(
              'Kelas Dicipta', result.classesCreated, const Color(0xff6d28d9)),
          _SummaryTile('Pendua Dilangkau', result.duplicatesSkipped,
              const Color(0xff7c2d12)),
          _SummaryTile(
              'Ralat Dilangkau', result.errorsSkipped, const Color(0xff991b1b)),
          _SummaryTile(
              'Jumlah Dilangkau', result.skippedRows, const Color(0xff475569)),
        ],
      ),
    );
  }
}

class _TimetableTable extends StatelessWidget {
  const _TimetableTable({
    required this.slots,
    required this.selectedSlotKeys,
    required this.batchProcessing,
    required this.onSelectionChanged,
    this.onDetails,
    this.onEdit,
    this.onDelete,
  });

  final List<TimetableSlot> slots;
  final Set<String> selectedSlotKeys;
  final bool batchProcessing;
  final void Function(TimetableSlot slot, bool selected) onSelectionChanged;
  final void Function(TimetableSlot slot)? onDetails;
  final void Function(TimetableSlot slot)? onEdit;
  final void Function(TimetableSlot slot)? onDelete;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return const _EmptyState(
        icon: Icons.event_busy_outlined,
        title: 'Tiada jadual ditemui untuk skop ini.',
        subtitle: 'Muat naik CSV atau tambah jadual secara manual.',
      );
    }

    return AppDataTable(
      columns: const [
        DataColumn(label: Text('Pilih')),
        DataColumn(label: Text('Kod')),
        DataColumn(label: Text('Subjek')),
        DataColumn(label: Text('Kelas')),
        DataColumn(label: Text('Program')),
        DataColumn(label: Text('Pensyarah')),
        DataColumn(label: Text('Hari & Masa')),
        DataColumn(label: Text('Bilik')),
        DataColumn(label: Text('Minggu')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Tindakan')),
      ],
      rows: slots.map((slot) {
        final selected = selectedSlotKeys.contains(_slotSelectionKey(slot));
        return DataRow(cells: [
          DataCell(
            Tooltip(
              message: 'Pilih slot',
              child: Checkbox(
                value: selected,
                onChanged: batchProcessing
                    ? null
                    : (value) => onSelectionChanged(slot, value ?? false),
              ),
            ),
          ),
          DataCell(Text(
            slot.subjectCode,
            style: const TextStyle(fontWeight: FontWeight.w800),
          )),
          DataCell(SizedBox(
            width: 220,
            child: Text(slot.subjectName),
          )),
          DataCell(Text(slot.section)),
          DataCell(Tooltip(
            message: slot.program,
            child: Text(
              _programCode(slot),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          )),
          DataCell(SizedBox(
            width: 160,
            child: Text(slot.lecturerName),
          )),
          DataCell(SizedBox(
            width: 130,
            child: Text('${slot.day} · ${slot.startTime}-${slot.endTime}'),
          )),
          DataCell(SizedBox(
            width: 160,
            child: Text(slot.room),
          )),
          DataCell(Text(_weekText(slot))),
          DataCell(StatusChip(_statusLabel(slot.status))),
          DataCell(Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Lihat Butiran',
                onPressed: onDetails == null ? null : () => onDetails!(slot),
                icon: const Icon(Icons.info_outline),
              ),
              IconButton(
                tooltip: 'Edit Jadual',
                onPressed: onEdit == null ? null : () => onEdit!(slot),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Padam Jadual',
                onPressed: onDelete == null ? null : () => onDelete!(slot),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          )),
        ]);
      }).toList(),
    );
  }

  String _weekText(TimetableSlot slot) {
    final start = slot.weekStart;
    final end = slot.weekEnd;
    if (start != null && end != null) return '$start-$end';
    if (slot.date.isNotEmpty) return slot.date;
    return '-';
  }

  String _programCode(TimetableSlot slot) {
    final programId = slot.programId?.trim();
    if (programId != null && programId.isNotEmpty) return programId;
    final match = RegExp(r'\b[A-Z]{2,4}\b').firstMatch(slot.program);
    return match?.group(0) ?? slot.program;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        border: Border.all(color: const Color(0xffe2e8f0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: const Color(0xff64748b)),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xff0f172a),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xff64748b), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        border: Border.all(color: const Color(0xffe2e8f0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xff0f172a),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 170,
                      child: Text(
                        row.$1,
                        style: const TextStyle(
                          color: Color(0xff64748b),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SelectableText(
                        row.$2.isEmpty ? '-' : row.$2,
                        style: const TextStyle(
                          color: Color(0xff0f172a),
                          fontSize: 13,
                        ),
                      ),
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

String _statusLabel(String status) {
  return switch (status.toLowerCase()) {
    'active' || 'upcoming' => 'Aktif',
    'inactive' => 'Tidak Aktif',
    'cancelled' || 'canceled' => 'Dibatalkan',
    'attendance completed' => 'Kehadiran Selesai',
    _ => status,
  };
}

String _slotSelectionKey(TimetableSlot slot) {
  final timetableSlotId = slot.timetableSlotId.trim();
  if (timetableSlotId.isNotEmpty) return timetableSlotId;
  return slot.id;
}

String _uploadStatusLabel(String status) {
  return switch (status.toLowerCase()) {
    'completed' => 'Berjaya',
    'completed_with_warnings' => 'Berjaya Dengan Amaran',
    'failed' => 'Gagal',
    _ => status,
  };
}

String _shortProgramLabel(String value) {
  final match = RegExp(r'\b[A-Z]{2,4}\b').firstMatch(value);
  return match?.group(0) ?? value;
}

String _weekTextForSlot(TimetableSlot slot) {
  final start = slot.weekStart;
  final end = slot.weekEnd;
  if (start != null && end != null) return '$start-$end';
  if (slot.date.isNotEmpty) return slot.date;
  return '-';
}
