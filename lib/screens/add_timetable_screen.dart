import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/timetable_template.dart';
import '../models/app_models.dart';
import '../services/firestore_service.dart';
import '../state/app_scope.dart';

class AddTimetableScreen extends StatefulWidget {
  const AddTimetableScreen({super.key});

  @override
  State<AddTimetableScreen> createState() => _AddTimetableScreenState();
}

class _AddTimetableScreenState extends State<AddTimetableScreen> {
  final _formKey = GlobalKey<FormState>();

  final _sessionCtrl = TextEditingController(
      text: TimetableCsvTemplate.defaultAcademicSessionId);
  final _semesterCtrl = TextEditingController(text: '1');
  final _sectionCtrl = TextEditingController(text: 'A');
  final _subjectCodeCtrl = TextEditingController();
  final _subjectNameCtrl = TextEditingController();
  final _dayCtrl = TextEditingController(text: 'Isnin');
  final _dateCtrl = TextEditingController(text: '2026-05-25');
  final _startTimeCtrl = TextEditingController(text: '08:00 AM');
  final _endTimeCtrl = TextEditingController(text: '10:00 AM');
  final _roomCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController(text: '30');

  String? _selectedProgramId;
  String? _selectedProgramName;
  String? _selectedLecturerId;
  List<ProgramCode> _programs = [];
  bool _loading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    try {
      final progs = await FirestoreService.instance.getPrograms();
      if (mounted) {
        setState(() {
          _programs = progs;
          if (progs.isNotEmpty) {
            _selectedProgramId = progs.first.id;
            _selectedProgramName = progs.first.name;
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ralat memuatkan program: $e')));
      }
    }
  }

  @override
  void dispose() {
    _sessionCtrl.dispose();
    _semesterCtrl.dispose();
    _sectionCtrl.dispose();
    _subjectCodeCtrl.dispose();
    _subjectNameCtrl.dispose();
    _dayCtrl.dispose();
    _dateCtrl.dispose();
    _startTimeCtrl.dispose();
    _endTimeCtrl.dispose();
    _roomCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSlot() async {
    if (!_formKey.currentState!.validate()) return;
    final user = AppScope.of(context).currentUser!;
    final state = AppScope.of(context);
    final canAddTimetable = user.role == UserRole.ketua_jabatan ||
        state.currentKetuaProgramInheritsKetuaJabatanTasks;
    if (!canAddTimetable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Hanya Ketua Jabatan atau Ketua Program tanpa Ketua Jabatan boleh menambah jadual.')),
      );
      return;
    }
    if (_selectedProgramName == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Sila pilih Program')));
      return;
    }
    if (_selectedLecturerId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Sila pilih Pensyarah')));
      return;
    }

    setState(() => _isSaving = true);
    final lecturer = AppScope.of(context)
        .lecturers
        .firstWhere((l) => l.id == _selectedLecturerId);

    final newSlot = TimetableSlot(
      id: const Uuid().v4(),
      session: _sessionCtrl.text.trim(),
      semester: int.tryParse(_semesterCtrl.text) ?? 1,
      program: _selectedProgramName!,
      section: _sectionCtrl.text.trim(),
      subjectCode: _subjectCodeCtrl.text.trim(),
      subjectName: _subjectNameCtrl.text.trim(),
      lecturerId: lecturer.id,
      lecturerName: lecturer.name,
      day: _dayCtrl.text.trim(),
      date: _dateCtrl.text.trim(),
      startTime: _startTimeCtrl.text.trim(),
      endTime: _endTimeCtrl.text.trim(),
      room: _roomCtrl.text.trim(),
      enrolled: 0,
      capacity: int.tryParse(_capacityCtrl.text) ?? 30,
      classType: 'Teori',
      slotType: 'Kelas Biasa',
      status: 'Upcoming',
    );

    try {
      await FirestoreService.instance.addTimetableSlot(newSlot);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Jadual berjaya ditambah!')));
        Navigator.of(context).pop(); // Go back
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ralat menyimpan jadual: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final state = AppScope.of(context);
    final user = state.currentUser!;
    final canAddTimetable = user.role == UserRole.ketua_jabatan ||
        state.currentKetuaProgramInheritsKetuaJabatanTasks;
    if (!canAddTimetable) {
      return const Scaffold(
        body: Center(
          child: Text(
              'Hanya Ketua Jabatan atau Ketua Program tanpa Ketua Jabatan boleh menambah jadual.'),
        ),
      );
    }
    final visiblePrograms = user.role == UserRole.ketua_program
        ? _programs.where((program) => program.id == user.programId).toList()
        : _programs
            .where((program) => program.departmentId == user.departmentId)
            .toList();
    final lecturers = user.role == UserRole.ketua_program
        ? state.lecturers
            .where((lecturer) => lecturer.id == 'L_${user.programId}')
            .toList()
        : state.lecturers
            .where((lecturer) => lecturer.department == user.departmentId)
            .toList();
    if (visiblePrograms.isEmpty || lecturers.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
              'Tiada program atau pensyarah ditemui untuk jabatan ini. Sila seed data dahulu.'),
        ),
      );
    }
    if (visiblePrograms.isNotEmpty &&
        !visiblePrograms.any((p) => p.id == _selectedProgramId)) {
      _selectedProgramId = visiblePrograms.first.id;
      _selectedProgramName = visiblePrograms.first.name;
    }

    if (lecturers.isNotEmpty &&
        !lecturers.any((l) => l.id == _selectedLecturerId)) {
      _selectedLecturerId = lecturers.first.id;
    }

    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Jadual Baru'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.paddingOf(context).bottom + 48),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Maklumat Akademik',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedProgramId,
                isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'Program (Course)',
                    border: OutlineInputBorder()),
                items: visiblePrograms
                    .map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(
                            isMobile ? '${p.id} - ${p.name}' : p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedProgramId = val;
                    _selectedProgramName =
                        visiblePrograms.firstWhere((p) => p.id == val).name;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedLecturerId,
                isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'Pensyarah (Lecturer)',
                    border: OutlineInputBorder()),
                items: lecturers
                    .map((l) => DropdownMenuItem(
                          value: l.id,
                          child: Text(
                            l.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedLecturerId = val;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _semesterCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Semester', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (val) => val!.isEmpty ? 'Diperlukan' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _sectionCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Seksyen (Kelas)',
                          border: OutlineInputBorder()),
                      validator: (val) => val!.isEmpty ? 'Diperlukan' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (isMobile) ...[
                TextFormField(
                  controller: _subjectCodeCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Kod Subjek', border: OutlineInputBorder()),
                  validator: (val) => val!.isEmpty ? 'Diperlukan' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _subjectNameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Nama Subjek', border: OutlineInputBorder()),
                  validator: (val) => val!.isEmpty ? 'Diperlukan' : null,
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _subjectCodeCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Kod Subjek',
                            border: OutlineInputBorder()),
                        validator: (val) => val!.isEmpty ? 'Diperlukan' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _subjectNameCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Nama Subjek',
                            border: OutlineInputBorder()),
                        validator: (val) => val!.isEmpty ? 'Diperlukan' : null,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              const Text('Maklumat Sesi & Masa',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              if (isMobile) ...[
                TextFormField(
                  controller: _sessionCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Sesi (Terma)', border: OutlineInputBorder()),
                  validator: (val) => val!.isEmpty ? 'Diperlukan' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _roomCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Bilik / Makmal',
                      border: OutlineInputBorder()),
                  validator: (val) => val!.isEmpty ? 'Diperlukan' : null,
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _sessionCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Sesi (Terma)',
                            border: OutlineInputBorder()),
                        validator: (val) => val!.isEmpty ? 'Diperlukan' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _roomCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Bilik / Makmal',
                            border: OutlineInputBorder()),
                        validator: (val) => val!.isEmpty ? 'Diperlukan' : null,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              if (isMobile) ...[
                TextFormField(
                  controller: _dayCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Hari (Cth: Isnin)',
                      border: OutlineInputBorder()),
                  validator: (val) => val!.isEmpty ? 'Diperlukan' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dateCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Tarikh (YYYY-MM-DD)',
                      border: OutlineInputBorder()),
                  validator: (val) => val!.isEmpty ? 'Diperlukan' : null,
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _dayCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Hari (Cth: Isnin)',
                            border: OutlineInputBorder()),
                        validator: (val) => val!.isEmpty ? 'Diperlukan' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _dateCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Tarikh (YYYY-MM-DD)',
                            border: OutlineInputBorder()),
                        validator: (val) => val!.isEmpty ? 'Diperlukan' : null,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startTimeCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Masa Mula (08:00 AM)',
                          border: OutlineInputBorder()),
                      validator: (val) => val!.isEmpty ? 'Diperlukan' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _endTimeCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Masa Tamat (10:00 AM)',
                          border: OutlineInputBorder()),
                      validator: (val) => val!.isEmpty ? 'Diperlukan' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveSlot,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Jadual'),
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
