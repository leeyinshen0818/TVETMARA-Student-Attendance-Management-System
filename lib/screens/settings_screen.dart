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
          subtitle: 'Sistem disambungkan ke Firebase Cloud Firestore.',
          child: Row(
            children: [
              Icon(Icons.cloud_done_outlined, color: Color(0xff16a34a)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Data kehadiran, bilik, laporan, tempahan dan jadual disimpan di Firebase Cloud Firestore. Semua ahli pasukan berkongsi pangkalan data yang sama.',
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
