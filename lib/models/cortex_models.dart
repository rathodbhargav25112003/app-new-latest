// Cortex AI v2/v3 — JSON models
//
// Plain Dart classes (no @JsonSerializable codegen) so the dev can drop them
// in without running `flutter pub run build_runner`. Match the server's
// /api/cortex/* response shapes exactly. Forgiving fromJson — null/missing
// fields default to safe values so partial responses don't crash.

class CortexChat {
  final String id;
  final String userId;
  final String title;
  final String contextKind; // 'general' | 'mcq' | 'mistake_debrief' | 'roleplay' | 'osce_viva' | 'topic_deep_dive'
  final String? contextQuestionId;
  final String? contextExamId;
  final String? contextUserExamId;
  final String? contextTopicName;
  final String? contextSubtopicName;
  final String? roleplayRole;
  final String? roleplayScenario;
  final String? roleplayDifficulty;
  final int totalMessages;
  final int totalInputTokens;
  final int totalOutputTokens;
  final DateTime? lastActivityAt;
  final bool pinned;
  final bool archived;
  final DateTime? createdAt;

  CortexChat({
    required this.id,
    required this.userId,
    required this.title,
    required this.contextKind,
    this.contextQuestionId,
    this.contextExamId,
    this.contextUserExamId,
    this.contextTopicName,
    this.contextSubtopicName,
    this.roleplayRole,
    this.roleplayScenario,
    this.roleplayDifficulty,
    this.totalMessages = 0,
    this.totalInputTokens = 0,
    this.totalOutputTokens = 0,
    this.lastActivityAt,
    this.pinned = false,
    this.archived = false,
    this.createdAt,
  });

  factory CortexChat.fromJson(Map<String, dynamic> json) {
    return CortexChat(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      title: (json['title'] ?? 'New chat').toString(),
      contextKind: (json['context_kind'] ?? 'general').toString(),
      contextQuestionId: json['context_question_id']?.toString(),
      contextExamId: json['context_exam_id']?.toString(),
      contextUserExamId: json['context_user_exam_id']?.toString(),
      contextTopicName: json['context_topic_name']?.toString(),
      contextSubtopicName: json['context_subtopic_name']?.toString(),
      roleplayRole: json['roleplay_role']?.toString(),
      roleplayScenario: json['roleplay_scenario']?.toString(),
      roleplayDifficulty: json['roleplay_difficulty']?.toString(),
      totalMessages: (json['total_messages'] ?? 0) is int ? (json['total_messages'] ?? 0) : int.tryParse(json['total_messages'].toString()) ?? 0,
      totalInputTokens: (json['total_input_tokens'] ?? 0) is int ? (json['total_input_tokens'] ?? 0) : int.tryParse(json['total_input_tokens'].toString()) ?? 0,
      totalOutputTokens: (json['total_output_tokens'] ?? 0) is int ? (json['total_output_tokens'] ?? 0) : int.tryParse(json['total_output_tokens'].toString()) ?? 0,
      lastActivityAt: _parseDate(json['last_activity_at']),
      pinned: json['pinned'] == true,
      archived: json['archived'] == true,
      createdAt: _parseDate(json['created_at']),
    );
  }
}

class CortexMessage {
  final String id;
  final String chatId;
  final String userId;
  final String role; // 'user' | 'assistant' | 'system'
  final String content;
  final List<String> images;
  final String? attachedQuestionId;
  final String? model;
  final int inputTokens;
  final int outputTokens;
  final String? finishReason;
  final String? error;
  final int latencyMs;
  final int? userRating;
  final bool savedSnippet;
  final String? snippetNote;
  final DateTime? snippetSavedAt;
  final List<String> suggestedFollowups;
  final String? mermaidSource;
  final int generatedFlashcardsCount;
  final DateTime? createdAt;

  CortexMessage({
    required this.id,
    required this.chatId,
    required this.userId,
    required this.role,
    required this.content,
    this.images = const [],
    this.attachedQuestionId,
    this.model,
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.finishReason,
    this.error,
    this.latencyMs = 0,
    this.userRating,
    this.savedSnippet = false,
    this.snippetNote,
    this.snippetSavedAt,
    this.suggestedFollowups = const [],
    this.mermaidSource,
    this.generatedFlashcardsCount = 0,
    this.createdAt,
  });

  factory CortexMessage.fromJson(Map<String, dynamic> json) {
    return CortexMessage(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      chatId: (json['chat_id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      role: (json['role'] ?? 'assistant').toString(),
      content: (json['content'] ?? '').toString(),
      images: _stringList(json['images']),
      attachedQuestionId: json['attached_question_id']?.toString(),
      model: json['model']?.toString(),
      inputTokens: _toInt(json['input_tokens']),
      outputTokens: _toInt(json['output_tokens']),
      finishReason: json['finish_reason']?.toString(),
      error: json['error']?.toString(),
      latencyMs: _toInt(json['latency_ms']),
      userRating: json['user_rating'] is num ? (json['user_rating'] as num).toInt() : null,
      savedSnippet: json['saved_snippet'] == true,
      snippetNote: json['snippet_note']?.toString(),
      snippetSavedAt: _parseDate(json['snippet_saved_at']),
      suggestedFollowups: _stringList(json['suggested_followups']),
      mermaidSource: json['mermaid_source']?.toString(),
      generatedFlashcardsCount: _toInt(json['generated_flashcards_count']),
      createdAt: _parseDate(json['created_at']),
    );
  }

  // Optimistic copy for streaming UI — appends streamed text to content.
  CortexMessage withAppendedText(String delta) {
    return CortexMessage(
      id: id, chatId: chatId, userId: userId, role: role,
      content: content + delta,
      images: images, attachedQuestionId: attachedQuestionId, model: model,
      inputTokens: inputTokens, outputTokens: outputTokens,
      finishReason: finishReason, error: error, latencyMs: latencyMs,
      userRating: userRating, savedSnippet: savedSnippet,
      snippetNote: snippetNote, snippetSavedAt: snippetSavedAt,
      suggestedFollowups: suggestedFollowups, mermaidSource: mermaidSource,
      generatedFlashcardsCount: generatedFlashcardsCount, createdAt: createdAt,
    );
  }
}

class CortexUsage {
  final int used;
  final int cap;
  final int remaining;
  final int inputTokens;
  final int outputTokens;
  final Map<String, int> featureUsage;

  CortexUsage({
    required this.used,
    required this.cap,
    required this.remaining,
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.featureUsage = const {},
  });

  factory CortexUsage.fromJson(Map<String, dynamic> json) {
    final fu = json['feature_usage'];
    final featureMap = <String, int>{};
    if (fu is Map) {
      fu.forEach((k, v) {
        if (v is num) featureMap[k.toString()] = v.toInt();
      });
    }
    return CortexUsage(
      used: _toInt(json['used']),
      cap: _toInt(json['cap'], fallback: 100),
      remaining: _toInt(json['remaining']),
      inputTokens: _toInt(json['input_tokens']),
      outputTokens: _toInt(json['output_tokens']),
      featureUsage: featureMap,
    );
  }

  factory CortexUsage.empty() => CortexUsage(used: 0, cap: 100, remaining: 100);
}

class CortexMemory {
  final List<CortexWeakTopic> weakTopics;
  final CortexPreferences preferences;
  final String notes;
  final int totalChats;
  final int totalMessages;
  final int totalDebriefs;
  final int totalFlashcardsGenerated;

  CortexMemory({
    this.weakTopics = const [],
    required this.preferences,
    this.notes = '',
    this.totalChats = 0,
    this.totalMessages = 0,
    this.totalDebriefs = 0,
    this.totalFlashcardsGenerated = 0,
  });

  factory CortexMemory.fromJson(Map<String, dynamic> json) {
    final wt = json['weak_topics'];
    final List<CortexWeakTopic> topics = wt is List
        ? wt.map((e) => CortexWeakTopic.fromJson(e as Map<String, dynamic>)).toList()
        : <CortexWeakTopic>[];
    return CortexMemory(
      weakTopics: topics,
      preferences: CortexPreferences.fromJson((json['preferences'] as Map<String, dynamic>?) ?? const {}),
      notes: (json['notes'] ?? '').toString(),
      totalChats: _toInt(json['total_chats']),
      totalMessages: _toInt(json['total_messages']),
      totalDebriefs: _toInt(json['total_debriefs']),
      totalFlashcardsGenerated: _toInt(json['total_flashcards_generated']),
    );
  }

  factory CortexMemory.empty() =>
      CortexMemory(weakTopics: const [], preferences: CortexPreferences.defaults());
}

class CortexWeakTopic {
  final String topic;
  final String subtopic;
  final int mistakeCount;
  final DateTime? lastMistakeAt;

  CortexWeakTopic({
    required this.topic,
    this.subtopic = '',
    this.mistakeCount = 1,
    this.lastMistakeAt,
  });

  factory CortexWeakTopic.fromJson(Map<String, dynamic> json) => CortexWeakTopic(
        topic: (json['topic'] ?? '').toString(),
        subtopic: (json['subtopic'] ?? '').toString(),
        mistakeCount: _toInt(json['mistake_count'], fallback: 1),
        lastMistakeAt: _parseDate(json['last_mistake_at']),
      );
}

class CortexPreferences {
  final String tone; // 'concise' | 'detailed' | 'mnemonic-heavy'
  final bool showReferenceSection;
  final bool showPearls;
  final bool showExaminerView;

  CortexPreferences({
    this.tone = 'detailed',
    this.showReferenceSection = true,
    this.showPearls = true,
    this.showExaminerView = true,
  });

  factory CortexPreferences.defaults() => CortexPreferences();

  factory CortexPreferences.fromJson(Map<String, dynamic> json) => CortexPreferences(
        tone: (json['tone'] ?? 'detailed').toString(),
        showReferenceSection: json['show_reference_section'] != false,
        showPearls: json['show_pearls'] != false,
        showExaminerView: json['show_examiner_view'] != false,
      );

  Map<String, dynamic> toJson() => {
        'tone': tone,
        'show_reference_section': showReferenceSection,
        'show_pearls': showPearls,
        'show_examiner_view': showExaminerView,
      };
}

class CortexQuickPrompts {
  final List<String> personal;
  final List<String> suggested;
  final List<CortexMode> modes;

  CortexQuickPrompts({
    this.personal = const [],
    this.suggested = const [],
    this.modes = const [],
  });

  factory CortexQuickPrompts.fromJson(Map<String, dynamic> json) {
    final modes = (json['modes'] as List?)
            ?.map((e) => CortexMode.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return CortexQuickPrompts(
      personal: _stringList(json['personal']),
      suggested: _stringList(json['suggested']),
      modes: modes,
    );
  }
}

class CortexMode {
  final String id;
  final String label;
  final String endpoint;

  CortexMode({required this.id, required this.label, required this.endpoint});

  factory CortexMode.fromJson(Map<String, dynamic> json) => CortexMode(
        id: (json['id'] ?? '').toString(),
        label: (json['label'] ?? '').toString(),
        endpoint: (json['endpoint'] ?? '').toString(),
      );
}

class CortexRelatedMcq {
  final String id;
  final int questionNumber;
  final String stemPreview;
  final String topic;
  final String subtopic;
  final String examId;
  final String examName;

  CortexRelatedMcq({
    required this.id,
    this.questionNumber = 0,
    this.stemPreview = '',
    this.topic = '',
    this.subtopic = '',
    this.examId = '',
    this.examName = '',
  });

  factory CortexRelatedMcq.fromJson(Map<String, dynamic> json) => CortexRelatedMcq(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        questionNumber: _toInt(json['question_number']),
        stemPreview: (json['stem_preview'] ?? '').toString(),
        topic: (json['topic'] ?? '').toString(),
        subtopic: (json['subtopic'] ?? '').toString(),
        examId: (json['exam_id'] ?? '').toString(),
        examName: (json['exam_name'] ?? '').toString(),
      );
}

class CortexFlashcard {
  final String question;
  final String answer;
  final List<String> tags;
  final String difficulty;
  final String topic;

  CortexFlashcard({
    required this.question,
    required this.answer,
    this.tags = const [],
    this.difficulty = 'medium',
    this.topic = '',
  });

  factory CortexFlashcard.fromJson(Map<String, dynamic> json) => CortexFlashcard(
        question: (json['question'] ?? '').toString(),
        answer: (json['answer'] ?? '').toString(),
        tags: _stringList(json['tags']),
        difficulty: (json['difficulty'] ?? 'medium').toString(),
        topic: (json['topic'] ?? '').toString(),
      );
}

// ── Helpers ──────────────────────────────────────────────────────────────

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  try {
    return DateTime.parse(v.toString());
  } catch (_) {
    return null;
  }
}

int _toInt(dynamic v, {int fallback = 0}) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

List<String> _stringList(dynamic v) {
  if (v is List) {
    return v.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
  }
  return const [];
}
