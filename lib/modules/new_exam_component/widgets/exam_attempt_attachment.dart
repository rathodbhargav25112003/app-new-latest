// ════════════════════════════════════════════════════════════════════
// ExamAttemptAttachment — drop-in heartbeat + crash recovery wiring
// ════════════════════════════════════════════════════════════════════
//
// One-line integration for any attempt screen (exam_screen,
// custom_test_exam_screen, quiz_exam_screen, test_exam_screen,
// section_exam_screen, etc).  Owns:
//
//   • 15s periodic heartbeat to /api/exam-attempt/:id/heartbeat
//   • Local SharedPreferences mirror via LocalAttemptCache so a
//     hard crash between heartbeats loses ≤15s of state
//   • AppLifecycleState.paused last-chance flush
//   • Bridge to PauseResumeButton (caller renders the icon, this
//     class handles the API + local state transitions)
//   • Section-mode passthrough (per-section time + status)
//
// Usage from a StatefulWidget:
//
//   class _MyExamScreenState extends State<MyExamScreen> {
//     late final ExamAttemptAttachment _att;
//     @override
//     void initState() {
//       super.initState();
//       _att = ExamAttemptAttachment(
//         userExamId: widget.userExamId,
//         examId: widget.examId,
//         mode: 'continuous', // or 'sectioned'
//         readState: () => HeartbeatPayload(
//           attemptId: widget.userExamId,
//           currentQuestionId: store.currentQuestionId.value,
//           timeRemainingMs: timer.remainingMs,
//           answers: store.dirtyAnswers, // diff since last heartbeat
//         ),
//       )..attach();
//     }
//     @override
//     void dispose() { _att.detach(); super.dispose(); }
//   }
//
// On submit:
//   final r = await _att.submit();   // atomic finalize, idempotent
//
// The class is intentionally *not* MobX-aware — the integrator
// supplies a `readState` closure that pulls from whatever store /
// controller they use. This keeps the helper compatible with the
// existing exam_store, custom_test stores, and quiz stores without
// modification.

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../api_service/exam_attempt_api.dart';
import '../../../services/local_attempt_cache.dart';
import '../../../services/resume_orchestrator.dart';

class ExamAttemptAttachment with WidgetsBindingObserver {
  ExamAttemptAttachment({
    required this.userExamId,
    required this.readState,
    this.examId,
    this.mode = 'continuous',
    this.heartbeatInterval = const Duration(seconds: 15),
    this.api,
    this.cache,
    this.orchestrator,
  });

  final String userExamId;
  final String? examId;
  final String mode;                                // 'continuous' | 'sectioned'
  final Duration heartbeatInterval;
  final HeartbeatPayload Function() readState;

  final ExamAttemptApi? api;
  final LocalAttemptCache? cache;
  final ResumeOrchestrator? orchestrator;

  late final ExamAttemptApi _api = api ?? ExamAttemptApi();
  late final LocalAttemptCache _cache = cache ?? LocalAttemptCache();
  late final ResumeOrchestrator _orch = orchestrator ?? ResumeOrchestrator();

  bool _attached = false;

  /// Begin heartbeating + observing app lifecycle. Idempotent — safe
  /// to call multiple times.
  Future<void> attach() async {
    if (_attached) return;
    _attached = true;

    // Seed local snapshot if not yet present so the boot prompt can
    // always show this attempt even if the first heartbeat fails.
    final existing = await _cache.load(userExamId);
    if (existing == null) {
      final p = readState();
      await _cache.save(LocalAttemptSnapshot(
        attemptId: userExamId,
        examId: examId ?? '',
        mode: mode,
        currentQuestionId: p.currentQuestionId,
        currentSectionId: p.currentSectionId,
        timeRemainingMs: p.timeRemainingMs,
      ));
    }

    WidgetsBinding.instance.addObserver(this);
    _orch.startHeartbeat(
      attemptId: userExamId,
      interval: heartbeatInterval,
      getPayload: () async {
        final p = readState();
        // Mirror to local cache before sending so crash-recovery has
        // the latest pointer even if the network call fails.
        await _cache.updatePointer(
          userExamId,
          currentQuestionId: p.currentQuestionId,
          currentSectionId: p.currentSectionId,
          timeRemainingMs: p.timeRemainingMs,
        );
        if (p.answers != null) {
          for (final a in p.answers!) {
            await _cache.upsertAnswer(userExamId, a);
          }
        }
        return p;
      },
    );
  }

  /// Stop heartbeating + remove observer. Call from the screen's
  /// dispose(). Does NOT delete the local snapshot — that happens on
  /// successful submit() so a "back" button + relaunch picks it up
  /// from the resume prompt.
  void detach() {
    if (!_attached) return;
    _attached = false;
    WidgetsBinding.instance.removeObserver(this);
    _orch.stopHeartbeat();
  }

  // Lifecycle hook — called by Flutter when the OS pauses the app.
  // We use it to flush a final heartbeat so up to 15s of activity
  // doesn't get lost when the user backgrounds the app.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_attached) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _orch.flushNow();
    }
  }

  // ─── Lifecycle commands ────────────────────────────────────────

  Future<void> pause(BuildContext context) async {
    try {
      await _api.pause(userExamId);
    } on ActiveSessionElsewhere catch (e) {
      _toast(context, 'Active on another device — wait ${_minutesUntil(e.staleSinceMs)} or close it there.');
      rethrow;
    }
  }

  Future<void> resume(BuildContext context) async {
    try {
      await _api.resume(userExamId);
    } on ActiveSessionElsewhere catch (e) {
      _toast(context, 'Active on another device — wait ${_minutesUntil(e.staleSinceMs)} or close it there.');
      rethrow;
    }
  }

  Future<SubmitResult> submit(BuildContext? context) async {
    try {
      final r = await _api.submit(userExamId);
      // Local snapshot is no longer relevant — drop it so the boot
      // prompt doesn't keep offering this attempt as resumable.
      await _cache.delete(userExamId);
      return r;
    } on AttemptFinalized {
      // Already submitted — surface as success so the caller routes
      // to the report screen anyway.
      await _cache.delete(userExamId);
      return SubmitResult(ok: true, alreadySubmitted: true);
    } on ActiveSessionElsewhere catch (e) {
      if (context != null) {
        _toast(context, 'Active on another device — submit blocked. Wait ${_minutesUntil(e.staleSinceMs)}.');
      }
      rethrow;
    }
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _minutesUntil(int? staleSinceMs) {
    if (staleSinceMs == null) return 'a few minutes';
    final remaining = (5 * 60 * 1000) - staleSinceMs;
    if (remaining <= 0) return '0 min';
    return '${(remaining / 60000).ceil()} min';
  }
}
