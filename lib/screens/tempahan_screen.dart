import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../state/app_scope.dart';
import '../widgets/app_layout.dart';
import '../widgets/status_chip.dart';

/// Tempahan Bilik screen — Pensyarah creates room booking requests,
/// KP reviews / approves them.
class TempahanScreen extends StatefulWidget {
  const TempahanScreen({super.key});

  @override
  State<TempahanScreen> createState() => _TempahanScreenState();
}

class _TempahanScreenState extends State<TempahanScreen> {
  String? selectedSlotId;
  String room = '';
  String block = 'All';
  String date = '2026-05-20';
  String start = '14:00';
  String end = '16:00';
  String reason = 'Latihan / Mesyuarat';

  // Manual input fallback controllers
  final _subjectCtrl = TextEditingController(text: 'Asas DED 1');
  final _sectionCtrl = TextEditingController(text: 'DED 1A');

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _sectionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.currentUser!;
    final isPensyarah = user.role == UserRole.pensyarah;
    final canApproveBookings = user.role == UserRole.ketuaProgram;
    if (!isPensyarah && !canApproveBookings) {
      return const PageHeader(
        title: 'Akses Tidak Dibenarkan',
        subtitle:
            'Hanya Pensyarah boleh memohon tempahan dan Ketua Program boleh meluluskan tempahan.',
      );
    }
    final visibleBookings = state.scopedBookings;
    final slots = state.scopedTimetable;
    final blocks = [
      'All',
      ...state.roomResources.map((r) => r.block).toSet().toList()..sort()
    ];
    final filteredRooms = state.roomResources
        .where((item) => block == 'All' || item.block == block)
        .toList();
    if (filteredRooms.isNotEmpty &&
        !filteredRooms.any((item) => item.name == room)) {
      room = filteredRooms.first.name;
    }
    selectedSlotId ??= slots.firstOrNull?.id;
    final selected =
        slots.where((slot) => slot.id == selectedSlotId).firstOrNull;
    final available = filteredRooms.isNotEmpty
        ? state.isRoomAvailable(room: room, date: date, start: start, end: end)
        : false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: isPensyarah
              ? 'Permohonan Tempahan Bilik'
              : 'Kelulusan Tempahan Bilik',
          subtitle: isPensyarah
              ? 'Mohon bilik kelas ganti berdasarkan ruang yang tersedia.'
              : 'Semak dan luluskan permohonan kelas ganti.',
          trailing: StatusChip('${visibleBookings.length} permohonan'),
        ),

        // ── Create Form (Pensyarah only) ──
        if (isPensyarah) ...[
          AppPanel(
            title: 'Permohonan Ganti Baharu',
            subtitle: selected != null
                ? '${selected.subjectCode} - ${selected.subjectName}'
                : 'Isi maklumat kelas ganti anda.',
            trailing: StatusChip(available ? 'Available' : 'Unavailable'),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // If timetable slots exist, show dropdown. Otherwise, manual input.
                if (slots.isNotEmpty)
                  SizedBox(
                    width: 240,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selected?.id,
                      decoration: const InputDecoration(labelText: 'Kelas'),
                      items: slots
                          .map((slot) => DropdownMenuItem(
                              value: slot.id,
                              child: Text(
                                  '${slot.subjectCode} - ${slot.section}')))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => selectedSlotId = value),
                    ),
                  )
                else ...[
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: _subjectCtrl,
                      decoration: const InputDecoration(labelText: 'Subjek'),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: _sectionCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Kelas / Seksyen'),
                    ),
                  ),
                ],
                SizedBox(
                  width: 150,
                  child: TextField(
                    decoration:
                        const InputDecoration(labelText: 'Tarikh Ganti'),
                    controller: TextEditingController(text: date),
                    onChanged: (value) => date = value,
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Mula'),
                    controller: TextEditingController(text: start),
                    onChanged: (value) => start = value,
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Tamat'),
                    controller: TextEditingController(text: end),
                    onChanged: (value) => end = value,
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
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
                if (filteredRooms.isNotEmpty)
                  SizedBox(
                    width: 290,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: room,
                      decoration: const InputDecoration(labelText: 'Bilik'),
                      items: filteredRooms
                          .map((item) => DropdownMenuItem(
                              value: item.name,
                              child: Text('${item.name} (${item.type})')))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => room = value ?? room),
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
                      lecturerId: user.id,
                      lecturerName: user.name,
                      subject: selected?.subjectName ?? _subjectCtrl.text,
                      section: selected?.section ?? _sectionCtrl.text,
                      originalDate: selected?.date ?? date,
                      originalTime: selected != null
                          ? '${selected.startTime} - ${selected.endTime}'
                          : '-',
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
                  icon: const Icon(Icons.send),
                  label: const Text('Hantar Permohonan'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Booking History / Approval Table ──
        AppPanel(
          title: 'Senarai Permohonan Tempahan',
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
                DataCell(canApproveBookings && booking.status == 'Pending'
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
      ],
    );
  }
}
