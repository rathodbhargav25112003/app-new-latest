import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:photo_view/photo_view.dart';

import '../../helpers/app_feedback.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/comman_widget.dart' show parseCustomSyntax;
import '../../helpers/empty_state.dart';
import '../../helpers/haptics.dart';
import '../../helpers/share_helpers.dart';
import '../../services/daily_review_service.dart';
import '../reports/explanation_common_widget.dart'
    show CommonExplanationWidget, preprocessDocument;
import 'streak_celebration_sheet.dart';

/// DailyReviewSessionScreen — full Q-by-Q answering UI with rich
/// content rendering identical to the rest of the MCQ surfaces.
///
/// Renders:
///  • Question prompt — split on `----image----` markers; text
///    interleaved with [PhotoView]-zoomable network images.
///  • Options — Apple-style A/B/C/D tiles with reveal states.
///  • Explanation — Quill rendering via [CommonExplanationWidget].
///    If the question has saved [annotationData] (the user's
///    highlights from a previous attempt), those highlights load
///    back. Otherwise [parseCustomSyntax] + [preprocessDocument]
///    convert the raw markdown-ish explanation into a Quill Delta.
///  • Explanation images — shown after the Quill, also zoomable.
///
/// Pure offline — every byte rendered came from the
/// SharedPreferences pool. The user can answer 20 questions on a
/// metro ride with no network.
class DailyReviewSessionScreen extends StatefulWidget {
  const DailyReviewSessionScreen({super.key, required this.deck});

  final List<ReviewQuestion> deck;

  static Route<dynamic> route(List<ReviewQuestion> deck) {
    return CupertinoPageRoute(
      builder: (_) => DailyReviewSessionScreen(deck: deck),
    );
  }

  @override
  State<DailyReviewSessionScreen> createState() =>
      _DailyReviewSessionScreenState();
}

class _DailyReviewSessionScreenState extends State<DailyReviewSessionScreen> {
  int _index = 0;
  int _correct = 0;
  int _wrong = 0;
  String? _picked; // user's selection on the current question
  bool _revealed = false; // true after user submits or skips

  /// Quill controller — recreated per question via [_buildQuillController]
  /// because each question has its own annotation/explanation pair.
  QuillController? _quillController;

  ReviewQuestion get _q => widget.deck[_index];

  bool get _isLast => _index == widget.deck.length - 1;
  bool get _hasDeck => widget.deck.isNotEmpty;

  @override
  void dispose() {
    _quillController?.dispose();
    super.dispose();
  }

  // ─── Quill builder ────────────────────────────────────────────────

  /// Build a read-only [QuillController] for the current question's
  /// explanation. Mirrors the logic in `practice_test_exam_screen
  /// .getExplanationText` so user-saved highlights survive.
  QuillController _buildQuillController(ReviewQuestion q) {
    Document document;

    if (q.annotationData != null &&
        q.annotationData!.isNotEmpty &&
        q.annotationData.toString() != "[{}]") {
      try {
        document = Document.fromJson(q.annotationData!);
      } catch (_) {
        document = _docFromExplanation(q.explanation ?? '');
      }
    } else {
      document = _docFromExplanation(q.explanation ?? '');
    }

    return QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  Document _docFromExplanation(String explanation) {
    final preprocessed = preprocessDocument(explanation);
    if (preprocessed.trim().isEmpty) {
      return Document()..insert(0, "No explanation available\n");
    }
    try {
      final parsed = parseCustomSyntax(preprocessed);
      if (parsed.isEmpty) {
        return Document()..insert(0, "No explanation available\n");
      }
      return Document.fromJson(parsed);
    } catch (_) {
      // Fallback: render raw text.
      return Document()..insert(0, '$explanation\n');
    }
  }

  // ─── Session lifecycle ────────────────────────────────────────────

  Future<void> _submit() async {
    if (_picked == null || _revealed) return;
    final isCorrect = _picked == _q.correctValue;
    Haptics.medium();
    setState(() {
      _revealed = true;
      if (isCorrect) {
        _correct++;
      } else {
        _wrong++;
      }
      // Lazily build the Quill controller for the explanation reveal.
      _quillController?.dispose();
      _quillController = _buildQuillController(_q);
    });
    // ignore: discarded_futures
    DailyReviewService.instance.markSeen(_q.id);
  }

  Future<void> _skip() async {
    if (_revealed) return;
    Haptics.selection();
    setState(() {
      _revealed = true;
      _quillController?.dispose();
      _quillController = _buildQuillController(_q);
    });
    // ignore: discarded_futures
    DailyReviewService.instance.markSeen(_q.id);
  }

  Future<void> _next() async {
    Haptics.selection();
    if (_isLast) {
      // Session done — log it, fire celebration if applicable.
      final result = await DailyReviewService.instance.recordSessionCompleted();
      if (!mounted) return;
      if (result.hitMilestone) {
        await StreakCelebrationSheet.show(context, streak: result.streak);
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(
          builder: (_) => _SessionSummary(
            correct: _correct,
            wrong: _wrong,
            total: widget.deck.length,
            streak: result.streak,
          ),
        ),
      );
      return;
    }
    setState(() {
      _index++;
      _picked = null;
      _revealed = false;
      _quillController?.dispose();
      _quillController = null;
    });
  }

  Future<void> _confirmExit() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: AppTokens.surface(dCtx),
        shape: RoundedRectangleBorder(borderRadius: AppTokens.radius16),
        title: Text('Leave session?', style: AppTokens.titleLg(dCtx)),
        content: Text(
          'Your progress on the questions you\'ve seen will count, but '
          'your streak will only update if you finish the full deck.',
          style: AppTokens.body(dCtx),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(false),
            child: Text('Stay',
                style: AppTokens.titleSm(dCtx)
                    .copyWith(color: AppTokens.ink2(dCtx))),
          ),
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(true),
            child: Text('Leave',
                style: AppTokens.titleSm(dCtx).copyWith(
                  color: AppTokens.danger(dCtx),
                  fontWeight: FontWeight.w700,
                )),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  // ─── Image helpers ────────────────────────────────────────────────

  /// Open a [PhotoView] dialog so the user can pinch-zoom on a
  /// question/explanation image. Same pattern as the rest of the app.
  void _openZoomImage(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(8),
        child: SizedBox(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.7,
          child: PhotoView(
            imageProvider: NetworkImage(url),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            backgroundDecoration:
                const BoxDecoration(color: Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionImage(String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.s8),
      child: GestureDetector(
        onTap: () => _openZoomImage(url),
        child: ClipRRect(
          borderRadius: AppTokens.radius12,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (ctx, child, progress) {
              if (progress == null) return child;
              return Container(
                height: 180,
                color: AppTokens.surface2(context),
                alignment: Alignment.center,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTokens.accent(context),
                ),
              );
            },
            errorBuilder: (_, __, ___) => Container(
              height: 100,
              color: AppTokens.surface2(context),
              alignment: Alignment.center,
              child: Icon(Icons.image_not_supported_outlined,
                  color: AppTokens.muted(context)),
            ),
          ),
        ),
      ),
    );
  }

  /// Render the question prompt + interleaved images.
  ///
  /// The same `----text----` separator convention used in the practice
  /// screen — each `----…----` block is replaced with `splittedImage`
  /// and we then split on that token. The Nth chunk pairs with the
  /// Nth image in [questionImages].
  Widget _buildQuestionContent(BuildContext context) {
    final raw = _q.text.replaceAllMapped(
        RegExp(r'----(.*?)----', multiLine: true), (m) => 'splittedImage');
    final chunks = raw.split('splittedImage');
    final images = _q.questionImages;

    final widgets = <Widget>[];
    for (var i = 0; i < chunks.length; i++) {
      final txt = chunks[i]
          .trim()
          .replaceAll('\t\t\t--', '                 •')
          .replaceAll('\t\t--', '           •')
          .replaceAll('\t--', '     •')
          .replaceAll('--', '•');
      if (txt.isNotEmpty) {
        widgets.add(
          Text(
            txt,
            style: AppTokens.body(context).copyWith(
              fontSize: 16,
              color: AppTokens.ink(context),
              fontWeight: FontWeight.w500,
              height: 1.55,
            ),
          ),
        );
      }
      if (i < images.length) {
        widgets.add(_buildQuestionImage(images[i]));
      }
    }

    // If text didn't have any image markers but the question still
    // has images, append them at the end.
    if (chunks.length == 1 && images.isNotEmpty) {
      for (final url in images) {
        widgets.add(_buildQuestionImage(url));
      }
    }

    if (images.isNotEmpty) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          'Tap any image to zoom in.',
          style: AppTokens.caption(context),
        ),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildExplanationContent(BuildContext context) {
    if (_quillController == null) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface2(context),
        borderRadius: AppTokens.radius16,
        border: Border(
          left: BorderSide(color: AppTokens.accent(context), width: 3),
        ),
      ),
      padding: const EdgeInsets.all(AppTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded,
                  color: AppTokens.accent(context), size: 18),
              const SizedBox(width: AppTokens.s8),
              Text(
                'Explanation',
                style: AppTokens.titleSm(context).copyWith(
                  color: AppTokens.accent(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          // Quill rendering — supports all the rich formatting the
          // app uses elsewhere (headings, lists, tables, colors,
          // sup/sub, embedded images, user highlights).
          CommonExplanationWidget(
            controller: _quillController!,
            textPercentage: 100,
          ),
          if (_q.explanationImages.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s12),
            ...(_q.explanationImages.map(_buildQuestionImage)),
          ],
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_hasDeck) {
      return Scaffold(
        backgroundColor: AppTokens.scaffold(context),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppTokens.scaffold(context),
          leading: IconButton(
            icon: Icon(Icons.close_rounded, color: AppTokens.ink(context)),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: const EmptyState(
          icon: Icons.replay_circle_filled_rounded,
          title: 'Empty deck',
          subtitle: 'Bookmark or mark some questions for review first.',
        ),
      );
    }

    final progress = (_index + (_revealed ? 1 : 0)) / widget.deck.length;

    return WillPopScope(
      onWillPop: () async {
        await _confirmExit();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTokens.scaffold(context),
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: AppTokens.scaffold(context),
          leading: IconButton(
            tooltip: 'Close',
            icon: Icon(Icons.close_rounded,
                color: AppTokens.ink(context), size: 22),
            onPressed: _confirmExit,
          ),
          title: Text(
            "Review ${_index + 1}/${widget.deck.length}",
            style: AppTokens.titleLg(context),
          ),
          centerTitle: false,
          actions: [
            // Post-reveal: let the user share question + solution.
            if (_revealed)
              IconButton(
                tooltip: 'Share',
                icon: Icon(Icons.ios_share_rounded,
                    color: AppTokens.ink(context), size: 20),
                onPressed: () {
                  final correctIdx = _q.options
                      .indexWhere((o) => o.value == _q.correctValue);
                  ShareHelpers.shareQuestionWithSolution(
                    context,
                    questionText: _q.text,
                    optionLabels:
                        _q.options.map((o) => o.label).toList(growable: false),
                    correctIndex: correctIdx < 0 ? 0 : correctIdx,
                    explanation: _q.explanation,
                  );
                },
              ),
            const SizedBox(width: AppTokens.s8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTokens.surface3(context),
                color: AppTokens.accent(context),
                minHeight: 4,
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppTokens.s24, AppTokens.s16, AppTokens.s24, AppTokens.s16),
            child: Column(
              children: [
                if ((_q.topicName ?? '').isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.s8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTokens.accentSoft(context),
                        borderRadius: AppTokens.radius8,
                      ),
                      child: Text(
                        _q.topicName!,
                        style: AppTokens.caption(context).copyWith(
                          color: AppTokens.accent(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: AppTokens.s12),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Question card (text + interleaved images).
                        Container(
                          padding: const EdgeInsets.all(AppTokens.s16),
                          decoration: BoxDecoration(
                            color: AppTokens.surface(context),
                            borderRadius: AppTokens.radius16,
                            border: Border.all(
                                color: AppTokens.border(context),
                                width: 0.5),
                          ),
                          child: _buildQuestionContent(context),
                        ),
                        const SizedBox(height: AppTokens.s16),

                        // Options.
                        ..._q.options.asMap().entries.map((e) {
                          final i = e.key;
                          final o = e.value;
                          return _OptionTile(
                            index: i,
                            option: o,
                            isPicked: _picked == o.value,
                            isCorrectAnswer: o.value == _q.correctValue,
                            isRevealed: _revealed,
                            onTap: _revealed
                                ? null
                                : () {
                                    Haptics.selection();
                                    setState(() => _picked = o.value);
                                  },
                          );
                        }),

                        // Explanation Quill + images (post-reveal).
                        if (_revealed) ...[
                          const SizedBox(height: AppTokens.s16),
                          _buildExplanationContent(context),
                        ],
                        const SizedBox(height: AppTokens.s16),
                      ],
                    ),
                  ),
                ),

                // Bottom action bar.
                Row(
                  children: [
                    if (!_revealed) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _skip,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTokens.ink2(context),
                            side: BorderSide(
                              color: AppTokens.border(context),
                              width: 0.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: AppTokens.radius16),
                          ),
                          child: Text('Skip',
                              style: AppTokens.titleSm(context)
                                  .copyWith(color: AppTokens.ink2(context))),
                        ),
                      ),
                      const SizedBox(width: AppTokens.s12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _picked == null ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTokens.accent(context),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                AppTokens.surface3(context),
                            disabledForegroundColor:
                                AppTokens.muted(context),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: AppTokens.radius16),
                          ),
                          child: Text(
                            _picked == null ? 'Pick an option' : 'Submit',
                            style: AppTokens.titleSm(context).copyWith(
                              color: _picked == null
                                  ? AppTokens.muted(context)
                                  : Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ] else
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _next,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTokens.accent(context),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: AppTokens.radius16),
                          ),
                          child: Text(
                            _isLast ? 'Finish session' : 'Next question',
                            style: AppTokens.titleSm(context).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.index,
    required this.option,
    required this.isPicked,
    required this.isCorrectAnswer,
    required this.isRevealed,
    required this.onTap,
  });

  final int index;
  final ReviewOption option;
  final bool isPicked;
  final bool isCorrectAnswer;
  final bool isRevealed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color border = AppTokens.border(context);
    Color fill = AppTokens.surface(context);
    Color textColor = AppTokens.ink(context);

    if (!isRevealed && isPicked) {
      border = AppTokens.accent(context);
      fill = AppTokens.accentSoft(context);
    }

    if (isRevealed) {
      if (isCorrectAnswer) {
        border = AppTokens.success(context);
        fill = AppTokens.successSoft(context);
      } else if (isPicked) {
        border = AppTokens.danger(context);
        fill = AppTokens.dangerSoft(context);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppTokens.radius12,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.s12, vertical: AppTokens.s12),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: AppTokens.radius12,
              border: Border.all(
                color: border,
                width: isPicked || (isRevealed && isCorrectAnswer) ? 1.4 : 0.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTokens.surface(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: border,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    String.fromCharCode(65 + index), // A, B, C, D
                    style: AppTokens.titleSm(context).copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.s12),
                Expanded(
                  child: Text(
                    option.label,
                    style: AppTokens.body(context).copyWith(
                      color: textColor,
                    ),
                  ),
                ),
                if (isRevealed && isCorrectAnswer)
                  Icon(Icons.check_circle_rounded,
                      color: AppTokens.success(context), size: 20)
                else if (isRevealed && isPicked && !isCorrectAnswer)
                  Icon(Icons.cancel_rounded,
                      color: AppTokens.danger(context), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Session summary screen — shown after the last question.
class _SessionSummary extends StatelessWidget {
  const _SessionSummary({
    required this.correct,
    required this.wrong,
    required this.total,
    required this.streak,
  });

  final int correct;
  final int wrong;
  final int total;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final accuracy = total == 0 ? 0.0 : correct / total;
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppTokens.scaffold(context),
        title: Text("Session complete", style: AppTokens.titleLg(context)),
        leading: IconButton(
          icon: Icon(Icons.close_rounded,
              color: AppTokens.ink(context), size: 22),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTokens.s24),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTokens.successSoft(context),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: AppTokens.success(context),
                    size: 56,
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.s20),
              Text(
                accuracy >= 0.8
                    ? "You crushed it!"
                    : accuracy >= 0.5
                        ? "Nice work."
                        : "Done — keep at it.",
                textAlign: TextAlign.center,
                style: AppTokens.displayMd(context),
              ),
              const SizedBox(height: AppTokens.s8),
              Text(
                "$correct correct out of $total. Streak: $streak day${streak == 1 ? '' : 's'}.",
                textAlign: TextAlign.center,
                style: AppTokens.body(context),
              ),
              const SizedBox(height: AppTokens.s24),
              _StatTriple(correct: correct, wrong: wrong, total: total),
              const Spacer(),
              if (streak > 1) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        ShareHelpers.shareStreak(context, streak: streak),
                    icon: Icon(Icons.ios_share_rounded,
                        size: 18, color: AppTokens.accent(context)),
                    label: Text(
                      'Share my $streak-day streak',
                      style: AppTokens.titleSm(context).copyWith(
                        color: AppTokens.accent(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: AppTokens.accent(context), width: 0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: AppTokens.radius16),
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.s12),
              ],
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTokens.accent(context),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: AppTokens.radius16),
                  ),
                  child: Text(
                    "Done",
                    style: AppTokens.titleSm(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTriple extends StatelessWidget {
  const _StatTriple({
    required this.correct,
    required this.wrong,
    required this.total,
  });
  final int correct;
  final int wrong;
  final int total;

  @override
  Widget build(BuildContext context) {
    final skipped = (total - correct - wrong).clamp(0, total);
    Widget cell(String label, String value, Color tint) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppTokens.s12),
            decoration: BoxDecoration(
              color: AppTokens.surface(context),
              borderRadius: AppTokens.radius12,
              border:
                  Border.all(color: AppTokens.border(context), width: 0.5),
            ),
            child: Column(
              children: [
                Text(value,
                    style: AppTokens.numeric(context, size: 22)
                        .copyWith(color: tint)),
                const SizedBox(height: 2),
                Text(label, style: AppTokens.caption(context)),
              ],
            ),
          ),
        );
    return Row(
      children: [
        cell('Correct', correct.toString(), AppTokens.success(context)),
        const SizedBox(width: AppTokens.s8),
        cell('Wrong', wrong.toString(), AppTokens.danger(context)),
        const SizedBox(width: AppTokens.s8),
        cell('Skipped', skipped.toString(), AppTokens.muted(context)),
      ],
    );
  }
}
