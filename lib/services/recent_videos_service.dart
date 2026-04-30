import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// RecentVideosService — tracks the last N video lectures the user
/// opened so the new VideoBrowseScreen can surface them as a
/// "Continue watching" rail at the top.
///
/// Mirrors [RecentNotesService] for the videos module. SharedPreferences-
/// backed, idempotent, bounded at 12 entries.
///
/// Each entry carries enough metadata to deep-link straight back into
/// the video player without an intermediate screen — the whole point
/// of this service is to shorten the four-level browse flow
/// (subject → subcategory → topic → lecture → player) to a single tap
/// on a recent.
class RecentVideosService {
  RecentVideosService._();
  static final instance = RecentVideosService._();

  static const _kKey = 'recent_videos_v1';
  static const int _maxEntries = 12;

  Future<void> recordOpen(RecentVideoEntry entry) async {
    if (entry.videoId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = await _load();
    list.removeWhere((e) => e.videoId == entry.videoId);
    list.insert(0, entry.copyWith(lastSeenAt: DateTime.now()));
    if (list.length > _maxEntries) list.removeRange(_maxEntries, list.length);
    await prefs.setString(
      _kKey,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  /// Update progress on an entry (last position, completion).
  /// No-op if not present.
  Future<void> updateProgress(
    String videoId, {
    int? positionSeconds,
    int? durationSeconds,
    bool? isCompleted,
  }) async {
    if (videoId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = await _load();
    final idx = list.indexWhere((e) => e.videoId == videoId);
    if (idx < 0) return;
    list[idx] = list[idx].copyWith(
      positionSeconds: positionSeconds ?? list[idx].positionSeconds,
      durationSeconds: durationSeconds ?? list[idx].durationSeconds,
      isCompleted: isCompleted ?? list[idx].isCompleted,
      lastSeenAt: DateTime.now(),
    );
    await prefs.setString(
      _kKey,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<RecentVideoEntry>> all() async => await _load();

  Future<List<RecentVideoEntry>> top(int n) async {
    final all = await _load();
    return all.take(n).toList();
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kKey);
  }

  Future<List<RecentVideoEntry>> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => RecentVideoEntry.fromJson(e as Map<String, dynamic>))
          .toList(growable: true);
    } catch (e) {
      debugPrint('RecentVideosService load failed: $e');
      return [];
    }
  }
}

/// One entry in the recents list. Carries enough metadata for the
/// browse screen's "Continue watching" rail to render with a
/// thumbnail, title, position-bar, and timestamp.
class RecentVideoEntry {
  RecentVideoEntry({
    required this.videoId,
    required this.title,
    this.thumbnail,
    this.topicId,
    this.topicName,
    this.subcategoryId,
    this.subcategoryName,
    this.categoryId,
    this.categoryName,
    this.positionSeconds,
    this.durationSeconds,
    this.isCompleted = false,
    this.lastSeenAt,
  });

  /// Unique video ID — primary key + the value pushed into
  /// `Routes.videoPlayDetail` arguments['topicId'].
  final String videoId;
  final String title;
  final String? thumbnail;
  final String? topicId;
  final String? topicName;
  final String? subcategoryId;
  final String? subcategoryName;
  final String? categoryId;
  final String? categoryName;

  /// Resume position in seconds. Drives the rail's "12:34 / 45:00"
  /// subtitle and the LinearProgressIndicator.
  final int? positionSeconds;
  final int? durationSeconds;
  final bool isCompleted;
  final DateTime? lastSeenAt;

  double get progressRatio {
    final p = positionSeconds ?? 0;
    final d = durationSeconds ?? 0;
    if (d == 0) return 0;
    return (p / d).clamp(0.0, 1.0);
  }

  RecentVideoEntry copyWith({
    int? positionSeconds,
    int? durationSeconds,
    bool? isCompleted,
    DateTime? lastSeenAt,
  }) =>
      RecentVideoEntry(
        videoId: videoId,
        title: title,
        thumbnail: thumbnail,
        topicId: topicId,
        topicName: topicName,
        subcategoryId: subcategoryId,
        subcategoryName: subcategoryName,
        categoryId: categoryId,
        categoryName: categoryName,
        positionSeconds: positionSeconds ?? this.positionSeconds,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        isCompleted: isCompleted ?? this.isCompleted,
        lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      );

  Map<String, dynamic> toJson() => {
        'videoId': videoId,
        'title': title,
        'thumbnail': thumbnail,
        'topicId': topicId,
        'topicName': topicName,
        'subcategoryId': subcategoryId,
        'subcategoryName': subcategoryName,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'positionSeconds': positionSeconds,
        'durationSeconds': durationSeconds,
        'isCompleted': isCompleted,
        'lastSeenAt': lastSeenAt?.toIso8601String(),
      };

  factory RecentVideoEntry.fromJson(Map<String, dynamic> json) =>
      RecentVideoEntry(
        videoId: (json['videoId'] as String?) ?? '',
        title: (json['title'] as String?) ?? '',
        thumbnail: json['thumbnail'] as String?,
        topicId: json['topicId'] as String?,
        topicName: json['topicName'] as String?,
        subcategoryId: json['subcategoryId'] as String?,
        subcategoryName: json['subcategoryName'] as String?,
        categoryId: json['categoryId'] as String?,
        categoryName: json['categoryName'] as String?,
        positionSeconds: json['positionSeconds'] as int?,
        durationSeconds: json['durationSeconds'] as int?,
        isCompleted: (json['isCompleted'] as bool?) ?? false,
        lastSeenAt: json['lastSeenAt'] == null
            ? null
            : DateTime.tryParse(json['lastSeenAt'] as String),
      );
}
