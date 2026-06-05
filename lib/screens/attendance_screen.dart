import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../state/app_scope.dart';
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
  String? loadedSlotId;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppScope.of(context);
    final slots = state.scopedTimetable;
    slotId ??= slots.firstOrNull?.id;
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
    sessionDate ??= slot.date;
    if (loadedSlotId != slot.id) {
      records =
          List.of(state.attendance[slot.id] ?? _defaultRecords(slot, state));
      loadedSlotId = slot.id;
      sessionDate = slot.date;
    }
    final students = state.students
        .where((student) => student.section == slot.section)
        .toList();
    final summary = _summaryFor(records);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Ambil Kehadiran',
          subtitle:
              'Tanda kehadiran kelas dengan MC dan CK sebagai status pengecualian.',
          trailing: StatusChip(slot.status),
        ),
        AppPanel(
          title: 'Sesi Kehadiran',
          subtitle: '${slot.subjectCode} - ${slot.subjectName}',
          trailing: FilledButton.icon(
            onPressed: _saving
                ? null
                : () async {
              setState(() => _saving = true);
              try {
                await state.saveAttendance(
                  slot.id,
                  records,
                  sessionDate: sessionDate ?? slot.date,
                  weekNo: weekNo,
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Kehadiran telah dihantar.')));
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text(
                      'Kehadiran untuk slot, tarikh dan minggu ini sudah wujud.'),
                ));
              } finally {
                if (mounted) setState(() => _saving = false);
              }
            },
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(_saving ? 'Menyimpan...' : 'Hantar'),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _InfoPill(
                      icon: Icons.groups_outlined,
                      label: slot.section,
                      tone: const Color(0xff2563eb)),
                  _InfoPill(
                      icon: Icons.schedule,
                      label: '${slot.startTime}-${slot.endTime}',
                      tone: const Color(0xff0891b2)),
                  _InfoPill(
                      icon: Icons.meeting_room_outlined,
                      label: slot.room,
                      tone: const Color(0xff7c3aed)),
                  _InfoPill(
                      icon: Icons.calendar_view_week_outlined,
                      label: 'Minggu $weekNo',
                      tone: const Color(0xff16a34a)),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 300,
                    child: DropdownButtonFormField<String>(
                      initialValue: slot.id,
                      decoration:
                          const InputDecoration(labelText: 'Sesi Kelas'),
                      items: slots
                          .map((item) => DropdownMenuItem(
                              value: item.id,
                              child:
                                  Text('${item.subjectCode} - ${item.section}')))
                          .toList(),
                      onChanged: (value) => setState(() {
                        slotId = value;
                        loadedSlotId = null;
                        sessionDate = null;
                      }),
                    ),
                  ),
                  SizedBox(
                    width: 190,
                    child: OutlinedButton.icon(
                      onPressed: () => _pickSessionDate(slot),
                      icon: const Icon(Icons.event),
                      label: Text(sessionDate ?? slot.date),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: DropdownButtonFormField<int>(
                      initialValue: weekNo,
                      decoration: const InputDecoration(labelText: 'Minggu'),
                      items: List.generate(18, (index) => index + 1)
                          .map((week) => DropdownMenuItem(
                              value: week, child: Text('Minggu $week')))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => weekNo = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _SummaryBox(
                      label: 'Hadir',
                      value: '${summary.present}',
                      color: const Color(0xff16a34a)),
                  _SummaryBox(
                      label: 'Lewat',
                      value: '${summary.late}',
                      color: const Color(0xfff59e0b)),
                  _SummaryBox(
                      label: 'Tidak Hadir',
                      value: '${summary.absent}',
                      color: const Color(0xffdc2626)),
                  _SummaryBox(
                      label: 'MC',
                      value: '${summary.mc}',
                      color: const Color(0xff64748b)),
                  _SummaryBox(
                      label: 'CK',
                      value: '${summary.ck}',
                      color: const Color(0xff475569)),
                  _SummaryBox(
                      label: 'Kehadiran',
                      value: '${summary.percentage}%',
                      color: const Color(0xff2563eb)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppPanel(
          title: 'Kehadiran Pelajar',
          subtitle: '${students.length} pelajar berdaftar',
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
          child: AppDataTable(
            columns: const [
              DataColumn(label: Text('ID Pelajar')),
              DataColumn(label: Text('Nama')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Masa Masuk')),
              DataColumn(label: Text('Kehadiran %')),
            ],
            rows: students.map((student) {
              final index = records
                  .indexWhere((record) => record.studentId == student.id);
              final record = index == -1
                  ? AttendanceRecord(
                      slotId: slot.id,
                      studentId: student.id,
                      status: AttendanceStatus.present,
                      checkIn: slot.startTime,
                      remarks: '',
                    )
                  : records[index];
              return DataRow(cells: [
                DataCell(Text(student.id)),
                DataCell(Text(student.name)),
                DataCell(DropdownButton<AttendanceStatus>(
                  value: record.status,
                  items: AttendanceStatus.values
                      .map((status) => DropdownMenuItem(
                          value: status, child: Text(status.label)))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    _updateRecordStatus(slot, record, index, value);
                  },
                )),
                DataCell(Text(record.checkIn)),
                DataCell(
                    Text('${state.attendancePercentageForStudent(student)}%')),
              ]);
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        AppPanel(
          title: 'Paparan 18 Minggu',
          subtitle:
              'Ringkasan mingguan untuk pelajar dalam kelas yang dipilih.',
          child: AppDataTable(
            columns: [
              const DataColumn(label: Text('ID Pelajar')),
              const DataColumn(label: Text('Nama')),
              for (var week = 1; week <= 18; week++)
                DataColumn(label: Text('M$week')),
            ],
            rows: students.map((student) {
              final weekly = state.weeklyAttendanceForStudent(student);
              return DataRow(cells: [
                DataCell(Text(student.id)),
                DataCell(Text(student.name)),
                for (final summary in weekly)
                  DataCell(Text(summary.denominator == 0 &&
                          summary.mc == 0 &&
                          summary.ck == 0
                      ? '-'
                      : '${summary.percentage}%')),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _pickSessionDate(TimetableSlot slot) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dateFromText(sessionDate ?? slot.date),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (selected == null) return;
    setState(() {
      sessionDate = selected.toIso8601String().substring(0, 10);
    });
  }

  DateTime _dateFromText(String value) {
    return DateTime.tryParse(value) ?? DateTime.now();
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

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: .1),
        border: Border.all(color: tone.withValues(alpha: .22)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: tone),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: tone, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  const _SummaryBox({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 124,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        border: Border.all(color: color.withValues(alpha: .18)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xff64748b),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
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
