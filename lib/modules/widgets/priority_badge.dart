import 'package:flutter/material.dart';

/// A small colored badge that displays a priority label (e.g. "High", "Medium").
/// Shows nothing when [priorityLabel] is null or empty.
class PriorityBadge extends StatelessWidget {
  final String? priorityLabel;
  final String? priorityColor;

  const PriorityBadge({
    super.key,
    this.priorityLabel,
    this.priorityColor,
  });

  @override
  Widget build(BuildContext context) {
    if (priorityLabel == null || priorityLabel!.isEmpty) {
      return const SizedBox.shrink();
    }

    final color = _parseColor(priorityColor);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        priorityLabel!,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.grey;
    try {
      String cleaned = hex.replaceAll('#', '');
      if (cleaned.length == 6) cleaned = 'FF$cleaned';
      return Color(int.parse(cleaned, radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }
}
