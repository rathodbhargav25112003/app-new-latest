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
import 'package:shusruta_lms/models/notes_subcategory_model.dart';
import 'package:shusruta_lms/models/notes_topic_model.dart';
import 'package:shusruta_lms/models/video_data_model.dart';
import 'package:shusruta_lms/modules/dashboard/models/global_search_model.dart';
import 'package:shusruta_lms/modules/dashboard/store/home_store.dart';
import 'package:shusruta_lms/modules/notes/store/notes_category_store.dart';
import 'package:shusruta_lms/modules/widgets/no_internet_connection.dart';

/// "Subject detail" screen — renders the list of subcategories
/// (chapters) that live under a notes subject. MobX-observed. Supports
/// filtering, global search, and deep-linking into child screens.
///
/// Preserved public contract:
///   • Constructor NotesSubjectDetail({super.key, required this.subject,
///     required this.notesid}) — both Strings non-nullable.
///   • Static route(RouteSettings) factory reading
///     `arguments['subject']` → subject, `arguments['noteid']` →
///     notesid (note the off-by-one "noteid" vs "notesid" — preserved).
///   • `store.onSubCategoryApiCall(widget.notesid)` in initState.
///   • `searchCategory(keyword)` → `HomeStore.onGlobalSearchApiCall(
///     keyword, "pdf")`.
///   • `_fetchOfflineCounts()` →
///     `DbHelper.getOfflineNotesCountsBySubCategoryIds(categoryIds)`
///     where categoryIds are `sId`s of filtered subcategories.
///   • Filter chip set preserved verbatim: ["All", "Completed",
///     "In Progress", "Not Started", "Offline Notes", "Bookmark Notes"].
///   • Filter predicates preserved byte-for-byte — including the
///     intentional `completPdfCount` typo on the model.
///   • Navigator push targets preserved byte-for-byte:
///       - Regular tile tap → Routes.notesTopicCategory with
///         { "topicname": widget.subject,
///           "topic": notesSubcategory?.subcategoryName,
///           "subcatId": notesSubcategory?.sId }
///         followed by `store.onSubCategoryApiCall(widget.notesid)`
///         in the `.then()` callback.
///       - Search-hit branches into notesSubjectDetail /
///         notesTopicCategory / notesChapterDetail / notesReadView
///         with the full 12-key `notesReadView` args map (annotations,
///         pageNo, bookmark state).
///   • Public state helpers preserved (exposed via GlobalKey):
///       - buildItem(context, GlobalSearchDataModel?)
///       - buildItem1(context, NotesSubCategoryModel?,
///         NotesCategoryStore, int offlineCount)
///       - convertAnnotationListToAnnotationData(`List<AnnotationList>?`)
///   • NoInternetScreen() fallback when !store.isConnected.
///   • Desktop uses CustomDynamicHeightGridView (crossAxisCount: 3,
///     mainAxisSpacing: 10); mobile uses ListView.builder with
///     BouncingScrollPhysics.
class NotesSubjectDetail extends StatefulWidget {
  const NotesSubjectDetail({
    super.key,
    required this.subject,
    required this.notesid,
  });

  final String subject;
  final String notesid;

  @override
  State<NotesSubjectDetail> createState() => _NotesSubjectDetailState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => NotesSubjectDetail(
        subject: arguments['subject'],
        notesid: arguments['noteid'],
      ),
    );
  }
}

class _NotesSubjectDetailState extends State<NotesSubjectDetail> {
  String query = '';
  String selectedFilter = "All";
  late List<NotesSubCategoryModel?> filteredNotes;
  Map<String, int> offlineCounts = {};
  // ignore: unused_field
  final FocusNode _focusNode = FocusNode();
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
    final store = Provider.of<NotesCategoryStore>(context, listen: false);
    store.onSubCategoryApiCall(widget.notesid);
  }

  Future<void> searchCategory(String keyword) async {
    final store = Provider.of<HomeStore>(context, listen: false);
    await store.onGlobalSearchApiCall(keyword, "pdf");
  }

  Future<void> _fetchOfflineCounts() async {
    final categoryIds = filteredNotes.map((video) => video?.sId ?? "").toList();
    final counts =
        await dbHelper.getOfflineNotesCountsBySubCategoryIds(categoryIds);

    if (mounted) {
      setState(() {
        offlineCounts = counts;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool desktop = Platform.isWindows || Platform.isMacOS;
    final store = Provider.of<NotesCategoryStore>(context, listen: false);
    final homeStore = Provider.of<HomeStore>(context);
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          _HeroHeader(title: widget.subject, isDesktop: desktop),
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
                      builder: (BuildContext context) {
                        filteredNotes = store.notessubcategory;
                        _fetchOfflineCounts();
                        if (selectedFilter == "All") {
                          filteredNotes = store.notessubcategory;
                        } else if (selectedFilter == "Completed") {
                          filteredNotes = store.notessubcategory
                              .where((note) =>
                                  note?.completPdfCount != null &&
                                  (note?.completPdfCount ?? 0) > 0)
                              .toList();
                        } else if (selectedFilter == "In Progress") {
                          filteredNotes = store.notessubcategory
                              .where((note) =>
                                  note?.progressCount != null &&
                                  (note?.progressCount ?? 0) > 0)
                              .toList();
                        } else if (selectedFilter == "Not Started") {
                          filteredNotes = store.notessubcategory
                              .where((note) =>
                                  note?.notStart != null &&
                                  (note?.notStart ?? 0) > 0)
                              .toList();
                        } else if (selectedFilter == "Offline Notes") {
                          filteredNotes =
                              store.notessubcategory.where((note) {
                            final subCatId = note?.sId ?? "";
                            final count = offlineCounts[subCatId] ?? 0;
                            return count > 0;
                          }).toList();
                        } else if (selectedFilter == "Bookmark Notes") {
                          filteredNotes = store.notessubcategory
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
                        if (store.notessubcategory.isEmpty) {
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
                            builder: (BuildContext context, int index) {
                              final note = filteredNotes[index];
                              final subCategoryId = note?.sId ?? "";
                              final offlineCount =
                                  offlineCounts[subCategoryId] ?? 0;
                              return buildItem1(
                                  context, note, store, offlineCount);
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
                            final subCategoryId = note?.sId ?? "";
                            final offlineCount =
                                offlineCounts[subCategoryId] ?? 0;
                            return buildItem1(
                                context, note, store, offlineCount);
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

  Widget buildItem(
      BuildContext context, GlobalSearchDataModel? searchDataModel) {
    GlobalSearchDataModel? noteSubcat = searchDataModel;
    String? categoryName = noteSubcat?.categoryName;
    String? subcategoryName = noteSubcat?.subcategoryName;
    String? topicName = noteSubcat?.topicName;
    String? title = noteSubcat?.title;

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
                  "noteid": noteSubcat?.id,
                },
              );
            } else if (type == "Subcategory") {
              Navigator.of(context).pushNamed(
                Routes.notesTopicCategory,
                arguments: {
                  "topicname": subcategoryName,
                  "topic": subcategoryName,
                  "subcatId": noteSubcat?.id,
                },
              );
            } else if (type == "Topic") {
              Navigator.of(context).pushNamed(
                Routes.notesChapterDetail,
                arguments: {
                  "topicname": topicName,
                  "chapter": topicName,
                  "subcatId": noteSubcat?.id,
                  "subcaptername": noteSubcat?.subName,
                },
              );
            } else if (type == "Content") {
              Navigator.of(context).pushNamed(
                Routes.notesReadView,
                arguments: {
                  'topic_name': noteSubcat?.topicName ?? '',
                  'category_name': noteSubcat?.categoryName ?? '',
                  'subcategory_name': noteSubcat?.subcategoryName ?? '',
                  'categoryId': noteSubcat?.categoryId,
                  'subcategoryId': noteSubcat?.subcategoryId,
                  'contentUrl': noteSubcat?.contentUrl,
                  'title': noteSubcat?.title,
                  'titleId': noteSubcat?.id,
                  'isDownloaded': false,
                  'isCompleted': false,
                  'topicId': noteSubcat?.topicId,
                  'isBookMark': noteSubcat?.isBookmark,
                  'annotationData': convertAnnotationListToAnnotationData(
                      noteSubcat?.annotation),
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
                    "assets/image/book-open2.svg",
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
                      if ((noteSubcat?.description ?? "").isNotEmpty) ...[
                        const SizedBox(height: AppTokens.s4),
                        Text(
                          noteSubcat?.description ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTokens.caption(context).copyWith(
                            fontWeight: FontWeight.w400,
                            color: AppTokens.muted(context),
                          ),
                        ),
                      ],
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
    NotesSubCategoryModel? notesSubCategoryModel,
    NotesCategoryStore store,
    int offlineCount,
  ) {
    NotesSubCategoryModel? notesSubcategory = notesSubCategoryModel;
    int completeNotesCount = notesSubcategory?.completPdfCount ?? 0;
    int notesCount = notesSubcategory?.notes ?? 0;
    double? progressCount =
        notesCount == 0 ? 0 : completeNotesCount / notesCount;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.r12),
          onTap: () {
            Navigator.of(context).pushNamed(
              Routes.notesTopicCategory,
              arguments: {
                "topicname": widget.subject,
                "topic": notesSubcategory?.subcategoryName,
                "subcatId": notesSubcategory?.sId,
              },
            ).then((value) {
              store.onSubCategoryApiCall(widget.notesid);
            });
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
                        "assets/image/book-open2.svg",
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
                                  notesSubcategory?.subcategoryName ?? "",
                                  maxLines: 3,
                                  overflow: TextOverflow.visible,
                                  style: AppTokens.body(context).copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTokens.ink(context),
                                  ),
                                ),
                              ),
                              if (notesSubcategory?.topicCount != null &&
                                  notesSubcategory?.notes != null) ...[
                                const SizedBox(width: AppTokens.s8),
                                Text(
                                  "${notesSubcategory?.notes.toString()} Notes",
                                  style: AppTokens.caption(context).copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: AppTokens.muted(context),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if ((notesSubcategory?.description ?? "")
                              .isNotEmpty) ...[
                            const SizedBox(height: AppTokens.s4),
                            Text(
                              notesSubcategory?.description ?? "",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTokens.caption(context).copyWith(
                                fontWeight: FontWeight.w400,
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
                          "${notesSubcategory?.completPdfCount.toString() ?? "0"} Completed",
                    ),
                    _StatusStat(
                      icon: "assets/image/inprogress_status_icon.svg",
                      label:
                          "${notesSubcategory?.progressCount.toString() ?? "0"} In Progress",
                    ),
                    _StatusStat(
                      icon: "assets/image/notstart_status_icon.svg",
                      label:
                          "${notesSubcategory?.notStart.toString() ?? "0"} Not Started",
                    ),
                  ],
                ),
                if ((notesSubcategory?.bookmarkPdfCount ?? 0) > 0 ||
                    offlineCount > 0) ...[
                  const SizedBox(height: AppTokens.s8),
                  Wrap(
                    spacing: AppTokens.s16,
                    runSpacing: AppTokens.s4,
                    children: [
                      if ((notesSubcategory?.bookmarkPdfCount ?? 0) > 0)
                        _StatusStat(
                          icon: "assets/image/bookmark_status_icon.svg",
                          label:
                              "${notesSubcategory?.bookmarkPdfCount.toString() ?? "0"}  Bookmarked",
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
  const _HeroHeader({required this.title, required this.isDesktop});

  final String title;
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
              title,
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
