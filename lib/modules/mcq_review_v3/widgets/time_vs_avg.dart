// TimeVsAvg — small inline indicator: "You took 47s · Cohort avg 32s"
// with a colored speed badge. Pulls from /api/analytics/question-time/:id.
//
// Drop below the explanation so students see their pacing without
// switching screens.

import 'package:flutter/material.dart';

import '../mcq_review_service.dart';

class TimeVsAvg extends StatefulWidget {
  final String questionId;
  final int? userTimeMs;
  const TimeVsAvg({super.key, required this.questionId, this.userTimeMs});

  @override
  State<TimeVsAvg> createState() => _TimeVsAvgState();
}

class _TimeVsAvgState extends State<TimeVsAvg> {
  int? _avgMs;
  int _n = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await McqReviewService().questionTimeStats(widget.questionId);
    if (!mounted) return;
    setState(() {
      _avgMs = (res['avg_ms'] as num?)?.toInt();
      _n = (res['n'] as num?)?.toInt() ?? 0;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    if (_avgMs == null || _n < 5) return const SizedBox.shrink(); // need cohort sample

    final user = widget.userTimeMs;
    final scheme = Theme.of(context).colorScheme;
    Color color = Colors.grey;
    String label = 'Cohort avg';
    String tip = '';

    if (user != null && user > 0) {
      final ratio = user / _avgMs!;
      if (ratio < 0.7) {
        color = Colors.green.shade600;
        label = 'Fast';
        tip = "You're ${(100 * (1 - ratio)).round()}% faster than the cohort.";
      } else if (ratio < 1.3) {
        color = Colors.blueGrey;
        label = 'Avg pace';
      } else {
        color = Colors.orange.shade700;
        label = 'Slower';
        tip = "${(100 * (ratio - 1)).round()}% longer than cohort.";
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 14, color: color),
          const SizedBox(width: 6),
          if (user != null && user > 0) ...[
            Text('You: ${_fmt(user)}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: scheme.onSurface)),
            const SizedBox(width: 8),
          ],
          Text('Avg: ${_fmt(_avgMs!)}', style: TextStyle(fontSize: 11, color: scheme.onSurface.withOpacity(0.6))),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
            child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color)),
          ),
          if (tip.isNotEmpty) ...[
            const SizedBox(width: 4),
            Tooltip(message: tip, child: Icon(Icons.info_outline, size: 12, color: scheme.onSurface.withOpacity(0.4))),
          ],
        ],
      ),
    );
  }

  String _fmt(int ms) {
    final s = (ms / 1000).round();
    if (s < 60) return '${s}s';
    return '${(s / 60).floor()}m ${s % 60}s';
  }
}
