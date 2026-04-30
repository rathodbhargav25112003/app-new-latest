// ════════════════════════════════════════════════════════════════════
// PostAttemptAnalyticsPanel — single drop-in for any solution screen
// ════════════════════════════════════════════════════════════════════
//
// Bundles every wave-2 post-attempt analytics widget into one slab
// that the integrator drops into:
//
//   • test/practice_test_solution_exam_screen.dart   (practice tests)
//   • masterTest/practice_mock_solution_exam_screen.dart (mocks)
//   • masterTest/practice_custom_test_solution_screen.dart (custom)
//   • customtests/custom_test_solution_report.dart   (custom report)
//   • quiztest/quiz_solution_screen.dart            (quizzes — quiz
//                                                    variant skips
//                                                    sectioned bits)
//   • reports/master reports/solution_master_report.dart (master)
//
// Single integration line:
//
//   PostAttemptAnalyticsPanel(userExamId: yourUserExamId)
//
// Renders, in order:
//   1. Pattern summary card           — Claude 4-6 sentences
//   2. Cohort percentile bar          — score vs everyone
//   3. Topic weakness heatmap         — colored grid
//   4. Time-pressure quadrant         — rushed/lingered × correct/wrong
//   5. Confidence calibration chart   — only renders if any
//                                       confidence ratings exist
//   6. "Practice my mistakes" CTA     — spawns remediation set,
//                                       routes back via callback
//
// Each section fetches its own data lazily — failures in one don't
// block the others. All skeletons + errors handled inline.

import 'package:flutter/material.dart';
import '../../../api_service/exam_analytics_api.dart';
import 'post_attempt_widgets.dart';

class PostAttemptAnalyticsPanel extends StatefulWidget {
  final String userExamId;

  /// Called after the user taps "Practice my mistakes" and the
  /// server has spawned a fresh attempt. The integrator decides
  /// whether to push into the practice attempt screen or just
  /// snackbar a confirmation. If null the button is hidden.
  final void Function(String newUserExamId, int count)? onRemediationCreated;

  /// Pass false for quiz-style screens that don't have a cohort
  /// (typically because the cohort_size is too small or the
  /// `submitted_at` filter on `cohortPercentile` isn't reliable
  /// for daily quizzes).
  final bool showCohortPercentile;

  /// Pass false to skip the Claude pattern-summary fetch. Useful
  /// for free-tier users where AI hooks are gated.
  final bool showPatternSummary;

  const PostAttemptAnalyticsPanel({
    super.key,
    required this.userExamId,
    this.onRemediationCreated,
    this.showCohortPercentile = true,
    this.showPatternSummary = true,
  });

  @override
  State<PostAttemptAnalyticsPanel> createState() => _PostAttemptAnalyticsPanelState();
}

class _PostAttemptAnalyticsPanelState extends State<PostAttemptAnalyticsPanel> {
  final ExamAnalyticsApi _api = ExamAnalyticsApi();

  late Future<HeatmapResult> _heatmap;
  late Future<TimePressureResult> _time;
  late Future<ConfidenceCalibration> _calibration;
  Future<CohortPercentile>? _cohort;
  Future<PatternSummary>? _summary;
  bool _remediationLoading = false;

  @override
  void initState() {
    super.initState();
    _heatmap = _api.heatmap(widget.userExamId);
    _time = _api.timePressure(widget.userExamId);
    _calibration = _api.confidenceCalibration(widget.userExamId);
    if (widget.showCohortPercentile) _cohort = _api.cohortPercentile(widget.userExamId);
    if (widget.showPatternSummary) _summary = _api.patternSummary(widget.userExamId);
  }

  Future<void> _buildRemediation() async {
    setState(() => _remediationLoading = true);
    try {
      final r = await _api.buildRemediation(widget.userExamId);
      if (!mounted) return;
      if (r.userExamId == null || r.count == 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No wrong answers to remediate — well done!'),
        ));
      } else {
        widget.onRemediationCreated?.call(r.userExamId!, r.count);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Remediation set ready: ${r.count} questions'),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not build remediation set: $e'),
        ));
      }
    } finally {
      if (mounted) setState(() => _remediationLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_summary != null) ...[
          FutureBuilder<PatternSummary>(
            future: _summary,
            builder: (ctx, snap) {
              if (snap.hasData && snap.data!.text.isNotEmpty) {
                return PatternSummaryCard(summary: snap.data!);
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 16),
        ],

        if (_cohort != null) ...[
          _section(t, 'Where you stand'),
          FutureBuilder<CohortPercentile>(
            future: _cohort,
            builder: (ctx, snap) => _wrap(snap,
                builder: (data) => CohortPercentileBar(data: data)),
          ),
          const SizedBox(height: 24),
        ],

        _section(t, 'Topic weaknesses'),
        FutureBuilder<HeatmapResult>(
          future: _heatmap,
          builder: (ctx, snap) => _wrap(snap,
              builder: (data) => TopicHeatmapView(data: data)),
        ),
        const SizedBox(height: 24),

        _section(t, 'Time pressure'),
        FutureBuilder<TimePressureResult>(
          future: _time,
          builder: (ctx, snap) => _wrap(snap,
              builder: (data) => TimePressureQuadrant(data: data)),
        ),
        const SizedBox(height: 24),

        FutureBuilder<ConfidenceCalibration>(
          future: _calibration,
          builder: (ctx, snap) {
            if (snap.hasData && snap.data!.totalCount > 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConfidenceCalibrationChart(data: snap.data!),
                  const SizedBox(height: 24),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),

        if (widget.onRemediationCreated != null)
          FilledButton.icon(
            onPressed: _remediationLoading ? null : _buildRemediation,
            icon: _remediationLoading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.repeat),
            label: const Text('Practice my mistakes'),
          ),
      ],
    );
  }

  Widget _section(ThemeData t, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label,
            style: t.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: t.colorScheme.onSurfaceVariant,
                letterSpacing: 0.04 * 14)),
      );

  Widget _wrap<T>(AsyncSnapshot<T> snap, {required Widget Function(T data) builder}) {
    if (snap.hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('Could not load: ${snap.error}',
            style: TextStyle(color: Theme.of(context).colorScheme.error)),
      );
    }
    if (!snap.hasData) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return builder(snap.data as T);
  }
}
