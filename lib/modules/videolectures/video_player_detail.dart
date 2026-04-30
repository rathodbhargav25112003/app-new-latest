// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters, unused_field, unused_local_variable, non_constant_identifier_names, dead_code, prefer_final_fields, unnecessary_import, use_build_context_synchronously, avoid_print, unused_element, unnecessary_string_interpolations, dead_null_aware_expression, prefer_interpolation_to_compose_strings, prefer_null_aware_operators, unnecessary_non_null_assertion, constant_identifier_names

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/styles.dart';
import '../notes/notes_viewer.dart';
import '../../helpers/dbhelper.dart';
import '../../helpers/constants.dart';
import '../widgets/bottom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../helpers/dimensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shusruta_lms/app/app.dart';
import '../../models/video_data_model.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart' as material;
import '../../models/video_offline_data_model.dart';
import '../../models/video_chapterization_list_model.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:shusruta_lms/models/notes_topic_model.dart';
import 'package:shusruta_lms/modules/notes/sharedhelper.dart';
import 'package:shusruta_lms/models/video_topic_detail_model.dart';
import 'package:shusruta_lms/modules/dashboard/store/home_store.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shusruta_lms/modules/videolectures/store/video_category_store.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

// import 'package:better_player_plus/better_player_plus.dart';
import '../../services/secure_keys.dart';
import '../../services/offline_encryptor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shusruta_lms/services/download_service.dart';
import 'package:shusruta_lms/modules/videolectures/widgets/download_manager_sheet.dart';
import 'package:shusruta_lms/modules/widgets/video_bookmarks_sheet.dart';

class VideoPlayerDetail extends StatefulWidget {
  final String? topicId;
  final String? pdfId;
  final String? pdfContents;
  final bool? isCompleted;
  final String? title;
  final String? videoThumbnail;
  final String? topic_name;
  final String? category_name;
  final String? subcategory_name;
  final String? titleId;
  final String? categoryId;
  final String? subcategoryId;
  final String? contentId;
  final String? pauseTime;
  final String? videoPlayUrl;
  final bool? isDownloaded;
  final bool? isBookmark;
  final List<Files>? videoQuality;
  final List<Download>? downloadVideoData;
  final String? annotationData;
  final String? hlsLink;

  const VideoPlayerDetail({
    super.key,
    this.topicId,
    this.isCompleted,
    this.titleId,
    this.pdfId,
    this.pdfContents,
    this.subcategoryId,
    this.categoryId,
    this.topic_name,
    this.subcategory_name,
    this.category_name,
    this.title,
    this.videoThumbnail,
    this.contentId,
    this.pauseTime,
    this.isDownloaded,
    this.isBookmark,
    this.videoPlayUrl,
    this.videoQuality,
    this.downloadVideoData,
    this.annotationData,
    this.hlsLink,
  });

  @override
  State<VideoPlayerDetail> createState() => _VideoPlayerDetailState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => VideoPlayerDetail(
        topicId: arguments['topicId'],
        contentId: arguments['contentId'],
        isCompleted: arguments['isCompleted'],
        title: arguments['title'],
        videoThumbnail: arguments['videoThumbnail'],
        topic_name: arguments['topic_name'],
        category_name: arguments['category_name'],
        subcategory_name: arguments['subcategory_name'],
        isDownloaded: arguments['isDownloaded'],
        titleId: arguments['titleId'],
        categoryId: arguments['categoryId'],
        subcategoryId: arguments['subcategoryId'],
        pauseTime: arguments['pauseTime'],
        isBookmark: arguments['isBookmark'],
        videoPlayUrl: arguments['videoPlayUrl'],
        videoQuality: arguments['videoQuality'],
        pdfId: arguments['pdfId'],
        pdfContents: arguments['pdfContents'],
        downloadVideoData: arguments['downloadVideoData'],
        annotationData: arguments['annotationData'],
        hlsLink: arguments['hlsLink'],
      ),
    );
  }
}

class _VideoPlayerDetailState extends State<VideoPlayerDetail> {
  final dbHelper = DbHelper();
  late VideoCategoryStore _videoStore;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _betterPlayerKey = GlobalKey();
  bool pdfview = false;
  bool positive = false;
  FlickManager? flickManager;
  bool isLoading = true;
  // Vimeo token moved to server-side proxy — see /api/video/vimeo-url/:videoId
  // DO NOT hardcode API tokens in client code (decompilable)
  final String _accessToken = const String.fromEnvironment('VIMEO_TOKEN', defaultValue: '');
  bool isFullScreen = false;
  String pdfUrl = '';
  String contentUrl = '';
  String topicName = '';
  final GlobalKey<NotesViewerState> _notesViewerKey =
      GlobalKey<NotesViewerState>();
  // Separate key for any secondary NotesViewer instances on desktop (e.g.,
  // the one embedded in the left column). Using distinct keys avoids
  // "Multiple widgets used the same GlobalKey" runtime exceptions.
  final GlobalKey<NotesViewerState> _notesViewerKeySecondary =
      GlobalKey<NotesViewerState>();
  final GlobalKey _pdfViewerKey = GlobalKey();
  late PdfViewerController _pdfViewerController;
  int duration = 0;
  String topicDesc = '';
  bool isDrawerOpen = false;
  bool isSeekDone = false;
  bool isFeaturedVideoExist = false;
  int currentIndex = 0;
  bool isMarkCompleted = false;
  bool isBookmarkedDone = false;
  int tabIndex = 2;
  File? _tempDecryptedFile; // holds a short-lived clear file during offline playback

  // late VideoPlayerController _videoPlayerController;
  late BetterPlayerController _betterPlayerController;
  bool _isInPipMode = false;
  bool _isPlayerInitialized = false;
  String _selectedQuality = "540p";
  String downloadQuality = "540p";
  bool _autoPlay = true;
  double _playbackSpeed = 1.0;
  int _seekTime = 10;
  final Map<String, String> _videoUrls = {};
  final Map<String, String> _qualityAndSize = {};
  int downloadProgress = 0;
  int selectedIndex = 0;
  bool isOfflineMode = false;
  bool isDownloaded = false;
  String downloadUrl = "";
  int _selectedIndex = 0;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  // ── Offline decrypt machinery ──────────────────────────────────────────
  // The encrypted file on disk (.enc) has to be streamed through AES-GCM
  // before ExoPlayer/AVPlayer can read it. For a 500 MB lecture this can
  // take 3-15 s on mid-range devices. Without an overlay the user sees a
  // black screen and assumes the app crashed — so we expose [_isDecrypting]
  // and render a "Preparing offline video…" overlay while it runs.
  //
  // The mutex prevents two rapid taps on adjacent offline videos from each
  // kicking off their own decrypt (which would thrash disk, blow RAM on
  // mobile, and race to write the same temp file). The second caller just
  // awaits the first one's Completer and short-circuits if the same path
  // has already finished.
  bool _isDecrypting = false;
  Completer<bool>? _decryptInFlight;
  String? _decryptInFlightPath;

  @override
  void initState() {
    super.initState();
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _initializeNotifications();
    _loadSavedPlaybackSpeed();
    // Phase 1: subscribe first so _buildDataSource sees correct network from
    // the very first source build — avoids building with `.none` defaults.
    _subscribeConnectivity();
    _initializeData();
    _loadVideoSizes();
    if (isDesktop) {
      _fetchVideoUrl();
    }
    // Phase 1 pre-warm: fire a Range GET on the HLS URL (if available) while
    // the API calls in _initializeData() are still in flight. By the time the
    // BetterPlayerController is built, Bunny CDN's edge is already primed.
    if (!isDesktop && widget.hlsLink != null && widget.hlsLink!.isNotEmpty) {
      _preWarmCdn(widget.hlsLink!);
    }
    isBookmarkedDone = widget.isBookmark ?? false;
    isMarkCompleted = widget.isCompleted ?? false;
    contentUrl = widget.pdfContents ?? "";
    if (contentUrl.isNotEmpty) {
      pdfUrl = "getPDF${contentUrl.substring(contentUrl.lastIndexOf('/'))}";
    }
    // Preload the global key for diagnostics; do not generate locally.
    SecureKeys.loadKey('global').then((k) {
      try {
        print('[KEY] loaded_global_key len=' + (k?.length ?? 0).toString());
      } catch (_) {}
    });
  }

  /// Restore saved playback speed from SharedPreferences
  Future<void> _loadSavedPlaybackSpeed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getDouble('video_playback_speed');
      if (saved != null && saved >= 0.5 && saved <= 3.0) {
        setState(() { _playbackSpeed = saved; });
      }
    } catch (_) {}
  }

  /// Auto-select video quality based on network type.
  ///
  /// **Startup-bitrate strategy** (Phase 1 optimization):
  ///   WiFi    → 540p first-frame target, HLS ABR ramps to 720p/1080p quickly
  ///   Mobile  → 360p (save data, avoid rebuffer)
  ///   Unknown → 480p safe middle
  ///
  /// Starting lower cuts first-frame latency ~40% vs starting at 720p, and
  /// HLS adaptive bitrate will ramp up within a few seconds anyway once the
  /// buffer fills. For MP4 sources (non-HLS) the user-selected or saved
  /// quality still wins — this only sets the default on a fresh open.
  /// **Important:** must run AFTER _videoUrls is populated, otherwise the
  /// containsKey check always fails and we silently stay at the constructor
  /// default.
  Future<void> _autoSelectQuality() async {
    try {
      if (_videoUrls.isEmpty) return; // nothing to pick from yet
      String autoQuality;
      if (_connectivityResult.contains(ConnectivityResult.wifi)) {
        autoQuality = '540p';
      } else if (_connectivityResult.contains(ConnectivityResult.mobile)) {
        autoQuality = '360p';
      } else {
        autoQuality = '480p';
      }
      // Pick exact match, else nearest by tier fallback.
      if (_videoUrls.containsKey(autoQuality)) {
        _selectedQuality = autoQuality;
        return;
      }
      const tierFallback = ['480p', '540p', '360p', '720p', '1080p'];
      for (final tier in tierFallback) {
        if (_videoUrls.containsKey(tier)) {
          _selectedQuality = tier;
          return;
        }
      }
      // Last resort: first available rendition
      _selectedQuality = _videoUrls.keys.first;
    } catch (_) {}
  }

  /// Subscribe to connectivity changes so _buildDataSource always uses the
  /// latest network state. We don't rebuild the player on every change (too
  /// disruptive); we just keep the field fresh for the next source swap.
  Future<void> _subscribeConnectivity() async {
    try {
      final initial = await Connectivity().checkConnectivity();
      if (!mounted) return;
      _connectivityResult = initial;
      _connectivitySub = Connectivity()
          .onConnectivityChanged
          .listen((result) {
        if (!mounted) return;
        _connectivityResult = result;
        debugPrint('[PLAYER][NET] connectivity=$result');
      });
    } catch (e) {
      debugPrint('[PLAYER][NET] connectivity subscribe error: $e');
    }
  }

  /// Warm the Bunny CDN edge (DNS + TLS + first segment) with a small Range
  /// GET before the player starts. This shaves ~200-400ms off first-frame
  /// time on cold plays, since the CDN POP is already primed when BetterPlayer
  /// actually requests the playlist/segments.
  ///
  /// Fire-and-forget; any error is ignored (this is pure optimization).
  void _preWarmCdn(String url) {
    if (url.isEmpty) return;
    if (_preWarmedUrl == url) return; // already warmed this session
    _preWarmedUrl = url;
    () async {
      http.Client? client;
      try {
        client = http.Client();
        final req = http.Request('GET', Uri.parse(url));
        req.headers['Range'] = 'bytes=0-65535'; // first 64 KB
        final resp = await client
            .send(req)
            .timeout(const Duration(seconds: 4));
        await resp.stream.drain();
        debugPrint('[PLAYER][WARM] pre-warmed CDN for '
            '${url.substring(0, math.min(60, url.length))}...');
      } catch (e) {
        debugPrint('[PLAYER][WARM] pre-warm skipped: $e');
      } finally {
        client?.close();
      }
    }();
  }

  Future<void> _initializeNotifications() async {
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
      iOS: initializationSettingsDarwin,
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // ── PLAYER RUNTIME STATE ─────────────────────────────────────────────────
  // Player controller is built once in _ensurePlayerBuilt(); subsequent
  // source/quality changes swap via setupDataSource(), never dispose+recreate.
  // That fixes the iOS AVPlayer leak + Android "controller disposed" race.
  bool _playerControllerBuilt = false;
  bool _initialSeekDone = false;
  int _playerErrorRetries = 0;
  Duration? _lastKnownPosition;

  // ── NETWORK-AWARE BUFFER TUNING ──────────────────────────────────────────
  // Updated by _subscribeConnectivity(); used by _buildDataSource() to size
  // player buffers. Bigger buffers on WiFi = YouTube-smooth playback. Tighter
  // buffers on cellular = respects the user's data plan.
  List<ConnectivityResult> _connectivityResult = const [ConnectivityResult.none];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  // Per-download subscription for the current titleId's progress events.
  // Lives for the duration of one download and is cancelled on terminal
  // state OR on dispose — whichever comes first. Guarantees we never retain
  // an orphan listener after the widget is torn down.
  StreamSubscription<DownloadTask>? _taskSub;

  // One-shot pre-warm guard so we don't fire multiple HEAD/Range requests
  // for the same URL during re-renders.
  String? _preWarmedUrl;

  /// Stronger HLS detection that covers Bunny CDN (b-cdn.net /hls/…/playlist.m3u8),
  /// Vimeo manifest URLs, relative m3u8 paths, and `hls`-keyed URLs. The previous
  /// check missed Bunny's hostname-based HLS delivery.
  bool _isHlsUrl(String url) {
    final u = url.toLowerCase();
    if (u.endsWith('.m3u8')) return true;
    if (u.contains('.m3u8?')) return true;
    if (u.contains('/hls/')) return true;
    if (u.contains('master.m3u8')) return true;
    if (u.contains('playlist.m3u8')) return true;
    if (u.contains('/manifest/video')) return true; // Vimeo HLS manifests
    return false;
  }

  /// Builds a BetterPlayerDataSource with platform + network-aware config.
  ///
  /// Buffer sizing strategy:
  ///   WiFi   → aggressive buffers (YouTube-smooth, no rebuffer on 1080p HLS)
  ///   Cell   → tighter buffers (respect data plan, prefer fresh ABR)
  ///   Offline→ small fixed buffers (local file, no network latency)
  ///
  /// iOS AVPlayer caches HLS natively; enabling BetterPlayer's cache layer on
  /// top of that caused the "stuck buffering" / "wrong current time" bugs we
  /// fixed earlier. Android (ExoPlayer) benefits from the cache layer.
  BetterPlayerDataSource _buildDataSource(String path, {required bool isOffline}) {
    if (isOffline) {
      // ── Local-file buffer config ─────────────────────────────────────────
      // Local disk reads are ~100x faster than network. The earlier 15s/30s
      // window was tuned for network and caused noticeable stutter on first
      // frame + unnecessarily large memory footprint. For local files we only
      // need enough buffer to survive a disk hiccup (a few hundred ms).
      // Result: near-instant first-frame, snappy scrubbing, minimal RAM.
      return BetterPlayerDataSource(
        BetterPlayerDataSourceType.file,
        path,
        videoExtension: 'mp4',
        bufferingConfiguration: const BetterPlayerBufferingConfiguration(
          minBufferMs: 500,
          maxBufferMs: 2000,
          bufferForPlaybackMs: 250,
          bufferForPlaybackAfterRebufferMs: 500,
        ),
        notificationConfiguration: isDesktop
            ? null
            : BetterPlayerNotificationConfiguration(
                showNotification: true,
                title: widget.title,
                imageUrl: widget.videoThumbnail ?? "",
                activityName: "MainActivity",
              ),
      );
    }

    final isHls = _isHlsUrl(path);
    final isIOS = !isDesktop && Platform.isIOS;
    final isWifi = _connectivityResult.contains(ConnectivityResult.wifi);
    final isCellular = _connectivityResult.contains(ConnectivityResult.mobile);

    // ── Network-aware buffer window ────────────────────────────────────────
    // Bigger WiFi buffers = smoother playback (YouTube ships ~60-90s on WiFi).
    // Tighter cellular buffers = respects data usage + faster ABR adjustments.
    // iOS AVPlayer manages its own internal buffer, so we keep BetterPlayer's
    // layer moderate to avoid double-buffer contention on iOS.
    final int minBuf;
    final int maxBuf;
    if (isIOS) {
      minBuf = isWifi ? 25000 : (isCellular ? 15000 : 20000);
      maxBuf = isWifi ? 45000 : (isCellular ? 30000 : 35000);
    } else {
      // Android ExoPlayer — Phase 1 optimization target (25s→45s / 60s→90s on WiFi).
      minBuf = isWifi ? 45000 : (isCellular ? 20000 : 25000);
      maxBuf = isWifi ? 90000 : (isCellular ? 45000 : 60000);
    }

    // ── Startup threshold ──────────────────────────────────────────────────
    // Lower bufferForPlaybackMs = faster first-frame. On WiFi we can be more
    // aggressive (1.5s) since the network is fast enough to keep up.
    final int startupMs = isWifi ? 1500 : 2500;
    final int rebufferMs = isWifi ? 3500 : 5000;

    // Parity: Android gets bigger prefetch (ExoPlayer loves it); iOS keeps it
    // lean so AVPlayer's own buffer doesn't fight BetterPlayer's cache.
    final useCache = !isIOS; // disabled on iOS for both HLS and MP4

    // On WiFi allow a bigger cache — lets ExoPlayer hold the adaptive-ladder
    // segments it's already fetched for fast re-seeks (YouTube-style scrubbing).
    final int maxCache = isHls
        ? (isWifi ? 256 * 1024 * 1024 : 150 * 1024 * 1024)
        : (isWifi ? 120 * 1024 * 1024 : 80 * 1024 * 1024);

    final cacheConfig = BetterPlayerCacheConfiguration(
      useCache: useCache,
      preCacheSize: isHls ? 20 * 1024 * 1024 : 10 * 1024 * 1024,
      maxCacheSize: maxCache,
      maxCacheFileSize: isHls ? 40 * 1024 * 1024 : 10 * 1024 * 1024,
      key: '${widget.titleId}_${isHls ? "hls" : _selectedQuality}',
    );

    return BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      path,
      videoFormat: isHls ? BetterPlayerVideoFormat.hls : BetterPlayerVideoFormat.other,
      videoExtension: isHls ? null : 'mp4',
      // Only pass MP4 resolutions to MP4 sources — never to HLS (HLS negotiates
      // its own adaptive ladder; passing resolutions breaks iOS playback).
      resolutions: isHls ? null : (_videoUrls.isEmpty ? null : _videoUrls),
      cacheConfiguration: cacheConfig,
      bufferingConfiguration: BetterPlayerBufferingConfiguration(
        minBufferMs: minBuf,
        maxBufferMs: maxBuf,
        bufferForPlaybackMs: startupMs,
        bufferForPlaybackAfterRebufferMs: rebufferMs,
      ),
      notificationConfiguration: BetterPlayerNotificationConfiguration(
        showNotification: true,
        title: widget.title,
        imageUrl: widget.videoThumbnail ?? "",
        activityName: "MainActivity",
      ),
    );
  }

  Future<void> _initializePlayer(String path,
      {Duration? startAt, bool isOffline = false}) async {
    if (!mounted) return;
    _playerErrorRetries = 0;
    _initialSeekDone = false;

    final dataSource = _buildDataSource(path, isOffline: isOffline);

    // First time: build the controller. After that: just swap the data source.
    if (!_playerControllerBuilt) {
      _betterPlayerController = BetterPlayerController(
        BetterPlayerConfiguration(
          expandToFill: true,
          autoPlay: true,
          looping: false,
          allowedScreenSleep: false,
          controlsConfiguration: const BetterPlayerControlsConfiguration(
            enablePlaybackSpeed: true,
            enableMute: false,
            enableQualities: false,
            enableSubtitles: false,
            enableFullscreen: false,
            enablePip: true,
            pipMenuIcon: Icons.picture_in_picture,
            backgroundColor: Colors.black,
            playIcon: Icons.play_arrow,
            pauseIcon: Icons.pause,
            muteIcon: Icons.volume_up,
            unMuteIcon: Icons.volume_off,
            skipForwardIcon: Icons.forward_10,
            skipBackIcon: Icons.replay_10,
            enableRetry: true,
            overflowMenuIcon: Icons.more_vert,
            progressBarPlayedColor: Colors.red,
            progressBarHandleColor: Colors.red,
            progressBarBufferedColor: Colors.grey,
            progressBarBackgroundColor: Colors.white24,
          ),
          startAt: startAt,
          // On mobile we let BetterPlayer auto-dispose with the widget; on
          // desktop we keep it alive so FlickManager handles the TV-style
          // split-pane layout transitions. We never manually dispose outside
          // of dispose() — that caused the "controller disposed" crash.
          autoDispose: !isDesktop,
          handleLifecycle: !isDesktop,
          errorBuilder: (ctx, errorMessage) => _buildPlayerErrorOverlay(errorMessage),
          eventListener: _betterPlayerEventListener,
        ),
        betterPlayerDataSource: dataSource,
      );
      _playerControllerBuilt = true;

      _betterPlayerController.addEventsListener(_onPlayerEvent);
    } else {
      // Live controller — swap the source and reset init flag.
      if (mounted) setState(() => _isPlayerInitialized = false);
      try {
        await _betterPlayerController.setupDataSource(dataSource);
      } catch (e) {
        debugPrint('[PLAYER] setupDataSource error: $e');
      }
      // Restore the remembered speed on source swap.
      try {
        await _betterPlayerController.setSpeed(_playbackSpeed);
      } catch (_) {}
    }
  }

  /// Single place for player events — drives init flag, initial seek, retry.
  void _onPlayerEvent(BetterPlayerEvent event) {
    switch (event.betterPlayerEventType) {
      case BetterPlayerEventType.initialized:
        if (!mounted) return;
        // Push initial duration from server if VideoPlayerController got zero.
        try {
          final store = Provider.of<VideoCategoryStore>(context, listen: false);
          final videoDetail = store.videotopicdetail;
          final duration = videoDetail.isEmpty ? 0 : (videoDetail[0]?.duration ?? 0);
          if (duration > 0) {
            final vpc = _betterPlayerController.videoPlayerController;
            if (vpc != null) {
              vpc.value = vpc.value.copyWith(duration: Duration(seconds: duration));
            }
          }
        } catch (_) {}

        // Seek to resume point only once per source.
        if (!_initialSeekDone) {
          _initialSeekDone = true;
          final pauseTime = widget.pauseTime;
          if (pauseTime != null && pauseTime.isNotEmpty) {
            seekToChapter(pauseTime);
          } else if (_lastKnownPosition != null) {
            // After quality/source swap: resume from last position.
            _betterPlayerController.seekTo(_lastKnownPosition!);
          }
        }
        // Apply remembered playback speed.
        try {
          _betterPlayerController.setSpeed(_playbackSpeed);
        } catch (_) {}
        break;
      case BetterPlayerEventType.exception:
        debugPrint('[PLAYER] exception event — retry ${_playerErrorRetries + 1}/3');
        _maybeAutoRetry();
        break;
      default:
        break;
    }
  }

  void _maybeAutoRetry() {
    if (_playerErrorRetries >= 3) return;
    _playerErrorRetries++;
    // Remember position before we bounce the source.
    try {
      _lastKnownPosition =
          _betterPlayerController.videoPlayerController?.value.position;
    } catch (_) {}
    final backoffMs = 1500 * _playerErrorRetries;
    Future.delayed(Duration(milliseconds: backoffMs), () {
      if (!mounted) return;
      debugPrint('[PLAYER] auto-retry $_playerErrorRetries');
      _playVideo(widget.titleId.toString());
    });
  }

  Widget _buildPlayerErrorOverlay(String? errorMessage) {
    debugPrint('[PLAYER] error overlay: $errorMessage');
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white54, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Video failed to load',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Check your connection and try again',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _playerErrorRetries = 0;
                    _playVideo(widget.titleId.toString());
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 12),
                if (_videoUrls.length > 1)
                  OutlinedButton(
                    onPressed: () {
                      final lowestQuality = _videoUrls.keys.first;
                      _changeVideoQuality(lowestQuality);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Try Lower Quality',
                        style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchVideoUrl() async {
    final vimeoId = extractVimeoId(widget.videoPlayUrl!);
    if (vimeoId == null || vimeoId.isEmpty) {
      debugPrint('[Desktop] No Vimeo ID found in URL: ${widget.videoPlayUrl}');
      return;
    }

    try {
      // Use server-side proxy to resolve Vimeo URL — keeps API token off client
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? '';
      final proxyUrl = '$baseUrl/video/vimeo-url/$vimeoId';

      final response = await http.get(
        Uri.parse(proxyUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final payload = data['data'] ?? data;
        final videoUrl = (payload['link'] ?? payload['url']) as String?;

        if (videoUrl != null && videoUrl.isNotEmpty) {
          final controller = VideoPlayerController.networkUrl(
            Uri.parse(videoUrl),
          );

          await controller.initialize();
          controller.play();

          setState(() {
            flickManager = FlickManager(
              videoPlayerController: controller,
            );
            isLoading = false;
          });

          controller.addListener(() {
            if (controller.value.isPlaying) {
              controller.removeListener(() {});
              if ((widget.pauseTime?.isNotEmpty ?? false)) {
                if (!isSeekDone) {
                  int totalSeconds =
                      convertTimeStringToSeconds(widget.pauseTime ?? "0");
                  controller.seekTo(Duration(seconds: totalSeconds));
                }
                setState(() {
                  isSeekDone = true;
                });
              }
            }
          });
        } else {
          debugPrint('[Desktop] No video URL in proxy response');
        }
      } else {
        debugPrint('[Desktop] Vimeo proxy failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[Desktop] Error fetching video URL: $e');
    }
  }

  Future<void> _betterPlayerEventListener(BetterPlayerEvent event) async {
    switch (event.betterPlayerEventType) {
      case BetterPlayerEventType.openFullscreen:
        debugPrint("@@@@@ 123 Video openFullscreen");
        break;

      case BetterPlayerEventType.controlsVisible:
        debugPrint("@@@@@ 345 Video controlsVisible");
        break;

      case BetterPlayerEventType.controlsHiddenEnd:
        debugPrint("@@@@@ Video controlsHiddenEnd");
        break;

      case BetterPlayerEventType.pause:
        final pausedPosition =
            _betterPlayerController.videoPlayerController?.value.position;
        if (pausedPosition != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _callApiWithLastWatchedTime(pausedPosition);
            });
          });
        }
        break;
      case BetterPlayerEventType.initialized:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _isPlayerInitialized = true;
          });
        });
        break;
      case BetterPlayerEventType.finished:
        debugPrint("Video playback finished");
        // Async cleanup so we never block the platform main thread (sync
        // file ops on iOS cause "takes too long on the main thread" asserts).
        final tmp = _tempDecryptedFile;
        if (tmp != null) {
          tmp.exists().then((exists) {
            if (exists) {
              tmp.delete().catchError((e) {
                debugPrint('[DEC][CLEANUP] error deleting temp: $e');
                return tmp; // satisfy Future<File> return type
              });
            }
          });
        }
        break;
      default:
        break;
    }
  }

  Future<void> initializePlayerWithAPIResponse(
      List<Map<String, dynamic>> apiFiles) async {
    _videoUrls.clear();
    _qualityAndSize.clear();
    for (var file in apiFiles) {
      String rendition = file["rendition"];
      String quality = file["quality"];
      String size = file["size_short"];
      String link = file["link"];
      _videoUrls[rendition] = link;
      _qualityAndSize["${quality.toUpperCase()} $rendition"] = " $size";
    }
  }

  Future<void> initializeDownload(List<Map<String, dynamic>> apiFiles) async {
    _qualityAndSize.clear();
    for (var file in apiFiles) {
      String rendition = file["rendition"];
      String quality = file["quality"];
      String size = file["size_short"];
      String link = file["link"];
      downloadUrl = link;
      _qualityAndSize["${quality.toUpperCase()} $rendition"] = " $size";
    }
  }

  /// Swap quality by calling setupDataSource on the LIVE controller — no
  /// dispose, no recreate. The previous dispose+recreate sequence was the
  /// source of the "black screen on quality change" and "controller already
  /// disposed" crashes on iOS. Remembered position is seeked to on the
  /// initialized event of the new source.
  void _changeVideoQuality(String quality) async {
    if (!_videoUrls.containsKey(quality)) return;
    if (!_playerControllerBuilt) {
      // First-time init (edge case if user taps quality before source loaded)
      setState(() => _selectedQuality = quality);
      await _initializePlayer(_videoUrls[quality]!);
      return;
    }
    try {
      _lastKnownPosition =
          _betterPlayerController.videoPlayerController?.value.position;
      await _betterPlayerController.pause();
    } catch (_) {}
    setState(() => _selectedQuality = quality);
    await _initializePlayer(_videoUrls[quality]!, startAt: _lastKnownPosition);
  }

  /// Auto-play toggle just flips state; we don't need to rebuild the source
  /// (BetterPlayer doesn't have a live autoPlay setter, but the value only
  /// matters on the NEXT source load — so deferring is correct).
  Future<void> _changeAutoPlay(bool value) async {
    setState(() => _autoPlay = value);
  }

  void _changePlaybackSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });
    if (_playerControllerBuilt) {
      try {
        _betterPlayerController.setSpeed(speed);
      } catch (e) {
        debugPrint('[PLAYER] setSpeed failed: $e');
      }
    }
    // Persist so next video opens at same speed
    SharedPreferences.getInstance().then((prefs) {
      prefs.setDouble('video_playback_speed', speed);
    });
  }

  void _changeSeekTime(int time) {
    setState(() {
      _seekTime = time;
    });
  }

  Duration getCurrentPlayedDuration() {
    if (flickManager != null &&
        flickManager!.flickVideoManager != null &&
        flickManager!
            .flickVideoManager!.videoPlayerController!.value.isInitialized) {
      return flickManager!
          .flickVideoManager!.videoPlayerController!.value.position;
    }
    return Duration(seconds: 0); // Default if video is not initialized
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _videoStore = Provider.of<VideoCategoryStore>(context, listen: false);
  }

  @override
  void dispose() {
    // Capture last watched position safely — desktop uses FlickManager,
    // mobile uses BetterPlayer; either may have never initialized.
    Duration? lastWatchedTime;
    try {
      lastWatchedTime = isDesktop
          ? getCurrentPlayedDuration()
          : (_playerControllerBuilt
              ? _betterPlayerController.videoPlayerController?.value.position
              : null);
    } catch (_) {
      lastWatchedTime = null;
    }
    if (lastWatchedTime != null) {
      // Fire-and-forget; do not await inside dispose
      _callApiWithLastWatchedTime(lastWatchedTime);
    }

    // Async cleanup of decrypted temp file — never block the main thread.
    final tmp = _tempDecryptedFile;
    if (tmp != null) {
      tmp.exists().then((exists) {
        if (exists) {
          tmp.delete().catchError((e) {
            debugPrint('[DEC][CLEANUP] error deleting temp: $e');
            return tmp;
          });
        }
      });
    }

    // Cancel connectivity subscription — leaving it active would leak the
    // stream controller after the screen is gone.
    try {
      _connectivitySub?.cancel();
    } catch (_) {}
    _connectivitySub = null;

    try {
      _taskSub?.cancel();
    } catch (_) {}
    _taskSub = null;

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _getVideoDetailList();
    // _getAllVideoDetailList();
    // _getFeaturedContent();
    _createVideoNoteHistory();
  }

  List<Map<String, dynamic>> filesToMapList(List<Files>? files) {
    if (files == null) return [];
    return files.map((file) {
      return {
        "rendition": file.rendition,
        "quality": file.quality,
        "link": file.link,
        "size_short": file.videoSize,
      };
    }).toList();
  }

  List<Map<String, dynamic>> downloadToMapList(List<Download>? files) {
    if (files == null) return [];
    return files.map((file) {
      return {
        "rendition": file.rendition,
        "quality": file.quality,
        "link": file.link,
        "size_short": file.videoSize,
      };
    }).toList();
  }

  Future<void> _getVideoDetailList() async {
    // Phase 1: start video playback ASAP — do NOT wait for topic-detail API.
    // The video URL already comes from widget props (hlsLink + videoQuality);
    // the topic-detail API is only needed for the chapterization sidebar,
    // which can load in parallel without blocking first-frame.
    //
    // This cuts the "tap → first frame" time by ~500-1000ms on cold opens,
    // since we no longer wait for an API round-trip before building the
    // player controller.
    await initializePlayerWithAPIResponse(filesToMapList(widget.videoQuality));

    // Pick startup quality AFTER URLs are known (initState call earlier ran
    // with an empty map and silently no-oped). Favors 480p-540p for faster
    // first-frame; HLS ABR will ramp to higher tiers once the buffer fills.
    await _autoSelectQuality();

    // If no HLS, pre-warm the chosen MP4 URL (DNS + TLS + first bytes) so
    // first-frame time is as close to HLS start as we can get.
    if ((widget.hlsLink == null || widget.hlsLink!.isEmpty) &&
        !isDesktop &&
        _videoUrls.containsKey(_selectedQuality)) {
      _preWarmCdn(_videoUrls[_selectedQuality]!);
    }

    // Kick off playback now — everything else below runs in parallel.
    _playVideo(widget.titleId.toString() ?? "");

    // Fire-and-forget the download catalog init (not required for playback).
    initializeDownload(downloadToMapList(widget.downloadVideoData));

    // Topic detail + chapter list load in parallel; sidebar populates when
    // ready. If this fails, the video still plays — sidebar just stays empty.
    final store = Provider.of<VideoCategoryStore>(context, listen: false);
    store.onTopicDetailApiCall(widget.contentId ?? "").then((_) {
      if (!mounted) return;
      final videoId = store.videotopicdetail.isNotEmpty
          ? (store.videotopicdetail[0]?.videoUrl ?? "")
          : "";
      if (videoId.isNotEmpty) {
        _getVideoChaptersDetailList(videoId);
      }
    }).catchError((e) {
      debugPrint('[PLAYER] topic-detail fetch failed: $e');
    });
  }

  Future<void> _getVideoChaptersDetailList(String videoId) async {
    final store = Provider.of<VideoCategoryStore>(context, listen: false);
    await store.onVideoChapterizationDetailApiCall(videoId);
  }

  Future<void> _getFeaturedContent() async {
    final store = Provider.of<HomeStore>(context, listen: false);
    await store.onGetFeaturedListApiCall(context);
  }

  Future<void> _createVideoNoteHistory() async {
    final store = Provider.of<HomeStore>(context, listen: false);
    await store.onCreateVideoNoteHistoryCall(widget.contentId ?? '', 'video');
  }

  Future<void> _createVideoHistory() async {
    final store = Provider.of<VideoCategoryStore>(context, listen: false);
    await store.onCreateVideoHistoryApiCall(widget.contentId ?? '');
  }

  Future<void> _putBookMarkApiCall() async {
    final store = Provider.of<VideoCategoryStore>(context, listen: false);
    await store.onCreateBookmarkContentApiCall(widget.contentId ?? '');
  }

  // Future<void> _getAllVideoDetailList() async {
  //   final store = Provider.of<VideoCategoryStore>(context, listen: false);
  //   await store.onAllVideoTopicDetailApiCall(widget.contentId ?? "");
  //   if (store.allvideotopicdetail.value?.message == null) {
  //     setState(() {
  //       tabIndex = 3;
  //     });
  //   }
  // }

  int convertTimeStringToSeconds(String timeString) {
    List<String> parts = timeString.split(':');
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);
    int seconds = int.parse(parts[2]);

    return (hours * 3600) + (minutes * 60) + seconds;
  }

  void seekToChapter(String? timeString) {
    if (timeString == null || timeString.isEmpty) {
      debugPrint('[SEEK] invalid time string');
      return;
    }
    if (!_playerControllerBuilt) return;
    try {
      final totalSeconds = convertTimeStringToSeconds(timeString);
      _betterPlayerController.seekTo(Duration(seconds: totalSeconds));
    } catch (e) {
      debugPrint('[SEEK] failed: $e');
    }
  }

  Future<void> _callApiWithLastWatchedTime(Duration lastWatchedTime) async {
    final formattedTime = remainTimeDuration(lastWatchedTime);
    // debugPrint("pauseTime$formattedTime");
    if (widget.isCompleted == false) {
      await _videoStore.onVideoProgressApiCall(
          widget.contentId ?? "", formattedTime, 0);
    }
  }

  /// Picture-in-Picture — gated by init state and native support. iOS needs
  /// AVAudioSession + playsInline from native side (already in Runner config),
  /// Android needs activity's android:supportsPictureInPicture="true".
  void _togglePipMode() async {
    if (!_playerControllerBuilt) return;
    try {
      final supported =
          await _betterPlayerController.isPictureInPictureSupported();
      if (supported != true) {
        debugPrint('[PIP] not supported on this device');
        return;
      }
      setState(() => _isInPipMode = !_isInPipMode);
      await _betterPlayerController.enablePictureInPicture(_betterPlayerKey);
    } catch (e) {
      debugPrint('[PIP] toggle failed: $e');
    }
  }

  String? extractVimeoId(String url) {
    RegExp regex = RegExp(r'playback\/(\d+)\/');
    Match? match = regex.firstMatch(url);
    return match != null ? match.group(1) : null;
  }

  void seekToChapterMac(int seconds) {
    if (flickManager != null &&
        flickManager!.flickVideoManager != null &&
        flickManager!
            .flickVideoManager!.videoPlayerController!.value.isInitialized) {
      flickManager!.flickVideoManager!.videoPlayerController!
          .seekTo(Duration(seconds: seconds));
    }
  }

  Future<void> _toggleFullScreen() async {
    setState(() {
      isFullScreen = !isFullScreen;
    });

    if (isFullScreen) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.portraitUp,
      ]);

      if (!(Platform.isWindows || Platform.isMacOS)) {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<VideoCategoryStore>(context, listen: false);
    final homeStore = Provider.of<HomeStore>(context, listen: false);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // final overlayScreen = OverlayScreen.of(context);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) return;
        Duration? lastWatchedTime;
        try {
          lastWatchedTime = isDesktop
              ? getCurrentPlayedDuration()
              : (_playerControllerBuilt
                  ? _betterPlayerController.videoPlayerController?.value.position
                  : null);
        } catch (_) {}
        if (lastWatchedTime != null) {
          _callApiWithLastWatchedTime(lastWatchedTime);
        }
        // Async cleanup of decrypted temp — never block the main thread.
        final tmp = _tempDecryptedFile;
        if (tmp != null) {
          tmp.exists().then((exists) {
            if (exists) tmp.delete().catchError((e) { return tmp; });
          });
        }
      },
      child: DefaultTabController(
        length: tabIndex,
        child: SafeArea(
          child: Scaffold(
            key: _scaffoldKey,
            // Bookmark FAB — lets the user capture the current playback
            // position with an optional label, and (via speed-dial-like long
            // press) reopens the bookmarks list. Hidden in fullscreen so it
            // doesn't obscure the video. Only renders once the controller is
            // built to avoid NPEs when reading .value.position.
            floatingActionButton: (!isFullScreen &&
                    _playerControllerBuilt &&
                    (widget.contentId ?? '').isNotEmpty)
                ? _VideoBookmarkFabCluster(
                    contentId: widget.contentId!,
                    getPosition: () {
                      try {
                        return _betterPlayerController
                                .videoPlayerController?.value.position ??
                            Duration.zero;
                      } catch (_) {
                        return Duration.zero;
                      }
                    },
                    onSeek: (seconds) {
                      try {
                        _betterPlayerController
                            .seekTo(Duration(seconds: seconds));
                      } catch (e) {
                        debugPrint('[Bookmark] seek failed: $e');
                      }
                    },
                  )
                : null,
            backgroundColor:
                isFullScreen ? ThemeManager.black : AppTokens.scaffold(context),
            body: OrientationBuilder(
              builder: (BuildContext context, Orientation orientation) {
                return Observer(
                  builder: (BuildContext context) {
                    final isDownloading =
                        store.isDownloading(widget.titleId ?? "");
                    final progress =
                        store.getDownloadProgress(widget.titleId ?? "");

                    isFeaturedVideoExist =
                        (homeStore.featuredContent.value?.video?.isNotEmpty ??
                            false);
                    bool isLandscape = orientation == Orientation.landscape;

                    // Adjust videoHeight calculation:
                    // When in full screen, it should take up the whole screen.
                    // When not in full screen, use your original logic.
                    double videoHeight;
                    if (isFullScreen) {
                      videoHeight = MediaQuery.of(context).size.height;
                    } else {
                      videoHeight = isLandscape
                          ? (Platform.isWindows || Platform.isMacOS)
                              ? MediaQuery.of(context).size.height *
                                  0.5 // Keep a reasonable size for desktop when not full screen
                              : MediaQuery.of(context).size.height *
                                  0.5 // Or adjust as needed for mobile landscape
                          : MediaQuery.of(context).size.height * 0.27;
                    }
                    List<VideoTopicDetailModel?>? videoDetail =
                        store.videotopicdetail;
                    log(widget.videoPlayUrl!);
                    String videoUrl = videoDetail.isEmpty
                        ? ""
                        : videoDetail[0]?.videoUrl ?? "";

                    videoUrl =
                        store.videoQualityDetail.value?.files?[0].link ?? "";

                    topicName =
                        videoDetail.isEmpty ? "" : videoDetail[0]?.title ?? "";
                    duration =
                        videoDetail.isEmpty ? 0 : videoDetail[0]?.duration ?? 0;
                    topicDesc = videoDetail.isEmpty
                        ? ""
                        : videoDetail[0]?.description ?? "";
                    if (videoDetail.isNotEmpty && videoDetail[0] != null) {
                      // contentUrl = videoDetail[0]!.pdfcontents ?? "";
                    }

                    List<VideoTopicDetailModel?>? filteredTopics =
                        store.videotopicdetail;
                    if (videoDetail.isNotEmpty && videoDetail[0] != null) {
                      filteredTopics = videoDetail
                          .where(
                              (topic) => topic?.title != videoDetail[0]!.title)
                          .toList();
                    }
                    if (isFullScreen) {
                      return SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        child: (Platform.isWindows || Platform.isMacOS)
                            ? isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : FlickVideoPlayer(flickManager: flickManager!)
                            : _isPlayerInitialized
                            ? Stack(
                          children: [
                            /// BetterPlayer: full screen
                            Positioned.fill(
                              child: BetterPlayer(
                                controller: _betterPlayerController,
                                key: _betterPlayerKey,
                              ),
                            ),

                            /// Decrypt overlay — sits above the player while
                            /// AES-GCM is streaming a .enc file to disk.
                            /// Without this overlay a user tapping an offline
                            /// video sees a black player rectangle for 3–15 s
                            /// and assumes the app crashed.
                            if (_isDecrypting)
                              Positioned.fill(child: _buildDecryptOverlay()),

                            /// Back Button (top-left)
                            Positioned(
                              top: 24,
                              left: 16,
                              child: GestureDetector(
                                onTap: () async {
                                  setState(() {
                                    isFullScreen = false;
                                  });
                                  await SystemChrome.setPreferredOrientations([
                                    DeviceOrientation.portraitUp,
                                    DeviceOrientation.portraitDown,
                                  ]);
                                  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  child: const Text(
                                    "Back",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                            : Stack(
                                children: [
                                  const Center(child: CircularProgressIndicator()),
                                  if (_isDecrypting)
                                    Positioned.fill(child: _buildDecryptOverlay()),
                                ],
                              ),
                      );
                    }
                    else {
                      return (Platform.isWindows || Platform.isMacOS)
                          ? Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    //video player
                                    Stack(
                                      children: [
                                        Container(
                                          color: AppColors.black,
                                          child: Container(
                                              width: isDesktop
                                                  ? MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      .5
                                                  : MediaQuery.of(context)
                                                      .size
                                                      .width,
                                              height: videoHeight,
                                              // Use the adjusted videoHeight here
                                              color: isDesktop
                                                  ? Colors.black
                                                  : ThemeManager.black,
                                              padding: EdgeInsets.zero,
                                              margin: EdgeInsets.zero,
                                              child: isLoading
                                                  ? const Center(
                                                      child:
                                                          CircularProgressIndicator())
                                                  : FlickVideoPlayer(
                                                      flickManager:
                                                          flickManager!)),
                                        ),
                                        Positioned(
                                          top: 50,
                                          left: 20,
                                          child: Visibility(
                                            visible: true,
                                            child: GestureDetector(
                                              onTap: () async {
                                                final lastWatchedTime = isDesktop
                                                    ? getCurrentPlayedDuration()
                                                    : _betterPlayerController
                                                        .videoPlayerController
                                                        ?.value
                                                        .position;
                                                await _callApiWithLastWatchedTime(
                                                    lastWatchedTime!);

                                                if (!isDesktop) {
                                                  _betterPlayerController
                                                      .dispose();
                                                }

                                                final notesViewerState =
                                                    _notesViewerKey
                                                        .currentState;
                                                await notesViewerState!
                                                    .saveLastPageToBackend();
                                                await notesViewerState
                                                    .exportAndSaveAnnotations();

                                                Navigator.pop(context);
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.5),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  "Back",
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Expanded(
                                      // Wrap the remaining content in an Expanded widget
                                      child:
                                          store.isLoading &&
                                                  store.isLoadingChapter
                                              ? const Padding(
                                                  padding:
                                                      EdgeInsets.only(top: 10),
                                                  child: Center(
                                                      child:
                                                          CircularProgressIndicator()),
                                                )
                                              : SizedBox(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      .5,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      // ... (Rest of your content below the video player for desktop)
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Container(
                                                            padding: const EdgeInsets
                                                                .only(
                                                                top: Dimensions
                                                                        .PADDING_SIZE_LARGE *
                                                                    0.5,
                                                                left: Dimensions
                                                                        .PADDING_SIZE_LARGE *
                                                                    1.2),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                SizedBox(
                                                                  width: Dimensions
                                                                          .PADDING_SIZE_EXTRA_LARGE *
                                                                      9,
                                                                  child: Text(
                                                                    topicName,
                                                                    style: interRegular
                                                                        .copyWith(
                                                                      fontSize:
                                                                          Dimensions
                                                                              .fontSizeDefault,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      color: ThemeManager
                                                                          .black,
                                                                    ),
                                                                  ),
                                                                ),
                                                                Text(
                                                                  formatVideoTime(
                                                                      duration),
                                                                  style: interRegular
                                                                      .copyWith(
                                                                    fontSize:
                                                                        Dimensions
                                                                            .fontSizeSmall,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    color:
                                                                        ThemeManager
                                                                            .grey,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          InkWell(
                                                            onTap: () {
                                                              if (!isDownloading) {
                                                                _showQualityOptions();
                                                              }
                                                            },
                                                            child: Row(
                                                              children: [
                                                                if (downloadProgress ==
                                                                        0 ||
                                                                    downloadProgress ==
                                                                        100)
                                                                  Padding(
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        right:
                                                                            5),
                                                                    child: Icon(
                                                                      isOfflineMode ||
                                                                              isDownloaded
                                                                          ? Icons
                                                                              .check_circle
                                                                          : Icons
                                                                              .download_for_offline_outlined,
                                                                      color: isOfflineMode ||
                                                                              isDownloaded
                                                                          ? Colors
                                                                              .green
                                                                          : ThemeManager
                                                                              .primaryColor,
                                                                    ),
                                                                  ),
                                                                if (isDownloading)
                                                                  Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            8.0),
                                                                    child:
                                                                        Stack(
                                                                      alignment:
                                                                          Alignment
                                                                              .center,
                                                                      children: [
                                                                        CircularProgressIndicator(
                                                                          color:
                                                                              ThemeManager.primaryColor,
                                                                          value:
                                                                              progress / 100,
                                                                        ),
                                                                        Text(
                                                                          "${progress.toInt()}%",
                                                                          style:
                                                                              TextStyle(
                                                                            fontSize:
                                                                                12,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color:
                                                                                ThemeManager.primaryColor,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  )
                                                                else
                                                                  Text(
                                                                    isDownloaded ||
                                                                            isOfflineMode
                                                                        ? "Downloaded"
                                                                        : "Download",
                                                                    style: interRegular
                                                                        .copyWith(
                                                                      fontSize:
                                                                          Dimensions
                                                                              .fontSizeExtraSmall,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      color: isOfflineMode
                                                                          ? Colors
                                                                              .green
                                                                          : ThemeManager
                                                                              .blackColor,
                                                                    ),
                                                                  ),
                                                              ],
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: Dimensions
                                                                  .PADDING_SIZE_DEFAULT),
                                                        ],
                                                      ),
                                                      const Divider(),
                                                      const SizedBox(
                                                          height: Dimensions
                                                              .PADDING_SIZE_EXTRA_SMALL),
                                                      Row(
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceAround,
                                                            children: [
                                                              const SizedBox(
                                                                  width: Dimensions
                                                                      .PADDING_SIZE_DEFAULT),
                                                              InkWell(
                                                                onTap: () =>
                                                                    setState(() =>
                                                                        selectedIndex =
                                                                            0),
                                                                child: Column(
                                                                  children: [
                                                                    Icon(
                                                                        CupertinoIcons
                                                                            .book,
                                                                        size:
                                                                            24,
                                                                        color: selectedIndex ==
                                                                                0
                                                                            ? ThemeManager.primaryColor
                                                                            : ThemeManager.blackColor),
                                                                    Text(
                                                                      "Chapters",
                                                                      style: interRegular
                                                                          .copyWith(
                                                                        fontSize:
                                                                            Dimensions.fontSizeExtraSmall,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                        color: selectedIndex ==
                                                                                0
                                                                            ? ThemeManager.primaryColor
                                                                            : ThemeManager.blackColor,
                                                                      ),
                                                                    )
                                                                  ],
                                                                ),
                                                              ),
                                                              if (!isWindows()) ...[
                                                                const SizedBox(
                                                                    width: Dimensions
                                                                        .PADDING_SIZE_DEFAULT),
                                                                InkWell(
                                                                  onTap: () =>
                                                                      setState(() =>
                                                                          selectedIndex =
                                                                              1),
                                                                  child: Column(
                                                                    children: [
                                                                      Icon(
                                                                          CupertinoIcons
                                                                              .doc_text,
                                                                          size:
                                                                              25,
                                                                          color: selectedIndex == 1
                                                                              ? ThemeManager.primaryColor
                                                                              : ThemeManager.blackColor),
                                                                      Text(
                                                                        "Notes",
                                                                        style: interRegular
                                                                            .copyWith(
                                                                          fontSize:
                                                                              Dimensions.fontSizeExtraSmall,
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                          color: selectedIndex == 1
                                                                              ? ThemeManager.primaryColor
                                                                              : ThemeManager.blackColor,
                                                                        ),
                                                                      )
                                                                    ],
                                                                  ),
                                                                ),
                                                              ],
                                                              const SizedBox(
                                                                  width: Dimensions
                                                                      .PADDING_SIZE_DEFAULT),
                                                              InkWell(
                                                                onTap: () {
                                                                  setState(() {
                                                                    isMarkCompleted =
                                                                        !isMarkCompleted;
                                                                  });
                                                                  _createVideoHistory();
                                                                },
                                                                child: Column(
                                                                  children: [
                                                                    Icon(
                                                                        Icons
                                                                            .check_circle_outline,
                                                                        color: isMarkCompleted ==
                                                                                true
                                                                            ? Colors
                                                                                .green
                                                                            : ThemeManager
                                                                                .blackColor,
                                                                        size:
                                                                            24),
                                                                    Text(
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                      isMarkCompleted ==
                                                                              true
                                                                          ? "Completed"
                                                                          : "Complete",
                                                                      style: interRegular
                                                                          .copyWith(
                                                                        fontSize:
                                                                            Dimensions.fontSizeExtraSmall,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                        color: isMarkCompleted ==
                                                                                true
                                                                            ? Colors.green
                                                                            : ThemeManager.blackColor,
                                                                      ),
                                                                    )
                                                                  ],
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  width: Dimensions
                                                                      .PADDING_SIZE_DEFAULT),
                                                              InkWell(
                                                                onTap: () {
                                                                  setState(() {
                                                                    isBookmarkedDone =
                                                                        !isBookmarkedDone;
                                                                  });
                                                                  _putBookMarkApiCall();
                                                                },
                                                                child: Column(
                                                                  children: [
                                                                    Icon(
                                                                      isBookmarkedDone ==
                                                                              true
                                                                          ? Icons
                                                                              .bookmark
                                                                          : Icons
                                                                              .bookmark_border,
                                                                      color: isBookmarkedDone ==
                                                                              true
                                                                          ? ThemeManager
                                                                              .primaryColor
                                                                          : ThemeManager
                                                                              .blackColor,
                                                                      size: 24,
                                                                    ),
                                                                    Text(
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                      isBookmarkedDone ==
                                                                              true
                                                                          ? "Bookmarked"
                                                                          : "Bookmark",
                                                                      style: interRegular
                                                                          .copyWith(
                                                                        fontSize:
                                                                            Dimensions.fontSizeExtraSmall,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                        color: isBookmarkedDone ==
                                                                                true
                                                                            ? ThemeManager.primaryColor
                                                                            : ThemeManager.blackColor,
                                                                      ),
                                                                    )
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                          height: Dimensions
                                                              .PADDING_SIZE_DEFAULT),
                                                      SizedBox(
                                                        width: MediaQuery.of(
                                                                context)
                                                            .size
                                                            .width,
                                                        height: 1,
                                                        child: Container(
                                                          color:
                                                              AppColors.divider,
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Container(
                                                          color: ThemeManager
                                                                      .currentTheme ==
                                                                  AppTheme.Light
                                                              ? ThemeManager
                                                                  .backgroundGrey
                                                              : ThemeManager
                                                                  .white,
                                                          child: IndexedStack(
                                                            index:
                                                                selectedIndex,
                                                            children: [
                                                              Column(
                                                                children: [
                                                                  Expanded(
                                                                    child: ListView
                                                                        .builder(
                                                                      itemCount: store
                                                                          .videoChapterizationList
                                                                          .length,
                                                                      shrinkWrap:
                                                                          true,
                                                                      padding:
                                                                          EdgeInsets
                                                                              .zero,
                                                                      physics:
                                                                          const AlwaysScrollableScrollPhysics(),
                                                                      itemBuilder:
                                                                          (BuildContext context,
                                                                              int index) {
                                                                        return _buildItem1(
                                                                            context,
                                                                            index);
                                                                      },
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              Stack(
                                                                children: [
                                                                  Center(
                                                                    child:
                                                                        Container(
                                                                      constraints:
                                                                          const BoxConstraints(
                                                                              maxWidth: 900),
                                                                      child:
                                                                          NotesViewer(
                                                                        key:
                                                                            _notesViewerKeySecondary,
                                                                        pdfUrl: pdfBaseUrl +
                                                                            pdfUrl,
                                                                        titleId: widget
                                                                            .pdfId!
                                                                            .toString(),
                                                                        initialAnnotationJson:
                                                                            jsonEncode(widget.annotationData),
                                                                        initialPage:
                                                                            0,
                                                                        isFromNormal:
                                                                            false,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.5,
                                  child: NotesViewer(
                                    key: _notesViewerKey,
                                    pdfUrl: pdfBaseUrl + pdfUrl,
                                    titleId: widget.pdfId!.toString(),
                                    initialAnnotationJson:
                                        jsonEncode(widget.annotationData),
                                    initialPage: 0,
                                    isFromNormal: false,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                //video player
                                Stack(
                                  children: [
                                    Container(
                                      color: ThemeManager.black,
                                      padding: EdgeInsets.zero,
                                      margin: EdgeInsets.zero,
                                      width: !isDesktop
                                          ? MediaQuery.of(context).size.width
                                          : isDesktop
                                              ? MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  .4
                                              : null,
                                      height: videoHeight,
                                      // Use the adjusted videoHeight here
                                      child: _isPlayerInitialized
                                          ? AspectRatio(
                                              aspectRatio: 16 / 9,
                                              child: BetterPlayer(
                                                controller:
                                                    _betterPlayerController,
                                                key: _betterPlayerKey,
                                              ),
                                            )
                                          : const Center(
                                              child:
                                                  CircularProgressIndicator()),
                                    ),
                                    // Decrypt-in-progress overlay. Sits inside
                                    // the same Stack as the player so it
                                    // overlays the BetterPlayer widget while
                                    // AES-GCM streams the .enc file to disk.
                                    if (_isDecrypting)
                                      Positioned.fill(
                                        child: AspectRatio(
                                          aspectRatio: 16 / 9,
                                          child: _buildDecryptOverlay(),
                                        ),
                                      ),
                                    Positioned(
                                      top: Platform.isIOS ? null : 10,
                                      right: 22,
                                      bottom: Platform.isIOS
                                          ? MediaQuery.of(context).size.height /
                                              3
                                          : null,
                                      child: IconButton(
                                        onPressed: _togglePipMode,
                                        icon: const Icon(
                                            Icons.picture_in_picture,
                                            color: AppColors.white,
                                            size: 25),
                                      ),
                                    ),
                                    Positioned(
                                      left: 20,
                                      top: 13,
                                      child: GestureDetector(
                                        onTap: () async {
                                          final lastWatchedTime = isDesktop
                                              ? getCurrentPlayedDuration()
                                              : _betterPlayerController
                                                  .videoPlayerController
                                                  ?.value
                                                  .position;
                                          await _callApiWithLastWatchedTime(
                                              lastWatchedTime!);

                                          final notesViewerState =
                                              _notesViewerKey.currentState;
                                          await notesViewerState!
                                              .saveLastPageToBackend();
                                          await notesViewerState!
                                              .exportAndSaveAnnotations();
                                          // BetterPlayer's autoDispose handles teardown on
                                          // mobile; on desktop we use FlickManager so there's
                                          // no BetterPlayer controller to release here. The
                                          // explicit dispose() call was double-disposing on
                                          // mobile (→ "controller disposed" crash).
                                          Navigator.pop(context);
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              color: Colors.white
                                                  .withOpacity(0.1)),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            child: Text(
                                              "Back",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 60,
                                      top: 19,
                                      child: GestureDetector(
                                        onTap: () async {
                                          setState(() {
                                            isFullScreen = !isFullScreen;
                                          });

                                          if (isFullScreen) {
                                            await SystemChrome
                                                .setPreferredOrientations([
                                              DeviceOrientation.landscapeRight,
                                              DeviceOrientation.landscapeLeft,
                                            ]);
                                          } else {
                                            await SystemChrome
                                                .setPreferredOrientations([
                                              DeviceOrientation.portraitUp,
                                              DeviceOrientation.portraitDown,
                                              DeviceOrientation.landscapeRight,
                                              DeviceOrientation.landscapeLeft,
                                            ]);
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          child: isFullScreen
                                              ? const Icon(
                                                  Icons.fullscreen_exit,
                                                  color: AppColors.white,
                                                  size: 25)
                                              : const Icon(Icons.fullscreen,
                                                  color: AppColors.white,
                                                  size: 25),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Expanded(
                                  // Wrap the remaining content in an Expanded widget
                                  child: store.isLoading &&
                                          store.isLoadingChapter
                                      ? const Padding(
                                          padding: EdgeInsets.only(top: 10),
                                          child: Center(
                                              child:
                                                  CircularProgressIndicator()),
                                        )
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // ... (Rest of your content below the video player for mobile)
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets
                                                      .only(
                                                      top: Dimensions
                                                              .PADDING_SIZE_LARGE *
                                                          0.5,
                                                      left: Dimensions
                                                              .PADDING_SIZE_LARGE *
                                                          1.2),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      SizedBox(
                                                        width: Dimensions
                                                                .PADDING_SIZE_EXTRA_LARGE *
                                                            9,
                                                        child: Text(
                                                          topicName,
                                                          style: interRegular
                                                              .copyWith(
                                                            fontSize: Dimensions
                                                                .fontSizeDefault,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: ThemeManager
                                                                .black,
                                                          ),
                                                        ),
                                                      ),
                                                      Text(
                                                        formatVideoTime(
                                                            duration),
                                                        style: interRegular
                                                            .copyWith(
                                                          fontSize: Dimensions
                                                              .fontSizeSmall,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color:
                                                              ThemeManager.grey,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    if (!isDownloading) {
                                                      _showQualityOptions();
                                                    }
                                                  },
                                                  child: Row(
                                                    children: [
                                                      if (downloadProgress ==
                                                              0 ||
                                                          downloadProgress ==
                                                              100)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  right: 5),
                                                          child: Icon(
                                                            isOfflineMode ||
                                                                    isDownloaded
                                                                ? Icons
                                                                    .check_circle
                                                                : Icons
                                                                    .download_for_offline_outlined,
                                                            color: isOfflineMode ||
                                                                    isDownloaded
                                                                ? Colors.green
                                                                : ThemeManager
                                                                    .primaryColor,
                                                          ),
                                                        ),
                                                      if (isDownloading)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          child: Stack(
                                                            alignment: Alignment
                                                                .center,
                                                            children: [
                                                              CircularProgressIndicator(
                                                                color: ThemeManager
                                                                    .primaryColor,
                                                                value:
                                                                    progress /
                                                                        100,
                                                              ),
                                                              Text(
                                                                "${progress.toInt()}%",
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: ThemeManager
                                                                      .primaryColor,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        )
                                                      else
                                                        Text(
                                                          isDownloaded ||
                                                                  isOfflineMode
                                                              ? "Downloaded"
                                                              : "Download",
                                                          style: interRegular
                                                              .copyWith(
                                                            fontSize: Dimensions
                                                                .fontSizeExtraSmall,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: isOfflineMode
                                                                ? Colors.green
                                                                : ThemeManager
                                                                    .blackColor,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(
                                                    width: Dimensions
                                                        .PADDING_SIZE_DEFAULT),
                                              ],
                                            ),
                                            const Divider(),
                                            const SizedBox(
                                                height: Dimensions
                                                    .PADDING_SIZE_EXTRA_SMALL),
                                            Row(
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceAround,
                                                  children: [
                                                    const SizedBox(
                                                        width: Dimensions
                                                            .PADDING_SIZE_DEFAULT),
                                                    InkWell(
                                                      onTap: () => setState(
                                                          () => selectedIndex =
                                                              0),
                                                      child: Column(
                                                        children: [
                                                          Icon(
                                                              CupertinoIcons
                                                                  .book,
                                                              size: 24,
                                                              color: selectedIndex ==
                                                                      0
                                                                  ? ThemeManager
                                                                      .primaryColor
                                                                  : ThemeManager
                                                                      .blackColor),
                                                          Text(
                                                            "Chapters",
                                                            style: interRegular
                                                                .copyWith(
                                                              fontSize: Dimensions
                                                                  .fontSizeExtraSmall,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: selectedIndex ==
                                                                      0
                                                                  ? ThemeManager
                                                                      .primaryColor
                                                                  : ThemeManager
                                                                      .blackColor,
                                                            ),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        width: Dimensions
                                                            .PADDING_SIZE_DEFAULT),
                                                    InkWell(
                                                      onTap: () => setState(
                                                          () => selectedIndex =
                                                              1),
                                                      child: Column(
                                                        children: [
                                                          Icon(
                                                              CupertinoIcons
                                                                  .doc_text,
                                                              size: 25,
                                                              color: selectedIndex ==
                                                                      1
                                                                  ? ThemeManager
                                                                      .primaryColor
                                                                  : ThemeManager
                                                                      .blackColor),
                                                          Text(
                                                            "Notes",
                                                            style: interRegular
                                                                .copyWith(
                                                              fontSize: Dimensions
                                                                  .fontSizeExtraSmall,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: selectedIndex ==
                                                                      1
                                                                  ? ThemeManager
                                                                      .primaryColor
                                                                  : ThemeManager
                                                                      .blackColor,
                                                            ),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        width: Dimensions
                                                            .PADDING_SIZE_DEFAULT),
                                                    InkWell(
                                                      onTap: () {
                                                        setState(() {
                                                          isMarkCompleted =
                                                              !isMarkCompleted;
                                                        });
                                                        _createVideoHistory();
                                                      },
                                                      child: Column(
                                                        children: [
                                                          Icon(
                                                              Icons
                                                                  .check_circle_outline,
                                                              color: isMarkCompleted ==
                                                                      true
                                                                  ? Colors.green
                                                                  : ThemeManager
                                                                      .blackColor,
                                                              size: 24),
                                                          Text(
                                                            textAlign: TextAlign
                                                                .center,
                                                            isMarkCompleted ==
                                                                    true
                                                                ? "Completed"
                                                                : "Complete",
                                                            style: interRegular
                                                                .copyWith(
                                                              fontSize: Dimensions
                                                                  .fontSizeExtraSmall,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: isMarkCompleted ==
                                                                      true
                                                                  ? Colors.green
                                                                  : ThemeManager
                                                                      .blackColor,
                                                            ),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        width: Dimensions
                                                            .PADDING_SIZE_DEFAULT),
                                                    InkWell(
                                                      onTap: () {
                                                        setState(() {
                                                          isBookmarkedDone =
                                                              !isBookmarkedDone;
                                                        });
                                                        _putBookMarkApiCall();
                                                      },
                                                      child: Column(
                                                        children: [
                                                          Icon(
                                                            isBookmarkedDone ==
                                                                    true
                                                                ? Icons.bookmark
                                                                : Icons
                                                                    .bookmark_border,
                                                            color: isBookmarkedDone ==
                                                                    true
                                                                ? ThemeManager
                                                                    .primaryColor
                                                                : ThemeManager
                                                                    .blackColor,
                                                            size: 24,
                                                          ),
                                                          Text(
                                                            textAlign: TextAlign
                                                                .center,
                                                            isBookmarkedDone ==
                                                                    true
                                                                ? "Bookmarked"
                                                                : "Bookmark",
                                                            style: interRegular
                                                                .copyWith(
                                                              fontSize: Dimensions
                                                                  .fontSizeExtraSmall,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: isBookmarkedDone ==
                                                                      true
                                                                  ? ThemeManager
                                                                      .primaryColor
                                                                  : ThemeManager
                                                                      .blackColor,
                                                            ),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(
                                                height: Dimensions
                                                    .PADDING_SIZE_DEFAULT),
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                  .size
                                                  .width,
                                              height: 1,
                                              child: Container(
                                                color: AppColors.divider,
                                              ),
                                            ),
                                            Expanded(
                                              child: Container(
                                                color:
                                                    ThemeManager.currentTheme ==
                                                            AppTheme.Light
                                                        ? ThemeManager
                                                            .backgroundGrey
                                                        : ThemeManager.white,
                                                child: IndexedStack(
                                                  index: selectedIndex,
                                                  children: [
                                                    Column(
                                                      children: [
                                                        Expanded(
                                                          child:
                                                              ListView.builder(
                                                            itemCount: store
                                                                .videoChapterizationList
                                                                .length,
                                                            shrinkWrap: true,
                                                            padding:
                                                                EdgeInsets.zero,
                                                            physics:
                                                                const AlwaysScrollableScrollPhysics(),
                                                            itemBuilder:
                                                                (BuildContext
                                                                        context,
                                                                    int index) {
                                                              return _buildItem1(
                                                                  context,
                                                                  index);
                                                            },
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Stack(
                                                      children: [
                                                        Center(
                                                          child: Container(
                                                            constraints:
                                                                const BoxConstraints(
                                                                    maxWidth:
                                                                        900),
                                                            child: NotesViewer(
                                                              key:
                                                                  _notesViewerKey,
                                                              pdfUrl:
                                                                  pdfBaseUrl +
                                                                      pdfUrl,
                                                              titleId: widget
                                                                  .pdfId!
                                                                  .toString(),
                                                              initialAnnotationJson:
                                                                  jsonEncode(widget
                                                                      .annotationData),
                                                              initialPage: 0,
                                                              isFromNormal:
                                                                  false,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ],
                            );
                    }
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<AnnotationData>? convertAnnotationListToAnnotationData(
      List<AnnotationList>? list) {
    if (list == null) return null;

    return list.map((annotation) {
      return AnnotationData(
        annotationType: annotation.annotationType,
        bounds: annotation.bounds,
        pageNumber: annotation.pageNumber,
        text: annotation.text,
      );
    }).toList();
  }

  void _showQualityOptions() {
    if (Platform.isMacOS || Platform.isWindows) {
      // Show a dialog for desktop platforms
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              "Download this video",
              style: interRegular.copyWith(
                fontSize: Dimensions.fontSizeLarge,
                fontWeight: FontWeight.w600,
                color: ThemeManager.blackColor,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Downloaded videos will still need an active internet connection to start playing. This would use only about 10k of data.",
                  style: interRegular.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    fontWeight: FontWeight.w600,
                    color: ThemeManager.grey,
                  ),
                ),
                const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
                material.Padding(
                  padding: const EdgeInsets.only(
                      left: 15, right: 15, top: 10, bottom: 10),
                  child: Wrap(
                    spacing: Dimensions.PADDING_SIZE_DEFAULT * 1.1,
                    children: List.generate(
                      _qualityAndSize.length,
                      (index) {
                        final entry = _qualityAndSize.entries.elementAt(index);
                        final quality = entry.key;
                        final size = entry.value;
                        bool isSelected = index == _selectedIndex;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              size,
                              style: interRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                fontWeight: FontWeight.w400,
                                color: ThemeManager.black,
                              ),
                            ),
                            const SizedBox(
                              height: Dimensions.PADDING_SIZE_EXTRA_SMALL,
                            ),
                            material.InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedIndex = index;
                                  downloadQuality = quality;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? ThemeManager.blueFinal
                                      : material.Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isSelected
                                        ? material.Colors.transparent
                                        : ThemeManager.black.withOpacity(0.28),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Dimensions.PADDING_SIZE_DEFAULT,
                                    vertical:
                                        Dimensions.PADDING_SIZE_EXTRA_SMALL,
                                  ),
                                  child: Text(
                                    quality,
                                    style: interRegular.copyWith(
                                      fontSize: isSelected
                                          ? Dimensions.fontSizeLarge
                                          : Dimensions.fontSizeDefaultLarge,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? ThemeManager.white
                                          : ThemeManager.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _downloadVideo(downloadUrl, downloadQuality);
                },
                child: Text(
                  "Download",
                  style: interRegular.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    fontWeight: FontWeight.w600,
                    color: ThemeManager.white,
                  ),
                ),
              ),
              if (isOfflineMode)
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(
                            "Delete Confirmation",
                            style: interRegular.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              fontWeight: FontWeight.w600,
                              color: ThemeManager.blackColor,
                            ),
                          ),
                          content: Text(
                            "Are you sure you want to delete the offline downloaded video?",
                            style: interRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              fontWeight: FontWeight.w600,
                              color: ThemeManager.blackColor,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                "Cancel",
                                style: interRegular.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  fontWeight: FontWeight.w600,
                                  color: ThemeManager.blackColor,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                await dbHelper.deleteVideoByTitleId(
                                    widget.titleId.toString());
                                Navigator.pop(context);
                                Navigator.pop(context);
                                Navigator.pop(context);
                                setState(() {});
                                BottomToast.showBottomToastOverlay(
                                  context: context,
                                  errorMessage:
                                      "Offline downloaded video has been deleted successfully!",
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.redText,
                              ),
                              child: Text(
                                "Delete",
                                style: interRegular.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  fontWeight: FontWeight.w600,
                                  color: ThemeManager.white,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.redText,
                  ),
                  child: Text(
                    "Delete",
                    style: interRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      fontWeight: FontWeight.w600,
                      color: ThemeManager.white,
                    ),
                  ),
                ),
            ],
          );
        },
      );
    } else {
      showModalBottomSheet<void>(
        isScrollControlled: true,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        context: context,
        backgroundColor: AppTokens.surface(context),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.r16)),
        ),
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return FractionallySizedBox(
              child: FittedBox(
                fit: BoxFit.fitWidth,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          "Download this video",
                          style: interRegular.copyWith(
                            fontSize: Dimensions.fontSizeLarge,
                            fontWeight: FontWeight.w600,
                            color: ThemeManager.blackColor,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          "Downloaded videos will still need an active internet connection to start playing. This would use only about 10k of data.",
                          style: interRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            fontWeight: FontWeight.w600,
                            color: ThemeManager.grey,
                          ),
                        ),
                      ),
                      const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
                      material.Padding(
                        padding: const EdgeInsets.only(
                            left: 15, right: 15, top: 10, bottom: 10),
                        child: Wrap(
                          spacing: Dimensions.PADDING_SIZE_DEFAULT * 1.1,
                          children: List.generate(
                            _qualityAndSize.length,
                            (index) {
                              final entry =
                                  _qualityAndSize.entries.elementAt(index);
                              final quality = entry.key;
                              final size = entry.value;
                              bool isSelected = index == _selectedIndex;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    size,
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      fontWeight: FontWeight.w400,
                                      color: ThemeManager.black,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: Dimensions.PADDING_SIZE_EXTRA_SMALL,
                                  ),
                                  material.InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedIndex = index;
                                        downloadQuality = quality;
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? ThemeManager.blueFinal
                                            : material.Colors.transparent,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: isSelected
                                              ? material.Colors.transparent
                                              : ThemeManager.black
                                                  .withOpacity(0.28),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal:
                                              Dimensions.PADDING_SIZE_DEFAULT,
                                          vertical: Dimensions
                                              .PADDING_SIZE_EXTRA_SMALL,
                                        ),
                                        child: Text(
                                          quality,
                                          style: interRegular.copyWith(
                                            fontSize: isSelected
                                                ? Dimensions.fontSizeLarge
                                                : Dimensions
                                                    .fontSizeDefaultLarge,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? ThemeManager.white
                                                : ThemeManager.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 15, right: 15, top: 10, bottom: 30),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _downloadVideo(downloadUrl, downloadQuality);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text("Download"),
                          ),
                        ),
                      ),
                      if (isOfflineMode)
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 15, right: 15, bottom: 15),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text(
                                        "Delete Confirmation",
                                        style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeDefault,
                                          fontWeight: FontWeight.w600,
                                          color: ThemeManager.blackColor,
                                        ),
                                      ),
                                      content: Text(
                                        "Are you sure you want to delete the offline downloaded video?",
                                        style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmall,
                                          fontWeight: FontWeight.w600,
                                          color: ThemeManager.blackColor,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: Text(
                                            "Cancel",
                                            style: interRegular.copyWith(
                                              fontSize:
                                                  Dimensions.fontSizeDefault,
                                              fontWeight: FontWeight.w600,
                                              color: ThemeManager.blackColor,
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            await dbHelper.deleteVideoByTitleId(
                                                widget.titleId.toString());
                                            BottomToast.showBottomToastOverlay(
                                              context: context,
                                              errorMessage:
                                                  "Offline downloaded video has been deleted successfully!",
                                              backgroundColor: Theme.of(context)
                                                  .primaryColor,
                                            );
                                            Navigator.pop(context);
                                            Navigator.pop(context);
                                            Navigator.pop(context);
                                            setState(() {});
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.redText,
                                          ),
                                          child: Text(
                                            "Delete",
                                            style: interRegular.copyWith(
                                              fontSize:
                                                  Dimensions.fontSizeDefault,
                                              fontWeight: FontWeight.w600,
                                              color: ThemeManager.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.redText,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                "Delete",
                                style: interRegular.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  fontWeight: FontWeight.w600,
                                  color: ThemeManager.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          });
        },
      );
    }
  }

  /// Delegate the actual download to the shared [DownloadService] (same one
  /// the chapter list + download manager sheet use) — one code path, one
  /// queue, one encryption pipeline.
  ///
  /// Historical bug: this function used to monkey-patch the service's
  /// single-field callbacks (`svc.onTaskUpdated = …`) and try to "chain"
  /// to any previous handler. That clobbered the download_manager_sheet's
  /// callbacks whenever the sheet was open, and in some error paths the
  /// prior callbacks were never restored — so after one failed download,
  /// the sheet would stop receiving progress updates until app restart.
  ///
  /// Fix: subscribe to the service's new broadcast streams scoped to this
  /// one titleId. Streams support any number of concurrent listeners, so
  /// the sheet + store + this player can all observe the same task
  /// independently. The subscription is cancelled automatically when the
  /// task reaches a terminal state OR when the widget is disposed.
  Future<void> _downloadVideo(String url, String quality) async {
    final titleId = widget.titleId.toString();
    final notificationId = _videoStore.getNotificationId(titleId);

    if (url.isEmpty) {
      debugPrint('[DL] aborted: empty url');
      return;
    }

    // If already queued, bail out — no duplicate enqueue.
    if (DownloadService.instance.isInQueue(titleId)) {
      debugPrint('[DL] already in queue: $titleId');
      return;
    }

    _videoStore.startDownload(titleId);
    if (!isDesktop) {
      _showDownloadProgressNotification(0, notificationId);
    }

    // Scoped subscription — only fires for this titleId's task events.
    // Self-cancels on terminal state (completed / failed / cancelled).
    _taskSub?.cancel();
    _taskSub = DownloadService.instance.updates.listen((task) {
      if (task.titleId != titleId || !mounted) return;
      switch (task.status) {
        case DownloadStatus.downloading:
        case DownloadStatus.encrypting:
        case DownloadStatus.queued:
          _videoStore.setDownloadProgressThrottled(titleId, task.progressPercent);
          if (!isDesktop && task.status == DownloadStatus.downloading) {
            _updateDownloadProgressNotification(
                task.progressPercent, notificationId);
          }
          break;
        case DownloadStatus.completed:
          _videoStore.setDownloadProgress(titleId, 100);
          _videoStore.completeDownload(titleId);
          _videoStore.markDownloaded(titleId);
          if (mounted) setState(() => isDownloaded = true);
          if (!isDesktop) {
            _showDownloadNotification(
                quality,
                "${widget.title} is available to watch offline.",
                notificationId);
          }
          _taskSub?.cancel();
          _taskSub = null;
          break;
        case DownloadStatus.failed:
          _videoStore.cancelDownload(titleId);
          if (!isDesktop) {
            _showDownloadNotification(
              'Download failed',
              task.errorMessage ??
                  'Could not download this video. Please try again.',
              notificationId,
            );
          }
          _taskSub?.cancel();
          _taskSub = null;
          break;
        case DownloadStatus.cancelled:
        case DownloadStatus.paused:
          _videoStore.cancelDownload(titleId);
          _taskSub?.cancel();
          _taskSub = null;
          break;
      }
    });

    DownloadService.instance.enqueue(
      titleId: titleId,
      url: url,
      quality: quality,
      title: widget.title ?? '',
      topicId: widget.topicId ?? '',
      categoryId: widget.categoryId ?? '',
      subCategoryId: widget.subcategoryId ?? '',
    );
  }

  void _showDownloadProgressNotification(
      int progress, int notificationId) async {
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'download_channel',
      'Downloads',
      channelDescription: 'Notifications for download progress',
      importance: Importance.high,
      priority: Priority.high,
      onlyAlertOnce: true,
      progress: downloadProgress,
    );

    NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      'Download in Progress',
      'Downloading... $progress%',
      platformDetails,
    );
  }

  void _updateDownloadProgressNotification(
      int progress, int notificationId) async {
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'download_channel',
      'Downloads',
      channelDescription: 'Notifications for download progress',
      importance: Importance.high,
      priority: Priority.high,
      onlyAlertOnce: true,
      progress: progress,
    );

    NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      'Download in Progress',
      'Downloading... $progress%',
      platformDetails,
    );
  }

  void _showDownloadNotification(
      String title, String message, int notificationId) async {
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'download_channel',
      'Downloads',
      channelDescription: 'Notifications for completed downloads',
      importance: Importance.high,
      priority: Priority.high,
    );

    NotificationDetails platformDetails = const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      message,
      platformDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      message,
      platformDetails,
    );
  }

  /// Source resolution order:
  ///   1) Offline encrypted file (.enc) if present for this titleId
  ///   2) Legacy plain .mp4 on disk (backward-compat for pre-encryption users)
  ///   3) Bunny CDN HLS link (adaptive streaming — preferred for online)
  ///   4) Fallback MP4 at the user's selected quality
  ///
  /// All file I/O is async (no *Sync calls on the UI isolate), error paths
  /// surface a snackbar + preserve the player controller so Retry works.
  Future<void> _playVideo(String titleId) async {
    debugPrint('[PLAY] checking offline for titleId=$titleId');

    // ── 1 + 2: offline first (works regardless of network) ──────────────
    // Defensive: refuse obvious junk IDs so we can't accidentally match a
    // DB row that was written with an empty/null titleId in a past build
    // (the same state-leak that caused "all videos show downloaded" before).
    final isValidId = titleId.isNotEmpty &&
        titleId != 'null' &&
        titleId != 'undefined';
    final downloadedVideo = isValidId
        ? await dbHelper.getVideoByTitleId(titleId)
        : null;
    if (downloadedVideo != null) {
      final videoPath = downloadedVideo.videoPath;
      if (videoPath != null && videoPath.isNotEmpty) {
        final file = File(videoPath);
        if (await file.exists()) {
          isOfflineMode = true;
          if (videoPath.toLowerCase().endsWith('.enc')) {
            final ok = await _playOfflineEncrypted(videoPath);
            if (ok) return;
            // If decrypt failed we fall through to online sources.
          } else {
            debugPrint('[PLAY] offline legacy mp4: $videoPath');
            await _initializePlayer(videoPath, isOffline: true);
            return;
          }
        } else {
          debugPrint('[PLAY] offline file missing on disk — falling back to online');
          _videoStore.markNotDownloaded(titleId);
        }
      }
    }

    isOfflineMode = false;

    // ── 3: HLS (Bunny CDN adaptive streaming — fastest start on mobile) ─
    if (widget.hlsLink != null && widget.hlsLink!.isNotEmpty) {
      debugPrint('[PLAY] online HLS: ${widget.hlsLink}');
      await _initializePlayer(widget.hlsLink!);
      return;
    }

    // ── 4: MP4 quality fallback (Vimeo progressive or server-proxied) ───
    final chosen = _videoUrls.containsKey(_selectedQuality)
        ? _selectedQuality
        : (_videoUrls.isNotEmpty ? _videoUrls.keys.first : null);
    if (chosen != null) {
      debugPrint('[PLAY] online MP4 quality=$chosen');
      if (chosen != _selectedQuality) {
        _selectedQuality = chosen;
      }
      await _initializePlayer(_videoUrls[chosen]!);
      return;
    }

    debugPrint('[PLAY] no source available');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video not available for playback.')),
      );
    }
  }

  /// Decrypt an AES-GCM .enc file and initialize the player from the temp
  /// clear file. Returns false if decryption failed (so the caller can try
  /// an online source instead of showing a dead screen).
  ///
  /// Mutex semantics: if a decrypt is already in flight for the same
  /// [videoPath], we return that Completer's future directly — no wasted
  /// parallel decrypt. If it's a different path (user tapped a different
  /// offline video before the first finished), we still short-circuit and
  /// let the newer call go through once the old one completes — otherwise
  /// we'd get two concurrent AES-GCM streams fighting for disk and RAM.
  Future<bool> _playOfflineEncrypted(String videoPath) async {
    // ── Mutex: dedupe in-flight decrypts ──────────────────────────────────
    final existing = _decryptInFlight;
    if (existing != null && !existing.isCompleted) {
      if (_decryptInFlightPath == videoPath) {
        debugPrint('[DEC] identical decrypt in flight — awaiting');
        return existing.future;
      }
      // Different video requested while another decrypt is running. Wait
      // for the current one to finish (success or fail) before starting,
      // so we never run two AES streams concurrently on the main isolate.
      debugPrint('[DEC] another decrypt active — queuing behind it');
      try {
        await existing.future;
      } catch (_) {}
    }

    final completer = Completer<bool>();
    _decryptInFlight = completer;
    _decryptInFlightPath = videoPath;
    if (mounted) {
      setState(() {
        _isDecrypting = true;
      });
    }

    try {
      final result = await _doDecryptAndPlay(videoPath);
      if (!completer.isCompleted) completer.complete(result);
      return result;
    } catch (e, st) {
      if (!completer.isCompleted) completer.completeError(e, st);
      rethrow;
    } finally {
      if (_decryptInFlightPath == videoPath) {
        _decryptInFlight = null;
        _decryptInFlightPath = null;
      }
      if (mounted) {
        setState(() {
          _isDecrypting = false;
        });
      }
    }
  }

  /// Inner decrypt logic — extracted so [_playOfflineEncrypted] can wrap
  /// cleanly with mutex + state flag bookkeeping. Never call this directly
  /// from outside; callers MUST go through [_playOfflineEncrypted] to get
  /// the overlay + serialization guarantees.
  Future<bool> _doDecryptAndPlay(String videoPath) async {
    try {
      final sz = await File(videoPath).length();
      debugPrint('[PLAY] enc=$videoPath size=$sz');

      // Load global key — never generate a new one here; must match the
      // key used at encryption time.
      List<int>? key = await SecureKeys.loadKey('global');
      if (key == null || key.length != 32) {
        try {
          await SecureKeys.deleteKey('global');
        } catch (_) {}
        try {
          if (!mounted) return false;
          final homeStore = Provider.of<HomeStore>(context, listen: false);
          await homeStore.onGetUserDetailsCall(context);
          key = await SecureKeys.loadKey('global');
        } catch (_) {}
      }
      if (key == null || key.length != 32) {
        debugPrint('[DEC] missing global key');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(
                'Decryption key missing. Please refresh your profile and try again.')),
          );
        }
        return false;
      }

      // Streaming decrypt keeps RAM footprint bounded for multi-hundred-MB
      // files (iOS would OOM with the previous load-everything path).
      _tempDecryptedFile = await OfflineEncryptor.decryptFileToTemp(
        File(videoPath),
        key,
      );
      debugPrint('[PLAY] temp=${_tempDecryptedFile!.path}');
      if (!mounted) {
        // Widget disposed while we were decrypting. Clean up the temp file
        // so we don't leak disk on back-navigation.
        try {
          if (_tempDecryptedFile != null && await _tempDecryptedFile!.exists()) {
            await _tempDecryptedFile!.delete();
          }
        } catch (_) {}
        return false;
      }
      await _initializePlayer(_tempDecryptedFile!.path, isOffline: true);
      return true;
    } catch (e) {
      debugPrint('[DEC] failed: $e');
      // Auto-repair: corrupt/wrong-key file would loop forever in buffering.
      // Nuke the .enc and let the user re-download.
      try {
        final f = File(videoPath);
        if (await f.exists()) {
          await f.delete();
          debugPrint('[DEC] deleted bad .enc: $videoPath');
        }
      } catch (_) {}
      // Also drop the stale DB row so the download button re-appears.
      try {
        await dbHelper.deleteVideoByTitleId(widget.titleId.toString());
        _videoStore.markNotDownloaded(widget.titleId.toString());
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(
              'Offline file invalid. Please re-download this video.')),
        );
      }
      return false;
    }
  }

  /// Lightweight overlay shown while [_isDecrypting] is true. Uses the same
  /// black backdrop as the player so the transition to BetterPlayer's first
  /// frame is invisible — no flash from spinner→black→video.
  Widget _buildDecryptOverlay() {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Preparing offline video…',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          SizedBox(height: 4),
          Text(
            'Decrypting securely on device',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _seekToChapter(int timecodeInSeconds) {
    if (!_playerControllerBuilt) return;
    try {
      _betterPlayerController.seekTo(Duration(seconds: timecodeInSeconds));
    } catch (e) {
      debugPrint('[SEEK] chapter seek failed: $e');
    }
  }

  void showBottomSheetOrDialog(BuildContext context) {
    if (Platform.isWindows || Platform.isMacOS) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: BottomSheetContent(
            isOffline: isOfflineMode,
            autoPlay: _autoPlay,
            playbackSpeed: _playbackSpeed,
            seekTime: _seekTime,
            selectedQuality: _selectedQuality,
            onAutoPlayChange: _changeAutoPlay,
            onSpeedChange: _changePlaybackSpeed,
            onSeekTimeChange: _changeSeekTime,
            onQualityChange: _changeVideoQuality,
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        builder: (context) => BottomSheetContent(
          isOffline: isOfflineMode,
          autoPlay: _autoPlay,
          playbackSpeed: _playbackSpeed,
          seekTime: _seekTime,
          selectedQuality: _selectedQuality,
          onAutoPlayChange: _changeAutoPlay,
          onSpeedChange: _changePlaybackSpeed,
          onSeekTimeChange: _changeSeekTime,
          onQualityChange: _changeVideoQuality,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      );
    }
  }

  Widget _buildItem1(BuildContext context, int index) {
    final store = Provider.of<VideoCategoryStore>(context, listen: false);
    VideoChapterizationListModel? videoChapters =
        store.videoChapterizationList[index];
    return Stack(
      children: [
        InkWell(
          onTap: () {
            if (!isDesktop) {
              _seekToChapter(videoChapters?.timeCode ?? 0);
            } else {
              seekToChapterMac(videoChapters?.timeCode ?? 0);
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: Dimensions.PADDING_SIZE_DEFAULT,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: Dimensions.PADDING_SIZE_DEFAULT,
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ThemeManager.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "${index + 1}",
                      style: interSemiBold.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        fontWeight: FontWeight.w600,
                        color: ThemeManager.blackColor,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: Dimensions.PADDING_SIZE_DEFAULT,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        videoChapters?.title ?? "",
                        maxLines: 3,
                        overflow: TextOverflow.visible,
                        style: interRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          fontWeight: FontWeight.w500,
                          color: ThemeManager.blackColor,
                        ),
                      ),
                      Text(
                        formatTime(videoChapters?.timeCode ?? 0),
                        style: interRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          fontWeight: FontWeight.w500,
                          overflow: TextOverflow.ellipsis,
                          color: ThemeManager.blackColor.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(
                height: Dimensions.PADDING_SIZE_SMALL,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 1,
                child: Container(
                  color: AppColors.divider,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    final hoursStr = hours.toString().padLeft(2, '0');
    final minutesStr = minutes.toString().padLeft(2, '0');
    final secondsStr = remainingSeconds.toString().padLeft(2, '0');

    return "$hoursStr:$minutesStr:$secondsStr";
  }

  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return "$hours hr $minutes min";
    } else if (minutes > 0) {
      return "$minutes min $seconds sec";
    } else {
      return "$seconds sec";
    }
  }

  String remainTimeDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  String? convertSecondsToMinutesAndSeconds(String? timeString) {
    if (timeString != '') {
      List<String>? parts = timeString?.split(':');
      int hours = int.parse(parts![0]);
      int minutes = int.parse(parts[1]);
      int seconds = int.parse(parts[2]);

      int totalSeconds = (hours * 3600) + (minutes * 60) + seconds;

      int convertedMinutes = totalSeconds ~/ 60;
      int convertedSeconds = totalSeconds % 60;

      return "${convertedMinutes}m ${convertedSeconds}s";
    }
    return null;
  }

  Future<void> _loadVideoSizes() async {
    for (var quality in _videoUrls.keys) {
      final url = _videoUrls[quality]!;
      final size = await getFileSize(url);
      if (size != null) {
        setState(() {
          _qualityAndSize[quality] = formatFileSize(size);
        });
      }
    }
  }

  Future<int?> getFileSize(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      if (response.statusCode == 200) {
        return int.tryParse(response.headers['content-length'] ?? '');
      }
    } catch (e) {
      print("Error fetching file size: $e");
    }
    return null;
  }

  String formatVideoTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return "$hours hr $minutes min";
    } else if (minutes > 0) {
      return "$minutes min $remainingSeconds s";
    } else {
      return "$remainingSeconds s";
    }
  }

  String formatFileSize(int bytes) {
    const int KB = 1024;
    const int MB = KB * 1024;
    if (bytes >= MB) {
      return '${(bytes / MB).toStringAsFixed(2)} MB';
    } else if (bytes >= KB) {
      return '${(bytes / KB).toStringAsFixed(2)} KB';
    } else {
      return '$bytes B';
    }
  }
}

class BottomSheetContent extends StatelessWidget {
  final bool autoPlay;
  final double playbackSpeed;
  final int seekTime;
  final String selectedQuality;
  final Function(bool) onAutoPlayChange;
  final Function(double) onSpeedChange;
  final Function(int) onSeekTimeChange;
  final Function(String) onQualityChange;
  final bool isOffline;

  const BottomSheetContent({
    super.key,
    required this.autoPlay,
    required this.playbackSpeed,
    required this.seekTime,
    required this.selectedQuality,
    required this.onAutoPlayChange,
    required this.onSpeedChange,
    required this.onSeekTimeChange,
    required this.onQualityChange,
    required this.isOffline,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.play_circle_outline),
            title: Text(
              "Auto play",
              style: interRegular.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
            trailing: Switch(
                value: autoPlay,
                activeColor: ThemeManager.primaryColor,
                onChanged: (value) {
                  onAutoPlayChange(value);
                  Navigator.pop(context);
                }),
          ),
          ListTile(
            leading: const Icon(Icons.speed),
            title: Text(
              "Speed",
              style: interRegular.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<double>(
                value: playbackSpeed,
                items: [0.5, 0.75, 1.0, 1.25, 1.75, 2.0].map((speed) {
                  return DropdownMenuItem(
                    value: speed,
                    child: Text("${speed}x"),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) onSpeedChange(value);
                  Navigator.pop(context);
                },
              ),
            ),
          ),
          if (!isOffline)
            ListTile(
              leading: const Icon(Icons.high_quality),
              title: Text(
                "Video quality",
                style: interRegular.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              trailing: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedQuality,
                  elevation: 5,
                  items: ["540p", "720p", "1080p"].map((String quality) {
                    return DropdownMenuItem<String>(
                      value: quality,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(quality),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onQualityChange(value);
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.replay_10),
            title: Text(
              "Seek Time",
              style: interRegular.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: seekTime,
                items: [5, 10, 15, 30].map((time) {
                  return DropdownMenuItem(
                    value: time,
                    child: Text("$time Seconds"),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) onSeekTimeChange(value);
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Two-button FAB cluster: a yellow "Bookmark" FAB that saves the current
/// position, and a small secondary button that opens the bookmarks list
/// sheet (tap a row to seek). Lives in its own stateless widget so the
/// Scaffold doesn't rebuild all of it on every Observer tick.
class _VideoBookmarkFabCluster extends StatelessWidget {
  const _VideoBookmarkFabCluster({
    required this.contentId,
    required this.getPosition,
    required this.onSeek,
  });

  final String contentId;
  final Duration Function() getPosition;
  final ValueChanged<int> onSeek;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.small(
          heroTag: 'bm_list_$contentId',
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          tooltip: 'Show bookmarks',
          onPressed: () => showVideoBookmarksSheet(
            context: context,
            contentId: contentId,
            onSeek: onSeek,
          ),
          child: const Icon(Icons.bookmarks_outlined, size: 18),
        ),
        const SizedBox(height: 8),
        VideoBookmarkFab(
          contentId: contentId,
          getCurrentPosition: getPosition,
        ),
      ],
    );
  }
}

