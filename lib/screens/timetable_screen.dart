import 'package:flutter/material.dart';

import '../core/constants/timetable_template.dart';
import '../models/app_models.dart';
import '../models/timetable_import_result.dart';
import '../models/timetable_import_write_result.dart';
import '../models/timetable_master_validation_result.dart';
import '../models/timetable_preview_conflict.dart';
import '../services/timetable_firestore_import_service.dart';
import '../services/timetable_import_service.dart';
import '../services/timetable_file_io.dart';
import '../services/timetable_master_validation_service.dart';
import '../services/timetable_preview_conflict_service.dart';
import '../services/timetable_view_export_service.dart';
import '../services/timetable_xlsx_export_service.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../widgets/app_layout.dart';
import '../widgets/app_theme.dart';
import '../widgets/class_timetable_generator_dialog.dart';
import '../widgets/mobile_components.dart';
import '../widgets/responsive.dart';
import '../widgets/status_chip.dart';
import 'add_timetable_screen.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

enum _TimetableViewMode { list, weekly, room, lecturer }

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
  TimetablePreviewConflictSummary _previewConflicts =
      const TimetablePreviewConflictSummary.empty();
  String? _previewFileName;
  String? _importError;
  TimetableImportWriteResult? _lastImportResult;
  bool _processingImport = false;
  bool _importing = false;
  bool _batchProcessing = false;
  int _selectedSection = 0;
  _TimetableViewMode _selectedTimetableView = _TimetableViewMode.list;
  final _searchCtrl = TextEditingController();
  final Set<String> _selectedSlotKeys = <String>{};
  String? _dayFilter;
  String? _statusFilter;
  String? _programFilter;
  String? _classFilter;
  String? _lecturerFilter;
  String? _roomFilter;
  String? _academicSessionFilter;
  String? _generatorProgramFilter;

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
      return const AppPageHeader(
        title: 'Akses Tidak Dibenarkan',
        subtitle:
            'Hanya Ketua Jabatan atau Ketua Program tanpa Ketua Jabatan boleh memuat naik dan mengurus jadual.',
      );
    }

    final timetable = state.scopedTimetable;
    final sessionOptions = _academicSessionOptions(state);
    final selectedSession = _activeAcademicSession(state);
    final sessionTimetable = _sessionTimetable(timetable, selectedSession);
    final filteredTimetable = _filteredTimetable(sessionTimetable);
    final generatorPrograms = _availableProgramOptions(sessionTimetable);
    return AppPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (context.isMobile) ...[
            MobileHeroCard(
              icon: Icons.calendar_month_outlined,
              title: 'Pengurusan Jadual',
              subtitle: '${sessionTimetable.length} rekod · $selectedSession',
              chips: [
                StatusChip(user.role == UserRole.ketua_program
                    ? 'Program'
                    : 'Jabatan'),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedSession,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Sesi',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: sessionOptions
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        _updateFilters(() {
                          state.updateAcademicSession(value);
                          _academicSessionFilter = value;
                          _dayFilter = null;
                          _statusFilter = null;
                          _programFilter = null;
                          _classFilter = null;
                          _lecturerFilter = null;
                          _roomFilter = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _showMobileActionsBottomSheet(
                      state: state,
                      filteredTimetable: filteredTimetable,
                      selectedSession: selectedSession,
                      generatorPrograms: generatorPrograms,
                    ),
                    icon: const Icon(Icons.touch_app_outlined, size: 18),
                    label: const Text('Tindakan'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionTabs(
              selectedIndex: _selectedSection,
              onChanged: (index) => setState(() => _selectedSection = index),
            ),
            const SizedBox(height: 12),
          ] else ...[
            AppPageHeader(
              title: user.role == UserRole.ketua_program
                  ? 'Pengurusan Jadual Program'
                  : 'Pengurusan Jadual Jabatan',
              subtitle:
                  'Urus jadual rasmi, muat naik jadual CSV, dan semak rekod import mengikut skop pengguna.',
              trailing: StatusChip('${sessionTimetable.length} Rekod Jadual'),
            ),
            _ScopeSummary(
              state: state,
              slotCount: sessionTimetable.length,
              selectedAcademicSession: selectedSession,
              academicSessionOptions: sessionOptions,
              onAcademicSessionChanged: (value) {
                if (value == null) return;
                _updateFilters(() {
                  state.updateAcademicSession(value);
                  _academicSessionFilter = value;
                  _dayFilter = null;
                  _statusFilter = null;
                  _programFilter = null;
                  _classFilter = null;
                  _lecturerFilter = null;
                  _roomFilter = null;
                });
              },
            ),
            const SizedBox(height: 12),
            _HeaderActionBar(
              hasTimetable: filteredTimetable.isNotEmpty,
              onUpload: () => setState(() => _selectedSection = 1),
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
            const SizedBox(height: 12),
            _ClassTimetableSecondaryAction(
              enabled: generatorPrograms.isNotEmpty,
              onOpen: () => _showClassTimetableGeneratorDialog(
                state: state,
                selectedSession: selectedSession,
                programOptions: generatorPrograms,
              ),
            ),
            const SizedBox(height: 20),
            _SectionTabs(
              selectedIndex: _selectedSection,
              onChanged: (index) => setState(() => _selectedSection = index),
            ),
            const SizedBox(height: 16),
          ],
          if (_selectedSection == 0)
            _OfficialTimetableSection(
              state: state,
              slots: filteredTimetable,
              allSlots: sessionTimetable,
              selectedAcademicSession: selectedSession,
              searchCtrl: _searchCtrl,
              dayFilter: _dayFilter,
              statusFilter: _statusFilter,
              programFilter: _programFilter,
              classFilter: _classFilter,
              lecturerFilter: _lecturerFilter,
              roomFilter: _roomFilter,
              selectedViewMode: _selectedTimetableView,
              selectedSlotKeys: _selectedSlotKeys,
              batchProcessing: _batchProcessing,
              onSearchChanged: (_) => _updateFilters(() {}),
              onDayChanged: (value) => _updateFilters(() => _dayFilter = value),
              onStatusChanged: (value) =>
                  _updateFilters(() => _statusFilter = value),
              onProgramChanged: (value) => _updateFilters(() {
                _programFilter = value;
                _classFilter = null;
                _lecturerFilter = null;
                _roomFilter = null;
              }),
              onClassChanged: (value) => _updateFilters(() {
                _classFilter = value;
                _lecturerFilter = null;
                _roomFilter = null;
              }),
              onLecturerChanged: (value) => _updateFilters(() {
                _lecturerFilter = value;
                _roomFilter = null;
              }),
              onRoomChanged: (value) =>
                  _updateFilters(() => _roomFilter = value),
              onResetFilters: _resetFilters,
              onViewModeChanged: (mode) => setState(() {
                _selectedTimetableView = mode;
                if (mode != _TimetableViewMode.list) {
                  _selectedSlotKeys.clear();
                }
              }),
              onToggleSelectAllVisible: () =>
                  _toggleSelectAllVisible(filteredTimetable),
              onClearSelection: _clearSelection,
              onExportSelected: () => _exportSelected(filteredTimetable),
              onBatchInactive: () =>
                  _confirmBatchInactive(state, filteredTimetable),
              onBatchDelete: () =>
                  _confirmBatchDelete(state, filteredTimetable),
              onSelectionChanged: _setSlotSelection,
              onDetails: (slot) => _showSlotDetails(state, slot),
              onEdit: (slot) => _showEditDialog(state, slot),
              onConflictEdit: (slot) =>
                  _showEditDialog(state, slot, conflictContext: true),
              onPublishDrafts: (slots) =>
                  _confirmPublishDraftSlots(state, slots),
              onDelete: (slot) => _confirmDelete(state, slot),
            )
          else if (_selectedSection == 1)
            _UploadWorkflowSection(
              selectedAcademicSession: selectedSession,
              processingImport: _processingImport,
              importError: _importError,
              previewResult: _previewResult,
              previewConflicts: _previewConflicts,
              previewFileName: _previewFileName,
              lastImportResult: _lastImportResult,
              importing: _importing,
              canImportPreview: _canImportPreview,
              canSaveDraftPreview: _canSaveDraftPreview,
              onPickFile: () => _pickAndPreviewFile(state),
              onDownloadTemplate: () =>
                  _downloadTemplate(state, selectedSession),
              onClearPreview: _clearPreview,
              onSaveDraftPreview: () => _confirmAndImportPreview(
                state,
                saveMode: TimetableImportSaveMode.draft,
              ),
              onImportPreview: () => _confirmAndImportPreview(state),
              onViewOfficialTimetable: () =>
                  setState(() => _selectedSection = 0),
            )
          else
            _ImportHistorySection(
              records: _filteredUploadHistory(state),
              scopedSlots: timetable,
              onUpload: () => setState(() => _selectedSection = 1),
            ),
        ],
      ),
    );
  }

  void _updateFilters(VoidCallback update) {
    setState(() {
      update();
      _selectedSlotKeys.clear();
    });
  }

  List<TimetableSlot> _sessionTimetable(
    List<TimetableSlot> slots,
    String selectedSession,
  ) {
    return slots
        .where((slot) => _slotSessionValue(slot) == selectedSession)
        .toList();
  }

  List<TimetableSlot> _filteredTimetable(List<TimetableSlot> slots) {
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
          _slotClassValue(slot),
          _slotProgramValue(slot),
          _slotRoomValue(slot),
        ].join(' ').toLowerCase();
        if (!haystack.contains(query)) return false;
      }
      if (_dayFilter != null && slot.day != _dayFilter) return false;
      if (_statusFilter != null) {
        if (_statusFilter == 'conflict_pending') {
          if (!slot.hasConflict && slot.importStatus != 'conflict_pending') {
            return false;
          }
        } else if (slot.status != _statusFilter) {
          return false;
        }
      }
      if (_programFilter != null && _slotProgramValue(slot) != _programFilter) {
        return false;
      }
      if (_classFilter != null && _slotClassValue(slot) != _classFilter) {
        return false;
      }
      if (_lecturerFilter != null && slot.lecturerName != _lecturerFilter) {
        return false;
      }
      if (_roomFilter != null && _slotRoomValue(slot) != _roomFilter) {
        return false;
      }
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
      _selectedSlotKeys.clear();
    });
  }

  List<String> _availableProgramOptions(List<TimetableSlot> slots) {
    return slots
        .map((slot) => slot.programId ?? slot.section.split(' ').first)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<String> _availableClassOptions(
    List<TimetableSlot> slots,
    String? programId,
  ) {
    return slots
        .where((slot) => programId == null || slot.programId == programId)
        .map((slot) => slot.classId ?? slot.section)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  void _showMobileActionsBottomSheet({
    required AppState state,
    required List<TimetableSlot> filteredTimetable,
    required String selectedSession,
    required List<String> generatorPrograms,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (sheetContext) => MobileBottomSheet(
        title: 'Tindakan Jadual',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MobileListTile(
              icon: Icons.upload_file_outlined,
              title: 'Muat Naik Jadual',
              subtitle: 'Import jadual dari fail CSV',
              onTap: () {
                Navigator.pop(sheetContext);
                setState(() => _selectedSection = 1);
              },
            ),
            const SizedBox(height: 8),
            MobileListTile(
              icon: Icons.ios_share,
              title: 'Eksport Paparan Semasa',
              subtitle: 'Muat turun senarai jadual semasa',
              onTap: () {
                if (filteredTimetable.isEmpty) return;
                Navigator.pop(sheetContext);
                _exportTimetable(filteredTimetable);
              },
            ),
            const SizedBox(height: 8),
            MobileListTile(
              icon: Icons.add,
              title: 'Tambah Slot Manual',
              subtitle: 'Cipta slot jadual baharu',
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddTimetableScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
            MobileListTile(
              icon: Icons.view_week_outlined,
              title: 'Jana Jadual Kelas',
              subtitle: 'Eksport jadual kelas khusus',
              onTap: () {
                if (generatorPrograms.isEmpty) return;
                Navigator.pop(sheetContext);
                _showClassTimetableGeneratorDialog(
                  state: state,
                  selectedSession: selectedSession,
                  programOptions: generatorPrograms,
                );
              },
            ),
            const SizedBox(height: 8),
            MobileListTile(
              icon: Icons.history_outlined,
              title: 'Sejarah Import',
              subtitle: 'Lihat rekod import lepas',
              onTap: () {
                Navigator.pop(sheetContext);
                setState(() => _selectedSection = 2);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showClassTimetableGeneratorDialog({
    required AppState state,
    required String selectedSession,
    required List<String> programOptions,
  }) {
    final initialProgramId = _generatorProgramFilter != null &&
            programOptions.contains(_generatorProgramFilter)
        ? _generatorProgramFilter
        : programOptions.firstOrNull;
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => ClassTimetableGeneratorDialog(
        sessionOptions: _academicSessionOptions(state),
        initialSessionId: selectedSession,
        programOptions: programOptions,
        initialProgramId: initialProgramId,
        programLabelFor: (programId) {
          final program =
              state.programs.where((item) => item.id == programId).firstOrNull;
          return program == null
              ? programId
              : '${program.id} - ${program.name}';
        },
        classOptionsFor: (academicSessionId, programId) {
          final sessionSlots =
              _sessionTimetable(state.scopedTimetable, academicSessionId);
          return _availableClassOptions(sessionSlots, programId);
        },
        slotsFor: (academicSessionId, programId, classId) {
          final sessionSlots =
              _sessionTimetable(state.scopedTimetable, academicSessionId);
          return filterClassTimetableSlots(
            sessionSlots,
            programId: programId,
            classId: classId,
            academicSessionId: academicSessionId,
          );
        },
        onExport: (academicSessionId, programId, classId, slots) {
          _generatorProgramFilter = programId;
          _exportClassTimetable(
            state: state,
            programId: programId,
            classId: classId,
            academicSessionId: academicSessionId,
            slots: slots,
          );
        },
      ),
    );
  }

  void _exportClassTimetable({
    required AppState state,
    required String programId,
    required String classId,
    required String academicSessionId,
    required List<TimetableSlot> slots,
  }) {
    final program =
        state.programs.where((item) => item.id == programId).firstOrNull;
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

  String _activeAcademicSession(AppState state) {
    return _academicSessionFilter ?? state.session;
  }

  List<String> _academicSessionOptions(AppState state) {
    final values = state.selectableAcademicSessions
        .map((session) => session.academicSessionId)
        .toList();
    if (values.isEmpty) return [state.session];
    if (!values.contains(state.session)) values.insert(0, state.session);
    return values;
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
        result.importableRows > 0 &&
        result.canImport &&
        !_previewConflicts.hasConflicts;
  }

  bool get _canSaveDraftPreview {
    final result = _previewResult;
    return !_processingImport &&
        !_importing &&
        result != null &&
        result.importableRows > 0 &&
        result.canImport;
  }

  void _clearPreview() {
    setState(() {
      _previewResult = null;
      _previewConflicts = const TimetablePreviewConflictSummary.empty();
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
        _previewConflicts = const TimetablePreviewConflictSummary.empty();
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
        _previewConflicts = const TimetablePreviewConflictSummary.empty();
        _previewFileName = file.name;
        _importError = null;
        _lastImportResult = null;
      });
      final parsed =
          const TimetableImportService().parseAndValidate(file.content);
      final preview = await TimetableMasterValidationService(
        FirestoreTimetableMasterDataSource(),
      ).preparePreview(
        parsed,
        uploadScope: TimetableUploadScope.forUser(
          state.currentUser!,
          state.programs,
        ),
      );
      final validatedPreview = _withSelectedSessionValidation(
        preview,
        _activeAcademicSession(state),
      );
      final conflicts = const TimetablePreviewConflictService().detect(
        preview: validatedPreview,
        existingSlots: state.scopedTimetable,
      );
      setState(() {
        _previewResult = validatedPreview;
        _previewConflicts = conflicts;
        _previewFileName = file.name;
        _importError = validatedPreview.validationErrors.isEmpty
            ? null
            : validatedPreview.validationErrors.join('\n');
      });
    } catch (e) {
      setState(() {
        _previewResult = null;
        _previewConflicts = const TimetablePreviewConflictSummary.empty();
        _previewFileName = file.name;
        _importError = e.toString().replaceFirst('Exception: ', '');
        _lastImportResult = null;
      });
    } finally {
      if (mounted) setState(() => _processingImport = false);
    }
  }

  TimetableMasterValidationResult _withSelectedSessionValidation(
    TimetableMasterValidationResult preview,
    String selectedSession,
  ) {
    final mismatches = preview.previewRows.where((row) {
      final rowSession = row.slotDraft?.academicSessionId ??
          row.sourceRow.draft?.academicSessionId;
      return rowSession != null &&
          rowSession.isNotEmpty &&
          rowSession != selectedSession;
    }).toList();
    if (mismatches.isEmpty) return preview;

    final messages = mismatches
        .map((row) {
          final rowSession = row.slotDraft?.academicSessionId ??
              row.sourceRow.draft?.academicSessionId ??
              '-';
          return 'Sesi dipilih ialah $selectedSession, tetapi baris CSV ${row.rowNumber} menggunakan $rowSession.';
        })
        .toSet()
        .toList();

    return TimetableMasterValidationResult(
      totalRows: preview.totalRows,
      validRows: preview.validRows,
      warningRows: preview.warningRows,
      duplicateRows: preview.duplicateRows,
      errorRows: preview.errorRows,
      subjectUpsertDrafts: preview.subjectUpsertDrafts,
      classCreateDrafts: preview.classCreateDrafts,
      previewRows: preview.previewRows,
      validationErrors: [
        ...preview.validationErrors,
        ...messages,
      ],
      validationWarnings: preview.validationWarnings,
    );
  }

  Future<void> _confirmAndImportPreview(
    AppState state, {
    TimetableImportSaveMode saveMode = TimetableImportSaveMode.official,
  }) async {
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
    if (!preview.canImport) {
      setState(
        () => _importError = 'Ralat kritikal perlu dibetulkan dahulu.',
      );
      return;
    }
    if (saveMode == TimetableImportSaveMode.official &&
        _previewConflicts.hasConflicts) {
      setState(
        () => _importError =
            'Konflik perlu diselesaikan sebelum jadual boleh diterbitkan sebagai rasmi.',
      );
      return;
    }

    final isDraft = saveMode == TimetableImportSaveMode.draft;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isDraft
              ? 'Simpan jadual sebagai draf?'
              : 'Import sebagai jadual rasmi?',
        ),
        content: Text(
          '${preview.importableRows} baris akan ${isDraft ? 'disimpan sebagai draf' : 'diterbitkan sebagai jadual rasmi'}. '
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
            child: Text(
              isDraft ? 'Simpan Sebagai Draf' : 'Import Sebagai Jadual Rasmi',
            ),
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
        saveMode: saveMode,
        conflictSummary: _previewConflicts,
      );
      await state.refreshTimetableData();
      if (!mounted) return;
      setState(() {
        _lastImportResult = result;
        _previewResult = null;
        _previewConflicts = const TimetablePreviewConflictSummary.empty();
        _previewFileName = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isDraft
                ? 'Jadual disimpan sebagai draf. Sila semak dan selesaikan konflik sebelum diterbitkan sebagai jadual rasmi.'
                : 'Jadual berjaya diimport sebagai jadual rasmi.',
          ),
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

  void _downloadTemplate(AppState state, String selectedSession) {
    final sampleProgramId = _sampleProgramId(state);
    final sampleLecturer = _sampleLecturer(state, sampleProgramId);
    final sampleRoomName = _sampleRoomName(state, sampleProgramId);
    final rows = [
      TimetableCsvTemplate.fullHeader,
      [
        selectedSession,
        sampleProgramId,
        _programNameForTemplate(state, sampleProgramId),
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
    final state = AppScope.of(context);
    final user = state.currentUser!;
    final isProgramScope = user.role == UserRole.ketua_program;

    // Build scope title
    final scopeTitle = isProgramScope
        ? 'Program ${user.programId ?? 'Unknown'}'
        : state.departments
                .where((d) => d.id == user.departmentId)
                .firstOrNull
                ?.name ??
            user.departmentId ??
            'Jabatan';

    // Build scoped program IDs list
    final scopeProgramIds = state.scopedPrograms.map((p) => p.id).toList()
      ..sort();

    // Build role label
    final roleLabel = isProgramScope
        ? 'KP ${user.programId ?? ''}'
        : 'KJ ${state.departments.where((d) => d.id == user.departmentId).firstOrNull?.name ?? user.departmentId ?? ''}';

    final selectedSession = _activeAcademicSession(state);

    final params = TimetableXlsxExportParams(
      slots: timetable,
      academicSessionId: selectedSession,
      scopeTitle: scopeTitle,
      scopeProgramIds: scopeProgramIds,
      generatedByName: user.name,
      generatedByRole: roleLabel,
      generatedAt: DateTime.now(),
      filterProgram: _programFilter,
      filterClass: _classFilter,
      filterLecturer: _lecturerFilter,
      filterRoom: _roomFilter,
      filterDay: _dayFilter,
      filterStatus: _statusFilter,
    );

    final bytes = buildTimetableXlsx(params);
    if (bytes.isEmpty) return;

    downloadBinaryFile(
      filename: buildExportFilename(params),
      bytes: bytes,
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  void _exportSelected(List<TimetableSlot> visibleSlots) {
    final selected = _selectedVisibleSlots(visibleSlots);
    if (selected.isEmpty) return;
    final rows = [
      _legacyExportColumns,
      ...selected.map((slot) => _slotToRow(slot)),
    ];
    downloadTextFile(
      filename: 'jadual_selected_${_dateStamp()}.csv',
      content: _toCsv(rows),
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

  Future<void> _confirmPublishDraftSlots(
    AppState state,
    List<TimetableSlot> draftSlots,
  ) async {
    final user = state.currentUser;
    if (user == null) return;
    draftSlots = draftSlots.where(_isDraftSlot).toList();
    if (draftSlots.isEmpty) {
      setState(() => _importError = 'Tiada slot draf untuk diterbitkan.');
      return;
    }

    final conflicts = _draftPublishConflicts(state, draftSlots);
    if (conflicts.hasConflicts) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Draf Masih Berkonflik'),
          content: Text(
            'Draf masih mempunyai konflik. Sila selesaikan konflik sebelum diterbitkan.\n\n'
            'Konflik Bilik: ${conflicts.roomConflicts}\n'
            'Konflik Pensyarah: ${conflicts.lecturerConflicts}\n'
            'Konflik Kelas: ${conflicts.classConflicts}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terbitkan Draf?'),
        content: Text(
          '${draftSlots.length} slot draf akan diterbitkan sebagai jadual rasmi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Terbitkan Draf'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _batchProcessing = true);
    try {
      await state.publishTimetableSlots(draftSlots);
      _clearSelection();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${draftSlots.length} slot diterbitkan sebagai rasmi.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _importError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _batchProcessing = false);
    }
  }

  TimetablePreviewConflictSummary _draftPublishConflicts(
    AppState state,
    List<TimetableSlot> draftSlots,
  ) {
    final previewRows = [
      for (var i = 0; i < draftSlots.length; i++)
        _previewRowFromDraftSlot(draftSlots[i], i + 2),
    ];
    final preview = TimetableMasterValidationResult(
      totalRows: previewRows.length,
      validRows: previewRows.length,
      warningRows: 0,
      duplicateRows: 0,
      errorRows: 0,
      subjectUpsertDrafts: const [],
      classCreateDrafts: const [],
      previewRows: previewRows,
      validationErrors: const [],
      validationWarnings: const [],
    );
    final draftIds = draftSlots.map((slot) => slot.id).toSet();
    final existingOfficialSlots = state.scopedTimetable
        .where((slot) => !draftIds.contains(slot.id) && slot.isOfficial)
        .toList();
    return const TimetablePreviewConflictService().detect(
      preview: preview,
      existingSlots: existingOfficialSlots,
    );
  }

  TimetablePreviewRow _previewRowFromDraftSlot(TimetableSlot slot, int row) {
    final draft = TimetablePreviewSlotDraft(
      academicSessionId: slot.academicSessionId ?? slot.session,
      programId: slot.programId ?? _shortProgramLabel(slot.program),
      programName: slot.program,
      departmentId: slot.departmentId,
      classId: slot.classId ?? slot.section,
      subjectId: slot.subjectId ?? '',
      subjectCode: slot.subjectCode,
      subjectName: slot.subjectName,
      lecturerId: slot.lecturerId,
      lecturerEmail: slot.lecturerEmail ?? '',
      lecturerName: slot.lecturerName,
      lecturerProfileId: slot.lecturerProfileId,
      roomId: slot.roomId ?? slot.room,
      roomName: slot.roomName ?? slot.room,
      dayOfWeek: slot.dayOfWeek ?? slot.day,
      startTime: slot.startTime,
      endTime: slot.endTime,
      weekStart: int.tryParse(slot.weekStart ?? slot.date) ?? 1,
      weekEnd: int.tryParse(slot.weekEnd ?? slot.date) ??
          (int.tryParse(slot.weekStart ?? slot.date) ?? 1),
      status: 'active',
      remarks: null,
    );
    return TimetablePreviewRow(
      rowNumber: row,
      status: TimetableImportRowStatus.valid,
      errors: const [],
      warnings: const [],
      slotDraft: draft,
      sourceRow: TimetableImportParsedRow(
        rowNumber: row,
        rawData: const {},
        draft: null,
        status: TimetableImportRowStatus.valid,
        errors: const [],
        warnings: const [],
      ),
    );
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

  String _safeFileSegment(String value) {
    return value.trim().replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
  }

  Future<void> _showEditDialog(
    AppState state,
    TimetableSlot slot, {
    bool conflictContext = false,
  }) async {
    final session =
        TextEditingController(text: slot.academicSessionId ?? slot.session);
    final semester = TextEditingController(text: slot.semester.toString());
    final subjectCode = TextEditingController(text: slot.subjectCode);
    final subjectName = TextEditingController(text: slot.subjectName);
    final lecturerId = TextEditingController(text: slot.lecturerId);
    final lecturerName = TextEditingController(text: slot.lecturerName);
    final date = TextEditingController(text: slot.date);
    final startTime = TextEditingController(text: slot.startTime);
    final endTime = TextEditingController(text: slot.endTime);
    final room = TextEditingController(text: _slotRoomValue(slot));
    final weekStart = TextEditingController(text: slot.weekStart ?? slot.date);
    final weekEnd = TextEditingController(text: slot.weekEnd ?? slot.date);
    final enrolled = TextEditingController(text: slot.enrolled.toString());
    final capacity = TextEditingController(text: slot.capacity.toString());
    final classType = TextEditingController(text: slot.classType);
    final slotType = TextEditingController(text: slot.slotType);
    var selectedProgram = _slotProgramValue(slot);
    var selectedClass = _slotClassValue(slot);
    var selectedSubjectKey = _subjectEditKey(
      slot.subjectId,
      slot.subjectCode,
      slot.subjectName,
    );
    var selectedSubjectId = slot.subjectId;
    var selectedLecturerKey =
        _lecturerEditKey(slot.lecturerId, slot.lecturerName);
    var selectedLecturerEmail = slot.lecturerEmail;
    var selectedLecturerProfileId = slot.lecturerProfileId;
    var selectedRoom = _slotRoomValue(slot);
    var selectedDay = _normalizeDay(slot.dayOfWeek ?? slot.day);
    var selectedStatus = _normalizeSlotStatus(slot.status);
    String? formError;
    StateSetter? dialogSetState;
    final sessionOptions = _academicSessionOptions(state);
    final roomValues = state.roomResources
        .map((room) => room.name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
      ..add(room.text.trim());
    roomValues.remove('');
    final roomOptions = roomValues.toList()..sort();

    final saved = await showDialog<TimetableSlot>(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          title: const Text('Kemas Kini Slot Jadual'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              dialogSetState = setDialogState;
              final programOptions = _editProgramOptions(state, slot);
              final classOptions =
                  _editClassOptions(state, selectedProgram, slot);
              final subjectOptions =
                  _editSubjectOptions(state, selectedProgram, slot);
              final subjectLabels = {
                for (final option in subjectOptions) option.key: option.label,
              };
              final lecturerOptions =
                  _editLecturerOptions(state, selectedProgram, slot);
              final lecturerLabels = {
                for (final option in lecturerOptions) option.key: option.label,
              };
              return SizedBox(
                width: _dialogWidth(context, maxWidth: 760),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _EditSlotNote(conflictContext: conflictContext),
                      if (formError != null) ...[
                        const SizedBox(height: 10),
                        _InlineErrorMessage(message: formError!),
                      ],
                      const SizedBox(height: 14),
                      _EditFormSection(
                        title: 'Maklumat Kursus',
                        children: [
                          _dropdownField(
                            label: 'Sesi Akademik',
                            value: session.text.trim(),
                            values: sessionOptions,
                            onChanged: (value) {
                              if (value == null) return;
                              setDialogState(() => session.text = value);
                            },
                          ),
                          _dropdownField(
                            label: 'Program',
                            value: selectedProgram,
                            values: programOptions,
                            labelForValue: (value) =>
                                _programOptionLabel(state, value),
                            onChanged: (value) {
                              if (value == null) return;
                              setDialogState(() {
                                selectedProgram = value;
                                final nextClasses =
                                    _editClassOptions(state, value, slot);
                                if (!nextClasses.contains(selectedClass)) {
                                  selectedClass = '';
                                }
                                final nextSubjects =
                                    _editSubjectOptions(state, value, slot);
                                if (!nextSubjects.any((option) =>
                                    option.key == selectedSubjectKey)) {
                                  selectedSubjectKey = '';
                                  selectedSubjectId = null;
                                  subjectCode.clear();
                                  subjectName.clear();
                                }
                                final nextLecturers =
                                    _editLecturerOptions(state, value, slot);
                                if (!nextLecturers.any((option) =>
                                    option.key == selectedLecturerKey)) {
                                  selectedLecturerKey = '';
                                  selectedLecturerEmail = null;
                                  selectedLecturerProfileId = null;
                                  lecturerId.clear();
                                  lecturerName.clear();
                                }
                                formError = null;
                              });
                            },
                          ),
                          _dropdownField(
                            label: 'Kelas',
                            value: selectedClass,
                            values: classOptions,
                            onChanged: (value) {
                              if (value == null) return;
                              setDialogState(() {
                                selectedClass = value;
                                formError = null;
                              });
                            },
                          ),
                          _dropdownField(
                            label: 'Kursus',
                            value: selectedSubjectKey,
                            values:
                                subjectOptions.map((item) => item.key).toList(),
                            labelForValue: (value) =>
                                subjectLabels[value] ?? value,
                            wide: true,
                            onChanged: (value) {
                              if (value == null) return;
                              final option = subjectOptions
                                  .where((item) => item.key == value)
                                  .firstOrNull;
                              if (option == null) return;
                              setDialogState(() {
                                selectedSubjectKey = option.key;
                                selectedSubjectId = option.subjectId;
                                subjectCode.text = option.subjectCode;
                                subjectName.text = option.subjectName;
                                formError = null;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _EditFormSection(
                        title: 'Pensyarah',
                        children: [
                          _dropdownField(
                            label: 'Pensyarah',
                            value: selectedLecturerKey,
                            values: lecturerOptions
                                .map((item) => item.key)
                                .toList(),
                            labelForValue: (value) =>
                                lecturerLabels[value] ?? value,
                            wide: true,
                            onChanged: (value) {
                              if (value == null) return;
                              final option = lecturerOptions
                                  .where((item) => item.key == value)
                                  .firstOrNull;
                              if (option == null) return;
                              setDialogState(() {
                                selectedLecturerKey = option.key;
                                lecturerId.text = option.lecturerId;
                                lecturerName.text = option.lecturerName;
                                selectedLecturerEmail = option.email;
                                selectedLecturerProfileId =
                                    option.lecturerProfileId;
                                formError = null;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _EditFormSection(
                        title: 'Jadual Slot',
                        children: [
                          _dropdownField(
                            label: 'Hari',
                            value: selectedDay,
                            values: _weekdayValues,
                            onChanged: (value) {
                              if (value == null) return;
                              setDialogState(() => selectedDay = value);
                            },
                          ),
                          _field(startTime, 'Masa Mula'),
                          _field(endTime, 'Masa Tamat'),
                          if (roomOptions.isEmpty)
                            _field(room, 'Bilik', wide: true)
                          else
                            _dropdownField(
                              label: 'Bilik',
                              value: selectedRoom,
                              values: roomOptions,
                              wide: true,
                              onChanged: (value) {
                                if (value == null) return;
                                setDialogState(() {
                                  selectedRoom = value;
                                  room.text = value;
                                  formError = null;
                                });
                              },
                            ),
                          _field(weekStart, 'Minggu Mula', number: true),
                          _field(weekEnd, 'Minggu Tamat', number: true),
                          _dropdownField(
                            label: 'Status',
                            value: selectedStatus,
                            values: const ['active', 'inactive', 'cancelled'],
                            labelForValue: _statusLabel,
                            onChanged: (value) {
                              if (value == null) return;
                              setDialogState(() => selectedStatus = value);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        initiallyExpanded: false,
                        title: const Text(
                          'Butiran Teknikal',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text(
                          'Medan ini dikekalkan untuk keserasian rekod lama.',
                        ),
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _field(lecturerId, 'ID Pensyarah'),
                              _field(semester, 'Semester', number: true),
                              _field(date, 'Tarikh / Minggu Legacy'),
                              _field(enrolled, 'Pelajar', number: true),
                              _field(capacity, 'Kapasiti', number: true),
                              _field(classType, 'Jenis Kelas'),
                              _field(slotType, 'Jenis Slot'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final cleanSession = session.text.trim();
                final cleanProgram = selectedProgram.trim();
                final cleanSection = selectedClass.trim();
                final cleanRoom = roomOptions.isEmpty
                    ? room.text.trim()
                    : selectedRoom.trim();
                final validationError = _validateEditSlotInput(
                  programId: cleanProgram,
                  classId: cleanSection,
                  subjectCode: subjectCode.text.trim(),
                  subjectName: subjectName.text.trim(),
                  lecturerId: lecturerId.text.trim(),
                  lecturerName: lecturerName.text.trim(),
                  roomName: cleanRoom,
                  day: selectedDay,
                  startTime: startTime.text.trim(),
                  endTime: endTime.text.trim(),
                  weekStart: weekStart.text.trim(),
                  weekEnd: weekEnd.text.trim(),
                  status: selectedStatus,
                );
                if (validationError != null) {
                  dialogSetState?.call(() => formError = validationError);
                  return;
                }
                Navigator.pop(
                  context,
                  TimetableSlot(
                    id: slot.id,
                    timetableSlotId: slot.timetableSlotId,
                    academicSessionId: cleanSession.isEmpty
                        ? slot.academicSessionId
                        : cleanSession,
                    programId:
                        cleanProgram.isEmpty ? slot.programId : cleanProgram,
                    departmentId: state.programs
                            .any((program) => program.id == cleanProgram)
                        ? _programDepartmentId(state, cleanProgram)
                        : slot.departmentId,
                    classId: cleanSection.isEmpty ? slot.classId : cleanSection,
                    subjectId: selectedSubjectId ?? slot.subjectId,
                    session: cleanSession.isEmpty ? slot.session : cleanSession,
                    semester: int.tryParse(semester.text.trim()) ??
                        _semesterFromClassId(cleanSection) ??
                        slot.semester,
                    program: cleanProgram.isEmpty ? slot.program : cleanProgram,
                    section: cleanSection.isEmpty ? slot.section : cleanSection,
                    subjectCode: subjectCode.text.trim(),
                    subjectName: subjectName.text.trim(),
                    lecturerId: lecturerId.text.trim(),
                    lecturerName: lecturerName.text.trim(),
                    lecturerEmail: selectedLecturerEmail,
                    lecturerProfileId: selectedLecturerProfileId,
                    roomId: cleanRoom.isEmpty
                        ? slot.roomId
                        : _roomIdForTemplate(cleanRoom),
                    roomName: cleanRoom.isEmpty ? slot.roomName : cleanRoom,
                    day: selectedDay,
                    date: date.text.trim(),
                    dayOfWeek: selectedDay,
                    startTime: startTime.text.trim(),
                    endTime: endTime.text.trim(),
                    weekStart: weekStart.text.trim().isEmpty
                        ? slot.weekStart
                        : weekStart.text.trim(),
                    weekEnd: weekEnd.text.trim().isEmpty
                        ? slot.weekEnd
                        : weekEnd.text.trim(),
                    room: cleanRoom.isEmpty ? slot.room : cleanRoom,
                    enrolled:
                        int.tryParse(enrolled.text.trim()) ?? slot.enrolled,
                    capacity:
                        int.tryParse(capacity.text.trim()) ?? slot.capacity,
                    classType: classType.text.trim(),
                    slotType: slotType.text.trim(),
                    status: selectedStatus,
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
      subjectCode,
      subjectName,
      lecturerId,
      lecturerName,
      date,
      startTime,
      endTime,
      room,
      weekStart,
      weekEnd,
      enrolled,
      capacity,
      classType,
      slotType,
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
          width: _dialogWidth(context, maxWidth: 680),
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

  Widget _dropdownField({
    required String label,
    required String? value,
    required List<String> values,
    required ValueChanged<String?> onChanged,
    String Function(String value)? labelForValue,
    bool wide = false,
  }) {
    final cleanValues = values
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
    final options = cleanValues.toList()..sort();
    final cleanValue = value?.trim();
    final selectedValue =
        cleanValue != null && options.contains(cleanValue) ? cleanValue : null;

    return SizedBox(
      width: wide ? 452 : 220,
      child: DropdownButtonFormField<String>(
        key: ValueKey('$label-$selectedValue-${options.length}'),
        initialValue: selectedValue,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          for (final option in options)
            DropdownMenuItem<String>(
              value: option,
              child: Text(
                labelForValue?.call(option) ?? option,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: onChanged,
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

  String _programNameForTemplate(AppState state, String programId) {
    return state.programs
            .where((program) => program.id == programId)
            .firstOrNull
            ?.name ??
        programId;
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
    final scopedUser = state.users.where((user) {
      if (user.role != UserRole.pensyarah || !user.isActive) return false;
      final currentUser = state.currentUser;
      if (currentUser?.role == UserRole.ketua_jabatan) {
        return user.departmentId == currentUser!.departmentId;
      }
      if (currentUser?.role == UserRole.ketua_program) {
        return user.programId == currentUser!.programId;
      }
      return user.programId == programId;
    }).firstOrNull;
    if (scopedUser != null) {
      return Lecturer(
        id: scopedUser.uid,
        name: scopedUser.name,
        email: scopedUser.email,
        department: scopedUser.departmentId ?? '',
        subjects: const [],
      );
    }

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
                        _sessionLabel(state, session),
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
        color: AppColors.surfaceTint,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.muted,
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
                    color: AppColors.primaryDark,
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

class _ClassTimetableSecondaryAction extends StatelessWidget {
  const _ClassTimetableSecondaryAction({
    required this.enabled,
    required this.onOpen,
  });

  final bool enabled;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth - 28;
        final introWidth =
            available < 720 ? available : (available - 220).clamp(360.0, 680.0);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceTint,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: introWidth,
                  child: const _SectionIntro(
                    icon: Icons.view_week_outlined,
                    title: 'Jana / Eksport Jadual Kelas',
                    subtitle:
                        'Alat sokongan untuk menjana jadual mingguan satu kelas. Pengurusan rasmi jadual kekal di bahagian Jadual Rasmi.',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: enabled ? onOpen : null,
                  icon: const Icon(Icons.view_week_outlined),
                  label: const Text('Jana / Eksport Jadual Kelas'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderActionBar extends StatelessWidget {
  const _HeaderActionBar({
    required this.hasTimetable,
    required this.onUpload,
    required this.onExport,
    required this.onAddManual,
  });

  final bool hasTimetable;
  final VoidCallback onUpload;
  final VoidCallback onExport;
  final VoidCallback onAddManual;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionIntro(
              icon: Icons.fact_check_outlined,
              title: 'Tindakan Utama Jadual',
              subtitle:
                  'Gunakan tindakan ini untuk memuat naik, mengeksport, atau menambah slot rasmi bagi sesi akademik dipilih.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: onUpload,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Muat Naik Jadual'),
                ),
                Tooltip(
                  message:
                      'Mengeksport jadual yang sedang dipaparkan berdasarkan penapis semasa.',
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    onPressed: hasTimetable ? onExport : null,
                    icon: const Icon(Icons.ios_share),
                    label: const Text('Eksport Paparan Semasa'),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onAddManual,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Slot Manual'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionIntro extends StatelessWidget {
  const _SectionIntro({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xffeff6ff),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xff1d4ed8), size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xff0f172a),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xff64748b),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditSlotNote extends StatelessWidget {
  const _EditSlotNote({required this.conflictContext});

  final bool conflictContext;

  @override
  Widget build(BuildContext context) {
    final text = conflictContext
        ? 'Anda sedang mengemas kini slot yang mempunyai konflik. Ubah bilik, masa, hari atau pensyarah untuk menyelesaikan konflik.'
        : 'Gunakan borang ini untuk pembetulan kecil seperti bilik, masa, hari, pensyarah atau status. Untuk jadual penuh, gunakan Muat Naik Jadual.';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xfffffbeb),
        border: Border.all(color: const Color(0xfffde68a)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: Color(0xff92400e), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Color(0xff92400e), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineErrorMessage extends StatelessWidget {
  const _InlineErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xfffff1f2),
        border: Border.all(color: const Color(0xfffecdd3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: Color(0xffbe123c), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xff9f1239),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditFormSection extends StatelessWidget {
  const _EditFormSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

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
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: children,
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
    required this.selectedAcademicSession,
    required this.searchCtrl,
    required this.dayFilter,
    required this.statusFilter,
    required this.programFilter,
    required this.classFilter,
    required this.lecturerFilter,
    required this.roomFilter,
    required this.selectedViewMode,
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
    required this.onViewModeChanged,
    required this.onToggleSelectAllVisible,
    required this.onClearSelection,
    required this.onExportSelected,
    required this.onBatchInactive,
    required this.onBatchDelete,
    required this.onSelectionChanged,
    required this.onDetails,
    required this.onEdit,
    required this.onConflictEdit,
    required this.onPublishDrafts,
    required this.onDelete,
  });

  final AppState state;
  final List<TimetableSlot> slots;
  final List<TimetableSlot> allSlots;
  final String selectedAcademicSession;
  final TextEditingController searchCtrl;
  final String? dayFilter;
  final String? statusFilter;
  final String? programFilter;
  final String? classFilter;
  final String? lecturerFilter;
  final String? roomFilter;
  final _TimetableViewMode selectedViewMode;
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
  final ValueChanged<_TimetableViewMode> onViewModeChanged;
  final VoidCallback onToggleSelectAllVisible;
  final VoidCallback onClearSelection;
  final VoidCallback onExportSelected;
  final VoidCallback onBatchInactive;
  final VoidCallback onBatchDelete;
  final void Function(TimetableSlot slot, bool selected) onSelectionChanged;
  final void Function(TimetableSlot slot) onDetails;
  final void Function(TimetableSlot slot) onEdit;
  final void Function(TimetableSlot slot) onConflictEdit;
  final void Function(List<TimetableSlot> slots) onPublishDrafts;
  final void Function(TimetableSlot slot) onDelete;

  @override
  Widget build(BuildContext context) {
    final isListView = selectedViewMode == _TimetableViewMode.list;
    final emptyTitle = allSlots.isEmpty
        ? 'Tiada jadual untuk sesi akademik ini.'
        : 'Tiada jadual ditemui untuk penapis semasa.';
    final emptySubtitle = allSlots.isEmpty
        ? 'Muat naik jadual CSV untuk mula menggunakan sesi ini.'
        : 'Laraskan carian atau reset penapis untuk melihat rekod jadual.';

    if (context.isMobile) {
      return _MobileOfficialTimetableSection(
        slots: slots,
        allSlots: allSlots,
        selectedAcademicSession: selectedAcademicSession,
        searchCtrl: searchCtrl,
        dayFilter: dayFilter,
        statusFilter: statusFilter,
        programFilter: programFilter,
        classFilter: classFilter,
        lecturerFilter: lecturerFilter,
        roomFilter: roomFilter,
        selectedViewMode: selectedViewMode,
        batchProcessing: batchProcessing,
        onSearchChanged: onSearchChanged,
        onDayChanged: onDayChanged,
        onStatusChanged: onStatusChanged,
        onProgramChanged: onProgramChanged,
        onClassChanged: onClassChanged,
        onLecturerChanged: onLecturerChanged,
        onRoomChanged: onRoomChanged,
        onResetFilters: onResetFilters,
        onViewModeChanged: onViewModeChanged,
        onDetails: onDetails,
        onEdit: onEdit,
        onConflictEdit: onConflictEdit,
        onPublishDrafts: onPublishDrafts,
        onDelete: onDelete,
        emptyTitle: emptyTitle,
        emptySubtitle: emptySubtitle,
      );
    }

    return AppPanel(
      title: 'Jadual Rasmi',
      subtitle: 'Senarai slot jadual rasmi untuk sesi akademik dipilih.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OfficialTimetableStatus(
            slots: slots,
            visibleCount: slots.length,
            totalCount: allSlots.length,
            selectedAcademicSession: selectedAcademicSession,
            batchProcessing: batchProcessing,
            onPublishDrafts: onPublishDrafts,
          ),
          const SizedBox(height: 16),
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
          _ConflictReviewPanel(
            slots: slots,
            onDetails: onDetails,
            onEdit: onConflictEdit,
          ),
          const SizedBox(height: 16),
          _TimetableViewSelector(
            selectedMode: selectedViewMode,
            onChanged: onViewModeChanged,
          ),
          const SizedBox(height: 16),
          if (isListView && slots.isNotEmpty) ...[
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
          if (isListView &&
              _selectedVisibleCount(slots, selectedSlotKeys) > 0) ...[
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
          if (selectedViewMode == _TimetableViewMode.list)
            _TimetableTable(
              slots: slots,
              emptyTitle: emptyTitle,
              emptySubtitle: emptySubtitle,
              selectedSlotKeys: selectedSlotKeys,
              batchProcessing: batchProcessing,
              onSelectionChanged: onSelectionChanged,
              onDetails: onDetails,
              onEdit: onEdit,
              onDelete: onDelete,
            )
          else if (selectedViewMode == _TimetableViewMode.weekly)
            _WeeklyTimetableView(
              slots: slots,
              emptyTitle: emptyTitle,
              emptySubtitle: emptySubtitle,
              onDetails: onDetails,
            )
          else if (selectedViewMode == _TimetableViewMode.room)
            _GroupedTimetableView(
              slots: slots,
              emptyTitle: emptyTitle,
              emptySubtitle: emptySubtitle,
              mode: _TimetableViewMode.room,
              onDetails: onDetails,
            )
          else
            _GroupedTimetableView(
              slots: slots,
              emptyTitle: emptyTitle,
              emptySubtitle: emptySubtitle,
              mode: _TimetableViewMode.lecturer,
              onDetails: onDetails,
            ),
        ],
      ),
    );
  }
}

class _MobileOfficialTimetableSection extends StatelessWidget {
  const _MobileOfficialTimetableSection({
    required this.slots,
    required this.allSlots,
    required this.selectedAcademicSession,
    required this.searchCtrl,
    required this.dayFilter,
    required this.statusFilter,
    required this.programFilter,
    required this.classFilter,
    required this.lecturerFilter,
    required this.roomFilter,
    required this.selectedViewMode,
    required this.batchProcessing,
    required this.onSearchChanged,
    required this.onDayChanged,
    required this.onStatusChanged,
    required this.onProgramChanged,
    required this.onClassChanged,
    required this.onLecturerChanged,
    required this.onRoomChanged,
    required this.onResetFilters,
    required this.onViewModeChanged,
    required this.onDetails,
    required this.onEdit,
    required this.onConflictEdit,
    required this.onPublishDrafts,
    required this.onDelete,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  final List<TimetableSlot> slots;
  final List<TimetableSlot> allSlots;
  final String selectedAcademicSession;
  final TextEditingController searchCtrl;
  final String? dayFilter;
  final String? statusFilter;
  final String? programFilter;
  final String? classFilter;
  final String? lecturerFilter;
  final String? roomFilter;
  final _TimetableViewMode selectedViewMode;
  final bool batchProcessing;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onDayChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onProgramChanged;
  final ValueChanged<String?> onClassChanged;
  final ValueChanged<String?> onLecturerChanged;
  final ValueChanged<String?> onRoomChanged;
  final VoidCallback onResetFilters;
  final ValueChanged<_TimetableViewMode> onViewModeChanged;
  final void Function(TimetableSlot slot) onDetails;
  final void Function(TimetableSlot slot) onEdit;
  final void Function(TimetableSlot slot) onConflictEdit;
  final void Function(List<TimetableSlot> slots) onPublishDrafts;
  final void Function(TimetableSlot slot) onDelete;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    final summary = _TimetableStatusSummary.fromSlots(slots);
    final conflicts = _detectTimetableConflicts(slots);
    final draftCount = slots.where(_isDraftSlot).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MobileSection(
          title: 'Status Jadual',
          subtitle: summary.message,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusChip(summary.hasDrafts ? 'Draf' : 'Rasmi'),
                  StatusChip('$draftCount draf'),
                  StatusChip('${conflicts.length} konflik'),
                  StatusChip(selectedAcademicSession),
                ],
              ),
              if (summary.hasDrafts) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: batchProcessing
                      ? null
                      : () => onPublishDrafts(summary.draftSlots),
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('Terbitkan Draf'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CompactStat(
                  icon: Icons.event_note_outlined,
                  value: '${slots.length} Slot'),
              _CompactStat(
                  icon: Icons.groups_outlined,
                  value: '${_countDistinct(slots.map(_slotClassValue))} Kelas'),
              _CompactStat(
                  icon: Icons.person_outline,
                  value:
                      '${_countDistinct(slots.map((s) => s.lecturerName))} Org'),
              _CompactStat(
                icon: Icons.warning_amber_outlined,
                value: '${conflicts.length} Konflik',
                color: conflicts.isEmpty ? AppColors.success : AppColors.danger,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
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
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: MobileSegmentedControl(
            selectedIndex: selectedViewMode == _TimetableViewMode.list
                ? 0
                : selectedViewMode == _TimetableViewMode.weekly
                    ? 1
                    : selectedViewMode == _TimetableViewMode.room
                        ? 2
                        : 3,
            onChanged: (index) {
              final mode = index == 0
                  ? _TimetableViewMode.list
                  : index == 1
                      ? _TimetableViewMode.weekly
                      : index == 2
                          ? _TimetableViewMode.room
                          : _TimetableViewMode.lecturer;
              onViewModeChanged(mode);
            },
            labels: const ['Senarai', 'Mingguan', 'Bilik', 'Pensyarah'],
          ),
        ),
        const SizedBox(height: 14),
        MobileSection(
          title: selectedViewMode == _TimetableViewMode.list
              ? 'Senarai Slot'
              : selectedViewMode == _TimetableViewMode.weekly
                  ? 'Paparan Mingguan'
                  : selectedViewMode == _TimetableViewMode.room
                      ? 'Paparan Bilik'
                      : 'Paparan Pensyarah',
          subtitle: '${slots.length} slot dipaparkan.',
          child: selectedViewMode == _TimetableViewMode.list
              ? _MobileTimetableSlotList(
                  slots: slots,
                  emptyTitle: emptyTitle,
                  emptySubtitle: emptySubtitle,
                  onDetails: onDetails,
                  onEdit: onEdit,
                  onDelete: onDelete,
                )
              : selectedViewMode == _TimetableViewMode.weekly
                  ? _WeeklyTimetableView(
                      slots: slots,
                      emptyTitle: emptyTitle,
                      emptySubtitle: emptySubtitle,
                      onDetails: onDetails,
                    )
                  : _GroupedTimetableView(
                      slots: slots,
                      emptyTitle: emptyTitle,
                      emptySubtitle: emptySubtitle,
                      mode: selectedViewMode,
                      onDetails: onDetails,
                    ),
        ),
      ],
    );
  }

  int _countDistinct(Iterable<String> values) {
    return values.where((value) => value.trim().isNotEmpty).toSet().length;
  }
}

class _CompactStat extends StatelessWidget {
  const _CompactStat({
    required this.icon,
    required this.value,
    this.color = AppColors.muted,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: color == AppColors.muted ? AppColors.primaryDark : color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MobileTimetableSlotList extends StatelessWidget {
  const _MobileTimetableSlotList({
    required this.slots,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onDetails,
    required this.onEdit,
    required this.onDelete,
  });

  final List<TimetableSlot> slots;
  final String emptyTitle;
  final String emptySubtitle;
  final void Function(TimetableSlot slot) onDetails;
  final void Function(TimetableSlot slot) onEdit;
  final void Function(TimetableSlot slot) onDelete;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return MobileEmptyState(
        icon: Icons.event_busy_outlined,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return Column(
      children: [
        for (final slot in slots) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
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
                    const SizedBox(width: 8),
                    if (slot.hasConflict)
                      const StatusChip('Konflik')
                    else if (_isDraftSlot(slot))
                      const StatusChip('Draf')
                    else
                      StatusChip(_statusLabel(slot.status)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${_slotClassValue(slot)} · ${slot.day} ${slot.startTime}–${slot.endTime}',
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
                  '${_slotRoomValue(slot)} · ${_weekText(slot)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  slot.lecturerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => onDetails(slot),
                      child:
                          const Text('Butiran', style: TextStyle(fontSize: 12)),
                    ),
                    const Spacer(),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showMobileSlotActions(context, slot),
                      icon: const Icon(Icons.more_horiz, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  void _showMobileSlotActions(BuildContext context, TimetableSlot slot) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (sheetContext) => MobileBottomSheet(
        title: 'Tindakan Slot',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MobileListTile(
              icon: Icons.info_outline,
              title: 'Lihat Butiran',
              subtitle: '${slot.subjectCode} - ${slot.section}',
              onTap: () {
                Navigator.of(sheetContext).pop();
                onDetails(slot);
              },
            ),
            MobileListTile(
              icon: Icons.edit_outlined,
              title: 'Edit Slot',
              subtitle: 'Kemas kini masa, bilik atau pensyarah.',
              onTap: () {
                Navigator.of(sheetContext).pop();
                onEdit(slot);
              },
            ),
            MobileListTile(
              icon: Icons.delete_outline,
              title: 'Padam Slot',
              subtitle: 'Padam slot jadual ini.',
              iconColor: AppColors.danger,
              onTap: () {
                Navigator.of(sheetContext).pop();
                onDelete(slot);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _weekText(TimetableSlot slot) {
    final start = slot.weekStart;
    final end = slot.weekEnd;
    if (start != null && end != null) return 'Minggu $start-$end';
    if (slot.date.isNotEmpty) return slot.date;
    return 'Minggu -';
  }
}

class _OfficialTimetableStatus extends StatelessWidget {
  const _OfficialTimetableStatus({
    required this.slots,
    required this.visibleCount,
    required this.totalCount,
    required this.selectedAcademicSession,
    required this.batchProcessing,
    required this.onPublishDrafts,
  });

  final List<TimetableSlot> slots;
  final int visibleCount;
  final int totalCount;
  final String selectedAcademicSession;
  final bool batchProcessing;
  final void Function(List<TimetableSlot> slots) onPublishDrafts;

  @override
  Widget build(BuildContext context) {
    final summary = _TimetableStatusSummary.fromSlots(slots);
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth - 24;
        final introWidth =
            available < 680 ? available : (available - 330).clamp(360.0, 720.0);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceTint,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: introWidth,
                  child: _SectionIntro(
                    icon: summary.icon,
                    title: summary.title,
                    subtitle: summary.message,
                  ),
                ),
                StatusChip('$visibleCount / $totalCount slot dipaparkan'),
                StatusChip(selectedAcademicSession),
                if (summary.hasDrafts) ...[
                  StatusChip('Konflik Bilik: ${summary.roomConflicts}'),
                  StatusChip('Konflik Pensyarah: ${summary.lecturerConflicts}'),
                  StatusChip('Konflik Kelas: ${summary.classConflicts}'),
                  FilledButton.icon(
                    onPressed: batchProcessing
                        ? null
                        : () => onPublishDrafts(summary.draftSlots),
                    icon: const Icon(Icons.verified_outlined),
                    label: const Text('Terbitkan Draf'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TimetableStatusSummary {
  const _TimetableStatusSummary({
    required this.title,
    required this.message,
    required this.icon,
    required this.draftSlots,
    required this.roomConflicts,
    required this.lecturerConflicts,
    required this.classConflicts,
  });

  final String title;
  final String message;
  final IconData icon;
  final List<TimetableSlot> draftSlots;
  final int roomConflicts;
  final int lecturerConflicts;
  final int classConflicts;

  bool get hasDrafts => draftSlots.isNotEmpty;

  factory _TimetableStatusSummary.fromSlots(List<TimetableSlot> slots) {
    if (slots.isEmpty) {
      return const _TimetableStatusSummary(
        title: 'Status Jadual: Tiada Rekod',
        message: 'Tiada slot jadual untuk sesi dan penapis semasa.',
        icon: Icons.event_busy_outlined,
        draftSlots: [],
        roomConflicts: 0,
        lecturerConflicts: 0,
        classConflicts: 0,
      );
    }

    final draftSlots = slots.where(_isDraftSlot).toList();
    if (draftSlots.isEmpty) {
      return const _TimetableStatusSummary(
        title: 'Status Jadual: Rasmi',
        message:
            'Jadual ini telah diterbitkan dan boleh digunakan oleh pensyarah.',
        icon: Icons.verified_outlined,
        draftSlots: [],
        roomConflicts: 0,
        lecturerConflicts: 0,
        classConflicts: 0,
      );
    }

    final conflicts = _detectTimetableConflicts(slots);
    final roomConflicts =
        conflicts.where((item) => item.type == 'Bilik').length;
    final lecturerConflicts =
        conflicts.where((item) => item.type == 'Pensyarah').length;
    final classConflicts =
        conflicts.where((item) => item.type == 'Kelas').length;
    final hasConflicts = conflicts.isNotEmpty;

    return _TimetableStatusSummary(
      title: hasConflicts
          ? 'Status Jadual: Draf / Konflik'
          : 'Status Jadual: Draf',
      message: hasConflicts
          ? 'Jadual ini belum diterbitkan. Sila selesaikan konflik sebelum diterbitkan sebagai jadual rasmi.'
          : 'Jadual ini belum diterbitkan sebagai jadual rasmi. Semakan konflik tidak menemui konflik aktif.',
      icon: hasConflicts
          ? Icons.warning_amber_outlined
          : Icons.pending_actions_outlined,
      draftSlots: draftSlots,
      roomConflicts: roomConflicts,
      lecturerConflicts: lecturerConflicts,
      classConflicts: classConflicts,
    );
  }
}

class _TimetableViewSelector extends StatelessWidget {
  const _TimetableViewSelector({
    required this.selectedMode,
    required this.onChanged,
  });

  final _TimetableViewMode selectedMode;
  final ValueChanged<_TimetableViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      (_TimetableViewMode.list, Icons.view_list_outlined, 'Paparan Senarai'),
      (
        _TimetableViewMode.weekly,
        Icons.calendar_view_week_outlined,
        'Paparan Mingguan'
      ),
      (_TimetableViewMode.room, Icons.meeting_room_outlined, 'Paparan Bilik'),
      (
        _TimetableViewMode.lecturer,
        Icons.person_search_outlined,
        'Paparan Pensyarah'
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          ChoiceChip(
            avatar: Icon(item.$2, size: 18),
            label: Text(item.$3),
            selected: selectedMode == item.$1,
            onSelected: (_) => onChanged(item.$1),
            labelStyle: TextStyle(
              fontWeight: FontWeight.w800,
              color: selectedMode == item.$1
                  ? const Color(0xff0f172a)
                  : const Color(0xff475569),
            ),
          ),
      ],
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
    final programContext = _contextSlots(includeProgram: false);
    final classContext = _contextSlots(includeClass: false);
    final lecturerContext = _contextSlots(includeLecturer: false);
    final roomContext = _contextSlots(includeRoom: false);
    const days = [
      'Isnin',
      'Selasa',
      'Rabu',
      'Khamis',
      'Jumaat',
      'Sabtu',
      'Ahad',
    ];
    final statuses = [
      ..._distinct(slots.map((slot) => slot.status)),
      if (slots.any((slot) => slot.hasConflict)) 'conflict_pending',
    ];
    final programs = _distinct(programContext.map(_slotProgramValue));
    final classes = _distinct(classContext.map(_slotClassValue));
    final lecturers =
        _distinct(lecturerContext.map((slot) => slot.lecturerName));
    final rooms = _distinct(roomContext.map(_slotRoomValue));

    if (context.isMobile) {
      final activeFilters = [
        dayFilter,
        statusFilter,
        programFilter,
        classFilter,
        lecturerFilter,
        roomFilter
      ].where((f) => f != null).length;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchCtrl,
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Cari jadual',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
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
                          label: 'Program',
                          value: programFilter,
                          values: programs,
                          width: double.infinity,
                          labelForValue: _shortProgramLabel,
                          onChanged: (v) {
                            onProgramChanged(v);
                            Navigator.pop(sheetContext);
                          },
                        ),
                        const SizedBox(height: 12),
                        _FilterDropdown(
                          label: 'Kelas',
                          value: classFilter,
                          values: classes,
                          width: double.infinity,
                          onChanged: (v) {
                            onClassChanged(v);
                            Navigator.pop(sheetContext);
                          },
                        ),
                        const SizedBox(height: 12),
                        _FilterDropdown(
                          label: 'Pensyarah',
                          value: lecturerFilter,
                          values: lecturers,
                          width: double.infinity,
                          onChanged: (v) {
                            onLecturerChanged(v);
                            Navigator.pop(sheetContext);
                          },
                        ),
                        const SizedBox(height: 12),
                        _FilterDropdown(
                          label: 'Bilik',
                          value: roomFilter,
                          values: rooms,
                          width: double.infinity,
                          onChanged: (v) {
                            onRoomChanged(v);
                            Navigator.pop(sheetContext);
                          },
                        ),
                        const SizedBox(height: 12),
                        _FilterDropdown(
                          label: 'Hari',
                          value: dayFilter,
                          values: days,
                          width: double.infinity,
                          onChanged: (v) {
                            onDayChanged(v);
                            Navigator.pop(sheetContext);
                          },
                        ),
                        const SizedBox(height: 12),
                        _FilterDropdown(
                          label: 'Status',
                          value: statusFilter,
                          values: statuses,
                          width: double.infinity,
                          labelForValue: _statusLabel,
                          onChanged: (v) {
                            onStatusChanged(v);
                            Navigator.pop(sheetContext);
                          },
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: () {
                            onResetFilters();
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
              label:
                  Text(activeFilters > 0 ? 'Tapis ($activeFilters)' : 'Tapis'),
            ),
          ],
        ),
      );
    }

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
            color: AppColors.surfaceTint,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(18),
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

  List<TimetableSlot> _contextSlots({
    bool includeProgram = true,
    bool includeClass = true,
    bool includeLecturer = true,
    bool includeRoom = true,
  }) {
    return slots.where((slot) {
      if (includeProgram &&
          programFilter != null &&
          _slotProgramValue(slot) != programFilter) {
        return false;
      }
      if (includeClass &&
          classFilter != null &&
          _slotClassValue(slot) != classFilter) {
        return false;
      }
      if (includeLecturer &&
          lecturerFilter != null &&
          slot.lecturerName != lecturerFilter) {
        return false;
      }
      if (includeRoom &&
          roomFilter != null &&
          _slotRoomValue(slot) != roomFilter) {
        return false;
      }
      if (dayFilter != null && slot.day != dayFilter) return false;
      if (statusFilter != null && slot.status != statusFilter) return false;
      return true;
    }).toList();
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
    final effectiveValue =
        value != null && values.contains(value) ? value : null;
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String?>(
        key: ValueKey('$label-${effectiveValue ?? 'all'}-${values.length}'),
        initialValue: effectiveValue,
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
          value: _count(slots.map(_slotProgramValue)),
          icon: Icons.school_outlined,
        ),
        _CoverageTile(
          label: 'Kelas',
          value: _count(slots.map(_slotClassValue)),
          icon: Icons.groups_outlined,
        ),
        _CoverageTile(
          label: 'Pensyarah',
          value: _count(slots.map((slot) => slot.lecturerName)),
          icon: Icons.person_outline,
        ),
        _CoverageTile(
          label: 'Bilik',
          value: _count(slots.map(_slotRoomValue)),
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

class _WeeklyTimetableView extends StatelessWidget {
  const _WeeklyTimetableView({
    required this.slots,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onDetails,
  });

  final List<TimetableSlot> slots;
  final String emptyTitle;
  final String emptySubtitle;
  final void Function(TimetableSlot slot) onDetails;

  static const _weekdayOrder = [
    'Isnin',
    'Selasa',
    'Rabu',
    'Khamis',
    'Jumaat',
    'Sabtu',
    'Ahad',
  ];

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return _EmptyState(
        icon: Icons.calendar_view_week_outlined,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    final days = _visibleDays(slots);
    final timeBlocks = _timeBlocks(slots);
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final timeWidth = available < 520 ? 104.0 : 124.0;
        final dayWidth = available >= 1180
            ? ((available - timeWidth) / days.length).clamp(190.0, 238.0)
            : available >= 760
                ? 206.0
                : 190.0;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints:
                BoxConstraints(minWidth: timeWidth + (days.length * dayWidth)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WeeklyHeaderCell(label: 'Masa', width: timeWidth),
                    for (final day in days)
                      _WeeklyHeaderCell(label: day, width: dayWidth),
                  ],
                ),
                for (final block in timeBlocks)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _WeeklyTimeCell(block: block, width: timeWidth),
                        for (final day in days)
                          _WeeklySlotCell(
                            width: dayWidth,
                            slots: _slotsForBlock(slots, day, block),
                            onDetails: onDetails,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<String> _visibleDays(List<TimetableSlot> slots) {
    final used = slots.map((slot) => slot.day.trim()).toSet();
    final days =
        _weekdayOrder.where((day) => used.contains(day)).toList(growable: true);
    final extraDays = used.where((day) => !days.contains(day)).toList()..sort();
    days.addAll(extraDays);
    return days;
  }

  List<String> _timeBlocks(List<TimetableSlot> slots) {
    final blocks = slots
        .map((slot) => '${slot.startTime}-${slot.endTime}')
        .where((value) => value.trim() != '-')
        .toSet()
        .toList()
      ..sort((a, b) => _timeSortValue(a).compareTo(_timeSortValue(b)));
    return blocks;
  }

  List<TimetableSlot> _slotsForBlock(
    List<TimetableSlot> slots,
    String day,
    String block,
  ) {
    final matches = slots
        .where((slot) =>
            slot.day == day && '${slot.startTime}-${slot.endTime}' == block)
        .toList()
      ..sort(_compareSlots);
    return matches;
  }

  int _timeSortValue(String block) {
    final start = block.split('-').first;
    return _minutesFromTime(start);
  }
}

class _WeeklyHeaderCell extends StatelessWidget {
  const _WeeklyHeaderCell({
    required this.label,
    this.width = 220,
  });

  final String label;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xffe2e8f0),
        border: Border.all(color: const Color(0xffcbd5e1)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xff0f172a),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _WeeklyTimeCell extends StatelessWidget {
  const _WeeklyTimeCell({
    required this.block,
    required this.width,
  });

  final String block;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 124),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: Text(
        block,
        style: const TextStyle(
          color: Color(0xff334155),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _WeeklySlotCell extends StatelessWidget {
  const _WeeklySlotCell({
    required this.width,
    required this.slots,
    required this.onDetails,
  });

  final double width;
  final List<TimetableSlot> slots;
  final void Function(TimetableSlot slot) onDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 124),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: slots.isEmpty
          ? const Center(
              child: Text(
                '-',
                style: TextStyle(color: Color(0xff94a3b8)),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final slot in slots) ...[
                  _MiniTimetableSlotCard(
                    slot: slot,
                    onTap: () => onDetails(slot),
                    showDayTime: false,
                    trailingRoom: true,
                  ),
                  if (slot != slots.last) const SizedBox(height: 6),
                ],
              ],
            ),
    );
  }
}

class _GroupedTimetableView extends StatelessWidget {
  const _GroupedTimetableView({
    required this.slots,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.mode,
    required this.onDetails,
  });

  final List<TimetableSlot> slots;
  final String emptyTitle;
  final String emptySubtitle;
  final _TimetableViewMode mode;
  final void Function(TimetableSlot slot) onDetails;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return _EmptyState(
        icon: mode == _TimetableViewMode.room
            ? Icons.meeting_room_outlined
            : Icons.person_search_outlined,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    final grouped = _groupSlots(slots);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in grouped.entries) ...[
          _GroupedTimetableCard(
            title: entry.key,
            mode: mode,
            slots: entry.value,
            onDetails: onDetails,
          ),
          if (entry.key != grouped.keys.last) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Map<String, List<TimetableSlot>> _groupSlots(List<TimetableSlot> slots) {
    final grouped = <String, List<TimetableSlot>>{};
    for (final slot in slots) {
      final key = mode == _TimetableViewMode.room
          ? _slotRoomValue(slot)
          : slot.lecturerName.trim();
      grouped.putIfAbsent(key.isEmpty ? '-' : key, () => []).add(slot);
    }
    final sortedKeys = grouped.keys.toList()..sort();
    return {
      for (final key in sortedKeys) key: (grouped[key]!..sort(_compareSlots)),
    };
  }
}

class _GroupedTimetableCard extends StatelessWidget {
  const _GroupedTimetableCard({
    required this.title,
    required this.mode,
    required this.slots,
    required this.onDetails,
  });

  final String title;
  final _TimetableViewMode mode;
  final List<TimetableSlot> slots;
  final void Function(TimetableSlot slot) onDetails;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(mobile ? 12 : 8),
      ),
      child: Padding(
        padding: EdgeInsets.all(mobile ? 10 : 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth >= 980
                ? (constraints.maxWidth - 20) / 3
                : constraints.maxWidth >= 640
                    ? (constraints.maxWidth - 10) / 2
                    : constraints.maxWidth;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      mode == _TimetableViewMode.room
                          ? Icons.meeting_room_outlined
                          : Icons.person_outline,
                      color: AppColors.primaryDark,
                      size: mobile ? 18 : 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Tooltip(
                        message: title,
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: mobile ? 14 : 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusChip('${slots.length} slot'),
                  ],
                ),
                SizedBox(height: mobile ? 8 : 10),
                Wrap(
                  spacing: mobile ? 8 : 10,
                  runSpacing: mobile ? 8 : 10,
                  children: [
                    for (final slot in slots)
                      SizedBox(
                        width: cardWidth,
                        child: _MiniTimetableSlotCard(
                          slot: slot,
                          onTap: () => onDetails(slot),
                          showDayTime: true,
                          trailingRoom: mode == _TimetableViewMode.lecturer,
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MiniTimetableSlotCard extends StatelessWidget {
  const _MiniTimetableSlotCard({
    required this.slot,
    required this.onTap,
    required this.showDayTime,
    required this.trailingRoom,
  });

  final TimetableSlot slot;
  final VoidCallback onTap;
  final bool showDayTime;
  final bool trailingRoom;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    final contextLine = trailingRoom
        ? '${_slotClassValue(slot)} - ${slot.day} ${slot.startTime}-${slot.endTime}'
        : '${_slotClassValue(slot)} - ${slot.day} ${slot.startTime}-${slot.endTime}';
    final supportingLine =
        trailingRoom ? slot.lecturerName : _slotRoomValue(slot);
    final active = slot.status.toLowerCase() == 'active';
    return Tooltip(
      message:
          '${slot.subjectCode}\n${slot.subjectName}\n$contextLine\n$supportingLine',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(mobile ? 12 : 8),
        child: Container(
          padding: EdgeInsets.all(mobile ? 10 : 10),
          decoration: BoxDecoration(
            color: active ? AppColors.surface : AppColors.surfaceTint,
            border: Border.all(
              color: active
                  ? AppColors.border
                  : AppColors.muted.withValues(alpha: .35),
            ),
            borderRadius: BorderRadius.circular(mobile ? 12 : 8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      slot.subjectCode,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (!active)
                    Text(
                      _statusLabel(slot.status),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                slot.subjectName,
                maxLines: mobile ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: mobile ? 12 : 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: mobile ? 7 : 6),
              Text(
                contextLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                trailingRoom
                    ? 'Pensyarah: $supportingLine'
                    : 'Bilik: $supportingLine',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConflictReviewPanel extends StatelessWidget {
  const _ConflictReviewPanel({
    required this.slots,
    required this.onDetails,
    required this.onEdit,
  });

  final List<TimetableSlot> slots;
  final void Function(TimetableSlot slot) onDetails;
  final void Function(TimetableSlot slot) onEdit;

  @override
  Widget build(BuildContext context) {
    final conflicts = _detectTimetableConflicts(slots);
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

  void _showConflictDetails(
    BuildContext context,
    List<_TimetableConflict> conflicts,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final screenHeight = MediaQuery.sizeOf(dialogContext).height;
        final contentHeight =
            (screenHeight - 220).clamp(260.0, 640.0).toDouble();
        return AlertDialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          title: const Text('Butiran Konflik Jadual'),
          content: SizedBox(
            width: _dialogWidth(dialogContext, maxWidth: 800),
            height: contentHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${conflicts.length} konflik dikesan. Klik "Edit Slot" untuk mengubah slot yang berkonflik.',
                  style: const TextStyle(
                    color: Color(0xff475569),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final conflict in conflicts) ...[
                          _ConflictCard(
                            conflict: conflict,
                            onDetails: (slot) {
                              Navigator.pop(dialogContext);
                              onDetails(slot);
                            },
                            onEdit: (slot) {
                              Navigator.pop(dialogContext);
                              onEdit(slot);
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
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

  String get displayValue {
    if (type == 'Pensyarah') {
      final nameA = a.lecturerName.trim();
      final nameB = b.lecturerName.trim();
      if (nameA.isNotEmpty) return nameA;
      if (nameB.isNotEmpty) return nameB;
      return 'Pensyarah tidak dikenal pasti';
    }
    if (type == 'Bilik') {
      final roomA = _slotRoomValue(a);
      final roomB = _slotRoomValue(b);
      if (roomA.isNotEmpty) return roomA;
      if (roomB.isNotEmpty) return roomB;
    }
    if (type == 'Kelas') {
      final classA = _slotClassValue(a);
      final classB = _slotClassValue(b);
      if (classA.isNotEmpty) return classA;
      if (classB.isNotEmpty) return classB;
    }
    return value;
  }
}

List<_TimetableConflict> _detectTimetableConflicts(List<TimetableSlot> slots) {
  final activeSlots = slots.where(_isTimetableConflictRelevant).toList();
  final conflicts = <_TimetableConflict>[];
  for (var i = 0; i < activeSlots.length; i++) {
    for (var j = i + 1; j < activeSlots.length; j++) {
      final a = activeSlots[i];
      final b = activeSlots[j];
      if (!_sameTimetableScheduleWindow(a, b)) continue;
      _addTimetableConflictIfSame(
        conflicts,
        type: 'Bilik',
        valueA: a.roomId ?? a.room,
        valueB: b.roomId ?? b.room,
        slotA: a,
        slotB: b,
      );
      _addTimetableConflictIfSame(
        conflicts,
        type: 'Pensyarah',
        valueA: a.lecturerId,
        valueB: b.lecturerId,
        slotA: a,
        slotB: b,
      );
      _addTimetableConflictIfSame(
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

bool _isTimetableConflictRelevant(TimetableSlot slot) {
  final status = slot.status.toLowerCase();
  return status != 'inactive' && status != 'cancelled' && status != 'canceled';
}

void _addTimetableConflictIfSame(
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

bool _sameTimetableScheduleWindow(TimetableSlot a, TimetableSlot b) {
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

class _ConflictCard extends StatelessWidget {
  const _ConflictCard({
    required this.conflict,
    required this.onDetails,
    required this.onEdit,
  });

  final _TimetableConflict conflict;
  final void Function(TimetableSlot slot) onDetails;
  final void Function(TimetableSlot slot) onEdit;

  @override
  Widget build(BuildContext context) {
    final slot = conflict.a;
    final typeLabel = switch (conflict.type) {
      'Bilik' => 'Konflik Bilik',
      'Pensyarah' => 'Konflik Pensyarah',
      'Kelas' => 'Konflik Kelas',
      _ => 'Konflik ${conflict.type}',
    };
    final typeIcon = switch (conflict.type) {
      'Bilik' => Icons.meeting_room_outlined,
      'Pensyarah' => Icons.person_outline,
      'Kelas' => Icons.groups_outlined,
      _ => Icons.warning_amber_outlined,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xfffffbeb),
        border: Border.all(color: const Color(0xfffde68a)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(typeIcon, size: 18, color: const Color(0xff92400e)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$typeLabel: ${conflict.displayValue}',
                    style: const TextStyle(
                      color: Color(0xff92400e),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xfffef3c7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${slot.day} - ${slot.startTime}-${slot.endTime} - Minggu ${_weekTextForSlot(slot)}',
                style: const TextStyle(
                  color: Color(0xff78350f),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Slot yang berkonflik:',
              style: TextStyle(
                color: Color(0xff475569),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _ConflictSlotCard(
              slot: conflict.a,
              onDetails: onDetails,
              onEdit: onEdit,
            ),
            const SizedBox(height: 8),
            _ConflictSlotCard(
              slot: conflict.b,
              onDetails: onDetails,
              onEdit: onEdit,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConflictSlotCard extends StatelessWidget {
  const _ConflictSlotCard({
    required this.slot,
    required this.onDetails,
    required this.onEdit,
  });

  final TimetableSlot slot;
  final void Function(TimetableSlot slot) onDetails;
  final void Function(TimetableSlot slot) onEdit;

  @override
  Widget build(BuildContext context) {
    final programLabel = slot.programId?.isNotEmpty == true
        ? slot.programId!
        : _shortProgramLabel(slot.program);
    final classLabel =
        slot.classId?.isNotEmpty == true ? slot.classId! : slot.section;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xffffffff),
        border: Border.all(color: const Color(0xffe2e8f0)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  slot.subjectCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Color(0xff0f172a),
                  ),
                ),
                Text(
                  slot.subjectName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xff334155),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _SlotInfoChip(
                  icon: Icons.groups_outlined,
                  label: '$programLabel  $classLabel',
                ),
                _SlotInfoChip(
                  icon: Icons.person_outline,
                  label: slot.lecturerName,
                ),
                _SlotInfoChip(
                  icon: Icons.meeting_room_outlined,
                  label: slot.room,
                ),
                _SlotInfoChip(
                  icon: Icons.schedule_outlined,
                  label: '${slot.day} ${slot.startTime}-${slot.endTime}',
                ),
                _SlotInfoChip(
                  icon: Icons.date_range_outlined,
                  label: 'Minggu ${_weekTextForSlot(slot)}',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                SizedBox(
                  height: 30,
                  child: OutlinedButton.icon(
                    onPressed: () => onDetails(slot),
                    icon: const Icon(Icons.info_outline, size: 14),
                    label: const Text('Lihat Butiran',
                        style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                SizedBox(
                  height: 30,
                  child: FilledButton.icon(
                    onPressed: () => onEdit(slot),
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label:
                        const Text('Edit Slot', style: TextStyle(fontSize: 12)),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotInfoChip extends StatelessWidget {
  const _SlotInfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xff64748b)),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xff475569),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _UploadWorkflowSection extends StatelessWidget {
  const _UploadWorkflowSection({
    required this.selectedAcademicSession,
    required this.processingImport,
    required this.importError,
    required this.previewResult,
    required this.previewConflicts,
    required this.previewFileName,
    required this.lastImportResult,
    required this.importing,
    required this.canImportPreview,
    required this.canSaveDraftPreview,
    required this.onPickFile,
    required this.onDownloadTemplate,
    required this.onClearPreview,
    required this.onSaveDraftPreview,
    required this.onImportPreview,
    required this.onViewOfficialTimetable,
  });

  final String selectedAcademicSession;
  final bool processingImport;
  final String? importError;
  final TimetableMasterValidationResult? previewResult;
  final TimetablePreviewConflictSummary previewConflicts;
  final String? previewFileName;
  final TimetableImportWriteResult? lastImportResult;
  final bool importing;
  final bool canImportPreview;
  final bool canSaveDraftPreview;
  final VoidCallback onPickFile;
  final VoidCallback onDownloadTemplate;
  final VoidCallback onClearPreview;
  final VoidCallback onSaveDraftPreview;
  final VoidCallback onImportPreview;
  final VoidCallback onViewOfficialTimetable;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _UploadStepCard(
          stepNumber: 1,
          title: 'Muat Naik Fail CSV',
          subtitle:
              'Muat naik fail CSV jadual rasmi mengikut format yang ditetapkan.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SelectedFileStatus(fileName: previewFileName),
              const SizedBox(height: 12),
              _UploadActions(
                processingImport: processingImport,
                onDownloadTemplate: onDownloadTemplate,
                onPickFile: onPickFile,
              ),
              const SizedBox(height: 12),
              _TemplateHelper(selectedAcademicSession: selectedAcademicSession),
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
          _PreviewSummary(
            result: previewResult!,
            conflicts: previewConflicts,
          ),
          const SizedBox(height: 16),
          _ValidationIssuePanel(
            result: previewResult!,
            conflicts: previewConflicts,
          ),
          const SizedBox(height: 16),
          _UploadStepCard(
            stepNumber: 3,
            title: 'Senarai Isu Validasi',
            subtitle:
                'Semak baris ralat, amaran, pendua dan luar skop sebelum import.',
            child: _ValidationIssueList(
              result: previewResult!,
              conflicts: previewConflicts,
            ),
          ),
          const SizedBox(height: 16),
          _UploadStepCard(
            stepNumber: 4,
            title: 'Import Jadual',
            subtitle:
                'Import hanya baris yang layak. Baris ralat, pendua atau luar skop tidak akan dimasukkan sebagai slot rasmi.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ImportActionPanel(
                  result: previewResult!,
                  conflicts: previewConflicts,
                  importing: importing,
                  canImportPreview: canImportPreview,
                  canSaveDraftPreview: canSaveDraftPreview,
                  onClearPreview: onClearPreview,
                  onSaveDraftPreview: onSaveDraftPreview,
                  onImportPreview: onImportPreview,
                ),
                const SizedBox(height: 16),
                AppPanel(
                  title: 'Pratonton CSV',
                  subtitle:
                      '${previewResult!.totalRows} baris daripada ${previewFileName ?? 'fail dipilih'}',
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 430),
                    child: SingleChildScrollView(
                      child: _PreviewTable(rows: previewResult!.previewRows),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (lastImportResult != null)
          _UploadStepCard(
            stepNumber: 5,
            title: 'Keputusan Import',
            subtitle:
                'Semak ringkasan import sebelum kembali ke Jadual Rasmi atau Sejarah Import.',
            child: _ImportSuccessPanel(
              result: lastImportResult!,
              onViewOfficialTimetable: onViewOfficialTimetable,
            ),
          ),
      ],
    );
  }
}

class _UploadStepCard extends StatelessWidget {
  const _UploadStepCard({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final int stepNumber;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xffffffff),
        border: Border.all(color: const Color(0xffe2e8f0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xff1d4ed8),
                  child: Text(
                    '$stepNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xff0f172a),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xff64748b),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _SelectedFileStatus extends StatelessWidget {
  const _SelectedFileStatus({required this.fileName});

  final String? fileName;

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName?.trim().isNotEmpty == true;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: hasFile ? const Color(0xffecfdf5) : const Color(0xfff8fafc),
        border: Border.all(
          color: hasFile ? const Color(0xffbbf7d0) : const Color(0xffe2e8f0),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              hasFile ? Icons.description_outlined : Icons.upload_file_outlined,
              color:
                  hasFile ? const Color(0xff166534) : const Color(0xff64748b),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasFile ? fileName! : 'Belum ada fail dipilih.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: hasFile
                      ? const Color(0xff166534)
                      : const Color(0xff475569),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
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
          width: _dialogWidth(context, maxWidth: 680),
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
        OutlinedButton.icon(
          onPressed: onDownloadTemplate,
          icon: const Icon(Icons.file_download_outlined),
          label: const Text('Muat Turun Templat CSV'),
        ),
        FilledButton.icon(
          onPressed: processingImport ? null : onPickFile,
          icon: const Icon(Icons.upload_file),
          label: Text(processingImport ? 'Memproses...' : 'Pilih Fail CSV'),
        ),
      ],
    );
  }
}

class _TemplateHelper extends StatelessWidget {
  const _TemplateHelper({required this.selectedAcademicSession});

  final String selectedAcademicSession;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      initiallyExpanded: false,
      title: const Text(
        'Panduan Format CSV',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: const Text('Klik untuk melihat header dan syarat format.'),
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
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const _InfoPill('CSV sahaja'),
              const _InfoPill('Excel: eksport sebagai CSV'),
              const _InfoPill('Minggu: 1-18'),
              _InfoPill('Sesi: $selectedAcademicSession'),
              const _InfoPill('Hari: Isnin-Ahad'),
              const _InfoPill('Masa: HH:mm'),
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
  const _PreviewSummary({
    required this.result,
    required this.conflicts,
  });

  final TimetableMasterValidationResult result;
  final TimetablePreviewConflictSummary conflicts;

  @override
  Widget build(BuildContext context) {
    final hasCriticalErrors = !result.canImport;
    final officialRows = !hasCriticalErrors && !conflicts.hasConflicts
        ? result.importableRows
        : 0;
    final draftableRows = hasCriticalErrors ? 0 : result.importableRows;
    final subtitle = hasCriticalErrors
        ? 'Terdapat ralat kritikal. Sila betulkan format, skop atau data rujukan sebelum import.'
        : conflicts.hasConflicts
            ? 'Fail ini sah dari segi format dan skop, tetapi mempunyai konflik jadual. Anda boleh simpan sebagai draf untuk disemak.'
            : 'Fail sah dan tiada konflik dikesan. Jadual boleh diterbitkan sebagai jadual rasmi.';
    return AppPanel(
      title: 'Pratonton & Validasi',
      subtitle: subtitle,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _SummaryTile(
              'Jumlah Baris', result.totalRows, const Color(0xff334155)),
          _SummaryTile('Sah', result.validRows, const Color(0xff166534)),
          _SummaryTile(
              'Ralat Kritikal', result.errorRows, const Color(0xff991b1b)),
          _SummaryTile('Konflik Bilik', conflicts.roomConflicts,
              const Color(0xff7c2d12)),
          _SummaryTile('Konflik Pensyarah', conflicts.lecturerConflicts,
              const Color(0xff92400e)),
          _SummaryTile('Konflik Kelas', conflicts.classConflicts,
              const Color(0xff991b1b)),
          _SummaryTile(
              'Baris Boleh Draf', draftableRows, const Color(0xff0f766e)),
          _SummaryTile('Baris Boleh Terbit Rasmi', officialRows,
              const Color(0xff1d4ed8)),
        ],
      ),
    );
  }
}

class _ValidationIssuePanel extends StatelessWidget {
  const _ValidationIssuePanel({
    required this.result,
    required this.conflicts,
  });

  final TimetableMasterValidationResult result;
  final TimetablePreviewConflictSummary conflicts;

  @override
  Widget build(BuildContext context) {
    final outOfScopeRows = result.previewRows
        .where((row) => row.errors.any(_isValidationScopeMessage))
        .length;
    if (outOfScopeRows > 0 && outOfScopeRows == result.previewRows.length) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xfffff1f2),
          border: Border.all(color: const Color(0xfffecdd3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _ValidationLegendChip(
            icon: Icons.block_outlined,
            label: 'Luar Skop',
            description:
                'Fail ini tidak boleh diimport oleh skop pengguna semasa',
            color: const Color(0xffb91c1c),
            count: outOfScopeRows,
          ),
        ),
      );
    }

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
          children: [
            _ValidationLegendChip(
              icon: Icons.check_circle_outline,
              label: 'Sah',
              description: 'Boleh diimport',
              color: const Color(0xff166534),
              count: result.validRows,
            ),
            _ValidationLegendChip(
              icon: Icons.warning_amber_outlined,
              label: 'Amaran',
              description: 'Boleh diimport dengan perhatian',
              color: const Color(0xff92400e),
              count: result.warningRows,
            ),
            _ValidationLegendChip(
              icon: Icons.error_outline,
              label: 'Ralat',
              description: 'Tidak akan diimport',
              color: const Color(0xff991b1b),
              count: result.errorRows,
            ),
            _ValidationLegendChip(
              icon: Icons.content_copy_outlined,
              label: 'Pendua',
              description: 'Dilangkau',
              color: const Color(0xff7c2d12),
              count: result.duplicateRows,
            ),
            _ValidationLegendChip(
              icon: Icons.warning_amber_outlined,
              label: 'Konflik',
              description: 'Boleh draf, tidak boleh rasmi',
              color: const Color(0xffb45309),
              count: conflicts.total,
            ),
          ],
        ),
      ),
    );
  }
}

class _ValidationLegendChip extends StatelessWidget {
  const _ValidationLegendChip({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.count,
  });

  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label: $count',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff475569),
                    fontSize: 11,
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

class _ValidationIssueList extends StatelessWidget {
  const _ValidationIssueList({
    required this.result,
    required this.conflicts,
  });

  final TimetableMasterValidationResult result;
  final TimetablePreviewConflictSummary conflicts;

  @override
  Widget build(BuildContext context) {
    final critical = <_ValidationIssueEntry>[
      for (final message in result.validationErrors)
        if (!_isScopeMessage(message) && !_isMasterDataMessage(message))
          _ValidationIssueEntry.file(message),
      for (final row in result.previewRows)
        for (final message in row.errors)
          if (!_rowHasScopeError(row) &&
              !_isScopeMessage(message) &&
              !_isMasterDataMessage(message))
            _ValidationIssueEntry.row(row.rowNumber, message),
    ];
    final scope = <_ValidationIssueEntry>[
      for (final message in result.validationErrors)
        if (_isScopeMessage(message)) _ValidationIssueEntry.file(message),
      for (final message in result.validationWarnings)
        if (_isScopeMessage(message)) _ValidationIssueEntry.file(message),
      for (final row in result.previewRows)
        for (final message in row.errors)
          if (_isScopeMessage(message))
            _ValidationIssueEntry.row(row.rowNumber, message),
    ];
    final masterData = <_ValidationIssueEntry>[
      for (final row in result.previewRows)
        for (final message in row.errors)
          if (!_rowHasScopeError(row) && _isMasterDataMessage(message))
            _ValidationIssueEntry.row(row.rowNumber, message),
      for (final row in result.previewRows)
        for (final message in row.warnings)
          if (!_rowHasScopeError(row) && _isMasterDataMessage(message))
            _ValidationIssueEntry.row(row.rowNumber, message),
    ];
    final warnings = <_ValidationIssueEntry>[
      for (final message in result.validationWarnings)
        if (!_isScopeMessage(message) && !_isMasterDataMessage(message))
          _ValidationIssueEntry.file(message),
      for (final row in result.previewRows)
        for (final message in row.warnings)
          if (!_rowHasScopeError(row) && !_isMasterDataMessage(message))
            _ValidationIssueEntry.row(row.rowNumber, message),
    ];
    final duplicates = [
      for (final row in result.previewRows)
        if (!_rowHasScopeError(row) &&
            row.status == TimetableImportRowStatus.duplicate)
          _ValidationIssueEntry.row(
            row.rowNumber,
            'Baris ini pendua dan akan dilangkau semasa import.',
          ),
    ];
    final conflictEntries = [
      for (final conflict in conflicts.conflicts)
        _ValidationIssueEntry.file(_conflictMessage(conflict)),
    ];

    final hasIssues = critical.isNotEmpty ||
        warnings.isNotEmpty ||
        scope.isNotEmpty ||
        masterData.isNotEmpty ||
        duplicates.isNotEmpty ||
        conflictEntries.isNotEmpty;

    if (!hasIssues) {
      return const _EmptyState(
        icon: Icons.verified_outlined,
        title: 'Tiada ralat validasi dikesan.',
        subtitle: 'Semua baris yang dipaparkan boleh diteruskan ke import.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (critical.isNotEmpty) ...[
          _ValidationIssueGroup(
            title: 'Ralat Kritikal',
            emptyText: 'Tiada ralat kritikal.',
            color: const Color(0xff991b1b),
            entries: critical,
          ),
          const SizedBox(height: 12),
        ],
        if (scope.isNotEmpty) ...[
          _ValidationIssueGroup(
            title: 'Luar Skop',
            emptyText: 'Tiada baris luar skop.',
            color: const Color(0xffb91c1c),
            entries: _dedupeIssueEntries(scope),
          ),
          const SizedBox(height: 12),
        ],
        if (warnings.isNotEmpty) ...[
          _ValidationIssueGroup(
            title: 'Amaran',
            emptyText: 'Tiada amaran.',
            color: const Color(0xff92400e),
            entries: warnings,
          ),
          const SizedBox(height: 12),
        ],
        if (masterData.isNotEmpty) ...[
          _ValidationIssueGroup(
            title: 'Master Data',
            emptyText: 'Tiada isu master data.',
            color: const Color(0xff1d4ed8),
            entries: masterData,
          ),
          const SizedBox(height: 12),
        ],
        if (duplicates.isNotEmpty) ...[
          _ValidationIssueGroup(
            title: 'Pendua',
            emptyText: 'Tiada baris pendua.',
            color: const Color(0xff7c2d12),
            entries: duplicates,
          ),
          const SizedBox(height: 12),
        ],
        if (conflictEntries.isNotEmpty) ...[
          _ValidationIssueGroup(
            title: 'Amaran Konflik',
            emptyText: 'Tiada konflik jadual.',
            color: const Color(0xffb45309),
            entries: conflictEntries,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  String _conflictMessage(TimetablePreviewConflict conflict) {
    final typeLabel = switch (conflict.type) {
      'room' => 'Konflik Bilik',
      'lecturer' => 'Konflik Pensyarah',
      'class' => 'Konflik Kelas',
      _ => 'Konflik Jadual',
    };
    final rows = conflict.previewRowNumbers.isEmpty
        ? '-'
        : conflict.previewRowNumbers.map((row) => 'Baris $row').join(', ');
    final existing = conflict.involvesExistingSlot
        ? ' Bertembung dengan jadual sedia ada.'
        : '';
    return '$rows - $typeLabel: ${conflict.target}. '
        '${conflict.dayOfWeek} ${conflict.startTime}-${conflict.endTime}, '
        'Minggu ${conflict.weekStart}-${conflict.weekEnd}. '
        'Kelas: ${conflict.classSummary}. Pensyarah: ${conflict.lecturerSummary}. '
        'Bilik: ${conflict.roomSummary}.$existing';
  }

  bool _rowHasScopeError(TimetablePreviewRow row) {
    return row.errors.any(_isScopeMessage);
  }

  List<_ValidationIssueEntry> _dedupeIssueEntries(
    List<_ValidationIssueEntry> entries,
  ) {
    final seen = <String>{};
    return [
      for (final entry in entries)
        if (seen.add('${entry.rowNumber ?? 'file'}:${entry.message}')) entry,
    ];
  }

  bool _isScopeMessage(String message) {
    return _isValidationScopeMessage(message);
  }

  bool _isMasterDataMessage(String message) {
    final text = message.toLowerCase();
    return text.contains('programid') ||
        text.contains('lectureremail') ||
        text.contains('roomid') ||
        text.contains('subjectid') ||
        text.contains('classid') ||
        text.contains('academic session') ||
        text.contains('lecturername') ||
        text.contains('roomname');
  }
}

bool _isValidationScopeMessage(String message) {
  final text = message.toLowerCase();
  return text.contains('luar skop') || text.contains('bukan dalam skop');
}

class _ValidationIssueEntry {
  const _ValidationIssueEntry({
    required this.rowNumber,
    required this.message,
  });

  factory _ValidationIssueEntry.file(String message) {
    return _ValidationIssueEntry(rowNumber: null, message: message);
  }

  factory _ValidationIssueEntry.row(int rowNumber, String message) {
    return _ValidationIssueEntry(rowNumber: rowNumber, message: message);
  }

  final int? rowNumber;
  final String message;
}

class _ValidationIssueGroup extends StatelessWidget {
  const _ValidationIssueGroup({
    required this.title,
    required this.emptyText,
    required this.color,
    required this.entries,
  });

  final String title;
  final String emptyText;
  final Color color;
  final List<_ValidationIssueEntry> entries;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
                StatusChip('${entries.length} isu'),
              ],
            ),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              Text(
                emptyText,
                style: const TextStyle(color: Color(0xff64748b), fontSize: 12),
              )
            else
              for (final entry in entries.take(8)) ...[
                _ValidationIssueRow(entry: entry, color: color),
                const SizedBox(height: 8),
              ],
            if (entries.length > 8)
              Text(
                '${entries.length - 8} isu lagi. Semak jadual pratonton untuk butiran baris.',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ValidationIssueRow extends StatelessWidget {
  const _ValidationIssueRow({
    required this.entry,
    required this.color,
  });

  final _ValidationIssueEntry entry;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            entry.rowNumber == null ? 'Fail' : 'Baris ${entry.rowNumber}',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            _friendlyImportMessage(entry.message),
            style: const TextStyle(
              color: Color(0xff334155),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _ImportActionPanel extends StatelessWidget {
  const _ImportActionPanel({
    required this.result,
    required this.conflicts,
    required this.importing,
    required this.canImportPreview,
    required this.canSaveDraftPreview,
    required this.onClearPreview,
    required this.onSaveDraftPreview,
    required this.onImportPreview,
  });

  final TimetableMasterValidationResult result;
  final TimetablePreviewConflictSummary conflicts;
  final bool importing;
  final bool canImportPreview;
  final bool canSaveDraftPreview;
  final VoidCallback onClearPreview;
  final VoidCallback onSaveDraftPreview;
  final VoidCallback onImportPreview;

  @override
  Widget build(BuildContext context) {
    final skippedRows = result.totalRows - result.importableRows > 0
        ? result.totalRows - result.importableRows
        : 0;
    final hasCriticalErrors = !result.canImport;
    final explanation = hasCriticalErrors
        ? 'Ralat kritikal perlu dibetulkan dahulu. Draf dan jadual rasmi tidak boleh disimpan.'
        : conflicts.hasConflicts
            ? '${result.importableRows} baris boleh disimpan sebagai draf. Konflik perlu diselesaikan sebelum jadual boleh diterbitkan sebagai rasmi.'
            : skippedRows > 0
                ? '${result.importableRows} baris boleh diterbitkan sebagai rasmi. $skippedRows baris ralat/pendua/luar skop akan dilangkau.'
                : '${result.importableRows} baris boleh diterbitkan sebagai jadual rasmi.';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xffecfdf5),
        border: Border.all(color: const Color(0xffbbf7d0)),
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
              width: 420,
              child: Text(
                explanation,
                style: const TextStyle(
                  color: Color(0xff166534),
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: importing ? null : onClearPreview,
              icon: const Icon(Icons.close),
              label: const Text('Reset Pratonton'),
            ),
            FilledButton.tonalIcon(
              onPressed: canSaveDraftPreview ? onSaveDraftPreview : null,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Simpan Sebagai Draf'),
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
                importing ? 'Memproses...' : 'Import Sebagai Jadual Rasmi',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _friendlyImportMessage(String message) {
  if (message.startsWith('subjectId ')) {
    return 'Subjek belum wujud dan akan dicipta semasa import.';
  }
  if (message.startsWith('classId ')) {
    return 'Kelas belum wujud dan akan dicipta semasa import.';
  }
  if (message.startsWith('Academic session ')) {
    return 'Sesi akademik perlu disemak atau dicipta dahulu.';
  }
  if (message.startsWith('lecturerName is blank')) {
    return 'Nama pensyarah kosong dan akan dilengkapkan daripada akaun pensyarah.';
  }
  if (message.startsWith('roomName is blank')) {
    return 'Nama bilik kosong dan akan dilengkapkan daripada master bilik.';
  }
  return message;
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
          width: _dialogWidth(context, maxWidth: 520),
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
    final isDraft = result.savedAs == 'draft';
    return AppPanel(
      title: isDraft ? 'Draf Jadual Disimpan' : 'Import Jadual Berjaya',
      subtitle: isDraft
          ? 'Rekod draf telah dicipta: ${result.uploadId}'
          : 'Rekod upload telah dicipta: ${result.uploadId}',
      trailing: OutlinedButton.icon(
        onPressed: onViewOfficialTimetable,
        icon: const Icon(Icons.table_chart_outlined),
        label: Text(isDraft ? 'Lihat Draf Jadual' : 'Lihat Jadual Rasmi'),
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
          if (result.conflictRows > 0)
            _SummaryTile(
                'Baris Konflik', result.conflictRows, const Color(0xffb45309)),
        ],
      ),
    );
  }
}

class _TimetableTable extends StatelessWidget {
  const _TimetableTable({
    required this.slots,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.selectedSlotKeys,
    required this.batchProcessing,
    required this.onSelectionChanged,
    this.onDetails,
    this.onEdit,
    this.onDelete,
  });

  final List<TimetableSlot> slots;
  final String emptyTitle;
  final String emptySubtitle;
  final Set<String> selectedSlotKeys;
  final bool batchProcessing;
  final void Function(TimetableSlot slot, bool selected) onSelectionChanged;
  final void Function(TimetableSlot slot)? onDetails;
  final void Function(TimetableSlot slot)? onEdit;
  final void Function(TimetableSlot slot)? onDelete;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return _EmptyState(
        icon: Icons.event_busy_outlined,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return AppDataTable(
      columns: const [
        DataColumn(label: Text('Pilih')),
        DataColumn(label: Text('Aksi')),
        DataColumn(label: Text('Kod')),
        DataColumn(label: Text('Subjek')),
        DataColumn(label: Text('Kelas')),
        DataColumn(label: Text('Program')),
        DataColumn(label: Text('Pensyarah')),
        DataColumn(label: Text('Hari & Masa')),
        DataColumn(label: Text('Bilik')),
        DataColumn(label: Text('Minggu')),
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
          DataCell(
            PopupMenuButton<String>(
              tooltip: 'Tindakan slot',
              icon: const Icon(Icons.more_vert, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onSelected: (action) {
                switch (action) {
                  case 'details':
                    onDetails?.call(slot);
                  case 'edit':
                    onEdit?.call(slot);
                  case 'delete':
                    onDelete?.call(slot);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'details',
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Lihat Butiran'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit Slot'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading:
                        Icon(Icons.delete_outline, color: Color(0xffef4444)),
                    title: Text(
                      'Padam Slot',
                      style: TextStyle(color: Color(0xffef4444)),
                    ),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
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
            child: Text('${slot.day} - ${slot.startTime}-${slot.endTime}'),
          )),
          DataCell(SizedBox(
            width: 160,
            child: Text(slot.room),
          )),
          DataCell(Text(_weekText(slot))),
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
              LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 430;
                  final label = Text(
                    row.$1,
                    style: const TextStyle(
                      color: Color(0xff64748b),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                  final value = SelectableText(
                    row.$2.isEmpty ? '-' : row.$2,
                    style: const TextStyle(
                      color: Color(0xff0f172a),
                      fontSize: 13,
                    ),
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: narrow
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              label,
                              const SizedBox(height: 2),
                              value,
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: 170, child: label),
                              Expanded(child: value),
                            ],
                          ),
                  );
                },
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
    'draft' => 'Draf',
    'conflict_pending' => 'Konflik',
    'inactive' => 'Tidak Aktif',
    'cancelled' || 'canceled' => 'Dibatalkan',
    'attendance completed' => 'Kehadiran Selesai',
    _ => status,
  };
}

bool _isDraftSlot(TimetableSlot slot) {
  final status = slot.status.toLowerCase();
  final importStatus = slot.importStatus?.toLowerCase();
  return !slot.isOfficial ||
      status == 'draft' ||
      status == 'conflict_pending' ||
      importStatus == 'draft_saved' ||
      importStatus == 'conflict_pending';
}

const _weekdayValues = [
  'Isnin',
  'Selasa',
  'Rabu',
  'Khamis',
  'Jumaat',
  'Sabtu',
  'Ahad',
];

String _normalizeDay(String value) {
  final clean = value.trim();
  if (_weekdayValues.contains(clean)) return clean;
  final lower = clean.toLowerCase();
  for (final day in _weekdayValues) {
    if (day.toLowerCase() == lower) return day;
  }
  return _weekdayValues.first;
}

String _normalizeSlotStatus(String value) {
  final clean = value.trim().toLowerCase();
  return switch (clean) {
    'aktif' || 'active' => 'active',
    'tidak aktif' || 'inactive' => 'inactive',
    'dibatalkan' || 'cancelled' || 'canceled' => 'cancelled',
    _ => 'active',
  };
}

String _sessionLabel(AppState state, String academicSessionId) {
  final session = state.academicSessions
      .where((item) => item.academicSessionId == academicSessionId)
      .firstOrNull;
  if (session == null) return academicSessionId;
  return '${session.name} (${session.academicSessionId})';
}

String _slotSessionValue(TimetableSlot slot) {
  final normalized = slot.academicSessionId?.trim();
  if (normalized != null && normalized.isNotEmpty) return normalized;
  return slot.session.trim();
}

String _slotProgramValue(TimetableSlot slot) {
  final normalized = slot.programId?.trim();
  if (normalized != null && normalized.isNotEmpty) return normalized;
  return slot.program.trim();
}

String _slotClassValue(TimetableSlot slot) {
  final normalized = slot.classId?.trim();
  if (normalized != null && normalized.isNotEmpty) return normalized;
  return slot.section.trim();
}

String _slotRoomValue(TimetableSlot slot) {
  final normalized = slot.roomName?.trim();
  if (normalized != null && normalized.isNotEmpty) return normalized;
  return slot.room.trim();
}

class _EditSubjectOption {
  const _EditSubjectOption({
    required this.subjectId,
    required this.subjectCode,
    required this.subjectName,
  });

  final String? subjectId;
  final String subjectCode;
  final String subjectName;

  String get key => _subjectEditKey(subjectId, subjectCode, subjectName);
  String get label => '$subjectCode - $subjectName';
}

class _EditLecturerOption {
  const _EditLecturerOption({
    required this.lecturerId,
    required this.lecturerName,
    this.email,
    this.lecturerProfileId,
  });

  final String lecturerId;
  final String lecturerName;
  final String? email;
  final String? lecturerProfileId;

  String get key => _lecturerEditKey(lecturerId, lecturerName);
  String get label {
    final cleanEmail = email?.trim();
    if (cleanEmail != null && cleanEmail.isNotEmpty) {
      return '$lecturerName - $cleanEmail';
    }
    return lecturerName.isNotEmpty
        ? lecturerName
        : 'Pensyarah tidak dikenal pasti';
  }
}

String _subjectEditKey(
    String? subjectId, String subjectCode, String subjectName) {
  final cleanId = subjectId?.trim();
  if (cleanId != null && cleanId.isNotEmpty) return cleanId;
  return '${subjectCode.trim()}|${subjectName.trim()}';
}

String _lecturerEditKey(String lecturerId, String lecturerName) {
  final cleanId = lecturerId.trim();
  if (cleanId.isNotEmpty) return cleanId;
  return lecturerName.trim();
}

String _programOptionLabel(AppState state, String programId) {
  final program =
      state.programs.where((item) => item.id == programId).firstOrNull;
  if (program == null || program.name.trim().isEmpty) return programId;
  return '${program.id} - ${program.name}';
}

String? _programDepartmentId(AppState state, String programId) {
  return state.programs
      .where((program) => program.id == programId)
      .firstOrNull
      ?.departmentId;
}

List<String> _editProgramOptions(AppState state, TimetableSlot slot) {
  final scoped = state.scopedPrograms.map((program) => program.id).toList();
  final current = _slotProgramValue(slot);
  if (current.isNotEmpty && !scoped.contains(current)) scoped.add(current);
  return scoped;
}

List<String> _editClassOptions(
  AppState state,
  String selectedProgram,
  TimetableSlot currentSlot,
) {
  final values = state.scopedTimetable
      .where((slot) => _slotProgramValue(slot) == selectedProgram)
      .map(_slotClassValue)
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  final currentClass = _slotClassValue(currentSlot);
  if (selectedProgram == _slotProgramValue(currentSlot) &&
      currentClass.isNotEmpty &&
      !values.contains(currentClass)) {
    values.insert(0, currentClass);
  }
  return values;
}

List<_EditSubjectOption> _editSubjectOptions(
  AppState state,
  String selectedProgram,
  TimetableSlot currentSlot,
) {
  final options = <String, _EditSubjectOption>{};
  for (final slot in state.scopedTimetable) {
    if (_slotProgramValue(slot) != selectedProgram) continue;
    final code = slot.subjectCode.trim();
    final name = slot.subjectName.trim();
    if (code.isEmpty && name.isEmpty) continue;
    final option = _EditSubjectOption(
      subjectId: slot.subjectId,
      subjectCode: code,
      subjectName: name,
    );
    options.putIfAbsent(option.key, () => option);
  }

  if (selectedProgram == _slotProgramValue(currentSlot)) {
    final current = _EditSubjectOption(
      subjectId: currentSlot.subjectId,
      subjectCode: currentSlot.subjectCode,
      subjectName: currentSlot.subjectName,
    );
    if (current.subjectCode.isNotEmpty || current.subjectName.isNotEmpty) {
      options.putIfAbsent(current.key, () => current);
    }
  }

  final values = options.values.toList()
    ..sort((a, b) => a.label.compareTo(b.label));
  return values;
}

List<_EditLecturerOption> _editLecturerOptions(
  AppState state,
  String selectedProgram,
  TimetableSlot currentSlot,
) {
  final options = <String, _EditLecturerOption>{};
  for (final user in state.users) {
    if (user.role != UserRole.pensyarah || !user.isActive) continue;
    final inProgram = user.programId == selectedProgram;
    final inDepartment = user.departmentId != null &&
        state.programs
                .where((program) => program.id == selectedProgram)
                .firstOrNull
                ?.departmentId ==
            user.departmentId;
    if (!inProgram && !inDepartment) continue;
    final option = _EditLecturerOption(
      lecturerId: user.uid,
      lecturerName: user.name,
      email: user.email,
      lecturerProfileId: user.lecturerProfileId,
    );
    options.putIfAbsent(option.key, () => option);
  }

  for (final slot in state.scopedTimetable) {
    if (_slotProgramValue(slot) != selectedProgram) continue;
    final name = slot.lecturerName.trim();
    final id = slot.lecturerId.trim();
    if (name.isEmpty && id.isEmpty) continue;
    final user = state.users
        .where((item) =>
            item.uid == id ||
            item.email.toLowerCase() ==
                (slot.lecturerEmail ?? '').toLowerCase() ||
            (slot.lecturerProfileId != null &&
                item.lecturerProfileId == slot.lecturerProfileId))
        .firstOrNull;
    final lecturer = state.lecturers
        .where((item) => item.id == id || item.name == name)
        .firstOrNull;
    final option = _EditLecturerOption(
      lecturerId: user?.uid ?? (id.isNotEmpty ? id : lecturer?.id ?? ''),
      lecturerName:
          user?.name ?? (name.isNotEmpty ? name : lecturer?.name ?? ''),
      email: user?.email ?? slot.lecturerEmail ?? lecturer?.email,
      lecturerProfileId:
          user?.lecturerProfileId ?? slot.lecturerProfileId ?? lecturer?.id,
    );
    options.putIfAbsent(option.key, () => option);
  }

  if (selectedProgram == _slotProgramValue(currentSlot)) {
    final currentName = currentSlot.lecturerName.trim();
    final currentId = currentSlot.lecturerId.trim();
    final currentUser = state.users
        .where((item) =>
            item.uid == currentId ||
            item.email.toLowerCase() ==
                (currentSlot.lecturerEmail ?? '').toLowerCase() ||
            (currentSlot.lecturerProfileId != null &&
                item.lecturerProfileId == currentSlot.lecturerProfileId))
        .firstOrNull;
    final currentLecturer = state.lecturers
        .where((item) => item.id == currentId || item.name == currentName)
        .firstOrNull;
    final current = _EditLecturerOption(
      lecturerId: currentUser?.uid ??
          (currentId.isNotEmpty ? currentId : currentLecturer?.id ?? ''),
      lecturerName: currentUser?.name ??
          (currentName.isNotEmpty ? currentName : currentLecturer?.name ?? ''),
      email: currentUser?.email ??
          currentSlot.lecturerEmail ??
          currentLecturer?.email,
      lecturerProfileId: currentUser?.lecturerProfileId ??
          currentSlot.lecturerProfileId ??
          currentLecturer?.id,
    );
    if (current.lecturerName.isNotEmpty || current.lecturerId.isNotEmpty) {
      options.putIfAbsent(current.key, () => current);
    }
  }

  final values = options.values.toList()
    ..sort((a, b) => a.label.compareTo(b.label));
  return values;
}

String? _validateEditSlotInput({
  required String programId,
  required String classId,
  required String subjectCode,
  required String subjectName,
  required String lecturerId,
  required String lecturerName,
  required String roomName,
  required String day,
  required String startTime,
  required String endTime,
  required String weekStart,
  required String weekEnd,
  required String status,
}) {
  if (programId.trim().isEmpty) return 'Program perlu dipilih.';
  if (classId.trim().isEmpty) return 'Kelas perlu dipilih.';
  if (subjectCode.trim().isEmpty || subjectName.trim().isEmpty) {
    return 'Kursus perlu dipilih.';
  }
  if (lecturerName.trim().isEmpty) return 'Pensyarah perlu dipilih.';
  if (roomName.trim().isEmpty) return 'Bilik perlu dipilih.';
  if (!_weekdayValues.contains(day.trim())) return 'Hari tidak sah.';

  final start = _nullableMinutesFromTime(startTime);
  final end = _nullableMinutesFromTime(endTime);
  if (start == null || end == null) return 'Masa mesti dalam format HH:mm.';
  if (start >= end) return 'Masa Mula mesti sebelum Masa Tamat.';

  final startWeek = int.tryParse(weekStart.trim());
  final endWeek = int.tryParse(weekEnd.trim());
  if (startWeek == null || endWeek == null) {
    return 'Minggu Mula dan Minggu Tamat mesti nombor.';
  }
  if (startWeek < 1 || endWeek < 1) return 'Minggu mesti bermula dari 1.';
  if (startWeek > endWeek) {
    return 'Minggu Mula mesti sebelum atau sama dengan Minggu Tamat.';
  }
  if (!{'active', 'inactive', 'cancelled'}.contains(status)) {
    return 'Status tidak sah.';
  }
  return null;
}

int? _nullableMinutesFromTime(String value) {
  final parts = value.trim().split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return (hour * 60) + minute;
}

int? _semesterFromClassId(String classId) {
  final match = RegExp(r'\b(\d)').firstMatch(classId);
  return int.tryParse(match?.group(1) ?? '');
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
    'conflict_pending' || 'draft_saved' => 'Disimpan sebagai Draf',
    'official' => 'Diterbitkan sebagai Rasmi',
    'blocked_by_errors' => 'Dibatalkan kerana Ralat',
    'failed' => 'Gagal',
    _ => status,
  };
}

String _shortProgramLabel(String value) {
  final match = RegExp(r'\b[A-Z]{2,4}\b').firstMatch(value);
  return match?.group(0) ?? value;
}

double _dialogWidth(
  BuildContext context, {
  required double maxWidth,
  double minWidth = 320,
}) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  return (screenWidth * 0.9).clamp(minWidth, maxWidth).toDouble();
}

int _compareSlots(TimetableSlot a, TimetableSlot b) {
  final dayCompare = _daySortValue(a.day).compareTo(_daySortValue(b.day));
  if (dayCompare != 0) return dayCompare;
  final timeCompare =
      _minutesFromTime(a.startTime).compareTo(_minutesFromTime(b.startTime));
  if (timeCompare != 0) return timeCompare;
  final classCompare = _slotClassValue(a).compareTo(_slotClassValue(b));
  if (classCompare != 0) return classCompare;
  return a.subjectCode.compareTo(b.subjectCode);
}

int _daySortValue(String day) {
  const days = [
    'Isnin',
    'Selasa',
    'Rabu',
    'Khamis',
    'Jumaat',
    'Sabtu',
    'Ahad',
  ];
  final index = days.indexOf(day.trim());
  return index == -1 ? 99 : index;
}

int _minutesFromTime(String value) {
  final parts = value.trim().split(':');
  if (parts.length < 2) return 99999;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return 99999;
  return (hour * 60) + minute;
}

String _weekTextForSlot(TimetableSlot slot) {
  final start = slot.weekStart;
  final end = slot.weekEnd;
  if (start != null && end != null) return '$start-$end';
  if (slot.date.isNotEmpty) return slot.date;
  return '-';
}
