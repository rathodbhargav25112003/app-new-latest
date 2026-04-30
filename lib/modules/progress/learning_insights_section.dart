// ignore_for_file: deprecated_member_use, library_private_types_in_public_api

import 'package:flutter/material.dart';

import 'package:shusruta_lms/api_service/api_service.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';

/// Learning Insights — drops into the bottom of ProgressScreen.
/// Renders three pieces in a single section:
///   1. Current streak / longest streak card with a 7-day dot strip
///   2. Last-7-days MCQ accuracy + volume card
///   3. Top-5 strongest and weakest topics by accuracy
///
/// All three pieces hit `/api/user/streak`, `/api/user/analytics/summary`
/// and `/api/user/topic-mastery` in parallel on first build. Each card
/// collapses to a compact loading pill while its data is in flight and
/// silently hides itself if the endpoint fails (so the page never breaks).
///
/// Preserved public contract:
///   • `LearningInsightsSection({super.key, this.onReviewTap})`
///   • `final VoidCallback? onReviewTap` — tapped when the user hits
///     the "Review queue" CTA in the streak card.
class LearningInsightsSection extends StatefulWidget {
  const LearningInsightsSection({super.key, this.onReviewTap});

  /// Tapped when the user hits the "Review queue" CTA in the streak card.
  /// Wire this to your review queue route.
  final VoidCallback? onReviewTap;

  @override
  State<LearningInsightsSection> createState() =>
      _LearningInsightsSectionState();
}

class _LearningInsightsSectionState extends State<LearningInsightsSection> {
  Map<String, dynamic>? _streak;
  Map<String, dynamic>? _analytics;
  List<Map<String, dynamic>> _mastery = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final results = await Future.wait([
        ApiService().getUserStreak(),
        ApiService().getUserAnalyticsSummary(),
        ApiService().getTopicMastery(),
      ]);
      if (!mounted) return;
      setState(() {
        _streak = results[0] as Map<String, dynamic>?;
        _analytics = results[1] as Map<String, dynamic>?;
        _mastery = (results[2] as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.s24),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryColor,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: AppTokens.s16,
            bottom: AppTokens.s8,
          ),
          child: Text(
            'Learning Insights',
            style: AppTokens.titleSm(context).copyWith(
              fontWeight: FontWeight.w700,
              color: AppTokens.ink(context),
            ),
          ),
        ),
        if (_streak != null)
          _StreakCard(streak: _streak!, onReviewTap: widget.onReviewTap),
        if (_analytics != null) _AnalyticsCard(analytics: _analytics!),
        if (_mastery.isNotEmpty) _TopicMasteryCard(items: _mastery),
      ],
    );
  }
}

// ──────────────────────────── Streak Card ───────────────────────────────────

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak, this.onReviewTap});

  final Map<String, dynamic> streak;
  final VoidCallback? onReviewTap;

  @override
  Widget build(BuildContext context) {
    final current = (streak['current_streak'] as num?)?.toInt() ?? 0;
    final longest = (streak['longest_streak'] as num?)?.toInt() ?? 0;
    final weekly = (streak['weekly'] as List?) ?? const [];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppTokens.s8),
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        border: Border.all(color: AppTokens.border(context)),
        borderRadius: BorderRadius.circular(AppTokens.r16),
        boxShadow: AppTokens.shadow1(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: AppTokens.warningSoft(context),
                  borderRadius: BorderRadius.circular(AppTokens.r8),
                ),
                child: Icon(
                  Icons.local_fire_department,
                  color: AppTokens.warning(context),
                  size: 22,
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Text(
                'Current Streak',
                style: AppTokens.body(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTokens.ink(context),
                ),
              ),
              const Spacer(),
              if (onReviewTap != null)
                InkWell(
                  onTap: onReviewTap,
                  borderRadius: BorderRadius.circular(AppTokens.r8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.s8,
                      vertical: AppTokens.s4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTokens.warningSoft(context),
                      borderRadius: BorderRadius.circular(AppTokens.r8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.replay_circle_filled_outlined,
                          size: 16,
                          color: AppTokens.warning(context),
                        ),
                        const SizedBox(width: AppTokens.s4),
                        Text(
                          'Review queue',
                          style: AppTokens.caption(context).copyWith(
                            color: AppTokens.warning(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$current',
                style: AppTokens.titleSm(context).copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppTokens.ink(context),
                  height: 1,
                ),
              ),
              const SizedBox(width: AppTokens.s4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  current == 1 ? 'day' : 'days',
                  style: AppTokens.caption(context).copyWith(
                    color: AppTokens.muted(context),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Longest: $longest',
                style: AppTokens.caption(context).copyWith(
                  color: AppTokens.muted(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          _WeekDots(weekly: weekly),
        ],
      ),
    );
  }
}

class _WeekDots extends StatelessWidget {
  const _WeekDots({required this.weekly});
  final List<dynamic> weekly;

  @override
  Widget build(BuildContext context) {
    // Expect 7 entries, one per day of the last week.
    final cells =
        weekly.length >= 7 ? weekly.sublist(weekly.length - 7) : weekly;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(cells.length, (i) {
        final cell = cells[i];
        final active = cell is Map && (cell['active'] == true);
        final dayLabel =
            (cell is Map ? (cell['label']?.toString() ?? '') : '');
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              children: [
                Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color: active
                        ? AppTokens.warning(context)
                        : AppTokens.surface2(context),
                    borderRadius: BorderRadius.circular(AppTokens.r8),
                  ),
                ),
                const SizedBox(height: AppTokens.s4),
                Text(
                  dayLabel,
                  style: AppTokens.caption(context).copyWith(
                    fontSize: 10,
                    color: active
                        ? AppTokens.warning(context)
                        : AppTokens.muted(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────── Analytics Card ─────────────────────────────────

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({required this.analytics});
  final Map<String, dynamic> analytics;

  @override
  Widget build(BuildContext context) {
    final attempts = (analytics['questions_last_7d'] as num?)?.toInt() ?? 0;
    final correct = (analytics['correct_last_7d'] as num?)?.toInt() ?? 0;
    final totalAttempts =
        (analytics['total_attempts'] as num?)?.toInt() ?? 0;
    final totalCorrect = (analytics['total_correct'] as num?)?.toInt() ?? 0;
    final pct7d = attempts == 0 ? 0 : ((correct / attempts) * 100).round();
    final pctAll = totalAttempts == 0
        ? 0
        : ((totalCorrect / totalAttempts) * 100).round();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppTokens.s8),
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        border: Border.all(color: AppTokens.border(context)),
        borderRadius: BorderRadius.circular(AppTokens.r16),
        boxShadow: AppTokens.shadow1(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: AppTokens.successSoft(context),
                  borderRadius: BorderRadius.circular(AppTokens.r8),
                ),
                child: Icon(
                  Icons.insights,
                  color: AppTokens.success(context),
                  size: 22,
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Text(
                'Last 7 days',
                style: AppTokens.body(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTokens.ink(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s16),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  title: 'Questions',
                  value: '$attempts',
                  subtitle: '$correct correct',
                ),
              ),
              Expanded(
                child: _StatTile(
                  title: 'Accuracy',
                  value: '$pct7d%',
                  subtitle: 'All-time $pctAll%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.title,
    required this.value,
    required this.subtitle,
  });
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTokens.caption(context).copyWith(
            color: AppTokens.muted(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTokens.s4),
        Text(
          value,
          style: AppTokens.titleSm(context).copyWith(
            fontWeight: FontWeight.w800,
            color: AppTokens.ink(context),
            height: 1,
          ),
        ),
        const SizedBox(height: AppTokens.s4),
        Text(
          subtitle,
          style: AppTokens.caption(context).copyWith(
            color: AppTokens.muted(context),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────── Topic Mastery Card ──────────────────────────────

class _TopicMasteryCard extends StatelessWidget {
  const _TopicMasteryCard({required this.items});
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    // Sort by accuracy ascending, then grab weakest 3 + strongest 3.
    final sorted = List<Map<String, dynamic>>.from(items);
    sorted.sort((a, b) {
      final ap = (a['accuracy_pct'] as num?)?.toDouble() ?? 0;
      final bp = (b['accuracy_pct'] as num?)?.toDouble() ?? 0;
      return ap.compareTo(bp);
    });
    final weakest = sorted.take(3).toList();
    final strongest = sorted.reversed.take(3).toList();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppTokens.s8),
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        border: Border.all(color: AppTokens.border(context)),
        borderRadius: BorderRadius.circular(AppTokens.r16),
        boxShadow: AppTokens.shadow1(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: AppTokens.accentSoft(context),
                  borderRadius: BorderRadius.circular(AppTokens.r8),
                ),
                child: Icon(
                  Icons.school_outlined,
                  color: AppTokens.accent(context),
                  size: 22,
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Text(
                'Topic Mastery',
                style: AppTokens.body(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTokens.ink(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s16),
          _MasteryGroup(
            title: 'Needs work',
            items: weakest,
            colorAccent: AppTokens.danger(context),
            softAccent: AppTokens.dangerSoft(context),
          ),
          const SizedBox(height: AppTokens.s16),
          _MasteryGroup(
            title: 'Strongest',
            items: strongest,
            colorAccent: AppTokens.success(context),
            softAccent: AppTokens.successSoft(context),
          ),
        ],
      ),
    );
  }
}

class _MasteryGroup extends StatelessWidget {
  const _MasteryGroup({
    required this.title,
    required this.items,
    required this.colorAccent,
    required this.softAccent,
  });
  final String title;
  final List<Map<String, dynamic>> items;
  final Color colorAccent;
  final Color softAccent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s8,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: softAccent,
            borderRadius: BorderRadius.circular(AppTokens.r8),
          ),
          child: Text(
            title,
            style: AppTokens.caption(context).copyWith(
              color: colorAccent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: AppTokens.s8),
        ...items.map((it) {
          final topic = (it['topic'] ?? '').toString();
          final pct = ((it['accuracy_pct'] as num?)?.toDouble() ?? 0)
              .clamp(0, 100);
          final attempts = (it['attempts'] as num?)?.toInt() ?? 0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTokens.s4 + 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        topic,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTokens.caption(context).copyWith(
                          color: AppTokens.ink(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${pct.toStringAsFixed(0)}%  ·  $attempts',
                      style: AppTokens.caption(context).copyWith(
                        color: AppTokens.muted(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTokens.r8),
                  child: LinearProgressIndicator(
                    value: pct / 100.0,
                    minHeight: 5,
                    backgroundColor: AppTokens.surface2(context),
                    color: colorAccent,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
