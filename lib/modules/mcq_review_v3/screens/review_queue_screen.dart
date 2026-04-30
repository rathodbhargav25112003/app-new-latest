// ReviewQueueScreen — daily spaced-repetition queue (SM-2). Lists Qs
// that are due today + lets the student grade each on a 0-5 scale
// after reviewing.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../models/mcq_review_models.dart';
import '../mcq_review_service.dart';

class ReviewQueueScreen extends StatefulWidget {
  const ReviewQueueScreen({super.key});

  static Route<dynamic> route(RouteSettings settings) =>
      CupertinoPageRoute(builder: (_) => const ReviewQueueScreen());

  @override
  State<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends State<ReviewQueueScreen> {
  final _service = McqReviewService();
  List<ReviewQueueItem> _due = [];
  ReviewQueueStats _stats = ReviewQueueStats();
  int _index = 0;
  bool _loading = true;
  bool _grading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _service.getDueReviews();
    final stats = await _service.getReviewStats();
    if (!mounted) return;
    setState(() {
      _due = (res['items'] as List).cast<ReviewQueueItem>();
      _stats = stats;
      _loading = false;
      if (_index >= _due.length) _index = 0;
    });
  }

  Future<void> _grade(int ease) async {
    if (_index >= _due.length) return;
    setState(() => _grading = true);
    final item = _due[_index];
    await _service.grade(item.id, ease);
    setState(() {
      _due.removeAt(_index);
      _grading = false;
      if (_index >= _due.length) _index = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Review Queue'),
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : Column(
              children: [
                _StatsHeader(stats: _stats),
                if (_due.isEmpty)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🎉', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            const Text("All caught up", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(
                              'No reviews due right now. Come back later or open an exam to add more.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.5)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: LinearProgressIndicator(
                            value: 1 - (_due.length / (_due.length + (_stats.totalReviews - _due.length).abs())).clamp(0, 1),
                            backgroundColor: scheme.surfaceVariant,
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: _CurrentItem(item: _due[_index]),
                          ),
                        ),
                        _GradeBar(onGrade: _grading ? null : _grade),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  final ReviewQueueStats stats;
  const _StatsHeader({required this.stats});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(child: _Stat(label: 'Due', value: '${stats.dueToday}', color: Colors.orange)),
          Expanded(child: _Stat(label: 'Active', value: '${stats.activeCount}', color: Colors.blue)),
          Expanded(child: _Stat(label: 'Mastered', value: '${stats.masteredCount}', color: Colors.green)),
          Expanded(child: _Stat(label: 'Accuracy', value: '${stats.accuracyPct}%', color: Colors.purple)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.7), fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _CurrentItem extends StatelessWidget {
  final ReviewQueueItem item;
  const _CurrentItem({required this.item});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (item.topicName.isNotEmpty)
              _Chip(label: item.topicName, color: Colors.indigo),
            if (item.difficulty.isNotEmpty) ...[
              const SizedBox(width: 4),
              _Chip(label: item.difficulty.toUpperCase(), color: _diffColor(item.difficulty)),
            ],
            const Spacer(),
            Text('Reps: ${item.repetitionCount} · Interval: ${item.intervalDays}d',
                style: TextStyle(fontSize: 10, color: scheme.onSurface.withOpacity(0.5))),
          ]),
          const SizedBox(height: 12),
          // The actual Q content should ideally be loaded — for now we
          // surface the topic + a deep link to "open the exam at this Q".
          Text(
            'Question — open in exam to review',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: scheme.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            'Use "Show in exam" below to attempt this question, then come back to grade.',
            style: TextStyle(fontSize: 11, color: scheme.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              // TODO: deep-link to exam view at this question_id
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening in exam… (wire to your exam viewer)')),
              );
            },
            icon: const Icon(Icons.open_in_new, size: 14),
            label: const Text('Show in exam'),
          ),
        ],
      ),
    );
  }

  Color _diffColor(String d) {
    final s = d.toLowerCase();
    if (s.contains('easy')) return Colors.green;
    if (s.contains('tough') || s.contains('hard')) return Colors.red;
    return Colors.orange;
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color)),
    );
  }
}

class _GradeBar extends StatelessWidget {
  final void Function(int ease)? onGrade;
  const _GradeBar({required this.onGrade});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(8, 8, 8, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outline.withOpacity(0.1))),
      ),
      child: Row(children: [
        Expanded(child: _GradeBtn(label: 'Blackout', sub: 'Forgot', ease: 0, color: Colors.red.shade400, onGrade: onGrade)),
        Expanded(child: _GradeBtn(label: 'Hard', sub: 'Struggle', ease: 2, color: Colors.orange.shade400, onGrade: onGrade)),
        Expanded(child: _GradeBtn(label: 'Good', sub: 'Got it', ease: 4, color: Colors.green.shade500, onGrade: onGrade)),
        Expanded(child: _GradeBtn(label: 'Easy', sub: 'No effort', ease: 5, color: Colors.blue.shade500, onGrade: onGrade)),
      ]),
    );
  }
}

class _GradeBtn extends StatelessWidget {
  final String label;
  final String sub;
  final int ease;
  final Color color;
  final void Function(int)? onGrade;
  const _GradeBtn({required this.label, required this.sub, required this.ease, required this.color, required this.onGrade});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onGrade == null ? null : () => onGrade!(ease),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
            Text(sub, style: TextStyle(fontSize: 9, color: color.withOpacity(0.7))),
          ],
        ),
      ),
    );
  }
}
