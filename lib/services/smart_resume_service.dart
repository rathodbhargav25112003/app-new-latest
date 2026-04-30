import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SmartResumeService — tracks the user's most-recent in-progress
/// "thing" so the home screen can surface a single one-tap "pick up
/// where you left off" banner.
///
/// Replaces the cold-boot flow of:
///   • open app → look at home → notice no in-progress callout →
///     navigate to mock-exam list / videos / notes / etc → find
///     where they were → tap to resume
///
/// With:
///   • open app → see "Continue mock test · Q12 of 100" banner →
///     1 tap.
///
/// **Design:** four channels (mock exam, custom test, video, note),
/// each with the latest entry. The home banner picks the most recent
/// across all four. Channels are kept separate so we can also surface
/// per-section "Continue" prompts elsewhere (the Notes browse home
/// already has its own recents rail; this is for the global home).
///
/// Fully client-side — no backend round-trip needed for the banner to
/// render on cold boot.
class SmartResumeService {
  SmartResumeService._();
  static final instance = SmartResumeService._();

  static const _kKey = 'smart_resume_v1';

  // ── Recording (call from each module's screens) ──────────────────

  Future<void> recordMockExam({
    required String userExamId,
    required String examName,
    required int currentQuestion,
    required int totalQuestions,
    int? remainingSeconds,
    String? examId,
  }) =>
      _record(
        ResumeKind.mockExam,
        ResumeEntry(
          kind: ResumeKind.mockExam,
          primaryId: userExamId,
          title: examName,
          subtitle: 'Q$currentQuestion of $totalQuestions',
          progress: totalQuestions == 0 ? 0 : currentQuestion / totalQuestions,
          updatedAt: DateTime.now(),
          extras: {
            'examId': examId,
            'remainingSeconds': remainingSeconds,
            'currentQuestion': currentQuestion,
            'totalQuestions': totalQuestions,
          },
        ),
      );

  Future<void> recordCustomTest({
    required String userExamId,
    required String testName,
    required int currentQuestion,
    required int totalQuestions,
    String? examId,
  }) =>
      _record(
        ResumeKind.customTest,
        ResumeEntry(
          kind: ResumeKind.customTest,
          primaryId: userExamId,
          title: testName,
          subtitle: 'Q$currentQuestion of $totalQuestions',
          progress: totalQuestions == 0 ? 0 : currentQuestion / totalQuestions,
          updatedAt: DateTime.now(),
          extras: {
            'examId': examId,
            'currentQuestion': currentQuestion,
            'totalQuestions': totalQuestions,
          },
        ),
      );

  Future<void> recordVideo({
    required String videoId,
    required String title,
    required int positionSeconds,
    required int durationSeconds,
    String? topicName,
    String? subjectName,
  }) =>
      _record(
        ResumeKind.video,
        ResumeEntry(
          kind: ResumeKind.video,
          primaryId: videoId,
          title: title,
          subtitle: topicName ?? subjectName ?? 'Lecture',
          progress: durationSeconds == 0
              ? 0
              : positionSeconds / durationSeconds,
          updatedAt: DateTime.now(),
          extras: {
            'positionSeconds': positionSeconds,
            'durationSeconds': durationSeconds,
            'topicName': topicName,
            'subjectName': subjectName,
          },
        ),
      );

  Future<void> recordNote({
    required String titleId,
    required String title,
    required int currentPage,
    required int totalPages,
    String? topicName,
    String? subjectName,
    String? contentUrl,
  }) =>
      _record(
        ResumeKind.note,
        ResumeEntry(
          kind: ResumeKind.note,
          primaryId: titleId,
          title: title,
          subtitle: 'Page $currentPage of $totalPages',
          progress: totalPages == 0 ? 0 : currentPage / totalPages,
          updatedAt: DateTime.now(),
          extras: {
            'currentPage': currentPage,
            'totalPages': totalPages,
            'topicName': topicName,
            'subjectName': subjectName,
            'contentUrl': contentUrl,
          },
        ),
      );

  /// Mark a channel as "done" — call when the user finishes / submits.
  /// Removes the entry so it doesn't reappear in the banner.
  Future<void> clear(ResumeKind kind) async {
    final all = await _loadAll();
    all.remove(kind);
    await _saveAll(all);
  }

  /// Wipe everything — hooks into "Reset progress".
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kKey);
  }

  // ── Reading ──────────────────────────────────────────────────────

  /// Returns the single most-recent entry across all channels, or null
  /// if nothing's in progress. The banner consumes this directly.
  Future<ResumeEntry?> latest() async {
    final all = await _loadAll();
    if (all.isEmpty) return null;
    final entries = all.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return entries.first;
  }

  /// All entries, newest first. Useful for a richer "pick from N
  /// in-progress items" sheet if we ever need it.
  Future<List<ResumeEntry>> all() async {
    final all = await _loadAll();
    final entries = all.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return entries;
  }

  // ── Internals ────────────────────────────────────────────────────

  Future<void> _record(ResumeKind kind, ResumeEntry entry) async {
    final all = await _loadAll();
    all[kind] = entry;
    await _saveAll(all);
  }

  Future<Map<ResumeKind, ResumeEntry>> _loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kKey);
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final out = <ResumeKind, ResumeEntry>{};
      decoded.forEach((k, v) {
        final kind = ResumeKind.values.firstWhere(
          (e) => e.name == k,
          orElse: () => ResumeKind.note,
        );
        try {
          out[kind] = ResumeEntry.fromJson(v as Map<String, dynamic>);
        } catch (_) {/* drop bad entry */}
      });
      return out;
    } catch (e) {
      debugPrint('SmartResumeService load failed: $e');
      return {};
    }
  }

  Future<void> _saveAll(Map<ResumeKind, ResumeEntry> all) async {
    final prefs = await SharedPreferences.getInstance();
    final json = <String, dynamic>{};
    all.forEach((kind, entry) {
      json[kind.name] = entry.toJson();
    });
    await prefs.setString(_kKey, jsonEncode(json));
  }
}

/// One in-progress entry across any module.
class ResumeEntry {
  ResumeEntry({
    required this.kind,
    required this.primaryId,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.updatedAt,
    this.extras = const {},
  });

  final ResumeKind kind;

  /// User-facing-stable identifier — the userExamId for tests, titleId
  /// for notes, videoId for videos. The screen that consumes this
  /// uses it to deep-link.
  final String primaryId;

  final String title;
  final String subtitle;

  /// 0..1 ratio for the progress bar inside the banner.
  final double progress;

  final DateTime updatedAt;

  /// Anything the consumer needs to push into the deep-link route.
  final Map<String, dynamic> extras;

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'primaryId': primaryId,
        'title': title,
        'subtitle': subtitle,
        'progress': progress,
        'updatedAt': updatedAt.toIso8601String(),
        'extras': extras,
      };

  factory ResumeEntry.fromJson(Map<String, dynamic> json) => ResumeEntry(
        kind: ResumeKind.values.firstWhere(
          (e) => e.name == json['kind'],
          orElse: () => ResumeKind.note,
        ),
        primaryId: (json['primaryId'] as String?) ?? '',
        title: (json['title'] as String?) ?? '',
        subtitle: (json['subtitle'] as String?) ?? '',
        progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
        extras: Map<String, dynamic>.from(
            json['extras'] as Map? ?? const {}),
      );
}

enum ResumeKind { mockExam, customTest, video, note }

extension ResumeKindLabels on ResumeKind {
  String get label {
    switch (this) {
      case ResumeKind.mockExam:
        return 'Mock test';
      case ResumeKind.customTest:
        return 'Custom test';
      case ResumeKind.video:
        return 'Video';
      case ResumeKind.note:
        return 'Note';
    }
  }
}
