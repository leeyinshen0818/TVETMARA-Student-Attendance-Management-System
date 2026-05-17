import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/app_models.dart';
import '../state/app_scope.dart';
import '../widgets/status_chip.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  String? selectedSlotId;
  String room = rooms.first;
  String date = '2026-05-05';
  String start = '14:00';
  String end = '16:00';
  String reason = 'Training / Meeting';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.currentUser!;
    final admin = user.role == UserRole.admin;
    final visibleBookings = admin ? state.bookings : state.bookings.where((booking) => booking.lecturerId == user.id).toList();
    final slots = state.scopedTimetable;
    selectedSlotId ??= slots.firstOrNull?.id;
    final selected = slots.where((slot) => slot.id == selectedSlotId).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(admin ? 'Booking Approvals' : 'Booking Request', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (!admin && selected != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  DropdownButton<String>(
                    value: selected.id,
                    items: slots.map((slot) => DropdownMenuItem(value: slot.id, child: Text('${slot.subjectCode} - ${slot.section}'))).toList(),
                    onChanged: (value) => setState(() => selectedSlotId = value),
                  ),
                  SizedBox(width: 150, child: TextField(decoration: const InputDecoration(labelText: 'Date'), controller: TextEditingController(text: date), onChanged: (value) => date = value)),
                  SizedBox(width: 110, child: TextField(decoration: const InputDecoration(labelText: 'Start'), controller: TextEditingController(text: start), onChanged: (value) => start = value)),
                  SizedBox(width: 110, child: TextField(decoration: const InputDecoration(labelText: 'End'), controller: TextEditingController(text: end), onChanged: (value) => end = value)),
                  DropdownButton<String>(value: room, items: rooms.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(), onChanged: (value) => setState(() => room = value ?? room)),
                  FilledButton.icon(
                    onPressed: () {
                      state.addBooking(BookingRequest(
                        id: 'B${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
                        lecturerId: selected.lecturerId,
                        lecturerName: selected.lecturerName,
                        subject: selected.subjectName,
                        section: selected.section,
                        originalDate: selected.date,
                        originalTime: '${selected.startTime} - ${selected.endTime}',
                        replacementDate: date,
                        replacementStart: start,
                        replacementEnd: end,
                        room: room,
                        reason: reason,
                        remarks: '',
                        status: 'Pending',
                      ));
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Submit Request'),
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
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Lecturer')),
                DataColumn(label: Text('Subject')),
                DataColumn(label: Text('Section')),
                DataColumn(label: Text('Replacement')),
                DataColumn(label: Text('Room')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Action')),
              ],
              rows: visibleBookings.map((booking) {
                return DataRow(cells: [
                  DataCell(Text(booking.id)),
                  DataCell(Text(booking.lecturerName)),
                  DataCell(Text(booking.subject)),
                  DataCell(Text(booking.section)),
                  DataCell(Text('${booking.replacementDate} ${booking.replacementStart}-${booking.replacementEnd}')),
                  DataCell(Text(booking.room)),
                  DataCell(StatusChip(booking.status)),
                  DataCell(admin && booking.status == 'Pending'
                      ? Wrap(
                          spacing: 8,
                          children: [
                            IconButton(onPressed: () => state.updateBooking(booking.id, 'Approved'), icon: const Icon(Icons.check, color: Colors.green)),
                            IconButton(onPressed: () => state.updateBooking(booking.id, 'Rejected'), icon: const Icon(Icons.close, color: Colors.red)),
                          ],
                        )
                      : const Text('-')),
                ]);
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Discipline Reports', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Report ID')),
                DataColumn(label: Text('Student')),
                DataColumn(label: Text('Issue')),
                DataColumn(label: Text('Severity')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Review')),
              ],
              rows: state.disciplineReports.map((report) {
                return DataRow(cells: [
                  DataCell(Text(report.id)),
                  DataCell(Text(report.studentName)),
                  DataCell(Text(report.issueType)),
                  DataCell(StatusChip(report.severity)),
                  DataCell(StatusChip(report.status)),
                  DataCell(admin && (report.status == 'New' || report.status == 'Under Review')
                      ? IconButton(onPressed: () => state.updateDiscipline(report.id, 'Approved'), icon: const Icon(Icons.check))
                      : const Text('-')),
                ]);
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
