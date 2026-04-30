// ════════════════════════════════════════════════════════════════════
// LocalAttemptCache — on-device snapshot for crash-recovery
// ════════════════════════════════════════════════════════════════════
//
// Why this exists
// ───────────────
// The server-side heartbeat endpoint solves *user-pause-and-resume*
// (the user opens the app tomorrow and continues). It does NOT solve
// the case where the app crashes between two heartbeats and the user
// re-opens it 10 seconds later expecting the last 30s of activity to
// still be there. SharedPreferences gives us a synchronous, durable
// write surface that survives any kind of process death; we snapshot
// after every meaningful local mutation.
//
// What gets cached
// ────────────────
//   • Per-attempt:
//       - currentQuestionId, currentSectionId
//       - timeRemainingMs (top-level + per-section)
//       - savedAt (local clock)
//       - the full answers map (questionId -> AnswerPatch)
//   • A side index `lac:active_attempts` listing the IDs we've cached,
//     so the resume orchestrator can iterate without scanning prefs.
//
// What does NOT get cached
// ────────────────────────
// Question text / options / images. Those are static content; the
// existing exam_store re-fetches them on resume.
//
// Reconciliation rule
// ───────────────────
// When the app boots and finds both a server `/in-progress` entry AND
// a local snapshot for the same attempt:
//   - if local.savedAt > server.lastSavedAt by >5s → flush local diff
//     to server via heartbeat, then start from server state
//   - otherwise → server state wins, drop the local snapshot
// This avoids the "phone offline for 10 min after answering 5 Qs"
// edge case from silently losing those answers.

import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../api_service/exam_attempt_api.dart';

class LocalAttemptCache {
  static const _prefix = 'lac:attempt:';
  static const _activeKey = 'lac:active_attempts';

  SharedPreferences? _prefs;
  Future<SharedPreferences> _p() async =>
      _prefs ??= await SharedPreferences.getInstance();

  // ─── Snapshot put / get / delete ────────────────────────────────

  Future<void> save(LocalAttemptSnapshot snapshot) async {
    final p = await _p();
    await p.setString(_prefix + snapshot.attemptId, jsonEncode(snapshot.toJson()));
    final active = (p.getStringList(_activeKey) ?? <String>[]).toSet()
      ..add(snapshot.attemptId);
    await p.setStringList(_activeKey, active.toList());
  }

  Future<LocalAttemptSnapshot?> load(String attemptId) async {
    final p = await _p();
    final raw = p.getString(_prefix + attemptId);
    if (raw == null) return null;
    try {
      return LocalAttemptSnapshot.fromJson(
        (jsonDecode(raw) as Map).cast<String, dynamic>(),
      );
    } catch (_) {
      // Corrupted cache → treat as missing.
      await p.remove(_prefix + attemptId);
      return null;
    }
  }

  Future<List<LocalAttemptSnapshot>> loadAll() async {
    final p = await _p();
    final ids = p.getStringList(_activeKey) ?? <String>[];
    final out = <LocalAttemptSnapshot>[];
    for (final id in ids) {
      final s = await load(id);
      if (s != null) out.add(s);
    }
    return out;
  }

  Future<void> delete(String attemptId) async {
    final p = await _p();
    await p.remove(_prefix + attemptId);
    final active = (p.getStringList(_activeKey) ?? <String>[])..remove(attemptId);
    await p.setStringList(_activeKey, active);
  }

  /// Clear only entries older than [maxAge] from the active index.
  /// Useful periodic cleanup so a stale week-old "in-flight" attempt
  /// doesn't keep prompting the user forever.
  Future<void> evictStale({Duration maxAge = const Duration(days: 7)}) async {
    final all = await loadAll();
    final cutoff = DateTime.now().subtract(maxAge);
    for (final s in all) {
      if (s.savedAt.isBefore(cutoff)) {
        await delete(s.attemptId);
      }
    }
  }

  // ─── Mutators that the exam_store will call inline ─────────────

  /// Patch one answer. Auto-persists.
  Future<void> upsertAnswer(String attemptId, AnswerPatch patch) async {
    final s = await load(attemptId);
    if (s == null) return;
    s.answers[patch.questionId] = patch;
    s.savedAt = DateTime.now();
    await save(s);
  }

  /// Update the "where am I" pointers without touching answers.
  Future<void> updatePointer(
    String attemptId, {
    String? currentQuestionId,
    String? currentSectionId,
    int? timeRemainingMs,
    Map<String, int>? sectionTimeRemainingMs,
  }) async {
    final s = await load(attemptId);
    if (s == null) return;
    if (currentQuestionId != null) s.currentQuestionId = currentQuestionId;
    if (currentSectionId != null) s.currentSectionId = currentSectionId;
    if (timeRemainingMs != null) s.timeRemainingMs = timeRemainingMs;
    if (sectionTimeRemainingMs != null) {
      s.sectionTimeRemainingMs.addAll(sectionTimeRemainingMs);
    }
    s.savedAt = DateTime.now();
    await save(s);
  }
}

// ════════════════════════════════════════════════════════════════════
// Snapshot DTO — JSON-serializable
// ════════════════════════════════════════════════════════════════════

class LocalAttemptSnapshot {
  final String attemptId;
  final String examId;
  final String mode; // 'continuous' | 'sectioned'
  String? currentQuestionId;
  String? currentSectionId;
  int? timeRemainingMs;
  Map<String, int> sectionTimeRemainingMs;
  Map<String, AnswerPatch> answers;
  DateTime savedAt;

  LocalAttemptSnapshot({
    required this.attemptId,
    required this.examId,
    required this.mode,
    this.currentQuestionId,
    this.currentSectionId,
    this.timeRemainingMs,
    Map<String, int>? sectionTimeRemainingMs,
    Map<String, AnswerPatch>? answers,
    DateTime? savedAt,
  })  : sectionTimeRemainingMs = sectionTimeRemainingMs ?? {},
        answers = answers ?? {},
        savedAt = savedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'attempt_id': attemptId,
        'exam_id': examId,
        'mode': mode,
        if (currentQuestionId != null) 'current_question_id': currentQuestionId,
        if (currentSectionId != null) 'current_section_id': currentSectionId,
        if (timeRemainingMs != null) 'time_remaining_ms': timeRemainingMs,
        'section_time_remaining_ms': sectionTimeRemainingMs,
        'answers': answers.map((k, v) => MapEntry(k, v.toJson())),
        'saved_at': savedAt.toIso8601String(),
      };

  factory LocalAttemptSnapshot.fromJson(Map<String, dynamic> j) {
    final ans = (j['answers'] as Map?)?.cast<String, dynamic>() ?? {};
    final answersOut = <String, AnswerPatch>{};
    ans.forEach((k, v) {
      final m = (v as Map).cast<String, dynamic>();
      answersOut[k] = AnswerPatch(
        questionId: (m['question_id'] as String?) ?? k,
        selectedOption: m['selected_option'] as String?,
        attempted: m['attempted'] as bool?,
        skipped: m['skipped'] as bool?,
        markedForReview: m['marked_for_review'] as bool?,
        bookmarks: m['bookmarks'] as bool?,
        confidence: (m['confidence'] as num?)?.toInt(),
        timeSpentMs: (m['time_spent_ms'] as num?)?.toInt(),
      );
    });
    final sectionMap = (j['section_time_remaining_ms'] as Map?)?.cast<String, dynamic>() ?? {};
    return LocalAttemptSnapshot(
      attemptId: j['attempt_id'].toString(),
      examId: j['exam_id'].toString(),
      mode: (j['mode'] as String?) ?? 'continuous',
      currentQuestionId: j['current_question_id'] as String?,
      currentSectionId: j['current_section_id'] as String?,
      timeRemainingMs: (j['time_remaining_ms'] as num?)?.toInt(),
      sectionTimeRemainingMs: sectionMap.map((k, v) => MapEntry(k, (v as num).toInt())),
      answers: answersOut,
      savedAt: DateTime.tryParse(j['saved_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
