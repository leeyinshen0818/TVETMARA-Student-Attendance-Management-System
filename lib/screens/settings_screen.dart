import 'package:flutter/material.dart';

import '../state/app_scope.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _NumberSetting(
                  label: 'Attendance Threshold (%)',
                  value: state.attendanceThreshold,
                  onChanged: state.updateAttendanceThreshold,
                ),
                SwitchListTile(
                  value: state.mcAsPresent,
                  title: const Text('MC counted as present'),
                  onChanged: state.updateMcAsPresent,
                ),
                SwitchListTile(
                  value: state.ckAsPresent,
                  title: const Text('CK counted as present'),
                  onChanged: state.updateCkAsPresent,
                ),
                _NumberSetting(
                  label: 'Semester',
                  value: state.semester,
                  onChanged: state.updateSemester,
                ),
              ],
            ),
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
