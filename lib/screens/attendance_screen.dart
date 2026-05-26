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
          title: '${slot.subjectCode} - ${slot.subjectName}',
          subtitle:
              '${slot.section} | ${slot.date} | ${slot.startTime}-${slot.endTime} | ${slot.room}',
          trailing: FilledButton.icon(
            onPressed: () async {
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
              }
            },
            icon: const Icon(Icons.send),
            label: const Text('Hantar'),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 280,
                child: DropdownButtonFormField<String>(
                  initialValue: slot.id,
                  decoration: const InputDecoration(labelText: 'Sesi Kelas'),
                  items: slots
                      .map((item) => DropdownMenuItem(
                          value: item.id,
                          child: Text('${item.subjectCode} - ${item.section}')))
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
        ),
        const SizedBox(height: 16),
        AppPanel(
          title: 'Kehadiran Pelajar',
          subtitle: '${students.length} pelajar berdaftar',
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
                    setState(() {
                      final updated = record.copyWith(
                        status: value,
                        checkIn: value == AttendanceStatus.absent ||
                                value == AttendanceStatus.mc ||
                                value == AttendanceStatus.ck
                            ? '-'
                            : slot.startTime,
                      );
                      if (index == -1) {
                        records.add(updated);
                      } else {
                        records[index] = updated;
                      }
                    });
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
