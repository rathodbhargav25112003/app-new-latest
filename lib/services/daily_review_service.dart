import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// DailyReviewService — picks the right ~20 questions for today.
///
/// Implements a lightweight client-side spaced-repetition selector. The
/// goal is *retention*, not new-question discovery. So we draw from
/// three pools, each persisted in [SharedPreferences] as the user
/// flags questions during practice:
///
///   1. **Bookmarked** (`bookmark`) — user explicitly tapped the
///      bookmark icon. Weight 1.0 (heaviest).
///   2. **Incorrect** (`incorrect`) — user answered wrong on practice
///      or mock. Weight 0.7.
///   3. **Marked-for-review** (`review`) — user flagged "look later"
///      during a test. Weight 0.4.
///
/// Each pool stores rich question data (text + options + correct
/// answer + explanation) so the review session screen can render
/// fully offline. Questions in each pool also carry a `lastSeenAt`
/// timestamp — older = more likely to surface today.
///
/// **Flow**:
///   • `recordBookmark(q)` / `recordIncorrect(q)` / `recordReview(q)`
///     — call from practice screens.
///   • `unrecordBookmark(qId)` — call when user un-bookmarks.
///   • `composeToday()` — picks today's deck.
///   • `markSeen(qId)` — call after each answer in a session.
///   • `recordSessionCompleted()` — call at session end; bumps streak,
///     fires celebration callback if streak crosses a milestone.
class DailyReviewService {
  DailyReviewService._();
  static final instance = DailyReviewService._();

  // ── Storage keys ──────────────────────────────────────────────────
  static const _kBookmarkedPool = 'dr_pool_bookmarked_v1';
  static const _kIncorrectPool = 'dr_pool_incorrect_v1';
  static const _kReviewPool = 'dr_pool_review_v1';
  static const _kSeenMap = 'dr_seen_map_v1';
  static const _kSessionsCount = 'dr_sessions_count_v1';
  static const _kStreakDays = 'dr_streak_days_v1';
  static const _kLastSessionAt = 'dr_last_session_at_v1';

  // ── Tunables ──────────────────────────────────────────────────────
  /// Today's session size. Anki recommends 20-30/day for long-term
  /// retention; we err on the smaller side to keep sessions <10 min.
  static const int defaultDailySize = 20;

  /// Pool weights — higher means "more likely to surface today".
  static const double _bookmarkWeight = 1.0;
  static const double _incorrectWeight = 0.7;
  static const double _reviewWeight = 0.4;

  /// Decay boost for older questions: +0.3 per day, capped at +0.9
  /// after 3 days. Never-seen questions get the max.
  static const double _dayDecay = 0.3;
  static const double _maxDecayBoost = 0.9;

  /// Hard cap per pool to bound storage. Oldest entries trimmed.
  static const int _poolHardCap = 2000;

  /// Streak milestones that fire a celebration. The integrator hooks
  /// into [recordSessionCompleted]'s return value.
  static const milestones = [3, 7, 14, 30, 60, 100, 200, 365];

  // ── Recording (call from practice screens) ────────────────────────

  /// User tapped the bookmark icon on a question. Persists the entry.
  /// Idempotent — recording the same question twice updates the
  /// timestamp but doesn't duplicate the entry.
  Future<void> recordBookmark(ReviewQuestion q) async {
    await _addToPool(_kBookmarkedPool, q);
  }

  /// User un-bookmarked a question. Removes from pool.
  Future<void> unrecordBookmark(String questionId) async {
    await _removeFromPool(_kBookmarkedPool, questionId);
  }

  /// User submitted a practice answer that was wrong. Persists the
  /// entry with the user's chosen option for "you picked X, correct
  /// is Y" coaching in the review session.
  Future<void> recordIncorrect(ReviewQuestion q) async {
    await _addToPool(_kIncorrectPool, q);
  }

  /// User unmarked-incorrect (e.g. answered correctly on retake).
  Future<void> unrecordIncorrect(String questionId) async {
    await _removeFromPool(_kIncorrectPool, questionId);
  }

  /// User flagged "review later" on a test question.
  Future<void> recordReview(ReviewQuestion q) async {
    await _addToPool(_kReviewPool, q);
  }

  Future<void> unrecordReview(String questionId) async {
    await _removeFromPool(_kReviewPool, questionId);
  }

  // ── Reading ───────────────────────────────────────────────────────

  /// Compose today's deck. [size] defaults to [defaultDailySize].
  /// Returns [ReviewQuestion]s ranked highest-priority first.
  Future<List<ReviewQuestion>> composeToday({int? size}) async {
    final n = size ?? defaultDailySize;
    final bookmarked = await _loadPool(_kBookmarkedPool);
    final incorrect = await _loadPool(_kIncorrectPool);
    final review = await _loadPool(_kReviewPool);
    final seen = await _loadSeenMap();

    final scored = <_Scored>[];
    final addedIds = <String>{};

    void add(ReviewQuestion q, double base) {
      if (q.id.isEmpty) return;
      if (addedIds.contains(q.id)) {
        // Same ID in multiple pools — keep the highest base.
        final existing = scored.firstWhere((s) => s.q.id == q.id);
        if (base > existing.base) existing.base = base;
        return;
      }
      addedIds.add(q.id);
      final boost = _decayBoost(seen[q.id]);
      scored.add(_Scored(q: q, base: base, boost: boost));
    }

    for (final q in bookmarked) {
      add(q, _bookmarkWeight);
    }
    for (final q in incorrect) {
      add(q, _incorrectWeight);
    }
    for (final q in review) {
      add(q, _reviewWeight);
    }

    // Sort by total descending; ties broken by boost (older wins).
    scored.sort((a, b) {
      final cmp = b.total.compareTo(a.total);
      if (cmp != 0) return cmp;
      return b.boost.compareTo(a.boost);
    });

    return scored.take(n).map((s) => s.q).toList(growable: false);
  }

  /// Return raw pool sizes — for the home card, "12 bookmarked, 4
  /// incorrect, 7 marked for review".
  Future<PoolSizes> getPoolSizes() async {
    final bookmarked = await _loadPool(_kBookmarkedPool);
    final incorrect = await _loadPool(_kIncorrectPool);
    final review = await _loadPool(_kReviewPool);
    return PoolSizes(
      bookmarked: bookmarked.length,
      incorrect: incorrect.length,
      review: review.length,
    );
  }

  // ── Session lifecycle ─────────────────────────────────────────────

  /// Mark a question as "seen now" — call from the review session
  /// after the user answers each question. Older entries beyond
  /// 5000 are trimmed.
  Future<void> markSeen(String questionId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSeenMap);
    final map = raw == null
        ? <String, String>{}
        : Map<String, String>.from(jsonDecode(raw) as Map);
    map[questionId] = DateTime.now().toIso8601String();
    if (map.length > 5000) {
      final entries = map.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      for (var i = 0; i < entries.length - 5000; i++) {
        map.remove(entries[i].key);
      }
    }
    await prefs.setString(_kSeenMap, jsonEncode(map));
  }

  /// Records a daily-review session completion. Returns the new
  /// streak and whether this completion crossed a [milestones] mark.
  Future<SessionResult> recordSessionCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    final lastIso = prefs.getString(_kLastSessionAt);
    int streak = prefs.getInt(_kStreakDays) ?? 0;
    final previousStreak = streak;

    if (lastIso == null) {
      streak = 1;
    } else {
      try {
        final last = DateTime.parse(lastIso);
        final lastMid = DateTime(last.year, last.month, last.day);
        final todayMid = DateTime(now.year, now.month, now.day);
        final daysDiff = todayMid.difference(lastMid).inDays;
        if (daysDiff == 0) {
          // Already counted today — no streak change.
        } else if (daysDiff == 1) {
          streak += 1;
        } else {
          streak = 1;
        }
      } catch (_) {
        streak = 1;
      }
    }

    final hitMilestone = milestones.contains(streak) && streak != previousStreak;

    await prefs.setInt(_kStreakDays, streak);
    await prefs.setString(_kLastSessionAt, now.toIso8601String());
    final count = prefs.getInt(_kSessionsCount) ?? 0;
    await prefs.setInt(_kSessionsCount, count + 1);

    return SessionResult(
      streak: streak,
      hitMilestone: hitMilestone,
      totalSessions: count + 1,
    );
  }

  Future<int> currentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastIso = prefs.getString(_kLastSessionAt);
    final streak = prefs.getInt(_kStreakDays) ?? 0;
    if (lastIso == null) return 0;
    try {
      final last = DateTime.parse(lastIso);
      final lastMid = DateTime(last.year, last.month, last.day);
      final todayMid = DateTime.now();
      final today = DateTime(todayMid.year, todayMid.month, todayMid.day);
      final daysSince = today.difference(lastMid).inDays;
      // Streak broken if user missed > 1 day.
      if (daysSince > 1) return 0;
      return streak;
    } catch (_) {
      return 0;
    }
  }

  Future<int> totalSessions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kSessionsCount) ?? 0;
  }

  Future<bool> isCompletedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastIso = prefs.getString(_kLastSessionAt);
    if (lastIso == null) return false;
    try {
      final last = DateTime.parse(lastIso);
      final now = DateTime.now();
      return last.year == now.year &&
          last.month == now.month &&
          last.day == now.day;
    } catch (_) {
      return false;
    }
  }

  // ── Internals ─────────────────────────────────────────────────────

  double _decayBoost(String? lastSeenIso) {
    if (lastSeenIso == null) return _maxDecayBoost;
    try {
      final lastSeen = DateTime.parse(lastSeenIso);
      final days = DateTime.now().difference(lastSeen).inDays.clamp(0, 100);
      return (days * _dayDecay).clamp(0.0, _maxDecayBoost);
    } catch (_) {
      return _maxDecayBoost;
    }
  }

  Future<void> _addToPool(String key, ReviewQuestion q) async {
    if (q.id.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = await _loadPool(key);
    // Replace existing entry (idempotent), or append.
    list.removeWhere((e) => e.id == q.id);
    list.add(q.copyWith(addedAt: DateTime.now()));
    if (list.length > _poolHardCap) {
      list.sort((a, b) =>
          (a.addedAt ?? DateTime.now()).compareTo(b.addedAt ?? DateTime.now()));
      list.removeRange(0, list.length - _poolHardCap);
    }
    await prefs.setString(
      key,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _removeFromPool(String key, String questionId) async {
    if (questionId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = await _loadPool(key);
    list.removeWhere((e) => e.id == questionId);
    await prefs.setString(
      key,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<ReviewQuestion>> _loadPool(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return <ReviewQuestion>[];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => ReviewQuestion.fromJson(e as Map<String, dynamic>))
          .toList(growable: true);
    } catch (e) {
      debugPrint('DailyReviewService _loadPool($key) failed: $e');
      return <ReviewQuestion>[];
    }
  }

  Future<Map<String, String>> _loadSeenMap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kSeenMap);
      if (raw == null) return const {};
      return Map<String, String>.from(jsonDecode(raw) as Map);
    } catch (e) {
      debugPrint('DailyReviewService _loadSeenMap failed: $e');
      return const {};
    }
  }

  /// Wipe all daily-review state. Use only for debugging / "Reset
  /// progress" flows.
  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      _kBookmarkedPool,
      _kIncorrectPool,
      _kReviewPool,
      _kSeenMap,
      _kSessionsCount,
      _kStreakDays,
      _kLastSessionAt,
    ]) {
      await prefs.remove(key);
    }
  }
}

/// One question in a pool. Carries enough data to render the review
/// session offline — including question/explanation images and the
/// user's saved Quill annotations.
class ReviewQuestion {
  ReviewQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.correctValue,
    this.explanation,
    this.topicName,
    this.examId,
    this.userPickedValue,
    this.addedAt,
    this.questionImages = const [],
    this.explanationImages = const [],
    this.annotationData,
  });

  /// Question's unique ID (`sId` in the model layer).
  final String id;

  /// Plain / HTML / markdown-with-images text of the question prompt.
  /// Renderer in the session screen splits on `----image----` markers
  /// to interleave images.
  final String text;

  /// Each option as `(value, label)`. `value` matches `correctValue`
  /// when correct.
  final List<ReviewOption> options;

  /// The string value of the correct option.
  final String correctValue;

  /// Optional explanation in the same custom syntax used across the
  /// app — preprocessed via [preprocessDocument] + [parseCustomSyntax]
  /// to a Quill Document for rendering.
  final String? explanation;

  /// Optional topic / chapter name.
  final String? topicName;

  /// Optional source exam ID (for backend syncing later).
  final String? examId;

  /// What the user picked when they got it wrong (for "incorrect"
  /// pool only). Null for bookmarked/review pools.
  final String? userPickedValue;

  /// When the entry was added to its pool. Used for trimming +
  /// secondary sort.
  final DateTime? addedAt;

  /// URLs of inline question images. Each is rendered + zoomable via
  /// PhotoView.
  final List<String> questionImages;

  /// URLs of explanation images, shown after the explanation Quill
  /// content.
  final List<String> explanationImages;

  /// Saved Quill annotation deltas — when the user highlighted
  /// portions of the explanation in a previous attempt, those
  /// highlights survive into the review session so the user sees
  /// their own marks again.
  final List<dynamic>? annotationData;

  ReviewQuestion copyWith({
    String? id,
    String? text,
    List<ReviewOption>? options,
    String? correctValue,
    String? explanation,
    String? topicName,
    String? examId,
    String? userPickedValue,
    DateTime? addedAt,
    List<String>? questionImages,
    List<String>? explanationImages,
    List<dynamic>? annotationData,
  }) =>
      ReviewQuestion(
        id: id ?? this.id,
        text: text ?? this.text,
        options: options ?? this.options,
        correctValue: correctValue ?? this.correctValue,
        explanation: explanation ?? this.explanation,
        topicName: topicName ?? this.topicName,
        examId: examId ?? this.examId,
        userPickedValue: userPickedValue ?? this.userPickedValue,
        addedAt: addedAt ?? this.addedAt,
        questionImages: questionImages ?? this.questionImages,
        explanationImages: explanationImages ?? this.explanationImages,
        annotationData: annotationData ?? this.annotationData,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'options': options.map((o) => o.toJson()).toList(),
        'correctValue': correctValue,
        'explanation': explanation,
        'topicName': topicName,
        'examId': examId,
        'userPickedValue': userPickedValue,
        'addedAt': addedAt?.toIso8601String(),
        'questionImages': questionImages,
        'explanationImages': explanationImages,
        'annotationData': annotationData,
      };

  factory ReviewQuestion.fromJson(Map<String, dynamic> json) => ReviewQuestion(
        id: (json['id'] as String?) ?? '',
        text: (json['text'] as String?) ?? '',
        options: (json['options'] as List<dynamic>? ?? const [])
            .map((e) => ReviewOption.fromJson(e as Map<String, dynamic>))
            .toList(),
        correctValue: (json['correctValue'] as String?) ?? '',
        explanation: json['explanation'] as String?,
        topicName: json['topicName'] as String?,
        examId: json['examId'] as String?,
        userPickedValue: json['userPickedValue'] as String?,
        addedAt: json['addedAt'] == null
            ? null
            : DateTime.tryParse(json['addedAt'] as String),
        questionImages: (json['questionImages'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        explanationImages:
            (json['explanationImages'] as List<dynamic>? ?? const [])
                .map((e) => e.toString())
                .toList(),
        annotationData: json['annotationData'] as List<dynamic>?,
      );
}

class ReviewOption {
  ReviewOption({required this.value, required this.label});
  final String value;
  final String label;

  Map<String, dynamic> toJson() => {'value': value, 'label': label};

  factory ReviewOption.fromJson(Map<String, dynamic> json) => ReviewOption(
        value: (json['value'] as String?) ?? '',
        label: (json['label'] as String?) ?? '',
      );
}

class PoolSizes {
  const PoolSizes({
    required this.bookmarked,
    required this.incorrect,
    required this.review,
  });
  final int bookmarked;
  final int incorrect;
  final int review;
  int get total => bookmarked + incorrect + review;
}

class SessionResult {
  const SessionResult({
    required this.streak,
    required this.hitMilestone,
    required this.totalSessions,
  });
  final int streak;
  final bool hitMilestone;
  final int totalSessions;
}

class _Scored {
  _Scored({required this.q, required this.base, required this.boost});
  final ReviewQuestion q;
  double base;
  final double boost;
  double get total => base + boost;
}
