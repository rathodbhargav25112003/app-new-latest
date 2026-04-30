// SmartSummaryDialog — upgraded test-summary modal. Replaces the basic
// "Correct: X · Incorrect: Y · Skipped: Z" with:
//   • Headline accuracy + grade (A/B/C/D/F)
//   • Per-topic breakdown (top 3 strong + top 3 weak)
//   • Confidence calibration recap (if any confidence data)
//   • Time-spent stats (total + avg/Q)
//   • Action chips: "Review wrong Qs in SR queue", "Generate study plan",
//                    "Ask Cortex for personalized feedback", "Save & Exit"

import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../models/mcq_review_models.dart';
import '../mcq_review_service.dart';

class SmartSummaryDialog extends StatefulWidget {
  final int correct;
  final int incorrect;
  final int skipped;
  final int? totalSeconds;
  final String? userExamId;
  final VoidCallback onSaveAndExit;

  const SmartSummaryDialog({
    super.key,
    required this.correct,
    required this.incorrect,
    required this.skipped,
    this.totalSeconds,
    this.userExamId,
    required this.onSaveAndExit,
  });

  static Future<void> show(BuildContext context, {
    required int correct,
    required int incorrect,
    required int skipped,
    int? totalSeconds,
    String? userExamId,
    required VoidCallback onSaveAndExit,
  }) {
    return showDialog(
      context: context,
      builder: (_) => SmartSummaryDialog(
        correct: correct, incorrect: incorrect, skipped: skipped,
        totalSeconds: totalSeconds, userExamId: userExamId,
        onSaveAndExit: onSaveAndExit,
      ),
    );
  }

  @override
  State<SmartSummaryDialog> createState() => _SmartSummaryDialogState();
}

class _SmartSummaryDialogState extends State<SmartSummaryDialog> {
  final _service = McqReviewService();
  List<TopicStrength> _topics = [];
  Map<String, dynamic> _calibration = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
    // Auto-enroll wrong Qs into SR queue (idempotent)
    if ((widget.userExamId ?? '').isNotEmpty) {
      _service.enrollFromAttempt(widget.userExamId!);
    }
  }

  Future<void> _loadAnalytics() async {
    final topics = await _service.topicStrength(days: 30);
    final calib = await _service.calibration(days: 30);
    if (!mounted) return;
    setState(() {
      _topics = topics;
      _calibration = calib;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final attempted = widget.correct + widget.incorrect;
    final total = attempted + widget.skipped;
    final accPct = attempted > 0 ? (widget.correct / attempted * 100) : 0.0;
    final grade = _grade(accPct);
    final scheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Headline
              Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [grade.color.withOpacity(0.15), grade.color.withOpacity(0.04)]),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(color: grade.color, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(
                      grade.letter,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(grade.label, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: grade.color)),
                        const SizedBox(height: 2),
                        Text(
                          '${accPct.toStringAsFixed(1)}% accuracy · ${attempted} of $total attempted',
                          style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.7), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),

              // Counts row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(children: [
                  Expanded(child: _StatTile(label: 'Correct', value: widget.correct, color: Colors.green)),
                  const SizedBox(width: 8),
                  Expanded(child: _StatTile(label: 'Incorrect', value: widget.incorrect, color: Colors.red)),
                  const SizedBox(width: 8),
                  Expanded(child: _StatTile(label: 'Skipped', value: widget.skipped, color: Colors.orange)),
                ]),
              ),

              // Time
              if (widget.totalSeconds != null && widget.totalSeconds! > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: scheme.surfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      Icon(Icons.timer_outlined, size: 14, color: scheme.onSurface.withOpacity(0.6)),
                      const SizedBox(width: 6),
                      Text('Total: ${_fmtTime(widget.totalSeconds!)}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: scheme.onSurface.withOpacity(0.7))),
                      if (attempted > 0) ...[
                        Text(' · ', style: TextStyle(color: scheme.onSurface.withOpacity(0.4))),
                        Text('Avg/Q: ${_fmtTime((widget.totalSeconds! / attempted).round())}',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: scheme.onSurface.withOpacity(0.7))),
                      ],
                    ]),
                  ),
                ),

              // Topic breakdown
              if (!_loading && _topics.isNotEmpty) ...[
                const SizedBox(height: 14),
                _SectionLabel('🎯 Your topic strength (last 30 days)'),
                const SizedBox(height: 6),
                ..._topRecent().map((t) => _TopicRow(topic: t)),
              ],

              // Calibration recap
              if (!_loading && (_calibration['sample_size'] ?? 0) > 5) ...[
                const SizedBox(height: 14),
                _SectionLabel('🧠 Confidence calibration'),
                const SizedBox(height: 6),
                _CalibrationLine(
                  brierScore: (_calibration['brier_score'] as num?)?.toDouble(),
                  sampleSize: _calibration['sample_size'] as int,
                ),
              ],

              const SizedBox(height: 14),
              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Wrap(
                  spacing: 6, runSpacing: 6,
                  children: [
                    _ActionChip(
                      icon: Icons.repeat,
                      label: '🔁 Review wrong Qs',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).pushNamed(Routes.reviewQueueV3);
                      },
                    ),
                    _ActionChip(
                      icon: Icons.calendar_month,
                      label: '📅 Study plan',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).pushNamed(Routes.studyPlan);
                      },
                    ),
                    _ActionChip(
                      icon: Icons.trending_up,
                      label: '📈 Trends',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).pushNamed(Routes.performanceTrends);
                      },
                    ),
                    _ActionChip(
                      icon: Icons.exit_to_app,
                      label: 'Save & Exit',
                      primary: true,
                      onTap: () {
                        Navigator.pop(context);
                        widget.onSaveAndExit();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<TopicStrength> _topRecent() {
    // Top 3 weakest + top 3 strongest, sorted by accuracy
    final sorted = List<TopicStrength>.from(_topics)
      ..sort((a, b) => a.accuracyPct.compareTo(b.accuracyPct));
    final picks = <TopicStrength>[];
    if (sorted.length <= 6) return sorted;
    picks.addAll(sorted.take(3));         // weakest
    picks.add(_TopicSpacer());            // visual gap
    picks.addAll(sorted.reversed.take(3)); // strongest
    return picks;
  }

  String _fmtTime(int s) {
    if (s < 60) return '${s}s';
    final m = s ~/ 60;
    final r = s % 60;
    return r == 0 ? '${m}m' : '${m}m ${r}s';
  }

  _Grade _grade(double pct) {
    if (pct >= 85) return _Grade('A', 'Excellent', Colors.green.shade600);
    if (pct >= 70) return _Grade('B', 'Strong', Colors.blue.shade500);
    if (pct >= 55) return _Grade('C', 'Average', Colors.orange.shade600);
    if (pct >= 40) return _Grade('D', 'Needs work', Colors.deepOrange.shade400);
    return _Grade('F', 'Drill more', Colors.red.shade500);
  }
}

class _Grade {
  final String letter;
  final String label;
  final Color color;
  _Grade(this.letter, this.label, this.color);
}

// Marker class — visual gap between weakest/strongest
class _TopicSpacer extends TopicStrength {
  _TopicSpacer() : super(topic: '__spacer__');
}

class _StatTile extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatTile({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8), fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85))),
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  final TopicStrength topic;
  const _TopicRow({required this.topic});
  @override
  Widget build(BuildContext context) {
    if (topic.topic == '__spacer__') {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(height: 1));
    }
    final color = topic.accuracyPct >= 75 ? Colors.green : topic.accuracyPct >= 50 ? Colors.orange : Colors.red;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(topic.topic, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: topic.accuracyPct / 100,
                minHeight: 6,
                backgroundColor: color.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text('${topic.accuracyPct.toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

class _CalibrationLine extends StatelessWidget {
  final double? brierScore;
  final int sampleSize;
  const _CalibrationLine({this.brierScore, required this.sampleSize});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    String msg;
    Color color;
    if (brierScore == null) {
      msg = 'Build calibration by rating confidence on more Qs.';
      color = scheme.onSurface.withOpacity(0.6);
    } else if (brierScore! < 0.15) {
      msg = 'Excellent calibration · Brier ${brierScore!.toStringAsFixed(2)} · $sampleSize ratings';
      color = Colors.green.shade600;
    } else if (brierScore! < 0.25) {
      msg = 'Decent calibration · Brier ${brierScore!.toStringAsFixed(2)} · $sampleSize ratings';
      color = Colors.blue.shade500;
    } else {
      msg = 'Calibration needs work · Brier ${brierScore!.toStringAsFixed(2)} · $sampleSize ratings';
      color = Colors.orange.shade700;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Icon(Icons.psychology_outlined, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(child: Text(msg, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color))),
        ]),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;
  const _ActionChip({required this.icon, required this.label, required this.onTap, this.primary = false});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: primary ? scheme.primary : scheme.primary.withOpacity(0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.primary.withOpacity(primary ? 1 : 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: primary ? Colors.white : scheme.primary),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: primary ? Colors.white : scheme.primary)),
        ]),
      ),
    );
  }
}
