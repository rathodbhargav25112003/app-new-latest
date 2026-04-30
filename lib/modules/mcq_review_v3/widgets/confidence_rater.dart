// ConfidenceRater — slider widget that captures pre-reveal confidence
// (0..100) and a tap-to-reveal button. Drives the metacognition feature.
//
// On tap "Reveal answer":
//   1. Persists confidence + time-spent via PATCH /api/user-answer/confidence
//   2. Calls onReveal() so the host screen can show the explanation
//
// Designed to slot ABOVE "View Answer" button in the MCQ play screen.
// Skipped entirely if reading_prefs.promptConfidence == false.

import 'package:flutter/material.dart';

import '../mcq_review_service.dart';
import '../reading_prefs.dart';

class ConfidenceRater extends StatefulWidget {
  /// User_answer _id we'll PATCH with confidence
  final String? userAnswerId;
  /// Question started time — used to compute time_spent_ms
  final DateTime questionStartedAt;
  /// Called after persistence — host screen reveals the answer
  final VoidCallback onReveal;
  /// Initial value (e.g., resuming a paused attempt)
  final int initial;

  const ConfidenceRater({
    super.key,
    required this.userAnswerId,
    required this.questionStartedAt,
    required this.onReveal,
    this.initial = 50,
  });

  @override
  State<ConfidenceRater> createState() => _ConfidenceRaterState();
}

class _ConfidenceRaterState extends State<ConfidenceRater> {
  late int _value;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _value = widget.initial.clamp(0, 100);
  }

  Future<void> _reveal() async {
    setState(() => _busy = true);
    final ms = DateTime.now().difference(widget.questionStartedAt).inMilliseconds;
    if (widget.userAnswerId != null) {
      await McqReviewService().updateConfidence(
        userAnswerId: widget.userAnswerId!,
        confidence: _value,
        timeSpentMs: ms,
      );
    }
    if (mounted) {
      setState(() => _busy = false);
      widget.onReveal();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = _confidenceColor(_value);

    // Honor user preference — skip rater entirely if turned off
    if (!ReadingPrefs.I.promptConfidence) {
      return _SimpleReveal(onReveal: widget.onReveal, busy: _busy);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.psychology_outlined, size: 16, color: c),
            const SizedBox(width: 6),
            const Text('How sure are you?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const Spacer(),
            Text(
              '$_value%',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: c),
            ),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.help_outline, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _label(_value),
                style: TextStyle(fontSize: 11, color: scheme.onSurface.withOpacity(0.7)),
              ),
            ),
          ]),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: c, thumbColor: c, overlayColor: c.withOpacity(0.2),
              inactiveTrackColor: c.withOpacity(0.15),
            ),
            child: Slider(
              value: _value.toDouble(),
              min: 0, max: 100, divisions: 20,
              onChanged: _busy ? null : (v) => setState(() => _value = v.toInt()),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _reveal,
              icon: _busy
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.visibility_outlined, size: 16),
              label: const Text('Reveal answer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: c, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _label(int v) {
    if (v <= 20) return 'Wild guess';
    if (v <= 40) return 'Probably wrong';
    if (v <= 60) return 'Coin flip';
    if (v <= 80) return 'Pretty sure';
    return 'Confident';
  }

  Color _confidenceColor(int v) {
    if (v <= 30) return Colors.red.shade400;
    if (v <= 60) return Colors.orange.shade400;
    if (v <= 80) return Colors.blue.shade400;
    return Colors.green.shade500;
  }
}

class _SimpleReveal extends StatelessWidget {
  final VoidCallback onReveal;
  final bool busy;
  const _SimpleReveal({required this.onReveal, required this.busy});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: busy ? null : onReveal,
        icon: const Icon(Icons.visibility_outlined, size: 16),
        label: const Text('Reveal answer'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
