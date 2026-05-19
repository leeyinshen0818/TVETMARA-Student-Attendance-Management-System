import 'package:flutter/material.dart';

import '../state/app_scope.dart';
import '../widgets/app_layout.dart';
import '../widgets/status_chip.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Tetapan',
          subtitle:
              'Peraturan akademik dan tetapan laporan yang digunakan dalam sistem.',
          trailing: StatusChip('${state.attendanceThreshold}% had'),
        ),
        AppPanel(
          title: 'Polisi Kehadiran',
          subtitle: 'Nilai ini mempengaruhi papan pemuka, rekod dan laporan.',
          child: Column(
            children: [
              _NumberSetting(
                label: 'Had Kehadiran (%)',
                value: state.attendanceThreshold,
                onChanged: state.updateAttendanceThreshold,
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Peraturan status kehadiran'),
                subtitle: Text(
                    'Hadir dan Lewat dikira hadir. Tidak Hadir dikira tidak hadir. MC dan CK dikecualikan.'),
                leading: Icon(Icons.rule),
              ),
              DropdownButtonFormField<String>(
                initialValue: state.reportFrequency,
                decoration: const InputDecoration(
                    labelText: 'Kekerapan Semakan Laporan'),
                items: const [
                  DropdownMenuItem(value: 'Weekly', child: Text('Mingguan')),
                  DropdownMenuItem(value: 'Daily', child: Text('Harian')),
                  DropdownMenuItem(value: 'Monthly', child: Text('Bulanan')),
                ],
                onChanged: (value) {
                  if (value != null) state.updateReportFrequency(value);
                },
              ),
              const SizedBox(height: 12),
              _NumberSetting(
                label: 'Semester',
                value: state.semester,
                onChanged: state.updateSemester,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const AppPanel(
          title: 'Sumber Data',
          subtitle:
              'Data contoh sedang digunakan. Firebase boleh disambungkan selepas UI dimuktamadkan.',
          child: Row(
            children: [
              Icon(Icons.storage_outlined, color: Color(0xff1d4ed8)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Binaan semasa menggunakan data contoh setempat untuk kehadiran, bilik, laporan, tempahan dan jadual.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NumberSetting extends StatelessWidget {
  const _NumberSetting({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: '$value',
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        onChanged: (text) => onChanged(int.tryParse(text) ?? value),
      ),
    );
  }
}
