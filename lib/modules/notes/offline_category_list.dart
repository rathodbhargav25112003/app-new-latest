import 'dart:io';

import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/helpers/constants.dart';
import 'package:shusruta_lms/modules/notes/store/notes_category_store.dart';
import '../../app/routes.dart';
import '../../helpers/app_skeleton.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/dbhelper.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/empty_state.dart';
import '../../helpers/refresh_helper.dart';
import '../../helpers/styles.dart';
import '../../models/notes_offline_data_model.dart';
import '../../models/subscription_model.dart';
import '../subscriptionplans/store/subscription_store.dart';

class OfflineCategoryList extends StatefulWidget {
  const OfflineCategoryList({super.key});

  @override
  State<OfflineCategoryList> createState() => _OfflineCategoryListState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const OfflineCategoryList(),
    );
  }
}

class _OfflineCategoryListState extends State<OfflineCategoryList> {
  String filterValue = '';
  String query = '';
  final FocusNode _focusNode = FocusNode();
  List<NotesOfflineDataModel>? notesList;
  bool isLoading = false;
  List<String>? pdfTopicId;
  // late Set flatSet;
  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    _getOfflineData();
    _getSubscribedPlan();
  }

  Future<void> _getSubscribedPlan() async {
    final store = Provider.of<SubscriptionStore>(context, listen: false);
    await store.onGetSubscribedUserPlan();
    if (store.subscribedPlan.isEmpty) {
      // _getofflineDataDelete();
      // Navigator.of(context).pushNamed(Routes.subscriptionList);
    } else if (store.subscribedPlan.isNotEmpty) {
      List<String>? offlinePdfTopicId;
      offlinePdfTopicId =
          (notesList?.map((e) => e.topicId).toList() ?? []).cast<String>();
      pdfTopicId = store.subscribedPlan
          .expand((e) => e?.pdf_topic_id ?? [])
          .cast<String>()
          .toList();
      debugPrint("pdfTopicId $pdfTopicId");
      debugPrint("offlinePdfTopicId $offlinePdfTopicId");
      List<String> difference = offlinePdfTopicId
          .where((element) => !pdfTopicId!.contains(element))
          .toList();

      debugPrint("Ids not present in pdfTopicId: $difference");
      if (pdfTopicId != offlinePdfTopicId) {
        debugPrint("if ${notesList?.map((e) => e.topicId)}");
        final dbHelper = DbHelper();
        for (var topicId in difference) {
          await dbHelper.deleteAllNotesByTopicId(topicId);
        }
        _getOfflineData();
      } else {
        debugPrint("else ${notesList?.map((e) => e.topicId)}");
      }
    } else {
      _getOfflineData();
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  Future<void> _getOfflineData() async {
    setState(() {
      isLoading = true;
    });
    final dbHelper = DbHelper();
    notesList = await dbHelper.getAllNotesGroupedByCategoryId();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _getofflineDataDelete() async {
    setState(() {
      isLoading = true;
    });

    final dbHelper = DbHelper();
    // await dbHelper.deleteAllNotesByTopicIdWithSubcription(flatSet);
    //notesList?.clear();
    print("notes list $notesList?.length");
    setState(() {
      isLoading = false;
    });
  }

  Future<void> searchCategory(String keyword) async {
    final store = Provider.of<NotesCategoryStore>(context, listen: false);
    await store.onSearchApiCall(keyword, "PDF");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeManager.white,
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
      //     "Offline Notes",
      //     style: interRegular.copyWith(
      //       fontSize: Dimensions.fontSizeLarge,
      //       fontWeight: FontWeight.w500,
      //       color: ThemeManager.black,
      //     ),
      //   ),
      // ),
      body: Container(
          color: ThemeManager.blueFinalDark,
          child: Column(
            children: [
              Padding(
                padding: (Platform.isWindows || Platform.isMacOS)
                    ? const EdgeInsets.symmetric(
                        vertical: Dimensions.PADDING_SIZE_LARGE * 1.2,
                        horizontal: Dimensions.PADDING_SIZE_LARGE * 1.2)
                    : const EdgeInsets.only(
                        top: Dimensions.PADDING_SIZE_LARGE * 2,
                        left: Dimensions.PADDING_SIZE_LARGE * 1.2,
                        right: Dimensions.PADDING_SIZE_LARGE * 1.2,
                        bottom: Dimensions.PADDING_SIZE_SMALL * 1.3),
                child: Row(
                  children: [
                    IconButton(
                        highlightColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.white,
                        )),
                    const SizedBox(
                      width: Dimensions.PADDING_SIZE_DEFAULT,
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.4,
                      child: Text(
                        "Offline Notes",
                        style: interRegular.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(
                      left: Dimensions.PADDING_SIZE_LARGE * 1.2,
                      right: Dimensions.PADDING_SIZE_LARGE * 1.2,
                      top: Dimensions.PADDING_SIZE_EXTRA_LARGE),
                  decoration: BoxDecoration(
                    color: ThemeManager.mainBackground,
                    borderRadius: (Platform.isWindows || Platform.isMacOS)
                        ? null
                        : const BorderRadius.only(
                            topLeft: Radius.circular(28.8),
                            topRight: Radius.circular(28.8),
                          ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      query.isNotEmpty
                          ? Text(
                              "Results for “$query”",
                              style: interRegular.copyWith(
                                fontSize: Dimensions.fontSizeDefault,
                                fontWeight: FontWeight.w400,
                                color: ThemeManager.black,
                              ),
                            )
                          : const SizedBox(),
                      const SizedBox(
                        height: Dimensions.PADDING_SIZE_SMALL,
                      ),

                      ///Search
                      SizedBox(
                        height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                        child: TextField(
                          focusNode: _focusNode,
                          onChanged: (value) {
                            setState(() {
                              query = value;
                            });
                          },
                          style: interRegular.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              color: ThemeManager.black,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'DM Sans'),
                          cursorColor: ThemeManager.grey,
                          decoration: InputDecoration(
                            suffixIcon: const Icon(CupertinoIcons.search),
                            suffixIconColor: ThemeManager.black,
                            hintStyle: interRegular.copyWith(
                                fontSize: Dimensions.fontSizeDefault,
                                color: ThemeManager.grey,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'DM Sans'),
                            hintText: 'Search',
                            fillColor: ThemeManager.white,
                            filled: true,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    Dimensions.RADIUS_DEFAULT),
                                borderSide: BorderSide(
                                  color: ThemeManager.mainBorder,
                                )),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  Dimensions.RADIUS_DEFAULT),
                              borderSide: BorderSide(
                                color: ThemeManager.mainBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  Dimensions.RADIUS_DEFAULT),
                              borderSide: BorderSide(
                                color: ThemeManager.mainBorder,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: Dimensions.PADDING_SIZE_DEFAULT,
                      ),

                      ///notes list
                      isLoading
                        ? const Expanded(
                            child: SkeletonList(count: 5, itemHeight: 88))
                        : (notesList?.isEmpty ?? false)
                        ? const Expanded(
                            child: EmptyState(
                              icon: Icons.cloud_off_rounded,
                              title: 'No offline notes',
                              subtitle:
                                  'Notes you download for offline reading '
                                  'will appear here.',
                            ),
                          )
                        : Expanded(
                                  child: ListView.builder(
                                    itemCount: notesList?.length ?? 0,
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    physics: const BouncingScrollPhysics(),
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      NotesOfflineDataModel? notesCat =
                                          notesList?[index];
                                      String categoryName =
                                          notesCat?.categoryName ?? "";
                                      String categoryId =
                                          notesCat?.categoryId ?? "";
                                      if (query.isNotEmpty &&
                                          (!categoryName
                                              .toLowerCase()
                                              .contains(query.toLowerCase()))) {
                                        return Container();
                                      }
                                      // return InkWell(
                                      //   onTap: (){
                                      //     Navigator.of(context).pushNamed(Routes.downloadedNotesSubCategory,
                                      //     arguments: {
                                      //       'categoryId': categoryId
                                      //     });
                                      //   },
                                      //   child: Container(
                                      //     padding: const EdgeInsets.only(
                                      //       left: Dimensions.PADDING_SIZE_LARGE,
                                      //       top: Dimensions.PADDING_SIZE_SMALL,
                                      //       right: Dimensions.PADDING_SIZE_LARGE,
                                      //       // bottom: Dimensions.PADDING_SIZE_LARGE,
                                      //     ),
                                      //     child: Row(
                                      //       children: [
                                      //         Expanded(
                                      //           child: Column(
                                      //             crossAxisAlignment: CrossAxisAlignment.start,
                                      //             children: [
                                      //               Row(
                                      //                 children: [
                                      //                   SvgPicture.asset("assets/image/book_outline_icon.svg"),
                                      //                   const SizedBox(width: Dimensions.PADDING_SIZE_SMALL,),
                                      //                   SizedBox(
                                      //                     width: MediaQuery.of(context).size.width * 0.68,
                                      //                     child: Text(categoryName,
                                      //                       style: interSemiBold.copyWith(
                                      //                         fontSize: Dimensions.fontSizeDefault,
                                      //                         fontWeight: FontWeight.w600,
                                      //                         color: ThemeManager.black,
                                      //                       ),),
                                      //                   )
                                      //                 ],
                                      //               ),
                                      //               const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT,),
                                      //               SizedBox(
                                      //                 width: MediaQuery.of(context).size.width,
                                      //                 height:1,
                                      //                 child: Container(
                                      //                   color: const Color(0x0ffe6e4a),
                                      //                 ),
                                      //               )
                                      //             ],
                                      //           ),
                                      //         ),
                                      //         Icon(Icons.arrow_forward_ios,
                                      //           color: Theme.of(context).primaryColor,)
                                      //       ],
                                      //     ),
                                      //   ),
                                      // );
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                            bottom:
                                                Dimensions.PADDING_SIZE_SMALL),
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.of(context).pushNamed(
                                                Routes
                                                    .downloadedNotesSubCategory,
                                                arguments: {
                                                  'categoryId': categoryId
                                                });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(
                                                Dimensions
                                                    .PADDING_SIZE_DEFAULT),
                                            decoration: BoxDecoration(
                                                color: ThemeManager.white,
                                                border: Border.all(
                                                    color: ThemeManager
                                                        .mainBorder),
                                                borderRadius:
                                                    BorderRadius.circular(9.6)),
                                            child: Row(
                                              children: [
                                                Container(
                                                  height: Dimensions
                                                          .PADDING_SIZE_LARGE *
                                                      3.6,
                                                  width: Dimensions
                                                          .PADDING_SIZE_LARGE *
                                                      3.6,
                                                  padding: const EdgeInsets.all(
                                                      Dimensions
                                                          .PADDING_SIZE_LARGE),
                                                  decoration: BoxDecoration(
                                                      color: ThemeManager
                                                          .blueFinalTrans,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              14.4)),
                                                  child: SvgPicture.asset(
                                                    "assets/image/noteCategory.svg",
                                                    color: ThemeManager
                                                                .currentTheme ==
                                                            AppTheme.Dark
                                                        ? AppColors.white
                                                        : null,
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: Dimensions
                                                      .PADDING_SIZE_DEFAULT,
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    categoryName ?? "",
                                                    style:
                                                        interSemiBold.copyWith(
                                                      fontSize: Dimensions
                                                          .fontSizeDefault,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: ThemeManager.black,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
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
}
