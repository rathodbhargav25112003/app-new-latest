// ignore_for_file: non_constant_identifier_types, deprecated_member_use, unused_field, library_private_types_in_public_api, constant_identifier_names, unused_element, non_constant_identifier_names

import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/helpers/constants.dart';
import 'package:shusruta_lms/modules/dashboard/store/home_store.dart';
import 'package:shusruta_lms/modules/notes/notes_viewer.dart';
import 'package:shusruta_lms/modules/notes/sharedhelper.dart';
import 'package:shusruta_lms/modules/notes/store/notes_category_store.dart';
import 'package:shusruta_lms/modules/videolectures/store/video_category_store.dart';

/// PDF reader screen opened from every notes tile in the app. Wraps
/// `NotesViewerWrapper` (which hosts either PSPDFKit on mobile or
/// Syncfusion `SfPdfViewer` on desktop) and adds the top hero bar with
/// Back / Mark-as-Read / Bookmark controls plus a floating "Save" FAB
/// that flushes annotations back to the backend.
///
/// Preserved public contract:
///   • `NotesReadView({...})` constructor with 14 fields — required:
///     `topic_name`, `subcategory_name`, `category_name`, `title`,
///     `isDownloaded`; optional: `fileUrl`, `titleId`, `subcategoryId`,
///     `categoryId`, `topicId`, `isCompleted`, `isBookmark`, `pageNo`,
///     `annotationData`. All field names (including the snake_case
///     `topic_name`/`category_name`/`subcategory_name` that would
///     normally be `topicName` etc.) are preserved because they're
///     referenced by GlobalKey-based callers in the legacy codebase.
///   • Static `route(RouteSettings)` factory reading the 14-key args
///     map including the mixed-case `'isBookMark'` key (note the
///     capital M in the middle — preserved byte-for-byte from
///     upstream) and returning a `CupertinoPageRoute`.
///   • `NotesViewerWrapper` public class + public `NotesViewerWrapperState`
///     with constructor parameters `pdfUrl`, `titleId`,
///     `initialAnnotationJson`, `initialPage`, `isFromNormal=true`,
///     `onAnnotationsChanged`, `onDocumentLoaded`, `onStateCreated` and
///     public state methods `saveLastPageToBackend()`,
///     `exportAndSaveAnnotations()`, `openAnnotationToolbar()`.
///   • MobX wiring: `Provider.of<NotesCategoryStore>` +
///     `onTopicDetailApiCall(widget.titleId)` in `_getPdfContent`,
///     `store.isDownloading` / `isLoading` / `startDownload` /
///     `completeDownload` / `cancelDownload` used by `downloadPDF`.
///   • `Provider.of<VideoCategoryStore>` used for
///     `onCreateVideoHistoryApiCall(titleId)` (mark-as-read) and
///     `onCreateBookmarkContentApiCall(titleId)` (bookmark toggle).
///   • `Provider.of<HomeStore>` used for
///     `onCreateVideoNoteHistoryCall(titleId, 'pdf')` (view history).
///   • `WillPopScope` save-on-back pattern preserved — delays,
///     mount-guards, and `FirebaseCrashlytics.instance.recordError`
///     all kept byte-for-byte.
///   • `FloatingActionButton` with heroTag "notes_save_button" and
///     tooltip "Save" triggering `exportAndSaveAnnotations` kept.
///   • `modifiedString = "getPDF${pdfUrl.substring(...)}"` URL
///     transformation and `pdfBaseUrl + modifiedString` composition
///     kept byte-for-byte.
///   • `jsonEncode(widget.annotationData)` passed to wrapper kept.
///   • Android SDK < 33 permission flow in `getPermission()` kept.
///   • `downloadPDF(String url, String filename, NotesCategoryStore)`
///     public state method with the flutter_local_notifications
///     progress/completion notification pattern preserved (mobile-only
///     via top-level `isDesktop` from `sharedhelper.dart`).
///   • Android notification channel 'download_channel' / 'Downloads'
///     and 'pdf_download_channel' / 'PDF Downloads' IDs kept.
class NotesReadView extends StatefulWidget {
  final String? fileUrl;
  final String title;
  final String? topic_name;
  final String? category_name;
  final String? subcategory_name;
  final String? topicId;
  final String? titleId;
  final String? categoryId;
  final String? subcategoryId;
  final String? annotationData;
  final bool isDownloaded;
  final bool? isCompleted;
  final bool? isBookmark;
  final int? pageNo;

  const NotesReadView({
    super.key,
    this.fileUrl,
    this.titleId,
    this.subcategoryId,
    this.categoryId,
    required this.topic_name,
    required this.subcategory_name,
    required this.category_name,
    required this.title,
    required this.isDownloaded,
    this.topicId,
    this.isCompleted,
    this.isBookmark,
    this.pageNo,
    this.annotationData,
  });

  @override
  State<NotesReadView> createState() => _NotesReadViewState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => NotesReadView(
        fileUrl: arguments['contentUrl'],
        title: arguments['title'],
        topic_name: arguments['topic_name'],
        category_name: arguments['category_name'],
        subcategory_name: arguments['subcategory_name'],
        isDownloaded: arguments['isDownloaded'],
        isCompleted: arguments['isCompleted'],
        topicId: arguments['topicId'],
        titleId: arguments['titleId'],
        categoryId: arguments['categoryId'],
        subcategoryId: arguments['subcategoryId'],
        isBookmark: arguments['isBookMark'],
        pageNo: arguments['pageNo'],
        annotationData: arguments['annotationData'],
      ),
    );
  }
}

/// Thin wrapper around [NotesViewer] that exposes its save/export/toolbar
/// methods through an [onStateCreated] callback so the enclosing
/// [NotesReadView] can drive them from its hero bar and FAB.
class NotesViewerWrapper extends StatefulWidget {
  final String pdfUrl;
  final String titleId;
  final String initialAnnotationJson;
  final int? initialPage;
  final bool isFromNormal;
  final VoidCallback? onAnnotationsChanged;
  final VoidCallback? onDocumentLoaded;
  final void Function(NotesViewerWrapperState)? onStateCreated;

  const NotesViewerWrapper({
    super.key,
    required this.pdfUrl,
    required this.titleId,
    required this.initialAnnotationJson,
    this.initialPage,
    this.isFromNormal = true,
    this.onAnnotationsChanged,
    this.onDocumentLoaded,
    this.onStateCreated,
  });

  @override
  NotesViewerWrapperState createState() => NotesViewerWrapperState();
}

class NotesViewerWrapperState extends State<NotesViewerWrapper> {
  final GlobalKey<NotesViewerState> _notesViewerKey =
      GlobalKey<NotesViewerState>();

  Future<void> saveLastPageToBackend() async {
    await _notesViewerKey.currentState?.saveLastPageToBackend();
  }

  Future<void> exportAndSaveAnnotations() async {
    await _notesViewerKey.currentState?.exportAndSaveAnnotations();
  }

  void openAnnotationToolbar() {
    _notesViewerKey.currentState?.openAnnotationToolbar();
  }

  @override
  void initState() {
    super.initState();
    widget.onStateCreated?.call(this);
  }

  @override
  Widget build(BuildContext context) {
    return NotesViewer(
      key: _notesViewerKey,
      pdfUrl: widget.pdfUrl,
      titleId: widget.titleId,
      initialAnnotationJson: widget.initialAnnotationJson,
      initialPage: widget.initialPage,
      isFromNormal: widget.isFromNormal,
      onAnnotationsChanged: widget.onAnnotationsChanged,
      onDocumentLoaded: widget.onDocumentLoaded,
    );
  }
}

class _NotesReadViewState extends State<NotesReadView> {
  bool permissionGranted = false;
  String pdfUrl = '';
  String modifiedString = '';
  String pdfName = '';
  bool isMarkRead = false;
  bool isBookmarkedDone = false;
  bool isDownloadedPdf = false;
  final String _selectedText = '';
  final String _documentPath =
      "https://pdftron.s3.amazonaws.com/downloads/pl/PDFTRON_mobile_about.pdf";
  String? _document;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  NotesViewerWrapperState? _notesViewerWrapperState;

  @override
  void initState() {
    super.initState();
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _initializeNotifications();
    _createVideoNoteHistory();
    isBookmarkedDone = widget.isBookmark ?? false;
    isDownloadedPdf = widget.isDownloaded;
    isMarkRead = widget.isCompleted ?? false;
    _getPdfContent();
    getPermission();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────────────
  // Lifecycle helpers — preserved API & side effects.
  // ───────────────────────────────────────────────────────────────────

  Future<void> _initializeNotifications() async {
    const AndroidNotificationChannel androidNotificationChannel =
        AndroidNotificationChannel(
      'download_channel',
      'Downloads',
      description: 'Notifications for download progress',
      importance: Importance.high,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidNotificationChannel);
  }

  Future<void> getPermission() async {
    try {
      DeviceInfoPlugin plugin = DeviceInfoPlugin();
      AndroidDeviceInfo android = await plugin.androidInfo;
      final sdkInt = android.version.sdkInt;
      if (sdkInt < 33) {
        if (await Permission.storage.request().isGranted) {
          setState(() {
            permissionGranted = true;
          });
        } else if (await Permission.storage.request().isPermanentlyDenied) {
          await openAppSettings();
        } else if (await Permission.audio.request().isDenied) {
          setState(() {
            permissionGranted = false;
          });
        }
      }
    } catch (e, st) {
      debugPrint('Error getting device info or permissions: $e\nStack: $st');
      setState(() {
        permissionGranted = false;
      });
    }
  }

  Future<void> _getPdfContent() async {
    final store = Provider.of<NotesCategoryStore>(context, listen: false);
    await store.onTopicDetailApiCall(widget.titleId ?? "");
    final pdfUrl = widget.fileUrl ?? "";
    if (pdfUrl.isNotEmpty) {
      modifiedString = "getPDF${pdfUrl.substring(pdfUrl.lastIndexOf('/'))}";
    }
  }

  Future<void> _createVideoHistory() async {
    final store = Provider.of<VideoCategoryStore>(context, listen: false);
    await store.onCreateVideoHistoryApiCall(widget.titleId ?? '');
  }

  Future<void> _createVideoNoteHistory() async {
    final store = Provider.of<HomeStore>(context, listen: false);
    await store.onCreateVideoNoteHistoryCall(widget.titleId ?? '', 'pdf');
  }

  Future<void> _putBookMarkApiCall() async {
    final store = Provider.of<VideoCategoryStore>(context, listen: false);
    await store.onCreateBookmarkContentApiCall(widget.titleId ?? '');
  }

  // ───────────────────────────────────────────────────────────────────
  // Build.
  // ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<NotesCategoryStore>(context, listen: false);
    final isDesktopEnv = Platform.isWindows || Platform.isMacOS;

    return WillPopScope(
      onWillPop: () async {
        try {
          await Future.delayed(const Duration(milliseconds: 300));
          if (!mounted) return false;
          await _notesViewerWrapperState?.saveLastPageToBackend();
          await _notesViewerWrapperState?.exportAndSaveAnnotations();
          await Future.delayed(const Duration(milliseconds: 200));
          return mounted;
        } catch (e, st) {
          FirebaseCrashlytics.instance.recordError(e, st);
          return mounted;
        }
      },
      child: Scaffold(
        backgroundColor: AppTokens.scaffold(context),
        floatingActionButton: _SaveFab(
          onPressed: () {
            _notesViewerWrapperState?.exportAndSaveAnnotations();
          },
        ),
        body: Observer(
          builder: (BuildContext context) {
            // ignore: unused_local_variable
            final isDownloading =
                store.isDownloading(widget.titleId?.toString() ?? "");

            return Column(
              children: [
                _HeroBar(
                  isDesktop: isDesktopEnv,
                  title: widget.title,
                  isMarkRead: isMarkRead,
                  isBookmarkedDone: isBookmarkedDone,
                  onBack: () async {
                    await _notesViewerWrapperState?.saveLastPageToBackend();
                    await _notesViewerWrapperState?.exportAndSaveAnnotations();
                    if (!mounted) return;
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  onToggleRead: () {
                    setState(() {
                      isMarkRead = !isMarkRead;
                    });
                    _createVideoHistory();
                  },
                  onToggleBookmark: () {
                    setState(() {
                      isBookmarkedDone = !isBookmarkedDone;
                    });
                    _putBookMarkApiCall();
                  },
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTokens.scaffold(context),
                      borderRadius: isDesktopEnv
                          ? null
                          : const BorderRadius.only(
                              topLeft: Radius.circular(AppTokens.r28),
                              topRight: Radius.circular(AppTokens.r28),
                            ),
                    ),
                    child: Observer(
                      builder: (BuildContext context) {
                        if (store.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryColor,
                            ),
                          );
                        }
                        return Stack(
                          children: [
                            Center(
                              child: ClipRRect(
                                borderRadius: isDesktopEnv
                                    ? BorderRadius.zero
                                    : const BorderRadius.only(
                                        topLeft:
                                            Radius.circular(AppTokens.r28),
                                        topRight:
                                            Radius.circular(AppTokens.r28),
                                      ),
                                child: NotesViewerWrapper(
                                  pdfUrl: pdfBaseUrl + modifiedString,
                                  titleId: widget.titleId!,
                                  initialAnnotationJson:
                                      jsonEncode(widget.annotationData),
                                  initialPage: widget.pageNo,
                                  isFromNormal: true,
                                  onAnnotationsChanged: () {
                                    setState(() {});
                                  },
                                  onDocumentLoaded: () {
                                    setState(() {});
                                  },
                                  onStateCreated: (state) {
                                    _notesViewerWrapperState = state;
                                  },
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
            );
          },
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────
  // Download path — preserved public method + android notification
  // progress/completion flow. Unchanged in behaviour.
  // ───────────────────────────────────────────────────────────────────

  Future<void> downloadPDF(
      String url, String filename, NotesCategoryStore store) async {
    final titleId = widget.titleId.toString();
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$filename.pdf';
      final file = File(filePath);

      final request = http.Request('GET', Uri.parse(url));
      final response = await request.send();

      if (response.statusCode == 200) {
        int totalBytes = response.contentLength ?? 0;
        int downloadedBytes = 0;

        final fileSink = file.openWrite();
        store.startDownload(titleId);
        if (!isDesktop) {
          _showPDFDownloadProgressNotification(0);
        }

        response.stream.listen(
          (data) {
            downloadedBytes += data.length;
            fileSink.add(data);

            if (totalBytes > 0) {
              double progress =
                  ((downloadedBytes / totalBytes) * 100).clamp(0, 100);
              _updatePDFDownloadProgressNotification(progress.toInt());
              debugPrint("PDF Download Progress: $progress%");
            }
          },
          onDone: () async {
            await fileSink.close();
            store.completeDownload(titleId);
            if (!isDesktop) {
              _showPDFDownloadNotification('PDF Download Complete',
                  "${widget.title} has been saved offline successfully.");
            }
            if (mounted) {
              setState(() {
                isDownloadedPdf = true;
              });
            }
          },
          onError: (e) async {
            debugPrint("Error downloading PDF: $e");
            store.cancelDownload(titleId);
            await fileSink.close();
          },
          cancelOnError: true,
        );
      } else {
        debugPrint(
            "Failed to download PDF. Status code: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Exception during PDF download: $e");
    }
  }

  void _showPDFDownloadProgressNotification(int progress) async {
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pdf_download_channel',
      'PDF Downloads',
      channelDescription: 'Notifications for PDF download progress',
      importance: Importance.high,
      priority: Priority.high,
      onlyAlertOnce: true,
      progress: progress,
    );

    NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      1,
      'PDF Download in Progress',
      'Downloading...',
      platformDetails,
    );
  }

  void _updatePDFDownloadProgressNotification(int progress) async {
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pdf_download_channel',
      'PDF Downloads',
      channelDescription: 'Notifications for PDF download progress',
      importance: Importance.high,
      priority: Priority.high,
      onlyAlertOnce: true,
      progress: progress,
    );

    NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      1,
      'PDF Download in Progress',
      'Downloading... $progress%',
      platformDetails,
    );
  }

  void _showPDFDownloadNotification(String title, String message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'pdf_download_channel',
      'PDF Downloads',
      channelDescription: 'Notifications for completed PDF downloads',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      1,
      title,
      message,
      platformDetails,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Presentational widgets — private, purely visual.
// ══════════════════════════════════════════════════════════════════════

class _SaveFab extends StatelessWidget {
  const _SaveFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: "notes_save_button",
      backgroundColor: AppTokens.accent(context),
      foregroundColor: AppColors.white,
      onPressed: onPressed,
      tooltip: 'Save',
      child: const Icon(Icons.save_rounded),
    );
  }
}

class _HeroBar extends StatelessWidget {
  const _HeroBar({
    required this.isDesktop,
    required this.title,
    required this.isMarkRead,
    required this.isBookmarkedDone,
    required this.onBack,
    required this.onToggleRead,
    required this.onToggleBookmark,
  });

  final bool isDesktop;
  final String title;
  final bool isMarkRead;
  final bool isBookmarkedDone;
  final VoidCallback onBack;
  final VoidCallback onToggleRead;
  final VoidCallback onToggleBookmark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTokens.brand, AppTokens.brand2],
        ),
      ),
      padding: isDesktop
          ? const EdgeInsets.symmetric(
              vertical: AppTokens.s20,
              horizontal: AppTokens.s20,
            )
          : const EdgeInsets.only(
              top: AppTokens.s32 + AppTokens.s24,
              left: AppTokens.s16,
              right: AppTokens.s16,
              bottom: AppTokens.s16,
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: AppTokens.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTokens.titleSm(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: AppTokens.s8),
                _MarkReadPill(
                  isMarkRead: isMarkRead,
                  onTap: onToggleRead,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          InkWell(
            onTap: onToggleBookmark,
            borderRadius: BorderRadius.circular(AppTokens.r8),
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.s8),
              child: Icon(
                isBookmarkedDone
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: AppColors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkReadPill extends StatelessWidget {
  const _MarkReadPill({
    required this.isMarkRead,
    required this.onTap,
  });

  final bool isMarkRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.r20),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s12,
          vertical: AppTokens.s4,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppTokens.r20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 18,
              color: isMarkRead
                  ? AppTokens.success(context)
                  : AppTokens.ink(context),
            ),
            const SizedBox(width: AppTokens.s4),
            Text(
              isMarkRead ? "Read" : "Mark as Read",
              style: AppTokens.caption(context).copyWith(
                fontWeight: FontWeight.w600,
                color: isMarkRead
                    ? AppTokens.success(context)
                    : AppTokens.ink(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
