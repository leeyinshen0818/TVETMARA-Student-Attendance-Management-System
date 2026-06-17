import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../state/app_scope.dart';
import '../widgets/app_layout.dart';
import '../widgets/status_chip.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  String? selectedSlotId;
  String room = '';
  String block = 'All';
  String date = '2026-05-05';
  String start = '14:00';
  String end = '16:00';
  String reason = 'Latihan / Mesyuarat';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.currentUser!;
    final admin = user.role == UserRole.pentadbir;
    final isApprover = user.role == UserRole.ketua_jabatan ||
        user.role == UserRole.ketua_program;
    final visibleBookings = state.scopedBookings;
    final visibleDiscipline = state.scopedDisciplineReports;
    final slots = state.scopedTimetable;
    final blocks = [
      'All',
      ...state.roomResources.map((room) => room.block).toSet().toList()..sort()
    ];
    final filteredRooms = state.roomResources
        .where((item) => block == 'All' || item.block == block)
        .toList();
    if (filteredRooms.isEmpty) {
      return const Center(child: Text('Memuatkan senarai bilik...'));
    }
    if (!filteredRooms.any((item) => item.name == room)) {
      room = filteredRooms.first.name;
    }
    selectedSlotId ??= slots.firstOrNull?.id;
    final selected =
        slots.where((slot) => slot.id == selectedSlotId).firstOrNull;
    final available =
        state.isRoomAvailable(room: room, date: date, start: start, end: end);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPageHeader(
          title: isApprover
              ? 'Kelulusan Tempahan & Disiplin'
              : 'Tempahan & Laporan Saya',
          subtitle: isApprover
              ? 'Semak permohonan kelas ganti dan laporan disiplin program anda.'
              : 'Mohon bilik kelas ganti berdasarkan ruang yang tersedia.',
          trailing: StatusChip('${visibleBookings.length} permohonan'),
        ),
        if (!isApprover && selected != null)
          AppPanel(
            title: 'Permohonan Ganti Baharu',
            subtitle: '${selected.subjectCode} - ${selected.subjectName}',
            trailing: StatusChip(available ? 'Available' : 'Unavailable'),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String>(
                    initialValue: selected.id,
                    decoration: const InputDecoration(labelText: 'Kelas'),
                    items: slots
                        .map((slot) => DropdownMenuItem(
                            value: slot.id,
                            child:
                                Text('${slot.subjectCode} - ${slot.section}')))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selectedSlotId = value),
                  ),
                ),
                SizedBox(
                    width: 150,
                    child: TextField(
                        decoration: const InputDecoration(labelText: 'Tarikh'),
                        controller: TextEditingController(text: date),
                        onChanged: (value) => date = value)),
                SizedBox(
                    width: 110,
                    child: TextField(
                        decoration: const InputDecoration(labelText: 'Mula'),
                        controller: TextEditingController(text: start),
                        onChanged: (value) => start = value)),
                SizedBox(
                    width: 110,
                    child: TextField(
                        decoration: const InputDecoration(labelText: 'Tamat'),
                        controller: TextEditingController(text: end),
                        onChanged: (value) => end = value)),
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    initialValue: block,
                    decoration: const InputDecoration(labelText: 'Blok'),
                    items: blocks
                        .map((item) => DropdownMenuItem(
                            value: item,
                            child: Text(item == 'All' ? 'Semua' : item)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => block = value ?? block),
                  ),
                ),
                SizedBox(
                  width: 290,
                  child: DropdownButtonFormField<String>(
                    initialValue: room,
                    decoration: const InputDecoration(labelText: 'Bilik'),
                    items: filteredRooms
                        .map((item) => DropdownMenuItem(
                            value: item.name,
                            child: Text('${item.name} (${item.type})')))
                        .toList(),
                    onChanged: (value) => setState(() => room = value ?? room),
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor:
                          available ? null : Theme.of(context).disabledColor),
                  onPressed: () {
                    if (!state.isRoomAvailable(
                        room: room, date: date, start: start, end: end)) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              'Bilik yang dipilih tidak tersedia pada masa ini.')));
                      return;
                    }
                    state.addBooking(BookingRequest(
                      id: 'B${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
                      lecturerId: selected.lecturerId,
                      lecturerName: selected.lecturerName,
                      subject: selected.subjectName,
                      section: selected.section,
                      originalDate: selected.date,
                      originalTime:
                          '${selected.startTime} - ${selected.endTime}',
                      replacementDate: date,
                      replacementStart: start,
                      replacementEnd: end,
                      room: room,
                      reason: reason,
                      remarks: '',
                      status: 'Pending',
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Permohonan tempahan telah dihantar.')));
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Hantar Permohonan'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        if (admin)
          AppPanel(
            title: 'Inventori Bilik',
            subtitle:
                '${state.roomResources.length} bilik dikumpulkan mengikut blok.',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final group
                    in state.roomResources.map((room) => room.block).toSet())
                  Chip(
                      label: Text(
                          '$group: ${state.roomResources.where((room) => room.block == group).length} bilik')),
              ],
            ),
          ),
        if (admin) const SizedBox(height: 16),
        AppPanel(
          title: 'Permohonan Tempahan',
          subtitle: 'Permohonan kelas ganti yang menunggu dan telah selesai.',
          child: AppDataTable(
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Pensyarah')),
              DataColumn(label: Text('Subjek')),
              DataColumn(label: Text('Kelas')),
              DataColumn(label: Text('Ganti')),
              DataColumn(label: Text('Bilik')),
              DataColumn(label: Text('Ketersediaan')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Tindakan')),
            ],
            rows: visibleBookings.map((booking) {
              return DataRow(cells: [
                DataCell(Text(booking.id)),
                DataCell(Text(booking.lecturerName)),
                DataCell(Text(booking.subject)),
                DataCell(Text(booking.section)),
                DataCell(Text(
                    '${booking.replacementDate} ${booking.replacementStart}-${booking.replacementEnd}')),
                DataCell(Text(booking.room)),
                DataCell(StatusChip(state.isRoomAvailable(
                  room: booking.room,
                  date: booking.replacementDate,
                  start: booking.replacementStart,
                  end: booking.replacementEnd,
                  ignoreBookingId: booking.id,
                )
                    ? 'Available'
                    : 'Unavailable')),
                DataCell(StatusChip(booking.status)),
                DataCell(isApprover && booking.status == 'Pending'
                    ? Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                              onPressed: () =>
                                  state.updateBooking(booking.id, 'Approved'),
                              icon:
                                  const Icon(Icons.check, color: Colors.green)),
                          IconButton(
                              onPressed: () =>
                                  state.updateBooking(booking.id, 'Rejected'),
                              icon: const Icon(Icons.close, color: Colors.red)),
                        ],
                      )
                    : const Text('-')),
              ]);
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        AppPanel(
          title: 'Laporan Disiplin',
          subtitle: 'Item susulan daripada semakan kehadiran dan tingkah laku.',
          child: AppDataTable(
            columns: const [
              DataColumn(label: Text('ID Laporan')),
              DataColumn(label: Text('Pelajar')),
              DataColumn(label: Text('Isu')),
              DataColumn(label: Text('Tahap')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Semakan')),
            ],
            rows: visibleDiscipline.map((report) {
              return DataRow(cells: [
                DataCell(Text(report.id)),
                DataCell(Text(report.studentName)),
                DataCell(Text(report.issueType)),
                DataCell(StatusChip(report.severity)),
                DataCell(StatusChip(report.status)),
                DataCell(isApprover &&
                        (report.status == 'New' ||
                            report.status == 'Under Review')
                    ? IconButton(
                        onPressed: () =>
                            state.updateDiscipline(report.id, 'Approved'),
                        icon: const Icon(Icons.check))
                    : const Text('-')),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }
}
