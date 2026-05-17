import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (label) {
      'Approved' || 'Completed' || 'Attendance Completed' || 'Present' || 'Active' => Colors.green,
      'Rejected' || 'Cancelled' || 'Absent' || 'High' => scheme.error,
      'Pending' || 'Under Review' || 'Attendance Not Taken' || 'Ongoing' || 'Late' => Colors.orange,
      'Replacement Class' => Colors.purple,
      _ => scheme.primary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
