import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/helpers/custom_dynamic_height_gridview.dart';
import 'package:shusruta_lms/modules/notes/sharedhelper.dart';
import 'package:shusruta_lms/modules/videolectures/store/video_category_store.dart';

import '../../app/routes.dart';
import '../../helpers/app_skeleton.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/dbhelper.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/empty_state.dart';
import '../../helpers/styles.dart';
import '../../models/video_topic_category_model.dart';
import '../dashboard/models/global_search_model.dart';
import '../dashboard/store/home_store.dart';
import '../widgets/no_internet_connection.dart';
import '../widgets/priority_badge.dart';

class VideoTopicCategoryScreen extends StatefulWidget {
  final String subject;
  final String vid;
  const VideoTopicCategoryScreen({super.key, required this.subject, required this.vid});

  @override
  State<VideoTopicCategoryScreen> createState() => _VideoTopicCategoryScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => VideoTopicCategoryScreen(
        subject: arguments['chapter'],
        vid: arguments['subcatId'],
      ),
    );
  }
}

class _VideoTopicCategoryScreenState extends State<VideoTopicCategoryScreen> {
  String query = '';
  String selectedFilter = "All";
  late List<VideoTopicCategoryModel?> filteredVideos;
  Map<String, int> offlineCounts = {};
  final dbHelper = DbHelper();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    final store = Provider.of<VideoCategoryStore>(context, listen: false);
    store.onTopicCategoryApiCall(widget.vid);
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  Future<void> _fetchOfflineCounts() async {
    final topicIds = filteredVideos.map((video) => video?.sId ?? "").toList();
    final counts = await dbHelper.getOfflineCountsByTopicIds(topicIds);

    if (mounted) {
      setState(() {
        offlineCounts = counts;
      });
    }
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
      "Bookmark Videos"
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
      //             "${store.videotopiccategory.length.toString().padLeft(2,'0')} Topics",
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
            //         child: SvgPicture.asset("assets/image/videotopic.svg"),
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
            //               store.videotopiccategory.length
            //                   .toString()
            //                   .padLeft(2, '0'),
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
                padding: const EdgeInsets.fromLTRB(AppTokens.s24, AppTokens.s8, AppTokens.s24, 0),
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
                    //           store.onTopicCategoryApiCall(widget.vid);
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
                    //     // onFieldSubmitted: (value){
                    //     //   setState(() {
                    //     //     query = value;
                    //     //     if (query.length >= 3) {
                    //     //       searchCategory(query);
                    //     //     }
                    //     //   });
                    //     // },
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
                          filteredVideos = store.videotopiccategory;
                          _fetchOfflineCounts();
                          if (selectedFilter == "All") {
                            filteredVideos = store.videotopiccategory;
                          } else if (selectedFilter == "Completed") {
                            filteredVideos = store.videotopiccategory
                                .where((video) =>
                                    video?.completVideoCount != null && (video?.completVideoCount ?? 0) > 0)
                                .toList();
                          } else if (selectedFilter == "In Progress") {
                            filteredVideos = store.videotopiccategory
                                .where((video) =>
                                    video?.progressCount != null && (video?.progressCount ?? 0) > 0)
                                .toList();
                          } else if (selectedFilter == "Not Started") {
                            filteredVideos = store.videotopiccategory
                                .where((video) => video?.notStart != null && (video?.notStart ?? 0) > 0)
                                .toList();
                          } else if (selectedFilter == "Offline Videos") {
                            filteredVideos = store.videotopiccategory.where((video) {
                              final topicId = video?.sId ?? "";
                              final count = offlineCounts[topicId] ?? 0;
                              return count > 0;
                            }).toList();
                          } else if (selectedFilter == "Bookmark Videos") {
                            filteredVideos = store.videotopiccategory
                                .where((video) =>
                                    video?.bookmarkVideoCount != null && (video?.bookmarkVideoCount ?? 0) > 0)
                                .toList();
                          }

                          if (store.isLoading) {
                            return const SkeletonList(count: 4, itemHeight: 96);
                          }
                          if (store.videotopiccategory.isEmpty) {
                            return const EmptyState(
                              icon: Icons.topic_outlined,
                              title: 'No topics yet',
                              subtitle: 'New topics will appear here as soon as they’re published.',
                            );
                          }
                          return store.isConnected
                              ? homeStore.isLoading
                                  ? const SkeletonList(count: 4, itemHeight: 96)
                                  : (homeStore.globalSearchList.isNotEmpty && query.isNotEmpty)
                                      ? (Platform.isWindows || Platform.isMacOS)
                                          ? CustomDynamicHeightGridView(
                                              itemCount: homeStore.globalSearchList.length,
                                              crossAxisCount: 3,
                                              mainAxisSpacing: 10,
                                              builder: (BuildContext context, int index) {
                                                return SearchItemWidget(
                                                    videoSubcat: homeStore.globalSearchList[index]);
                                              },
                                            )
                                          : ListView.builder(
                                              itemCount: homeStore.globalSearchList.length,
                                              shrinkWrap: true,
                                              padding: EdgeInsets.zero,
                                              physics: const BouncingScrollPhysics(),
                                              itemBuilder: (BuildContext context, int index) {
                                                return SearchItemWidget(
                                                    videoSubcat: homeStore.globalSearchList[index]);
                                              },
                                            )
                                      : (Platform.isWindows || Platform.isMacOS)
                                          ? CustomDynamicHeightGridView(
                                              crossAxisCount: 3,
                                              mainAxisSpacing: 10,
                                              itemCount: filteredVideos.length,
                                              shrinkWrap: true,
                                              physics: const BouncingScrollPhysics(),
                                              builder: (BuildContext context, int index) {
                                                final video = filteredVideos[index];
                                                final topicId = video?.sId ?? "";
                                                final offlineCount = offlineCounts[topicId] ?? 0;
                                                return _buildItem(
                                                    context, filteredVideos[index], index, offlineCount);
                                              },
                                            )
                                          : ListView.builder(
                                              itemCount: filteredVideos.length,
                                              shrinkWrap: true,
                                              padding: EdgeInsets.zero,
                                              physics: const BouncingScrollPhysics(),
                                              itemBuilder: (BuildContext context, int index) {
                                                final video = filteredVideos[index];
                                                final topicId = video?.sId ?? "";
                                                final offlineCount = offlineCounts[topicId] ?? 0;
                                                return _buildItem(
                                                    context, filteredVideos[index], index, offlineCount);
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
      ),
    );
  }

  Widget _buildItem(BuildContext context, VideoTopicCategoryModel? videoSubCat, int index, int offlineCount) {
    final store = Provider.of<VideoCategoryStore>(context, listen: false);
    // VideoTopicCategoryModel? videoSubCat = store.videotopiccategory[index];
    int completeVideoCount = videoSubCat?.completVideoCount ?? 0;
    int videoCount = videoSubCat?.videoCount ?? 0;
    double? progressCount = videoCount > 0 ? completeVideoCount / videoCount : 0;
    String indexCount = (index + 1).toString().padLeft(2, '0');
    String alphabeticalChar = String.fromCharCode('A'.codeUnitAt(0) + index);

    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.PADDING_SIZE_SMALL),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(Routes.videoChapterDetail, arguments: {
            "chapter": videoSubCat?.topicName,
            "subject": widget.subject,
            "subcatId": videoSubCat?.sId,
          }).then((value) {
            store.onTopicCategoryApiCall(widget.vid);
          });
        },
        child: Container(
          padding: const EdgeInsets.all(Dimensions.PADDING_SIZE_DEFAULT),
          decoration: BoxDecoration(
            color: ThemeManager.white,
            border: Border.all(color: ThemeManager.mainBorder),
            borderRadius: BorderRadius.circular(9.6),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    height: Dimensions.PADDING_SIZE_LARGE * 3.4,
                    width: Dimensions.PADDING_SIZE_LARGE * 3.4,
                    padding: const EdgeInsets.all(Dimensions.PADDING_SIZE_DEFAULT),
                    decoration: BoxDecoration(
                      color: ThemeManager.continueContainerTrans,
                      borderRadius: BorderRadius.circular(14.4),
                      // border: ProgressBorder.all(
                      //   width: 2,
                      //   color: ThemeManager.greenBorder,
                      //   progress: progressCount,
                      // ),
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
                                videoSubCat?.topicName.toString() ?? "",
                                maxLines: 3,
                                overflow: TextOverflow.visible,
                                style: interSemiBold.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  fontWeight: FontWeight.w600,
                                  color: ThemeManager.black,
                                ),
                              ),
                            ),
                            (videoSubCat?.videoCount != null)
                                ? Text(
                                    "${videoSubCat?.videoCount} Videos",
                                    style: interSemiBold.copyWith(
                                      fontSize: Dimensions.fontSizeExtraSmall,
                                      fontWeight: FontWeight.w500,
                                      color: ThemeManager.black.withOpacity(0.5),
                                    ),
                                  )
                                : const SizedBox(),
                          ],
                        ),
                        const SizedBox(
                          height: Dimensions.PADDING_SIZE_EXTRA_SMALL,
                        ),
                        Text(
                          videoSubCat?.description ?? "",
                          style: interRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            fontWeight: FontWeight.w500,
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        "assets/image/completed_status_icon.svg",
                        height: Dimensions.PADDING_SIZE_LARGE,
                        width: Dimensions.PADDING_SIZE_LARGE,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${videoSubCat?.completVideoCount.toString() ?? "0"} Completed",
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
                        "${videoSubCat?.progressCount.toString() ?? "0"} In Progress",
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
                        "${videoSubCat?.notStart.toString() ?? "0"} Not Started",
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
                  if ((videoSubCat?.bookmarkVideoCount ?? 0) > 0)
                    Row(
                      children: [
                        SvgPicture.asset(
                          "assets/image/bookmark_status_icon.svg",
                          height: Dimensions.PADDING_SIZE_LARGE,
                          width: Dimensions.PADDING_SIZE_LARGE,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${videoSubCat?.bookmarkVideoCount.toString() ?? "0"} Bookmarked",
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
              videoSubCat?.priorityLabel != null ? const Divider() : SizedBox.shrink(),
              Center(
                child: PriorityBadge(
                  priorityLabel: videoSubCat?.priorityLabel,
                  priorityColor: videoSubCat?.priorityColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchItemWidget extends StatelessWidget {
  final GlobalSearchDataModel? videoSubcat;

  const SearchItemWidget({super.key, this.videoSubcat});

  @override
  Widget build(BuildContext context) {
    String? categoryName = videoSubcat?.categoryName;
    String? subcategoryName = videoSubcat?.subcategoryName;
    String? topicName = videoSubcat?.topicName;
    String? title = videoSubcat?.title;

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
            Navigator.of(context).pushNamed(Routes.videoSubjectDetail,
                arguments: {"subject": categoryName, "vid": videoSubcat?.id});
          } else if (type == "Subcategory") {
            Navigator.of(context).pushNamed(Routes.VideoTopicCategory,
                arguments: {"chapter": subcategoryName, "subcatId": videoSubcat?.id});
          } else if (type == "Topic") {
            Navigator.of(context).pushNamed(Routes.videoChapterDetail, arguments: {
              "chapter": topicName,
              "subject": videoSubcat?.subName,
              "subcatId": videoSubcat?.id
            });
          } else if (type == "Content") {
            Navigator.of(context).pushNamed(Routes.videoPlayDetail, arguments: {
              "topicId": videoSubcat?.id,
              "videoTopicId": videoSubcat?.topicId,
              // "topicId": videoSubcat?.topicId,
              "isCompleted": false,
              'title': videoSubcat?.title ?? '',
              'isDownloaded': false,
              'titleId': videoSubcat?.id,
              'contentId': videoSubcat?.id,
              // 'pauseTime': videoCat?.pausedTime,
              'categoryId': videoSubcat?.categoryId,
              'subcategoryId': videoSubcat?.subcategoryId,
              'isBookmark': videoSubcat?.isBookmark,
              'pdfId': videoSubcat?.pdfId,
              'videoPlayUrl': videoSubcat?.videoLink,
              'videoQuality': videoSubcat?.videoFiles,
              'downloadVideoData': videoSubcat?.downloadVideo,
              'annotationData': videoSubcat?.annotation,
              'hlsLink': null // GlobalSearchDataModel doesn't have hlsLink
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.all(Dimensions.PADDING_SIZE_DEFAULT),
          decoration: BoxDecoration(
            color: ThemeManager.white,
            border: Border.all(color: ThemeManager.mainBorder),
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
                  // border: ProgressBorder.all(
                  //   width: 2,
                  //   color: ThemeManager.greenBorder,
                  //   progress: 0.55,
                  // ),
                ),
                child: SvgPicture.asset(
                  "assets/image/book-open2.svg",
                  color: ThemeManager.currentTheme == AppTheme.Dark ? AppColors.white : null,
                ),
              ),
              const SizedBox(width: Dimensions.PADDING_SIZE_SMALL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayText,
                      style: interSemiBold.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        fontWeight: FontWeight.w600,
                        color: ThemeManager.black,
                      ),
                    ),
                    const SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                    Text(
                      videoSubcat?.description ?? "",
                      style: interRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        fontWeight: FontWeight.w400,
                        overflow: TextOverflow.ellipsis,
                        color: ThemeManager.black.withOpacity(0.5),
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_SMALL),
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
}
