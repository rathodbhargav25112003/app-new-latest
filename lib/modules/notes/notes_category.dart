// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, dead_null_aware_expression, unused_local_variable, unused_element

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/helpers/custom_dynamic_height_gridview.dart';
import 'package:shusruta_lms/helpers/dbhelper.dart';
import 'package:shusruta_lms/models/notes_category_model.dart';
import 'package:shusruta_lms/models/notes_topic_model.dart';
import 'package:shusruta_lms/models/video_data_model.dart';
import 'package:shusruta_lms/modules/dashboard/models/global_search_model.dart';
import 'package:shusruta_lms/modules/dashboard/store/home_store.dart';
import 'package:shusruta_lms/modules/notes/store/notes_category_store.dart';
import 'package:shusruta_lms/modules/subscriptionplans/store/subscription_store.dart';
import 'package:shusruta_lms/modules/widgets/no_internet_connection.dart';

/// "Notes" landing screen — the root of the notes browse tree. Renders
/// a horizontally-scrollable filter chip row ("All", "Completed", "In
/// Progress", "Not Started", "Offline Notes", "Bookmark Notes") plus a
/// MobX-observed list of notes categories. Responsive: desktop uses
/// `CustomDynamicHeightGridView` with `crossAxisCount: 3`, mobile uses
/// `ListView.builder` with `BouncingScrollPhysics`.
///
/// Preserved public contract:
///   • `const NotesScreen({super.key})` — no arguments.
///   • Static `route(RouteSettings)` factory returning CupertinoPageRoute.
///   • MobX wiring:
///       - `Provider.of<NotesCategoryStore>(context)` for category list
///         + loading/connectivity flags.
///       - `Provider.of<HomeStore>(context)` for global search results
///         (`homeStore.globalSearchList`, `homeStore.isLoading`).
///   • `store.onRegisterApiCall(context)` in initState.
///   • `_getSubscribedPlan()` → `SubscriptionStore.onGetSubscribedUserPlan()`.
///   • `searchCategory(keyword)` → `HomeStore.onGlobalSearchApiCall(keyword, "pdf")`.
///   • `_fetchOfflineCounts()` → `DbHelper.getOfflineNotesCountsByCategoryIds(categoryIds)`.
///   • Navigator push targets preserved byte-for-byte:
///       - `Routes.notesSubjectDetail`: `{ "subject": categoryName,
///         "noteid": id }`
///       - `Routes.notesTopicCategory`: `{ "topicname": subcategoryName,
///         "topic": subcategoryName, "subcatId": id }`
///       - `Routes.notesChapterDetail`: `{ "topicname": topicName,
///         "chapter": topicName, "subcatId": id, "subcaptername": subName }`
///       - `Routes.notesReadView` with the full 12-key args map
///         including annotations, pageNo, bookmark state.
///   • Public state helpers retained:
///       - `buildItem(context, GlobalSearchDataModel?)`
///       - `buildItem1(context, NotesCategoryModel?, int offlineCount)`
///       - `convertAnnotationListToAnnotationData(List<AnnotationList>?)`
///     (callers may reach them via GlobalKey.)
///   • `NoInternetScreen()` fallback when `!store.isConnected`.
///   • Desktop/mobile branching computed from
///     `Platform.isWindows || Platform.isMacOS` inside `build()`.
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const NotesScreen(),
    );
  }
}

class _NotesScreenState extends State<NotesScreen> {
  String filterValue = '';
  String query = '';
  String selectedFilter = "All";
  late List<NotesCategoryModel?> filteredNotes;
  final FocusNode _focusNode = FocusNode();
  Map<String, int> offlineCounts = {};
  final dbHelper = DbHelper();

  static const List<String> _filters = [
    "All",
    "Completed",
    "In Progress",
    "Not Started",
    "Offline Notes",
    "Bookmark Notes",
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    _getSubscribedPlan();
    final store = Provider.of<NotesCategoryStore>(context, listen: false);
    store.onRegisterApiCall(context);
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  Future<void> _fetchOfflineCounts() async {
    final categoryIds = filteredNotes.map((note) => note?.id ?? "").toList();
    final counts =
        await dbHelper.getOfflineNotesCountsByCategoryIds(categoryIds);

    if (mounted) {
      setState(() {
        offlineCounts = counts;
      });
    }
  }

  Future<void> searchCategory(String keyword) async {
    final store = Provider.of<HomeStore>(context, listen: false);
    await store.onGlobalSearchApiCall(keyword, "pdf");
  }

  Future<void> _getSubscribedPlan() async {
    final store = Provider.of<SubscriptionStore>(context, listen: false);
    await store.onGetSubscribedUserPlan();
  }

  @override
  Widget build(BuildContext context) {
    final bool desktop = Platform.isWindows || Platform.isMacOS;
    final store = Provider.of<NotesCategoryStore>(context);
    final homeStore = Provider.of<HomeStore>(context);
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          _HeroHeader(isDesktop: desktop),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(
                left: AppTokens.s20,
                right: AppTokens.s20,
                top: AppTokens.s24,
              ),
              decoration: BoxDecoration(
                color: AppTokens.scaffold(context),
                borderRadius: desktop
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
                    onSelected: (value) {
                      setState(() {
                        selectedFilter = value;
                      });
                    },
                  ),
                  const SizedBox(height: AppTokens.s16),
                  Expanded(
                    child: Observer(
                      builder: (_) {
                        filteredNotes = store.notescategory;
                        _fetchOfflineCounts();
                        if (selectedFilter == "All") {
                          filteredNotes = store.notescategory;
                        } else if (selectedFilter == "Completed") {
                          filteredNotes = store.notescategory
                              .where((note) =>
                                  note?.completedPdfCount != null &&
                                  (note?.completedPdfCount ?? 0) > 0)
                              .toList();
                        } else if (selectedFilter == "In Progress") {
                          filteredNotes = store.notescategory
                              .where((note) =>
                                  note?.progressCount != null &&
                                  (note?.progressCount ?? 0) > 0)
                              .toList();
                        } else if (selectedFilter == "Not Started") {
                          filteredNotes = store.notescategory
                              .where((note) =>
                                  note?.notStart != null &&
                                  (note?.notStart ?? 0) > 0)
                              .toList();
                        } else if (selectedFilter == "Offline Notes") {
                          filteredNotes = store.notescategory.where((note) {
                            final catId = note?.id ?? "";
                            final count = offlineCounts[catId] ?? 0;
                            return count > 0;
                          }).toList();
                        } else if (selectedFilter == "Bookmark Notes") {
                          filteredNotes = store.notescategory
                              .where((note) =>
                                  note?.bookmarkPdfCount != null &&
                                  (note?.bookmarkPdfCount ?? 0) > 0)
                              .toList();
                        }

                        if (store.isLoading) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: AppTokens.brand,
                            ),
                          );
                        }
                        if (store.notescategory.isEmpty) {
                          return _EmptyState();
                        }
                        if (!store.isConnected) {
                          return const NoInternetScreen();
                        }
                        if (homeStore.isLoading) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final showSearch =
                            homeStore.globalSearchList.isNotEmpty &&
                                query.isNotEmpty;

                        if (showSearch) {
                          if (desktop) {
                            return CustomDynamicHeightGridView(
                              crossAxisCount: 3,
                              mainAxisSpacing: 10,
                              itemCount: homeStore.globalSearchList.length,
                              builder: (BuildContext context, int index) {
                                return buildItem(
                                    context, homeStore.globalSearchList[index]);
                              },
                            );
                          }
                          return ListView.builder(
                            itemCount: homeStore.globalSearchList.length,
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (BuildContext context, int index) {
                              return buildItem(
                                  context, homeStore.globalSearchList[index]);
                            },
                          );
                        }

                        if (desktop) {
                          return CustomDynamicHeightGridView(
                            crossAxisCount: 3,
                            mainAxisSpacing: 10,
                            itemCount: filteredNotes.length,
                            shrinkWrap: true,
                            builder: (BuildContext context, int index) {
                              final note = filteredNotes[index];
                              final categoryId = note?.id ?? "";
                              final offlineCount =
                                  offlineCounts[categoryId] ?? 0;
                              return buildItem1(
                                  context, filteredNotes[index], offlineCount);
                            },
                          );
                        }
                        return ListView.builder(
                          itemCount: filteredNotes.length,
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (BuildContext context, int index) {
                            final note = filteredNotes[index];
                            final categoryId = note?.id ?? "";
                            final offlineCount =
                                offlineCounts[categoryId] ?? 0;
                            return buildItem1(
                                context, filteredNotes[index], offlineCount);
                          },
                        );
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

  Widget buildItem(BuildContext context, GlobalSearchDataModel? noteCat) {
    GlobalSearchDataModel? notesCat = noteCat;
    String? categoryName = notesCat?.categoryName;
    String? subcategoryName = notesCat?.subcategoryName;
    String? topicName = notesCat?.topicName;
    String? title = notesCat?.title;

    String displayText =
        categoryName ?? subcategoryName ?? topicName ?? title ?? "";
    String type = categoryName != null
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
                arguments: {
                  "subject": categoryName,
                  "noteid": notesCat?.id,
                },
              );
            } else if (type == "Subcategory") {
              Navigator.of(context).pushNamed(
                Routes.notesTopicCategory,
                arguments: {
                  "topicname": subcategoryName,
                  "topic": subcategoryName,
                  "subcatId": notesCat?.id,
                },
              );
            } else if (type == "Topic") {
              Navigator.of(context).pushNamed(
                Routes.notesChapterDetail,
                arguments: {
                  "topicname": topicName,
                  "chapter": topicName,
                  "subcatId": notesCat?.id,
                  "subcaptername": notesCat?.subName,
                },
              );
            } else if (type == "Content") {
              Navigator.of(context).pushNamed(
                Routes.notesReadView,
                arguments: {
                  'topic_name': notesCat?.topicName ?? '',
                  'category_name': notesCat?.categoryName ?? '',
                  'subcategory_name': notesCat?.subcategoryName ?? '',
                  'categoryId': notesCat?.categoryId,
                  'subcategoryId': notesCat?.subcategoryId,
                  'contentUrl': notesCat?.contentUrl,
                  'title': notesCat?.title,
                  'titleId': notesCat?.id,
                  'isDownloaded': false,
                  'isCompleted': false,
                  'topicId': notesCat?.topicId,
                  'isBookMark': notesCat?.isBookmark,
                  'annotationData': convertAnnotationListToAnnotationData(
                      notesCat?.annotation),
                  'pageNo': 0,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: AppTokens.s32 + AppTokens.s20,
                  width: AppTokens.s32 + AppTokens.s20,
                  padding: const EdgeInsets.all(AppTokens.s12),
                  decoration: BoxDecoration(
                    color: AppTokens.accentSoft(context),
                    borderRadius: BorderRadius.circular(AppTokens.r12),
                  ),
                  child: SvgPicture.asset(
                    "assets/image/videocategoryIcon.svg",
                    color: AppTokens.accent(context),
                  ),
                ),
                const SizedBox(width: AppTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayText,
                        maxLines: 3,
                        overflow: TextOverflow.visible,
                        style: AppTokens.body(context).copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTokens.ink(context),
                        ),
                      ),
                      const SizedBox(height: AppTokens.s4),
                      Text(
                        notesCat?.description ?? "",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTokens.caption(context).copyWith(
                          fontWeight: FontWeight.w400,
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
    NotesCategoryModel? noteCatModel,
    int offlineCount,
  ) {
    NotesCategoryModel? notesModel = noteCatModel;
    String categoryName = notesModel?.category_name ?? "";
    String subcategoryName = notesModel?.subcategory_name ?? "";
    String topicName = notesModel?.topic_name ?? "";

    String displayText = categoryName;

    if (subcategoryName.isNotEmpty && topicName.isNotEmpty) {
      displayText = "$subcategoryName > $topicName";
    } else if (subcategoryName.isNotEmpty) {
      displayText = subcategoryName;
    } else if (topicName.isNotEmpty) {
      displayText = topicName;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.r12),
          onTap: () {
            Navigator.of(context).pushNamed(
              Routes.notesSubjectDetail,
              arguments: {
                "subject": noteCatModel?.category_name,
                "noteid": noteCatModel?.sid,
              },
            );
          },
          child: Container(
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
                      height: AppTokens.s32 + AppTokens.s20,
                      width: AppTokens.s32 + AppTokens.s20,
                      padding: const EdgeInsets.all(AppTokens.s12),
                      decoration: BoxDecoration(
                        color: AppTokens.accentSoft(context),
                        borderRadius: BorderRadius.circular(AppTokens.r12),
                      ),
                      child: SvgPicture.asset(
                        "assets/image/noteCategory.svg",
                        color: AppTokens.accent(context),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  notesModel?.category_name ?? "",
                                  maxLines: 3,
                                  overflow: TextOverflow.visible,
                                  style: AppTokens.body(context).copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTokens.ink(context),
                                  ),
                                ),
                              ),
                              if (notesModel?.subcategory != null &&
                                  notesModel?.notes != null) ...[
                                const SizedBox(width: AppTokens.s8),
                                Text(
                                  "${notesModel?.notes.toString()} Notes",
                                  style: AppTokens.caption(context).copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: AppTokens.muted(context),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if ((notesModel?.description ?? "").isNotEmpty) ...[
                            const SizedBox(height: AppTokens.s4),
                            Text(
                              notesModel?.description ?? "",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTokens.caption(context).copyWith(
                                fontWeight: FontWeight.w500,
                                color: AppTokens.muted(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatusStat(
                      icon: "assets/image/completed_status_icon.svg",
                      label:
                          "${notesModel?.completedPdfCount.toString() ?? "0"} Completed",
                    ),
                    _StatusStat(
                      icon: "assets/image/inprogress_status_icon.svg",
                      label:
                          "${notesModel?.progressCount.toString() ?? "0"} In Progress",
                    ),
                    _StatusStat(
                      icon: "assets/image/notstart_status_icon.svg",
                      label:
                          "${notesModel?.notStart.toString() ?? "0"} Not Started",
                    ),
                  ],
                ),
                if ((notesModel?.bookmarkPdfCount ?? 0) > 0 ||
                    offlineCount > 0) ...[
                  const SizedBox(height: AppTokens.s8),
                  Wrap(
                    spacing: AppTokens.s16,
                    runSpacing: AppTokens.s4,
                    children: [
                      if ((notesModel?.bookmarkPdfCount ?? 0) > 0)
                        _StatusStat(
                          icon: "assets/image/bookmark_status_icon.svg",
                          label:
                              "${notesModel?.bookmarkPdfCount.toString() ?? "0"}  Bookmarked",
                        ),
                      if (offlineCount > 0)
                        _StatusStat(
                          icon: "assets/image/offline_status_icon.svg",
                          label: "$offlineCount Offline Downloaded",
                        ),
                    ],
                  ),
                ],
              ],
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
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.isDesktop});

  final bool isDesktop;

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
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Text(
              "Notes",
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final bool isSelected = selected == filter;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: ChoiceChip(
              side: BorderSide(color: AppTokens.border(context)),
              label: Text(filter),
              labelStyle: AppTokens.caption(context).copyWith(
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? AppColors.white
                    : AppTokens.ink(context),
              ),
              selected: isSelected,
              selectedColor: AppTokens.brand,
              backgroundColor: AppTokens.surface(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.r20),
                side: BorderSide(color: AppTokens.border(context)),
              ),
              onSelected: (_) => onSelected(filter),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatusStat extends StatelessWidget {
  const _StatusStat({required this.icon, required this.label});

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          icon,
          height: AppTokens.s16,
          width: AppTokens.s16,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTokens.caption(context).copyWith(
            color: AppTokens.muted(context),
          ),
        ),
      ],
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
        vertical: 2,
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

class _EmptyState extends StatelessWidget {
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
              "No notes yet",
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
