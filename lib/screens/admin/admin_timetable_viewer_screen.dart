import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../../services/user_timetable_service.dart';
import '../../widgets/app_layout.dart';

class AdminTimetableViewerScreen extends StatefulWidget {
  const AdminTimetableViewerScreen({super.key});

  @override
  State<AdminTimetableViewerScreen> createState() =>
      _AdminTimetableViewerScreenState();
}

class _AdminTimetableViewerScreenState
    extends State<AdminTimetableViewerScreen> {
  static const _academicSessionId = 'JAN_JUN_2026';
  static const _staffRoles = <UserRole>[
    UserRole.pensyarah,
    UserRole.ketua_program,
    UserRole.ketua_jabatan,
  ];

  late final UserTimetableService _service;
  UserRole _selectedRole = UserRole.pensyarah;
  AppUser? _selectedLecturer;

  @override
  void initState() {
    super.initState();
    _service = UserTimetableService();
  }

  String _roleLabel(UserRole role) {
    return switch (role) {
      UserRole.pensyarah => 'Pensyarah',
      UserRole.ketua_program => 'Ketua Program',
      UserRole.ketua_jabatan => 'Ketua Jabatan',
      UserRole.pentadbir => 'Pentadbir',
    };
  }

  String _normalizeDayLabel(String? raw) {
    if (raw == null || raw.isEmpty) return 'Unknown';
    final normalized = raw.toLowerCase().trim();
    if (normalized.contains('isn') || normalized.contains('monday')) {
      return 'Isnin';
    }
    if (normalized.contains('sel') || normalized.contains('tuesday')) {
      return 'Selasa';
    }
    if (normalized.contains('rab') || normalized.contains('wednesday')) {
      return 'Rabu';
    }
    if (normalized.contains('kha') || normalized.contains('thursday')) {
      return 'Khamis';
    }
    if (normalized.contains('jum') || normalized.contains('friday')) {
      return 'Jumaat';
    }
    if (normalized.contains('sab') || normalized.contains('saturday')) {
      return 'Sabtu';
    }
    if (normalized.contains('aha') || normalized.contains('sunday')) {
      return 'Ahad';
    }
    return raw;
  }

  int _dayOrder(String day) {
    return switch (day) {
      'Isnin' => 0,
      'Selasa' => 1,
      'Rabu' => 2,
      'Khamis' => 3,
      'Jumaat' => 4,
      'Sabtu' => 5,
      'Ahad' => 6,
      _ => 99,
    };
  }

  Widget _buildFilterDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Expanded(
      child: DropdownButtonHideUnderline(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xffd1d5db)),
            color: const Color(0xfff8fafc),
          ),
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            hint: Text(
              hint,
              style: const TextStyle(fontSize: 13, color: Color(0xff64748b)),
            ),
            icon: const Icon(Icons.keyboard_arrow_down, size: 20),
            items: items,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildSlotCard(TimetableSlot slot) {
    final roomLabel = slot.roomName?.isNotEmpty == true
        ? slot.roomName!
        : slot.roomId?.isNotEmpty == true
            ? slot.roomId!
            : slot.room;
    final programLabel = slot.program.isNotEmpty
        ? slot.program
        : slot.programId ?? 'Tidak Diketahui';
    final classLabel =
        slot.section.isNotEmpty ? slot.section : slot.classId ?? '—';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '${slot.subjectCode} • ${slot.subjectName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xffe2e8f0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    classLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff334155),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              programLabel,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xff475569),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Color(0xff64748b)),
                const SizedBox(width: 6),
                Text(
                  '${slot.startTime} - ${slot.endTime}',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xff475569)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on,
                    size: 16, color: Color(0xff64748b)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    roomLabel,
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xff475569)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayColumn(String day, List<TimetableSlot> slots) {
    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xffe2e8f0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Color(0xff0f172a),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  slots.isEmpty ? 'Tiada slot' : '${slots.length} slot',
                  style: const TextStyle(
                    color: Color(0xff475569),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (slots.isEmpty)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xfff8fafc),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xffe2e8f0)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
              child: const Center(
                child: Text(
                  'Tiada slot untuk hari ini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xff64748b)),
                ),
              ),
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: slots.map(_buildSlotCard).toList(),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AppPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppPageHeader(
                title: 'Master Admin Timetable Viewer',
                subtitle:
                    'Pilih peranan dan pensyarah untuk melihat jadual minggu terperinci mengikut sesi akademik.',
              ),
              Row(
                children: [
                  _buildFilterDropdown<UserRole>(
                    value: _selectedRole,
                    hint: 'Pilih Peranan',
                    items: _staffRoles.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(_roleLabel(role)),
                      );
                    }).toList(),
                    onChanged: (role) {
                      if (role == null) return;
                      setState(() {
                        _selectedRole = role;
                        _selectedLecturer = null;
                      });
                    },
                  ),
                  const SizedBox(width: 14),
                  // FIX 1: Removed the redundant 'Expanded' wrapper from here
                  // because '_buildFilterDropdown' already wraps itself in an 'Expanded'.
                  StreamBuilder<List<AppUser>>(
                    stream: _service.getUsersStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Expanded(
                          child: Container(
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xfff8fafc),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: const Color(0xffd1d5db)),
                            ),
                            child: const Text(
                              'Memuatkan nama pengguna...',
                              style: TextStyle(
                                color: Color(0xff64748b),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }

                      final candidates = (snapshot.data ?? [])
                          .where((user) => user.role == _selectedRole)
                          .toList()
                        ..sort((a, b) => a.name.compareTo(b.name));

                      // FIX 2: Safeguard against the value assertion error.
                      // If the selected lecturer is not part of the newly loaded list, reset it to null.
                      final currentSelectionExists = candidates
                          .any((user) => user.uid == _selectedLecturer?.uid);
                      final validSelection =
                          currentSelectionExists ? _selectedLecturer : null;

                      return _buildFilterDropdown<AppUser>(
                        value: validSelection,
                        hint: candidates.isEmpty
                            ? 'Tiada pengguna untuk peranan ini'
                            : 'Pilih Nama Pengguna',
                        items: candidates.map((user) {
                          return DropdownMenuItem<AppUser>(
                            value: user,
                            child: Text(user.name),
                          );
                        }).toList(),
                        onChanged: (lecturer) {
                          setState(() {
                            _selectedLecturer = lecturer;
                          });
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: const BoxDecoration(
                      color: Color(0xffe2e8f0),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: const Text(
                      'Sesi Akademik: $_academicSessionId',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xff334155),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_selectedLecturer != null)
                    Expanded(
                      child: Text(
                        'Menunjukkan jadual ${_selectedLecturer!.name} (${_roleLabel(_selectedRole)})',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xff475569),
                        ),
                      ),
                    )
                  else
                    const Expanded(
                      child: Text(
                        'Sila pilih nama pengguna untuk memaparkan jadual.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xff64748b),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: _selectedLecturer == null
                    ? const Center(
                        child: Text(
                          'Pilih peranan dan nama pengguna untuk memulakan.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xff64748b),
                          ),
                        ),
                      )
                    : StreamBuilder<List<TimetableSlot>>(
                        stream: _service.getLecturerTimetableStream(
                          lecturerId: _selectedLecturer!.uid,
                          academicSessionId: _academicSessionId,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Ralat memuat slot jadual: ${snapshot.error}',
                                style: const TextStyle(color: Colors.red),
                              ),
                            );
                          }

                          final slots = snapshot.data ?? [];
                          if (slots.isEmpty) {
                            return const Center(
                              child: Text(
                                'Tiada slot jadual dijumpai untuk pengguna ini dalam sesi akademik terpilih.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xff64748b),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }

                          final grouped = <String, List<TimetableSlot>>{};
                          for (final slot in slots) {
                            final day =
                                _normalizeDayLabel(slot.dayOfWeek ?? slot.day);
                            grouped.putIfAbsent(day, () => []).add(slot);
                          }

                          for (final entry in grouped.entries) {
                            entry.value.sort((a, b) {
                              final dayA = _dayOrder(
                                  _normalizeDayLabel(a.dayOfWeek ?? a.day));
                              final dayB = _dayOrder(
                                  _normalizeDayLabel(b.dayOfWeek ?? b.day));
                              if (dayA != dayB) return dayA.compareTo(dayB);
                              return a.startTime.compareTo(b.startTime);
                            });
                          }

                          final weekDays = [
                            'Isnin',
                            'Selasa',
                            'Rabu',
                            'Khamis',
                            'Jumaat',
                            'Sabtu',
                            'Ahad',
                          ];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${slots.length} slot dijumpai',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xff64748b),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    color: const Color(0xfff8fafc),
                                    padding: const EdgeInsets.all(14),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: IntrinsicHeight(
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: weekDays.map((day) {
                                            final daySlots = grouped[day] ?? [];
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 14.0),
                                              child: _buildDayColumn(
                                                day,
                                                daySlots,
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
