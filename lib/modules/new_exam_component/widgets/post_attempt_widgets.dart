// ════════════════════════════════════════════════════════════════════
// Post-attempt review widgets
// ════════════════════════════════════════════════════════════════════
//
// Companion widgets for the review screen that consume the new
// `/exam-attempt/:id/analytics/*` endpoints. All theme-agnostic — use
// Theme.of(context) so the integrator can drop them into any
// existing scaffold.
//
//   • TopicHeatmapView          — color-ranked topic + subtopic grid
//   • TimePressureQuadrant      — 2×2 rushed/lingered × correct/wrong
//   • ConfidenceCalibrationChart — per-bin accuracy vs midpoint bars
//   • PatternSummaryCard        — Claude post-attempt summary text
//   • WhyWrongDrawer            — bottom-sheet with Claude explanation
//                                 + tap-into doubt-chat
//   • CohortPercentileBar       — your score vs cohort histogram

import 'package:flutter/material.dart';
import '../../../api_service/exam_analytics_api.dart';

// ────────────────────────────────────────────────────────────────────
// Topic heatmap
// ────────────────────────────────────────────────────────────────────

class TopicHeatmapView extends StatelessWidget {
  final HeatmapResult data;
  final void Function(HeatmapTopic)? onTopicTap;

  const TopicHeatmapView({super.key, required this.data, this.onTopicTap});

  @override
  Widget build(BuildContext context) {
    if (data.topics.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Not enough data for a heatmap yet.'),
      ));
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.topics.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) => _TopicTile(topic: data.topics[i], onTap: onTopicTap),
    );
  }
}

class _TopicTile extends StatelessWidget {
  final HeatmapTopic topic;
  final void Function(HeatmapTopic)? onTap;
  const _TopicTile({required this.topic, this.onTap});

  Color _color(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    final w = topic.weaknessScore.clamp(0.0, 4.0) / 4.0;
    return Color.lerp(cs.tertiary, cs.error, w) ?? cs.error;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final color = _color(context);
    final pct = (topic.accuracy * 100).round();
    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withValues(alpha: 0.40), width: 1),
      ),
      child: InkWell(
        onTap: onTap == null ? null : () => onTap!(topic),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      topic.topicId.isEmpty ? 'Untagged' : topic.topicId,
                      style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text('$pct%  ·  ${topic.correct}/${topic.attempted}',
                      style: t.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
              if (topic.subtopics.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: topic.subtopics.take(8).map((s) {
                    final w = s.weaknessScore.clamp(0.0, 4.0) / 4.0;
                    final sc = Color.lerp(cs.tertiary, cs.error, w) ?? cs.error;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: sc.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: sc.withValues(alpha: 0.30)),
                      ),
                      child: Text(
                        '${s.subcategoryId.isEmpty ? '—' : s.subcategoryId} · ${(s.accuracy * 100).round()}%',
                        style: t.textTheme.labelSmall?.copyWith(color: sc),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Time pressure 2×2 quadrant
// ────────────────────────────────────────────────────────────────────

class TimePressureQuadrant extends StatelessWidget {
  final TimePressureResult data;
  final void Function(String bucketKey, List<String> questionIds)? onBucketTap;

  const TimePressureQuadrant({super.key, required this.data, this.onBucketTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.6,
      children: [
        _quadrant(context, 'rushed_correct', '< 20s · correct', cs.tertiary),
        _quadrant(context, 'rushed_wrong', '< 20s · wrong', cs.error),
        _quadrant(context, 'lingered_correct', '> 2 min · correct', cs.primary),
        _quadrant(context, 'lingered_wrong', '> 2 min · wrong', cs.error.withValues(alpha: 0.75)),
      ],
    );
  }

  Widget _quadrant(BuildContext ctx, String key, String label, Color color) {
    final t = Theme.of(ctx);
    final n = data.counts[key] ?? 0;
    final qs = data.questions[key] ?? const <String>[];
    return Material(
      color: color.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withValues(alpha: 0.30)),
      ),
      child: InkWell(
        onTap: onBucketTap == null || n == 0 ? null : () => onBucketTap!(key, qs),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: t.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700)),
              Text('$n', style: t.textTheme.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Confidence calibration chart
// ────────────────────────────────────────────────────────────────────

class ConfidenceCalibrationChart extends StatelessWidget {
  final ConfidenceCalibration data;

  const ConfidenceCalibrationChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    if (data.totalCount == 0) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No confidence ratings recorded for this attempt.'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Confidence calibration',
                style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            if (data.brierScore != null)
              Text(
                'Brier ${data.brierScore!.toStringAsFixed(3)}',
                style: t.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...data.bins.where((b) => b.count > 0).map((b) {
          final overUnder = b.delta;
          final color = overUnder.abs() < 0.10
              ? cs.primary
              : (overUnder >= 0 ? cs.tertiary : cs.error);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(width: 60, child: Text(b.label, style: t.textTheme.bodySmall)),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: b.accuracy,
                      minHeight: 8,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 70,
                  child: Text(
                    '${(b.accuracy * 100).round()}%  (${b.count})',
                    style: t.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        Text(
          'Bars at the bin midpoint = perfectly calibrated. Above = underconfident, below = overconfident.',
          style: t.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Pattern summary card
// ────────────────────────────────────────────────────────────────────

class PatternSummaryCard extends StatelessWidget {
  final PatternSummary summary;
  const PatternSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    if (summary.text.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      elevation: 0,
      color: cs.primaryContainer.withValues(alpha: 0.30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.primary.withValues(alpha: 0.20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.auto_awesome, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Text('What to focus on next',
                  style: t.textTheme.labelLarge?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 8),
            Text(summary.text, style: t.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Why-wrong drawer
// ────────────────────────────────────────────────────────────────────

class WhyWrongDrawer extends StatelessWidget {
  final WhyWrongResult result;
  final VoidCallback? onOpenDoubtChat;
  const WhyWrongDrawer({super.key, required this.result, this.onOpenDoubtChat});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.psychology_alt, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Text('Why your answer was wrong',
                style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            if (result.cached) ...[
              const SizedBox(width: 8),
              Text('(cached)', style: t.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ]),
          const SizedBox(height: 12),
          if (result.error != null && result.text.isEmpty)
            Text('Sorry — couldn\'t fetch an explanation: ${result.error}')
          else
            Text(result.text, style: t.textTheme.bodyMedium),
          const SizedBox(height: 12),
          Row(children: [
            const Spacer(),
            if (onOpenDoubtChat != null)
              TextButton.icon(
                onPressed: onOpenDoubtChat,
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('Ask a follow-up'),
              ),
            TextButton(
              onPressed: () => Navigator.maybePop(context),
              child: const Text('Close'),
            ),
          ]),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Cohort percentile bar
// ────────────────────────────────────────────────────────────────────

class CohortPercentileBar extends StatelessWidget {
  final CohortPercentile data;
  const CohortPercentileBar({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    if (data.cohortSize == 0) {
      return Text('Cohort percentile available once others have submitted.',
          style: t.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant));
    }
    final maxBin = data.histogram.isEmpty
        ? 1
        : data.histogram.map((b) => b.count).reduce((a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${data.percentile.toStringAsFixed(1)} percentile',
            style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: cs.primary)),
        Text('out of ${data.cohortSize} attempts',
            style: t.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.histogram.map((b) {
              final h = (b.count / maxBin) * 70;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Container(
                    height: h.clamp(2.0, 70.0),
                    color: cs.primary.withValues(alpha: 0.50),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
