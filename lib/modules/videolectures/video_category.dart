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
import '../../models/video_category_model.dart';
import '../../models/video_offline_data_model.dart';
import '../dashboard/models/global_search_model.dart';
import '../dashboard/store/home_store.dart';
import '../subscriptionplans/store/subscription_store.dart';
import '../widgets/no_internet_connection.dart';
import '../widgets/priority_badge.dart';
// import 'package:screen_protector/screen_protector.dart';

// import 'package:screen_protector/screen_protector.dart';

class VideoLecturesScreen extends StatefulWidget {
  const VideoLecturesScreen({super.key});

  @override
  State<VideoLecturesScreen> createState() => _VideoLecturesScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const VideoLecturesScreen(),
    );
  }
}

class _VideoLecturesScreenState extends State<VideoLecturesScreen> {
  String filterValue = '';
  String query = '';
  String selectedFilter = "All";
  late List<VideoCategoryModel?> filteredVideos;
  List<VideoOfflineDataModel>? videosList;
  final FocusNode _focusNode = FocusNode();
  bool isLoading = false;
  Map<String, int> offlineCounts = {};
  final dbHelper = DbHelper();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    _getOfflineData();
    _getSubscribedPlan();
    final store = Provider.of<VideoCategoryStore>(context, listen: false);
    store.onRegisterApiCall(context);
  }

  Future<void> _fetchOfflineCounts() async {
    final categoryIds = filteredVideos.map((video) => video?.id ?? "").toList();
    final counts = await dbHelper.getOfflineCountsByCategoryIds(categoryIds);

    if (mounted) {
      setState(() {
        offlineCounts = counts;
      });
    }
  }

  Future<void> _getSubscribedPlan() async {
    final store = Provider.of<SubscriptionStore>(context, listen: false);
    await store.onGetSubscribedUserPlan();
    // if(store.subscribedPlan.isEmpty){
    //   Navigator.of(context).pushNamed(Routes.subscriptionList);
    // }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  Future<void> searchCategory(String keyword) async {
    // final store = Provider.of<VideoCategoryStore>(context, listen: false);
    // await store.onSearchApiCall(keyword, "video");
    final store = Provider.of<HomeStore>(context, listen: false);
    await store.onGlobalSearchApiCall(keyword, "video");
  }

  Future<void> _getOfflineData() async {
    setState(() {
      isLoading = true;
    });
    videosList = await dbHelper.getAllVideoGroupedByCategoryId();
    setState(() {
      isLoading = false;
    });
  }

  // @override
  // Widget build(BuildContext context) {
  //   final store = Provider.of<VideoCategoryStore>(context);
  //   return Scaffold(
  //     backgroundColor: ThemeManager.white,
  //     appBar: AppBar(
  //       elevation: 0,
  //       automaticallyImplyLeading: false,
  //       backgroundColor: ThemeManager.white,
  //       leading: Padding(
  //         padding: const EdgeInsets.only(left: Dimensions.PADDING_SIZE_SMALL),
  //         child:       IconButton(       highlightColor: Colors.transparent,     hoverColor: Colors.transparent,
  //           icon:  Icon(Icons.arrow_back_ios, color: ThemeManager.iconColor),
  //           onPressed: () {
  //             Navigator.pop(context);
  //           },
  //         ),
  //       ),
  //       actions: [
  //         Padding(
  //           padding: const EdgeInsets.only(right: Dimensions.PADDING_SIZE_SMALL),
  //           child:       IconButton(       highlightColor: Colors.transparent,     hoverColor: Colors.transparent,
  //             icon:  Icon(Icons.home, color: ThemeManager.iconColor),
  //             onPressed: () {
  //               Navigator.of(context).pushNamed(Routes.dashboard);
  //             },
  //           ),
  //         ),
  //       ],
  //       centerTitle: true,
  //       title: Text(
  //         "Video Category",
  //         style: interRegular.copyWith(
  //           fontSize: Dimensions.fontSizeLarge,
  //           fontWeight: FontWeight.w500,
  //           color: ThemeManager.black,
  //         ),
  //       ),
  //     ),
  //     body: Column(
  //       children: [
  //         ///Search and Filter
  //         Padding(
  //           padding: const EdgeInsets.only(
  //             left: Dimensions.PADDING_SIZE_LARGE,
  //             top: Dimensions.PADDING_SIZE_SMALL,
  //             right: Dimensions.PADDING_SIZE_LARGE,
  //             bottom: Dimensions.PADDING_SIZE_LARGE,
  //           ),
  //           child: SizedBox(
  //             height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
  //             child: TextField(
  //               focusNode: _focusNode,
  //               onChanged: (value) {
  //                 setState(() {
  //                   query = value;
  //                   if(query.length >=3){
  //                     searchCategory(query);
  //                   }
  //                   if(query.isEmpty){
  //                     store.onRegisterApiCall(context);
  //                   }
  //                 });
  //               },
  //               cursorColor: Theme.of(context).disabledColor,
  //               decoration: InputDecoration(
  //                 prefixIcon: const Icon(Icons.search),
  //                 prefixIconColor: Theme.of(context).disabledColor,
  //                 hintStyle: interRegular.copyWith(
  //                   fontSize: Dimensions.fontSizeSmall,
  //                   color: Theme.of(context).disabledColor,
  //                   fontWeight: FontWeight.w500,
  //                 ),
  //                 hintText: 'Search',
  //                 fillColor: Colors.white,
  //                 filled: true,
  //                 border: OutlineInputBorder(
  //                     borderRadius: BorderRadius.circular(Dimensions.RADIUS_DEFAULT),
  //                     borderSide: BorderSide(color: Theme.of(context).disabledColor,)
  //                 ),
  //                 focusedBorder: OutlineInputBorder(
  //                   borderRadius: BorderRadius.circular(Dimensions.RADIUS_DEFAULT),
  //                   borderSide: BorderSide(color: Theme.of(context).disabledColor),
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ),
  //
  //         ///video list
  //         Expanded(
  //           child: Observer(
  //             builder: (_){
  //               if(store.isLoading){
  //                 return  Center(child: CircularProgressIndicator(color: ThemeManager.primaryColor,));
  //               }
  //               if (store.videocategory.isEmpty) {
  //                 return const Center(
  //                   child: Padding(
  //                     padding: EdgeInsets.only(left:30, right:30),
  //                     child: Text(
  //                       'Please upgrade your subscription plan to get access',
  //                       textAlign: TextAlign.center,
  //                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //                     ),
  //                   ),
  //                 );
  //               }
  //               return store.isConnected?
  //               (store.searchList.isNotEmpty && query.isNotEmpty)?
  //                 ListView.builder(
  //                     itemCount: store.searchList.length,
  //                     shrinkWrap: true,
  //                     physics: const BouncingScrollPhysics(),
  //                     itemBuilder: (BuildContext context, int index){
  //                       SearchedDataModel? videoCat = store.searchList[index];
  //                       String? categoryName = videoCat?.categoryName;
  //                       String? subcategoryName = videoCat?.subcategoryName;
  //                       String? topicName = videoCat?.topicName;
  //                       String? title = videoCat?.title;
  //
  //                       String displayText = categoryName??subcategoryName??topicName??title??"";
  //                       String type = categoryName != null ? "Category" : subcategoryName != null ? "Subcategory" : topicName != null ? "Topic" : title != null ? "Content" : "";
  //
  //                       return InkWell(
  //                         onTap: (){
  //                           if(type=="Category"){
  //                             Navigator.of(context).pushNamed(Routes.videoSubjectDetail,
  //                                 arguments: {"subject": categoryName,
  //                                   "vid": videoCat?.id});
  //                           }
  //                           else if(type=="Subcategory"){
  //                             Navigator.of(context).pushNamed(Routes.VideoTopicCategory,
  //                                 arguments: {
  //                                   "chapter": subcategoryName,
  //                                   "subcatId": videoCat?.id
  //                                 });
  //                           }else if(type=="Topic"){
  //                             Navigator.of(context).pushNamed(Routes.videoChapterDetail,
  //                                 arguments: {
  //                                   "chapter": topicName,
  //                                   "subject":videoCat?.subName,
  //                                   "subcatId": videoCat?.id
  //                                 });
  //                           }else if(type == "Content"){
  //                             Navigator.of(context).pushNamed(Routes.videoPlayDetail,
  //                                 arguments: {
  //                                   "topicId": videoCat?.id
  //                                 });
  //                           }
  //                         },
  //                         child: Container(
  //                           padding: const EdgeInsets.only(
  //                             left: Dimensions.PADDING_SIZE_LARGE,
  //                             top: Dimensions.PADDING_SIZE_SMALL,
  //                             right: Dimensions.PADDING_SIZE_LARGE,
  //                             // bottom: Dimensions.PADDING_SIZE_LARGE,
  //                           ),
  //                           child: Row(
  //                             children: [
  //                               Expanded(
  //                                 child: Column(
  //                                   crossAxisAlignment: CrossAxisAlignment.start,
  //                                   children: [
  //                                     Row(
  //                                       children: [
  //                                         SvgPicture.asset("assets/image/video_outline_icon.svg",color:ThemeManager.black),
  //                                         const SizedBox(width: Dimensions.PADDING_SIZE_SMALL,),
  //                                         SizedBox(
  //                                           width: MediaQuery.of(context).size.width * 0.68,
  //                                           child: Text(displayText ?? "",
  //                                             style: interSemiBold.copyWith(
  //                                               fontSize: Dimensions.fontSizeDefault,
  //                                               fontWeight: FontWeight.w600,
  //                                               color: ThemeManager.black,
  //                                             ),),
  //                                         )
  //                                       ],
  //                                     ),
  //                                     const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT,),
  //                                     ExpandableText(
  //                                       videoCat?.description ?? "",
  //                                       style: interRegular.copyWith(
  //                                         fontSize: Dimensions.fontSizeSmall,
  //                                         fontWeight: FontWeight.w400,
  //                                         color: Theme.of(context).hintColor,
  //                                       ),
  //                                       expandText: "Show more",
  //                                       maxLines: 2,
  //                                       collapseText: 'Show less',
  //                                       linkColor: Colors.blue,),
  //                                     const SizedBox(height: Dimensions.PADDING_SIZE_SMALL,),
  //                                     Text(type,
  //                                       style: interRegular.copyWith(
  //                                         fontSize: Dimensions.fontSizeSmall,
  //                                         fontWeight: FontWeight.w600,
  //                                         color: ThemeManager.black,
  //                                       ),),
  //                                     const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT,),
  //                                     SizedBox(
  //                                       width: MediaQuery.of(context).size.width,
  //                                       height:1,
  //                                       child: Container(
  //                                         color: const Color(0x0ffe6e4a),
  //                                       ),
  //                                     )
  //                                   ],
  //                                 ),
  //                               ),
  //                               Icon(Icons.arrow_forward_ios,
  //                                 color: Theme.of(context).primaryColor,)
  //                             ],
  //                           ),
  //                         ),
  //                       );
  //                     },
  //                   ):
  //                 ListView.builder(
  //                 itemCount: store.videocategory.length,
  //                 shrinkWrap: true,
  //                 physics: const BouncingScrollPhysics(),
  //                 itemBuilder: (BuildContext context, int index){
  //                   VideoCategoryModel? videoCat = store.videocategory[index];
  //                   String categoryName = videoCat?.category_name ?? "";
  //                   String subcategoryName = videoCat?.subcategory_name ?? "";
  //                   String topicName = videoCat?.topic_name ?? "";
  //
  //                   String displayText = categoryName;
  //
  //                   if (subcategoryName.isNotEmpty && topicName.isNotEmpty) {
  //                     displayText = "$subcategoryName > $topicName";
  //                   } else if (subcategoryName.isNotEmpty) {
  //                     displayText = subcategoryName;
  //                   } else if (topicName.isNotEmpty) {
  //                     displayText = topicName;
  //                   }
  //                   // if (query.isNotEmpty &&
  //                   //     (!store.videocategory[index]!.category_name!.toLowerCase().contains(query.toLowerCase()))) {
  //                   //   return Container();
  //                   // }
  //                   return InkWell(
  //                     onTap: (){
  //                       Navigator.of(context).pushNamed(Routes.videoSubjectDetail,
  //                           arguments: {"subject": videoCat?.category_name,
  //                             "vid": videoCat?.id});
  //                     },
  //                     child: Container(
  //                       padding: const EdgeInsets.only(
  //                         left: Dimensions.PADDING_SIZE_LARGE,
  //                         top: Dimensions.PADDING_SIZE_SMALL,
  //                         right: Dimensions.PADDING_SIZE_LARGE,
  //                         // bottom: Dimensions.PADDING_SIZE_LARGE,
  //                       ),
  //                       child: Row(
  //                         children: [
  //                           Expanded(
  //                             child: Column(
  //                               crossAxisAlignment: CrossAxisAlignment.start,
  //                               children: [
  //                                 Row(
  //                                   children: [
  //                                     SvgPicture.asset("assets/image/video_outline_icon.svg",color:ThemeManager.black),
  //                                     const SizedBox(width: Dimensions.PADDING_SIZE_SMALL,),
  //                                     SizedBox(
  //                                       width: MediaQuery.of(context).size.width * 0.68,
  //                                       child: Text(videoCat?.category_name ?? "",
  //                                         style: interSemiBold.copyWith(
  //                                           fontSize: Dimensions.fontSizeDefault,
  //                                           fontWeight: FontWeight.w600,
  //                                           color: ThemeManager.black,
  //                                         ),),
  //                                     )
  //                                   ],
  //                                 ),
  //                                 const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT,),
  //                                 ExpandableText(
  //                                   videoCat?.description ?? "",
  //                                   style: interRegular.copyWith(
  //                                     fontSize: Dimensions.fontSizeSmall,
  //                                     fontWeight: FontWeight.w400,
  //                                     color: Theme.of(context).hintColor,
  //                                   ),
  //                                   expandText: "Show more",
  //                                   maxLines: 2,
  //                                   collapseText: 'Show less',
  //                                   linkColor: Colors.blue,),
  //                                 const SizedBox(height: Dimensions.PADDING_SIZE_SMALL,),
  //                                 IntrinsicHeight(
  //                                   child:
  //                                   (videoCat?.subcategory!=null && videoCat?.video!=null)?
  //                                   Row(
  //                                     children: [
  //                                       // Text("${videoCat?.subcategory.toString()} Subcategory",
  //                                       //   style: interRegular.copyWith(
  //                                       //     fontSize: Dimensions.fontSizeSmall,
  //                                       //     fontWeight: FontWeight.w400,
  //                                       //     color: ThemeManager.black,
  //                                       //   ),),
  //                                       // const SizedBox(width: Dimensions.PADDING_SIZE_DEFAULT,),
  //                                       // SizedBox(
  //                                       //   width: 1,
  //                                       //   child: Container(
  //                                       //     color: ThemeManager.black,
  //                                       //   ),
  //                                       // ),
  //                                       // const SizedBox(width: Dimensions.PADDING_SIZE_DEFAULT,),
  //                                       Text("${videoCat?.video.toString()} Videos",
  //                                         style: interRegular.copyWith(
  //                                           fontSize: Dimensions.fontSizeSmall,
  //                                           fontWeight: FontWeight.w400,
  //                                           color: ThemeManager.black,
  //                                         ),),
  //                                       // const Spacer(),
  //                                       // SvgPicture.asset("assets/image/correct_check_icon.svg",
  //                                       //   width: 23,),
  //                                     ],
  //                                   ):const SizedBox(),
  //                                 ),
  //                                 IntrinsicHeight(
  //                                   child:
  //                                   (videoCat?.subcategory_name!=null || videoCat?.topic_name!=null)?
  //                                   Row(
  //                                     children: [
  //                                       Text(displayText,
  //                                         style: interRegular.copyWith(
  //                                           fontSize: Dimensions.fontSizeSmall,
  //                                           fontWeight: FontWeight.w400,
  //                                           color: Theme.of(context).primaryColor,
  //                                         ),),
  //                                     ],
  //                                   ):const SizedBox(),
  //                                 ),
  //                                 const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT,),
  //                                 SizedBox(
  //                                   width: MediaQuery.of(context).size.width,
  //                                   height:1,
  //                                   child: Container(
  //                                     color: const Color(0x0ffe6e4a),
  //                                   ),
  //                                 )
  //                               ],
  //                             ),
  //                           ),
  //                           Icon(Icons.arrow_forward_ios,
  //                             color: Theme.of(context).primaryColor,)
  //                         ],
  //                       ),
  //                     ),
  //                   );
  //                 },
  //               ): const NoInternetScreen();
  //             },
  //           ),
  //         )
  //       ],
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    // if(!isDesktop){    ScreenProtector.protectDataLeakageOff();}
    final List<String> filters = [
      "All",
      "Completed",
      "In Progress",
      "Not Started",
      "Offline Videos",
      "Bookmark Videos"
    ];
    final store = Provider.of<VideoCategoryStore>(context);
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
        title: Text("Video lectures", style: AppTokens.titleLg(context)),
        centerTitle: false,
      ),
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

                    ///Search and Filter
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
                    //         fontSize: Dimensions.fontSizeDefault,
                    //         color: ThemeManager.grey,
                    //         fontWeight: FontWeight.w500,
                    //         fontFamily: 'DM Sans'),
                    //       hintText: 'Search',
                    //       fillColor: ThemeManager.white,
                    //       filled: true,
                    //       border: OutlineInputBorder(
                    //         borderRadius: BorderRadius.circular(
                    //             Dimensions.RADIUS_DEFAULT),
                    //         borderSide: BorderSide(
                    //           color: ThemeManager.mainBorder,
                    //         )),
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

                    ///video list
                    Expanded(
                      child: Observer(
                        builder: (_) {
                          filteredVideos = store.videocategory;
                          _fetchOfflineCounts();
                          if (selectedFilter == "All") {
                            filteredVideos = store.videocategory;
                          } else if (selectedFilter == "Completed") {
                            filteredVideos = store.videocategory
                                .where((video) =>
                                    video?.completedVideoCount != null &&
                                    (video?.completedVideoCount ?? 0) > 0)
                                .toList();
                          } else if (selectedFilter == "In Progress") {
                            filteredVideos = store.videocategory
                                .where((video) =>
                                    video?.progressCount != null && (video?.progressCount ?? 0) > 0)
                                .toList();
                          } else if (selectedFilter == "Not Started") {
                            filteredVideos = store.videocategory
                                .where((video) => video?.notStart != null && (video?.notStart ?? 0) > 0)
                                .toList();
                          } else if (selectedFilter == "Offline Videos") {
                            filteredVideos = store.videocategory.where((video) {
                              final topicId = video?.id ?? "";
                              final count = offlineCounts[topicId] ?? 0;
                              return count > 0;
                            }).toList();
                          } else if (selectedFilter == "Bookmark Videos") {
                            filteredVideos = store.videocategory
                                .where((video) =>
                                    video?.bookmarkVideoCount != null && (video?.bookmarkVideoCount ?? 0) > 0)
                                .toList();
                          }
                          if (store.isLoading) {
                            return const SkeletonList(count: 5, itemHeight: 96);
                          }
                          if (store.videocategory.isEmpty) {
                            return const EmptyState(
                              icon: Icons.video_library_outlined,
                              title: 'No video subjects yet',
                              subtitle: 'New lectures will appear here as soon as they’re published.',
                            );
                          }
                          return store.isConnected
                              ? homeStore.isLoading
                                  ? const SkeletonList(count: 5, itemHeight: 96)
                                  : (homeStore.globalSearchList.isNotEmpty && query.isNotEmpty)
                                      ? isDesktop
                                          ? CustomDynamicHeightGridView(
                                              crossAxisCount: 3,
                                              mainAxisSpacing: 10,
                                              itemCount: homeStore.globalSearchList.length,
                                              builder: (BuildContext context, int index) {
                                                return buildItem(context, homeStore.globalSearchList[index]);
                                              },
                                            )
                                          : ListView.builder(
                                              itemCount: homeStore.globalSearchList.length,
                                              shrinkWrap: true,
                                              padding: EdgeInsets.zero,
                                              physics: const BouncingScrollPhysics(),
                                              itemBuilder: (BuildContext context, int index) {
                                                return buildItem(context, homeStore.globalSearchList[index]);
                                              },
                                            )
                                      : isDesktop
                                          ? CustomDynamicHeightGridView(
                                              crossAxisCount: 3,
                                              mainAxisSpacing: 10,
                                              itemCount: filteredVideos.length,
                                              shrinkWrap: true,
                                              builder: (BuildContext context, int index) {
                                                final video = filteredVideos[index];
                                                final categoryId = video?.id ?? "";
                                                final offlineCount = offlineCounts[categoryId] ?? 0;
                                                return buildItem1(
                                                    context, filteredVideos[index], offlineCount);
                                              },
                                            )
                                          : ListView.builder(
                                              itemCount: filteredVideos.length,
                                              padding: EdgeInsets.zero,
                                              shrinkWrap: true,
                                              physics: const BouncingScrollPhysics(),
                                              itemBuilder: (BuildContext context, int index) {
                                                final video = filteredVideos[index];
                                                final categoryId = video?.id ?? "";
                                                final offlineCount = offlineCounts[categoryId] ?? 0;
                                                return buildItem1(
                                                    context, filteredVideos[index], offlineCount);
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

  Widget buildItem(BuildContext context, GlobalSearchDataModel? videoCat) {
    String? categoryName = videoCat?.categoryName;
    String? subcategoryName = videoCat?.subcategoryName;
    String? topicName = videoCat?.topicName;
    String? title = videoCat?.title;

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
                arguments: {"subject": categoryName, "vid": videoCat?.id});
          } else if (type == "Subcategory") {
            Navigator.of(context).pushNamed(Routes.VideoTopicCategory,
                arguments: {"chapter": subcategoryName, "subcatId": videoCat?.id});
          } else if (type == "Topic") {
            Navigator.of(context).pushNamed(Routes.videoChapterDetail,
                arguments: {"chapter": topicName, "subject": videoCat?.subName, "subcatId": videoCat?.id});
          } else if (type == "Content") {
            Navigator.of(context).pushNamed(Routes.videoPlayDetail, arguments: {
              "topicId": videoCat?.id,
              "videoTopicId": videoCat?.topicId,
              // "topicId": videoTopic?.topicId,
              "isCompleted": false,
              'title': videoCat?.title ?? '',
              'isDownloaded': false,
              'titleId': videoCat?.id,
              'contentId': videoCat?.id,
              // 'pauseTime': videoCat?.pausedTime,
              'categoryId': videoCat?.categoryId,
              'subcategoryId': videoCat?.subcategoryId,
              'isBookmark': videoCat?.isBookmark,
              'pdfId': videoCat?.pdfId,
              'videoPlayUrl': videoCat?.videoLink,
              'videoQuality': videoCat?.videoFiles,
              'downloadVideoData': videoCat?.downloadVideo,
              'annotationData': videoCat?.annotation,
              'hlsLink': null // GlobalSearchDataModel doesn't have hlsLink
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.all(Dimensions.PADDING_SIZE_DEFAULT),
          decoration: BoxDecoration(
            color: ThemeManager.white,
            borderRadius: BorderRadius.circular(9.6),
            border: Border.all(color: ThemeManager.mainBorder),
          ),
          child: Row(
            children: [
              Container(
                height: Dimensions.PADDING_SIZE_LARGE * 3.2,
                width: Dimensions.PADDING_SIZE_LARGE * 3.2,
                padding: const EdgeInsets.all(Dimensions.PADDING_SIZE_DEFAULT),
                // decoration: BoxDecoration(
                //   color: ThemeManager.blueFinalTrans,
                //   border: Border.all(color: ThemeManager.mainBorder),
                //   borderRadius: BorderRadius.circular(14.4),
                // ),
                child: SvgPicture.asset(
                  "assets/image/videocategoryIcon.svg",
                ),
              ),
              const SizedBox(width: Dimensions.PADDING_SIZE_DEFAULT),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: (Platform.isWindows || Platform.isMacOS)
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    Text(
                      displayText,
                      maxLines: 3,
                      overflow: TextOverflow.visible,
                      style: interSemiBold.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        fontWeight: FontWeight.w600,
                        color: ThemeManager.black,
                      ),
                    ),
                    const SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                    Text(
                      videoCat?.description ?? "",
                      style: interRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        fontWeight: FontWeight.w400,
                        overflow: TextOverflow.ellipsis,
                        color: ThemeManager.black.withOpacity(0.5),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_SMALL),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  // void getOfflineCount(String catId) async{
  //   debugPrint("onlincatId$catId");
  //   final offlineVideosCount = await DbHelper().getVideoCountByCategoryId(catId);
  //   debugPrint("count$offlineVideosCount");
  //   // setState(() {
  //     offlineCount = offlineVideosCount;
  //   // });
  // }

  Widget buildItem1(BuildContext context, VideoCategoryModel? videoCat, int offlineCount) {
    String categoryName = videoCat?.category_name ?? "";
    String subcategoryName = videoCat?.subcategory_name ?? "";
    String topicName = videoCat?.topic_name ?? "";

    String displayText = categoryName;
    // int offlineVideosCount = videosList
    //     ?.where((video) => video.categoryId == videoCat?.id)
    //     .length ??
    //     0;

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
          Navigator.of(context).pushNamed(
            Routes.videoSubjectDetail,
            arguments: {
              "subject": videoCat?.category_name,
              "vid": videoCat?.id,
            },
          );
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 120),
          padding: const EdgeInsets.all(Dimensions.PADDING_SIZE_DEFAULT),
          decoration: BoxDecoration(
            color: ThemeManager.white,
            borderRadius: BorderRadius.circular(9.6),
            border: Border.all(color: ThemeManager.mainBorder),
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
                      color: ThemeManager.blueFinalTrans,
                      border: Border.all(color: ThemeManager.mainBorder),
                      borderRadius: BorderRadius.circular(14.4),
                    ),
                    child: SvgPicture.asset(
                      "assets/image/videocategoryIcon.svg",
                    ),
                  ),
                  const SizedBox(width: Dimensions.PADDING_SIZE_SMALL),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: (Platform.isWindows || Platform.isMacOS)
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: isDesktop ? null : MediaQuery.of(context).size.width * 0.4,
                              child: Text(
                                videoCat?.category_name ?? "",
                                maxLines: 3,
                                overflow: TextOverflow.visible,
                                style: interSemiBold.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  fontWeight: FontWeight.w600,
                                  color: ThemeManager.black,
                                ),
                              ),
                            ),
                            (videoCat?.subcategory != null && videoCat?.video != null)
                                ? Text(
                                    "${videoCat?.video.toString()} Videos",
                                    style: interSemiBold.copyWith(
                                      fontSize: Dimensions.fontSizeExtraSmall,
                                      fontWeight: FontWeight.w500,
                                      color: ThemeManager.black.withOpacity(0.5),
                                    ),
                                  )
                                : const SizedBox(),
                          ],
                        ),
                        const SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                        Text(
                          videoCat?.description ?? "",
                          style: interRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            fontWeight: FontWeight.w500,
                            overflow: TextOverflow.ellipsis,
                            color: ThemeManager.black.withOpacity(0.5),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_SMALL),
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
                        "${videoCat?.completedVideoCount.toString() ?? "0"} Completed",
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
                        "${videoCat?.progressCount.toString() ?? "0"} In Progress",
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
                        "${videoCat?.notStart.toString() ?? "0"} Not Started",
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
                  if ((videoCat?.bookmarkVideoCount ?? 0) > 0)
                    Row(
                      children: [
                        SvgPicture.asset(
                          "assets/image/bookmark_status_icon.svg",
                          height: Dimensions.PADDING_SIZE_LARGE,
                          width: Dimensions.PADDING_SIZE_LARGE,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${videoCat?.bookmarkVideoCount.toString() ?? "0"} Bookmarked",
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
              videoCat?.priorityLabel != null ? const Divider() : SizedBox.shrink(),
              PriorityBadge(
                priorityLabel: videoCat?.priorityLabel,
                priorityColor: videoCat?.priorityColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
