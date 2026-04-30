import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/helpers/custom_dynamic_height_gridview.dart';
import 'package:shusruta_lms/modules/notes/sharedhelper.dart';
import 'package:shusruta_lms/modules/videolectures/store/video_category_store.dart';
import 'package:shusruta_lms/modules/videolectures/widgets/download_manager_sheet.dart';
import 'package:shusruta_lms/services/download_service.dart';
import 'package:shusruta_lms/services/offline_encryptor.dart';
import 'package:shusruta_lms/services/secure_keys.dart';

import '../../app/routes.dart';
import '../../helpers/app_skeleton.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/dbhelper.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/empty_state.dart';
import '../../helpers/styles.dart';
import '../../models/video_data_model.dart';
import '../../models/video_topic_model.dart';
import '../dashboard/models/global_search_model.dart';
import '../dashboard/store/home_store.dart';
import '../widgets/bottom_toast.dart';
import '../widgets/no_access_alert_dialog.dart';
import '../widgets/no_access_bottom_sheet.dart';
import '../widgets/no_internet_connection.dart';

class VideoChapterDetail extends StatefulWidget {
  final String chapter;
  final String? subject;
  final String subcatId;
  const VideoChapterDetail({super.key, required this.chapter, required this.subcatId, required this.subject});

  @override
  State<VideoChapterDetail> createState() => _VideoChapterDetailState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => VideoChapterDetail(
          chapter: arguments['chapter'], subject: arguments['subject'], subcatId: arguments['subcatId']),
    );
  }
}

class _VideoChapterDetailState extends State<VideoChapterDetail> {
  final dbHelper = DbHelper();
  late VideoCategoryStore _videoStore;
  String query = '';
  bool isOfflineMode = false;
  // NOTE: No class-level `isDownloaded` field here. Using one was the root
  // cause of the "all videos show downloaded" bug — it leaks across siblings.
  // Per-video download status is ALWAYS read from the store's
  // downloadedVideoIds ObservableSet via store.isVideoDownloadedCached(titleId).
  String selectedFilter = "All";
  int downloadProgress = 0;
  late List<VideoTopicModel?> filteredVideos;
  late List<VideoTopicModel?> offlineVideos;
  final Map<String, bool> downloadStatus = {};
  List<bool>? isBookmarkedDone = [];
  final FocusNode _focusNode = FocusNode();
  final Map<String, String> _videoUrls = {};
  final Map<String, String> _qualityAndSize = {};
  // Keyed by the same label used in _qualityAndSize so that user selection can
  // look up the exact download URL. Previously we kept a single `downloadUrl`
  // String that was overwritten on every loop iteration in initializeDownload
  // — so selecting any quality downloaded whatever the LAST rendition in the
  // API response happened to be (usually the biggest file). That was the root
  // cause of the "download progress not showing / wrong file size" reports.
  final Map<String, String> _downloadUrls = {};
  int _selectedIndex = 0;
  String downloadQuality = "540p";
  String downloadUrl = "";
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _initializeNotifications();
    _focusNode.addListener(_onFocusChanged);
    _getVideoList();
  }

  Future<void> _initializeNotifications() async {
    const AndroidNotificationChannel androidNotificationChannel = AndroidNotificationChannel(
      'download_channel', // Channel ID
      'Downloads', // Channel Name
      description: 'Notifications for download progress',
      importance: Importance.high,
    );

    // Now create the channel
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidNotificationChannel);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _videoStore = Provider.of<VideoCategoryStore>(context, listen: false);
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  Future<void> _getVideoList() async {
    final store = Provider.of<VideoCategoryStore>(context, listen: false);
    await store.onTopicApiCall(widget.subcatId);
    if (!mounted) return;
    // Pre-load download status for all videos in one batch (replaces per-item
    // FutureBuilder DB queries). Use the same identifier resolver as the tap
    // handler — otherwise videos whose `id` is null would be keyed as the
    // literal "null" string, which the store's `_isValidTitleId` rejects, so
    // their "Downloaded" badge would never light up.
    final allIds =
        store.videotopic.where((v) => v != null).map(_resolveTitleId).where((tid) => tid.isNotEmpty).toList();
    await store.loadDownloadedIds(allIds);
    if (!mounted) return;
    await _filterOfflineVideos();
  }

  Future<void> _putBookMarkApiCall(String? titleId) async {
    final store = Provider.of<VideoCategoryStore>(context, listen: false);
    await store.onCreateBookmarkContentApiCall(titleId ?? '');
  }

  Future<void> searchCategory(String keyword) async {
    // final store = Provider.of<VideoCategoryStore>(context, listen: false);
    // await store.onSearchApiCall(keyword, "video");
    final store = Provider.of<HomeStore>(context, listen: false);
    await store.onGlobalSearchApiCall(keyword, "video");
  }

  @override
  Widget build(BuildContext context) {
    final List<String> filters = [
      "All",
      "Completed",
      "In Progress",
      "Not Started",
      "Offline Videos",
      "Bookmarked Videos"
    ];
    final store = Provider.of<VideoCategoryStore>(context, listen: false);
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
      //             "${store.videotopic.length.toString().padLeft(2,'0')} Videos",
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
            // Header action row — preserves the legacy "Download all"
            // observer + bookmarks pill that lives next to the title
            // in the original blue-strip header. AppTokens-toned now.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppTokens.s24, AppTokens.s8, AppTokens.s12, AppTokens.s4),
              child: Row(
                children: [
                  const Spacer(),
                  // Download All button
                  Observer(builder: (_) {
                    final downloadedCount = store.downloadedVideoIds.length;
                    final totalCount = store.videotopic.length;
                    final allDownloaded = totalCount > 0 && downloadedCount >= totalCount;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!allDownloaded && totalCount > 0)
                          GestureDetector(
                            onTap: () => _downloadAllVideos(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.download_rounded, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'All',
                                    style: interRegular.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (downloadedCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$downloadedCount offline',
                                style: interRegular.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green[300],
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 4),
                        // Downloads manager
                        GestureDetector(
                          onTap: () => DownloadManagerSheet.show(context),
                          child: const Icon(Icons.queue_rounded, color: Colors.white70, size: 20),
                        ),
                      ],
                    );
                  }),
                  // const Spacer(),
                  // Container(
                  //   padding: EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_SMALL*1.2,vertical: Dimensions.PADDING_SIZE_EXTRA_SMALL*1.6),
                  //   decoration: BoxDecoration(
                  //       color: ThemeManager.white,
                  //       borderRadius: BorderRadius.circular(50.53)
                  //   ),
                  //   child: Text(
                  //     "Offline Videos",
                  //     style: interRegular.copyWith(
                  //       fontSize: Dimensions.fontSizeSmall,
                  //       fontWeight: FontWeight.w500,
                  //       color: ThemeManager.blueFinal,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
            // Padding(
            //   padding: const EdgeInsets.only(
            //       left: Dimensions.PADDING_SIZE_LARGE * 1.2,
            //       right: Dimensions.PADDING_SIZE_LARGE * 1.2,
            //       bottom: Dimensions.PADDING_SIZE_SMALL * 2.1),
            //   child: Row(
            //     children: [
            //       Container(
            //         height: Dimensions.PADDING_SIZE_SMALL * 3.362,
            //         width: Dimensions.PADDING_SIZE_SMALL * 3.362,
            //         margin: const EdgeInsets.only(
            //             right: Dimensions.PADDING_SIZE_SMALL),
            //         padding: const EdgeInsets.all(
            //             Dimensions.PADDING_SIZE_EXTRA_SMALL * 1.6),
            //         decoration: BoxDecoration(
            //             color:
            //                 ThemeManager.videoSubjectContainer.withOpacity(0.3),
            //             borderRadius: BorderRadius.circular(9.61)),
            //         child: SvgPicture.asset("assets/image/videochapter2.svg"),
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
            //             height: 4,
            //           ),
            //           Observer(builder: (context) {
            //             return Text(
            //               store.videotopic.length.toString().padLeft(2, '0'),
            //               style: interRegular.copyWith(
            //                   fontSize: Dimensions.fontSizeDefault,
            //                   fontWeight: FontWeight.w600,
            //                   color: AppColors.white,
            //                   height: 0),
            //             );
            //           }),
            //         ],
            //       )
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

                    ///Search bar
                    // SizedBox(
                    //   height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                    //   child: TextField(
                    //     cursorColor: ThemeManager.grey,
                    //     onChanged: (value) {
                    //       setState(() {
                    //         query = value;
                    //         if (query.length >= 3) {
                    //           searchCategory(query);
                    //         }
                    //         if (query.isEmpty) {
                    //           store.onTopicApiCall(widget.subcatId);
                    //         }
                    //       });
                    //     },
                    //     style: interRegular.copyWith(
                    //         fontSize: Dimensions.fontSizeDefault,
                    //         color: ThemeManager.black,
                    //         fontWeight: FontWeight.w500,
                    //         fontFamily: 'DM Sans'),
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
                    //           borderRadius: BorderRadius.circular(
                    //               Dimensions.RADIUS_DEFAULT),
                    //           borderSide: BorderSide(
                    //             color: ThemeManager.mainBorder,
                    //           )),
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
                        builder: (_) {
                          // if (selectedFilter == "All") {
                          //   filteredVideos = store.videotopic;
                          // }else if (selectedFilter == "Completed") {
                          //   filteredVideos = store.videotopic
                          //       .where((video) =>
                          //   video?.isCompleted != null &&
                          //       (video?.isCompleted??false) == true)
                          //       .toList();
                          // }else if (selectedFilter == "In Progress") {
                          //   filteredVideos = store.videotopic
                          //       .where((video) =>
                          //   (video?.pausedTime?.isNotEmpty??false))
                          //       .toList();
                          // }else if (selectedFilter == "Not Started") {
                          //   filteredVideos = store.videotopic
                          //       .where((video) =>
                          //   (video?.isCompleted == null || (video?.isCompleted ?? false) == false) &&
                          //       !(video?.pausedTime?.isNotEmpty ?? false))
                          //       .toList();
                          // }
                          filteredVideos = store.videotopic;
                          _filterVideos();
                          if (store.isLoading) {
                            return const SkeletonList(
                                count: 5, itemHeight: 96);
                          }
                          if (store.videotopic.isEmpty) {
                            return const EmptyState(
                              icon: Icons.play_circle_outline_rounded,
                              title: 'No lectures yet',
                              subtitle:
                                  'New lectures will appear here as soon as they’re published.',
                            );
                          }
                          if (store.isConnected) {
                            return RefreshIndicator(
                                color: AppTokens.accent(context),
                                backgroundColor: AppTokens.surface(context),
                                onRefresh: () => _getVideoList(),
                                child: homeStore.isLoading
                                    ? const Center(child: CircularProgressIndicator())
                                    : (homeStore.globalSearchList.isNotEmpty && query.isNotEmpty)
                                        ? (Platform.isWindows || Platform.isMacOS)
                                            ? CustomDynamicHeightGridView(
                                                crossAxisCount: 3,
                                                mainAxisSpacing: 10,
                                                itemCount: homeStore.globalSearchList.length,
                                                shrinkWrap: true,
                                                physics: const BouncingScrollPhysics(),
                                                builder: (BuildContext context, int index) {
                                                  return _buildItem(context, index);
                                                },
                                              )
                                            : ListView.builder(
                                                itemCount: homeStore.globalSearchList.length,
                                                shrinkWrap: true,
                                                padding: EdgeInsets.zero,
                                                physics: const BouncingScrollPhysics(),
                                                itemBuilder: (BuildContext context, int index) {
                                                  return _buildItem(context, index);
                                                },
                                              )
                                        : (Platform.isWindows || Platform.isMacOS)
                                            ? CustomDynamicHeightGridView(
                                                crossAxisCount: 3,
                                                mainAxisSpacing: 10,
                                                itemCount: filteredVideos.length,
                                                shrinkWrap: true,
                                                physics: const AlwaysScrollableScrollPhysics(),
                                                builder: (BuildContext context, int index) {
                                                  if (filteredVideos.isEmpty) {
                                                    return const Center(
                                                      child: Text("No videos available"),
                                                    );
                                                  }

                                                  // Resolve via the same helper _downloadVideo uses so
                                                  // the badge status and the download action key off
                                                  // the identical titleId — otherwise the UI and the
                                                  // service disagree for videos where `id` is null.
                                                  final titleId = _resolveTitleId(filteredVideos[index]);
                                                  // debugPrint("downId$titleId");
                                                  return Observer(
                                                    builder: (_) {
                                                      final isDownloaded =
                                                          store.isVideoDownloadedCached(titleId);
                                                      return _buildItem1(
                                                          context, filteredVideos[index], index,
                                                          isDownloaded: isDownloaded);
                                                    },
                                                  );
                                                },
                                              )
                                            : ListView.builder(
                                                itemCount: filteredVideos.length,
                                                shrinkWrap: true,
                                                padding: EdgeInsets.zero,
                                                physics: const AlwaysScrollableScrollPhysics(),
                                                itemBuilder: (BuildContext context, int index) {
                                                  // debugPrint('filterdvideos$filteredVideos');
                                                  if (filteredVideos.isEmpty) {
                                                    return const Center(
                                                      child: Text("No videos available"),
                                                    );
                                                  }

                                                  final titleId = _resolveTitleId(filteredVideos[index]);
                                                  return Observer(
                                                    builder: (_) {
                                                      final isDownloaded =
                                                          store.isVideoDownloadedCached(titleId);
                                                      return _buildItem1(
                                                          context, filteredVideos[index], index,
                                                          isDownloaded: isDownloaded);
                                                    },
                                                  );
                                                },
                                              ));
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
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final store = Provider.of<HomeStore>(context, listen: false);
    GlobalSearchDataModel? videoTopic = store.globalSearchList[index];
    String? categoryName = videoTopic?.categoryName;
    String? subcategoryName = videoTopic?.subcategoryName;
    String? topicName = videoTopic?.topicName;
    String? title = videoTopic?.title;

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
            Navigator.of(context).pushNamed(
              Routes.videoSubjectDetail,
              arguments: {
                "subject": categoryName,
                "vid": videoTopic?.id,
              },
            );
          } else if (type == "Subcategory") {
            Navigator.of(context).pushNamed(
              Routes.VideoTopicCategory,
              arguments: {
                "chapter": subcategoryName,
                "subcatId": videoTopic?.id,
              },
            );
          } else if (type == "Topic") {
            Navigator.of(context).pushNamed(
              Routes.videoChapterDetail,
              arguments: {
                "chapter": topicName,
                "subject": videoTopic?.subName,
                "subcatId": videoTopic?.id,
              },
            );
          } else if (type == "Content") {
            Navigator.of(context).pushNamed(
              Routes.videoPlayDetail,
              arguments: {
                "topicId": videoTopic?.id,
                'title': videoTopic?.title ?? '',
                'topic_name': videoTopic?.topicName ?? '',
                'category_name': videoTopic?.categoryName ?? '',
                'subcategory_name': videoTopic?.subcategoryName ?? '',
                'isDownloaded': _videoStore.isVideoDownloadedCached(videoTopic?.id?.toString() ?? ''),
                'titleId': videoTopic?.id,
                'categoryId': videoTopic?.categoryId,
                'subcategoryId': videoTopic?.subcategoryId,
              },
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(Dimensions.PADDING_SIZE_DEFAULT),
          decoration: BoxDecoration(
            color: ThemeManager.white,
            borderRadius: BorderRadius.circular(9.6),
          ),
          child: Row(
            children: [
              Container(
                height: Dimensions.PADDING_SIZE_LARGE * 3.2,
                width: Dimensions.PADDING_SIZE_LARGE * 3.2,
                padding: const EdgeInsets.all(Dimensions.PADDING_SIZE_DEFAULT),
                decoration: BoxDecoration(
                  color: ThemeManager.continueContainerTrans,
                  borderRadius: BorderRadius.circular(14.4),
                ),
                child: SvgPicture.asset(
                  "assets/image/videochapter.svg",
                  color: ThemeManager.currentTheme == AppTheme.Dark ? AppColors.white : null,
                ),
              ),
              const SizedBox(
                width: Dimensions.PADDING_SIZE_DEFAULT,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.56,
                      child: Text(
                        displayText,
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
                        videoTopic?.description ?? "",
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem1(BuildContext context, VideoTopicModel? videoTopic, int index,
      {required bool isDownloaded}) {
    final store = Provider.of<VideoCategoryStore>(context, listen: false);
    final durationInSeconds = videoTopic?.duration ?? 0;
    final pausedInSeconds = parseTimeToSeconds(videoTopic?.pausedTime ?? "0");
    final remainingSeconds = (durationInSeconds - (pausedInSeconds ?? 0)).clamp(0, durationInSeconds);

    if (query.isNotEmpty && (!videoTopic!.title!.toLowerCase().contains(query.toLowerCase()))) {
      return Container();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.PADDING_SIZE_DEFAULT),
      child: InkWell(
        onTap: () async {
          if (videoTopic?.isAccess == true) {
            Navigator.of(context).pushNamed(
              Routes.videoPlayDetail,
              arguments: {
                "topicId": videoTopic?.topicId,
                "isCompleted": videoTopic?.isCompleted,
                'title': videoTopic?.title ?? '',
                'isDownloaded': isDownloaded,
                // Use the same fallback (id → sId → topicId) that the badge
                // observer and download enqueue both use; otherwise the
                // player opens with a "null" titleId and fails its offline
                // lookup / defeats the download-cache check.
                'titleId': _resolveTitleId(videoTopic),
                'contentId': videoTopic?.sId,
                'pauseTime': videoTopic?.pausedTime,
                'categoryId': videoTopic?.category_id,
                'subcategoryId': videoTopic?.subcategory_id,
                'isBookmark': videoTopic?.isBookmark,
                'pdfId': videoTopic?.pdfId,
                'pdfContents': videoTopic?.pdfContents,
                'videoPlayUrl': videoTopic?.videoLink,
                'videoQuality': videoTopic?.videoFiles,
                'downloadVideoData': videoTopic?.downloadVideo,
                'annotationData': videoTopic?.annotationData.toString(),
                'videoThumbnail': videoTopic?.thumbnail,
                'hlsLink': videoTopic?.hlsLink
              },
            ).then((value) => _getVideoList());
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
                          _getVideoList();
                        },
                        planId: videoTopic?.plan_id ?? "",
                        day: int.parse(videoTopic?.day ?? "0"),
                        isFree: videoTopic!.isfreeTrail!,
                      ),
                    ],
                  );
                },
              );
            } else {
              showModalBottomSheet<void>(
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                clipBehavior: Clip.antiAliasWithSaveLayer,
                context: context,
                builder: (BuildContext context) {
                  return NoAccessBottomSheet(
                    onTap: () {
                      _getVideoList();
                    },
                    planId: videoTopic?.plan_id ?? "",
                    day: int.parse(videoTopic?.day ?? "0"),
                    isFree: videoTopic!.isfreeTrail!,
                  );
                },
              );
            }
          }
        },
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(Dimensions.PADDING_SIZE_DEFAULT),
              decoration: BoxDecoration(
                color: ThemeManager.white,
                border: Border.all(color: ThemeManager.mainBorder),
                borderRadius: BorderRadius.circular(9.6),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: Dimensions.PADDING_SIZE_LARGE * 3.2,
                        width: Dimensions.PADDING_SIZE_LARGE * 4.6,
                        // padding: const EdgeInsets.all(Dimensions.PADDING_SIZE_LARGE),
                        decoration: BoxDecoration(
                          color: ThemeManager.continueContainerTrans,
                          borderRadius: BorderRadius.circular(10),
                          // border: ProgressBorder.all(
                          //   width: 2,
                          //   color: ThemeManager.greenBorder,
                          //   progress: videoTopic?.isCompleted ?? true ? 1 : 0,
                          // ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: (videoTopic?.thumbnail != null && videoTopic!.thumbnail!.isNotEmpty)
                              ? Image.network(
                                  videoTopic.thumbnail ?? "",
                                  // "https://i.vimeocdn.com/video/1943788748-7650fc712ef95631e35e4bf5b5062ed4dd2d79fcf4b95733a1e0ca4bb53b46c3-d_200x150?r=pad",
                                  fit: BoxFit.fill,
                                )
                              : SvgPicture.asset(
                                  "assets/image/videochapter.svg",
                                  color: ThemeManager.currentTheme == AppTheme.Dark ? AppColors.white : null,
                                ),
                        ),
                      ),
                      const SizedBox(width: Dimensions.PADDING_SIZE_DEFAULT),
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
                                    videoTopic?.title ?? "",
                                    maxLines: 3,
                                    overflow: TextOverflow.visible,
                                    style: interSemiBold.copyWith(
                                      fontSize: Dimensions.fontSizeDefault,
                                      fontWeight: FontWeight.w600,
                                      color: ThemeManager.black,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    _putBookMarkApiCall(videoTopic?.sId);
                                    setState(() {
                                      isBookmarkedDone?[index] = !isBookmarkedDone![index];
                                      filteredVideos[index]?.isBookmark = isBookmarkedDone?[index];
                                    });
                                  },
                                  child: isBookmarkedDone?[index] == true
                                      ? SvgPicture.asset(
                                          "assets/image/bookmarkfill_video_icon.svg",
                                          height: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                                          width: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                                        )
                                      : SvgPicture.asset(
                                          "assets/image/bookmark_video_icon.svg",
                                          height: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                                          width: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                                        ),
                                )
                              ],
                            ),
                            Text(
                              formatTime(videoTopic?.duration ?? 0),
                              style: interRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                fontWeight: FontWeight.w400,
                                overflow: TextOverflow.ellipsis,
                                color: ThemeManager.black.withOpacity(0.5),
                              ),
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
                      videoTopic?.isCompleted == true
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
                          : videoTopic?.pausedTime?.isNotEmpty ?? false
                              ? Row(
                                  children: [
                                    SvgPicture.asset(
                                      "assets/image/inprogress_status_icon.svg",
                                      height: Dimensions.PADDING_SIZE_LARGE,
                                      width: Dimensions.PADDING_SIZE_LARGE,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Paused | ${formatTime(remainingSeconds)} left",
                                      style: interRegular.copyWith(
                                        fontSize: Dimensions.fontSizeExtraSmall,
                                        color: ThemeManager.black.withOpacity(0.6),
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
                                        fontSize: Dimensions.fontSizeExtraSmall,
                                        color: ThemeManager.black.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                      Observer(builder: (context) {
                        // Same identifier fallback chain as the outer list
                        // Observer — otherwise videos with a null numeric id
                        // never flip to "Downloading N%" because the in-
                        // progress check reads an empty string key.
                        final progressId = _resolveTitleId(videoTopic);
                        final isDownloading = store.isDownloading(progressId);
                        final progress = store.getDownloadProgress(progressId);

                        return InkWell(
                          onTap: () async {
                            if (!isDownloading) {
                              await initializePlayerWithAPIResponse(filesToMapList(videoTopic?.videoFiles));
                              await initializeDownload(downloadToMapList(videoTopic?.downloadVideo));
                              _showQualityOptions(store, videoTopic, isDownloaded);
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              isDownloading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        value: progress / 100,
                                        strokeWidth: 3.0,
                                        valueColor: AlwaysStoppedAnimation<Color>(ThemeManager.primaryColor),
                                      ),
                                    )
                                  : Icon(
                                      isDownloaded! ? Icons.check_circle : Icons.download_for_offline,
                                      color: isDownloaded ? Colors.green : ThemeManager.blueFinal,
                                    ),
                              const SizedBox(width: 4),
                              Text(
                                isDownloaded!
                                    ? "Downloaded"
                                    : isDownloading
                                        ? "Downloading $progress%"
                                        : "Download",
                                style: interRegular.copyWith(
                                  fontSize: Dimensions.fontSizeExtraSmall,
                                  fontWeight: FontWeight.w500,
                                  color: isDownloaded
                                      ? Colors.green
                                      : isDownloading
                                          ? ThemeManager.primaryColor
                                          : ThemeManager.blackColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      })
                    ],
                  ),
                ],
              ),
            ),
            if (videoTopic?.isAccess == false)
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
    );
  }

  int? parseTimeToSeconds(String time) {
    final parts = time.split(":").map(int.tryParse).toList();
    if (parts.length == 3) {
      return (parts[0]! * 3600) + (parts[1]! * 60) + parts[2]!;
    } else if (parts.length == 2) {
      return (parts[0]! * 60) + parts[1]!;
    } else if (parts.length == 1) {
      return parts[0];
    }
    return 0;
  }

  String formatTimeToHHMMSS(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    final hoursStr = hours.toString().padLeft(2, '0');
    final minutesStr = minutes.toString().padLeft(2, '0');
    final secondsStr = remainingSeconds.toString().padLeft(2, '0');

    return "$hoursStr:$minutesStr:$secondsStr";
  }

  /// Resolve the stable titleId used as a key across DB + download queue + UI
  /// observers for a given [VideoTopicModel].
  ///
  /// Priority:
  ///   1. `id` — legacy numeric PK. Populated on older API responses. Using
  ///      it first preserves backward compatibility with existing DB rows.
  ///   2. `sId` — Mongo `_id` string. Always populated on newer responses.
  ///   3. `topicId` — topic-level fallback (rare).
  ///
  /// Returns empty string when NONE are usable, and callers MUST treat empty
  /// as a hard fail (the store's `_isValidTitleId` also rejects empty/'null'
  /// to guard against keyspace collisions that leaked "downloaded" state
  /// across sibling videos).
  String _resolveTitleId(VideoTopicModel? v) {
    if (v == null) return '';
    final intId = v.id;
    if (intId != null) return intId.toString();
    final mongoId = v.sId;
    if (mongoId != null && mongoId.isNotEmpty) return mongoId;
    final topic = v.topicId;
    if (topic != null && topic.isNotEmpty) return topic;
    return '';
  }

  Future<bool> _checkIfVideoDownloaded(String titleId) async {
    // debugPrint("checktitleID$titleId");
    final dbHelper = DbHelper();
    final downloadedVideo = await dbHelper.getVideoByTitleId(titleId);
    // debugPrint("downloadedVideo$downloadedVideo");
    if (downloadedVideo != null) {
      final videoPath = downloadedVideo.videoPath;
      final file = File(videoPath!);
      if (await file.exists()) {
        // debugPrint("downExists");
        return true;
      } else {
        // Clean up the database entry if the file is missing
        await dbHelper.deleteVideoByTitleId(titleId);
      }
    }
    return false;
  }

  void _filterVideos() async {
    final store = Provider.of<VideoCategoryStore>(context, listen: false);
    List<VideoTopicModel?> filtered = [];
    if (selectedFilter == "All") {
      filtered = store.videotopic;
    } else if (selectedFilter == "Completed") {
      filtered = store.videotopic
          .where((video) => video?.isCompleted != null && (video?.isCompleted ?? false) == true)
          .toList();
    } else if (selectedFilter == "In Progress") {
      filtered = store.videotopic.where((video) => (video?.pausedTime?.isNotEmpty ?? false)).toList();
    } else if (selectedFilter == "Not Started") {
      filtered = store.videotopic
          .where((video) =>
              (video?.isCompleted == null || (video?.isCompleted ?? false) == false) &&
              !(video?.pausedTime?.isNotEmpty ?? false))
          .toList();
    } else if (selectedFilter == "Offline Videos") {
      filtered = offlineVideos;
    } else if (selectedFilter == "Bookmarked Videos") {
      filtered = store.videotopic.where((video) => video?.isBookmark == true).toList();
    }
    // Sort once here: incomplete videos first, completed at bottom
    filtered.sort((a, b) {
      if (a?.isCompleted == b?.isCompleted) return 0;
      return (a?.isCompleted ?? false) ? 1 : -1;
    });
    filteredVideos = filtered;
    isBookmarkedDone = filtered.map((topic) => topic?.isBookmark ?? false).toList();
    // debugPrint('filtervd${filteredVideos.length}');
    // setState(() {});
  }

  Future<void> _filterOfflineVideos() async {
    if (!mounted) return;
    final store = Provider.of<VideoCategoryStore>(context, listen: false);
    List<VideoTopicModel?> downloadedVideos = [];
    for (var video in store.videotopic) {
      final titleId = _resolveTitleId(video);
      if (titleId.isEmpty) continue;
      final isDownloaded = await _checkIfVideoDownloaded(titleId);
      if (isDownloaded) {
        downloadedVideos.add(video);
      }
    }
    offlineVideos = downloadedVideos;
    debugPrint('ofvd${offlineVideos.length}');
  }

  String formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return "$hours hr $minutes min";
    } else if (minutes > 0) {
      return "$minutes min $remainingSeconds s";
    } else {
      return "${remainingSeconds}s";
    }
  }

  void _showQualityOptions(VideoCategoryStore store, VideoTopicModel? videoTopic, bool isDownloaded) {
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
                  padding: const EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
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
                                  // CRITICAL: also sync the URL — otherwise
                                  // selecting a different quality still
                                  // downloads the seeded default.
                                  downloadUrl = _downloadUrls[quality] ?? downloadUrl;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? ThemeManager.blueFinal : material.Colors.transparent,
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
                                    vertical: Dimensions.PADDING_SIZE_EXTRA_SMALL,
                                  ),
                                  child: Text(
                                    quality,
                                    style: interRegular.copyWith(
                                      fontSize: isSelected
                                          ? Dimensions.fontSizeLarge
                                          : Dimensions.fontSizeDefaultLarge,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? ThemeManager.white : ThemeManager.black,
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
                  _downloadVideo(store, downloadUrl, downloadQuality, videoTopic);
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
              if (isDownloaded)
                Padding(
                  padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
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
                                      fontSize: Dimensions.fontSizeDefault,
                                      fontWeight: FontWeight.w600,
                                      color: ThemeManager.blackColor,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    // Use the resolver so deletion matches
                                    // the key the download was written with.
                                    final tid = _resolveTitleId(videoTopic);
                                    if (tid.isEmpty) {
                                      Navigator.pop(context);
                                      return;
                                    }
                                    await dbHelper.deleteVideoByTitleId(tid);
                                    // Evict cached decrypted file too.
                                    await OfflineEncryptor.evictCache(tid);
                                    _videoStore.markNotDownloaded(tid);
                                    BottomToast.showBottomToastOverlay(
                                      context: context,
                                      errorMessage: "Offline downloaded video has been deleted successfully!",
                                      backgroundColor: Theme.of(context).primaryColor,
                                    );
                                    Navigator.pop(context);
                                    Navigator.pop(context);
                                    Navigator.pop(context);
                                    if (mounted) setState(() {});
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
          );
        },
      );
    } else {
      showModalBottomSheet<void>(
        isScrollControlled: true,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        context: context,
        backgroundColor: ThemeManager.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
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
                      // ListView(
                      //   shrinkWrap: true,
                      //   children: _qualityAndSize.entries.map((entry) {
                      //     final quality = entry.key;
                      //     final size = entry.value;
                      //     return RadioListTile<String>(
                      //       activeColor: ThemeManager.primaryColor,
                      //       value: quality,
                      //       groupValue: downloadQuality,
                      //       title: Text("$quality - $size",
                      //         style: interRegular.copyWith(
                      //           fontSize: Dimensions.fontSizeDefault,
                      //           fontWeight: FontWeight.w600,
                      //           color: ThemeManager.blackColor,
                      //         ),),
                      //       onChanged: (value) {
                      //         if (value != null) {
                      //           setState(() {
                      //             downloadQuality = value;
                      //           });
                      //         }
                      //       },
                      //     );
                      //   }).toList(),
                      // ),
                      material.Padding(
                        padding: const EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
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
                                        // Sync URL to the selected quality so
                                        // the Download button below enqueues
                                        // the right rendition.
                                        downloadUrl = _downloadUrls[quality] ?? downloadUrl;
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected ? ThemeManager.blueFinal : material.Colors.transparent,
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
                                          vertical: Dimensions.PADDING_SIZE_EXTRA_SMALL,
                                        ),
                                        child: Text(
                                          quality,
                                          style: interRegular.copyWith(
                                            fontSize: isSelected
                                                ? Dimensions.fontSizeLarge
                                                : Dimensions.fontSizeDefaultLarge,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                            color: isSelected ? ThemeManager.white : ThemeManager.black,
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
                        padding: const EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 30),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _downloadVideo(store, downloadUrl, downloadQuality, videoTopic);
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
                      if (isDownloaded)
                        Padding(
                          padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
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
                                              fontSize: Dimensions.fontSizeDefault,
                                              fontWeight: FontWeight.w600,
                                              color: ThemeManager.blackColor,
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            // Same resolver as enqueue so the
                                            // delete key matches what we wrote.
                                            final tid = _resolveTitleId(videoTopic);
                                            if (tid.isEmpty) {
                                              Navigator.pop(context);
                                              return;
                                            }
                                            await dbHelper.deleteVideoByTitleId(tid);
                                            // Evict cached decrypted file too.
                                            await OfflineEncryptor.evictCache(tid);
                                            store.markNotDownloaded(tid);
                                            BottomToast.showBottomToastOverlay(
                                              context: context,
                                              errorMessage:
                                                  "Offline downloaded video has been deleted successfully!",
                                              backgroundColor: Theme.of(context).primaryColor,
                                            );
                                            Navigator.pop(context);
                                            Navigator.pop(context);
                                            Navigator.pop(context);
                                            if (mounted) setState(() {});
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
                                padding: const EdgeInsets.symmetric(vertical: 14),
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

  Future<void> initializePlayerWithAPIResponse(List<Map<String, dynamic>> apiFiles) async {
    _videoUrls.clear();
    _qualityAndSize.clear();
    for (var file in apiFiles) {
      final rendition = (file["rendition"] ?? "").toString().trim();
      final quality = (file["quality"] ?? "").toString().trim();
      final size = (file["size_short"] ?? "").toString().trim();
      final link = (file["link"] ?? "").toString().trim();
      if (link.isEmpty || rendition.isEmpty) continue;
      _videoUrls[rendition] = link;
      final label = quality.isEmpty ? rendition : "${quality.toUpperCase()} $rendition";
      _qualityAndSize[label] = size.isEmpty ? "" : " $size";
    }
  }

  Future<void> initializeDownload(List<Map<String, dynamic>> apiFiles) async {
    _qualityAndSize.clear();
    _downloadUrls.clear();
    // Reset selection state — otherwise the dialog reopens with a
    // _selectedIndex pointing past the end of a shorter list from a different
    // video, and the wrong row highlights.
    _selectedIndex = 0;
    downloadQuality = "";
    downloadUrl = "";

    // Track which renditions (e.g. "480p", "720p") we've already added so
    // that near-duplicates like "SD 480p" and bare "480p" from the API
    // don't both appear in the quality picker.
    final Set<String> seenRenditions = {};

    for (var file in apiFiles) {
      final rendition = (file["rendition"] ?? "").toString().trim();
      final quality = (file["quality"] ?? "").toString().trim();
      final size = (file["size_short"] ?? "").toString().trim();
      final link = (file["link"] ?? "").toString().trim();
      // Skip entries we can't actually download.
      if (link.isEmpty || rendition.isEmpty) continue;

      // Deduplicate by rendition (e.g. "480p"). The API sometimes returns
      // two entries for the same resolution — one with a quality prefix
      // ("SD 480p") and one without ("480p"). Keep whichever appears first.
      if (seenRenditions.contains(rendition)) continue;
      seenRenditions.add(rendition);

      // Build a human-readable label. If quality is blank (e.g. just "480p"
      // with no SD/HD prefix) we don't want a leading space — it rendered as
      // " 480p" and looked like a duplicate entry next to "SD 480p".
      final label = quality.isEmpty ? rendition : "${quality.toUpperCase()} $rendition";

      _qualityAndSize[label] = size.isEmpty ? "" : " $size";
      _downloadUrls[label] = link;
    }

    // Seed defaults from the first available option so that tapping Download
    // without changing selection still uses a valid URL keyed to that label.
    if (_qualityAndSize.isNotEmpty) {
      final firstLabel = _qualityAndSize.keys.first;
      downloadQuality = firstLabel;
      downloadUrl = _downloadUrls[firstLabel] ?? "";
    }
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

  /// Enqueue a single-video download through the global [DownloadService].
  ///
  /// Historical note: this function used to open its own `http.Request` and
  /// drive `response.stream.listen` to a temp file, then encrypt inline and
  /// save to the DB — all while the widget was potentially being disposed.
  /// That caused two classes of bugs:
  ///
  ///   1. Crashes on back-navigation — the `onDone` callback reached for
  ///      `Provider.of<HomeStore>(context, listen: false)` (for key refresh)
  ///      and `setState()` long after the widget had been unmounted, and the
  ///      file sink was sometimes closed twice via `cancelOnError` + manual.
  ///   2. Memory pressure on multi-download — every tap spawned a fresh
  ///      concurrent HTTP stream AND a fresh concurrent AES encryption, with
  ///      no queue. On a 4-video download burst we held 4× the full-file bytes
  ///      in RAM during encryption and routinely OOMed on mid-range devices.
  ///
  /// The fix is to delegate to [DownloadService] (a proper serial queue with
  /// retry/resume/teardown), and let the store's stream bridge keep the UI
  /// state in sync. This function is now fire-and-forget from the caller's
  /// perspective — all post-enqueue async work happens inside the service,
  /// which outlives this widget.
  Future<void> _downloadVideo(
      VideoCategoryStore store, String url, String quality, VideoTopicModel? videoTopic) async {
    // ── Input validation ─────────────────────────────────────────────────
    // The server has two identifier schemes on a VideoTopicModel: `id` (an
    // int from the legacy numeric PK) and `sId` (the Mongo `_id` string).
    // Newer API payloads only populate `sId` — `id` comes back null — so we
    // were refusing to download those and surfacing "Cannot download: missing
    // video identifier." to the user even though a perfectly valid `sId` was
    // sitting right there. Fall back through the chain.
    final titleId = _resolveTitleId(videoTopic);
    if (titleId.isEmpty) {
      debugPrint('[DL] aborted — no usable identifier on videoTopic (id/sId/topicId all empty)');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot download: missing video identifier.'),
          ),
        );
      }
      return;
    }
    if (url.isEmpty) {
      debugPrint('[DL] aborted — empty url for $titleId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No download URL available.')),
        );
      }
      return;
    }

    // Idempotency guards — if already downloading or already on disk, bail.
    if (store.isDownloading(titleId)) {
      debugPrint('[DL] $titleId already downloading — ignoring tap');
      return;
    }
    if (store.isVideoDownloadedCached(titleId)) {
      debugPrint('[DL] $titleId already downloaded — ignoring tap');
      return;
    }

    // ── Preflight the encryption key ─────────────────────────────────────
    // DownloadService will fail the task if the key is missing at encrypt
    // time, but the error would only surface after the full download. We
    // check the key BEFORE enqueuing so a misconfigured device shows the
    // error instantly instead of 300 MB later. This is the only await before
    // enqueue, and we gate further work behind `mounted` afterwards.
    List<int>? key = await SecureKeys.loadKey('global');
    if (key == null || key.length != 32) {
      if (!mounted) return;
      try {
        final homeStore = Provider.of<HomeStore>(context, listen: false);
        await homeStore.onGetUserDetailsCall(context);
        key = await SecureKeys.loadKey('global');
      } catch (e) {
        debugPrint('[DL] key refresh failed: $e');
      }
    }
    if (key == null || key.length != 32) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not secure video. Please refresh your profile and try again.'),
          ),
        );
      }
      return;
    }

    // ── Optimistic store update ─────────────────────────────────────────
    // The service's stream bridge will keep this in sync going forward,
    // but we flip the flag immediately so the UI doesn't show a split-second
    // "Download" button between tap and the service's first progress event.
    store.startDownload(titleId);

    // ── Enqueue — service owns queueing, retry, resume, encrypt, DB save ─
    DownloadService.instance.enqueue(
      titleId: titleId,
      url: url,
      quality: quality,
      title: videoTopic?.title ?? '',
      topicId: videoTopic?.topicId ?? '',
      categoryId: videoTopic?.category_id ?? '',
      subCategoryId: videoTopic?.subcategory_id ?? '',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Queued: ${videoTopic?.title ?? "video"}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Notification helpers (_showDownloadProgressNotification,
  // _updateDownloadProgressNotification, _showDownloadNotification) used to
  // live here. They were called from the inline download path that we've
  // since replaced with DownloadService — the service + download_manager_sheet
  // now own all download-progress UI. Methods removed to avoid dead code.

  /// Download all undownloaded videos in the current topic using DownloadService queue.
  Future<void> _downloadAllVideos() async {
    final store = _videoStore;
    final videos = store.videotopic;
    if (videos.isEmpty) return;

    final toDownload = <Map<String, String>>[];

    for (final v in videos) {
      if (v == null) continue;
      // Resolver instead of raw `id` so we pick up sId-only responses too.
      final titleId = _resolveTitleId(v);
      if (titleId.isEmpty) continue;

      // Skip already downloaded or currently in queue
      if (store.isVideoDownloadedCached(titleId)) continue;
      if (DownloadService.instance.isInQueue(titleId)) continue;

      // Pick best download URL — prefer 540p, fallback to first available
      String? url;
      String quality = '540p';

      final downloads = v.downloadVideo;
      if (downloads != null && downloads.isNotEmpty) {
        // Try to find 540p, then 360p, then first available
        final preferred = downloads.firstWhere(
          (d) => d.rendition == '540p',
          orElse: () => downloads.firstWhere(
            (d) => d.rendition == '360p',
            orElse: () => downloads.first,
          ),
        );
        url = preferred.link;
        quality = preferred.rendition ?? '540p';
      }

      // Fallback to hlsLink or videoUrl if no download links
      if (url == null || url.isEmpty) {
        url = v.hlsLink ?? v.videoUrl;
      }

      if (url == null || url.isEmpty) continue;

      toDownload.add({
        'titleId': titleId,
        'url': url,
        'quality': quality,
        'title': v.title ?? 'Video',
        'topicId': v.topicId ?? '',
        'categoryId': v.category_id ?? '',
        'subCategoryId': v.subcategory_id ?? '',
      });
    }

    if (toDownload.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All videos are already downloaded or queued')),
        );
      }
      return;
    }

    // Enqueue all via DownloadService
    DownloadService.instance.enqueueMultiple(toDownload);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${toDownload.length} videos queued for download')),
      );
      // Open download manager so user can see progress
      DownloadManagerSheet.show(context);
    }
  }
}
