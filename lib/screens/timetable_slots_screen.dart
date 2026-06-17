import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../state/app_scope.dart';
import '../state/timetable_slots_controller.dart';
import '../widgets/app_layout.dart';
import '../widgets/status_chip.dart';

class TimetableSlotsScreen extends StatefulWidget {
  const TimetableSlotsScreen({
    super.key,
    this.selectedUser,
  });

  final AppUser? selectedUser;

  @override
  State<TimetableSlotsScreen> createState() => _TimetableSlotsScreenState();
}

class _TimetableSlotsScreenState extends State<TimetableSlotsScreen> {
  late final TimetableSlotsController _controller;
  final _searchController = TextEditingController();
  bool _controllerInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_controllerInitialized) {
      final user = widget.selectedUser ?? AppScope.of(context).currentUser!;
      _controller = TimetableSlotsController(currentUser: user);
      _controllerInitialized = true;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppPageHeader(
                title: 'Papar Slot Jadual',
                subtitle:
                    'Tapis slot mengikut sesi akademik, program, kelas, pensyarah, subjek dan ruang.',
                trailing: StatusChip('M5: Paparan Slot'),
              ),
              Builder(
                builder: (context) {
                  final state = AppScope.of(context);
                  if (state.isCollectionLoading('timetable') &&
                      state.timetable.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 36),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final slots = _controller.scopedSlots(state.timetable);

                  // Use the controller mapping operations to load individual item filter parameters
                  final filteredSlots = _controller.filterSlots(slots);
                  final programmeOptions = _controller.programmeOptions(slots);
                  final sessionOptions =
                      _controller.academicSessionOptions(slots);
                  final classOptions = _controller.classOptions(slots);
                  final lecturerOptions = _controller.lecturerOptions(slots);
                  final subjectOptions = _controller.subjectOptions(slots);
                  final roomOptions = _controller.roomOptions(slots);
                  final dayOptions = _controller.dayOfWeekOptions(slots);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFilterDashboard(
                        programmeOptions: programmeOptions,
                        sessionOptions: sessionOptions,
                        classOptions: classOptions,
                        lecturerOptions: lecturerOptions,
                        subjectOptions: subjectOptions,
                        roomOptions: roomOptions,
                        dayOptions: dayOptions,
                      ),
                      const SizedBox(height: 18),
                      _buildToolbar(filteredSlots.length),
                      const SizedBox(height: 18),
                      _buildContent(context, filteredSlots),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDashboard({
    required List<String> programmeOptions,
    required List<String> sessionOptions,
    required List<String> classOptions,
    required List<String> lecturerOptions,
    required List<String> subjectOptions,
    required List<String> roomOptions,
    required List<String> dayOptions,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xffe2e8f0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, size: 20, color: Color(0xff475569)),
                const SizedBox(width: 8),
                const Text(
                  'Panel Tapisan Jadual',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xff1e293b),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _controller.resetFilters();
                      _searchController.clear();
                    });
                  },
                  icon: const Icon(Icons.restart_alt, size: 16),
                  label: const Text('Set Semula'),
                ),
              ],
            ),
            const Divider(height: 24, color: Color(0xfff1f5f9)),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Cari subjek, kod, pensyarah atau bilik...',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
              onChanged: (val) => setState(() => _controller.searchQuery = val),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildDropdown<String>(
                  label: 'Sesi Akademik',
                  value: _controller.selectedAcademicSession,
                  items: sessionOptions,
                  onChanged: (val) =>
                      setState(() => _controller.selectedAcademicSession = val),
                ),
                if (!_controller.hideProgramFilter)
                  _buildDropdown<String>(
                    label: 'Program',
                    value: _controller.selectedProgramId,
                    items: programmeOptions,
                    onChanged: (val) =>
                        setState(() => _controller.selectedProgramId = val),
                  ),
                _buildDropdown<String>(
                  label: 'Kelas / Seksyen',
                  value: _controller.selectedClassId,
                  items: classOptions,
                  onChanged: (val) =>
                      setState(() => _controller.selectedClassId = val),
                ),
                if (!_controller.hideLecturerFilter)
                  _buildDropdown<String>(
                    label: 'Pensyarah',
                    value: _controller.selectedLecturerId,
                    items: lecturerOptions,
                    onChanged: (val) =>
                        setState(() => _controller.selectedLecturerId = val),
                  ),
                _buildDropdown<String>(
                  label: 'Hari',
                  value: _controller.selectedDayOfWeek,
                  items: dayOptions,
                  onChanged: (val) =>
                      setState(() => _controller.selectedDayOfWeek = val),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xff64748b),
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<T?>(
            initialValue: value,
            isExpanded: true,
            decoration: const InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            hint: Text('Semua $label'),
            items: [
              DropdownMenuItem<T?>(
                value: null,
                child: Text('Semua $label'),
              ),
              ...items.map(
                (item) => DropdownMenuItem<T?>(
                  value: item,
                  child: Text(item.toString()),
                ),
              ),
            ],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(int count) {
    return Row(
      children: [
        Text(
          'Dijumpai: $count slot aktif',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Color(0xff64748b),
          ),
        ),
        const Spacer(),
        ToggleButtons(
          isSelected: [
            _controller.viewMode == TimetableSlotViewMode.weekly,
            _controller.viewMode == TimetableSlotViewMode.list,
          ],
          onPressed: (index) {
            setState(() {
              _controller.viewMode = index == 0
                  ? TimetableSlotViewMode.weekly
                  : TimetableSlotViewMode.list;
            });
          },
          borderRadius: BorderRadius.circular(8),
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.calendar_view_week, size: 18),
                  SizedBox(width: 6),
                  Text('Mingguan'),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.view_list, size: 18),
                  SizedBox(width: 6),
                  Text('Senarai'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, List<TimetableSlot> slots) {
    if (slots.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 64),
          child: Text(
            'Tiada slot jadual waktu dijumpai matching tapisan aktif.',
            style: TextStyle(color: Color(0xff64748b)),
          ),
        ),
      );
    }

    if (_controller.viewMode == TimetableSlotViewMode.list) {
      return _buildListView(context, slots);
    }

    return _buildWeeklyGridView(context, slots);
  }

  Widget _buildListView(BuildContext context, List<TimetableSlot> slots) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: slots.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final slot = slots[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xffe2e8f0)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              '${slot.subjectCode} - ${slot.subjectName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                    'Hari: ${_controller.normalizedDayLabel(slot.day)} | Masa: ${slot.startTime} - ${slot.endTime}'),
                Text('Kelas: ${slot.section} | Ruang: ${slot.room}'),
                Text('Pensyarah: ${slot.lecturerName}'),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showSlotDetailsDialog(context, slot),
          ),
        );
      },
    );
  }

  Widget _buildWeeklyGridView(BuildContext context, List<TimetableSlot> slots) {
    final days = _controller.uniqueValues(slots.map((s) => s.day));

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: days.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (context, dayIdx) {
        final day = days[dayIdx];
        final daySlots = slots.where((s) => s.dayOfWeek == day).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                _controller.normalizedDayLabel(day),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff1e293b),
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 340,
                mainAxisExtent: 150,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: daySlots.length,
              itemBuilder: (context, slotIdx) {
                final slot = daySlots[slotIdx];
                return InkWell(
                  onTap: () => _showSlotDetailsDialog(context, slot),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xffe2e8f0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xffeff6ff),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                slot.subjectCode,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff1d4ed8),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              slot.section,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xff475569),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          slot.subjectName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff0f172a),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.schedule,
                                size: 14, color: Color(0xff64748b)),
                            const SizedBox(width: 4),
                            Text(
                              '${slot.startTime} - ${slot.endTime}',
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xff64748b)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.room,
                                size: 14, color: Color(0xff64748b)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                slot.room,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xff64748b)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showSlotDetailsDialog(BuildContext context, TimetableSlot slot) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              const Icon(Icons.calendar_today, color: Color(0xff2563eb)),
              const SizedBox(width: 10),
              Expanded(child: Text('${slot.subjectCode}: rincian slot')),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Nama Subjek', slot.subjectName),
                _buildDetailRow('Sesi Akademik', slot.session),
                _buildDetailRow('Program ID', slot.programId ?? '-'),
                _buildDetailRow('Kelas / Seksyen', slot.section),
                _buildDetailRow(
                    'Hari Kuliah', _controller.normalizedDayLabel(slot.day)),
                _buildDetailRow(
                    'Masa Slot', '${slot.startTime} - ${slot.endTime}'),
                _buildDetailRow('Ruang / Bilik', slot.room),
                _buildDetailRow('Pensyarah', slot.lecturerName),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
            ElevatedButton.icon(
              onPressed: () => _navigateToAttendanceModule(slot),
              icon: const Icon(Icons.check_circle_outline, size: 16),
              label: const Text('Ambil Kehadiran'),
            ),
            FilledButton.icon(
              onPressed: () => _navigateToBookingModule(slot),
              icon: const Icon(Icons.swap_horiz, size: 16),
              label: const Text('Mohon Ganti Kelas'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xff475569),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: const TextStyle(color: Color(0xff0f172a)),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAttendanceModule(TimetableSlot slot) {
    Navigator.pop(context);
    Navigator.pushNamed(
      context,
      '/attendance/init',
      arguments: {
        'slotId': slot.timetableSlotId,
        'classId': slot.classId ?? slot.section,
        'subjectId': slot.subjectId ?? slot.subjectCode,
      },
    );
  }

  void _navigateToBookingModule(TimetableSlot slot) {
    Navigator.pop(context);
    Navigator.pushNamed(
      context,
      '/booking/request',
      arguments: {
        'roomId': slot.roomId ?? slot.room,
      },
    );
  }
}
