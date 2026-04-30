import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// RecentNotesService — tracks the last N notes the user opened so we
/// can surface them as a "Continue reading" rail at the top of the
/// notes landing.
///
/// Stored client-side in SharedPreferences (the backend already has
/// this in the form of pdf-progress, but a local cache means the home
/// screen renders instantly on cold-boot).
///
/// Each entry carries enough metadata to deep-link straight back into
/// the PDF reader without an intermediate screen — that's the whole
/// point of this service: shorten the four-level browse flow
/// (category → subcategory → topic → content → reader) down to a
/// single tap on a recent.
class RecentNotesService {
  RecentNotesService._();
  static final instance = RecentNotesService._();

  static const _kKey = 'recent_notes_v1';
  static const int _maxEntries = 12;

  /// Record a note as just-opened. Idempotent: if the note is already
  /// in the list, it's promoted to position 0 with the new lastSeenAt.
  Future<void> recordOpen(RecentNoteEntry entry) async {
    if (entry.titleId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = await _load();
    list.removeWhere((e) => e.titleId == entry.titleId);
    list.insert(0, entry.copyWith(lastSeenAt: DateTime.now()));
    if (list.length > _maxEntries) list.removeRange(_maxEntries, list.length);
    await prefs.setString(
      _kKey,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  /// Update progress on an entry (last page seen, completion).
  /// No-op if the entry isn't in the list.
  Future<void> updateProgress(
    String titleId, {
    int? lastPage,
    bool? isCompleted,
  }) async {
    if (titleId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = await _load();
    final idx = list.indexWhere((e) => e.titleId == titleId);
    if (idx < 0) return;
    list[idx] = list[idx].copyWith(
      lastPage: lastPage ?? list[idx].lastPage,
      isCompleted: isCompleted ?? list[idx].isCompleted,
      lastSeenAt: DateTime.now(),
    );
    await prefs.setString(
      _kKey,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  /// All recents, newest first. Limited to [_maxEntries].
  Future<List<RecentNoteEntry>> all() async => await _load();

  /// Top [n] recents.
  Future<List<RecentNoteEntry>> top(int n) async {
    final all = await _load();
    return all.take(n).toList();
  }

  /// Wipe all recents — call from "Reset progress".
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kKey);
  }

  Future<List<RecentNoteEntry>> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => RecentNoteEntry.fromJson(e as Map<String, dynamic>))
          .toList(growable: true);
    } catch (e) {
      debugPrint('RecentNotesService load failed: $e');
      return [];
    }
  }
}

/// A single entry in the recents list.
class RecentNoteEntry {
  RecentNoteEntry({
    required this.titleId,
    required this.title,
    required this.contentUrl,
    this.topicId,
    this.topicName,
    this.subcategoryId,
    this.subcategoryName,
    this.categoryId,
    this.categoryName,
    this.lastPage,
    this.isCompleted = false,
    this.lastSeenAt,
  });

  /// The unique ID of the note (`titleId` everywhere in the legacy
  /// codebase) — primary key for SharedPreferences.
  final String titleId;

  /// Display name shown on the recents tile.
  final String title;

  /// PDF URL — pushed straight into [Routes.notesReadView] arguments.
  final String contentUrl;

  final String? topicId;
  final String? topicName;
  final String? subcategoryId;
  final String? subcategoryName;
  final String? categoryId;
  final String? categoryName;

  /// Last page the user was on. Drives the "Page 12 of 48" subtitle.
  final int? lastPage;
  final bool isCompleted;
  final DateTime? lastSeenAt;

  RecentNoteEntry copyWith({
    int? lastPage,
    bool? isCompleted,
    DateTime? lastSeenAt,
  }) =>
      RecentNoteEntry(
        titleId: titleId,
        title: title,
        contentUrl: contentUrl,
        topicId: topicId,
        topicName: topicName,
        subcategoryId: subcategoryId,
        subcategoryName: subcategoryName,
        categoryId: categoryId,
        categoryName: categoryName,
        lastPage: lastPage ?? this.lastPage,
        isCompleted: isCompleted ?? this.isCompleted,
        lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      );

  Map<String, dynamic> toJson() => {
        'titleId': titleId,
        'title': title,
        'contentUrl': contentUrl,
        'topicId': topicId,
        'topicName': topicName,
        'subcategoryId': subcategoryId,
        'subcategoryName': subcategoryName,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'lastPage': lastPage,
        'isCompleted': isCompleted,
        'lastSeenAt': lastSeenAt?.toIso8601String(),
      };

  factory RecentNoteEntry.fromJson(Map<String, dynamic> json) =>
      RecentNoteEntry(
        titleId: (json['titleId'] as String?) ?? '',
        title: (json['title'] as String?) ?? '',
        contentUrl: (json['contentUrl'] as String?) ?? '',
        topicId: json['topicId'] as String?,
        topicName: json['topicName'] as String?,
        subcategoryId: json['subcategoryId'] as String?,
        subcategoryName: json['subcategoryName'] as String?,
        categoryId: json['categoryId'] as String?,
        categoryName: json['categoryName'] as String?,
        lastPage: json['lastPage'] as int?,
        isCompleted: (json['isCompleted'] as bool?) ?? false,
        lastSeenAt: json['lastSeenAt'] == null
            ? null
            : DateTime.tryParse(json['lastSeenAt'] as String),
      );
}
