import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../helpers/app_feedback.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/empty_state.dart';
import '../../helpers/haptics.dart';
import '../../helpers/value_formatters.dart';
import '../../services/daily_review_service.dart';
import 'daily_review_session_screen.dart';

/// DailyReviewScreen — the spaced-repetition home.
///
/// End-to-end wired:
///  • Reads streak + total sessions from [DailyReviewService].
///  • Calls [DailyReviewService.composeToday] to get today's deck.
///  • "Start review" pushes [DailyReviewSessionScreen] with the deck.
///  • Shows pool breakdown ("12 bookmarked, 4 incorrect, 7 review")
///    so the user understands what's queued.
///
/// Empty state when the user hasn't built up any review-eligible
/// questions yet.
class DailyReviewScreen extends StatefulWidget {
  const DailyReviewScreen({super.key});

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(builder: (_) => const DailyReviewScreen());
  }

  @override
  State<DailyReviewScreen> createState() => _DailyReviewScreenState();
}

class _DailyReviewScreenState extends State<DailyReviewScreen> {
  int _streak = 0;
  int _totalSessions = 0;
  bool _completedToday = false;
  PoolSizes _pools = const PoolSizes(bookmarked: 0, incorrect: 0, review: 0);
  List<ReviewQuestion> _todaysDeck = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-fetch when the user comes back from a session, so streak +
    // completion state refresh.
    if (!_loading) _refresh();
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    await _refresh();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refresh() async {
    final svc = DailyReviewService.instance;
    final streak = await svc.currentStreak();
    final total = await svc.totalSessions();
    final done = await svc.isCompletedToday();
    final pools = await svc.getPoolSizes();
    final deck = await svc.composeToday();

    if (!mounted) return;
    setState(() {
      _streak = streak;
      _totalSessions = total;
      _completedToday = done;
      _pools = pools;
      _todaysDeck = deck;
    });
  }

  Future<void> _startSession() async {
    if (_todaysDeck.isEmpty) {
      AppFeedback.info(
        context,
        "Bookmark or mark some questions for review during practice first.",
      );
      return;
    }
    Haptics.medium();
    await Navigator.of(context)
        .push(DailyReviewSessionScreen.route(_todaysDeck));
    // After the session screen pops, refresh the home so streak
    // + completed-today reflect immediately.
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppTokens.scaffold(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTokens.ink(context), size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text("Daily review", style: AppTokens.titleLg(context)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: _loading
            ? Center(
                child: CircularProgressIndicator(
                  color: AppTokens.accent(context),
                ),
              )
            : _pools.total == 0 && _totalSessions == 0
                ? EmptyState(
                    icon: Icons.replay_circle_filled_rounded,
                    title: 'Build your review deck',
                    subtitle:
                        'Bookmark questions or mark them for review during '
                        'practice — they’ll show up here for spaced '
                        'repetition the next day.',
                    action: TextButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: Text(
                        'Got it',
                        style: AppTokens.titleSm(context).copyWith(
                          color: AppTokens.accent(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(AppTokens.s24),
                    children: [
                      _heroCard(),
                      const SizedBox(height: AppTokens.s16),
                      _poolBreakdownCard(),
                      const SizedBox(height: AppTokens.s16),
                      Row(
                        children: [
                          Expanded(
                            child: _statCard(
                              icon: Icons.local_fire_department_rounded,
                              tint: const Color(0xFFE89B20),
                              label: 'Streak',
                              value:
                                  _streak == 1 ? '1 day' : '$_streak days',
                            ),
                          ),
                          const SizedBox(width: AppTokens.s12),
                          Expanded(
                            child: _statCard(
                              icon: Icons.task_alt_rounded,
                              tint: const Color(0xFF33AD48),
                              label: 'Total sessions',
                              value: Fmt.compactInt(_totalSessions),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTokens.s16),
                      _howItWorksCard(),
                    ],
                  ),
      ),
    );
  }

  Widget _heroCard() {
    final completed = _completedToday;
    return Container(
      padding: const EdgeInsets.all(AppTokens.s20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: completed
              ? [
                  AppTokens.success(context),
                  AppTokens.success(context).withOpacity(0.85)
                ]
              : [AppTokens.brand, AppTokens.brand2],
        ),
        borderRadius: AppTokens.radius20,
        boxShadow: AppTokens.shadow2(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                completed
                    ? Icons.check_circle_rounded
                    : Icons.bolt_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: AppTokens.s8),
              Text(
                completed ? 'Done for today' : 'Today’s review',
                style: AppTokens.titleLg(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            completed
                ? "Come back tomorrow to keep your streak alive."
                : _todaysDeck.isEmpty
                    ? "Your queue is empty for now. Bookmark or mark "
                        "questions during practice."
                    : "${_todaysDeck.length} questions, picked from your "
                        "bookmarks and review queue.",
            style: AppTokens.body(context).copyWith(
              color: Colors.white.withOpacity(0.92),
            ),
          ),
          const SizedBox(height: AppTokens.s20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: completed || _todaysDeck.isEmpty ? null : _startSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTokens.accent(context),
                disabledBackgroundColor: Colors.white.withOpacity(0.4),
                disabledForegroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: AppTokens.radius16,
                ),
              ),
              child: Text(
                completed
                    ? 'Already reviewed'
                    : _todaysDeck.isEmpty
                        ? 'Empty deck'
                        : 'Start review',
                style: AppTokens.titleSm(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: completed || _todaysDeck.isEmpty
                      ? Colors.white
                      : AppTokens.accent(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _poolBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius16,
        border: Border.all(color: AppTokens.border(context), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('In your pool', style: AppTokens.titleSm(context)),
          const SizedBox(height: AppTokens.s12),
          _poolRow(
            icon: Icons.bookmark_outline_rounded,
            tint: const Color(0xFFE89B20),
            label: 'Bookmarked',
            count: _pools.bookmarked,
          ),
          const SizedBox(height: AppTokens.s8),
          _poolRow(
            icon: Icons.error_outline_rounded,
            tint: const Color(0xFFE23B3B),
            label: 'Marked incorrect',
            count: _pools.incorrect,
          ),
          const SizedBox(height: AppTokens.s8),
          _poolRow(
            icon: Icons.flag_outlined,
            tint: const Color(0xFF1E88E5),
            label: 'Marked for review',
            count: _pools.review,
          ),
        ],
      ),
    );
  }

  Widget _poolRow({
    required IconData icon,
    required Color tint,
    required String label,
    required int count,
  }) {
    return Row(
      children: [
        Icon(icon, color: tint, size: 18),
        const SizedBox(width: AppTokens.s8),
        Expanded(
          child: Text(label, style: AppTokens.body(context)),
        ),
        Text(
          count.toString(),
          style: AppTokens.numeric(context, size: 16).copyWith(
            color: AppTokens.ink(context),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color tint,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius16,
        border: Border.all(color: AppTokens.border(context), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tint.withOpacity(0.14),
              borderRadius: AppTokens.radius12,
            ),
            child: Icon(icon, size: 18, color: tint),
          ),
          const SizedBox(height: AppTokens.s12),
          Text(value,
              style: AppTokens.numeric(context, size: 20)
                  .copyWith(color: AppTokens.ink(context))),
          const SizedBox(height: 2),
          Text(label, style: AppTokens.caption(context)),
        ],
      ),
    );
  }

  Widget _howItWorksCard() {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius16,
        border: Border.all(color: AppTokens.border(context), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How daily review works',
              style: AppTokens.titleSm(context)),
          const SizedBox(height: AppTokens.s12),
          _step(1,
              'Bookmarked questions, ones you got wrong, and ones you flagged for review get added to your pool automatically.'),
          const SizedBox(height: AppTokens.s8),
          _step(2,
              'Each day we pick 20 questions, prioritising bookmarks > incorrect > review. Older items rise to the top.'),
          const SizedBox(height: AppTokens.s8),
          _step(3,
              'Finish the deck to extend your streak. Miss a day and the streak resets.'),
        ],
      ),
    );
  }

  Widget _step(int n, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTokens.accentSoft(context),
            shape: BoxShape.circle,
          ),
          child: Text('$n',
              style: AppTokens.caption(context).copyWith(
                color: AppTokens.accent(context),
                fontWeight: FontWeight.w700,
              )),
        ),
        const SizedBox(width: AppTokens.s8),
        Expanded(
          child: Text(text, style: AppTokens.body(context)),
        ),
      ],
    );
  }
}
