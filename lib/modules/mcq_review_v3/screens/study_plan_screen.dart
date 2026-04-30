// StudyPlanScreen — view + manage the AI-generated study plan.
// Shows a day-by-day timeline; tap any day to mark items complete.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../models/mcq_review_models.dart';
import '../mcq_review_service.dart';

class StudyPlanScreen extends StatefulWidget {
  const StudyPlanScreen({super.key});
  static Route<dynamic> route(RouteSettings settings) =>
      CupertinoPageRoute(builder: (_) => const StudyPlanScreen());
  @override
  State<StudyPlanScreen> createState() => _StudyPlanScreenState();
}

class _StudyPlanScreenState extends State<StudyPlanScreen> {
  final _service = McqReviewService();
  StudyPlan? _plan;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final p = await _service.getActiveStudyPlan();
    if (!mounted) return;
    setState(() {
      _plan = p;
      _loading = false;
    });
  }

  Future<void> _generate() async {
    final examDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().add(const Duration(days: 3)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (examDate == null) return;
    setState(() => _loading = true);
    final p = await _service.generateStudyPlan(examDate: examDate, dailyMinutes: 60);
    if (!mounted) return;
    setState(() {
      _plan = p;
      _loading = false;
    });
  }

  Future<void> _toggle(StudyPlanItem item) async {
    final newStatus = item.status == 'completed' ? 'pending' : 'completed';
    final updated = await _service.updatePlanItem(item.id, newStatus);
    if (!mounted) return;
    if (updated != null) setState(() => _plan = updated);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('My Study Plan'),
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        actions: [
          if (_plan != null)
            TextButton(onPressed: _generate, child: const Text('Regenerate')),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _plan == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month, size: 60, color: scheme.onSurface.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        const Text('No study plan yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(
                          'Cortex will generate a personalized day-by-day plan based on your weak topics + exam date.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.5)),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _generate,
                          icon: const Icon(Icons.auto_awesome, size: 16),
                          label: const Text('Generate plan'),
                          style: ElevatedButton.styleFrom(backgroundColor: scheme.primary, foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    _PlanHeader(plan: _plan!),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _plan!.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (_, i) => _PlanItemTile(item: _plan!.items[i], onToggle: () => _toggle(_plan!.items[i])),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _PlanHeader extends StatelessWidget {
  final StudyPlan plan;
  const _PlanHeader({required this.plan});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final daysLeft = plan.examDate.difference(DateTime.now()).inDays;
    final pct = plan.items.isEmpty ? 0.0 : plan.completedCount / plan.items.length;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [scheme.primary.withOpacity(0.10), scheme.primary.withOpacity(0.04)]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.event, size: 18, color: scheme.primary),
              const SizedBox(width: 6),
              Text('Exam in $daysLeft days',
                  style: TextStyle(fontWeight: FontWeight.w800, color: scheme.primary)),
              const Spacer(),
              Text('${plan.completedCount}/${plan.items.length} done',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: pct, minHeight: 6, backgroundColor: scheme.outline.withOpacity(0.2)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanItemTile extends StatelessWidget {
  final StudyPlanItem item;
  final VoidCallback onToggle;
  const _PlanItemTile({required this.item, required this.onToggle});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = item.status == 'completed';
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: done ? Colors.green.withOpacity(0.06) : scheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: done ? Colors.green.withOpacity(0.3) : scheme.outline.withOpacity(0.15)),
        ),
        child: Row(children: [
          Icon(_kindIcon(item.kind), size: 18, color: _kindColor(item.kind)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('Day ${item.dayOffset + 1}',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: scheme.primary)),
                  ),
                  const SizedBox(width: 4),
                  Text('${item.estimatedMinutes} min',
                      style: TextStyle(fontSize: 10, color: scheme.onSurface.withOpacity(0.5))),
                ]),
                const SizedBox(height: 4),
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: done ? scheme.onSurface.withOpacity(0.5) : scheme.onSurface,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (item.description.isNotEmpty)
                  Text(item.description, style: TextStyle(fontSize: 11, color: scheme.onSurface.withOpacity(0.6))),
              ],
            ),
          ),
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done ? Colors.green : scheme.onSurface.withOpacity(0.3),
          ),
        ]),
      ),
    );
  }

  IconData _kindIcon(String k) {
    switch (k) {
      case 'deep_dive': return Icons.menu_book_outlined;
      case 'mcq_practice': return Icons.quiz_outlined;
      case 'review_queue': return Icons.repeat;
      case 'mock_exam': return Icons.assignment_turned_in_outlined;
      case 'flashcards': return Icons.style_outlined;
      case 'rest': return Icons.bedtime_outlined;
      default: return Icons.task_alt_outlined;
    }
  }

  Color _kindColor(String k) {
    switch (k) {
      case 'deep_dive': return Colors.indigo;
      case 'mcq_practice': return Colors.blue;
      case 'review_queue': return Colors.orange;
      case 'mock_exam': return Colors.red.shade700;
      case 'flashcards': return Colors.purple;
      case 'rest': return Colors.grey;
      default: return Colors.teal;
    }
  }
}
