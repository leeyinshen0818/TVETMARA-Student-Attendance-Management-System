import 'package:flutter/material.dart';

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.helper,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tileColor = color ?? Theme.of(context).colorScheme.primary;
    final card = Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: tileColor,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xff64748b),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xff0f172a),
                    ),
                  ),
                ],
              ),
            ),
            CircleAvatar(
              backgroundColor: tileColor.withValues(alpha: .12),
              child: Icon(icon, color: tileColor),
            ),
          ],
        ),
      ),
    );

    if (helper == null || helper!.isEmpty) return card;

    return Tooltip(
      message: helper!,
      child: card,
    );
  }
}
