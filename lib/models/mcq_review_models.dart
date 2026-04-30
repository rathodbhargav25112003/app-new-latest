// MCQ Review v3 — JSON models for discussion / review queue / study plan /
// scheduled sessions / analytics. Plain Dart classes — no codegen
// required. Forgiving fromJson defaults so partial server payloads
// don't crash the UI.

class DiscussionPost {
  final String id;
  final String discussionId;
  final String questionId;
  final String userId;
  final String? parentPostId;
  final String content;
  final bool isInstructor;
  final bool isPinned;
  final bool isAcceptedAnswer;
  final bool isEdited;
  final int upvoteCount;
  final int replyCount;
  final bool didIUpvote;
  final DateTime? createdAt;

  DiscussionPost({
    required this.id,
    required this.discussionId,
    required this.questionId,
    required this.userId,
    this.parentPostId,
    required this.content,
    this.isInstructor = false,
    this.isPinned = false,
    this.isAcceptedAnswer = false,
    this.isEdited = false,
    this.upvoteCount = 0,
    this.replyCount = 0,
    this.didIUpvote = false,
    this.createdAt,
  });

  factory DiscussionPost.fromJson(Map<String, dynamic> json) => DiscussionPost(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        discussionId: (json['discussion_id'] ?? '').toString(),
        questionId: (json['question_id'] ?? '').toString(),
        userId: (json['user_id'] ?? '').toString(),
        parentPostId: json['parent_post_id']?.toString(),
        content: (json['content'] ?? '').toString(),
        isInstructor: json['is_instructor'] == true,
        isPinned: json['is_pinned'] == true,
        isAcceptedAnswer: json['is_accepted_answer'] == true,
        isEdited: json['is_edited'] == true,
        upvoteCount: _i(json['upvote_count']),
        replyCount: _i(json['reply_count']),
        didIUpvote: json['did_i_upvote'] == true,
        createdAt: _d(json['created_at']),
      );

  DiscussionPost copyWith({int? upvoteCount, bool? didIUpvote, String? content, bool? isEdited}) {
    return DiscussionPost(
      id: id, discussionId: discussionId, questionId: questionId, userId: userId,
      parentPostId: parentPostId, content: content ?? this.content,
      isInstructor: isInstructor, isPinned: isPinned, isAcceptedAnswer: isAcceptedAnswer,
      isEdited: isEdited ?? this.isEdited,
      upvoteCount: upvoteCount ?? this.upvoteCount,
      replyCount: replyCount, didIUpvote: didIUpvote ?? this.didIUpvote,
      createdAt: createdAt,
    );
  }
}

class ReviewQueueItem {
  final String id;
  final String userId;
  final String questionId;
  final String? examId;
  final String topicName;
  final String subtopicName;
  final String difficulty;
  final double easeFactor;
  final int intervalDays;
  final int repetitionCount;
  final String enrollmentReason;
  final int? initialConfidence;
  final DateTime? dueAt;
  final DateTime? lastReviewedAt;
  final int? lastGrade;
  final int totalReviews;
  final int correctReviews;
  final int lapseCount;
  final String status;

  ReviewQueueItem({
    required this.id,
    required this.userId,
    required this.questionId,
    this.examId,
    this.topicName = '',
    this.subtopicName = '',
    this.difficulty = '',
    this.easeFactor = 2.5,
    this.intervalDays = 1,
    this.repetitionCount = 0,
    this.enrollmentReason = 'manual',
    this.initialConfidence,
    this.dueAt,
    this.lastReviewedAt,
    this.lastGrade,
    this.totalReviews = 0,
    this.correctReviews = 0,
    this.lapseCount = 0,
    this.status = 'active',
  });

  factory ReviewQueueItem.fromJson(Map<String, dynamic> json) => ReviewQueueItem(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        userId: (json['user_id'] ?? '').toString(),
        questionId: (json['question_id'] ?? '').toString(),
        examId: json['exam_id']?.toString(),
        topicName: (json['topic_name'] ?? '').toString(),
        subtopicName: (json['subtopic_name'] ?? '').toString(),
        difficulty: (json['difficulty'] ?? '').toString(),
        easeFactor: (json['ease_factor'] is num) ? (json['ease_factor'] as num).toDouble() : 2.5,
        intervalDays: _i(json['interval_days'], fallback: 1),
        repetitionCount: _i(json['repetition_count']),
        enrollmentReason: (json['enrollment_reason'] ?? 'manual').toString(),
        initialConfidence: json['initial_confidence'] is num ? (json['initial_confidence'] as num).toInt() : null,
        dueAt: _d(json['due_at']),
        lastReviewedAt: _d(json['last_reviewed_at']),
        lastGrade: json['last_grade'] is num ? (json['last_grade'] as num).toInt() : null,
        totalReviews: _i(json['total_reviews']),
        correctReviews: _i(json['correct_reviews']),
        lapseCount: _i(json['lapse_count']),
        status: (json['status'] ?? 'active').toString(),
      );
}

class ReviewQueueStats {
  final int activeCount;
  final int masteredCount;
  final int pausedCount;
  final int dueToday;
  final int totalReviews;
  final int correctReviews;
  final int accuracyPct;

  ReviewQueueStats({
    this.activeCount = 0,
    this.masteredCount = 0,
    this.pausedCount = 0,
    this.dueToday = 0,
    this.totalReviews = 0,
    this.correctReviews = 0,
    this.accuracyPct = 0,
  });

  factory ReviewQueueStats.fromJson(Map<String, dynamic> json) => ReviewQueueStats(
        activeCount: _i(json['active_count']),
        masteredCount: _i(json['mastered_count']),
        pausedCount: _i(json['paused_count']),
        dueToday: _i(json['due_today']),
        totalReviews: _i(json['total_reviews']),
        correctReviews: _i(json['correct_reviews']),
        accuracyPct: _i(json['accuracy_pct']),
      );
}

class StudyPlan {
  final String id;
  final DateTime examDate;
  final int dailyTimeBudgetMinutes;
  final List<StudyPlanItem> items;
  final int totalDays;
  final int completedCount;
  final int pendingCount;
  final String status;

  StudyPlan({
    required this.id,
    required this.examDate,
    this.dailyTimeBudgetMinutes = 60,
    this.items = const [],
    this.totalDays = 0,
    this.completedCount = 0,
    this.pendingCount = 0,
    this.status = 'active',
  });

  factory StudyPlan.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List?)
            ?.map((e) => StudyPlanItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return StudyPlan(
      id: (json['_id'] ?? '').toString(),
      examDate: _d(json['exam_date']) ?? DateTime.now(),
      dailyTimeBudgetMinutes: _i(json['daily_time_budget_minutes'], fallback: 60),
      items: items,
      totalDays: _i(json['total_days']),
      completedCount: _i(json['completed_count']),
      pendingCount: _i(json['pending_count']),
      status: (json['status'] ?? 'active').toString(),
    );
  }
}

class StudyPlanItem {
  final String id;
  final int dayOffset;
  final DateTime? date;
  final String kind;
  final String title;
  final String description;
  final String topic;
  final int estimatedMinutes;
  final String status;

  StudyPlanItem({
    required this.id,
    required this.dayOffset,
    this.date,
    required this.kind,
    required this.title,
    this.description = '',
    this.topic = '',
    this.estimatedMinutes = 30,
    this.status = 'pending',
  });

  factory StudyPlanItem.fromJson(Map<String, dynamic> json) => StudyPlanItem(
        id: (json['_id'] ?? '').toString(),
        dayOffset: _i(json['day_offset']),
        date: _d(json['date']),
        kind: (json['kind'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        topic: (json['topic'] ?? '').toString(),
        estimatedMinutes: _i(json['estimated_minutes'], fallback: 30),
        status: (json['status'] ?? 'pending').toString(),
      );
}

class ScheduledSession {
  final String id;
  final String kind;
  final String topic;
  final List<int> daysOfWeek;
  final String timeOfDay;
  final String timezone;
  final DateTime? nextRunAt;
  final DateTime? lastRunAt;
  final int totalRuns;
  final int estimatedMinutes;
  final bool notifyViaPush;
  final String status;

  ScheduledSession({
    required this.id,
    required this.kind,
    this.topic = '',
    this.daysOfWeek = const [],
    this.timeOfDay = '19:00',
    this.timezone = 'Asia/Kolkata',
    this.nextRunAt,
    this.lastRunAt,
    this.totalRuns = 0,
    this.estimatedMinutes = 15,
    this.notifyViaPush = true,
    this.status = 'active',
  });

  factory ScheduledSession.fromJson(Map<String, dynamic> json) {
    final dows = (json['days_of_week'] as List?)
            ?.map((e) => e is num ? e.toInt() : int.tryParse(e.toString()) ?? 0)
            .toList() ??
        [];
    return ScheduledSession(
      id: (json['_id'] ?? '').toString(),
      kind: (json['kind'] ?? 'topic_deep_dive').toString(),
      topic: (json['topic'] ?? '').toString(),
      daysOfWeek: dows,
      timeOfDay: (json['time_of_day'] ?? '19:00').toString(),
      timezone: (json['timezone'] ?? 'Asia/Kolkata').toString(),
      nextRunAt: _d(json['next_run_at']),
      lastRunAt: _d(json['last_run_at']),
      totalRuns: _i(json['total_runs']),
      estimatedMinutes: _i(json['estimated_minutes'], fallback: 15),
      notifyViaPush: json['notify_via_push'] != false,
      status: (json['status'] ?? 'active').toString(),
    );
  }
}

class TopicTrendPoint {
  final String day;
  final String topic;
  final int attempted;
  final int correct;
  final double accuracyPct;

  TopicTrendPoint({
    required this.day,
    this.topic = '',
    this.attempted = 0,
    this.correct = 0,
    this.accuracyPct = 0,
  });

  factory TopicTrendPoint.fromJson(Map<String, dynamic> json) => TopicTrendPoint(
        day: (json['day'] ?? '').toString(),
        topic: (json['topic'] ?? '').toString(),
        attempted: _i(json['attempted']),
        correct: _i(json['correct']),
        accuracyPct: (json['accuracy_pct'] is num) ? (json['accuracy_pct'] as num).toDouble() : 0,
      );
}

class CalibrationBucket {
  final int bucket;
  final int attempted;
  final int correct;
  final double avgConfidence;
  final double accuracyPct;

  CalibrationBucket({
    required this.bucket,
    this.attempted = 0,
    this.correct = 0,
    this.avgConfidence = 0,
    this.accuracyPct = 0,
  });

  factory CalibrationBucket.fromJson(Map<String, dynamic> json) => CalibrationBucket(
        bucket: _i(json['bucket']),
        attempted: _i(json['attempted']),
        correct: _i(json['correct']),
        avgConfidence: (json['avg_confidence'] is num) ? (json['avg_confidence'] as num).toDouble() : 0,
        accuracyPct: (json['accuracy_pct'] is num) ? (json['accuracy_pct'] as num).toDouble() : 0,
      );
}

class TopicStrength {
  final String topic;
  final int attempted;
  final int correct;
  final double accuracyPct;

  TopicStrength({required this.topic, this.attempted = 0, this.correct = 0, this.accuracyPct = 0});

  factory TopicStrength.fromJson(Map<String, dynamic> json) => TopicStrength(
        topic: (json['topic'] ?? '').toString(),
        attempted: _i(json['attempted']),
        correct: _i(json['correct']),
        accuracyPct: (json['accuracy_pct'] is num) ? (json['accuracy_pct'] as num).toDouble() : 0,
      );
}

// ── helpers ──
int _i(dynamic v, {int fallback = 0}) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

DateTime? _d(dynamic v) {
  if (v == null) return null;
  try { return DateTime.parse(v.toString()); } catch (_) { return null; }
}
