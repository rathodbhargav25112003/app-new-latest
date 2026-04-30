// McqSolutionActionBar — single drop-in widget that bundles all the
// new MCQ-review-screen actions into one row. Designed to slot into
// `practice_test_solution_exam_screen.dart` and `test_exam_screen.dart`
// just below the explanation block.
//
// Includes:
//   • Highlighter (3 colors)
//   • Sticky-note button
//   • Cortex AI (multi-turn, MCQ-anchored)
//   • Mistake debrief (only shows when this answer was wrong)
//   • Mnemonic generator
//   • Diagram generator
//   • Make flashcards
//   • Audio explain (TTS via flutter_tts)
//   • Add to review queue
//   • Discussion thread
//   • Share / report wrong Q
//
// Most actions delegate to existing CortexIntegrationHelpers + this
// module's McqReviewService. Minimal new state — local only.

import 'package:flutter/material.dart';

import '../../cortex/cortex_integration_helpers.dart';
import '../mcq_review_service.dart';
import 'discussion_sheet.dart';
import 'audio_explain_button.dart';
// Wave-2 backend hooks — added April 2026. The existing Cortex
// "mistake debrief" / "ask Cortex" paths still work; these add the
// dedicated question-scoped endpoints (Sonnet why-wrong drawer,
// multi-turn doubt chat, similar-question generator, real
// /api/question-report).
import '../../../api_service/exam_analytics_api.dart';
import '../../new_exam_component/widgets/doubt_chat_sheet.dart';
import '../../new_exam_component/widgets/post_attempt_widgets.dart' show WhyWrongDrawer;

class McqSolutionActionBar extends StatelessWidget {
  /// Required — the question being reviewed.
  final String questionId;

  /// Required for Mistake debrief + auto-enroll
  final String? selectedOption;
  final String? correctOption;

  /// Required for Cortex MCQ context
  final String? examId;
  final String? userExamId;
  final String examType; // 'regular' | 'mock'

  /// Used by audio-explain endpoint (full Q content for prompt building)
  final String? questionText;
  final List<dynamic>? options;
  final String? briefExplanation;

  /// Set true if you want the bar to show the mistake-debrief button
  /// when the student got this Q wrong.
  final bool wasWrong;

  /// Sticky-notes / highlighter callbacks — wire to your existing
  /// note + highlight handlers (the module is intentionally
  /// agnostic about how those are stored).
  final VoidCallback? onOpenNotes;
  final VoidCallback? onToggleHighlighter;

  /// Topic chip — pass a topic name to render a tappable chip that
  /// launches a Cortex deep-dive on that topic.
  final String? topic;
  final String? subtopic;
  final String? difficulty;
  final String? questionType;

  const McqSolutionActionBar({
    super.key,
    required this.questionId,
    this.selectedOption,
    this.correctOption,
    this.examId,
    this.userExamId,
    this.examType = 'regular',
    this.questionText,
    this.options,
    this.briefExplanation,
    this.wasWrong = false,
    this.onOpenNotes,
    this.onToggleHighlighter,
    this.topic,
    this.subtopic,
    this.difficulty,
    this.questionType,
  });

  @override
  Widget build(BuildContext context) {
    // Minimalistic redesign (April 2026): the action bar previously
    // exposed 10 pills which created a wall of buttons. We now show
    // 3 primary chips inline (Highlight, Notes, Ask Cortex), the
    // wrong-answer-only "Why I was wrong" chip when relevant, and a
    // single "More" chip that opens an icon grid containing every
    // other action. Topic / difficulty chips are kept above for
    // discoverability of the deep-dive route.
    final wrongChipVisible = wasWrong && selectedOption != null;
    return Column(
      children: [
        if (_hasChips) _buildChipsRow(context),
        if (_hasChips) const SizedBox(height: 8),

        // Single-row primary actions — never wraps. Designed so the
        // 4 most-used actions fit even on narrow phones.
        Row(
          children: [
            if (onToggleHighlighter != null)
              _CompactPill(icon: Icons.format_color_fill, label: 'Highlight', onTap: onToggleHighlighter),
            if (onOpenNotes != null)
              _CompactPill(icon: Icons.sticky_note_2_outlined, label: 'Notes', onTap: onOpenNotes),
            _CompactPill(
              icon: Icons.auto_awesome,
              label: 'Ask Cortex',
              accent: true,
              onTap: () => CortexIntegrationHelpers.openAskCortex(
                context,
                questionId: questionId, examId: examId, userExamId: userExamId,
              ),
            ),
            if (wrongChipVisible)
              _CompactPill(
                icon: Icons.lightbulb_outline,
                label: 'Why wrong',
                color: Colors.orange,
                onTap: () => _openWhyWrong(context),
              ),
            const Spacer(),
            // Overflow — secondary actions live here so the primary
            // row stays clean. Tap surfaces a bottom-sheet of pills.
            _CompactPill(
              icon: Icons.more_horiz_rounded,
              label: 'More',
              onTap: () => _openMoreSheet(context),
            ),
          ],
        ),
      ],
    );
  }

  /// Bottom-sheet of secondary actions. Keeps the primary row tight
  /// while still surfacing every wave-2 hook one tap away.
  void _openMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              _ActionPill(
                icon: Icons.chat_bubble_outline,
                label: 'Doubt chat',
                accent: true,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => DoubtChatSheet(
                      questionId: questionId,
                      userExamId: userExamId,
                    ),
                  );
                },
              ),
              _ActionPill(
                icon: Icons.bolt_outlined,
                label: 'Similar Qs',
                onTap: () { Navigator.pop(sheetCtx); _openSimilarQs(context); },
              ),
              if (questionText != null)
                AudioExplainButton(
                  questionText: questionText!,
                  options: options ?? const [],
                  correctOption: correctOption ?? '',
                  briefExplanation: briefExplanation,
                ),
              _ActionPill(
                icon: Icons.psychology_outlined, label: 'Mnemonic',
                onTap: () {
                  Navigator.pop(sheetCtx);
                  Navigator.of(context).pushNamed(
                    'cortexModeStart',
                    arguments: {'mode_id': 'mnemonic', 'mode_label': '🧠 Make a mnemonic'},
                  );
                },
              ),
              _ActionPill(
                icon: Icons.account_tree_outlined, label: 'Diagram',
                onTap: () {
                  Navigator.pop(sheetCtx);
                  Navigator.of(context).pushNamed(
                    'cortexModeStart',
                    arguments: {'mode_id': 'diagram', 'mode_label': '📊 Generate diagram'},
                  );
                },
              ),
              _ActionPill(
                icon: Icons.repeat,
                label: 'Review later',
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  final ok = await McqReviewService().enrollManual(questionId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ok ? 'Added to review queue' : 'Failed'),
                      duration: const Duration(seconds: 2),
                    ));
                  }
                },
              ),
              _ActionPill(
                icon: Icons.forum_outlined, label: 'Discuss',
                onTap: () {
                  Navigator.pop(sheetCtx);
                  DiscussionSheet.show(context, questionId: questionId);
                },
              ),
              _ActionPill(
                icon: Icons.flag_outlined, label: 'Report',
                color: Colors.red.shade400,
                onTap: () { Navigator.pop(sheetCtx); _reportQ(context); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _hasChips => (topic != null && topic!.isNotEmpty)
      || (difficulty != null && difficulty!.isNotEmpty)
      || (questionType != null && questionType!.isNotEmpty);

  Widget _buildChipsRow(BuildContext context) {
    return Wrap(
      spacing: 5, runSpacing: 5,
      children: [
        if (difficulty != null && difficulty!.isNotEmpty)
          _Chip(label: difficulty!.toUpperCase(), color: _diffColor(difficulty!)),
        if (questionType != null && questionType!.isNotEmpty)
          _Chip(label: questionType!, color: Colors.blueGrey),
        if (topic != null && topic!.isNotEmpty)
          _Chip(
            label: subtopic != null && subtopic!.isNotEmpty ? '$topic · $subtopic' : topic!,
            color: Colors.indigo,
            onTap: () => Navigator.of(context).pushNamed(
              'cortexModeStart',
              arguments: {'mode_id': 'deep_dive', 'mode_label': '🔍 ${topic!} deep dive'},
            ),
          ),
      ],
    );
  }

  Color _diffColor(String d) {
    final s = d.toLowerCase();
    if (s.contains('easy')) return Colors.green;
    if (s.contains('tough') || s.contains('hard')) return Colors.red;
    return Colors.orange;
  }

  Future<void> _reportQ(BuildContext context) async {
    final ctrl = TextEditingController();
    String reasonValue = 'wrong_correct';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setState) => AlertDialog(
        title: const Text('Report this question'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: reasonValue,
              items: const [
                DropdownMenuItem(value: 'wrong_correct', child: Text('Wrong correct option')),
                DropdownMenuItem(value: 'broken_stem', child: Text('Broken stem / unclear')),
                DropdownMenuItem(value: 'outdated_reference', child: Text('Outdated reference')),
                DropdownMenuItem(value: 'duplicate', child: Text('Duplicate of another Q')),
                DropdownMenuItem(value: 'image_missing', child: Text('Image missing / wrong')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (v) => setState(() => reasonValue = v ?? 'wrong_correct'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl, maxLines: 3,
              decoration: const InputDecoration(hintText: 'Optional details', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
        ],
      )),
    );
    if (ok == true && context.mounted) {
      // Wave-2 dedicated /api/question-report endpoint (deduped by
      // (user, question, reason) on the server). Falls back to the
      // legacy [REPORT:reason] discussion-post path if the new
      // endpoint errors — keeps user-side UX unchanged.
      try {
        await ExamAnalyticsApi().reportQuestion(
          questionId: questionId,
          reason: _mapReasonToServer(reasonValue),
          details: ctrl.text.isEmpty ? null : ctrl.text,
          userExamId: userExamId,
        );
      } catch (_) {
        await McqReviewService().createPost(
          questionId,
          '[REPORT:$reasonValue] ${ctrl.text}',
        );
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted — thanks!')),
        );
      }
    }
  }

  /// Map the action-bar reason values to the server enum values
  /// (api/models/questionReport.model.js). Anything unrecognised
  /// falls into 'other'.
  String _mapReasonToServer(String v) {
    switch (v) {
      case 'wrong_correct': return 'wrong_correct_answer';
      case 'broken_stem': return 'ambiguous';
      case 'outdated_reference': return 'outdated';
      case 'duplicate': return 'duplicate';
      case 'image_missing': return 'image_missing';
      default: return 'other';
    }
  }

  /// Wave-2 why-wrong drawer. Hits Sonnet via the cached endpoint;
  /// shows the explanation + a "Ask a follow-up" button that opens
  /// the doubt-chat sheet for multi-turn discussion. Falls back to
  /// the existing Cortex mistake-debrief if `userExamId` is missing.
  Future<void> _openWhyWrong(BuildContext context) async {
    if (userExamId == null || userExamId!.isEmpty) {
      // Need a userExamId for the new endpoint — fall back to Cortex.
      CortexIntegrationHelpers.showMistakeDebrief(
        context,
        questionId: questionId,
        selectedOption: selectedOption!,
        correctOption: correctOption,
        examId: examId,
        userExamId: userExamId,
        examType: examType,
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => SafeArea(
        child: FutureBuilder<WhyWrongResult>(
          future: ExamAnalyticsApi().whyWrong(
            userExamId: userExamId!,
            questionId: questionId,
          ),
          builder: (ctx, snap) {
            if (!snap.hasData && snap.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Could not fetch explanation: ${snap.error}'),
              );
            }
            return WhyWrongDrawer(
              result: snap.data!,
              onOpenDoubtChat: () {
                Navigator.of(sheetCtx).pop();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => DoubtChatSheet(
                    questionId: questionId,
                    userExamId: userExamId,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Wave-2 similar-question generator. Server returns 3 generated
  /// MCQs with stems + options + correct + explanation. We render
  /// them inline in a bottom-sheet — student can read through; deep
  /// integration into a "practice these now" custom-test creation is
  /// a follow-up.
  Future<void> _openSimilarQs(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(sheetCtx).size.height * 0.75,
          child: FutureBuilder<SimilarQuestions>(
            future: ExamAnalyticsApi().similarQuestions(questionId),
            builder: (ctx, snap) {
              if (!snap.hasData && snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError || (snap.data?.questions ?? []).isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(snap.data?.error ?? 'Could not generate similar questions.'),
                );
              }
              final qs = snap.data!.questions;
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: qs.length,
                separatorBuilder: (_, __) => const Divider(height: 24),
                itemBuilder: (_, i) {
                  final q = qs[i];
                  final t = Theme.of(ctx);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Variant ${i + 1}',
                          style: t.textTheme.labelLarge?.copyWith(
                              color: t.colorScheme.primary,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(q.stem, style: t.textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      ...q.options.entries.map((e) {
                        final correct = e.key == q.correct;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 22,
                                child: Text('${e.key}.',
                                    style: t.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: correct
                                            ? t.colorScheme.tertiary
                                            : null)),
                              ),
                              Expanded(child: Text(e.value)),
                              if (correct)
                                Icon(Icons.check_circle,
                                    size: 16, color: t.colorScheme.tertiary),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: t.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(q.explanation,
                            style: t.textTheme.bodySmall),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Tight icon-with-label chip used in the primary action row. Icon-
/// only with a 1-line label below; designed so 5 of these fit
/// without wrapping on a 360dp-wide phone.
class _CompactPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool accent;
  final Color? color;
  const _CompactPill({
    required this.icon,
    required this.label,
    this.onTap,
    this.accent = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? (accent ? scheme.primary : scheme.onSurface.withOpacity(0.62));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: c),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: c),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool accent;
  final Color? color;
  const _ActionPill({required this.icon, required this.label, this.onTap, this.accent = false, this.color});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? (accent ? Colors.deepPurple : scheme.onSurface.withOpacity(0.7));
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: c.withOpacity(accent ? 0.10 : 0.06),
          border: Border.all(color: c.withOpacity(accent ? 0.40 : 0.20)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c)),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _Chip({required this.label, required this.color, this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.30)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.3),
        ),
      ),
    );
  }
}
