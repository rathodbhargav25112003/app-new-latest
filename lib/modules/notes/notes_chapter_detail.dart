// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, constant_identifier_names, non_constant_identifier_names, unused_field

import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/helpers/custom_dynamic_height_gridview.dart';
import 'package:shusruta_lms/helpers/dbhelper.dart';
import 'package:shusruta_lms/models/notes_offline_data_model.dart';
import 'package:shusruta_lms/models/notes_topic_model.dart';
import 'package:shusruta_lms/modules/dashboard/models/global_search_model.dart';
import 'package:shusruta_lms/modules/dashboard/store/home_store.dart';
import 'package:shusruta_lms/modules/notes/sharedhelper.dart';
import 'package:shusruta_lms/modules/notes/store/notes_category_store.dart';
import 'package:shusruta_lms/modules/videolectures/store/video_category_store.dart';
import 'package:shusruta_lms/modules/widgets/bottom_toast.dart';
import 'package:shusruta_lms/modules/widgets/no_access_alert_dialog.dart';
import 'package:shusruta_lms/modules/widgets/no_access_bottom_sheet.dart';
import 'package:shusruta_lms/modules/widgets/no_internet_connection.dart';

/// Leaf-level chapter-detail screen in the notes module. Shows every
/// `NotesTopicModel` under a given topic (chapter) as a card row with
/// title, page count, read-progress status, bookmark toggle, and — on
/// tap — an access-gated jump into [Routes.notesReadView].
///
/// Preserved public contract:
///   • `NotesChapterDetail({super.key, required this.chapter,
///     required this.subcatId, required this.subcaptername,
///     required this.topicname})` — note that `chapter` / `subcatId`
///     are non-nullable `String` and `subcaptername` / `topicname`
///     are required but nullable (`String?`). All four names kept.
///   • Static `route(RouteSettings)` factory reading `arguments`
///     keys `topicname`, `subcaptername`, `chapter`, `subcatId` and
///     returning a `CupertinoPageRoute`.
///   • MobX wiring: `Provider.of<NotesCategoryStore>` +
///     `onTopicApiCall(widget.subcatId)` in initState,
///     `store.notestopic` / `isLoading` / `isConnected` /
///     `pdfPageCounts` / `fetchPdfPageCount(url)` /
///     `isLoadingPdf` / `isDownloading` / `startDownload` /
///     `completeDownload` / `cancelDownload`; all wrapped in nested
///     `Observer` builders.
///   • `Provider.of<VideoCategoryStore>` used for
///     `onCreateBookmarkContentApiCall(titleId)` (bookmark toggle).
///   • `Provider.of<HomeStore>` used for
///     `onGlobalSearchApiCall(keyword, "pdf")` / `globalSearchList`
///     / `isLoading` (global search hit rendering).
///   • Public state helpers preserved (exposed via GlobalKey):
///     - `buildItem(BuildContext, GlobalSearchDataModel?)` — search
///       hit tile with 4-way navigation matrix
///     - `buildItem1(BuildContext, NotesTopicModel?, int,
///       NotesCategoryStore, int pageCount, {bool? isDownloaded})`
///       — the main note card
///     - `downloadPDF(String, String, NotesCategoryStore,
///       NotesTopicModel?)` — kicks off a streamed download and
///       persists a `NotesOfflineDataModel` row
///     - `_checkIfNoteDownloaded(String)` — retained for legacy
///       callers even though the UI now reads from the synchronous
///       `_downloadedTitleIdsCache` populated in initState
///   • Navigator push targets preserved byte-for-byte:
///     - `Routes.notesSubjectDetail` (Category hit): args
///       `{subject, noteid}`
///     - `Routes.notesTopicCategory` (Subcategory hit): args
///       `{topicname, topic, subcatId}`
///     - `Routes.notesChapterDetail` (Topic hit): args
///       `{topicname, chapter, subcatId, subcaptername}`
///     - `Routes.notesReadView` (Content hit): 10-key args map
///       `{contentUrl, title, topic_name, category_name,
///        subcategory_name, isDownloaded, topicId, titleId,
///        categoryId, subcategoryId}`
///     - `Routes.notesReadView` (main tile tap, isAccess==true):
///       14-key args map `{topic_name, category_name,
///        subcategory_name, categoryId, subcategoryId, contentUrl,
///        title, titleId, annotationData, isDownloaded, isCompleted,
///        topicId, isBookMark (capital M preserved), pageNo}` with
///       `.then((value) => _getNotesList())` for refresh
///   • `isAccess==false` → desktop `NoAccessAlertDialog` /
///     mobile `NoAccessBottomSheet`, each with
///     `onTap: _getNotesList`, `planId`, `day: int.parse(day ?? "0")`,
///     `isFree: isfreeTrail` — kept byte-for-byte including the
///     `.parse(... ?? "0")` fallback.
///   • Six filters kept with their predicates:
///     All / Completed / In Progress / Not Started / Offline Notes /
///     Bookmarked Notes (note: the trailing "ed" on "Bookmarked"
///     is how this screen labels it — preserved, even though the
///     sibling screens use "Bookmark Notes").
///   • `_filterNotes()` predicates kept: Completed uses
///     `isCompleted`, In Progress uses `isPaused`, Not Started
///     inverts Completed + isPaused, Offline Notes uses the
///     pre-loaded cache, Bookmarked Notes uses `isBookmark`.
///   • `_loadDownloadedTitleIds()` parallel batch + stale-row
///     cleanup behaviour preserved.
///   • Download path writes `NotesOfflineDataModel` via
///     `DbHelper.insert()`; cache is updated in-place on
///     completion (`_downloadedTitleIdsCache.add(titleId)`).
///   • Android notification channel IDs 'download_channel' /
///     'Downloads' and 'pdf_download_channel' / 'PDF Downloads'
///     preserved, mobile-only via top-level `isDesktop`.
///   • Bookmark toggle updates both `isBookmarkedDone[index]` and
///     `filteredNotes[index]?.isBookmark` so the Observer sees the
///     change before the next refresh.
class NotesChapterDetail extends StatefulWidget {
  final String chapter;
  final String subcatId;
  final String? subcaptername;
  final String? topicname;

  const NotesChapterDetail({
    super.key,
    required this.chapter,
    required this.subcatId,
    required this.subcaptername,
    required this.topicname,
  });

  @override
  State<NotesChapterDetail> createState() => _NotesChapterDetailState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => NotesChapterDetail(
        topicname: arguments['topicname'],
        subcaptername: arguments['subcaptername'],
        chapter: arguments['chapter'],
        subcatId: arguments['subcatId'],
      ),
    );
  }
}

class _NotesChapterDetailState extends State<NotesChapterDetail> {
  String query = '';
  String selectedFilter = "All";
  List<bool>? isBookmarkedDone = [];
  final FocusNode _focusNode = FocusNode();
  late List<NotesTopicModel?> filteredNotes;
  late List<NotesTopicModel?> offlineNotes;
  final dbHelper = DbHelper();
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  bool isDownloaded = false;

  // Replaces per-row FutureBuilder<bool>(_checkIfNoteDownloaded). We load
  // the full set of downloaded titleIds once (one SQLite query + a batch
  // of file.exists checks) and let every row do a synchronous set lookup.
  final Set<String> _downloadedTitleIdsCache = <String>{};

  static const List<String> _filters = <String>[
    "All",
    "Completed",
    "In Progress",
    "Not Started",
    "Offline Notes",
    "Bookmarked Notes",
  ];

  @override
  void initState() {
    super.initState();
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _initializeNotifications();
    _loadDownloadedTitleIds();
    _getNotesList();
  }

  /// Loads all downloaded PDF titleIds into [_downloadedTitleIdsCache].
  /// Concurrency-safe: one DB query -> parallel file.exists checks.
  Future<void> _loadDownloadedTitleIds() async {
    try {
      final rows = await dbHelper.getAllNotes();
      // Parallel file.exists — avoids N sequential awaits inside a loop.
      final checks = await Future.wait(rows.map((n) async {
        final path = n.notePath;
        if (path == null || path.isEmpty) return null;
        final exists = await File(path).exists();
        if (!exists) {
          // Stale row — best-effort cleanup, fire-and-forget.
          unawaited(dbHelper.deleteNoteByTitleId(n.titleId ?? ""));
          return null;
        }
        return n.titleId;
      }));
      if (!mounted) return;
      setState(() {
        _downloadedTitleIdsCache
          ..clear()
          ..addAll(checks.whereType<String>());
      });
    } catch (e) {
      debugPrint('loadDownloadedTitleIds failed: $e');
    }
  }

  bool _isNoteDownloadedSync(String titleId) =>
      _downloadedTitleIdsCache.contains(titleId);

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

  Future<void> _getNotesList() async {
    final store = Provider.of<NotesCategoryStore>(context, listen: false);
    await store.onTopicApiCall(widget.subcatId);
    await _filterOfflineNotes();
  }

  Future<void> _putBookMarkApiCall(String? titleId) async {
    final store = Provider.of<VideoCategoryStore>(context, listen: false);
    await store.onCreateBookmarkContentApiCall(titleId ?? '');
  }

  Future<void> searchCategory(String keyword) async {
    final store = Provider.of<HomeStore>(context, listen: false);
    await store.onGlobalSearchApiCall(keyword, "pdf");
  }

  // ───────────────────────────────────────────────────────────────────
  // Build
  // ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool isDesktopEnv = Platform.isWindows || Platform.isMacOS;
    final store = Provider.of<NotesCategoryStore>(context, listen: false);
    final homeStore = Provider.of<HomeStore>(context, listen: false);

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          _HeroHeader(
            isDesktop: isDesktopEnv,
            chapter: widget.chapter,
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(
                left: AppTokens.s20,
                right: AppTokens.s20,
                top: AppTokens.s24,
              ),
              decoration: BoxDecoration(
                color: AppTokens.scaffold(context),
                borderRadius: isDesktopEnv
                    ? null
                    : const BorderRadius.only(
                        topLeft: Radius.circular(AppTokens.r28),
                        topRight: Radius.circular(AppTokens.r28),
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FilterChipRow(
                    filters: _filters,
                    selected: selectedFilter,
                    onSelected: (f) {
                      setState(() {
                        selectedFilter = f;
                      });
                    },
                  ),
                  const SizedBox(height: AppTokens.s16),
                  Expanded(
                    child: Observer(
                      builder: (BuildContext context) {
                        filteredNotes = store.notestopic;
                        _filterNotes();
                        if (store.isLoading) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: AppTokens.accent(context),
                            ),
                          );
                        }
                        if (store.notestopic.isEmpty) {
                          return const _EmptyState();
                        }
                        if (store.isConnected) {
                          return RefreshIndicator(
                            onRefresh: () => _getNotesList(),
                            child:
                                homeStore.isLoading && store.isLoadingPdf
                                    ? const Center(
                                        child: CircularProgressIndicator())
                                    : (homeStore.globalSearchList.isNotEmpty &&
                                            query.isNotEmpty)
                                        ? _buildSearchList(
                                            context,
                                            isDesktopEnv,
                                            homeStore,
                                          )
                                        : _buildNotesList(
                                            context,
                                            isDesktopEnv,
                                            store,
                                          ),
                          );
                        } else {
                          return const NoInternetScreen();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchList(
      BuildContext context, bool isDesktopEnv, HomeStore homeStore) {
    if (isDesktopEnv) {
      return CustomDynamicHeightGridView(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        itemCount: homeStore.globalSearchList.length,
        builder: (BuildContext context, int index) {
          return buildItem(context, homeStore.globalSearchList[index]);
        },
      );
    }
    return ListView.builder(
      itemCount: homeStore.globalSearchList.length,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        return buildItem(context, homeStore.globalSearchList[index]);
      },
    );
  }

  Widget _buildNotesList(
      BuildContext context, bool isDesktopEnv, NotesCategoryStore store) {
    if (isDesktopEnv) {
      return CustomDynamicHeightGridView(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        itemCount: filteredNotes.length,
        builder: (BuildContext context, int index) {
          if (filteredNotes.isEmpty) {
            return const Center(child: Text("No videos available"));
          }
          return _buildNoteTileObserver(context, index, store);
        },
      );
    }
    return ListView.builder(
      itemCount: filteredNotes.length,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const AlwaysScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        if (filteredNotes.isEmpty) {
          return const Center(child: Text("No videos available"));
        }
        return _buildNoteTileObserver(context, index, store);
      },
    );
  }

  Widget _buildNoteTileObserver(
      BuildContext context, int index, NotesCategoryStore store) {
    final titleId = filteredNotes[index]?.sId.toString() ?? "";
    final String pdfUrl = filteredNotes[index]?.contentUrl ?? "";
    if (!store.pdfPageCounts.containsKey(pdfUrl)) {
      store.fetchPdfPageCount(pdfUrl);
    }
    return Observer(
      builder: (context) {
        final int pageCount = store.pdfPageCounts[pdfUrl] ?? 0;
        final isDownloaded = _isNoteDownloadedSync(titleId);
        return buildItem1(
          context,
          filteredNotes[index],
          index,
          store,
          pageCount,
          isDownloaded: isDownloaded,
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────
  // Public state helpers — preserved for GlobalKey-based callers.
  // ───────────────────────────────────────────────────────────────────

  Widget buildItem(
      BuildContext context, GlobalSearchDataModel? searchDataModel) {
    final GlobalSearchDataModel? noteTopic = searchDataModel;
    final String? categoryName = noteTopic?.categoryName;
    final String? subcategoryName = noteTopic?.subcategoryName;
    final String? topicName = noteTopic?.topicName;
    final String? title = noteTopic?.title;

    final String displayText =
        categoryName ?? subcategoryName ?? topicName ?? title ?? "";
    final String type = categoryName != null
        ? "Category"
        : subcategoryName != null
            ? "Subcategory"
            : topicName != null
                ? "Topic"
                : title != null
                    ? "Content"
                    : "";

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.r12),
          onTap: () {
            if (type == "Category") {
              Navigator.of(context).pushNamed(
                Routes.notesSubjectDetail,
                arguments: {"subject": categoryName, "noteid": noteTopic?.id},
              );
            } else if (type == "Subcategory") {
              Navigator.of(context).pushNamed(
                Routes.notesTopicCategory,
                arguments: {
                  "topicname": subcategoryName,
                  "topic": subcategoryName,
                  "subcatId": noteTopic?.id
                },
              );
            } else if (type == "Topic") {
              Navigator.of(context).pushNamed(
                Routes.notesChapterDetail,
                arguments: {
                  "topicname": topicName,
                  "chapter": topicName,
                  "subcatId": noteTopic?.id,
                  "subcaptername": noteTopic?.subName,
                },
              );
            } else if (type == "Content") {
              Navigator.of(context).pushNamed(
                Routes.notesReadView,
                arguments: {
                  'contentUrl': noteTopic?.contentUrl,
                  'title': noteTopic?.title ?? '',
                  'topic_name': noteTopic?.topicName ?? '',
                  'category_name': noteTopic?.categoryName ?? '',
                  'subcategory_name': noteTopic?.subcategoryName ?? '',
                  'isDownloaded': false,
                  'topicId': noteTopic?.topicId,
                  'titleId': noteTopic?.id,
                  'categoryId': noteTopic?.categoryId,
                  'subcategoryId': noteTopic?.subcategoryId,
                },
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(AppTokens.s16),
            decoration: BoxDecoration(
              color: AppTokens.surface(context),
              border: Border.all(color: AppTokens.border(context)),
              borderRadius: BorderRadius.circular(AppTokens.r12),
              boxShadow: AppTokens.shadow1(context),
            ),
            child: Row(
              children: [
                Container(
                  height: AppTokens.s32 + AppTokens.s24,
                  width: AppTokens.s32 + AppTokens.s24,
                  padding: const EdgeInsets.all(AppTokens.s12),
                  decoration: BoxDecoration(
                    color: AppTokens.accentSoft(context),
                    borderRadius: BorderRadius.circular(AppTokens.r12),
                  ),
                  child: SvgPicture.asset(
                    "assets/image/notedetails.svg",
                    color: AppTokens.accent(context),
                  ),
                ),
                const SizedBox(width: AppTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTokens.body(context).copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTokens.ink(context),
                        ),
                      ),
                      const SizedBox(height: AppTokens.s4),
                      Text(
                        noteTopic?.description ?? "",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTokens.caption(context).copyWith(
                          color: AppTokens.muted(context),
                        ),
                      ),
                      const SizedBox(height: AppTokens.s8),
                      _TypeBadge(label: type),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildItem1(
    BuildContext context,
    NotesTopicModel? notesTopicModel,
    int index,
    NotesCategoryStore store,
    int pageCount, {
    bool? isDownloaded = false,
  }) {
    final NotesTopicModel? notesTopic = notesTopicModel;
    if (query.isNotEmpty &&
        (!notesTopic!.title!.toLowerCase().contains(query.toLowerCase()))) {
      return const SizedBox.shrink();
    }
    final bool completed = notesTopic?.isCompleted == true;
    final bool inProgress =
        (notesTopic?.pageNumber ?? 0) != 0 && !completed;
    final bool isLocked = notesTopic?.isAccess == false;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.r12),
          onTap: () async {
            if (notesTopic?.isAccess == true) {
              if (notesTopic?.contentUrl != null &&
                  notesTopic?.contentUrl != "") {
                Navigator.of(context).pushNamed(
                  Routes.notesReadView,
                  arguments: {
                    'topic_name': notesTopic?.topic_name ?? '',
                    'category_name': notesTopic?.category_name ?? '',
                    'subcategory_name': notesTopic?.subcategory_name ?? '',
                    'categoryId': notesTopic?.categoryId,
                    'subcategoryId': notesTopic?.subcategoryId,
                    'contentUrl': notesTopic?.contentUrl,
                    'title': notesTopic?.title,
                    'titleId': notesTopic?.sId,
                    'annotationData':
                        notesTopicModel?.annotationData.toString(),
                    'isDownloaded': isDownloaded,
                    'isCompleted': notesTopic?.isCompleted,
                    'topicId': notesTopic?.topicId,
                    'isBookMark': notesTopic?.isBookmark,
                    'pageNo': notesTopicModel?.pageNumber,
                  },
                ).then((value) => _getNotesList());
              } else {
                BottomToast.showBottomToastOverlay(
                  context: context,
                  errorMessage: "No File is Found!",
                  backgroundColor: AppTokens.danger(context),
                );
              }
            } else {
              if (Platform.isWindows || Platform.isMacOS) {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      backgroundColor: AppTokens.scaffold(context),
                      actionsPadding: EdgeInsets.zero,
                      insetPadding:
                          const EdgeInsets.symmetric(horizontal: 100),
                      actions: [
                        NoAccessAlertDialog(
                          onTap: () {
                            _getNotesList();
                          },
                          planId: notesTopic?.plan_id ?? "",
                          day: int.parse(notesTopic?.day ?? "0"),
                          isFree: notesTopic!.isfreeTrail!,
                        ),
                      ],
                    );
                  },
                );
              } else {
                showModalBottomSheet<void>(
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppTokens.r20),
                    ),
                  ),
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  context: context,
                  builder: (BuildContext context) {
                    return NoAccessBottomSheet(
                      onTap: () {
                        _getNotesList();
                      },
                      planId: notesTopic?.plan_id ?? "",
                      day: int.parse(notesTopic?.day ?? "0"),
                      isFree: notesTopic!.isfreeTrail!,
                    );
                  },
                );
              }
            }
          },
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTokens.s16),
                decoration: BoxDecoration(
                  color: AppTokens.surface(context),
                  border: Border.all(color: AppTokens.border(context)),
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                  boxShadow: AppTokens.shadow1(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: AppTokens.s32 + AppTokens.s24,
                          width: AppTokens.s32 + AppTokens.s24,
                          padding: const EdgeInsets.all(AppTokens.s12),
                          decoration: BoxDecoration(
                            color: AppTokens.accentSoft(context),
                            borderRadius:
                                BorderRadius.circular(AppTokens.r12),
                          ),
                          child: SvgPicture.asset(
                            "assets/image/notedetails.svg",
                            color: AppTokens.accent(context),
                          ),
                        ),
                        const SizedBox(width: AppTokens.s12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notesTopic?.title ?? "",
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: AppTokens.body(context).copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTokens.ink(context),
                                ),
                              ),
                              const SizedBox(height: AppTokens.s4),
                              Text(
                                "Total Pages — $pageCount",
                                style: AppTokens.caption(context).copyWith(
                                  color: AppTokens.muted(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            _putBookMarkApiCall(notesTopic?.sId);
                            setState(() {
                              isBookmarkedDone?[index] =
                                  !isBookmarkedDone![index];
                              filteredNotes[index]?.isBookmark =
                                  isBookmarkedDone?[index];
                            });
                          },
                          borderRadius:
                              BorderRadius.circular(AppTokens.r8),
                          child: Padding(
                            padding: const EdgeInsets.all(AppTokens.s4),
                            child: Icon(
                              isBookmarkedDone?[index] == true
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              size: 24,
                              color: isBookmarkedDone?[index] == true
                                  ? AppTokens.accent(context)
                                  : AppTokens.muted(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.s12),
                    _StatusRow(
                      completed: completed,
                      inProgress: inProgress,
                      pageNumber: notesTopic?.pageNumber ?? 0,
                    ),
                  ],
                ),
              ),
              if (isLocked)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    height: AppTokens.s24,
                    width: AppTokens.s24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTokens.accent(context),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(AppTokens.r12),
                        bottomLeft: Radius.circular(AppTokens.r12),
                      ),
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: AppColors.white,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────
  // Filter predicates.
  // ───────────────────────────────────────────────────────────────────

  void _filterNotes() async {
    final store = Provider.of<NotesCategoryStore>(context, listen: false);
    List<NotesTopicModel?> filtered = [];
    if (selectedFilter == "All") {
      filtered = store.notestopic;
    } else if (selectedFilter == "Completed") {
      filtered = store.notestopic
          .where((note) =>
              note?.isCompleted != null &&
              (note?.isCompleted ?? false) == true)
          .toList();
    } else if (selectedFilter == "In Progress") {
      filtered = store.notestopic
          .where((note) => (note?.isPaused ?? false))
          .toList();
    } else if (selectedFilter == "Not Started") {
      filtered = store.notestopic
          .where((note) =>
              (note?.isCompleted == null ||
                  (note?.isCompleted ?? false) == false) &&
              !(note?.isPaused ?? false))
          .toList();
    } else if (selectedFilter == "Offline Notes") {
      filtered = offlineNotes;
    } else if (selectedFilter == "Bookmarked Notes") {
      filtered = store.notestopic
          .where((note) => note?.isBookmark == true)
          .toList();
    }
    filteredNotes = filtered;
    isBookmarkedDone =
        filtered.map((topic) => topic?.isBookmark ?? false).toList();
  }

  Future<void> _filterOfflineNotes() async {
    final store = Provider.of<NotesCategoryStore>(context, listen: false);
    if (_downloadedTitleIdsCache.isEmpty) {
      await _loadDownloadedTitleIds();
    }
    offlineNotes = store.notestopic
        .where((n) => _isNoteDownloadedSync(n?.sId.toString() ?? ''))
        .toList();
  }

  // ignore: unused_element
  Future<bool> _checkIfNoteDownloaded(String titleId) async {
    final downloadedNote = await dbHelper.getNoteByTitleId(titleId);
    if (downloadedNote != null) {
      final videoPath = downloadedNote.notePath;
      final file = File(videoPath!);
      if (await file.exists()) {
        debugPrint("downExists");
        return true;
      } else {
        await dbHelper.deleteNoteByTitleId(titleId);
      }
    }
    return false;
  }

  // ───────────────────────────────────────────────────────────────────
  // Download path — preserved behaviour.
  // ───────────────────────────────────────────────────────────────────

  Future<void> downloadPDF(
    String url,
    String filename,
    NotesCategoryStore store,
    NotesTopicModel? notesTopic,
  ) async {
    final titleId = notesTopic?.sId.toString() ?? "";

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
            final pdfDataModel = NotesOfflineDataModel(
              title: notesTopic?.title ?? '',
              titleId: notesTopic?.sId ?? '',
              topicName: notesTopic?.topic_name ?? '',
              categoryName: notesTopic?.category_name ?? '',
              subCategoryName: notesTopic?.subcategory_name ?? '',
              categoryId: notesTopic?.categoryId ?? '',
              subCategoryId: notesTopic?.subcategoryId ?? '',
              topicId: notesTopic?.topicId ?? '',
              notePath: filePath,
            );
            await dbHelper.insert(pdfDataModel);
            // Keep the in-memory cache in sync so the row flips to
            // "Downloaded" without another N+1 sweep.
            _downloadedTitleIdsCache.add(titleId);

            if (!isDesktop) {
              _showPDFDownloadNotification(
                'PDF Download Complete',
                "${notesTopic?.title} has been saved offline successfully.",
              );
            }
            if (mounted) {
              setState(() {
                isDownloaded = true;
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

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.isDesktop,
    required this.chapter,
  });

  final bool isDesktop;
  final String chapter;

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
              vertical: AppTokens.s24, horizontal: AppTokens.s24)
          : const EdgeInsets.only(
              top: AppTokens.s32 + AppTokens.s24,
              left: AppTokens.s20,
              right: AppTokens.s20,
              bottom: AppTokens.s20,
            ),
      child: Row(
        children: [
          IconButton(
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: AppTokens.s4),
          Expanded(
            child: Text(
              chapter,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppTokens.s32 + AppTokens.s4,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTokens.s8),
        itemBuilder: (context, i) {
          final f = filters[i];
          final isSelected = f == selected;
          return ChoiceChip(
            side: BorderSide(color: AppTokens.border(context)),
            label: Text(f),
            labelStyle: AppTokens.caption(context).copyWith(
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.white : AppTokens.ink(context),
            ),
            selected: isSelected,
            selectedColor: AppTokens.accent(context),
            backgroundColor: AppTokens.surface(context),
            onSelected: (_) => onSelected(f),
          );
        },
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s8,
        vertical: AppTokens.s4,
      ),
      decoration: BoxDecoration(
        color: AppTokens.accentSoft(context),
        borderRadius: BorderRadius.circular(AppTokens.r8),
      ),
      child: Text(
        label,
        style: AppTokens.caption(context).copyWith(
          fontWeight: FontWeight.w600,
          color: AppTokens.accent(context),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.completed,
    required this.inProgress,
    required this.pageNumber,
  });

  final bool completed;
  final bool inProgress;
  final int pageNumber;

  @override
  Widget build(BuildContext context) {
    if (completed) {
      return Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: AppTokens.success(context),
          ),
          const SizedBox(width: AppTokens.s4),
          Text(
            "Completed",
            style: AppTokens.caption(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppTokens.success(context),
            ),
          ),
        ],
      );
    }
    if (inProgress) {
      return Row(
        children: [
          Icon(
            Icons.pause_circle_rounded,
            size: 18,
            color: AppTokens.warning(context),
          ),
          const SizedBox(width: AppTokens.s4),
          Flexible(
            child: Text(
              "Paused | Continue Reading — Page $pageNumber",
              overflow: TextOverflow.ellipsis,
              style: AppTokens.caption(context).copyWith(
                fontWeight: FontWeight.w600,
                color: AppTokens.warning(context),
              ),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        Icon(
          Icons.circle_outlined,
          size: 18,
          color: AppTokens.muted(context),
        ),
        const SizedBox(width: AppTokens.s4),
        Text(
          "Not Started",
          style: AppTokens.caption(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppTokens.muted(context),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: AppTokens.s32 + AppTokens.s32,
              width: AppTokens.s32 + AppTokens.s32,
              decoration: BoxDecoration(
                color: AppTokens.surface2(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.menu_book_rounded,
                color: AppTokens.muted(context),
                size: 32,
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              "No chapters yet",
              style: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppTokens.ink(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.s8),
            Text(
              "We're sorry, there's no content available right now. Please check back later or explore other sections for more educational resources.",
              style: AppTokens.body(context).copyWith(
                fontWeight: FontWeight.w400,
                color: AppTokens.muted(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
