import 'dart:io';
import 'dart:developer';
import '../../app/routes.dart';
import '../../helpers/app_skeleton.dart';
import '../../helpers/colors.dart';
import '../../helpers/refresh_helper.dart';
import '../../helpers/styles.dart';
import '../../helpers/app_tokens.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import '../../helpers/dimensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'models/global_search_model.dart';
import '../../models/video_data_model.dart';
import '../../models/notes_topic_model.dart';
import '../widgets/custom_bottom_sheet.dart';
import 'models/continue_watching_model.dart';
import '../../models/searched_data_model.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../models/video_category_model.dart';
import '../widgets/no_internet_connection.dart';
import 'package:expandable_text/expandable_text.dart';
import '../subscriptionplans/store/subscription_store.dart';
import 'package:shusruta_lms/models/test_exampaper_list_model.dart';
import 'package:shusruta_lms/modules/dashboard/store/home_store.dart';
import 'package:shusruta_lms/modules/videolectures/store/video_category_store.dart';

class ContinueWatchingScreen extends StatefulWidget {
  const ContinueWatchingScreen({super.key});

  @override
  State<ContinueWatchingScreen> createState() => _ContinueWatchingScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const ContinueWatchingScreen(),
    );
  }
}

class _ContinueWatchingScreenState extends State<ContinueWatchingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _getContinueWatchingData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _getContinueWatchingData() async {
    final store = Provider.of<HomeStore>(context, listen: false);
    await store.onGetContinueListApiCall();
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<HomeStore>(context);
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
        title: Text("Continue learning", style: AppTokens.titleLg(context)),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.fromLTRB(
                AppTokens.s24, 0, AppTokens.s24, AppTokens.s8),
            decoration: BoxDecoration(
              color: AppTokens.surface2(context),
              borderRadius: AppTokens.radius12,
              border: Border.all(
                color: AppTokens.border(context),
                width: 0.5,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTokens.surface(context),
                borderRadius: AppTokens.radius12,
                boxShadow: AppTokens.shadow1(context),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(3),
              dividerColor: Colors.transparent,
              labelColor: AppTokens.ink(context),
              unselectedLabelColor: AppTokens.muted(context),
              labelStyle: AppTokens.titleSm(context),
              unselectedLabelStyle: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: "Videos"),
                Tab(text: "Notes"),
                Tab(text: "MCQ Bank"),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Observer(
          builder: (_) {
            if (store.isLoading) {
              return const SkeletonList(count: 5, itemHeight: 90);
            }
            if (!store.isConnected) return const NoInternetScreen();
            if (store.getContinueListData.isEmpty) {
              return _ContinueEmpty(
                title: 'Nothing to resume',
                subtitle: 'Start a video, note or quiz and pick it up here.',
              );
            }
            return TabBarView(
              physics: const BouncingScrollPhysics(),
              controller: _tabController,
              children: [
                AppRefresh(
                  onRefresh: () => store.onGetContinueListApiCall(),
                  child: _buildVideosList(store),
                ),
                AppRefresh(
                  onRefresh: () => store.onGetContinueListApiCall(),
                  child: _buildNotesList(store),
                ),
                AppRefresh(
                  onRefresh: () => store.onGetContinueListApiCall(),
                  child: _buildMCQList(store),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideosList(HomeStore store) {
    if (store.getContinueListData[0]?.videoResults?.isEmpty ?? true) {
      return _ContinueEmpty(
        title: 'No videos in progress',
        subtitle: 'Videos you start will appear here.',
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTokens.s24, AppTokens.s16, AppTokens.s24, AppTokens.s24),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        itemCount: store.getContinueListData[0]?.videoResults?.length ?? 0,
        itemBuilder: (context, index) {
          VideoResultsDetailModel? videoData =
              store.getContinueListData[0]?.videoResults?[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.s12),
            child: InkWell(
              borderRadius: AppTokens.radius16,
              onTap: () => _handleVideoTap(context, videoData),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTokens.surface(context),
                  borderRadius: AppTokens.radius16,
                  border: Border.all(
                      color: AppTokens.border(context), width: 0.5),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 10,
                      ),
                      Stack(
                        children: [
                          Container(
                            height: Dimensions.PADDING_SIZE_LARGE * 3.2,
                            width: Dimensions.PADDING_SIZE_LARGE * 4.6,
                            decoration: BoxDecoration(
                              color: ThemeManager.continueContainerTrans,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: (videoData?.thumbnail != null &&
                                      videoData!.thumbnail!.isNotEmpty)
                                  ? Image.network(
                                      videoData.thumbnail ?? "",
                                      fit: BoxFit.fill,
                                    )
                                  : SvgPicture.asset(
                                      "assets/image/videochapter.svg",
                                      color: ThemeManager.currentTheme ==
                                              AppTheme.Dark
                                          ? AppColors.white
                                          : null,
                                    ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            top: 0,
                            right: 0,
                            bottom: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: ThemeManager.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.play_arrow,
                                    size: 16,
                                    color: ThemeManager.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                videoData?.title ?? '',
                                style: interRegular.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: ThemeManager.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${videoData?.pausedTime} left',
                                style: interRegular.copyWith(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: () async {
                              await store.onDeleteHistoryCall(
                                  videoData?.historyId ?? '', 'video');
                            },
                            child: Image.asset(
                              "assets/image/delete.png",
                              height: 30,
                              width: 30,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            margin: const EdgeInsets.all(12),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: ThemeManager.primaryColor,
                              size: 19,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotesList(HomeStore store) {
    if (store.getContinueListData[1]?.pdfResults?.isEmpty ?? true) {
      return _ContinueEmpty(
        title: 'No notes in progress',
        subtitle: 'Notes you open will appear here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
          AppTokens.s24, AppTokens.s16, AppTokens.s24, AppTokens.s24),
      physics: const BouncingScrollPhysics(),
      itemCount: store.getContinueListData[1]?.pdfResults?.length ?? 0,
      itemBuilder: (context, index) {
        PdfTopicDetailModel? pdfData =
            store.getContinueListData[1]?.pdfResults?[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTokens.s12),
          child: InkWell(
            borderRadius: AppTokens.radius16,
            onTap: () => _handleNotesTap(context, pdfData),
            child: Container(
              decoration: BoxDecoration(
                color: AppTokens.surface(context),
                border: Border.all(
                    color: AppTokens.border(context), width: 0.5),
                borderRadius: AppTokens.radius16,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 10,
                    ),
                    Container(
                      height: Dimensions.PADDING_SIZE_LARGE * 3.6,
                      width: Dimensions.PADDING_SIZE_LARGE * 3.6,
                      padding:
                          const EdgeInsets.all(Dimensions.PADDING_SIZE_LARGE),
                      decoration: BoxDecoration(
                        color: ThemeManager.continueContainerTrans,
                        borderRadius: BorderRadius.circular(14.4),
                      ),
                      child: SvgPicture.asset(
                        "assets/image/examsubject.svg",
                        color: ThemeManager.currentTheme == AppTheme.Dark
                            ? AppColors.white
                            : null,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pdfData?.title ?? '',
                              style: interRegular.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: ThemeManager.black,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'You can start from where you left',
                              style: interRegular.copyWith(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        await store.onDeleteHistoryCall(
                            pdfData?.historyId ?? '', 'pdf');
                      },
                      child: Image.asset(
                        "assets/image/delete.png",
                        height: 30,
                        width: 30,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      margin: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: ThemeManager.primaryColor,
                        size: 19,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMCQList(HomeStore store) {
    if (store.getContinueListData[2]?.examResults?.isEmpty ?? true) {
      return _ContinueEmpty(
        title: 'No quizzes in progress',
        subtitle: 'Resume any quiz right from where you paused.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
          AppTokens.s24, AppTokens.s16, AppTokens.s24, AppTokens.s24),
      physics: const BouncingScrollPhysics(),
      itemCount: store.getContinueListData[2]?.examResults?.length ?? 0,
      itemBuilder: (context, index) {
        ExamTopicDetailModel? examData =
            store.getContinueListData[2]?.examResults?[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTokens.s12),
          child: InkWell(
            borderRadius: AppTokens.radius16,
            onTap: () => _handleMCQTap(context, examData),
            child: Container(
              decoration: BoxDecoration(
                color: AppTokens.surface(context),
                borderRadius: AppTokens.radius16,
                border: Border.all(
                    color: AppTokens.border(context), width: 0.5),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 10,
                    ),
                    Container(
                      height: Dimensions.PADDING_SIZE_LARGE * 3.6,
                      width: Dimensions.PADDING_SIZE_LARGE * 3.6,
                      padding:
                          const EdgeInsets.all(Dimensions.PADDING_SIZE_LARGE),
                      decoration: BoxDecoration(
                        color: ThemeManager.continueContainerTrans,
                        borderRadius: BorderRadius.circular(14.4),
                      ),
                      child: SvgPicture.asset(
                        "assets/image/examsubject.svg",
                        color: ThemeManager.currentTheme == AppTheme.Dark
                            ? AppColors.white
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            examData?.examName ?? '',
                            style: interSemiBold.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              fontWeight: FontWeight.w600,
                              color: ThemeManager.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${examData?.totalQuestions ?? 0} Questions Remain',
                            style: interRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              fontWeight: FontWeight.w500,
                              color: ThemeManager.black.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: examData?.isPracticeMode ?? false
                                  ? ThemeManager.blueFinalTrans
                                  : ThemeManager.orangeColor,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              examData?.isPracticeMode ?? false
                                  ? 'Practice mode'
                                  : 'Test mode',
                              style: interSemiBold.copyWith(
                                fontSize: Dimensions.fontSizeExtraSmall,
                                fontWeight: FontWeight.w600,
                                color:
                                    ThemeManager.currentTheme == AppTheme.Light
                                        ? ThemeManager.white
                                        : ThemeManager.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        await store.onDeleteHistoryCall(
                            examData?.historyId ?? '', 'exam');
                      },
                      child: Image.asset(
                        "assets/image/delete.png",
                        height: 30,
                        width: 30,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      margin: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: ThemeManager.primaryColor,
                        size: 19,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleVideoTap(
      BuildContext context, VideoResultsDetailModel? videoData) {
    Navigator.of(context).pushNamed(
      Routes.videoPlayDetail,
      arguments: {
        "topicId": videoData?.topicId,
        "isCompleted": videoData?.isCompleted,
        "videoTopicId": videoData?.topicId,
        'title': videoData?.title ?? '',
        'isDownloaded': false,
        'titleId': videoData?.sId,
        'contentId': videoData?.sId,
        'pauseTime': videoData?.pausedTime,
        'categoryId': videoData?.categoryId,
        'pdfContents': videoData?.pdfcontents,
        'subcategoryId': videoData?.subcategoryId,
        'isBookmark': videoData?.isBookmark,
        'pdfId': videoData?.pdfId,
        'videoPlayUrl': videoData?.videoLink,
        'videoQuality': videoData?.videoFiles,
        'downloadVideoData': videoData?.downloadVideo,
        'annotationData': videoData?.annotation,
        'hlsLink': videoData?.hlsLink,
      },
    );
  }

  void _handleNotesTap(BuildContext context, PdfTopicDetailModel? pdfData) {
    Navigator.of(context).pushNamed(
      Routes.notesReadView,
      arguments: {
        'contentUrl': pdfData?.contentUrl,
        'title': pdfData?.title ?? '',
        'topic_name': pdfData?.topicName ?? '',
        'category_name': pdfData?.categoryName ?? '',
        'subcategory_name': pdfData?.subcategoryName ?? '',
        'annotationData': pdfData?.annotationData?.toString(),
        'isDownloaded': false,
        "isCompleted": pdfData?.isCompleted,
        'topicId': pdfData?.topicId,
        'titleId': pdfData?.sId,
        'categoryId': pdfData?.categoryId,
        'subcategoryId': pdfData?.subcategoryId,
        'isBookMark': pdfData?.isBookmark,
        'pageNo': 0,
      },
    );
  }

  void _handleMCQTap(BuildContext context, ExamTopicDetailModel? examData) {
    Navigator.of(context).pushNamed(
      Routes.showTestScreen,
      arguments: {
        'id': examData?.sId,
        "testExamPaperListModel": TestExamPaperListModel(
          categoryId: examData!.categoryId ?? "",
          declarationTime: examData.declarationTime,
          sid: examData.examId,
          examId: examData.examId,
          examName: examData.examName,
          isAccess: examData.isAccess,
          instruction: examData.instruction,
          isDeclaration: examData.isDeclaration,
          isAttempt: examData.isAttempt,
          isPracticeMode: examData.isPracticeMode ?? false,
          marksAwarded: examData.marksAwarded,
          marksDeducted: examData.marksDeducted,
          fromtime: examData.fromtime,
          negativeMarking: examData.negativeMarking,
          remainingAttempts: examData.remainingAttempts ?? 0,
          isSection: examData.isSection,
          totalQuestions: examData.totalQuestions ?? 0,
          timeDuration: examData.timeDuration,
        ),
        'type': "topic"
      },
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

class _ContinueEmpty extends StatelessWidget {
  const _ContinueEmpty({
    Key? key,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

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
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTokens.surface2(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.schedule_rounded,
                size: 26,
                color: AppTokens.muted(context),
              ),
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
