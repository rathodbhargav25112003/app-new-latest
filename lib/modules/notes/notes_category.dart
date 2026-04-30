import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/helpers/custom_dynamic_height_gridview.dart';
import 'package:shusruta_lms/models/notes_category_model.dart';
import 'package:shusruta_lms/modules/notes/sharedhelper.dart';
import 'package:shusruta_lms/modules/notes/store/notes_category_store.dart';

import '../../app/routes.dart';
import '../../helpers/app_skeleton.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/dbhelper.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/empty_state.dart';
import '../../helpers/styles.dart';
import '../../models/notes_topic_model.dart';
import '../../models/video_data_model.dart';
import '../dashboard/models/global_search_model.dart';
import '../dashboard/store/home_store.dart';
import '../subscriptionplans/store/subscription_store.dart';
import '../widgets/no_internet_connection.dart';
import '../widgets/priority_badge.dart';

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
    final counts = await dbHelper.getOfflineNotesCountsByCategoryIds(categoryIds);

    if (mounted) {
      setState(() {
        offlineCounts = counts;
      });
    }
  }

  Future<void> searchCategory(String keyword) async {
    // final store = Provider.of<NotesCategoryStore>(context, listen: false);
    // await store.onSearchApiCall(keyword, "PDF");
    final store = Provider.of<HomeStore>(context, listen: false);
    await store.onGlobalSearchApiCall(keyword, "pdf");
  }

  Future<void> _getSubscribedPlan() async {
    final store = Provider.of<SubscriptionStore>(context, listen: false);
    await store.onGetSubscribedUserPlan();
    // if(store.subscribedPlan.isEmpty){
    //   Navigator.of(context).pushNamed(Routes.subscriptionList);
    // }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> filters = [
      "All",
      "Completed",
      "In Progress",
      "Not Started",
      "Offline Notes",
      "Bookmark Notes"
    ];
    bool isDesktop = Platform.isWindows || Platform.isMacOS;
    final store = Provider.of<NotesCategoryStore>(context);
    final homeStore = Provider.of<HomeStore>(context);
    return Scaffold(
        backgroundColor: AppTokens.scaffold(context),
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: AppTokens.scaffold(context),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTokens.ink(context), size: 18),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text("Notes", style: AppTokens.titleLg(context)),
          centerTitle: false,
        ),
        // appBar: AppBar(
        //   elevation: 0,
        //   automaticallyImplyLeading: false,
        //   backgroundColor: ThemeManager.white,
        //   leading: Padding(
        //     padding: const EdgeInsets.only(left: Dimensions.PADDING_SIZE_SMALL),
        //     child:       IconButton(       highlightColor: Colors.transparent,     hoverColor: Colors.transparent,
        //       icon:  Icon(Icons.arrow_back_ios, color: ThemeManager.iconColor),
        //       onPressed: () {
        //         Navigator.pop(context);
        //       },
        //     ),
        //   ),
        //   actions: [
        //     Padding(
        //       padding: const EdgeInsets.only(right: Dimensions.PADDING_SIZE_SMALL),
        //       child:       IconButton(       highlightColor: Colors.transparent,     hoverColor: Colors.transparent,
        //         icon:  Icon(Icons.home, color: ThemeManager.iconColor),
        //         onPressed: () {
        //           Navigator.of(context).pushNamed(Routes.dashboard);
        //         },
        //       ),
        //     ),
        //   ],
        //   centerTitle: true,
        //   title: Text(
        //     "Notes",
        //     style: interRegular.copyWith(
        //       fontSize: Dimensions.fontSizeLarge,
        //       fontWeight: FontWeight.w500,
        //       color: ThemeManager.black,
        //     ),
        //   ),
        // ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppTokens.s24, AppTokens.s8, AppTokens.s24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // query.isNotEmpty
                      // ? Text(
                      //     "Results for “$query”",
                      //     style: interRegular.copyWith(
                      //       fontSize: Dimensions.fontSizeDefault,
                      //       fontWeight: FontWeight.w400,
                      //       color: ThemeManager.black,
                      //     ),
                      //   )
                      // : const SizedBox(),
                      // const SizedBox(
                      //   height: Dimensions.PADDING_SIZE_SMALL,
                      // ),
                      //
                      // ///Search and Filter
                      // SizedBox(
                      //   height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                      //   child: TextField(
                      //     focusNode: _focusNode,
                      //     onChanged: (value) {
                      //       setState(() {
                      //         query = value;
                      //         if (query.length >= 3) {
                      //           searchCategory(query);
                      //         }
                      //         if (query.isEmpty) {
                      //           store.onRegisterApiCall(context);
                      //         }
                      //       });
                      //     },
                      //     style: interRegular.copyWith(
                      //         fontSize: Dimensions.fontSizeDefault,
                      //         color: ThemeManager.black,
                      //         fontWeight: FontWeight.w500,
                      //         fontFamily: 'DM Sans'),
                      //     cursorColor: ThemeManager.grey,
                      //     decoration: InputDecoration(
                      //       suffixIcon: const Icon(CupertinoIcons.search),
                      //       suffixIconColor: ThemeManager.black,
                      //       hintStyle: interRegular.copyWith(
                      //           fontSize: Dimensions.fontSizeDefault,
                      //           color: ThemeManager.grey,
                      //           fontWeight: FontWeight.w500,
                      //           fontFamily: 'DM Sans'),
                      //       hintText: 'Search',
                      //       fillColor: ThemeManager.white,
                      //       filled: true,
                      //       border: OutlineInputBorder(
                      //           borderRadius: BorderRadius.circular(
                      //               Dimensions.RADIUS_DEFAULT),
                      //           borderSide: BorderSide(
                      //             color: ThemeManager.mainBorder,
                      //           )),
                      //       focusedBorder: OutlineInputBorder(
                      //         borderRadius: BorderRadius.circular(
                      //             Dimensions.RADIUS_DEFAULT),
                      //         borderSide: BorderSide(
                      //           color: ThemeManager.mainBorder,
                      //         ),
                      //       ),
                      //       enabledBorder: OutlineInputBorder(
                      //         borderRadius: BorderRadius.circular(
                      //             Dimensions.RADIUS_DEFAULT),
                      //         borderSide: BorderSide(
                      //           color: ThemeManager.mainBorder,
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      // const SizedBox(
                      //   height: Dimensions.PADDING_SIZE_DEFAULT,
                      // ),
                      // Container(
                      //   constraints: const BoxConstraints(
                      //     minHeight: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                      //   ),
                      //   decoration: BoxDecoration(
                      //     color: ThemeManager.white,
                      //     borderRadius: const BorderRadius.horizontal(
                      //         left: Radius.circular(10),
                      //         right: Radius.circular(10)),
                      //   ),
                      //   child: TextFormField(
                      //     cursorColor: ThemeManager.textColor4,
                      //     style: interRegular.copyWith(
                      //         fontSize: Dimensions.fontSizeDefault,
                      //         color: ThemeManager.textColor4),
                      //     focusNode: _focusNode,
                      //     onChanged: (value) {
                      //       setState(() {
                      //         query = value;
                      //         if (query.length >= 3) {
                      //           searchCategory(query);
                      //         }
                      //       });
                      //     },
                      //     keyboardType: TextInputType.name,
                      //     // controller: _searchController,
                      //     decoration: InputDecoration(
                      //       contentPadding: const EdgeInsets.only(
                      //           left: Dimensions.PADDING_SIZE_SMALL * 1.2),
                      //       fillColor: Theme.of(context).disabledColor,
                      //       enabledBorder: InputBorder.none,
                      //       hintText: 'Search chapter name, topic...',
                      //       hintStyle: interRegular.copyWith(
                      //         fontSize: Dimensions.fontSizeSmall,
                      //         color: ThemeManager.textColor4.withOpacity(0.5),
                      //       ),
                      //       counterText: '',
                      //       focusedBorder: InputBorder.none,
                      //       border: InputBorder.none,
                      //     ),
                      //   ),
                      // ),
                      // const SizedBox(
                      //   height: Dimensions.PADDING_SIZE_DEFAULT,
                      // ),
                      // if(query.isEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: filters.map((filter) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2.0),
                              child: ChoiceChip(
                                side: BorderSide(color: ThemeManager.mainBorder),
                                label: Text(filter),
                                labelStyle: interRegular.copyWith(
                                  fontSize: Dimensions.fontSizeExtraSmall,
                                  fontWeight: FontWeight.w400,
                                  color: selectedFilter == filter ? ThemeManager.white : ThemeManager.black,
                                ),
                                selected: selectedFilter == filter,
                                selectedColor: Theme.of(context).primaryColor,
                                backgroundColor: ThemeManager.white,
                                onSelected: (bool isSelected) {
                                  setState(() {
                                    selectedFilter = filter;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(
                        height: Dimensions.PADDING_SIZE_DEFAULT,
                      ),

                      ///notes list
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
                                      note?.completedPdfCount != null && (note?.completedPdfCount ?? 0) > 0)
                                  .toList();
                            } else if (selectedFilter == "In Progress") {
                              filteredNotes = store.notescategory
                                  .where(
                                      (note) => note?.progressCount != null && (note?.progressCount ?? 0) > 0)
                                  .toList();
                            } else if (selectedFilter == "Not Started") {
                              filteredNotes = store.notescategory
                                  .where((note) => note?.notStart != null && (note?.notStart ?? 0) > 0)
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
                                      note?.bookmarkPdfCount != null && (note?.bookmarkPdfCount ?? 0) > 0)
                                  .toList();
                            }
                            if (store.isLoading) {
                              return const SkeletonList(count: 4, itemHeight: 96);
                            }
                            if (store.notescategory.isEmpty) {
                              return const EmptyState(
                                icon: Icons.menu_book_outlined,
                                title: 'No notes yet',
                                subtitle: 'New notes will appear here as soon as they’re published.',
                              );
                            }
                            return store.isConnected
                                ? homeStore.isLoading
                                    ? const SkeletonList(count: 4, itemHeight: 96)
                                    : (homeStore.globalSearchList.isNotEmpty && query.isNotEmpty)
                                        ? isDesktop
                                            ? CustomDynamicHeightGridView(
                                                crossAxisCount: 3,
                                                mainAxisSpacing: 10,
                                                itemCount: homeStore.globalSearchList.length,
                                                builder: (BuildContext context, int index) {
                                                  return buildItem(
                                                      context, homeStore.globalSearchList[index]);
                                                },
                                              )
                                            : ListView.builder(
                                                itemCount: homeStore.globalSearchList.length,
                                                shrinkWrap: true,
                                                padding: EdgeInsets.zero,
                                                physics: const BouncingScrollPhysics(),
                                                itemBuilder: (BuildContext context, int index) {
                                                  return buildItem(
                                                      context, homeStore.globalSearchList[index]);
                                                },
                                              )
                                        : isDesktop
                                            ? CustomDynamicHeightGridView(
                                                crossAxisCount: 3,
                                                mainAxisSpacing: 10,
                                                itemCount: filteredNotes.length,
                                                shrinkWrap: true,
                                                builder: (BuildContext context, int index) {
                                                  final note = filteredNotes[index];
                                                  final categoryId = note?.id ?? "";
                                                  final offlineCount = offlineCounts[categoryId] ?? 0;
                                                  return buildItem1(
                                                      context, filteredNotes[index], offlineCount);
                                                },
                                              )
                                            : ListView.builder(
                                                itemCount: filteredNotes.length,
                                                shrinkWrap: true,
                                                padding: EdgeInsets.zero,
                                                physics: const BouncingScrollPhysics(),
                                                itemBuilder: (BuildContext context, int index) {
                                                  final note = filteredNotes[index];
                                                  final categoryId = note?.id ?? "";
                                                  final offlineCount = offlineCounts[categoryId] ?? 0;
                                                  return buildItem1(
                                                      context, filteredNotes[index], offlineCount);
                                                },
                                              )
                                : const NoInternetScreen();
                          },
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Widget buildItem(BuildContext context, GlobalSearchDataModel? noteCat) {
    GlobalSearchDataModel? notesCat = noteCat;
    String? categoryName = notesCat?.categoryName;
    String? subcategoryName = notesCat?.subcategoryName;
    String? topicName = notesCat?.topicName;
    String? title = notesCat?.title;

    String displayText = categoryName ?? subcategoryName ?? topicName ?? title ?? "";
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
      padding: const EdgeInsets.only(bottom: Dimensions.PADDING_SIZE_SMALL),
      child: InkWell(
        onTap: () {
          if (type == "Category") {
            Navigator.of(context).pushNamed(Routes.notesSubjectDetail,
                arguments: {"subject": categoryName, "noteid": notesCat?.id});
          } else if (type == "Subcategory") {
            Navigator.of(context).pushNamed(Routes.notesTopicCategory, arguments: {
              "topicname": subcategoryName,
              "topic": subcategoryName,
              "subcatId": notesCat?.id
            });
          } else if (type == "Topic") {
            Navigator.of(context).pushNamed(Routes.notesChapterDetail, arguments: {
              "topicname": topicName,
              "chapter": topicName,
              "subcatId": notesCat?.id,
              "subcaptername": notesCat?.subName,
            });
          } else if (type == "Content") {
            Navigator.of(context).pushNamed(Routes.notesReadView, arguments: {
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
              'annotationData': convertAnnotationListToAnnotationData(notesCat?.annotation),
              'pageNo': 0,
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.all(Dimensions.PADDING_SIZE_DEFAULT),
          decoration: BoxDecoration(
              color: ThemeManager.white,
              border: Border.all(color: ThemeManager.mainBorder),
              borderRadius: BorderRadius.circular(9.6)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                height: Dimensions.PADDING_SIZE_LARGE * 3.2,
                width: Dimensions.PADDING_SIZE_LARGE * 3.2,
                padding: const EdgeInsets.all(Dimensions.PADDING_SIZE_LARGE),
                decoration: BoxDecoration(
                    color: ThemeManager.blueFinalTrans, borderRadius: BorderRadius.circular(14.4)),
                child: SvgPicture.asset(
                  "assets/image/videocategoryIcon.svg",
                  color: ThemeManager.currentTheme == AppTheme.Dark ? AppColors.white : null,
                ),
              ),
              const SizedBox(
                width: Dimensions.PADDING_SIZE_SMALL,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.56,
                    child: Text(
                      displayText ?? "",
                      maxLines: 3,
                      overflow: TextOverflow.visible,
                      style: interSemiBold.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        fontWeight: FontWeight.w600,
                        color: ThemeManager.black,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: Dimensions.PADDING_SIZE_EXTRA_SMALL,
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.56,
                    child: Text(
                      notesCat?.description ?? "",
                      style: interRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        fontWeight: FontWeight.w400,
                        overflow: TextOverflow.ellipsis,
                        color: ThemeManager.black.withOpacity(0.5),
                      ),
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(
                    height: Dimensions.PADDING_SIZE_EXTRA_SMALL,
                  ),
                  Text(
                    type,
                    style: interSemiBold.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      fontWeight: FontWeight.w600,
                      color: ThemeManager.black,
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildItem1(BuildContext context, NotesCategoryModel? noteCatModel, int offlineCount) {
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
      padding: const EdgeInsets.only(bottom: Dimensions.PADDING_SIZE_SMALL),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(Routes.notesSubjectDetail,
              arguments: {"subject": noteCatModel?.category_name, "noteid": noteCatModel?.sid});
        },
        child: Container(
          padding: const EdgeInsets.all(Dimensions.PADDING_SIZE_DEFAULT),
          decoration: BoxDecoration(
              color: ThemeManager.white,
              border: Border.all(color: ThemeManager.mainBorder),
              borderRadius: BorderRadius.circular(9.6)),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    height: Dimensions.PADDING_SIZE_LARGE * 3.2,
                    width: Dimensions.PADDING_SIZE_LARGE * 3.2,
                    padding: const EdgeInsets.all(Dimensions.PADDING_SIZE_DEFAULT),
                    decoration: BoxDecoration(
                        color: ThemeManager.blueFinalTrans, borderRadius: BorderRadius.circular(14.4)),
                    child: SvgPicture.asset(
                      "assets/image/noteCategory.svg",
                      color: ThemeManager.currentTheme == AppTheme.Dark ? AppColors.white : null,
                    ),
                  ),
                  const SizedBox(
                    width: Dimensions.PADDING_SIZE_SMALL,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: isDesktop ? null : MediaQuery.of(context).size.width * 0.4,
                              child: Text(
                                notesModel?.category_name ?? "",
                                maxLines: 3,
                                overflow: TextOverflow.visible,
                                style: interSemiBold.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  fontWeight: FontWeight.w600,
                                  color: ThemeManager.black,
                                ),
                              ),
                            ),
                            (notesModel?.subcategory != null && notesModel?.notes != null)
                                ? Text(
                                    "${notesModel?.notes.toString()} Notes",
                                    style: interSemiBold.copyWith(
                                      fontSize: Dimensions.fontSizeExtraSmall,
                                      fontWeight: FontWeight.w500,
                                      color: ThemeManager.black,
                                    ),
                                  )
                                : const SizedBox(),
                          ],
                        ),
                        const SizedBox(
                          height: Dimensions.PADDING_SIZE_EXTRA_SMALL,
                        ),
                        Text(
                          notesModel?.description ?? "",
                          style: interRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            fontWeight: FontWeight.w500,
                            overflow: TextOverflow.ellipsis,
                            color: ThemeManager.black.withOpacity(0.5),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(
                          height: Dimensions.PADDING_SIZE_EXTRA_SMALL,
                        ),
                        // IntrinsicHeight(
                        //   child:
                        //   (videoCat?.subcategory_name!=null || videoCat?.topic_name!=null)?
                        //   Row(
                        //     children: [
                        //       Text(displayText,
                        //         style: interRegular.copyWith(
                        //           fontSize: Dimensions.fontSizeSmall,
                        //           fontWeight: FontWeight.w400,
                        //           color: Theme.of(context).primaryColor,
                        //         ),),
                        //     ],
                        //   ):const SizedBox(),
                        // ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset(
                        "assets/image/completed_status_icon.svg",
                        height: Dimensions.PADDING_SIZE_LARGE,
                        width: Dimensions.PADDING_SIZE_LARGE,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${notesModel?.completedPdfCount.toString() ?? "0"} Completed",
                        style: interRegular.copyWith(
                          fontSize: Dimensions.fontSizeExtraSmall,
                          color: ThemeManager.black.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      SvgPicture.asset(
                        "assets/image/inprogress_status_icon.svg",
                        height: Dimensions.PADDING_SIZE_LARGE,
                        width: Dimensions.PADDING_SIZE_LARGE,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${notesModel?.progressCount.toString() ?? "0"} In Progress",
                        style: interRegular.copyWith(
                          fontSize: Dimensions.fontSizeExtraSmall,
                          color: ThemeManager.black.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      SvgPicture.asset(
                        "assets/image/notstart_status_icon.svg",
                        height: Dimensions.PADDING_SIZE_LARGE,
                        width: Dimensions.PADDING_SIZE_LARGE,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${notesModel?.notStart.toString() ?? "0"} Not Started",
                        style: interRegular.copyWith(
                          fontSize: Dimensions.fontSizeExtraSmall,
                          color: ThemeManager.black.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
              Row(
                children: [
                  if ((notesModel?.bookmarkPdfCount ?? 0) > 0)
                    Row(
                      children: [
                        SvgPicture.asset(
                          "assets/image/bookmark_status_icon.svg",
                          height: Dimensions.PADDING_SIZE_LARGE,
                          width: Dimensions.PADDING_SIZE_LARGE,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${notesModel?.bookmarkPdfCount.toString() ?? "0"}  Bookmarked",
                          style: interRegular.copyWith(
                            fontSize: Dimensions.fontSizeExtraSmall,
                            color: ThemeManager.black.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(width: Dimensions.PADDING_SIZE_DEFAULT),
                      ],
                    ),
                  if (offlineCount > 0)
                    Row(
                      children: [
                        SvgPicture.asset(
                          "assets/image/offline_status_icon.svg",
                          height: Dimensions.PADDING_SIZE_LARGE,
                          width: Dimensions.PADDING_SIZE_LARGE,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "$offlineCount Offline Downloaded",
                          style: interRegular.copyWith(
                            fontSize: Dimensions.fontSizeExtraSmall,
                            color: ThemeManager.black.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              notesModel?.priorityLabel != null ? const Divider() : SizedBox.shrink(),
              PriorityBadge(
                priorityLabel: notesModel?.priorityLabel,
                priorityColor: notesModel?.priorityColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<AnnotationData>? convertAnnotationListToAnnotationData(List<AnnotationList>? list) {
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
