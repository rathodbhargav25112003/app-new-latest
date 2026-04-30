// MCQ Review v3 — Service layer for confidence / discussion / SR queue /
// analytics / study plan / scheduled sessions / audio explain.
//
// Plain http package, SharedPreferences token — same idiom as ApiService.
// One class instead of N micro-services to keep the surface small.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/constants.dart';
import '../../models/mcq_review_models.dart';

class McqReviewService {
  Future<Map<String, String>> _headers({bool json = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      if (json) 'Content-Type': 'application/json',
      'Authorization': token,
    };
  }

  Map<String, dynamic> _unwrap(http.Response res) {
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) {
      if (decoded['data'] is Map<String, dynamic>) return decoded['data'] as Map<String, dynamic>;
      return decoded;
    }
    return {};
  }

  // ═══ CONFIDENCE + TIME ════════════════════════════════════════════════

  /// Patch the user-answer with confidence (0..100) + time spent (ms).
  /// Call this right after the student rates and before they tap "View Answer".
  Future<bool> updateConfidence({
    required String userAnswerId,
    int? confidence,
    int? timeSpentMs,
  }) async {
    final res = await http.patch(
      Uri.parse(userAnswerConfidence),
      headers: await _headers(),
      body: jsonEncode({
        'user_answer_id': userAnswerId,
        if (confidence != null) 'confidence': confidence,
        if (timeSpentMs != null) 'time_spent_ms': timeSpentMs,
      }),
    );
    return res.statusCode == 200;
  }

  /// Bulk-enroll wrong + low-confidence Qs from a finished UserExam attempt
  /// into the spaced-rep queue. Call once on submit.
  Future<int> enrollFromAttempt(String userExamId) async {
    final res = await http.post(
      Uri.parse(reviewQueueEnrollFromAttempt),
      headers: await _headers(),
      body: jsonEncode({'user_exam_id': userExamId}),
    );
    if (res.statusCode == 200) {
      final data = _unwrap(res);
      return (data['enrolled'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  // ═══ REVIEW QUEUE (SM-2) ═══════════════════════════════════════════════

  Future<Map<String, dynamic>> getDueReviews({String? topic, String? difficulty, int limit = 20}) async {
    final qp = <String, String>{'limit': '$limit'};
    if (topic != null) qp['topic'] = topic;
    if (difficulty != null) qp['difficulty'] = difficulty;
    final res = await http.get(
      Uri.parse(reviewQueueDue).replace(queryParameters: qp),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = _unwrap(res);
      return {
        'items': (data['items'] as List? ?? [])
            .map((e) => ReviewQueueItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        'total_due': data['total_due'] ?? 0,
        'total_active': data['total_active'] ?? 0,
      };
    }
    return {'items': <ReviewQueueItem>[], 'total_due': 0, 'total_active': 0};
  }

  Future<ReviewQueueStats> getReviewStats() async {
    final res = await http.get(Uri.parse(reviewQueueStats), headers: await _headers());
    if (res.statusCode == 200) return ReviewQueueStats.fromJson(_unwrap(res));
    return ReviewQueueStats();
  }

  Future<bool> enrollManual(String questionId, {int? confidence}) async {
    final res = await http.post(
      Uri.parse(reviewQueueEnroll),
      headers: await _headers(),
      body: jsonEncode({'question_id': questionId, if (confidence != null) 'confidence': confidence}),
    );
    return res.statusCode == 200 || res.statusCode == 201;
  }

  /// SM-2 grade — 0..5. 0=blackout, 5=perfect.
  Future<ReviewQueueItem?> grade(String queueId, int ease) async {
    final res = await http.post(
      Uri.parse('$reviewQueueGrade/$queueId/grade'),
      headers: await _headers(),
      body: jsonEncode({'ease': ease}),
    );
    if (res.statusCode == 200) return ReviewQueueItem.fromJson(_unwrap(res));
    return null;
  }

  Future<bool> setQueueStatus(String queueId, String status) async {
    final res = await http.patch(
      Uri.parse('$reviewQueueStatus/$queueId/status'),
      headers: await _headers(),
      body: jsonEncode({'status': status}),
    );
    return res.statusCode == 200;
  }

  // ═══ DISCUSSION THREADS ═══════════════════════════════════════════════

  Future<Map<String, dynamic>> getThread(String questionId, {String sort = 'top', int page = 1}) async {
    final res = await http.get(
      Uri.parse('$discussionThread/$questionId').replace(queryParameters: {'sort': sort, 'page': '$page'}),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = _unwrap(res);
      return {
        'discussion': data['discussion'],
        'posts': (data['posts'] as List? ?? [])
            .map((e) => DiscussionPost.fromJson(e as Map<String, dynamic>))
            .toList(),
        'total': data['total'] ?? 0,
      };
    }
    return {'discussion': null, 'posts': <DiscussionPost>[], 'total': 0};
  }

  Future<List<DiscussionPost>> getReplies(String parentPostId) async {
    final res = await http.get(
      Uri.parse('$discussionPostBase/$parentPostId/replies'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = _unwrap(res);
      return (data['replies'] as List? ?? [])
          .map((e) => DiscussionPost.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<DiscussionPost?> createPost(String questionId, String content, {String? parentPostId}) async {
    final res = await http.post(
      Uri.parse('$discussionPost/$questionId/post'),
      headers: await _headers(),
      body: jsonEncode({
        'content': content,
        if (parentPostId != null) 'parent_post_id': parentPostId,
      }),
    );
    if (res.statusCode == 200 || res.statusCode == 201) return DiscussionPost.fromJson(_unwrap(res));
    return null;
  }

  Future<DiscussionPost?> editPost(String postId, String newContent) async {
    final res = await http.patch(
      Uri.parse('$discussionPostBase/$postId'),
      headers: await _headers(),
      body: jsonEncode({'content': newContent}),
    );
    if (res.statusCode == 200) return DiscussionPost.fromJson(_unwrap(res));
    return null;
  }

  Future<bool> deletePost(String postId) async {
    final res = await http.delete(
      Uri.parse('$discussionPostBase/$postId'),
      headers: await _headers(),
    );
    return res.statusCode == 200;
  }

  Future<Map<String, dynamic>> toggleUpvote(String postId) async {
    final res = await http.post(
      Uri.parse('$discussionPostBase/$postId/upvote'),
      headers: await _headers(),
      body: jsonEncode({}),
    );
    if (res.statusCode == 200) return _unwrap(res);
    return {'upvoted': false, 'upvote_count': 0};
  }

  Future<bool> reportPost(String postId, String reason) async {
    final res = await http.post(
      Uri.parse('$discussionPostBase/$postId/report'),
      headers: await _headers(),
      body: jsonEncode({'reason': reason}),
    );
    return res.statusCode == 200;
  }

  // ═══ ANALYTICS ═════════════════════════════════════════════════════════

  Future<List<TopicTrendPoint>> topicTrend({int days = 30, String? topic}) async {
    final qp = <String, String>{'days': '$days'};
    if (topic != null) qp['topic'] = topic;
    final res = await http.get(
      Uri.parse(analyticsTopicTrend).replace(queryParameters: qp),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = _unwrap(res);
      return (data['trend'] as List? ?? [])
          .map((e) => TopicTrendPoint.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> calibration({int days = 90}) async {
    final res = await http.get(
      Uri.parse(analyticsCalibration).replace(queryParameters: {'days': '$days'}),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = _unwrap(res);
      return {
        'buckets': (data['buckets'] as List? ?? [])
            .map((e) => CalibrationBucket.fromJson(e as Map<String, dynamic>))
            .toList(),
        'brier_score': data['brier_score'],
        'sample_size': data['sample_size'] ?? 0,
      };
    }
    return {'buckets': <CalibrationBucket>[], 'brier_score': null, 'sample_size': 0};
  }

  Future<Map<String, dynamic>> questionTimeStats(String questionId) async {
    final res = await http.get(
      Uri.parse('$analyticsQuestionTime/$questionId'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) return _unwrap(res);
    return {'n': 0, 'avg_ms': null};
  }

  Future<List<TopicStrength>> topicStrength({int days = 90}) async {
    final res = await http.get(
      Uri.parse(analyticsTopicStrength).replace(queryParameters: {'days': '$days'}),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = _unwrap(res);
      return (data['topics'] as List? ?? [])
          .map((e) => TopicStrength.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ═══ STUDY PLAN ═══════════════════════════════════════════════════════

  Future<StudyPlan?> generateStudyPlan({
    required DateTime examDate,
    int dailyMinutes = 60,
    int? accuracyPct,
    int? totalAttempts,
  }) async {
    final res = await http.post(
      Uri.parse(cortexStudyPlan),
      headers: await _headers(),
      body: jsonEncode({
        'exam_date': examDate.toUtc().toIso8601String(),
        'daily_minutes': dailyMinutes,
        if (accuracyPct != null) 'accuracy_pct': accuracyPct,
        if (totalAttempts != null) 'total_attempts': totalAttempts,
      }),
    );
    if (res.statusCode == 200 || res.statusCode == 201) return StudyPlan.fromJson(_unwrap(res));
    return null;
  }

  Future<StudyPlan?> getActiveStudyPlan() async {
    final res = await http.get(Uri.parse(cortexStudyPlan), headers: await _headers());
    if (res.statusCode == 200) {
      final data = _unwrap(res);
      if (data.isEmpty) return null;
      return StudyPlan.fromJson(data);
    }
    return null;
  }

  Future<StudyPlan?> updatePlanItem(String itemId, String status) async {
    final res = await http.patch(
      Uri.parse('$cortexStudyPlan/item/$itemId'),
      headers: await _headers(),
      body: jsonEncode({'status': status}),
    );
    if (res.statusCode == 200) return StudyPlan.fromJson(_unwrap(res));
    return null;
  }

  // ═══ AUDIO EXPLAIN ═════════════════════════════════════════════════════

  Future<Map<String, dynamic>> audioExplain({
    required String questionText,
    required List<dynamic> options,  // can be {value,answer_title} or strings
    required String correctOption,
    String? briefExplanation,
  }) async {
    final res = await http.post(
      Uri.parse(cortexAudioExplain),
      headers: await _headers(),
      body: jsonEncode({
        'question_text': questionText,
        'options': options,
        'correct_option': correctOption,
        if (briefExplanation != null) 'brief_explanation': briefExplanation,
      }),
    );
    if (res.statusCode == 200) return _unwrap(res);
    return {'script': '', 'estimated_seconds': 0};
  }

  // ═══ SCHEDULED SESSIONS ═══════════════════════════════════════════════

  Future<ScheduledSession?> createScheduledSession({
    required String kind,
    String? topic,
    List<int>? daysOfWeek,
    String timeOfDay = '19:00',
    String timezone = 'Asia/Kolkata',
    int estimatedMinutes = 15,
  }) async {
    final res = await http.post(
      Uri.parse(cortexScheduledSession),
      headers: await _headers(),
      body: jsonEncode({
        'kind': kind,
        if (topic != null) 'topic': topic,
        if (daysOfWeek != null) 'days_of_week': daysOfWeek,
        'time_of_day': timeOfDay,
        'timezone': timezone,
        'estimated_minutes': estimatedMinutes,
      }),
    );
    if (res.statusCode == 200 || res.statusCode == 201) return ScheduledSession.fromJson(_unwrap(res));
    return null;
  }

  Future<List<ScheduledSession>> listScheduledSessions() async {
    final res = await http.get(Uri.parse(cortexScheduledSessions), headers: await _headers());
    if (res.statusCode == 200) {
      final data = _unwrap(res);
      return (data['sessions'] as List? ?? [])
          .map((e) => ScheduledSession.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<bool> updateScheduledSession(String id, Map<String, dynamic> patch) async {
    final res = await http.patch(
      Uri.parse('$cortexScheduledSession/$id'),
      headers: await _headers(),
      body: jsonEncode(patch),
    );
    return res.statusCode == 200;
  }

  Future<bool> deleteScheduledSession(String id) async {
    final res = await http.delete(
      Uri.parse('$cortexScheduledSession/$id'),
      headers: await _headers(),
    );
    return res.statusCode == 200;
  }
}
