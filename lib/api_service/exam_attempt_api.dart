// ════════════════════════════════════════════════════════════════════
// ExamAttemptApi — wraps the new /api/exam-attempt/* endpoints
// ════════════════════════════════════════════════════════════════════
//
// Drop-in API client for the resume / heartbeat / pause / submit flow
// that ships with the May 2026 backend update. Designed to coexist
// with the existing ApiService rather than replace it — once the
// frontend exam_store migrates to the new contract, the legacy
// `/api/UserAnswer/create` calls can be retired piece by piece.
//
// Usage from MobX store / widget:
//
//   final api = ExamAttemptApi();
//   final state = await api.getState(userExamId);
//   await api.heartbeat(
//     userExamId: userExamId,
//     currentQuestionId: state.attempt.currentQuestionId,
//     timeRemainingMs: timer.remainingMs,
//     answers: pendingAnswers,
//   );
//   await api.submit(userExamId);
//
// Idempotency
// ───────────
// Heartbeat + submit + answer-related writes accept an
// `Idempotency-Key` header. The class auto-generates a UUIDv4 per
// logical action so retries on flaky networks never produce duplicate
// User_answer rows. Pass an explicit `idempotencyKey` if the caller
// owns the action's identity (preferred for explicit submit).
//
// Device id
// ─────────
// The backend rejects a heartbeat from a *different* device while a
// recent one is still live (anti-double-attempt). We piggyback on the
// existing ApiService.getDeviceInfo() so each call carries the same
// stable device id the rest of the app already uses.

import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/constants.dart' show baseUrl;
import 'api_service.dart' show ApiService;

class ExamAttemptApi {
  final http.Client _http;
  ExamAttemptApi({http.Client? client}) : _http = client ?? http.Client();

  // ─── Auth + headers helpers ─────────────────────────────────────

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String> _deviceId() async {
    final info = await ApiService().getDeviceInfo();
    return info['device_id'] ?? 'unknown';
  }

  /// UUIDv4 — used as default Idempotency-Key. We don't need crypto
  /// strength; collisions across users are isolated by the server-side
  /// (user, route) namespace. Uses Random — Random.secure() would be
  /// nicer but is overkill for cache keys.
  String _uuid() {
    final r = Random();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Future<Map<String, String>> _headers({
    bool withIdempotency = false,
    String? idempotencyKey,
  }) async {
    final token = await _token();
    final h = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': token,
      'X-Device-Id': await _deviceId(),
    };
    if (withIdempotency) {
      h['Idempotency-Key'] = idempotencyKey ?? _uuid();
    }
    return h;
  }

  // ─── GET /api/exam-attempt/:id/state ────────────────────────────

  Future<ResumeState> getState(String userExamId) async {
    final url = Uri.parse('$baseUrl/exam-attempt/$userExamId/state');
    final res = await _http.get(url, headers: await _headers());
    final body = _decode(res);
    return ResumeState.fromJson(body);
  }

  // ─── POST /api/exam-attempt/:id/heartbeat ───────────────────────

  /// Idempotent autosave. Call every ~15s during attempt + on
  /// AppLifecycleState.paused + on question navigation.
  ///
  /// `answers` carries only the dirty diff — answers the user touched
  /// since the previous heartbeat. The server upserts by
  /// (userExam_id, question_id) so resending the full set is also
  /// safe but wastes bandwidth.
  Future<HeartbeatResult> heartbeat({
    required String userExamId,
    String? currentQuestionId,
    String? currentSectionId,
    int? timeRemainingMs,
    List<SectionTime>? sectionsTimeRemaining,
    List<AnswerPatch>? answers,
    String? idempotencyKey,
  }) async {
    final url = Uri.parse('$baseUrl/exam-attempt/$userExamId/heartbeat');
    final body = <String, dynamic>{
      if (currentQuestionId != null) 'current_question_id': currentQuestionId,
      if (currentSectionId != null) 'current_section_id': currentSectionId,
      if (timeRemainingMs != null) 'time_remaining_ms': timeRemainingMs,
      if (sectionsTimeRemaining != null)
        'sections_time_remaining': sectionsTimeRemaining.map((s) => s.toJson()).toList(),
      if (answers != null && answers.isNotEmpty)
        'answers': answers.map((a) => a.toJson()).toList(),
    };
    final res = await _http.post(
      url,
      headers: await _headers(withIdempotency: true, idempotencyKey: idempotencyKey),
      body: jsonEncode(body),
    );
    final json = _decode(res);
    return HeartbeatResult.fromJson(json);
  }

  // ─── POST pause / resume / submit ───────────────────────────────

  Future<void> pause(String userExamId) async {
    final url = Uri.parse('$baseUrl/exam-attempt/$userExamId/pause');
    final res = await _http.post(url, headers: await _headers(), body: '{}');
    _decode(res);
  }

  Future<void> resume(String userExamId) async {
    final url = Uri.parse('$baseUrl/exam-attempt/$userExamId/resume');
    final res = await _http.post(url, headers: await _headers(), body: '{}');
    _decode(res);
  }

  /// Atomic submit. Idempotent — calling twice on the same attempt
  /// returns the same result with `already_submitted: true`.
  Future<SubmitResult> submit(String userExamId, {String? idempotencyKey}) async {
    final url = Uri.parse('$baseUrl/exam-attempt/$userExamId/submit');
    // Stable idempotency key per attempt — re-derives the same key
    // from the attempt id so a rapid double-tap on submit can't create
    // two finalize requests.
    final key = idempotencyKey ?? 'submit-$userExamId';
    final res = await _http.post(
      url,
      headers: await _headers(withIdempotency: true, idempotencyKey: key),
      body: '{}',
    );
    final json = _decode(res);
    return SubmitResult.fromJson(json);
  }

  // ─── GET /api/users/me/in-progress ──────────────────────────────

  Future<List<InProgressAttempt>> listInProgress({int limit = 20}) async {
    final url = Uri.parse('$baseUrl/users/me/in-progress?limit=$limit');
    final res = await _http.get(url, headers: await _headers());
    final json = _decode(res);
    final list = (json['attempts'] as List?) ?? [];
    return list.map((j) => InProgressAttempt.fromJson(j as Map<String, dynamic>)).toList();
  }

  // ─── Quiz variants ──────────────────────────────────────────────

  Future<ResumeState> getQuizState(String quizUserExamId) async {
    final url = Uri.parse('$baseUrl/quiz-attempt/$quizUserExamId/state');
    final res = await _http.get(url, headers: await _headers());
    return ResumeState.fromJson(_decode(res));
  }

  Future<HeartbeatResult> heartbeatQuiz({
    required String quizUserExamId,
    String? currentQuestionId,
    int? timeRemainingMs,
    String? idempotencyKey,
  }) async {
    final url = Uri.parse('$baseUrl/quiz-attempt/$quizUserExamId/heartbeat');
    final body = <String, dynamic>{
      if (currentQuestionId != null) 'current_question_id': currentQuestionId,
      if (timeRemainingMs != null) 'time_remaining_ms': timeRemainingMs,
    };
    final res = await _http.post(
      url,
      headers: await _headers(withIdempotency: true, idempotencyKey: idempotencyKey),
      body: jsonEncode(body),
    );
    return HeartbeatResult.fromJson(_decode(res));
  }

  // ─── Internal: decode + map error codes to typed exceptions ──────

  Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic> json;
    try {
      json = (jsonDecode(res.body) as Map).cast<String, dynamic>();
    } catch (_) {
      throw ExamAttemptException(res.statusCode, 'invalid_json', res.body);
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      // Backend wraps responses as { status, message, data } (express-easy-helper)
      // but new endpoints return the data envelope directly. Handle both.
      if (json['data'] is Map) return (json['data'] as Map).cast<String, dynamic>();
      return json;
    }
    final code = (json['code'] as String?) ?? '';
    final message = (json['message'] as String?) ?? 'Request failed';
    if (code == 'ACTIVE_SESSION_ELSEWHERE') {
      throw ActiveSessionElsewhere(message, json['stale_since_ms'] as int?);
    }
    if (code == 'ATTEMPT_FINALIZED' || res.statusCode == 410) {
      throw AttemptFinalized(message);
    }
    throw ExamAttemptException(res.statusCode, code, message);
  }

  void close() => _http.close();
}

// ════════════════════════════════════════════════════════════════════
// DTOs — mirror the backend's resume payload shape
// ════════════════════════════════════════════════════════════════════

class ResumeState {
  final ResumeAttempt attempt;
  final List<ResumeAnswer> answers;
  final List<ResumeSection> sections;
  ResumeState({required this.attempt, required this.answers, required this.sections});
  factory ResumeState.fromJson(Map<String, dynamic> j) => ResumeState(
        attempt: ResumeAttempt.fromJson((j['attempt'] as Map).cast<String, dynamic>()),
        answers: ((j['answers'] as List?) ?? [])
            .map((a) => ResumeAnswer.fromJson((a as Map).cast<String, dynamic>()))
            .toList(),
        sections: ((j['sections'] as List?) ?? [])
            .map((s) => ResumeSection.fromJson((s as Map).cast<String, dynamic>()))
            .toList(),
      );
}

class ResumeAttempt {
  final String id;
  final String examId;
  final String status; // 'in_progress' | 'paused' | 'submitted' | 'abandoned'
  final String mode;   // 'continuous' | 'sectioned'
  final DateTime? lastSavedAt;
  final DateTime? pausedAt;
  final int? timeRemainingMs;
  final String? currentQuestionId;
  final String? currentSectionId;
  final String deviceId;
  final bool isPractice;
  final List<String> questionOrder;

  ResumeAttempt({
    required this.id,
    required this.examId,
    required this.status,
    required this.mode,
    this.lastSavedAt,
    this.pausedAt,
    this.timeRemainingMs,
    this.currentQuestionId,
    this.currentSectionId,
    required this.deviceId,
    required this.isPractice,
    required this.questionOrder,
  });

  factory ResumeAttempt.fromJson(Map<String, dynamic> j) => ResumeAttempt(
        id: j['id'].toString(),
        examId: j['exam_id'].toString(),
        status: (j['status'] as String?) ?? 'in_progress',
        mode: (j['mode'] as String?) ?? 'continuous',
        lastSavedAt: _parseDate(j['last_saved_at']),
        pausedAt: _parseDate(j['paused_at']),
        timeRemainingMs: j['time_remaining_ms'] is int ? j['time_remaining_ms'] as int : null,
        currentQuestionId: j['current_question_id']?.toString(),
        currentSectionId: j['current_section_id']?.toString(),
        deviceId: (j['device_id'] as String?) ?? '',
        isPractice: (j['isPractice'] as bool?) ?? false,
        questionOrder: ((j['question_order'] as List?) ?? []).map((e) => e.toString()).toList(),
      );

  bool get isResumable => status == 'in_progress' || status == 'paused';
}

class ResumeAnswer {
  final String questionId;
  final String selectedOption;
  final bool attempted;
  final bool skipped;
  final bool markedForReview;
  final bool bookmarked;
  final int? confidence;
  final int? timeSpentMs;

  ResumeAnswer({
    required this.questionId,
    required this.selectedOption,
    required this.attempted,
    required this.skipped,
    required this.markedForReview,
    required this.bookmarked,
    this.confidence,
    this.timeSpentMs,
  });

  factory ResumeAnswer.fromJson(Map<String, dynamic> j) => ResumeAnswer(
        questionId: j['question_id'].toString(),
        selectedOption: (j['selected_option'] as String?) ?? '',
        attempted: (j['attempted'] as bool?) ?? false,
        skipped: (j['skipped'] as bool?) ?? false,
        markedForReview: (j['marked_for_review'] as bool?) ?? false,
        bookmarked: (j['bookmarks'] as bool?) ?? false,
        confidence: j['confidence'] is num ? (j['confidence'] as num).toInt() : null,
        timeSpentMs: j['time_spent_ms'] is num ? (j['time_spent_ms'] as num).toInt() : null,
      );
}

class ResumeSection {
  final String sectionId;
  final String status;
  final int? timeRemainingMs;
  final DateTime? startedAt;
  final DateTime? submittedAt;
  final String? currentQuestionId;
  final int questionsAnswered;

  ResumeSection({
    required this.sectionId,
    required this.status,
    this.timeRemainingMs,
    this.startedAt,
    this.submittedAt,
    this.currentQuestionId,
    required this.questionsAnswered,
  });

  factory ResumeSection.fromJson(Map<String, dynamic> j) => ResumeSection(
        sectionId: j['section_id'].toString(),
        status: (j['status'] as String?) ?? 'available',
        timeRemainingMs: j['time_remaining_ms'] is num ? (j['time_remaining_ms'] as num).toInt() : null,
        startedAt: _parseDate(j['started_at']),
        submittedAt: _parseDate(j['submitted_at']),
        currentQuestionId: j['current_question_id']?.toString(),
        questionsAnswered: (j['questions_answered'] as int?) ?? 0,
      );
}

class InProgressAttempt {
  final String id;
  final String examId;
  final String examName;
  final String mode;
  final String status;
  final DateTime? lastSavedAt;
  final DateTime? pausedAt;
  final int? timeRemainingMs;
  final String? currentQuestionId;
  final String? currentSectionId;
  final int questionsAnswered;
  final bool isPractice;

  InProgressAttempt({
    required this.id,
    required this.examId,
    required this.examName,
    required this.mode,
    required this.status,
    this.lastSavedAt,
    this.pausedAt,
    this.timeRemainingMs,
    this.currentQuestionId,
    this.currentSectionId,
    required this.questionsAnswered,
    required this.isPractice,
  });

  factory InProgressAttempt.fromJson(Map<String, dynamic> j) => InProgressAttempt(
        id: j['id'].toString(),
        examId: j['exam_id'].toString(),
        examName: (j['exam_name'] as String?) ?? '',
        mode: (j['mode'] as String?) ?? 'continuous',
        status: (j['status'] as String?) ?? 'in_progress',
        lastSavedAt: _parseDate(j['last_saved_at']),
        pausedAt: _parseDate(j['paused_at']),
        timeRemainingMs: j['time_remaining_ms'] is num ? (j['time_remaining_ms'] as num).toInt() : null,
        currentQuestionId: j['current_question_id']?.toString(),
        currentSectionId: j['current_section_id']?.toString(),
        questionsAnswered: (j['questions_answered'] as int?) ?? 0,
        isPractice: (j['isPractice'] as bool?) ?? false,
      );
}

class HeartbeatResult {
  final bool ok;
  final int answersWritten;
  final DateTime? lastSavedAt;
  HeartbeatResult({required this.ok, required this.answersWritten, this.lastSavedAt});
  factory HeartbeatResult.fromJson(Map<String, dynamic> j) => HeartbeatResult(
        ok: (j['ok'] as bool?) ?? false,
        answersWritten: (j['answers_written'] as int?) ?? 0,
        lastSavedAt: _parseDate(j['last_saved_at']),
      );
}

class SubmitResult {
  final bool ok;
  final bool alreadySubmitted;
  final DateTime? submittedAt;
  final num? score;
  final int? correctCount;
  final int? incorrectCount;
  final int? skippedCount;
  SubmitResult({
    required this.ok,
    required this.alreadySubmitted,
    this.submittedAt,
    this.score,
    this.correctCount,
    this.incorrectCount,
    this.skippedCount,
  });
  factory SubmitResult.fromJson(Map<String, dynamic> j) => SubmitResult(
        ok: (j['ok'] as bool?) ?? false,
        alreadySubmitted: (j['already_submitted'] as bool?) ?? false,
        submittedAt: _parseDate(j['submitted_at']),
        score: j['score'] as num?,
        correctCount: (j['correctCount'] as int?),
        incorrectCount: (j['incorrectCount'] as int?),
        skippedCount: (j['skippedCount'] as int?),
      );
}

class AnswerPatch {
  final String questionId;
  final String? selectedOption;
  final bool? attempted;
  final bool? skipped;
  final bool? markedForReview;
  final bool? bookmarks;
  final int? confidence;
  final int? timeSpentMs;

  AnswerPatch({
    required this.questionId,
    this.selectedOption,
    this.attempted,
    this.skipped,
    this.markedForReview,
    this.bookmarks,
    this.confidence,
    this.timeSpentMs,
  });

  Map<String, dynamic> toJson() => {
        'question_id': questionId,
        if (selectedOption != null) 'selected_option': selectedOption,
        if (attempted != null) 'attempted': attempted,
        if (skipped != null) 'skipped': skipped,
        if (markedForReview != null) 'marked_for_review': markedForReview,
        if (bookmarks != null) 'bookmarks': bookmarks,
        if (confidence != null) 'confidence': confidence,
        if (timeSpentMs != null) 'time_spent_ms': timeSpentMs,
      };
}

class SectionTime {
  final String sectionId;
  final int? timeRemainingMs;
  final String? status;
  final String? currentQuestionId;
  final int? questionsAnswered;
  SectionTime({
    required this.sectionId,
    this.timeRemainingMs,
    this.status,
    this.currentQuestionId,
    this.questionsAnswered,
  });
  Map<String, dynamic> toJson() => {
        'section_id': sectionId,
        if (timeRemainingMs != null) 'time_remaining_ms': timeRemainingMs,
        if (status != null) 'status': status,
        if (currentQuestionId != null) 'current_question_id': currentQuestionId,
        if (questionsAnswered != null) 'questions_answered': questionsAnswered,
      };
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
  return null;
}

// ════════════════════════════════════════════════════════════════════
// Typed exceptions
// ════════════════════════════════════════════════════════════════════

class ExamAttemptException implements Exception {
  final int status;
  final String code;
  final String message;
  ExamAttemptException(this.status, this.code, this.message);
  @override
  String toString() => 'ExamAttemptException($status / $code): $message';
}

class ActiveSessionElsewhere extends ExamAttemptException {
  final int? staleSinceMs;
  ActiveSessionElsewhere(String message, this.staleSinceMs)
      : super(409, 'ACTIVE_SESSION_ELSEWHERE', message);
}

class AttemptFinalized extends ExamAttemptException {
  AttemptFinalized(String message) : super(410, 'ATTEMPT_FINALIZED', message);
}
