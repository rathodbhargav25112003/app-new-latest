// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters, unused_field, unused_local_variable, non_constant_identifier_names, dead_code

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/models/searched_data_model.dart';
import 'package:shusruta_lms/models/test_subcategory_model.dart';
import 'package:shusruta_lms/helpers/custom_dynamic_height_gridview.dart';
import 'package:shusruta_lms/modules/new-bookmark-flow/new_bookmark_screen1.dart';
import 'package:shusruta_lms/modules/test/status_toggle_widget.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';
import 'package:shusruta_lms/modules/widgets/no_internet_connection.dart';

/// Subcategory listing inside a subject/category — status toggle filter
/// plus subcategory cards (or active search results tiles).
///
/// Preserved public contract:
///   • `TestsSubjectDetail({super.key, required subject, testid})`
///   • Static `route(RouteSettings)` reads `{subject, testid}`.
///   • `store.onSubCategoryApiCall(testid!)` in initState.
///   • `searchCategory(keyword)` → `store.onSearchApiCall(keyword,
///     "exam")`.
///   • `StatusToggleWidget` options `['All','Completed','Not Started','In
///     Progress']` → `store.statusSubCategoryFilter(context, v)`.
///   • Bookmark icon → pushes `BookMarkScreen1()` via CupertinoPageRoute.
///   • `buildItem(context, SearchedDataModel?)` — search results list.
///       - Category tap → `Routes.testSubjectDetail` with
///         `{subject: categoryName, testid: id}`.
///       - Subcategory tap → `Routes.testChapterDetail` with
///         `{chapter: subcategoryName, subcatId: id}`.
///       - Topic tap → `Routes.selectTestList` with
///         `{id, type: "topic"}`.
///   • `buildItem1(context, TestSubCategoryModel?)` — subcategory tiles.
///       - Tap → `Routes.testChapterDetail` with `{chapter:
///         widget.subject, subcatId: tstSubCat.sid}`.
///   • Status mapping: same as chapter/topic tiles.
///   • `!store.isConnected` → `NoInternetScreen`.
///   • Empty-state copy verbatim.
class TestsSubjectDetail extends StatefulWidget {
  final String subject;
  final String? testid;
  const TestsSubjectDetail({super.key, required this.subject, this.testid});

  @override
  State<TestsSubjectDetail> createState() => _TestsSubjectDetailState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => TestsSubjectDetail(
        subject: arguments['subject'],
        testid: arguments['testid'],
      ),
    );
  }
}

class _TestsSubjectDetailState extends State<TestsSubjectDetail> {
  String query = '';

  @override
  void initState() {
    super.initState();
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    store.onSubCategoryApiCall(widget.testid!);
  }

  Future<void> searchCategory(String keyword) async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.onSearchApiCall(keyword, "exam");
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Platform.isWindows || Platform.isMacOS;
    final store = Provider.of<TestCategoryStore>(context, listen: false);

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s20,
                AppTokens.s20,
                AppTokens.s20,
                AppTokens.s12,
              ),
              decoration: BoxDecoration(
                color: AppTokens.scaffold(context),
                borderRadius: isDesktop
                    ? null
                    : const BorderRadius.only(
                        topLeft: Radius.circular(AppTokens.r28),
                        topRight: Radius.circular(AppTokens.r28),
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: StatusToggleWidget(
                      options: const [
                        'All',
                        'Completed',
                        'Not Started',
                        'In Progress',
                      ],
                      onOptionSelected: (v) {
                        store.statusSubCategoryFilter(context, v);
                      },
                    ),
                  ),
                  const SizedBox(height: AppTokens.s16),
                  Expanded(
                    child: Observer(
                      builder: (_) {
                        if (!store.isConnected) {
                          return const NoInternetScreen();
                        }
                        if (store.isLoading) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: AppTokens.accent(context),
                            ),
                          );
                        }
                        if (store.filtterTestSubcategory.isEmpty) {
                          return _buildEmpty(context);
                        }
                        final bool showSearch = store.searchList.isNotEmpty &&
                            query.isNotEmpty;

                        if (showSearch) {
                          return isDesktop
                              ? CustomDynamicHeightGridView(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: AppTokens.s12,
                                  itemCount: store.searchList.length,
                                  builder: (ctx, i) => buildItem(
                                      ctx, store.searchList[i]),
                                )
                              : ListView.builder(
                                  itemCount: store.searchList.length,
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  physics: const BouncingScrollPhysics(),
                                  itemBuilder: (ctx, i) => buildItem(
                                      ctx, store.searchList[i]),
                                );
                        }
                        return isDesktop
                            ? CustomDynamicHeightGridView(
                                crossAxisCount: 3,
                                mainAxisSpacing: AppTokens.s12,
                                itemCount: store.filtterTestSubcategory.length,
                                builder: (ctx, i) => buildItem1(
                                    ctx, store.filtterTestSubcategory[i]),
                              )
                            : ListView.builder(
                                itemCount: store.filtterTestSubcategory.length,
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                physics: const BouncingScrollPhysics(),
                                itemBuilder: (ctx, i) => buildItem1(
                                    ctx, store.filtterTestSubcategory[i]),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTokens.s8,
        (Platform.isWindows || Platform.isMacOS)
            ? AppTokens.s16
            : MediaQuery.of(context).padding.top + AppTokens.s8,
        AppTokens.s20,
        AppTokens.s20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTokens.brand, AppTokens.brand2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(AppTokens.r8),
            child: Container(
              height: AppTokens.s32,
              width: AppTokens.s32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTokens.r8),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Text(
              widget.subject,
              style: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          InkWell(
            onTap: () {
              Navigator.of(context).push(CupertinoPageRoute(
                builder: (context) => const BookMarkScreen1(),
              ));
            },
            borderRadius: BorderRadius.circular(AppTokens.r8),
            child: Container(
              height: AppTokens.s32,
              width: AppTokens.s32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTokens.r8),
              ),
              child: const Icon(
                Icons.bookmark_border,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s24),
        child: Text(
          "We're sorry, there's no content available right now. Please check back later or explore other sections for more educational resources.",
          textAlign: TextAlign.center,
          style: AppTokens.body(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppTokens.ink(context),
          ),
        ),
      ),
    );
  }

  Widget buildItem(BuildContext context, SearchedDataModel? searchCat) {
    SearchedDataModel? examSubcat = searchCat;
    String? categoryName = examSubcat?.categoryName;
    String? subcategoryName = examSubcat?.subcategoryName;
    String? topicName = examSubcat?.topicName;

    String displayText = categoryName ?? subcategoryName ?? topicName ?? "";
    String type = categoryName != null
        ? "Category"
        : subcategoryName != null
            ? "Subcategory"
            : "Topic";

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.r16),
        onTap: () {
          if (type == "Category") {
            Navigator.of(context).pushNamed(
              Routes.testSubjectDetail,
              arguments: {
                "subject": categoryName,
                "testid": examSubcat?.id,
              },
            );
          } else if (type == "Subcategory") {
            Navigator.of(context).pushNamed(
              Routes.testChapterDetail,
              arguments: {
                "chapter": subcategoryName,
                "subcatId": examSubcat?.id,
              },
            );
          } else if (type == "Topic") {
            Navigator.of(context).pushNamed(
              Routes.selectTestList,
              arguments: {'id': examSubcat?.id, 'type': "topic"},
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(AppTokens.s16),
          decoration: BoxDecoration(
            color: AppTokens.surface(context),
            border: Border.all(color: AppTokens.border(context)),
            borderRadius: BorderRadius.circular(AppTokens.r16),
          ),
          child: Row(
            children: [
              _TileIcon(asset: "assets/image/examsubject.svg"),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayText,
                      style: AppTokens.body(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTokens.ink(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTokens.s4),
                    Text(
                      examSubcat?.description ?? "",
                      style: AppTokens.caption(context).copyWith(
                        color: AppTokens.muted(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTokens.s4),
                    Text(
                      type,
                      style: AppTokens.caption(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTokens.accent(context),
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

  Widget buildItem1(BuildContext context, TestSubCategoryModel? testCatModel) {
    TestSubCategoryModel? tstSubCat = testCatModel;
    if (query.isNotEmpty &&
        (!tstSubCat!.subcategory_name!
            .toLowerCase()
            .contains(query.toLowerCase()))) {
      return Container();
    }

    final bool attempted = tstSubCat?.isAttempt ?? false;
    final bool completed = tstSubCat?.isCompleted ?? false;
    final String statusAsset = (attempted && !completed)
        ? "assets/image/inprogress.svg"
        : (attempted && completed)
            ? "assets/image/correct_i.svg"
            : "assets/image/cross.svg";
    final String statusLabel = (attempted && !completed)
        ? "In progress"
        : (attempted && completed)
            ? "Completed"
            : "Not Started";

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.r16),
        onTap: () {
          Navigator.of(context).pushNamed(
            Routes.testChapterDetail,
            arguments: {
              "chapter": widget.subject,
              "subcatId": tstSubCat?.sid,
            },
          );
        },
        child: Container(
          constraints: (Platform.isMacOS || Platform.isWindows)
              ? const BoxConstraints(minHeight: 187)
              : null,
          padding: const EdgeInsets.all(AppTokens.s16),
          decoration: BoxDecoration(
            color: AppTokens.surface(context),
            border: Border.all(color: AppTokens.border(context)),
            borderRadius: BorderRadius.circular(AppTokens.r16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _TileIcon(asset: "assets/image/examsubject.svg"),
                  const SizedBox(width: AppTokens.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tstSubCat?.subcategory_name ?? "",
                          style: AppTokens.body(context).copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTokens.ink(context),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppTokens.s4),
                        Text(
                          "${testCatModel?.questionCount.toString()} Questions | ${testCatModel?.examCount.toString()} Tests",
                          style: AppTokens.caption(context).copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTokens.accent(context),
                          ),
                        ),
                        const SizedBox(height: AppTokens.s4),
                        Text(
                          tstSubCat?.description ?? "",
                          style: AppTokens.caption(context).copyWith(
                            color: AppTokens.muted(context),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppTokens.s8),
                        Row(
                          children: [
                            SvgPicture.asset(statusAsset, height: 14, width: 14),
                            const SizedBox(width: AppTokens.s4),
                            Text(
                              statusLabel,
                              style: AppTokens.caption(context).copyWith(
                                fontWeight: FontWeight.w500,
                                color: AppTokens.muted(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (attempted) ...[
                const SizedBox(height: AppTokens.s12),
                Divider(
                  height: 1,
                  color: AppTokens.border(context),
                ),
                const SizedBox(height: AppTokens.s12),
                Text(
                  "Practice mode",
                  style: AppTokens.caption(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTokens.ink(context),
                  ),
                ),
                const SizedBox(height: AppTokens.s4),
                Row(
                  children: [
                    SvgPicture.asset(
                      "assets/image/note3.svg",
                      height: 16,
                      width: 16,
                    ),
                    const SizedBox(width: AppTokens.s4),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  "${testCatModel?.practiceAnswersCount.toString()} ",
                              style: AppTokens.caption(context).copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTokens.ink(context),
                              ),
                            ),
                            TextSpan(
                              text: "Questions Solved  |  ",
                              style: AppTokens.caption(context).copyWith(
                                color: AppTokens.muted(context),
                              ),
                            ),
                            TextSpan(
                              text:
                                  "${testCatModel?.questionCount.toString()} ",
                              style: AppTokens.caption(context).copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTokens.ink(context),
                              ),
                            ),
                            TextSpan(
                              text: "Total Questions",
                              style: AppTokens.caption(context).copyWith(
                                color: AppTokens.muted(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s8),
                Text(
                  "Test mode",
                  style: AppTokens.caption(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTokens.ink(context),
                  ),
                ),
                const SizedBox(height: AppTokens.s4),
                Row(
                  children: [
                    SvgPicture.asset(
                      "assets/image/question2.svg",
                      height: 16,
                      width: 16,
                    ),
                    const SizedBox(width: AppTokens.s4),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  "${testCatModel?.userExamCount.toString()} ",
                              style: AppTokens.caption(context).copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTokens.ink(context),
                              ),
                            ),
                            TextSpan(
                              text: "Tests Attempted  |  ",
                              style: AppTokens.caption(context).copyWith(
                                color: AppTokens.muted(context),
                              ),
                            ),
                            TextSpan(
                              text: "${testCatModel?.examCount.toString()} ",
                              style: AppTokens.caption(context).copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTokens.ink(context),
                              ),
                            ),
                            TextSpan(
                              text: "Total Test",
                              style: AppTokens.caption(context).copyWith(
                                color: AppTokens.muted(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  final String asset;
  const _TileIcon({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: 56,
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.accentSoft(context),
        borderRadius: BorderRadius.circular(AppTokens.r16),
      ),
      child: SvgPicture.asset(
        asset,
        color: AppTokens.accent(context),
      ),
    );
  }
}
