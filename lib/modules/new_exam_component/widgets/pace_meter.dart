// ════════════════════════════════════════════════════════════════════
// PaceMeter — "you're 4 min behind expected pace"
// ════════════════════════════════════════════════════════════════════
//
// Pure UI math, no API calls. Given:
//   • totalQuestions
//   • answeredCount
//   • elapsedMs (since attempt start, excluding paused time if you
//     have it)
//   • totalDurationMs (the exam's allotted time)
//
// computes:
//   expected_answered_at_now = answeredFraction
//                            = elapsedMs / totalDurationMs * totalQuestions
//   delta = answeredCount - expected_answered_at_now (questions)
//   delta_ms = delta * (totalDurationMs / totalQuestions)
//
// Negative delta = behind, positive = ahead.

import 'package:flutter/material.dart';

class PaceMeter extends StatelessWidget {
  final int totalQuestions;
  final int answeredCount;
  final int elapsedMs;
  final int totalDurationMs;

  const PaceMeter({
    super.key,
    required this.totalQuestions,
    required this.answeredCount,
    required this.elapsedMs,
    required this.totalDurationMs,
  });

  @override
  Widget build(BuildContext context) {
    if (totalQuestions <= 0 || totalDurationMs <= 0) return const SizedBox.shrink();
    final fraction = (elapsedMs / totalDurationMs).clamp(0.0, 1.0);
    final expected = fraction * totalQuestions;
    final delta = answeredCount - expected;
    final perQ = totalDurationMs / totalQuestions;
    final deltaMs = (delta * perQ).round();
    final aheadMin = (deltaMs / 60000).abs();

    final t = Theme.of(context);
    final cs = t.colorScheme;
    final isAhead = delta >= 0;
    final isOnPace = aheadMin < 1;

    final color = isOnPace
        ? cs.primary
        : (isAhead ? cs.tertiary : cs.error);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnPace
                ? Icons.timer
                : (isAhead ? Icons.speed : Icons.warning_amber_rounded),
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            _label(isOnPace, isAhead, aheadMin),
            style: t.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _label(bool onPace, bool ahead, double aheadMin) {
    if (onPace) return 'On pace';
    final mins = aheadMin.toStringAsFixed(aheadMin >= 10 ? 0 : 1);
    return ahead ? '$mins min ahead' : '$mins min behind';
  }
}
