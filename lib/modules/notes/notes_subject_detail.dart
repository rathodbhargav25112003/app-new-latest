import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/helpers/custom_dynamic_height_gridview.dart';
import 'package:shusruta_lms/models/notes_subcategory_model.dart';
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
import '../widgets/no_internet_connection.dart';
import '../widgets/priority_badge.dart';

class NotesSubjectDetail extends StatefulWidget {
  final String subject;
  final String notesid;
  const NotesSubjectDetail({super.key, required this.subject, required this.notesid});

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
  final FocusNode _focusNode = FocusNode();
  final dbHelper = DbHelper();

  @override
  void initState() {
    super.initState();
    final store = Provider.of<NotesCategoryStore>(context, listen: false);
    store.onSubCategoryApiCall(widget.notesid);
  }

  Future<void> searchCategory(String keyword) async {
    // final store = Provider.of<NotesCategoryStore>(context, listen: false);
    // await store.onSearchApiCall(keyword, "PDF");
    final store = Provider.of<HomeStore>(context, listen: false);
    await store.onGlobalSearchApiCall(keyword, "pdf");
  }

  Future<void> _fetchOfflineCounts() async {
    final categoryIds = filteredNotes.map((video) => video?.sId ?? "").toList();
    final counts = await dbHelper.getOfflineNotesCountsBySubCategoryIds(categoryIds);

    if (mounted) {
      setState(() {
        offlineCounts = counts;
      });
    }
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
    final store = Provider.of<NotesCategoryStore>(context, listen: false);
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
          title: Text(widget.subject, style: AppTokens.titleLg(context)),
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
        //   title: Observer(
        //     builder: (_){
        //       return Column(
        //         children: [
        //           Text(
        //             widget.subject,
        //             style: interRegular.copyWith(
        //               fontSize: Dimensions.fontSizeLarge,
        //               fontWeight: FontWeight.w500,
        //               color: ThemeManager.black,
        //             ),
        //           ),
        //           Text(
        //             "${store.notessubcategory.length.toString().padLeft(2,'0')} Chapters",
        //             style: interRegular.copyWith(
        //               fontSize: Dimensions.fontSizeExtraSmall,
        //               fontWeight: FontWeight.w400,
        //               color: Theme.of(context).hintColor,
        //             ),
        //           ),
        //         ],
        //       );
        //     },
        //   ),
        // ),
        body: SafeArea(
          child: Column(
            children: [
              // Padding(
              //   padding: const EdgeInsets.only(
              //       left: Dimensions.PADDING_SIZE_LARGE * 1.2,
              //       right: Dimensions.PADDING_SIZE_LARGE * 1.2,
              //       bottom: Dimensions.PADDING_SIZE_SMALL * 2.1),
              //   child: Row(
              //     crossAxisAlignment: CrossAxisAlignment.end,
              //     children: [
              //       Container(
              //         height: Dimensions.PADDING_SIZE_SMALL * 3.362,
              //         width: Dimensions.PADDING_SIZE_SMALL * 3.362,
              //         margin: const EdgeInsets.only(
              //             right: Dimensions.PADDING_SIZE_SMALL),
              //         padding: const EdgeInsets.all(
              //             Dimensions.PADDING_SIZE_EXTRA_SMALL * 1.6),
              //         decoration: BoxDecoration(
              //             color: ThemeManager.videoSubjectContainer
              //                 .withOpacity(0.3),
              //             borderRadius: BorderRadius.circular(9.61)),
              //         child: SvgPicture.asset("assets/image/notechapter2.svg"),
              //       ),
              //       const SizedBox(
              //         width: Dimensions.PADDING_SIZE_DEFAULT,
              //       ),
              //       Column(
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         children: [
              //           Text(
              //             "Chapters",
              //             style: interRegular.copyWith(
              //                 fontSize: Dimensions.fontSizeSmall,
              //                 fontWeight: FontWeight.w400,
              //                 color: AppColors.white,
              //                 height: 0),
              //           ),
              //           const SizedBox(
              //             height: 5,
              //           ),
              //           Observer(builder: (context) {
              //             return Text(
              //               store.notessubcategory.length
              //                   .toString()
              //                   .padLeft(2, '0'),
              //               style: interRegular.copyWith(
              //                   fontSize: Dimensions.fontSizeDefault,
              //                   fontWeight: FontWeight.w500,
              //                   color: AppColors.white,
              //                   height: 0),
              //             );
              //           }),
              //         ],
              //       ),
              //       // const Spacer(),
              //       // InkWell(
              //       //   onTap: () {
              //       //     Navigator.of(context)
              //       //         .pushNamed(Routes.downloadedNotesCategory);
              //       //   },
              //       //   child: Container(
              //       //     padding: const EdgeInsets.symmetric(
              //       //         horizontal: Dimensions.PADDING_SIZE_SMALL * 1.2,
              //       //         vertical:
              //       //             Dimensions.PADDING_SIZE_EXTRA_SMALL * 1.2),
              //       //     decoration: BoxDecoration(
              //       //         color: ThemeManager.whitePrimary,
              //       //         borderRadius: BorderRadius.circular(50.53)),
              //       //     child: Text(
              //       //       "Offline Notes",
              //       //       style: interRegular.copyWith(
              //       //         fontSize: Dimensions.fontSizeSmall,
              //       //         fontWeight: FontWeight.w500,
              //       //         color: ThemeManager.blueFinal,
              //       //       ),
              //       //     ),
              //       //   ),
              //       // ),
              //     ],
              //   ),
              // ),
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
                      // ///Search bar
                      // SizedBox(
                      //   height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                      //   child: TextField(
                      //     onChanged: (value) {
                      //       setState(() {
                      //         query = value;
                      //         if (query.length >= 3) {
                      //           searchCategory(query);
                      //         }
                      //         if (query.isEmpty) {
                      //           store.onSubCategoryApiCall(widget.notesid);
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

                      ///Chapters list
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
                                      note?.completPdfCount != null && (note?.completPdfCount ?? 0) > 0)
                                  .toList();
                            } else if (selectedFilter == "In Progress") {
                              filteredNotes = store.notessubcategory
                                  .where(
                                      (note) => note?.progressCount != null && (note?.progressCount ?? 0) > 0)
                                  .toList();
                            } else if (selectedFilter == "Not Started") {
                              filteredNotes = store.notessubcategory
                                  .where((note) => note?.notStart != null && (note?.notStart ?? 0) > 0)
                                  .toList();
                            } else if (selectedFilter == "Offline Notes") {
                              filteredNotes = store.notessubcategory.where((note) {
                                final subCatId = note?.sId ?? "";
                                final count = offlineCounts[subCatId] ?? 0;
                                return count > 0;
                              }).toList();
                            } else if (selectedFilter == "Bookmark Notes") {
                              filteredNotes = store.notessubcategory
                                  .where((note) =>
                                      note?.bookmarkPdfCount != null && (note?.bookmarkPdfCount ?? 0) > 0)
                                  .toList();
                            }
                            if (store.isLoading) {
                              return const SkeletonList(count: 4, itemHeight: 96);
                            }
                            if (store.notessubcategory.isEmpty) {
                              return const EmptyState(
                                icon: Icons.menu_book_outlined,
                                title: 'No chapters yet',
                                subtitle: 'New chapters will appear here as soon as they’re published.',
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
                                                builder: (BuildContext context, int index) {
                                                  final note = filteredNotes[index];
                                                  final subCategoryId = note?.sId ?? "";
                                                  final offlineCount = offlineCounts[subCategoryId] ?? 0;
                                                  return buildItem1(
                                                      context, filteredNotes[index], store, offlineCount);
                                                },
                                              )
                                            : ListView.builder(
                                                itemCount: filteredNotes.length,
                                                shrinkWrap: true,
                                                padding: EdgeInsets.zero,
                                                physics: const BouncingScrollPhysics(),
                                                itemBuilder: (BuildContext context, int index) {
                                                  final note = filteredNotes[index];
                                                  final subCategoryId = note?.sId ?? "";
                                                  final offlineCount = offlineCounts[subCategoryId] ?? 0;
                                                  return buildItem1(
                                                      context, filteredNotes[index], store, offlineCount);
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

  Widget buildItem(BuildContext context, GlobalSearchDataModel? searchDataModel) {
    GlobalSearchDataModel? noteSubcat = searchDataModel;
    String? categoryName = noteSubcat?.categoryName;
    String? subcategoryName = noteSubcat?.subcategoryName;
    String? topicName = noteSubcat?.topicName;
    String? title = noteSubcat?.title;

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
                arguments: {"subject": categoryName, "noteid": noteSubcat?.id});
          } else if (type == "Subcategory") {
            Navigator.of(context).pushNamed(Routes.notesTopicCategory, arguments: {
              "topicname": subcategoryName,
              "topic": subcategoryName,
              "subcatId": noteSubcat?.id
            });
          } else if (type == "Topic") {
            Navigator.of(context).pushNamed(Routes.notesChapterDetail, arguments: {
              "topicname": topicName,
              "chapter": topicName,
              "subcatId": noteSubcat?.id,
              "subcaptername": noteSubcat?.subName,
            });
          } else if (type == "Content") {
            Navigator.of(context).pushNamed(Routes.notesReadView, arguments: {
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
              'annotationData': convertAnnotationListToAnnotationData(noteSubcat?.annotation),
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
            children: [
              Container(
                height: Dimensions.PADDING_SIZE_LARGE * 3.2,
                width: Dimensions.PADDING_SIZE_LARGE * 3.2,
                padding: const EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
                decoration: BoxDecoration(
                  color: ThemeManager.continueContainer,
                  borderRadius: BorderRadius.circular(14.4),
                  // border: ProgressBorder.all(
                  //   width: 2,
                  //   color: ThemeManager.greenBorder,
                  //   progress: 0.55,
                  // )
                ),
                child: SvgPicture.asset(
                  "assets/image/book-open2.svg",
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
                      noteSubcat?.description ?? "",
                      style: interRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        fontWeight: FontWeight.w400,
                        overflow: TextOverflow.ellipsis,
                        color: ThemeManager.black.withOpacity(0.5),
                      ),
                      maxLines: 1,
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
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildItem1(BuildContext context, NotesSubCategoryModel? notesSubCategoryModel,
      NotesCategoryStore store, int offlineCount) {
    NotesSubCategoryModel? notesSubcategory = notesSubCategoryModel;
    int completeNotesCount = notesSubcategory?.completPdfCount ?? 0;
    int notesCount = notesSubcategory?.notes ?? 0;
    double? progressCount = completeNotesCount / notesCount;
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.PADDING_SIZE_SMALL),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(Routes.notesTopicCategory, arguments: {
            "topicname": widget.subject,
            "topic": notesSubcategory?.subcategoryName,
            "subcatId": notesSubcategory?.sId
          }).then((value) {
            store.onSubCategoryApiCall(widget.notesid);
          });
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
                      color: ThemeManager.continueContainerTrans,
                      borderRadius: BorderRadius.circular(14.4),
                      // border: ProgressBorder.all(
                      //   width: 2,
                      //   color: ThemeManager.greenBorder,
                      //   progress: progressCount,
                      // )
                    ),
                    child: SvgPicture.asset(
                      "assets/image/book-open2.svg",
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
                              width: isDesktop
                                  ? MediaQuery.of(context).size.width * 0.2
                                  : MediaQuery.of(context).size.width * 0.4,
                              child: Text(
                                notesSubcategory?.subcategoryName ?? "",
                                maxLines: 3,
                                overflow: TextOverflow.visible,
                                style: interSemiBold.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  fontWeight: FontWeight.w600,
                                  color: ThemeManager.black,
                                ),
                              ),
                            ),
                            (notesSubcategory?.topicCount != null && notesSubcategory?.notes != null)
                                ? Text(
                                    "${notesSubcategory?.notes.toString()} Notes",
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
                          notesSubcategory?.description ?? "",
                          style: interRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            fontWeight: FontWeight.w400,
                            overflow: TextOverflow.ellipsis,
                            color: ThemeManager.black.withOpacity(0.5),
                          ),
                          maxLines: 1,
                        ),
                        const SizedBox(
                          height: Dimensions.PADDING_SIZE_EXTRA_SMALL,
                        ),
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
                        "${notesSubcategory?.completPdfCount.toString() ?? "0"} Completed",
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
                        "${notesSubcategory?.progressCount.toString() ?? "0"} In Progress",
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
                        "${notesSubcategory?.notStart.toString() ?? "0"} Not Started",
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
                  if ((notesSubcategory?.bookmarkPdfCount ?? 0) > 0)
                    Row(
                      children: [
                        SvgPicture.asset(
                          "assets/image/bookmark_status_icon.svg",
                          height: Dimensions.PADDING_SIZE_LARGE,
                          width: Dimensions.PADDING_SIZE_LARGE,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${notesSubcategory?.bookmarkPdfCount.toString() ?? "0"}  Bookmarked",
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
              notesSubcategory?.priorityLabel != null ? const Divider() : SizedBox.shrink(),
              Center(
                child: PriorityBadge(
                  priorityLabel: notesSubcategory?.priorityLabel,
                  priorityColor: notesSubcategory?.priorityColor,
                ),
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
