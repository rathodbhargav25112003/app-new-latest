// ════════════════════════════════════════════════════════════════════
// ExamAnalyticsApi — wraps the post-attempt analytics + AI endpoints
// ════════════════════════════════════════════════════════════════════
//
// Sister client to ExamAttemptApi. Keeps the analytics endpoints
// separate so the exam screen can avoid loading any analytics code
// during the attempt itself, and the review screen can avoid loading
// the heartbeat machinery.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/constants.dart' show baseUrl;

class ExamAnalyticsApi {
  final http.Client _http;
  ExamAnalyticsApi({http.Client? client}) : _http = client ?? http.Client();

  Future<Map<String, String>> _headers() async {
    final p = await SharedPreferences.getInstance();
    final token = p.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': token,
    };
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final res = await _http.get(Uri.parse('$baseUrl$path'), headers: await _headers());
    return _decode(res);
  }

  Future<Map<String, dynamic>> _post(String path, [Map<String, dynamic>? body]) async {
    final res = await _http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body ?? {}),
    );
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic> json;
    try {
      json = (jsonDecode(res.body) as Map).cast<String, dynamic>();
    } catch (_) {
      throw Exception('invalid_json: ${res.statusCode}');
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (json['data'] is Map) return (json['data'] as Map).cast<String, dynamic>();
      return json;
    }
    throw Exception('${res.statusCode}: ${json['message'] ?? 'request failed'}');
  }

  // ─── Heatmap ────────────────────────────────────────────────────
  Future<HeatmapResult> heatmap(String userExamId) async =>
      HeatmapResult.fromJson(await _get('/exam-attempt/$userExamId/analytics/heatmap'));

  // ─── Time pressure ──────────────────────────────────────────────
  Future<TimePressureResult> timePressure(String userExamId) async =>
      TimePressureResult.fromJson(await _get('/exam-attempt/$userExamId/analytics/time-pressure'));

  // ─── Confidence calibration ─────────────────────────────────────
  Future<ConfidenceCalibration> confidenceCalibration(String userExamId) async =>
      ConfidenceCalibration.fromJson(
        await _get('/exam-attempt/$userExamId/analytics/confidence-calibration'),
      );

  // ─── Cohort percentile ──────────────────────────────────────────
  Future<CohortPercentile> cohortPercentile(String userExamId) async =>
      CohortPercentile.fromJson(
        await _get('/exam-attempt/$userExamId/analytics/cohort-percentile'),
      );

  // ─── Auto-build remediation set ─────────────────────────────────
  Future<RemediationResult> buildRemediation(String userExamId) async =>
      RemediationResult.fromJson(await _post('/exam-attempt/$userExamId/remediation'));

  // ─── Claude: why wrong ──────────────────────────────────────────
  Future<WhyWrongResult> whyWrong({
    required String userExamId,
    required String questionId,
  }) async =>
      WhyWrongResult.fromJson(
        await _post('/exam-attempt/$userExamId/why-wrong/$questionId'),
      );

  // ─── Claude: pattern summary ────────────────────────────────────
  Future<PatternSummary> patternSummary(String userExamId) async =>
      PatternSummary.fromJson(await _post('/exam-attempt/$userExamId/ai/pattern-summary'));

  // ─── Claude: similar questions ──────────────────────────────────
  Future<SimilarQuestions> similarQuestions(String questionId) async =>
      SimilarQuestions.fromJson(await _post('/question/$questionId/ai/similar'));

  // ─── Doubt chat ─────────────────────────────────────────────────
  Future<DoubtChatThread> openDoubtChat(String questionId, {String? userExamId}) async =>
      DoubtChatThread.fromJson(await _get(
        '/doubt-chat/$questionId${userExamId != null ? '?user_exam_id=$userExamId' : ''}',
      ));

  Future<DoubtChatThread> sendDoubtMessage(
    String questionId,
    String text, {
    String? userExamId,
  }) async =>
      DoubtChatThread.fromJson(await _post(
        '/doubt-chat/$questionId/message',
        {'text': text, if (userExamId != null) 'user_exam_id': userExamId},
      ));

  Future<void> closeDoubtChat(String questionId) async {
    await _post('/doubt-chat/$questionId/close');
  }

  // ─── Streak ─────────────────────────────────────────────────────
  Future<StreakInfo> streak() async =>
      StreakInfo.fromJson(await _get('/users/me/streak'));

  // ─── Spaced rep due ─────────────────────────────────────────────
  Future<List<dynamic>> spacedRepDue({int limit = 20}) async {
    final r = await _get('/spaced-rep/due?limit=$limit');
    return (r['items'] as List?) ?? (r['cards'] as List?) ?? [];
  }

  Future<void> spacedRepGrade(String queueId, int ease) async {
    await _post('/spaced-rep/grade/$queueId', {'ease': ease});
  }

  // ─── Mocks scheduled / unlocked ─────────────────────────────────
  Future<List<dynamic>> activeMocks() async {
    final r = await _get('/mock-schedules/active');
    return (r['schedules'] as List?) ?? [];
  }

  // ─── Question report ────────────────────────────────────────────
  Future<void> reportQuestion({
    required String questionId,
    required String reason,
    String? details,
    String? userExamId,
  }) async {
    await _post('/question-report', {
      'question_id': questionId,
      'reason': reason,
      if (details != null) 'details': details,
      if (userExamId != null) 'user_exam_id': userExamId,
    });
  }

  void close() => _http.close();
}

// ════════════════════════════════════════════════════════════════════
// DTOs
// ════════════════════════════════════════════════════════════════════

class HeatmapResult {
  final List<HeatmapTopic> topics;
  final int totalCount, totalAttempted, totalCorrect;
  HeatmapResult({
    required this.topics,
    required this.totalCount,
    required this.totalAttempted,
    required this.totalCorrect,
  });
  factory HeatmapResult.fromJson(Map<String, dynamic> j) {
    final totals = (j['totals'] as Map?)?.cast<String, dynamic>() ?? {};
    return HeatmapResult(
      topics: ((j['topics'] as List?) ?? [])
          .map((t) => HeatmapTopic.fromJson((t as Map).cast<String, dynamic>()))
          .toList(),
      totalCount: (totals['count'] as int?) ?? 0,
      totalAttempted: (totals['attempted'] as int?) ?? 0,
      totalCorrect: (totals['correct'] as int?) ?? 0,
    );
  }
}

class HeatmapTopic {
  final String topicId;
  final int count, attempted, correct;
  final double accuracy, weaknessScore;
  final int? avgTimePerQMs;
  final int? avgConfidence;
  final List<HeatmapSubtopic> subtopics;
  HeatmapTopic({
    required this.topicId,
    required this.count,
    required this.attempted,
    required this.correct,
    required this.accuracy,
    required this.weaknessScore,
    this.avgTimePerQMs,
    this.avgConfidence,
    required this.subtopics,
  });
  factory HeatmapTopic.fromJson(Map<String, dynamic> j) => HeatmapTopic(
        topicId: (j['topic_id'] ?? '').toString(),
        count: (j['count'] as int?) ?? 0,
        attempted: (j['attempted'] as int?) ?? 0,
        correct: (j['correct'] as int?) ?? 0,
        accuracy: (j['accuracy'] as num?)?.toDouble() ?? 0,
        weaknessScore: (j['weakness_score'] as num?)?.toDouble() ?? 0,
        avgTimePerQMs: (j['avg_time_per_q_ms'] as num?)?.toInt(),
        avgConfidence: (j['avg_confidence'] as num?)?.toInt(),
        subtopics: ((j['subtopics'] as List?) ?? [])
            .map((s) => HeatmapSubtopic.fromJson((s as Map).cast<String, dynamic>()))
            .toList(),
      );
}

class HeatmapSubtopic {
  final String subcategoryId;
  final int count, attempted, correct;
  final double accuracy, weaknessScore;
  HeatmapSubtopic({
    required this.subcategoryId,
    required this.count,
    required this.attempted,
    required this.correct,
    required this.accuracy,
    required this.weaknessScore,
  });
  factory HeatmapSubtopic.fromJson(Map<String, dynamic> j) => HeatmapSubtopic(
        subcategoryId: (j['subcategory_id'] ?? '').toString(),
        count: (j['count'] as int?) ?? 0,
        attempted: (j['attempted'] as int?) ?? 0,
        correct: (j['correct'] as int?) ?? 0,
        accuracy: (j['accuracy'] as num?)?.toDouble() ?? 0,
        weaknessScore: (j['weakness_score'] as num?)?.toDouble() ?? 0,
      );
}

class TimePressureResult {
  final Map<String, int> counts;
  final Map<String, List<String>> questions;
  final int fastMs, slowMs;
  TimePressureResult({
    required this.counts,
    required this.questions,
    required this.fastMs,
    required this.slowMs,
  });
  factory TimePressureResult.fromJson(Map<String, dynamic> j) {
    final c = (j['counts'] as Map?)?.cast<String, dynamic>() ?? {};
    final q = (j['questions'] as Map?)?.cast<String, dynamic>() ?? {};
    final th = (j['thresholds'] as Map?)?.cast<String, dynamic>() ?? {};
    return TimePressureResult(
      counts: c.map((k, v) => MapEntry(k, (v as int?) ?? 0)),
      questions: q.map((k, v) =>
          MapEntry(k, ((v as List?) ?? []).map((x) => x.toString()).toList())),
      fastMs: (th['fast_ms'] as int?) ?? 20000,
      slowMs: (th['slow_ms'] as int?) ?? 120000,
    );
  }
}

class ConfidenceCalibration {
  final List<CalibrationBin> bins;
  final int totalCount;
  final double? brierScore;
  ConfidenceCalibration({required this.bins, required this.totalCount, this.brierScore});
  factory ConfidenceCalibration.fromJson(Map<String, dynamic> j) {
    final totals = (j['totals'] as Map?)?.cast<String, dynamic>() ?? {};
    return ConfidenceCalibration(
      bins: ((j['bins'] as List?) ?? [])
          .map((b) => CalibrationBin.fromJson((b as Map).cast<String, dynamic>()))
          .toList(),
      totalCount: (totals['count'] as int?) ?? 0,
      brierScore: (totals['brier_score'] as num?)?.toDouble(),
    );
  }
}

class CalibrationBin {
  final String label;
  final int count, correct;
  final double accuracy, delta;
  CalibrationBin({
    required this.label,
    required this.count,
    required this.correct,
    required this.accuracy,
    required this.delta,
  });
  factory CalibrationBin.fromJson(Map<String, dynamic> j) => CalibrationBin(
        label: (j['label'] as String?) ?? '',
        count: (j['count'] as int?) ?? 0,
        correct: (j['correct'] as int?) ?? 0,
        accuracy: (j['accuracy'] as num?)?.toDouble() ?? 0,
        delta: (j['delta'] as num?)?.toDouble() ?? 0,
      );
}

class CohortPercentile {
  final num myScore;
  final int cohortSize;
  final double percentile;
  final List<HistogramBin> histogram;
  CohortPercentile({
    required this.myScore,
    required this.cohortSize,
    required this.percentile,
    required this.histogram,
  });
  factory CohortPercentile.fromJson(Map<String, dynamic> j) => CohortPercentile(
        myScore: (j['my_score'] as num?) ?? 0,
        cohortSize: (j['cohort_size'] as int?) ?? 0,
        percentile: (j['percentile'] as num?)?.toDouble() ?? 0,
        histogram: ((j['histogram'] as List?) ?? [])
            .map((h) => HistogramBin.fromJson((h as Map).cast<String, dynamic>()))
            .toList(),
      );
}

class HistogramBin {
  final List<int> range;
  final int count;
  HistogramBin({required this.range, required this.count});
  factory HistogramBin.fromJson(Map<String, dynamic> j) => HistogramBin(
        range: ((j['range'] as List?) ?? []).map((e) => (e as num).toInt()).toList(),
        count: (j['count'] as int?) ?? 0,
      );
}

class RemediationResult {
  final String? userExamId;
  final int count;
  final List<String> questions;
  RemediationResult({this.userExamId, required this.count, required this.questions});
  factory RemediationResult.fromJson(Map<String, dynamic> j) => RemediationResult(
        userExamId: j['user_exam_id']?.toString(),
        count: (j['count'] as int?) ?? 0,
        questions: ((j['questions'] as List?) ?? []).map((e) => e.toString()).toList(),
      );
}

class WhyWrongResult {
  final String text;
  final bool cached;
  final String? correctOption;
  final String? studentChoice;
  final bool? isCorrect;
  final String? error;
  WhyWrongResult({
    required this.text,
    required this.cached,
    this.correctOption,
    this.studentChoice,
    this.isCorrect,
    this.error,
  });
  factory WhyWrongResult.fromJson(Map<String, dynamic> j) => WhyWrongResult(
        text: (j['text'] as String?) ?? '',
        cached: (j['cached'] as bool?) ?? false,
        correctOption: j['correct_option']?.toString(),
        studentChoice: j['student_choice']?.toString(),
        isCorrect: j['is_correct'] as bool?,
        error: j['error'] as String?,
      );
}

class PatternSummary {
  final String text;
  final bool cached;
  final String? error;
  PatternSummary({required this.text, required this.cached, this.error});
  factory PatternSummary.fromJson(Map<String, dynamic> j) => PatternSummary(
        text: (j['text'] as String?) ?? '',
        cached: (j['cached'] as bool?) ?? false,
        error: j['error'] as String?,
      );
}

class SimilarQuestions {
  final List<GeneratedQuestion> questions;
  final bool cached;
  final String? error;
  SimilarQuestions({required this.questions, required this.cached, this.error});
  factory SimilarQuestions.fromJson(Map<String, dynamic> j) => SimilarQuestions(
        questions: ((j['questions'] as List?) ?? [])
            .map((q) => GeneratedQuestion.fromJson((q as Map).cast<String, dynamic>()))
            .toList(),
        cached: (j['cached'] as bool?) ?? false,
        error: j['error'] as String?,
      );
}

class GeneratedQuestion {
  final String stem;
  final Map<String, String> options;
  final String correct;
  final String explanation;
  GeneratedQuestion({
    required this.stem,
    required this.options,
    required this.correct,
    required this.explanation,
  });
  factory GeneratedQuestion.fromJson(Map<String, dynamic> j) => GeneratedQuestion(
        stem: (j['stem'] as String?) ?? '',
        options: ((j['options'] as Map?)?.cast<String, dynamic>() ?? {})
            .map((k, v) => MapEntry(k, v.toString())),
        correct: (j['correct'] as String?) ?? '',
        explanation: (j['explanation'] as String?) ?? '',
      );
}

class DoubtChatThread {
  final String? id;
  final List<DoubtChatMessage> messages;
  final DateTime? closedAt;
  DoubtChatThread({this.id, required this.messages, this.closedAt});
  factory DoubtChatThread.fromJson(Map<String, dynamic> j) => DoubtChatThread(
        id: j['id']?.toString(),
        messages: ((j['messages'] as List?) ?? [])
            .map((m) => DoubtChatMessage.fromJson((m as Map).cast<String, dynamic>()))
            .toList(),
        closedAt: j['closed_at'] != null ? DateTime.tryParse(j['closed_at'].toString()) : null,
      );
}

class DoubtChatMessage {
  final String role;
  final String text;
  final DateTime? createdAt;
  DoubtChatMessage({required this.role, required this.text, this.createdAt});
  factory DoubtChatMessage.fromJson(Map<String, dynamic> j) => DoubtChatMessage(
        role: (j['role'] as String?) ?? 'user',
        text: (j['text'] as String?) ?? '',
        createdAt: j['created_at'] != null ? DateTime.tryParse(j['created_at'].toString()) : null,
      );
}

class StreakInfo {
  final int current;
  final int longest;
  final String? lastActiveDate;
  final int totalActiveDays;
  StreakInfo({
    required this.current,
    required this.longest,
    this.lastActiveDate,
    required this.totalActiveDays,
  });
  factory StreakInfo.fromJson(Map<String, dynamic> j) => StreakInfo(
        current: (j['current'] as int?) ?? 0,
        longest: (j['longest'] as int?) ?? 0,
        lastActiveDate: j['last_active_date'] as String?,
        totalActiveDays: (j['total_active_days'] as int?) ?? 0,
      );
}
