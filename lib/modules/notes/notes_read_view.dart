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
import 'package:shusruta_lms/modules/notes/reading_preferences_sheet.dart';
import 'package:shusruta_lms/modules/notes/sharedhelper.dart';
import 'package:shusruta_lms/modules/notes/store/notes_category_store.dart';

import '../../helpers/app_feedback.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/constants.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/haptics.dart';
import '../../helpers/share_helpers.dart';
import '../../services/recent_notes_service.dart';
import '../dashboard/store/home_store.dart';
import '../videolectures/store/video_category_store.dart';
import 'notes_viewer.dart';

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
  const NotesReadView(
      {super.key,
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
      this.annotationData});

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
    Key? key,
    required this.pdfUrl,
    required this.titleId,
    required this.initialAnnotationJson,
    this.initialPage,
    this.isFromNormal = true,
    this.onAnnotationsChanged,
    this.onDocumentLoaded,
    this.onStateCreated,
  }) : super(key: key);

  @override
  NotesViewerWrapperState createState() => NotesViewerWrapperState();
}

class NotesViewerWrapperState extends State<NotesViewerWrapper> {
  final GlobalKey<NotesViewerState> _notesViewerKey = GlobalKey<NotesViewerState>();

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
  String _selectedText = '';
  final String _documentPath = "https://pdftron.s3.amazonaws.com/downloads/pl/PDFTRON_mobile_about.pdf";
  String? _document;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  late NotesViewerWrapperState? _notesViewerWrapperState;

  @override
  void initState() {
    super.initState();
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _initializeNotifications();
    _createVideoNoteHistory();
    isBookmarkedDone = widget.isBookmark ?? false;
    isDownloadedPdf = widget.isDownloaded ?? false;
    isMarkRead = widget.isCompleted ?? false;
    // if (widget.isDownloaded == false) {
    _getPdfContent();
    // }
    getPermission();

    // Record this open into the recents cache so the new browse
    // screen can surface this PDF in the "Continue reading" rail.
    // Fire-and-forget — failures don't block the reader.
    if ((widget.titleId ?? '').isNotEmpty) {
      // ignore: discarded_futures
      RecentNotesService.instance.recordOpen(
        RecentNoteEntry(
          titleId: widget.titleId!,
          title: widget.title,
          contentUrl: widget.fileUrl ?? '',
          topicId: widget.topicId,
          topicName: widget.topic_name,
          subcategoryId: widget.subcategoryId,
          subcategoryName: widget.subcategory_name,
          categoryId: widget.categoryId,
          categoryName: widget.category_name,
          lastPage: widget.pageNo,
          isCompleted: widget.isCompleted ?? false,
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    const AndroidNotificationChannel androidNotificationChannel = AndroidNotificationChannel(
      'download_channel',
      'Downloads',
      description: 'Notifications for download progress',
      importance: Importance.high,
    );

    // Now create the channel
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidNotificationChannel);
  }

  Future<void> getPermission() async {
    try {
      if (!Platform.isAndroid) {
        // iOS doesn't need storage permission for this flow
        setState(() {
          permissionGranted = true;
        });
        return;
      }
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
      } else {
        setState(() {
          permissionGranted = true;
        });
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

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<NotesCategoryStore>(context, listen: false);
    return WillPopScope(
      onWillPop: () async {
        try {
          // Add delay to allow any pending animations to complete
          await Future.delayed(Duration(milliseconds: 300));
          if (!mounted) return false;

          await _notesViewerWrapperState?.saveLastPageToBackend();
          await _notesViewerWrapperState?.exportAndSaveAnnotations();

          // Add another small delay before allowing pop
          await Future.delayed(Duration(milliseconds: 200));
          return mounted;
        } catch (e, st) {
          FirebaseCrashlytics.instance.recordError(e, st);
          return mounted;
        }
      },
      child: Scaffold(
        // Apple-style mini-FAB pinned bottom-right. Saves annotations
        // explicitly (auto-save runs on dispose). Uses accent color +
        // soft shadow + 16pt radius — matches the rest of the app.
        floatingActionButton: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: AppTokens.accent(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () async {
                Haptics.medium();
                await _notesViewerWrapperState?.exportAndSaveAnnotations();
                if (mounted) {
                  AppFeedback.success(context, 'Notes saved');
                }
              },
              child: Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.save_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
        backgroundColor: AppTokens.scaffold(context),
        body: Observer(builder: (BuildContext context) {
          final isDownloading = store.isDownloading(widget.titleId?.toString() ?? "");

          return Container(
            // Apple-style reader chrome: ink-tone header for contrast
            // against the white page below; matches iBooks / Apple
            // Books on dark mode.
            color: AppTokens.ink(context),
            child: Column(
              children: [
                Padding(
                  padding: (Platform.isWindows || Platform.isMacOS)
                      ? const EdgeInsets.symmetric(vertical: AppTokens.s12, horizontal: AppTokens.s12)
                      : const EdgeInsets.only(
                          top: AppTokens.s32, left: AppTokens.s8, right: AppTokens.s8, bottom: AppTokens.s8),
                  child: Row(
                    children: [
                      IconButton(
                          highlightColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          onPressed: () async {
                            Haptics.selection();
                            await _notesViewerWrapperState?.saveLastPageToBackend();
                            await _notesViewerWrapperState?.exportAndSaveAnnotations();
                            if (mounted) Navigator.pop(context);
                          },
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.white,
                            size: 18,
                          )),
                      if (_selectedText.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.highlight, color: AppColors.white),
                          onPressed: () {},
                        ),
                      const SizedBox(width: AppTokens.s4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTokens.titleSm(context).copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Mark-as-read pill — flips to a soft
                            // "Read" badge when complete.
                            InkWell(
                              onTap: () {
                                Haptics.medium();
                                setState(() {
                                  isMarkRead = !isMarkRead;
                                });
                                _createVideoHistory();
                              },
                              borderRadius: BorderRadius.circular(50),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppTokens.s8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isMarkRead
                                      ? AppTokens.success(context).withOpacity(0.18)
                                      : Colors.white.withOpacity(0.16),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isMarkRead ? Icons.check_circle_rounded : Icons.circle_outlined,
                                      color: isMarkRead ? AppTokens.success(context) : Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isMarkRead ? "Read" : "Mark as read",
                                      style: AppTokens.caption(context).copyWith(
                                        color: isMarkRead ? AppTokens.success(context) : Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Reading preferences (sepia/dark/brightness/etc).
                      IconButton(
                        tooltip: 'Reading options',
                        icon: const Icon(
                          Icons.text_format_rounded,
                          color: AppColors.white,
                          size: 22,
                        ),
                        onPressed: () {
                          Haptics.selection();
                          ReadingPreferencesSheet.show(context);
                        },
                      ),
                      // Share PDF link.
                      IconButton(
                        tooltip: 'Share',
                        icon: const Icon(
                          Icons.ios_share_rounded,
                          color: AppColors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          Haptics.selection();
                          ShareHelpers.openUrlAsLink(
                            context,
                            text: "${widget.title}\n\nReading on Sushruta LGS",
                            url: pdfBaseUrl + modifiedString,
                          );
                        },
                      ),
                      InkWell(
                        onTap: () {
                          Haptics.medium();
                          setState(() {
                            isBookmarkedDone = !isBookmarkedDone;
                          });
                          _putBookMarkApiCall();
                          AppFeedback.success(
                            context,
                            isBookmarkedDone ? 'Bookmarked' : 'Bookmark removed',
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            isBookmarkedDone ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                            color: AppColors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: AppTokens.s4,
                      ),
                      // isDownloading
                      //     ? SizedBox(
                      //         width: 20,
                      //         height: 20,
                      //         child: CircularProgressIndicator(
                      //           color: ThemeManager.white,
                      //         ),
                      //       )
                      //     : isDownloadedPdf
                      //         ? InkWell(
                      //             onTap: () {
                      //               showDialog(
                      //                 context: context,
                      //                 builder: (BuildContext context) {
                      //                   return AlertDialog(
                      //                     title: Text(
                      //                       "Delete Confirmation",
                      //                       style: interRegular.copyWith(
                      //                         fontSize:
                      //                             Dimensions.fontSizeDefault,
                      //                         fontWeight: FontWeight.w600,
                      //                         color: ThemeManager.blackColor,
                      //                       ),
                      //                     ),
                      //                     content: Text(
                      //                       "Are you sure you want to delete the offline downloaded note?",
                      //                       style: interRegular.copyWith(
                      //                         fontSize:
                      //                             Dimensions.fontSizeSmall,
                      //                         fontWeight: FontWeight.w600,
                      //                         color: ThemeManager.blackColor,
                      //                       ),
                      //                     ),
                      //                     actions: [
                      //                       TextButton(
                      //                         onPressed: () {
                      //                           Navigator.pop(context);
                      //                         },
                      //                         child: Text(
                      //                           "Cancel",
                      //                           style: interRegular.copyWith(
                      //                             fontSize: Dimensions
                      //                                 .fontSizeDefault,
                      //                             fontWeight: FontWeight.w600,
                      //                             color:
                      //                                 ThemeManager.blackColor,
                      //                           ),
                      //                         ),
                      //                       ),
                      //                       ElevatedButton(
                      //                         onPressed: () async {
                      //                           Navigator.pop(context);
                      //                           Navigator.pop(context);
                      //                           Navigator.pop(context);
                      //                           setState(() {});
                      //                         },
                      //                         style: ElevatedButton.styleFrom(
                      //                           backgroundColor:
                      //                               AppColors.redText,
                      //                         ),
                      //                         child: Text(
                      //                           "Delete",
                      //                           style: interRegular.copyWith(
                      //                             fontSize: Dimensions
                      //                                 .fontSizeDefault,
                      //                             fontWeight: FontWeight.w600,
                      //                             color: ThemeManager.white,
                      //                           ),
                      //                         ),
                      //                       ),
                      //                     ],
                      //                   );
                      //                 },
                      //               );
                      //             },
                      //             child: Container(
                      //               height: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                      //               width: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                      //               alignment: Alignment.center,
                      //               decoration: BoxDecoration(
                      //                   color: ThemeManager.downloadColor,
                      //                   shape: BoxShape.circle),
                      //               child: SvgPicture.asset(
                      //                 "assets/image/offline_status_white.svg",
                      //                 color: ThemeManager.white,
                      //               ),
                      //             ),
                      //           )
                      //         : InkWell(
                      //             onTap: () {
                      //               String url = pdfBaseUrl + modifiedString;
                      //               String filename = pdfName;
                      //               downloadPDF(url, filename, store);
                      //             },
                      //             child: Container(
                      //               height: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                      //               width: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                      //               alignment: Alignment.center,
                      //               decoration: BoxDecoration(
                      //                   color: ThemeManager.downloadColor,
                      //                   shape: BoxShape.circle),
                      //               child: SvgPicture.asset(
                      //                 "assets/image/downloadIcon.svg",
                      //                 color: ThemeManager.white,
                      //               ),
                      //             ),
                      //           ),
                      const SizedBox(
                        width: Dimensions.PADDING_SIZE_SMALL,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(),
                    decoration: BoxDecoration(
                      color: ThemeManager.mainBackground,
                      borderRadius: (Platform.isWindows || Platform.isMacOS)
                          ? null
                          : const BorderRadius.only(
                              topLeft: Radius.circular(28.8),
                              topRight: Radius.circular(28.8),
                            ),
                    ),
                    child: Observer(
                      builder: (BuildContext context) {
                        if (store.isLoading) {
                          return Center(
                              child: CircularProgressIndicator(
                            color: ThemeManager.primaryColor,
                          ));
                        }
                        return Stack(
                          children: [
                            Center(
                              child: Container(
                                  decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(28.8),
                                        topRight: Radius.circular(28.8),
                                      )),
                                  child: ClipRRect(
                                    borderRadius: (Platform.isWindows || Platform.isMacOS)
                                        ? BorderRadius.zero
                                        : const BorderRadius.only(
                                            topLeft: Radius.circular(28.8),
                                            topRight: Radius.circular(28.8),
                                          ),
                                    child: NotesViewerWrapper(
                                      pdfUrl: pdfBaseUrl + modifiedString,
                                      titleId: widget.titleId!,
                                      initialAnnotationJson: jsonEncode(widget.annotationData),
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
                                  )),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
          // return Container(
          //   color: ThemeManager.blueFinalDark,
          //   child: Column(
          //     children: [
          //       Padding(
          //         padding: (Platform.isWindows || Platform.isMacOS)
          //             ? const EdgeInsets.symmetric(
          //                 vertical: Dimensions.PADDING_SIZE_LARGE * 1.2,
          //                 horizontal: Dimensions.PADDING_SIZE_LARGE * 1.2)
          //             : const EdgeInsets.only(
          //                 top: Dimensions.PADDING_SIZE_LARGE * 3,
          //                 left: Dimensions.PADDING_SIZE_LARGE * 1.2,
          //                 right: Dimensions.PADDING_SIZE_SMALL * 1.2,
          //                 bottom: Dimensions.PADDING_SIZE_SMALL * 1.3),
          //         child: Row(
          //           children: [
          //             IconButton(
          //                 highlightColor: Colors.transparent,
          //                 hoverColor: Colors.transparent,
          //                 onPressed: () async {
          //                   try {
          //                     // Add delay to allow any pending animations to complete
          //                     await Future.delayed(Duration(milliseconds: 300));
          //                     if (!mounted) return;

          //                     await _notesViewerWrapperState?.saveLastPageToBackend();
          //                     await _notesViewerWrapperState?.exportAndSaveAnnotations();

          //                     // Add another small delay before navigation
          //                     await Future.delayed(Duration(milliseconds: 200));
          //                     if (mounted) {
          //                       Navigator.pop(context);
          //                     }
          //                   } catch (e, st) {
          //                     FirebaseCrashlytics.instance.recordError(e, st);
          //                     // Still try to navigate even if save fails
          //                     if (mounted) {
          //                   Navigator.pop(context);
          //                     }
          //                   }
          //                 },
          //                 icon: const Icon(
          //                   Icons.arrow_back_ios_new_rounded,
          //                   color: AppColors.white,
          //                 )),

          //               IconButton(
          //                 icon: const Icon(Icons.highlight),
          //                 onPressed: () async {
          //                   // Add a short delay to allow ripple animation to finish before opening annotation toolbar (fixes Android crash)
          //                   await Future.delayed(const Duration(milliseconds: 150));
          //                   if (_notesViewerWrapperState != null && mounted) {
          //                     _notesViewerWrapperState?.openAnnotationToolbar();
          //                   }
          //                 },
          //               ),
          //             const SizedBox(
          //               width: Dimensions.PADDING_SIZE_SMALL,
          //             ),
          //             Column(
          //               crossAxisAlignment: CrossAxisAlignment.start,
          //               children: [
          //                 SizedBox(
          //                   width: MediaQuery.of(context).size.width * 0.5,
          //                   child: Text(
          //                     " ${widget.title}",
          //                     style: interRegular.copyWith(
          //                       fontSize: Dimensions.fontSizeDefault,
          //                       fontWeight: FontWeight.w600,
          //                       color: AppColors.white,
          //                     ),
          //                   ),
          //                 ),
          //                 const SizedBox(
          //                   height: Dimensions.PADDING_SIZE_SMALL,
          //                 ),
          //                 InkWell(
          //                   onTap: () {
          //                     setState(() {
          //                       isMarkRead = !isMarkRead;
          //                     });
          //                     _createVideoHistory();
          //                   },
          //                   child: Container(
          //                     padding: const EdgeInsets.symmetric(
          //                         horizontal:
          //                             Dimensions.PADDING_SIZE_SMALL * 1.2,
          //                         vertical:
          //                             Dimensions.PADDING_SIZE_EXTRA_SMALL *
          //                                 1.2),
          //                     decoration: BoxDecoration(
          //                         color: ThemeManager.whitePrimary,
          //                         borderRadius: BorderRadius.circular(50.53)),
          //                     child: Row(
          //                       children: [
          //                         Icon(Icons.check_circle_outline,
          //                             color: isMarkRead == true
          //                                 ? Colors.green
          //                                 : ThemeManager.blackColor,
          //                             size: 24),
          //                         Text(
          //                           isMarkRead == true
          //                               ? "Read"
          //                               : "Mark as Read",
          //                           style: interRegular.copyWith(
          //                             fontSize: Dimensions.fontSizeSmall,
          //                             fontWeight: FontWeight.w500,
          //                             color: isMarkRead == true
          //                                 ? Colors.green
          //                                 : ThemeManager.blackColor,
          //                           ),
          //                         ),
          //                       ],
          //                     ),
          //                   ),
          //                 ),
          //               ],
          //             ),
          //             const Spacer(),
          //             InkWell(
          //               onTap: () {
          //                 setState(() {
          //                   isBookmarkedDone = !isBookmarkedDone;
          //                 });
          //                 _putBookMarkApiCall();
          //               },
          //               child: Icon(
          //                 isBookmarkedDone == true
          //                     ? Icons.bookmark
          //                     : Icons.bookmark_border,
          //                 color: isBookmarkedDone == true
          //                     ? ThemeManager.currentTheme == AppTheme.Light
          //                         ? ThemeManager.white
          //                         : Colors.white
          //                     : ThemeManager.currentTheme == AppTheme.Light
          //                         ? ThemeManager.white
          //                         : Colors.white,
          //                 size: 24,
          //               ),
          //             ),
          //             const SizedBox(
          //               width: Dimensions.PADDING_SIZE_SMALL * 1.4,
          //             ),
          //             isDownloading
          //                 ? SizedBox(
          //                     width: 20,
          //                     height: 20,
          //                     child: CircularProgressIndicator(
          //                       color: ThemeManager.white,
          //                     ),
          //                   )
          //                 : isDownloadedPdf
          //                     ? InkWell(
          //                         onTap: () {
          //                           showDialog(
          //                             context: context,
          //                             builder: (BuildContext context) {
          //                               return AlertDialog(
          //                                 title: Text(
          //                                   "Delete Confirmation",
          //                                   style: interRegular.copyWith(
          //                                     fontSize:
          //                                         Dimensions.fontSizeDefault,
          //                                     fontWeight: FontWeight.w600,
          //                                     color: ThemeManager.blackColor,
          //                                   ),
          //                                 ),
          //                                 content: Text(
          //                                   "Are you sure you want to delete the offline downloaded note?",
          //                                   style: interRegular.copyWith(
          //                                     fontSize:
          //                                         Dimensions.fontSizeSmall,
          //                                     fontWeight: FontWeight.w600,
          //                                     color: ThemeManager.blackColor,
          //                                   ),
          //                                 ),
          //                                 actions: [
          //                                   TextButton(
          //                                     onPressed: () {
          //                                       Navigator.pop(context);
          //                                     },
          //                                     child: Text(
          //                                       "Cancel",
          //                                       style: interRegular.copyWith(
          //                                         fontSize: Dimensions
          //                                             .fontSizeDefault,
          //                                         fontWeight: FontWeight.w600,
          //                                         color:
          //                                             ThemeManager.blackColor,
          //                                       ),
          //                                     ),
          //                                   ),
          //                                   ElevatedButton(
          //                                     onPressed: () async {
          //                                       Navigator.pop(context);
          //                                       Navigator.pop(context);
          //                                       Navigator.pop(context);
          //                                       setState(() {});
          //                                     },
          //                                     style: ElevatedButton.styleFrom(
          //                                       backgroundColor:
          //                                           AppColors.redText,
          //                                     ),
          //                                     child: Text(
          //                                       "Delete",
          //                                       style: interRegular.copyWith(
          //                                         fontSize: Dimensions
          //                                             .fontSizeDefault,
          //                                         fontWeight: FontWeight.w600,
          //                                         color: ThemeManager.white,
          //                                       ),
          //                                     ),
          //                                   ),
          //                                 ],
          //                               );
          //                             },
          //                           );
          //                         },
          //                         child: Container(
          //                           height: Dimensions.PADDING_SIZE_EXTRA_LARGE,
          //                           width: Dimensions.PADDING_SIZE_EXTRA_LARGE,
          //                           alignment: Alignment.center,
          //                           decoration: BoxDecoration(
          //                               color: ThemeManager.downloadColor,
          //                               shape: BoxShape.circle),
          //                           child: SvgPicture.asset(
          //                             "assets/image/offline_status_white.svg",
          //                             color: ThemeManager.white,
          //                           ),
          //                         ),
          //                       )
          //                     : InkWell(
          //                         onTap: () {
          //                           String url = pdfBaseUrl + modifiedString;
          //                           String filename = pdfName;
          //                           downloadPDF(url, filename, store);
          //                         },
          //                         child: Container(
          //                           height: Dimensions.PADDING_SIZE_EXTRA_LARGE,
          //                           width: Dimensions.PADDING_SIZE_EXTRA_LARGE,
          //                           alignment: Alignment.center,
          //                           decoration: BoxDecoration(
          //                               color: ThemeManager.downloadColor,
          //                               shape: BoxShape.circle),
          //                           child: SvgPicture.asset(
          //                             "assets/image/downloadIcon.svg",
          //                             color: ThemeManager.white,
          //                           ),
          //                         ),
          //                       ),
          //             const SizedBox(
          //               width: Dimensions.PADDING_SIZE_SMALL,
          //             ),
          //           ],
          //         ),
          //       ),
          //       Expanded(
          //         child: Container(
          //           width: double.infinity,
          //           padding: const EdgeInsets.only(
          //               // left: Dimensions.PADDING_SIZE_LARGE*1.2,
          //               // right: Dimensions.PADDING_SIZE_LARGE*1.2,
          //               // top: Dimensions.PADDING_SIZE_EXTRA_LARGE
          //               ),
          //           decoration: BoxDecoration(
          //             color: ThemeManager.mainBackground,
          //             borderRadius: (Platform.isWindows || Platform.isMacOS)
          //                 ? null
          //                 : const BorderRadius.only(
          //                     topLeft: Radius.circular(28.8),
          //                     topRight: Radius.circular(28.8),
          //                   ),
          //           ),
          //           child: Observer(
          //             builder: (BuildContext context) {
          //               if (store.isLoading) {
          //                 return Center(
          //                     child: CircularProgressIndicator(
          //                   color: ThemeManager.primaryColor,
          //                 ));
          //               }
          //               return Stack(
          //                 children: [
          //                   Center(
          //                     child: Container(
          //                         decoration: BoxDecoration(
          //                             color: ThemeManager.borderBlue,
          //                             borderRadius: const BorderRadius.only(
          //                               topLeft: Radius.circular(28.8),
          //                               topRight: Radius.circular(28.8),
          //                             )),
          //                         child: ClipRRect(
          //                           borderRadius:
          //                               (Platform.isWindows || Platform.isMacOS)
          //                                   ? BorderRadius.zero
          //                                   : const BorderRadius.only(
          //                                       topLeft: Radius.circular(28.8),
          //                                       topRight: Radius.circular(28.8),
          //                                     ),
          //                           child: NotesViewerWrapper(
          //                             pdfUrl: pdfBaseUrl + modifiedString,
          //                             titleId: widget.titleId!,
          //                             initialAnnotationJson:
          //                                 jsonEncode(widget.annotationData),
          //                             initialPage: widget.pageNo,
          //                             isFromNormal: true,
          //                             onAnnotationsChanged: () {
          //                               setState(() {});
          //                             },
          //                             onDocumentLoaded: () {
          //                               setState(() {});
          //                             },
          //                             onStateCreated: (state) {
          //                               _notesViewerWrapperState = state;
          //                             },
          //                           ),
          //                         )),
          //                   ),
          //                 ],
          //               );
          //             },
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // );
        }),
      ),
    );
  }

  Future<void> downloadPDF(String url, String filename, NotesCategoryStore store) async {
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

        response.stream.listen((data) {
          downloadedBytes += data.length;
          fileSink.add(data);

          if (totalBytes > 0) {
            double progress = ((downloadedBytes / totalBytes) * 100).clamp(0, 100);
            _updatePDFDownloadProgressNotification(progress.toInt());
            debugPrint("PDF Download Progress: $progress%");
          }
        }, onDone: () async {
          await fileSink.close();
          store.completeDownload(titleId);
          if (!isDesktop) {
            _showPDFDownloadNotification(
                'PDF Download Complete', "${widget.title} has been saved offline successfully.");
          }
          if (mounted) {
            setState(() {
              isDownloadedPdf = true;
            });
          }
        }, onError: (e) async {
          debugPrint("Error downloading PDF: $e");
          store.cancelDownload(titleId);
          await fileSink.close();
        }, cancelOnError: true);
      } else {
        debugPrint("Failed to download PDF. Status code: ${response.statusCode}");
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

    NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      1, // Unique Notification ID
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

    NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      1, // Unique Notification ID
      'PDF Download in Progress',
      'Downloading... $progress%',
      platformDetails,
    );
  }

  void _showPDFDownloadNotification(String title, String message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pdf_download_channel',
      'PDF Downloads',
      channelDescription: 'Notifications for completed PDF downloads',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      1, // Unique Notification ID
      title,
      message,
      platformDetails,
    );
  }
}
