import 'dart:io';
import 'dart:ui';
import '../../app/routes.dart';
import '../../helpers/app_skeleton.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/empty_state.dart';
import '../../helpers/styles.dart';
import '../../helpers/dbhelper.dart';
import 'package:flutter_svg/svg.dart';
import '../widgets/bottom_toast.dart';
import 'package:flutter/material.dart';
import '../../helpers/dimensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../dashboard/store/home_store.dart';
import '../../models/notes_topic_model.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../widgets/no_access_bottom_sheet.dart';
import '../widgets/no_internet_connection.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/notes_offline_data_model.dart';
import 'package:shusruta_lms/helpers/constants.dart';
import '../dashboard/models/global_search_model.dart';
import '../videolectures/store/video_category_store.dart';
import 'package:shusruta_lms/modules/notes/sharedhelper.dart';
import 'package:shusruta_lms/helpers/custom_dynamic_height_gridview.dart';
import 'package:shusruta_lms/modules/widgets/no_access_alert_dialog.dart';
import 'package:shusruta_lms/modules/notes/store/notes_category_store.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

  @override
  void initState() {
    super.initState();
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _initializeNotifications();
    _getNotesList();
  }

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
    // isBookmarkedDone = store.notestopic.map((topic) => topic?.isBookmark ?? false).toList();
  }

  Future<void> _putBookMarkApiCall(String? titleId) async {
    final store = Provider.of<VideoCategoryStore>(context, listen: false);
    await store.onCreateBookmarkContentApiCall(titleId ?? '');
  }

  Future<void> searchCategory(String keyword) async {
    // final store = Provider.of<NotesCategoryStore>(context, listen: false);
    // await store.onSearchApiCall(keyword, "PDF");
    final store = Provider.of<HomeStore>(context, listen: false);
    await store.onGlobalSearchApiCall(keyword, "pdf");
  }

  @override
  Widget build(BuildContext context) {
    final List<String> filters = [
      "All",
      "Completed",
      "In Progress",
      "Not Started",
      "Offline Notes",
      "Bookmarked Notes"
    ];

    bool isDesktop = Platform.isWindows || Platform.isMacOS;
    final store = Provider.of<NotesCategoryStore>(context, listen: false);
    final homeStore = Provider.of<HomeStore>(context, listen: false);
    return Scaffold(
        backgroundColor: AppTokens.scaffold(context),
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: AppTokens.scaffold(context),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: AppTokens.ink(context), size: 18),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(widget.chapter, style: AppTokens.titleLg(context)),
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
        //             widget.chapter,
        //             style: interRegular.copyWith(
        //               fontSize: Dimensions.fontSizeLarge,
        //               fontWeight: FontWeight.w500,
        //               color: ThemeManager.black,
        //             ),
        //           ),
        //           Text(
        //             "${store.notestopic.length.toString().padLeft(2,'0')} Notes",
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
              //         child: SvgPicture.asset("assets/image/notedetails2.svg"),
              //       ),
              //       const SizedBox(
              //         width: Dimensions.PADDING_SIZE_DEFAULT,
              //       ),
              //       Column(
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         children: [
              //           Text(
              //             "Topics",
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
              //               store.notestopic.length.toString().padLeft(2, '0'),
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
                  padding: const EdgeInsets.fromLTRB(
                      AppTokens.s24, AppTokens.s8, AppTokens.s24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // query.isNotEmpty
                      //     ? Text(
                      //         "Results for “$query”",
                      //         style: interRegular.copyWith(
                      //           fontSize: Dimensions.fontSizeDefault,
                      //           fontWeight: FontWeight.w400,
                      //           color: ThemeManager.black,
                      //         ),
                      //       )
                      //     : const SizedBox(),
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
                      //     keyboardType: TextInputType.text,
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2.0),
                              child: ChoiceChip(
                                side:
                                    BorderSide(color: ThemeManager.mainBorder),
                                label: Text(filter),
                                labelStyle: interRegular.copyWith(
                                  fontSize: Dimensions.fontSizeExtraSmall,
                                  fontWeight: FontWeight.w400,
                                  color: selectedFilter == filter
                                      ? ThemeManager.white
                                      : ThemeManager.black,
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
                            filteredNotes = store.notestopic;
                            // _fetchOfflineCounts();
                            _filterNotes();
                            if (store.isLoading) {
                              return const SkeletonList(
                                  count: 5, itemHeight: 96);
                            }
                            if (store.notestopic.isEmpty) {
                              return const EmptyState(
                                icon: Icons.picture_as_pdf_outlined,
                                title: 'No notes yet',
                                subtitle:
                                    'New notes will appear here as soon as they’re published.',
                              );
                            }
                            if (store.isConnected) {
                              return RefreshIndicator(
                                color: AppTokens.accent(context),
                                backgroundColor: AppTokens.surface(context),
                                onRefresh: () => _getNotesList(),
                                child: homeStore.isLoading && store.isLoadingPdf
                                    ? const SkeletonList(
                                        count: 5, itemHeight: 96)
                                    : (homeStore.globalSearchList.isNotEmpty &&
                                            query.isNotEmpty)
                                        ? isDesktop
                                            ? CustomDynamicHeightGridView(
                                                crossAxisCount: 3,
                                                mainAxisSpacing: 10,
                                                itemCount: homeStore
                                                    .globalSearchList.length,
                                                builder: (BuildContext context,
                                                    int index) {
                                                  return buildItem(
                                                      context,
                                                      homeStore
                                                              .globalSearchList[
                                                          index]);
                                                },
                                              )
                                            : ListView.builder(
                                                itemCount: homeStore
                                                    .globalSearchList.length,
                                                shrinkWrap: true,
                                                padding: EdgeInsets.zero,
                                                physics:
                                                    const BouncingScrollPhysics(),
                                                itemBuilder:
                                                    (BuildContext context,
                                                        int index) {
                                                  return buildItem(
                                                      context,
                                                      homeStore
                                                              .globalSearchList[
                                                          index]);
                                                },
                                              )
                                        : isDesktop
                                            ? CustomDynamicHeightGridView(
                                                crossAxisCount: 3,
                                                mainAxisSpacing: 10,
                                                itemCount: filteredNotes.length,
                                                builder: (BuildContext context,
                                                    int index) {
                                                  if (filteredNotes.isEmpty) {
                                                    return const Center(
                                                      child: Text(
                                                          "No videos available"),
                                                    );
                                                  }

                                                  final titleId =
                                                      filteredNotes[index]
                                                              ?.sId
                                                              .toString() ??
                                                          "";
                                                  final String pdfUrl =
                                                      filteredNotes[index]
                                                              ?.contentUrl ??
                                                          "";
                                                  if (!store.pdfPageCounts
                                                      .containsKey(pdfUrl)) {
                                                    store.fetchPdfPageCount(
                                                        pdfUrl);
                                                  }
                                                  return Observer(
                                                    builder: (context) {
                                                      final int pageCount =
                                                          store.pdfPageCounts[
                                                                  pdfUrl] ??
                                                              0;
                                                      return FutureBuilder<
                                                          bool>(
                                                        future:
                                                            _checkIfNoteDownloaded(
                                                                titleId),
                                                        builder: (context,
                                                            snapshot) {
                                                          final isDownloaded =
                                                              snapshot.data ??
                                                                  false;
                                                          return buildItem1(
                                                            context,
                                                            filteredNotes[
                                                                index],
                                                            index,
                                                            store,
                                                            pageCount,
                                                            isDownloaded:
                                                                isDownloaded,
                                                          );
                                                        },
                                                      );
                                                    },
                                                  );
                                                },
                                              )
                                            : ListView.builder(
                                                itemCount: filteredNotes.length,
                                                shrinkWrap: true,
                                                padding: EdgeInsets.zero,
                                                physics:
                                                    const AlwaysScrollableScrollPhysics(),
                                                itemBuilder:
                                                    (BuildContext context,
                                                        int index) {
                                                  if (filteredNotes.isEmpty) {
                                                    return const Center(
                                                      child: Text(
                                                          "No videos available"),
                                                    );
                                                  }

                                                  final titleId =
                                                      filteredNotes[index]
                                                              ?.sId
                                                              .toString() ??
                                                          "";
                                                  final String pdfUrl =
                                                      filteredNotes[index]
                                                              ?.contentUrl ??
                                                          "";
                                                  if (!store.pdfPageCounts
                                                      .containsKey(pdfUrl)) {
                                                    store.fetchPdfPageCount(
                                                        pdfUrl);
                                                  }
                                                  return Observer(
                                                    builder: (context) {
                                                      final int pageCount =
                                                          store.pdfPageCounts[
                                                                  pdfUrl] ??
                                                              0;
                                                      return FutureBuilder<
                                                          bool>(
                                                        future:
                                                            _checkIfNoteDownloaded(
                                                                titleId),
                                                        builder: (context,
                                                            snapshot) {
                                                          final isDownloaded =
                                                              snapshot.data ??
                                                                  false;
                                                          return buildItem1(
                                                            context,
                                                            filteredNotes[
                                                                index],
                                                            index,
                                                            store,
                                                            pageCount,
                                                            isDownloaded:
                                                                isDownloaded,
                                                          );
                                                        },
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                              );
                            } else {
                              return const NoInternetScreen();
                            }
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

  Widget buildItem(
      BuildContext context, GlobalSearchDataModel? searchDataModel) {
    GlobalSearchDataModel? noteTopic = searchDataModel;
    String? categoryName = noteTopic?.categoryName;
    String? subcategoryName = noteTopic?.subcategoryName;
    String? topicName = noteTopic?.topicName;
    String? title = noteTopic?.title;

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
      padding: const EdgeInsets.only(bottom: Dimensions.PADDING_SIZE_SMALL),
      child: InkWell(
        onTap: () {
          if (type == "Category") {
            Navigator.of(context).pushNamed(Routes.notesSubjectDetail,
                arguments: {"subject": categoryName, "noteid": noteTopic?.id});
          } else if (type == "Subcategory") {
            Navigator.of(context)
                .pushNamed(Routes.notesTopicCategory, arguments: {
              "topicname": subcategoryName,
              "topic": subcategoryName,
              "subcatId": noteTopic?.id
            });
          } else if (type == "Topic") {
            Navigator.of(context)
                .pushNamed(Routes.notesChapterDetail, arguments: {
              "topicname": topicName,
              "chapter": topicName,
              "subcatId": noteTopic?.id,
              "subcaptername": noteTopic?.subName,
            });
          } else if (type == "Content") {
            Navigator.of(context).pushNamed(Routes.notesReadView, arguments: {
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
                padding: const EdgeInsets.all(Dimensions.PADDING_SIZE_LARGE),
                decoration: BoxDecoration(
                  color: ThemeManager.continueContainerTrans,
                  borderRadius: BorderRadius.circular(14.4),
                ),
                child: SvgPicture.asset(
                  "assets/image/notedetails.svg",
                  color: ThemeManager.currentTheme == AppTheme.Dark
                      ? AppColors.white
                      : null,
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
                      noteTopic?.description ?? "",
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

  Widget buildItem1(BuildContext context, NotesTopicModel? notesTopicModel,
      int index, NotesCategoryStore store, int pageCount,
      {bool? isDownloaded = false}) {
    NotesTopicModel? notesTopic = notesTopicModel;
    // debugPrint('bookmark${isBookmarkedDone?[index]}');
    // debugPrint('annotationList${notesTopicModel?.annotation.toString()}');
    if (query.isNotEmpty &&
        (!notesTopic!.title!.toLowerCase().contains(query.toLowerCase()))) {
      return Container();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.PADDING_SIZE_SMALL),
      child: InkWell(
        onTap: () async {
          // if(notesTopic?.contentUrl!=null&&
          //     notesTopic?.contentUrl!=""){
          //   Navigator.of(context).pushNamed(Routes.notesReadView,
          //       arguments: {
          //         'contentUrl': notesTopic?.contentUrl,
          //         'title': notesTopic?.title ?? '',
          //         'topic_name': notesTopic?.topic_name ?? '',
          //         'category_name': notesTopic?.category_name ?? '',
          //         'subcategory_name': notesTopic?.subcategory_name ?? '',
          //         'isDownloaded': false,
          //         'topicId': notesTopic?.topicId,
          //         'titleId': notesTopic?.sId,
          //         'categoryId': notesTopic?.categoryId,
          //         'subcategoryId': notesTopic?.subcategoryId,
          //       });
          // }
          // else{
          //   BottomToast.showBottomToastOverlay(
          //     context: context,
          //     errorMessage: "No File is Found!",
          //     backgroundColor: ThemeManager.redAlert,
          //   );
          // }
          if (notesTopic?.isAccess == true) {
            notesTopic?.contentUrl != null && notesTopic?.contentUrl != ""
                ? Navigator.of(context)
                    .pushNamed(Routes.notesReadView, arguments: {
                    'topic_name': notesTopic?.topic_name ?? '',
                    'category_name': notesTopic?.category_name ?? '',
                    'subcategory_name': notesTopic?.subcategory_name ?? '',
                    'categoryId': notesTopic?.categoryId,
                    'subcategoryId': notesTopic?.subcategoryId,
                    'contentUrl': notesTopic?.contentUrl,
                    'title': notesTopic?.title,
                    'titleId': notesTopic?.sId,
                    'annotationData': notesTopicModel?.annotationData.toString(),
                    'isDownloaded': isDownloaded,
                    'isCompleted': notesTopic?.isCompleted,
                    'topicId': notesTopic?.topicId,
                    'isBookMark': notesTopic?.isBookmark,
                    'pageNo': notesTopicModel?.pageNumber,
                  }).then((value) => _getNotesList())
                : BottomToast.showBottomToastOverlay(
                    context: context,
                    errorMessage: "No File is Found!",
                    backgroundColor: ThemeManager.redAlert,
                  );
          } else {
            if (Platform.isWindows || Platform.isMacOS) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: ThemeManager.mainBackground,
                    actionsPadding: EdgeInsets.zero,
                    insetPadding: const EdgeInsets.symmetric(horizontal: 100),
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
                      top: Radius.circular(25),
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
            // BottomToast.showBottomToastOverlay(context: context,
            //     errorMessage: "Upgrade Your Plan",
            //     backgroundColor: ThemeManager.redAlert);
            // Navigator.of(context).pushNamed(Routes.subscriptionPlan);
          }
        },
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(Dimensions.PADDING_SIZE_DEFAULT),
              decoration: BoxDecoration(
                  color: ThemeManager.white,
                  border: Border.all(color: ThemeManager.mainBorder),
                  borderRadius: BorderRadius.circular(9.6)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: Dimensions.PADDING_SIZE_LARGE * 3.2,
                        width: Dimensions.PADDING_SIZE_LARGE * 3.2,
                        padding:
                            const EdgeInsets.all(Dimensions.PADDING_SIZE_LARGE),
                        decoration: BoxDecoration(
                          color: ThemeManager.continueContainerTrans,
                          borderRadius: BorderRadius.circular(14.4),
                          // border: ProgressBorder.all(
                          //   width: 2,
                          //   color: ThemeManager.greenBorder,
                          //   progress: (notesTopic?.isCompleted == false) ? 0 : 100,
                          // )
                        ),
                        child: SvgPicture.asset(
                          "assets/image/notedetails.svg",
                          color: ThemeManager.currentTheme == AppTheme.Dark
                              ? AppColors.white
                              : null,
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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: isDesktop
                                          ? MediaQuery.of(context).size.width *
                                              0.2
                                          : MediaQuery.of(context).size.width *
                                              0.4,
                                      child: Text(
                                        notesTopic?.title ?? "",
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
                                        height: Dimensions
                                            .PADDING_SIZE_EXTRA_SMALL),
                                    Text(
                                      "Total Pages - $pageCount",
                                      style: interRegular.copyWith(
                                        fontSize: Dimensions.fontSizeExtraSmall,
                                        color:
                                            ThemeManager.black.withOpacity(0.6),
                                      ),
                                    )
                                  ],
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
                                  child: isBookmarkedDone?[index] == true
                                      ? SvgPicture.asset(
                                          "assets/image/bookmarkfill_video_icon.svg",
                                          height: Dimensions
                                              .PADDING_SIZE_EXTRA_LARGE,
                                          width: Dimensions
                                              .PADDING_SIZE_EXTRA_LARGE,
                                        )
                                      : SvgPicture.asset(
                                          "assets/image/bookmark_video_icon.svg",
                                          height: Dimensions
                                              .PADDING_SIZE_EXTRA_LARGE,
                                          width: Dimensions
                                              .PADDING_SIZE_EXTRA_LARGE,
                                        ),
                                )
                              ],
                            ),
                            const SizedBox(
                              height: Dimensions.PADDING_SIZE_EXTRA_SMALL,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      notesTopic?.isCompleted == true
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SvgPicture.asset(
                                  "assets/image/completed_status_icon.svg",
                                  height: Dimensions.PADDING_SIZE_LARGE,
                                  width: Dimensions.PADDING_SIZE_LARGE,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  " Completed",
                                  style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeExtraSmall,
                                    color: ThemeManager.black.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            )
                          : notesTopic?.pageNumber != 0
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      "assets/image/inprogress_status_icon.svg",
                                      height: Dimensions.PADDING_SIZE_LARGE,
                                      width: Dimensions.PADDING_SIZE_LARGE,
                                    ),
                                    const SizedBox(width: 4),
                                    SizedBox(
                                      width: isDesktop
                                          ? null
                                          : MediaQuery.of(context).size.width *
                                              0.45,
                                      child: Text(
                                        " Paused | Continue Reading - Page ${notesTopic?.pageNumber.toString() ?? "0"}",
                                        // " Paused | $totalPageno out of ${notesTopic?.pageNumber.toString() ?? "0"} left",
                                        style: interRegular.copyWith(
                                          fontSize:
                                              Dimensions.fontSizeExtraSmall,
                                          color: ThemeManager.black
                                              .withOpacity(0.6),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : notesTopic?.notStart == true
                                  ? Row(
                                      children: [
                                        SvgPicture.asset(
                                          "assets/image/notstart_status_icon.svg",
                                          height: Dimensions.PADDING_SIZE_LARGE,
                                          width: Dimensions.PADDING_SIZE_LARGE,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          " Not Started",
                                          style: interRegular.copyWith(
                                            fontSize:
                                                Dimensions.fontSizeExtraSmall,
                                            color: ThemeManager.black
                                                .withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        SvgPicture.asset(
                                          "assets/image/notstart_status_icon.svg",
                                          height: Dimensions.PADDING_SIZE_LARGE,
                                          width: Dimensions.PADDING_SIZE_LARGE,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          " Not Started",
                                          style: interRegular.copyWith(
                                            fontSize:
                                                Dimensions.fontSizeExtraSmall,
                                            color: ThemeManager.black
                                                .withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                      // Observer(builder: (BuildContext context) {
                      //   final isDownloading = store
                      //       .isDownloading(notesTopic?.sId?.toString() ?? "");

                      //   debugPrint('isdownl$isDownloading');
                      //   return InkWell(
                      //     onTap: () async {
                      //       if (isDownloaded) {
                      //         showDialog(
                      //           context: context,
                      //           builder: (BuildContext context) {
                      //             return AlertDialog(
                      //               title: Text(
                      //                 "Delete Confirmation",
                      //                 style: interRegular.copyWith(
                      //                   fontSize: Dimensions.fontSizeDefault,
                      //                   fontWeight: FontWeight.w600,
                      //                   color: ThemeManager.blackColor,
                      //                 ),
                      //               ),
                      //               content: Text(
                      //                 "Are you sure you want to delete the offline downloaded note?",
                      //                 style: interRegular.copyWith(
                      //                   fontSize: Dimensions.fontSizeSmall,
                      //                   fontWeight: FontWeight.w600,
                      //                   color: ThemeManager.blackColor,
                      //                 ),
                      //               ),
                      //               actions: [
                      //                 TextButton(
                      //                   onPressed: () {
                      //                     Navigator.pop(context);
                      //                   },
                      //                   child: Text(
                      //                     "Cancel",
                      //                     style: interRegular.copyWith(
                      //                       fontSize:
                      //                           Dimensions.fontSizeDefault,
                      //                       fontWeight: FontWeight.w600,
                      //                       color: ThemeManager.blackColor,
                      //                     ),
                      //                   ),
                      //                 ),
                      //                 ElevatedButton(
                      //                   onPressed: () async {
                      //                     await dbHelper.deleteNoteByTitleId(
                      //                         notesTopic?.sId.toString() ?? "");
                      //                     BottomToast.showBottomToastOverlay(
                      //                       context: context,
                      //                       errorMessage:
                      //                           "Offline downloaded note has been deleted successfully!",
                      //                       backgroundColor:
                      //                           Theme.of(context).primaryColor,
                      //                     );
                      //                     Navigator.pop(context);
                      //                     Navigator.pop(context);
                      //                     Navigator.pop(context);
                      //                     setState(() {});
                      //                   },
                      //                   style: ElevatedButton.styleFrom(
                      //                     backgroundColor: AppColors.redText,
                      //                   ),
                      //                   child: Text(
                      //                     "Delete",
                      //                     style: interRegular.copyWith(
                      //                       fontSize:
                      //                           Dimensions.fontSizeDefault,
                      //                       fontWeight: FontWeight.w600,
                      //                       color: ThemeManager.white,
                      //                     ),
                      //                   ),
                      //                 ),
                      //               ],
                      //             );
                      //           },
                      //         );
                      //       } else {
                      //         String pdfUrl = notesTopic?.contentUrl ?? "";
                      //         if (pdfUrl.isNotEmpty) {
                      //           pdfUrl =
                      //               "getPDF${pdfUrl.substring(pdfUrl.lastIndexOf('/'))}";
                      //         }
                      //         String url = pdfBaseUrl + pdfUrl;
                      //         String filename = notesTopic?.title ?? "Notes";
                      //         downloadPDF(url, filename, store, notesTopic);
                      //       }
                      //     },
                      //     child: Row(
                      //       mainAxisAlignment: MainAxisAlignment.end,
                      //       children: [
                      //         isDownloading
                      //             ? SizedBox(
                      //                 width: 20,
                      //                 height: 20,
                      //                 child: CircularProgressIndicator(
                      //                   color: ThemeManager.primaryColor,
                      //                 ),
                      //               )
                      //             : Icon(
                      //                 isDownloaded!
                      //                     ? Icons.check_circle
                      //                     : Icons.download_for_offline,
                      //                 color: isDownloaded
                      //                     ? Colors.green
                      //                     : ThemeManager.blueFinal,
                      //               ),
                      //         const SizedBox(width: 4),
                      //         Text(
                      //           isDownloaded!
                      //               ? "Downloaded"
                      //               : isDownloading
                      //                   ? "Downloading"
                      //                   : "Download",
                      //           style: interRegular.copyWith(
                      //             fontSize: Dimensions.fontSizeExtraSmall,
                      //             fontWeight: FontWeight.w500,
                      //             color: isDownloaded
                      //                 ? Colors.green
                      //                 : isDownloading
                      //                     ? ThemeManager.primaryColor
                      //                     : ThemeManager.blackColor,
                      //           ),
                      //         ),
                      //       ],
                      //     ),
                      //   );
                      // })
                      // Observer(
                      //     builder: (context) {
                      //       final isDownloading = store.isDownloading(videoTopic?.id?.toString()??"");
                      //       final progress = store.getDownloadProgress(videoTopic?.id?.toString()??"");
                      //
                      //       return Row(
                      //         mainAxisAlignment: MainAxisAlignment.end,
                      //         children: [
                      //           isDownloading ? SizedBox(
                      //             width: 20,
                      //             height: 20,
                      //             child: CircularProgressIndicator(
                      //               value: progress / 100,
                      //               strokeWidth: 3.0,
                      //               valueColor: AlwaysStoppedAnimation<Color>(ThemeManager.primaryColor),
                      //             ),
                      //           )
                      //               : Icon(
                      //             isDownloaded!
                      //                 ? Icons.check_circle
                      //                 : Icons.download_for_offline,
                      //             color: isDownloaded ? Colors.green : ThemeManager.blueFinal,
                      //           ),
                      //           const SizedBox(width: 4),
                      //           Text(
                      //             isDownloaded!
                      //                 ? "Downloaded"
                      //                 : isDownloading
                      //                 ? "Downloading $progress%"
                      //                 : "Download",
                      //             style: interRegular.copyWith(
                      //               fontSize: Dimensions.fontSizeExtraSmall,
                      //               fontWeight: FontWeight.w500,
                      //               color: isDownloaded
                      //                   ? Colors.green
                      //                   : isDownloading
                      //                   ? ThemeManager.primaryColor
                      //                   : ThemeManager.blackColor,
                      //             ),
                      //           ),
                      //         ],
                      //       );
                      //     }
                      // )
                    ],
                  ),
                ],
              ),
            ),
            if (notesTopic?.isAccess == false)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  height: Dimensions.PADDING_SIZE_LARGE,
                  width: Dimensions.PADDING_SIZE_LARGE,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: ThemeManager.primaryColor,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(9.6),
                        bottomLeft: Radius.circular(9.6),
                      )),
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
    );
  }

  void _filterNotes() async {
    final store = Provider.of<NotesCategoryStore>(context, listen: false);
    List<NotesTopicModel?> filtered = [];
    if (selectedFilter == "All") {
      filtered = store.notestopic;
    } else if (selectedFilter == "Completed") {
      filtered = store.notestopic
          .where((note) =>
              note?.isCompleted != null && (note?.isCompleted ?? false) == true)
          .toList();
    } else if (selectedFilter == "In Progress") {
      filtered =
          store.notestopic.where((note) => (note?.isPaused ?? false)).toList();
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
      filtered =
          store.notestopic.where((note) => note?.isBookmark == true).toList();
    }
    filteredNotes = filtered;
    isBookmarkedDone =
        filtered.map((topic) => topic?.isBookmark ?? false).toList();
    // setState(() {});
  }

  Future<void> _filterOfflineNotes() async {
    final store = Provider.of<NotesCategoryStore>(context, listen: false);
    List<NotesTopicModel?> downloadedNotes = [];
    for (var note in store.notestopic) {
      final titleId = note?.sId.toString() ?? "";
      final isDownloaded = await _checkIfNoteDownloaded(titleId);
      if (isDownloaded) {
        downloadedNotes.add(note);
      }
    }

    offlineNotes = downloadedNotes;
  }

  Future<bool> _checkIfNoteDownloaded(String titleId) async {
    final downloadedNote = await dbHelper.getNoteByTitleId(titleId);
    if (downloadedNote != null) {
      final videoPath = downloadedNote.notePath;
      final file = File(videoPath!);
      if (await file.exists()) {
        debugPrint("downExists");
        return true;
      } else {
        // Clean up the database entry if the file is missing
        await dbHelper.deleteNoteByTitleId(titleId);
      }
    }
    return false;
  }

  Future<void> downloadPDF(String url, String filename,
      NotesCategoryStore store, NotesTopicModel? notesTopic) async {
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

        response.stream.listen((data) {
          downloadedBytes += data.length;
          fileSink.add(data);

          if (totalBytes > 0) {
            double progress =
                ((downloadedBytes / totalBytes) * 100).clamp(0, 100);
            _updatePDFDownloadProgressNotification(progress.toInt());
            debugPrint("PDF Download Progress: $progress%");
          }
        }, onDone: () async {
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

          if (!isDesktop) {
            _showPDFDownloadNotification('PDF Download Complete',
                "${notesTopic?.title} has been saved offline successfully.");
          }
          if (mounted) {
            setState(() {
              isDownloaded = true;
            });
          }
        }, onError: (e) async {
          debugPrint("Error downloading PDF: $e");
          store.cancelDownload(titleId);
          await fileSink.close();
        }, cancelOnError: true);
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

    NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      1, // Unique Notification ID
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
      1, // Unique Notification ID
      title,
      message,
      platformDetails,
    );
  }
}
