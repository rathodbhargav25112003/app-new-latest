// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters, use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:shusruta_lms/api_service/api_service.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';

/// Review Queue — daily spaced-repetition deck of questions a student got
/// wrong (auto-enqueued by the server on wrong-answer submit) plus any
/// manually flagged ones.
///
/// Flow: load due items → show first card → student rates it (again/hard/
/// good/easy) → post to /api/user/review/answer (server runs SM-2) → move
/// to next card. When the deck is empty show an "all caught up" state.
///
/// Preserved public contract:
///   • `ReviewQueueScreen({super.key})`
///   • Static `route(RouteSettings)` returns `CupertinoPageRoute(builder:
///     (_) => const ReviewQueueScreen())`.
///   • `ApiService().getReviewNext(limit: 20)` on init + refresh.
///   • `ApiService().submitReviewAnswer(itemId, rating, timeSpentMs)` on
///     rate — ratings: 'again', 'hard', 'good', 'easy'.
///   • Labels byte-for-byte: "Review Queue", "Show Answer", "Again",
///     "Hard", "Good", "Easy", "Explanation", "New", "${interval}d",
///     "All caught up!", "No cards due right now. Check back tomorrow —\n
///     or keep practicing to build up your deck.", "Session complete",
///     "You reviewed {N} card[s].", "Check for more",
///     "(missing question)".
class ReviewQueueScreen extends StatefulWidget {
  const ReviewQueueScreen({super.key});

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(builder: (_) => const ReviewQueueScreen());
  }

  @override
  State<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends State<ReviewQueueScreen> {
  List<Map<String, dynamic>> _items = const [];
  int _cursor = 0;
  bool _loading = true;
  bool _submitting = false;
  bool _showAnswer = false;
  DateTime? _cardStartAt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await ApiService().getReviewNext(limit: 20);
    if (!mounted) return;
    setState(() {
      _items = data;
      _cursor = 0;
      _loading = false;
      _showAnswer = false;
      _cardStartAt = data.isNotEmpty ? DateTime.now() : null;
    });
  }

  Future<void> _rate(String rating) async {
    if (_cursor >= _items.length || _submitting) return;
    final item = _items[_cursor];
    final itemId = (item['_id'] ?? '').toString();
    if (itemId.isEmpty) return;

    setState(() => _submitting = true);
    final elapsedMs = _cardStartAt == null
        ? 0
        : DateTime.now().difference(_cardStartAt!).inMilliseconds;
    await ApiService().submitReviewAnswer(
      itemId: itemId,
      rating: rating,
      timeSpentMs: elapsedMs,
    );
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _showAnswer = false;
      _cursor++;
      _cardStartAt = _cursor < _items.length ? DateTime.now() : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SafeArea(
              top: false,
              child: _buildBody(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppTokens.s8,
        left: AppTokens.s8,
        right: AppTokens.s20,
        bottom: AppTokens.s16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTokens.brand, AppTokens.brand2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(AppTokens.r8),
            child: Container(
              height: AppTokens.s32,
              width: AppTokens.s32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTokens.r8),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Text(
              'Review Queue',
              style: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: AppTokens.accent(context)),
      );
    }
    if (_items.isEmpty) {
      return _allCaughtUp(context);
    }
    if (_cursor >= _items.length) {
      return _sessionComplete(context);
    }
    return _buildCard(context, _items[_cursor]);
  }

  Widget _buildCard(BuildContext context, Map<String, dynamic> item) {
    final question = item['question'] as Map<String, dynamic>?;
    final stem = question?['question']?.toString() ?? '(missing question)';
    final options = (question?['options'] as List?) ?? const [];
    final correct = question?['correct_option']?.toString() ?? '';
    final explanation = question?['explanation']?.toString() ?? '';
    final interval = (item['interval_days'] as num?)?.toInt() ?? 0;
    final ease = (item['ease_factor'] as num?)?.toDouble() ?? 2.5;

    final progress = (_cursor + 1) / _items.length;

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppTokens.surface2(context),
          valueColor:
              AlwaysStoppedAnimation<Color>(AppTokens.accent(context)),
          minHeight: 4,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s20,
            AppTokens.s12,
            AppTokens.s20,
            AppTokens.s4,
          ),
          child: Row(
            children: [
              Text(
                '${_cursor + 1} / ${_items.length}',
                style: AppTokens.caption(context).copyWith(
                  color: AppTokens.muted(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _Chip(
                icon: Icons.schedule,
                label: interval == 0 ? 'New' : '${interval}d',
              ),
              const SizedBox(width: AppTokens.s8),
              _Chip(
                icon: Icons.bolt,
                label: ease.toStringAsFixed(2),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.s20,
              AppTokens.s12,
              AppTokens.s20,
              AppTokens.s12,
            ),
            physics: const BouncingScrollPhysics(),
            child: Container(
              padding: const EdgeInsets.all(AppTokens.s20),
              decoration: BoxDecoration(
                color: AppTokens.surface(context),
                borderRadius: BorderRadius.circular(AppTokens.r16),
                border: Border.all(color: AppTokens.border(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stem,
                    style: AppTokens.body(context).copyWith(
                      color: AppTokens.ink(context),
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppTokens.s16),
                  ...options.map((opt) {
                    final key = opt is Map
                        ? (opt['option_id']?.toString() ?? '')
                        : '';
                    final text = opt is Map
                        ? (opt['option']?.toString() ?? '')
                        : opt.toString();
                    final isCorrect = _showAnswer && key == correct;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: _OptionTile(
                        letter: key.toUpperCase(),
                        text: text,
                        isCorrect: isCorrect,
                      ),
                    );
                  }),
                  if (_showAnswer && explanation.trim().isNotEmpty) ...[
                    const SizedBox(height: AppTokens.s16),
                    _ExplanationBlock(text: explanation),
                  ],
                ],
              ),
            ),
          ),
        ),
        _buildActionBar(context),
      ],
    );
  }

  Widget _buildActionBar(BuildContext context) {
    if (!_showAnswer) {
      return Padding(
        padding: const EdgeInsets.all(AppTokens.s16),
        child: InkWell(
          onTap: () => setState(() => _showAnswer = true),
          borderRadius: BorderRadius.circular(AppTokens.r12),
          child: Container(
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTokens.brand, AppTokens.brand2],
              ),
              borderRadius: BorderRadius.circular(AppTokens.r12),
            ),
            child: Text(
              'Show Answer',
              style: AppTokens.body(context).copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(AppTokens.s16),
      child: Row(
        children: [
          Expanded(
            child: _ratingButton(
              context,
              'Again',
              ThemeManager.redAlert,
              'again',
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: _ratingButton(
              context,
              'Hard',
              const Color(0xFFFB8C00),
              'hard',
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: _ratingButton(
              context,
              'Good',
              ThemeManager.greenSuccess,
              'good',
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: _ratingButton(
              context,
              'Easy',
              const Color(0xFF1E88E5),
              'easy',
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingButton(
    BuildContext context,
    String label,
    Color color,
    String rating,
  ) {
    return InkWell(
      onTap: _submitting ? null : () => _rate(rating),
      borderRadius: BorderRadius.circular(AppTokens.r12),
      child: Opacity(
        opacity: _submitting ? 0.5 : 1,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppTokens.r12),
          ),
          child: Text(
            label,
            style: AppTokens.caption(context).copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _allCaughtUp(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.s24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 72,
              color: ThemeManager.evolveYellow,
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              'All caught up!',
              style: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppTokens.ink(context),
              ),
            ),
            const SizedBox(height: AppTokens.s8),
            Text(
              'No cards due right now. Check back tomorrow —\nor keep practicing to build up your deck.',
              textAlign: TextAlign.center,
              style: AppTokens.body(context).copyWith(
                color: AppTokens.muted(context),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sessionComplete(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.s24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 72,
              color: AppTokens.accent(context),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              'Session complete',
              style: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppTokens.ink(context),
              ),
            ),
            const SizedBox(height: AppTokens.s8),
            Text(
              'You reviewed ${_items.length} card${_items.length == 1 ? "" : "s"}.',
              style: AppTokens.body(context).copyWith(
                color: AppTokens.muted(context),
              ),
            ),
            const SizedBox(height: AppTokens.s20),
            InkWell(
              onTap: () {
                setState(() => _loading = true);
                _load();
              },
              borderRadius: BorderRadius.circular(AppTokens.r12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s24,
                  vertical: AppTokens.s12,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTokens.brand, AppTokens.brand2],
                  ),
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh, color: Colors.white, size: 18),
                    const SizedBox(width: AppTokens.s8),
                    Text(
                      'Check for more',
                      style: AppTokens.body(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(color: AppTokens.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTokens.muted(context)),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTokens.caption(context).copyWith(
              color: AppTokens.muted(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String letter;
  final String text;
  final bool isCorrect;
  const _OptionTile({
    required this.letter,
    required this.text,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final Color successBg = ThemeManager.greenSuccess.withOpacity(0.15);
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: isCorrect ? successBg : AppTokens.surface2(context),
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(
          color: isCorrect
              ? ThemeManager.greenSuccess
              : AppTokens.border(context),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: isCorrect
                ? ThemeManager.greenSuccess
                : AppTokens.surface(context),
            child: Text(
              letter,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isCorrect ? Colors.white : AppTokens.muted(context),
              ),
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Text(
              text,
              style: AppTokens.body(context).copyWith(
                color: AppTokens.ink(context),
                fontWeight: isCorrect ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          if (isCorrect)
            Icon(Icons.check_circle, color: ThemeManager.greenSuccess),
        ],
      ),
    );
  }
}

class _ExplanationBlock extends StatelessWidget {
  final String text;
  const _ExplanationBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: ThemeManager.evolveYellow.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTokens.r12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 18,
                color: ThemeManager.evolveYellow,
              ),
              const SizedBox(width: 6),
              Text(
                'Explanation',
                style: AppTokens.caption(context).copyWith(
                  color: ThemeManager.evolveYellow,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: AppTokens.body(context).copyWith(
              color: AppTokens.ink(context),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
