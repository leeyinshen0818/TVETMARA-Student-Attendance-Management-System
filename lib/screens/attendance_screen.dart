import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/app_models.dart';
import '../state/app_scope.dart';
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
    if (slot == null) return const Text('No timetable slot assigned.');
    if (loadedSlotId != slot.id) {
      records = List.of(state.attendance[slot.id] ?? attendanceForSlot(slot));
      loadedSlotId = slot.id;
    }
    final students = state.students.where((student) => student.section == slot.section).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Taking Attendance', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DropdownButton<String>(
                  value: slot.id,
                  items: slots.map((item) => DropdownMenuItem(value: item.id, child: Text('${item.subjectCode} - ${item.section}'))).toList(),
                  onChanged: (value) => setState(() {
                    slotId = value;
                    loadedSlotId = null;
                  }),
                ),
                Text('${slot.date} ${slot.startTime}-${slot.endTime}'),
                Text(slot.room),
                StatusChip(slot.status),
                FilledButton.icon(
                  onPressed: () {
                    state.saveAttendance(slot.id, records);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance submitted.')));
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Submit Attendance'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Student ID')),
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Check-in')),
                DataColumn(label: Text('Attendance %')),
              ],
              rows: students.map((student) {
                final index = records.indexWhere((record) => record.studentId == student.id);
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
                    items: AttendanceStatus.values.map((status) => DropdownMenuItem(value: status, child: Text(status.name.toUpperCase()))).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        final updated = record.copyWith(
                          status: value,
                          checkIn: value == AttendanceStatus.absent || value == AttendanceStatus.mc || value == AttendanceStatus.ck ? '-' : slot.startTime,
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
                  DataCell(Text('${student.attendance}%')),
                ]);
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
