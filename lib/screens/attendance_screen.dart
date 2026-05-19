import 'package:flutter/material.dart';

import '../data/mock_data.dart';
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
    final slots = state.scopedTimetable;
    final slot = slots.where((item) => item.id == slotId).firstOrNull;
    if (slot == null) return const Text('Tiada slot jadual ditetapkan.');
    if (loadedSlotId != slot.id) {
      records = List.of(state.attendance[slot.id] ?? attendanceForSlot(slot));
      loadedSlotId = slot.id;
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
            onPressed: () {
              state.saveAttendance(slot.id, records);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kehadiran telah dihantar.')));
            },
            icon: const Icon(Icons.send),
            label: const Text('Hantar'),
          ),
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
            }),
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
      ],
    );
  }
}
