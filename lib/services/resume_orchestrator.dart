// ════════════════════════════════════════════════════════════════════
// ResumeOrchestrator — boot-time + mid-attempt resume coordinator
// ════════════════════════════════════════════════════════════════════
//
// Two responsibilities:
//
// 1. On app boot, decide whether to show a "Resume?" prompt.
//    Looks at server's GET /users/me/in-progress AND the local cache,
//    reconciles divergences, returns a curated list of resumable
//    attempts the UI can render.
//
// 2. During an active attempt, drive the heartbeat cadence + flush
//    local snapshots to server. Owned by the new exam_store; this
//    class doesn't directly mutate UI state, it just exposes a stream
//    of "save-attempted" events the store can listen to.
//
// Lifecycle binding (recommended hookup)
// ──────────────────────────────────────
//   class _AppState with WidgetsBindingObserver {
//     final orchestrator = ResumeOrchestrator();
//
//     @override
//     void didChangeAppLifecycleState(AppLifecycleState state) {
//       if (state == AppLifecycleState.paused ||
//           state == AppLifecycleState.inactive) {
//         orchestrator.flushNow();   // last-chance save before kill
//       }
//     }
//   }

import 'dart:async';
import '../api_service/exam_attempt_api.dart';
import 'local_attempt_cache.dart';

class ResumeOrchestrator {
  final ExamAttemptApi _api;
  final LocalAttemptCache _cache;
  Timer? _heartbeatTimer;
  String? _activeAttemptId;
  bool _flushing = false;

  ResumeOrchestrator({ExamAttemptApi? api, LocalAttemptCache? cache})
      : _api = api ?? ExamAttemptApi(),
        _cache = cache ?? LocalAttemptCache();

  // ─── App-boot resume detection ──────────────────────────────────

  /// Returns the list of resumable attempts the UI should consider
  /// surfacing as "you have an attempt in progress, continue?"
  /// prompts. Reconciles server + local divergences along the way.
  ///
  /// The returned items are ordered by recency (last_saved_at desc).
  /// Caller decides whether to auto-route into the most recent one
  /// or show a picker.
  Future<List<ResumableAttempt>> findResumable() async {
    // Talk to both sources in parallel — slow network shouldn't
    // block reading from local prefs.
    final results = await Future.wait([
      _safe(() => _api.listInProgress()),
      _cache.loadAll(),
    ]);
    final server = (results[0] as List?)?.cast<InProgressAttempt>() ?? <InProgressAttempt>[];
    final local = (results[1] as List).cast<LocalAttemptSnapshot>();

    final serverById = {for (final s in server) s.id: s};
    final localById = {for (final s in local) s.attemptId: s};

    final merged = <ResumableAttempt>[];

    // Server-known attempts come first; if local has fresher data,
    // we'll flag it so the UI can flush before mounting.
    for (final s in server) {
      final l = localById[s.id];
      final localFresher = l != null &&
          (s.lastSavedAt == null ||
              l.savedAt.isAfter(s.lastSavedAt!.add(const Duration(seconds: 5))));
      merged.add(ResumableAttempt(
        attemptId: s.id,
        examId: s.examId,
        examName: s.examName,
        mode: s.mode,
        status: s.status,
        questionsAnswered: s.questionsAnswered,
        timeRemainingMs: s.timeRemainingMs,
        currentQuestionId: l?.currentQuestionId ?? s.currentQuestionId,
        currentSectionId: l?.currentSectionId ?? s.currentSectionId,
        lastSavedAt: localFresher ? l.savedAt : s.lastSavedAt,
        localFresher: localFresher,
        local: l,
        server: s,
      ));
    }

    // Local-only entries survived a process death between server
    // creation and the first heartbeat — rare but real. We surface
    // them; on resume the store will issue an immediate heartbeat to
    // sync state.
    for (final l in local) {
      if (serverById.containsKey(l.attemptId)) continue;
      merged.add(ResumableAttempt(
        attemptId: l.attemptId,
        examId: l.examId,
        examName: '',
        mode: l.mode,
        status: 'in_progress',
        questionsAnswered: l.answers.values.where((a) => a.attempted == true).length,
        timeRemainingMs: l.timeRemainingMs,
        currentQuestionId: l.currentQuestionId,
        currentSectionId: l.currentSectionId,
        lastSavedAt: l.savedAt,
        localFresher: true,
        local: l,
        server: null,
      ));
    }

    merged.sort((a, b) {
      final av = a.lastSavedAt?.millisecondsSinceEpoch ?? 0;
      final bv = b.lastSavedAt?.millisecondsSinceEpoch ?? 0;
      return bv.compareTo(av);
    });
    return merged;
  }

  Future<T?> _safe<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (_) {
      return null;
    }
  }

  // ─── Mid-attempt heartbeat driver ───────────────────────────────

  /// Start periodic heartbeats for [attemptId]. The provided getter
  /// is called each tick to read the latest store state without the
  /// orchestrator needing a direct reference to the store.
  void startHeartbeat({
    required String attemptId,
    required Future<HeartbeatPayload> Function() getPayload,
    Duration interval = const Duration(seconds: 15),
  }) {
    stopHeartbeat();
    _activeAttemptId = attemptId;
    _heartbeatTimer = Timer.periodic(interval, (_) => _doHeartbeat(getPayload));
  }

  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _activeAttemptId = null;
  }

  /// Flush a heartbeat right now. Call this from
  /// AppLifecycleState.paused so the last 15s of activity isn't lost.
  Future<void> flushNow() async {
    final id = _activeAttemptId;
    if (id == null) return;
    final snap = await _cache.load(id);
    if (snap == null) return;
    await _flushSnapshot(snap);
  }

  Future<void> _doHeartbeat(Future<HeartbeatPayload> Function() getPayload) async {
    if (_flushing) return; // skip — previous heartbeat still in flight
    final payload = await getPayload();
    if (payload.attemptId.isEmpty) return;
    await _flushPayload(payload);
  }

  Future<void> _flushSnapshot(LocalAttemptSnapshot s) async {
    final answers = s.answers.values.toList();
    final sections = s.sectionTimeRemainingMs.entries
        .map((e) => SectionTime(sectionId: e.key, timeRemainingMs: e.value))
        .toList();
    await _flushPayload(HeartbeatPayload(
      attemptId: s.attemptId,
      currentQuestionId: s.currentQuestionId,
      currentSectionId: s.currentSectionId,
      timeRemainingMs: s.timeRemainingMs,
      sectionsTimeRemaining: sections,
      answers: answers,
    ));
  }

  Future<void> _flushPayload(HeartbeatPayload p) async {
    _flushing = true;
    try {
      await _api.heartbeat(
        userExamId: p.attemptId,
        currentQuestionId: p.currentQuestionId,
        currentSectionId: p.currentSectionId,
        timeRemainingMs: p.timeRemainingMs,
        sectionsTimeRemaining: p.sectionsTimeRemaining,
        answers: p.answers,
      );
    } catch (_) {
      // Swallow; the local cache still has the data, next heartbeat
      // (or app reopen) will retry. Log via your usual telemetry.
    } finally {
      _flushing = false;
    }
  }
}

// ════════════════════════════════════════════════════════════════════
// Wire types
// ════════════════════════════════════════════════════════════════════

class ResumableAttempt {
  final String attemptId;
  final String examId;
  final String examName;
  final String mode;
  final String status;
  final int questionsAnswered;
  final int? timeRemainingMs;
  final String? currentQuestionId;
  final String? currentSectionId;
  final DateTime? lastSavedAt;

  /// True when the local snapshot has a newer savedAt than the
  /// server's last_saved_at by more than 5 seconds. The store should
  /// flush local state to the server before re-fetching the
  /// authoritative resume payload.
  final bool localFresher;

  final LocalAttemptSnapshot? local;
  final InProgressAttempt? server;

  ResumableAttempt({
    required this.attemptId,
    required this.examId,
    required this.examName,
    required this.mode,
    required this.status,
    required this.questionsAnswered,
    this.timeRemainingMs,
    this.currentQuestionId,
    this.currentSectionId,
    this.lastSavedAt,
    required this.localFresher,
    this.local,
    this.server,
  });
}

class HeartbeatPayload {
  final String attemptId;
  final String? currentQuestionId;
  final String? currentSectionId;
  final int? timeRemainingMs;
  final List<SectionTime>? sectionsTimeRemaining;
  final List<AnswerPatch>? answers;
  HeartbeatPayload({
    required this.attemptId,
    this.currentQuestionId,
    this.currentSectionId,
    this.timeRemainingMs,
    this.sectionsTimeRemaining,
    this.answers,
  });
}
