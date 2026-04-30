import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shusruta_lms/helpers/dbhelper.dart';
import 'package:shusruta_lms/models/video_offline_data_model.dart';
import 'package:shusruta_lms/services/offline_encryptor.dart';
import 'package:shusruta_lms/services/secure_keys.dart';

/// One-at-a-time download queue with:
///  - HTTP Range resume
///  - AES-256-GCM encryption at rest (chunked, memory-safe for large files)
///  - WiFi-only toggle with automatic pause/resume on connectivity changes
///  - Retry (up to 3) on transient network errors
///  - Progress throttling (debounced 500ms) so UI never repaints faster than 2 fps
///  - Proper cancellation that tears down the HTTP socket cleanly (iOS stalls
///    if streams are abandoned without explicit close).
///
/// Public API is intentionally preserved for callers in video_chapter_detail.dart,
/// video_player_detail.dart, download_manager_sheet.dart, and main.dart.
class DownloadService {
  DownloadService._();
  static final DownloadService instance = DownloadService._();

  // ── Public surface (unchanged from prior version) ───────────────────────
  bool wifiOnly = false;

  // NOTE: The single-callback fields below are kept for backward-compat with
  // the download_manager_sheet widget that was written before we needed
  // multi-listener fan-out. New code should listen to [updates] / [completed]
  // / [failed] / [queueChanges] streams instead — those support any number of
  // subscribers without one of them clobbering the others.
  DownloadCallback? onTaskUpdated;
  DownloadCallback? onTaskCompleted;
  DownloadCallback? onTaskFailed;
  VoidCallback? onQueueChanged;

  // Broadcast streams — fan-out to store + UI + anywhere else simultaneously.
  // Using broadcast so listeners can come and go (screens pushed/popped)
  // without the streams ever closing. We never close them for the life of
  // the app (singleton service).
  final StreamController<DownloadTask> _updatesCtrl =
      StreamController<DownloadTask>.broadcast();
  final StreamController<DownloadTask> _completedCtrl =
      StreamController<DownloadTask>.broadcast();
  final StreamController<DownloadTask> _failedCtrl =
      StreamController<DownloadTask>.broadcast();
  final StreamController<void> _queueCtrl =
      StreamController<void>.broadcast();

  Stream<DownloadTask> get updates => _updatesCtrl.stream;
  Stream<DownloadTask> get completed => _completedCtrl.stream;
  Stream<DownloadTask> get failed => _failedCtrl.stream;
  Stream<void> get queueChanges => _queueCtrl.stream;

  void _emitUpdate(DownloadTask t) {
    onTaskUpdated?.call(t);
    if (!_updatesCtrl.isClosed) _updatesCtrl.add(t);
    _pushProgressNotification(t);
  }

  void _emitCompleted(DownloadTask t) {
    onTaskCompleted?.call(t);
    if (!_completedCtrl.isClosed) _completedCtrl.add(t);
    // A completion is also an update — keep simple listeners that only watch
    // `updates` in sync without requiring them to also subscribe `completed`.
    if (!_updatesCtrl.isClosed) _updatesCtrl.add(t);
    _pushCompletedNotification(t);
  }

  void _emitFailed(DownloadTask t) {
    onTaskFailed?.call(t);
    if (!_failedCtrl.isClosed) _failedCtrl.add(t);
    if (!_updatesCtrl.isClosed) _updatesCtrl.add(t);
    _pushFailedNotification(t);
  }

  void _emitQueueChanged() {
    // NOTE: do NOT call _emitQueueChanged() here — it would recurse forever
    // and every enqueue/cancel/complete would crash the app with a
    // StackOverflowError. Emit to the legacy callback and the broadcast
    // stream exactly once each.
    onQueueChanged?.call();
    if (!_queueCtrl.isClosed) _queueCtrl.add(null);
  }

  // ── Internal state ──────────────────────────────────────────────────────
  static const String _wifiOnlyKey = 'download_wifi_only';
  static const int _maxNetworkRetries = 3;
  // iOS cellular and Wi-Fi-with-weak-signal commonly have multi-second idle
  // gaps (power-saving mode puts the radio to sleep between chunks). 30s
  // was triggering spurious idle timeouts on iOS that Android never saw
  // because Android's NetworkPolicyManager keeps the socket warmer. Use a
  // longer budget on iOS and keep Android tight to catch real stalls fast.
  static final Duration _idleTimeout =
      Platform.isIOS ? const Duration(seconds: 60) : const Duration(seconds: 30);

  final Queue<DownloadTask> _queue = Queue<DownloadTask>();
  final Map<String, DownloadTask> _allTasks = {};
  DownloadTask? _activeTask;
  bool _isProcessing = false;

  // Live download handles — kept so cancel() can tear them down promptly.
  HttpClient? _activeClient;
  HttpClientRequest? _activeRequest;
  StreamSubscription<List<int>>? _activeSub;
  IOSink? _activeSink;
  // The Completer that _downloadOnce is awaiting. Exposed so _tearDownActive
  // can unblock it synchronously on cancel/pause — otherwise cancelling the
  // subscription prevents onDone/onError from firing, which would leave
  // _runNext hung forever on `await done.future`.
  Completer<void>? _activeDoneCompleter;

  // Cooperative cancellation — checked between chunks / retries.
  bool _cancelRequested = false;

  StreamSubscription<List<ConnectivityResult>>? _connSub;

  // ── Notifications ───────────────────────────────────────────────────────
  // The plugin itself is already `.initialize()`d from phone_app.dart at app
  // boot (shared MethodChannel — multiple Dart instances talk to the same
  // native plugin). We only need to ensure the download-progress channel
  // exists and keep per-task notification IDs so parallel downloads don't
  // collide on the same notification row.
  //
  // Why duplicate this from video_chapter_detail.dart's copy?  The widget's
  // notification helpers only run while the widget is mounted — navigating
  // away from the topic screen killed the progress notification. Downloads
  // live in the service (which outlives any screen), so progress UI has to
  // live there too or it disappears mid-download.
  static const String _notifChannelId = 'download_channel';
  static const String _notifChannelName = 'Downloads';
  static const String _notifChannelDesc =
      'Notifications for video download progress';
  final FlutterLocalNotificationsPlugin _notifs =
      FlutterLocalNotificationsPlugin();
  bool _notifChannelReady = false;
  // 1000+ offset so we never collide with the PDF download notification (ID 1)
  // that notes_chapter_detail uses. Each task gets a stable ID for the
  // duration of its lifecycle so updates replace the same row instead of
  // piling up.
  int _nextNotifId = 1001;
  final Map<String, int> _notifIdByTitle = {};
  // Last integer-percent we pushed to the notification layer per task. Used
  // to skip redundant .show() calls — on Android a re-show with the same
  // percentage is a silent no-op that still pays the MethodChannel round-trip,
  // and at 10 MB/s over 30ms chunks that's ~330 wasted hops per MB.
  final Map<String, int> _lastNotifPercent = {};
  // iOS-only: track which tasks have already shown their "Started downloading"
  // banner so we don't re-alert on every progress tick. iOS has no progress
  // bar in notifications — each .show() is a full user-facing alert, so we
  // intentionally show ONE notification at start, skip middle updates, then
  // show a final success/failure notification. Android gets the full live
  // progress bar (see _pushProgressNotification).
  final Set<String> _iosStartShown = <String>{};

  // ── Lifecycle ───────────────────────────────────────────────────────────

  /// Called once from main() at app startup.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    wifiOnly = prefs.getBool(_wifiOnlyKey) ?? false;
    await _cleanupTempFiles();
    _listenConnectivity();
    // Best-effort — if the channel creation fails (e.g. iOS / older Android
    // flavors), we silently skip progress notifications rather than break
    // downloads. Notifications are strictly additive UX.
    await _ensureNotifChannel();
  }

  Future<void> setWifiOnly(bool value) async {
    wifiOnly = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wifiOnlyKey, value);
    // Re-evaluate active task against new policy.
    if (value && _activeTask != null) {
      final results = await Connectivity().checkConnectivity();
      if (!_hasWifi(results)) {
        pauseActive();
      }
    }
  }

  void _listenConnectivity() {
    _connSub?.cancel();
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      // If policy is WiFi-only and we lost WiFi → pause any active download.
      if (wifiOnly && _activeTask != null && !_hasWifi(results)) {
        pauseActive();
        return;
      }
      // If we came back online (WiFi, or policy off) and a paused task exists,
      // resume the first paused task into the queue.
      final anyPaused = _allTasks.values
          .where((t) => t.status == DownloadStatus.paused)
          .toList();
      if (anyPaused.isNotEmpty) {
        final online = results.any((r) => r != ConnectivityResult.none);
        if (online && (!wifiOnly || _hasWifi(results))) {
          for (final t in anyPaused) {
            resumePaused(t.titleId);
          }
        }
      }
    });
  }

  bool _hasWifi(List<ConnectivityResult> r) =>
      r.contains(ConnectivityResult.wifi) || r.contains(ConnectivityResult.ethernet);

  /// Remove any .tmp.mp4 left behind by an interrupted prior run.
  Future<void> _cleanupTempFiles() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      int cleaned = 0;
      await for (final f in dir.list(recursive: false, followLinks: false)) {
        if (f is File && f.path.endsWith('.tmp.mp4')) {
          try {
            await f.delete();
            cleaned++;
          } catch (_) {}
        }
      }
      if (cleaned > 0) debugPrint('[DL] cleaned $cleaned leftover temp files');
    } catch (e) {
      debugPrint('[DL] temp cleanup error: $e');
    }
  }

  // ── Queue API ───────────────────────────────────────────────────────────

  DownloadTask enqueue({
    required String titleId,
    required String url,
    required String quality,
    required String title,
    String topicId = '',
    String categoryId = '',
    String subCategoryId = '',
  }) {
    final existing = _allTasks[titleId];
    if (existing != null) {
      // Active or already-finished tasks: nothing to do.
      if (existing.status == DownloadStatus.downloading ||
          existing.status == DownloadStatus.encrypting ||
          existing.status == DownloadStatus.queued ||
          existing.status == DownloadStatus.completed) {
        return existing;
      }
      // Failed / cancelled / paused → re-queue for retry.
      existing.status = DownloadStatus.queued;
      existing.errorMessage = null;
      existing.downloadedBytes = 0;
      existing.totalBytes = 0;
      _queue.add(existing);
      _emitQueueChanged();
      _pump();
      return existing;
    }

    final task = DownloadTask(
      titleId: titleId,
      url: url,
      quality: quality,
      title: title,
      topicId: topicId,
      categoryId: categoryId,
      subCategoryId: subCategoryId,
    );
    _allTasks[titleId] = task;
    _queue.add(task);
    // Emit an update as well so observers that only listen to `updates`
    // (store, player) immediately see the queued task. Without this the
    // "Queued" UI state only appears once the task reaches the front of
    // the queue and _runNext flips it to downloading — which for anything
    // after the first task means a delay of minutes.
    _emitUpdate(task);
    _emitQueueChanged();
    _pump();
    return task;
  }

  List<DownloadTask> enqueueMultiple(List<Map<String, String>> videos) {
    final tasks = <DownloadTask>[];
    for (final v in videos) {
      tasks.add(enqueue(
        titleId: v['titleId'] ?? '',
        url: v['url'] ?? '',
        quality: v['quality'] ?? '540p',
        title: v['title'] ?? '',
        topicId: v['topicId'] ?? '',
        categoryId: v['categoryId'] ?? '',
        subCategoryId: v['subCategoryId'] ?? '',
      ));
    }
    return tasks;
  }

  void cancel(String titleId) {
    final task = _allTasks[titleId];
    if (task == null) return;
    if (task == _activeTask) {
      // Mark intent and tear down the live handles. _tearDownActive now
      // completes the done-completer synchronously so _runNext unblocks
      // cleanly. CRITICAL: do NOT touch _activeTask / _isProcessing or call
      // _pump() here — _runNext's finally block owns that state. If we
      // reset it here, a fresh _runNext from our own _pump() can race
      // against the original _runNext's finally, which would clobber
      // _activeTask mid-download and briefly leave two concurrent downloads
      // running.
      _cancelRequested = true;
      task.status = DownloadStatus.cancelled;
      _emitUpdate(task);
      _tearDownActive();
      // Fire-and-forget temp cleanup; safe because _runNext won't restart
      // this titleId (it's marked cancelled).
      _cleanupTaskFiles(titleId, task.quality);
      _emitQueueChanged();
    } else {
      _queue.removeWhere((t) => t.titleId == titleId);
      task.status = DownloadStatus.cancelled;
      _emitUpdate(task);
      _emitQueueChanged();
    }
  }

  void pauseActive() {
    final t = _activeTask;
    if (t == null) return;
    // Same reasoning as cancel(): _tearDownActive unblocks _runNext's await
    // on done.future, and _runNext's finally owns _activeTask / _isProcessing.
    // Touching them here races with the finally block.
    _cancelRequested = true;
    t.status = DownloadStatus.paused;
    _emitUpdate(t);
    _tearDownActive();
    _emitQueueChanged();
  }

  void resumePaused(String titleId) {
    final t = _allTasks[titleId];
    if (t == null || t.status != DownloadStatus.paused) return;
    t.status = DownloadStatus.queued;
    _queue.addFirst(t);
    // Surface the queued transition to UI listeners right away so the UI
    // doesn't keep showing "Paused" until _runNext gets around to this task.
    _emitUpdate(t);
    _emitQueueChanged();
    _pump();
  }

  // ── Queries ─────────────────────────────────────────────────────────────

  DownloadTask? getTask(String titleId) => _allTasks[titleId];
  List<DownloadTask> get allTasks => _allTasks.values.toList();
  List<DownloadTask> get queuedTasks => _allTasks.values
      .where((t) => t.status == DownloadStatus.queued)
      .toList();
  DownloadTask? get activeTask => _activeTask;
  int get queueLength => _queue.length;
  bool isInQueue(String titleId) {
    final t = _allTasks[titleId];
    return t != null &&
        (t.status == DownloadStatus.queued ||
            t.status == DownloadStatus.downloading ||
            t.status == DownloadStatus.encrypting);
  }

  // ── Pump / worker loop ──────────────────────────────────────────────────

  void _pump() {
    if (_isProcessing) return;
    if (_queue.isEmpty) return;
    _runNext();
  }

  Future<void> _runNext() async {
    // Flip the processing flag SYNCHRONOUSLY before any await. If we awaited
    // connectivity first (old code) a second _pump() could race through the
    // same `!_isProcessing` check while this one was suspended, and we'd end
    // up with two concurrent downloads pulling the same queue.
    if (_isProcessing || _queue.isEmpty) return;
    _isProcessing = true;

    // WiFi-only gate — evaluated after claiming the slot, so we own it.
    if (wifiOnly) {
      final results = await Connectivity().checkConnectivity();
      if (!_hasWifi(results)) {
        debugPrint('[DL] WiFi-only: waiting for WiFi');
        _isProcessing = false;
        return;
      }
    }

    // Queue could have been drained during the connectivity await.
    if (_queue.isEmpty) {
      _isProcessing = false;
      return;
    }

    _cancelRequested = false;
    final task = _queue.removeFirst();
    _activeTask = task;
    task.status = DownloadStatus.downloading;
    _emitUpdate(task);
    _emitQueueChanged();

    try {
      await _downloadWithRetry(task);
      if (!_cancelRequested &&
          task.status != DownloadStatus.cancelled &&
          task.status != DownloadStatus.paused) {
        await _encryptAndSave(task);
        // Re-check status AFTER encrypt — pauseActive / cancel could have
        // fired during the multi-second encrypt phase, in which case we do
        // NOT want to clobber their status flip (paused/cancelled) with
        // `completed`. The DB row is already inserted by _encryptAndSave
        // though, so the user still sees the video offline on resume.
        if (!_cancelRequested &&
            task.status != DownloadStatus.cancelled &&
            task.status != DownloadStatus.paused) {
          task.status = DownloadStatus.completed;
          _emitCompleted(task);
          debugPrint('[DL] completed ${task.titleId}');
        }
      }
    } catch (e) {
      if (!_cancelRequested) {
        task.status = DownloadStatus.failed;
        task.errorMessage = e.toString();
        _emitFailed(task);
        debugPrint('[DL] failed ${task.titleId}: $e');
      }
    } finally {
      _activeTask = null;
      _isProcessing = false;
      _emitQueueChanged();
      // Small yield so UI can repaint before we pull the next task.
      Future<void>.delayed(const Duration(milliseconds: 50), _pump);
    }
  }

  // ── Download phase (with resume + retry) ────────────────────────────────

  Future<void> _downloadWithRetry(DownloadTask task) async {
    int attempt = 0;
    Object? lastErr;
    while (attempt < _maxNetworkRetries) {
      if (_cancelRequested) return;
      try {
        await _downloadOnce(task);
        return; // success
      } on _CancelledException {
        // User cancelled — do not retry.
        return;
      } on _NonRetryableException catch (e) {
        throw Exception(e.message);
      } catch (e) {
        lastErr = e;
        attempt++;
        if (_cancelRequested) return;
        // Exponential backoff: 2s, 4s, 8s …
        final delay = Duration(seconds: 2 << (attempt - 1));
        debugPrint(
            '[DL] ${task.titleId} attempt $attempt/$_maxNetworkRetries failed: $e; retrying in ${delay.inSeconds}s');
        await Future<void>.delayed(delay);
      }
    }
    throw Exception('Download failed after $_maxNetworkRetries attempts: $lastErr');
  }

  /// Streams the body into a temp file with HTTP Range resume support.
  Future<void> _downloadOnce(DownloadTask task) async {
    final dir = await getApplicationDocumentsDirectory();
    final tempPath = '${dir.path}/video_${task.titleId}_${task.quality}.tmp.mp4';
    final tempFile = File(tempPath);

    int existing = 0;
    if (await tempFile.exists()) {
      existing = await tempFile.length();
    }
    task.downloadedBytes = existing;

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20)
      ..idleTimeout = _idleTimeout;
    _activeClient = client;

    HttpClientRequest req;
    try {
      req = await client.getUrl(Uri.parse(task.url));
    } catch (e) {
      client.close(force: true);
      _activeClient = null;
      rethrow;
    }
    if (existing > 0) {
      req.headers.set(HttpHeaders.rangeHeader, 'bytes=$existing-');
    }
    req.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
    _activeRequest = req;

    late HttpClientResponse res;
    try {
      res = await req.close();
    } catch (e) {
      client.close(force: true);
      _activeRequest = null;
      _activeClient = null;
      rethrow;
    }

    final status = res.statusCode;
    if (status != 200 && status != 206) {
      // 403/404/410 → permanent; others → retryable.
      client.close(force: true);
      _activeRequest = null;
      _activeClient = null;
      if (status == 403 || status == 404 || status == 410) {
        throw _NonRetryableException('HTTP $status — video unavailable');
      }
      throw Exception('HTTP $status');
    }

    // If server ignored Range and sent full body, restart from scratch.
    if (status == 200 && existing > 0) {
      try {
        await tempFile.delete();
      } catch (_) {}
      existing = 0;
      task.downloadedBytes = 0;
    }

    final contentLength = res.contentLength;
    if (contentLength > 0) {
      task.totalBytes = existing + contentLength;
    }

    final sink = tempFile.openWrite(
      mode: existing > 0 ? FileMode.writeOnlyAppend : FileMode.writeOnly,
    );
    _activeSink = sink;

    int lastReportMs = 0;
    final done = Completer<void>();
    // Expose for _tearDownActive so cancel/pause can unblock the await below.
    _activeDoneCompleter = done;

    _activeSub = res.listen(
      (chunk) {
        if (_cancelRequested) return;
        task.downloadedBytes += chunk.length;
        sink.add(chunk);
        final now = DateTime.now().millisecondsSinceEpoch;
        // Report every 500ms; always at start (0%) and end (100%).
        if ((now - lastReportMs) >= 500 ||
            task.progressPercent >= 100 ||
            lastReportMs == 0) {
          lastReportMs = now;
          _emitUpdate(task);
        }
      },
      onDone: () async {
        try {
          await sink.flush();
        } catch (_) {}
        try {
          await sink.close();
        } catch (_) {}
        _activeSink = null;
        try {
          client.close();
        } catch (_) {}
        _activeClient = null;
        _activeRequest = null;
        if (!done.isCompleted) done.complete();
        // Clear only if still ours — _tearDownActive may have already
        // nulled and re-assigned _activeDoneCompleter for a subsequent task.
        if (identical(_activeDoneCompleter, done)) {
          _activeDoneCompleter = null;
        }
      },
      onError: (Object e, StackTrace s) async {
        try {
          await sink.close();
        } catch (_) {}
        _activeSink = null;
        try {
          client.close(force: true);
        } catch (_) {}
        _activeClient = null;
        _activeRequest = null;
        if (!done.isCompleted) done.completeError(e, s);
        if (identical(_activeDoneCompleter, done)) {
          _activeDoneCompleter = null;
        }
      },
      cancelOnError: true,
    );

    await done.future;
    _activeSub = null;
    if (identical(_activeDoneCompleter, done)) {
      _activeDoneCompleter = null;
    }

    if (_cancelRequested) {
      throw _CancelledException();
    }
  }

  // ── Encrypt → DB save phase ─────────────────────────────────────────────

  Future<void> _encryptAndSave(DownloadTask task) async {
    task.status = DownloadStatus.encrypting;
    _emitUpdate(task);

    final dir = await getApplicationDocumentsDirectory();
    final tempFile =
        File('${dir.path}/video_${task.titleId}_${task.quality}.tmp.mp4');
    final encFile =
        File('${dir.path}/video_${task.titleId}_${task.quality}.enc');

    if (!await tempFile.exists()) {
      throw Exception('Temp file missing before encryption');
    }

    List<int>? key = await SecureKeys.loadKey('global');
    if (key == null || key.length != 32) {
      try {
        await SecureKeys.deleteKey('global');
      } catch (_) {}
      key = await SecureKeys.loadKey('global');
    }
    if (key == null || key.length != 32) {
      await _cleanupTaskFiles(task.titleId, task.quality);
      throw Exception('Encryption key missing — please refresh your profile');
    }

    try {
      await OfflineEncryptor.encryptFile(tempFile, encFile, key);
    } catch (e) {
      // Encryption failed → remove both partial files.
      try {
        if (await encFile.exists()) await encFile.delete();
      } catch (_) {}
      try {
        if (await tempFile.exists()) await tempFile.delete();
      } catch (_) {}
      rethrow;
    }

    // Remove clear-text temp now that .enc is sealed on disk.
    try {
      if (await tempFile.exists()) await tempFile.delete();
    } catch (_) {}

    // Persist to DB.
    final db = DbHelper();
    final model = VideoOfflineDataModel(
      title: task.title,
      titleId: task.titleId,
      topicId: task.topicId,
      videoPath: encFile.path,
      categoryId: task.categoryId,
      subCategoryId: task.subCategoryId,
    );
    await db.insertVideo(model);
  }

  // ── Teardown / cleanup helpers ──────────────────────────────────────────

  void _tearDownActive() {
    // Complete _downloadOnce's `done` future FIRST so the awaiting _runNext
    // can proceed. If we cancelled the subscription first (previous order),
    // the listen's onDone/onError callbacks never fire — the subscription is
    // dead — and `await done.future` in _downloadOnce would hang forever,
    // racing with whatever state teardown the caller then did. That left
    // orphaned futures + occasionally two _runNext instances running at once
    // when a cancel happened near a queue transition.
    final done = _activeDoneCompleter;
    _activeDoneCompleter = null;
    if (done != null && !done.isCompleted) {
      try {
        done.complete();
      } catch (_) {}
    }
    try {
      _activeSub?.cancel();
    } catch (_) {}
    _activeSub = null;
    try {
      _activeSink?.close();
    } catch (_) {}
    _activeSink = null;
    try {
      _activeClient?.close(force: true);
    } catch (_) {}
    _activeClient = null;
    _activeRequest = null;
  }

  Future<void> _cleanupTaskFiles(String titleId, String quality) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final tmp = File('${dir.path}/video_${titleId}_$quality.tmp.mp4');
      final enc = File('${dir.path}/video_${titleId}_$quality.enc');
      if (await tmp.exists()) await tmp.delete();
      if (await enc.exists()) await enc.delete();
    } catch (_) {}
  }

  // ── Storage info / delete-all ───────────────────────────────────────────

  Future<Map<String, dynamic>> getStorageInfo() async {
    final dir = await getApplicationDocumentsDirectory();
    int totalSize = 0;
    int fileCount = 0;
    try {
      await for (final f in dir.list(recursive: false, followLinks: false)) {
        if (f is File && (f.path.endsWith('.enc') || f.path.endsWith('.mp4'))) {
          try {
            totalSize += await f.length();
            fileCount++;
          } catch (_) {}
        }
      }
    } catch (_) {}
    final formatted = totalSize > 1024 * 1024 * 1024
        ? '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB'
        : '${(totalSize / (1024 * 1024)).toStringAsFixed(0)} MB';
    return {
      'totalBytes': totalSize,
      'totalMB': (totalSize / (1024 * 1024)).toStringAsFixed(0),
      'totalGB': (totalSize / (1024 * 1024 * 1024)).toStringAsFixed(2),
      'fileCount': fileCount,
      'formatted': formatted,
    };
  }

  Future<void> deleteAllDownloads() async {
    // Abort anything in-flight first.
    if (_activeTask != null) {
      cancel(_activeTask!.titleId);
    }
    _queue.clear();

    final db = DbHelper();
    final dir = await getApplicationDocumentsDirectory();
    try {
      await for (final f in dir.list(recursive: false, followLinks: false)) {
        if (f is File &&
            (f.path.endsWith('.enc') || f.path.endsWith('.tmp.mp4'))) {
          try {
            await f.delete();
          } catch (_) {}
        }
      }
    } catch (_) {}

    try {
      final allVideos = await db.getAllVideoGroupedByCategoryId();
      for (final v in allVideos) {
        if (v.titleId != null) {
          await db.deleteVideoByTitleId(v.titleId!);
        }
      }
    } catch (_) {}

    _allTasks.clear();
    _emitQueueChanged();
  }

  // ── Notification plumbing ───────────────────────────────────────────────

  Future<void> _ensureNotifChannel() async {
    if (_notifChannelReady) return;
    try {
      // Android: create the dedicated low-importance channel that all
      // download notifications are posted to.
      final androidImpl =
          _notifs.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl.createNotificationChannel(
          const AndroidNotificationChannel(
            _notifChannelId,
            _notifChannelName,
            description: _notifChannelDesc,
            importance: Importance.low,
            // We don't want a sound every 500ms during a long download.
            playSound: false,
            enableVibration: false,
            showBadge: false,
          ),
        );
      }
      // iOS: phone_app.dart's initializeNotifications() already called
      // requestPermissions(alert/badge/sound) during app boot. We don't
      // re-request here — doing so every time the download service boots
      // would re-prompt the user if they'd previously denied. If permission
      // is denied, `.show()` silently no-ops, which is the correct fallback.
      _notifChannelReady = true;
    } catch (e) {
      debugPrint('[DL] notif channel setup failed: $e');
      // Leave `_notifChannelReady = false` so the helpers below early-out
      // silently. Downloads still work; we just don't get notifications.
    }
  }

  int _notifIdFor(String titleId) {
    return _notifIdByTitle.putIfAbsent(titleId, () => _nextNotifId++);
  }

  /// Safe-looking task title for the notification body. Empty titles fall
  /// back to a generic string so Android doesn't render an awkward blank row.
  String _notifTitleFor(DownloadTask t) {
    final raw = t.title.trim();
    return raw.isEmpty ? 'Video' : raw;
  }

  Future<void> _pushProgressNotification(DownloadTask t) async {
    if (!_notifChannelReady) return;
    // Routes status → notification action so callers don't have to branch.
    try {
      switch (t.status) {
        case DownloadStatus.cancelled:
        case DownloadStatus.paused:
          // Remove the progress notification — it's no longer meaningful.
          final id = _notifIdByTitle.remove(t.titleId);
          _lastNotifPercent.remove(t.titleId);
          _iosStartShown.remove(t.titleId);
          if (id != null) {
            await _notifs.cancel(id);
          }
          return;
        case DownloadStatus.completed:
        case DownloadStatus.failed:
          // Handled by the dedicated complete/failed helpers.
          return;
        case DownloadStatus.queued:
        case DownloadStatus.downloading:
        case DownloadStatus.encrypting:
          break;
      }

      // ── iOS path ────────────────────────────────────────────────────────
      // iOS has no in-notification progress bar and treats every .show() as
      // a new user-facing alert (the foreground stays silent because we use
      // presentAlert:false — but in background each update would dock-badge
      // noisily). Strategy: show ONE "Started downloading" banner at the
      // first downloading event, then stay silent until completion.
      // Encrypting gets its own one-shot banner too so a long encrypt phase
      // on a big file doesn't look like the app hung.
      if (Platform.isIOS) {
        // Decide whether this iOS tick warrants a banner.
        final bool showStart = t.status == DownloadStatus.downloading &&
            !_iosStartShown.contains(t.titleId);
        final bool showEncrypt = t.status == DownloadStatus.encrypting &&
            // Reuse the same flag store — entering encrypt overrides the
            // "started" one-shot so user sees the phase change.
            _lastNotifPercent[t.titleId] != -1;
        if (!showStart && !showEncrypt) return;
        if (showStart) _iosStartShown.add(t.titleId);
        if (showEncrypt) _lastNotifPercent[t.titleId] = -1;

        final body = showEncrypt ? 'Finalizing…' : 'Downloading…';
        const ios = DarwinNotificationDetails(
          // Don't alert in foreground — user is already looking at the app.
          presentAlert: false,
          presentBadge: false,
          presentSound: false,
          // Group all download notifications so iOS collapses them into
          // one stack in Notification Center instead of spamming the list.
          threadIdentifier: _notifChannelId,
          interruptionLevel: InterruptionLevel.passive,
        );
        const details = NotificationDetails(iOS: ios);
        await _notifs.show(
          _notifIdFor(t.titleId),
          _notifTitleFor(t),
          body,
          details,
        );
        return;
      }

      // ── Android path ────────────────────────────────────────────────────
      final percent = t.progressPercent.clamp(0, 100);
      // Skip redundant shows for identical percentages — Android renders them
      // as no-ops but still pays MethodChannel cost. Encrypting state always
      // pushes (different body line) so user sees the phase transition.
      final last = _lastNotifPercent[t.titleId];
      if (t.status != DownloadStatus.encrypting &&
          last != null &&
          last == percent) {
        return;
      }
      _lastNotifPercent[t.titleId] = percent;

      final body = t.status == DownloadStatus.queued
          ? 'Queued'
          : t.status == DownloadStatus.encrypting
              ? 'Encrypting…'
              : 'Downloading — $percent%';

      final android = AndroidNotificationDetails(
        _notifChannelId,
        _notifChannelName,
        channelDescription: _notifChannelDesc,
        importance: Importance.low,
        priority: Priority.low,
        // Stops the notification sound/vibration from replaying on every
        // 500ms progress tick.
        onlyAlertOnce: true,
        // Encrypting is indeterminate (we don't stream bytes through the
        // encryptor — it's file-to-file AES-GCM); flip the indeterminate
        // bit so the bar animates instead of freezing at the last %.
        showProgress: t.status == DownloadStatus.downloading ||
            t.status == DownloadStatus.encrypting,
        maxProgress: 100,
        progress: t.status == DownloadStatus.encrypting ? 0 : percent,
        indeterminate: t.status == DownloadStatus.encrypting,
        playSound: false,
        enableVibration: false,
        ongoing: true,
        autoCancel: false,
        category: AndroidNotificationCategory.progress,
      );
      final details = NotificationDetails(android: android);
      await _notifs.show(
        _notifIdFor(t.titleId),
        _notifTitleFor(t),
        body,
        details,
      );
    } catch (e) {
      // Never let a notification failure bubble up into the download pipeline.
      debugPrint('[DL] notif progress failed: $e');
    }
  }

  Future<void> _pushCompletedNotification(DownloadTask t) async {
    if (!_notifChannelReady) return;
    try {
      final id = _notifIdByTitle.remove(t.titleId);
      _lastNotifPercent.remove(t.titleId);
      _iosStartShown.remove(t.titleId);
      // Cancel the ongoing-progress notification so the "complete" row is a
      // standalone dismissible one, not overlaid on the running bar.
      if (id != null) {
        await _notifs.cancel(id);
      }
      const android = AndroidNotificationDetails(
        _notifChannelId,
        _notifChannelName,
        channelDescription: _notifChannelDesc,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: false,
        enableVibration: false,
        autoCancel: true,
        // No progress bar on the final notification.
      );
      const ios = DarwinNotificationDetails(
        // Complete is worth a banner even in foreground — the user was
        // likely off doing something else while the download ran.
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
        threadIdentifier: _notifChannelId,
        interruptionLevel: InterruptionLevel.active,
      );
      const details = NotificationDetails(android: android, iOS: ios);
      await _notifs.show(
        // Reuse the same task ID the progress row was using so we don't leak
        // notification IDs (if progress never fired we get a fresh ID here).
        id ?? _notifIdFor(t.titleId),
        _notifTitleFor(t),
        'Download complete',
        details,
      );
    } catch (e) {
      debugPrint('[DL] notif complete failed: $e');
    }
  }

  Future<void> _pushFailedNotification(DownloadTask t) async {
    if (!_notifChannelReady) return;
    try {
      final id = _notifIdByTitle.remove(t.titleId);
      _lastNotifPercent.remove(t.titleId);
      _iosStartShown.remove(t.titleId);
      if (id != null) {
        await _notifs.cancel(id);
      }
      const android = AndroidNotificationDetails(
        _notifChannelId,
        _notifChannelName,
        channelDescription: _notifChannelDesc,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: false,
        enableVibration: false,
        autoCancel: true,
      );
      const ios = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
        threadIdentifier: _notifChannelId,
        interruptionLevel: InterruptionLevel.active,
      );
      const details = NotificationDetails(android: android, iOS: ios);
      await _notifs.show(
        id ?? _notifIdFor(t.titleId),
        _notifTitleFor(t),
        // Keep the error message short — Android truncates past ~80 chars in
        // the collapsed view anyway.
        'Download failed',
        details,
      );
    } catch (e) {
      debugPrint('[DL] notif failed failed: $e');
    }
  }
}

// ── Model / enums ─────────────────────────────────────────────────────────

class DownloadTask {
  final String titleId;
  final String url;
  final String quality;
  final String title;
  final String topicId;
  final String categoryId;
  final String subCategoryId;

  DownloadStatus status;
  int totalBytes;
  int downloadedBytes;
  String? errorMessage;
  DateTime queuedAt;

  DownloadTask({
    required this.titleId,
    required this.url,
    required this.quality,
    required this.title,
    this.topicId = '',
    this.categoryId = '',
    this.subCategoryId = '',
    this.status = DownloadStatus.queued,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    this.errorMessage,
  }) : queuedAt = DateTime.now();

  int get progressPercent => totalBytes > 0
      ? ((downloadedBytes / totalBytes) * 100).clamp(0, 100).toInt()
      : 0;

  String get fileSizeFormatted {
    if (totalBytes <= 0) return '';
    final mb = totalBytes / (1024 * 1024);
    return mb >= 1024
        ? '${(mb / 1024).toStringAsFixed(1)} GB'
        : '${mb.toStringAsFixed(0)} MB';
  }

  String get downloadedSizeFormatted {
    final mb = downloadedBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(0)} MB';
  }
}

enum DownloadStatus {
  queued,
  downloading,
  encrypting,
  completed,
  failed,
  paused,
  cancelled,
}

typedef DownloadCallback = void Function(DownloadTask task);

// ── Internal sentinels ────────────────────────────────────────────────────

class _NonRetryableException implements Exception {
  final String message;
  _NonRetryableException(this.message);
  @override
  String toString() => message;
}

class _CancelledException implements Exception {}
