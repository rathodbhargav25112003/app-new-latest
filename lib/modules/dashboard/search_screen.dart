import 'dart:io';
import '../../app/routes.dart';
import '../../helpers/colors.dart';
import '../../helpers/styles.dart';
import '../../helpers/app_tokens.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import '../../helpers/dimensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'models/global_search_model.dart';
import '../widgets/custom_bottom_sheet.dart';
import '../../models/searched_data_model.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../models/video_category_model.dart';
import '../widgets/no_access_bottom_sheet.dart';
import '../widgets/no_internet_connection.dart';
import 'package:expandable_text/expandable_text.dart';
import '../subscriptionplans/store/subscription_store.dart';
import 'package:shusruta_lms/modules/dashboard/store/home_store.dart';
import 'package:shusruta_lms/modules/widgets/no_access_alert_dialog.dart';
import 'package:shusruta_lms/modules/videolectures/store/video_category_store.dart';

class SearchScreen extends StatefulWidget {
  final String selectedValue;
  final String text;
  const SearchScreen(
      {super.key, required this.selectedValue, required this.text});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => SearchScreen(
        selectedValue: arguments['selectedValue'],
        text: arguments['text'],
      ),
    );
  }
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String selectedValue = '';
  List<String> drop = [
    "All Category",
    "Videos",
    "Notes",
    "Exams",
    "Mock Exams"
  ];
  String query = '';
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    selectedValue = widget.selectedValue;
    query = widget.text;
    _searchController.text = widget.text;
    if (widget.text.length > 3) {
      searchCategory(widget.text, "all");
    }
    _focusNode.addListener(_onFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  Future<void> searchCategory(String keyword, String selectedVal) async {
    final store = Provider.of<HomeStore>(context, listen: false);
    await store.onGlobalSearchApiCall(keyword, selectedVal);
  }

  /// Maps the human-readable filter chip label onto the API key the
  /// backend expects, then dispatches the search.
  void _runSearch() {
    final apiKey = _filterApiKey(selectedValue);
    searchCategory(query, apiKey);
  }

  String _filterApiKey(String label) {
    switch (label) {
      case 'Videos':
        return 'video';
      case 'Notes':
        return 'pdf';
      case 'Exams':
        return 'exam';
      case 'Mock Exams':
        return 'mockExam';
      case 'All Category':
      default:
        return 'all';
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<HomeStore>(context);
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      appBar: AppBar(
        backgroundColor: AppTokens.scaffold(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTokens.ink(context), size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text("Search", style: AppTokens.titleLg(context)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppTokens.s24, AppTokens.s8, AppTokens.s24, AppTokens.s16),
          child: Column(
            children: [
              /// Apple-style search field with leading magnifier + trailing clear.
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppTokens.surface(context),
                  borderRadius: AppTokens.radius12,
                  border: Border.all(
                    color: AppTokens.border(context),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: AppTokens.s12),
                    Icon(Icons.search_rounded,
                        size: 20, color: AppTokens.muted(context)),
                    const SizedBox(width: AppTokens.s8),
                    Expanded(
                      child: TextFormField(
                        cursorColor: AppTokens.accent(context),
                        style: AppTokens.body(context).copyWith(
                          color: AppTokens.ink(context),
                        ),
                        focusNode: _focusNode,
                        onChanged: (value) {
                          setState(() {
                            query = value;
                            if (query.length >= 3) {
                              _runSearch();
                            }
                          });
                        },
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.search,
                        controller: _searchController,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: 'Chapter name, topic, exam…',
                          hintStyle: AppTokens.body(context).copyWith(
                            color: AppTokens.muted(context),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          counterText: '',
                        ),
                      ),
                    ),
                    if (query.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.cancel_rounded,
                            size: 18, color: AppTokens.muted(context)),
                        onPressed: () {
                          setState(() {
                            query = '';
                            _searchController.clear();
                          });
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.s12),

              /// Filter chip row — replaces the legacy blue dropdown.
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: drop.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppTokens.s8),
                  itemBuilder: (_, i) {
                    final label = drop[i];
                    final isActive = selectedValue.isEmpty
                        ? i == 0
                        : selectedValue == label;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedValue = label;
                          if (query.length >= 3) {
                            _runSearch();
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.s16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTokens.accent(context)
                              : AppTokens.surface(context),
                          borderRadius: AppTokens.radius12,
                          border: Border.all(
                            color: isActive
                                ? AppTokens.accent(context)
                                : AppTokens.border(context),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          label,
                          style: AppTokens.titleSm(context).copyWith(
                            color: isActive
                                ? Colors.white
                                : AppTokens.ink2(context),
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppTokens.s16),

            ///video list
            Expanded(
              child: Observer(
                builder: (_) {
                  if (store.isLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppTokens.accent(context),
                      ),
                    );
                  }
                  if (store.globalSearchList.isEmpty && query.isNotEmpty) {
                    return _SearchEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No matches',
                      subtitle:
                          'Try a different keyword or change the filter above.',
                    );
                  }
                  if (!store.isConnected) return const NoInternetScreen();
                  if (query.isEmpty) {
                    return _SearchEmptyState(
                      icon: Icons.search_rounded,
                      title: 'Start typing to search',
                      subtitle:
                          'Search across videos, notes, exams and mock tests.',
                    );
                  }
                  return store.isConnected
                      ? (store.globalSearchList.isNotEmpty && query.isNotEmpty)
                          ? ListView.builder(
                              itemCount: store.globalSearchList.length,
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (BuildContext context, int index) {
                                GlobalSearchDataModel? videoCat =
                                    store.globalSearchList[index];
                                String? categoryName = videoCat?.categoryName;
                                String? subcategoryName =
                                    videoCat?.subcategoryName;
                                String? topicName = videoCat?.topicName;
                                String? title = videoCat?.title;
                                String? examName = videoCat?.examName;

                                String displayText = categoryName ??
                                    subcategoryName ??
                                    topicName ??
                                    title ??
                                    examName ??
                                    "";
                                String type = videoCat?.type ?? '';
                                String typeName = videoCat?.type ?? '';
                                String assetImage =
                                    videoCat?.contentType == 'video'
                                        ? "assets/image/continueIcon.svg"
                                        : videoCat?.contentType == 'PDF'
                                            ? "assets/image/continueNote.svg"
                                            : "assets/image/continueExam.svg";
                                if (type == 'videoCategory' ||
                                    type == 'videoSubCategory' ||
                                    type == 'videoTopic') {
                                  typeName = 'Videos';
                                  assetImage = "assets/image/continueIcon.svg";
                                } else if (type == 'pdfCategory' ||
                                    type == 'pdfSubCategory' ||
                                    type == 'pdfTopic') {
                                  typeName = 'eNotes';
                                  assetImage = "assets/image/continueNote.svg";
                                } else if (type == 'examCategory' ||
                                    type == 'examSubcategory' ||
                                    type == 'examTopic') {
                                  typeName = 'Exams';
                                  assetImage = "assets/image/continueExam.svg";
                                } else if (type == 'mockCategory') {
                                  typeName = 'Mock Exams';
                                  assetImage = "assets/image/continueExam.svg";
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: Dimensions.PADDING_SIZE_SMALL),
                                  child: InkWell(
                                    onTap: () {
                                      if (type == "videoCategory") {
                                        Navigator.of(context).pushNamed(
                                            Routes.videoSubjectDetail,
                                            arguments: {
                                              "subject": categoryName,
                                              "vid": videoCat?.id
                                            });
                                      } else if (type == "videoSubCategory") {
                                        debugPrint(
                                            "videoCat?.subcategoryId:${videoCat?.id}");
                                        Navigator.of(context).pushNamed(
                                            Routes.VideoTopicCategory,
                                            arguments: {
                                              "chapter": subcategoryName,
                                              "subcatId": videoCat?.id
                                            });
                                      } else if (type == "videoTopic") {
                                        Navigator.of(context).pushNamed(
                                            Routes.videoChapterDetail,
                                            arguments: {
                                              "chapter": videoCat?.topicName,
                                              "subject": '',
                                              "subcatId": videoCat?.id
                                            });
                                      } else if (type == "content" &&
                                          videoCat?.contentType == 'video') {
                                        if (videoCat?.isAccess == true) {
                                          Navigator.of(context).pushNamed(
                                              Routes.videoPlayDetail,
                                              arguments: {
                                                "topicId": videoCat?.id,
                                              });
                                        } else {
                                          if (Platform.isWindows ||
                                              Platform.isMacOS) {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  backgroundColor: ThemeManager
                                                      .mainBackground,
                                                  actionsPadding:
                                                      EdgeInsets.zero,
                                                  insetPadding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 100),
                                                  actions: const [
                                                    NoAccessAlertDialog(),
                                                  ],
                                                );
                                              },
                                            );
                                          } else {
                                            showModalBottomSheet<void>(
                                              isScrollControlled: true,
                                              shape:
                                                  const RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.vertical(
                                                  top: Radius.circular(25),
                                                ),
                                              ),
                                              clipBehavior:
                                                  Clip.antiAliasWithSaveLayer,
                                              context: context,
                                              builder: (BuildContext context) {
                                                return const NoAccessBottomSheet();
                                              },
                                            );
                                          }
                                        }
                                      } else if (type == "pdfCategory") {
                                        Navigator.of(context).pushNamed(
                                            Routes.notesSubjectDetail,
                                            arguments: {
                                              "subject": categoryName,
                                              "noteid": videoCat?.id
                                            });
                                      } else if (type == "pdfSubCategory") {
                                        Navigator.of(context).pushNamed(
                                            Routes.notesTopicCategory,
                                            arguments: {
                                              "topicname": subcategoryName,
                                              "topic": subcategoryName,
                                              "subcatId": videoCat?.id
                                            });
                                      } else if (type == "pdfTopic") {
                                        Navigator.of(context).pushNamed(
                                            Routes.notesChapterDetail,
                                            arguments: {
                                              "topicname": topicName,
                                              "chapter": topicName,
                                              "subcatId": videoCat?.id,
                                              "subcaptername":
                                                  videoCat?.subName,
                                            });
                                      } else if (type == "content" &&
                                          videoCat?.contentType == 'PDF') {
                                        if (videoCat?.isAccess == true) {
                                          Navigator.of(context).pushNamed(
                                              Routes.notesReadView,
                                              arguments: {
                                                'contentUrl':
                                                    videoCat?.contentUrl,
                                                'title': videoCat?.title ?? '',
                                                'topic_name':
                                                    videoCat?.topicName ?? '',
                                                'category_name':
                                                    videoCat?.categoryName ??
                                                        '',
                                                'subcategory_name':
                                                    videoCat?.subcategoryName ??
                                                        '',
                                                'isDownloaded': false,
                                                'topicId': videoCat?.topicId,
                                                'titleId': videoCat?.id,
                                                'isCompleted': true,
                                                'categoryId':
                                                    videoCat?.categoryId,
                                                'subcategoryId':
                                                    videoCat?.subcategoryId,
                                              });
                                        } else {
                                          if (Platform.isWindows ||
                                              Platform.isMacOS) {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  backgroundColor: ThemeManager
                                                      .mainBackground,
                                                  actionsPadding:
                                                      EdgeInsets.zero,
                                                  insetPadding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 100),
                                                  actions: const [
                                                    NoAccessAlertDialog(),
                                                  ],
                                                );
                                              },
                                            );
                                          } else {
                                            showModalBottomSheet<void>(
                                              isScrollControlled: true,
                                              shape:
                                                  const RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.vertical(
                                                  top: Radius.circular(25),
                                                ),
                                              ),
                                              clipBehavior:
                                                  Clip.antiAliasWithSaveLayer,
                                              context: context,
                                              builder: (BuildContext context) {
                                                return const NoAccessBottomSheet();
                                              },
                                            );
                                          }
                                        }
                                      } else if (type == "examCategory") {
                                        Navigator.of(context).pushNamed(
                                            Routes.testSubjectDetail,
                                            arguments: {
                                              "subject": categoryName,
                                              "testid": videoCat?.id
                                            });
                                      } else if (type == "examSubcategory") {
                                        Navigator.of(context).pushNamed(
                                            Routes.testChapterDetail,
                                            arguments: {
                                              "chapter": subcategoryName,
                                              "subcatId": videoCat?.id
                                            });
                                      } else if (type == "examTopic") {
                                        Navigator.of(context).pushNamed(
                                            Routes.selectTestList,
                                            arguments: {
                                              'id': videoCat?.id,
                                              'type': "topic"
                                            });
                                      } else if (type == "mockCategory") {
                                        Navigator.of(context).pushNamed(
                                            Routes.allSelectTestList,
                                            arguments: {
                                              'id': videoCat?.id,
                                              'type': "topic",
                                            });
                                      }
                                    },
                                    child: Stack(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(
                                              AppTokens.s16),
                                          decoration: BoxDecoration(
                                            color: AppTokens.surface(context),
                                            borderRadius: AppTokens.radius16,
                                            border: Border.all(
                                                color: AppTokens.border(context),
                                                width: 0.5),
                                          ),
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
                                                      .containerOpacity,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          14.4),
                                                ),
                                                child: SvgPicture.asset(
                                                  assetImage,
                                                  color: ThemeManager
                                                              .currentTheme ==
                                                          AppTheme.Light
                                                      ? null
                                                      : ThemeManager.black,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: Dimensions
                                                    .PADDING_SIZE_DEFAULT,
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.56,
                                                    child: Text(
                                                      displayText ?? "",
                                                      style: interSemiBold
                                                          .copyWith(
                                                        fontSize: Dimensions
                                                            .fontSizeDefault,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            ThemeManager.black,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    height: Dimensions
                                                        .PADDING_SIZE_EXTRA_SMALL,
                                                  ),
                                                  SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.56,
                                                    child: Text(
                                                      videoCat?.description ??
                                                          "",
                                                      style:
                                                          interRegular.copyWith(
                                                        fontSize: Dimensions
                                                            .fontSizeSmall,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        color: ThemeManager
                                                            .black
                                                            .withOpacity(0.5),
                                                      ),
                                                      maxLines: 2,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    height: Dimensions
                                                        .PADDING_SIZE_EXTRA_SMALL,
                                                  ),
                                                  Text(
                                                    type == "content"
                                                        ? videoCat?.contentType ==
                                                                'video'
                                                            ? 'Videos'
                                                            : videoCat?.contentType ==
                                                                    'PDF'
                                                                ? 'eNotes'
                                                                : typeName
                                                        : typeName,
                                                    style:
                                                        interSemiBold.copyWith(
                                                      fontSize: Dimensions
                                                          .fontSizeSmall,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: ThemeManager.black,
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (videoCat?.isAccess == false)
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: Container(
                                              height: 28,
                                              width: 28,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: AppTokens.accent(context),
                                                borderRadius:
                                                    const BorderRadius.only(
                                                  topRight: Radius.circular(16),
                                                  bottomLeft:
                                                      Radius.circular(12),
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.lock_rounded,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                          : const SizedBox()
                      : const NoInternetScreen();
                },
              ),
            )
          ],
        ),
      ),
    ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTokens.surface2(context),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: 30, color: AppTokens.muted(context)),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(title, style: AppTokens.titleMd(context)),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTokens.body(context),
            ),
          ],
        ),
      ),
    );
  }
}
