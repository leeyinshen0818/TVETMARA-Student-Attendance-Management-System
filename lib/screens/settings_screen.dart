import 'package:flutter/material.dart';

import '../state/app_scope.dart';
import '../widgets/app_layout.dart';
import '../widgets/app_theme.dart';
import '../widgets/mobile_components.dart';
import '../widgets/responsive.dart';
import '../widgets/status_chip.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (context.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MobileHeroCard(
            icon: Icons.settings_outlined,
            title: 'Tetapan Sistem',
            subtitle: 'Semak polisi kehadiran, semester dan kekerapan laporan.',
            chips: [
              StatusChip('${state.attendanceThreshold}% had'),
              StatusChip(_reportFrequencyLabel(state.reportFrequency)),
            ],
          ),
          const SizedBox(height: 14),
          MobileSection(
            title: 'Polisi Kehadiran',
            subtitle: 'Digunakan dalam dashboard, rekod pelajar dan laporan.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _NumberSetting(
                  label: 'Had Kehadiran (%)',
                  value: state.attendanceThreshold,
                  onChanged: state.updateAttendanceThreshold,
                ),
                const SizedBox(height: 4),
                const _MobileRuleCard(),
              ],
            ),
          ),
          const SizedBox(height: 14),
          MobileSection(
            title: 'Semakan Laporan',
            subtitle: 'Tetapan kekerapan dan semester aktif.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: state.reportFrequency,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Kekerapan Semakan Laporan',
                  ),
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
          const SizedBox(height: 14),
          const MobileSection(
            title: 'Sumber Data',
            subtitle: 'Sistem disambungkan ke Firebase Cloud Firestore.',
            child: _DataSourceRow(),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPageHeader(
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
          child: _DataSourceRow(),
        ),
      ],
    );
  }
}

String _reportFrequencyLabel(String value) {
  return switch (value) {
    'Daily' => 'Harian',
    'Monthly' => 'Bulanan',
    _ => 'Mingguan',
  };
}

class _MobileRuleCard extends StatelessWidget {
  const _MobileRuleCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MobileIconBadge(icon: Icons.rule_outlined, size: 38),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Peraturan status kehadiran',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Hadir dan Lewat dikira hadir. Tidak Hadir dikira tidak hadir. MC dan CK dikecualikan.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DataSourceRow extends StatelessWidget {
  const _DataSourceRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.cloud_done_outlined, color: Color(0xff16a34a)),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Data kehadiran, bilik, laporan, tempahan dan jadual disimpan di Firebase Cloud Firestore. Semua ahli pasukan berkongsi pangkalan data yang sama.',
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
