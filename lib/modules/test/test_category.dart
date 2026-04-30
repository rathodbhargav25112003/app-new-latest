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
import 'package:shusruta_lms/helpers/custom_dynamic_height_gridview.dart';
import 'package:shusruta_lms/models/searched_data_model.dart';
import 'package:shusruta_lms/models/test_category_model.dart';
import 'package:shusruta_lms/modules/customtests/custom_test_lists.dart';
import 'package:shusruta_lms/modules/new-bookmark-flow/new_bookmark_screen1.dart';
import 'package:shusruta_lms/modules/subscriptionplans/store/subscription_store.dart';
import 'package:shusruta_lms/modules/test/status_toggle_widget.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';
import 'package:shusruta_lms/modules/widgets/no_internet_connection.dart';

/// Top-level test catalog — 2-tab screen (MCQ Bank / Custom Module) with
/// status toggle filter and responsive category grid/list.
///
/// Preserved public contract:
///   • `TestCategoryScreen({super.key, this.tabIndex})`
///   • Static `route(RouteSettings)` — no arguments.
///   • `store.onTestApiCall(context)` in initState.
///   • `SubscriptionStore.onGetSubscribedUserPlan()` runs on mount.
///   • `WillPopScope` back → pushes `Routes.dashboard`.
///   • Tab labels verbatim: "MCQ Bank", "Custom Module".
///   • `StatusToggleWidget` options `['All','Completed','Not Started','In
///     Progress']` → `store.statusCategoryFilter(context, v)`.
///   • Bookmark icon → pushes `BookMarkScreen1()` via CupertinoPageRoute.
///   • `buildItem(context, SearchedDataModel?)` navigates to
///     `Routes.testSubjectDetail` / `Routes.testChapterDetail` /
///     `Routes.selectTestList` per `type` field.
///   • `buildItem1(context, TestCategoryModel?)` tap →
///     `Routes.testSubjectDetail` with `{subject: category_name,
///     testid: sid}`.
///   • Attempted extras: "Practice mode" / "Test mode" RichText blocks
///     with "X Questions Solved | Y Total Questions" and
///     "X Tests Attempted | Y Total Test".
///   • `!store.isConnected` → `NoInternetScreen`.
///   • Empty-state copy verbatim.
///   • CustomTestLists rendered in the second tab.
class TestCategoryScreen extends StatefulWidget {
  const TestCategoryScreen({super.key, this.tabIndex});
  final int? tabIndex;

  @override
  State<TestCategoryScreen> createState() => _TestCategoryScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const TestCategoryScreen(),
    );
  }
}

class _TestCategoryScreenState extends State<TestCategoryScreen>
    with SingleTickerProviderStateMixin {
  String filterValue = '';
  final FocusNode _focusNode = FocusNode();
  String query = '';
  TabController? _controller;
  late int tabIndex;

  @override
  void initState() {
    super.initState();
    tabIndex = widget.tabIndex ?? 0;
    setState(() {});
    _controller = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.tabIndex ?? 0,
    );
    _controller?.addListener(() {
      setState(() {
        tabIndex = widget.tabIndex ?? _controller?.index ?? 0;
      });
    });
    _focusNode.addListener(_onFocusChanged);
    _getSubscribedPlan();
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    store.onTestApiCall(context);
  }

  Future<void> _getSubscribedPlan() async {
    final store = Provider.of<SubscriptionStore>(context, listen: false);
    await store.onGetSubscribedUserPlan();
    if (store.subscribedPlan.isEmpty) {
      // Navigator.of(context).pushNamed(Routes.subscriptionList);
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  Future<void> searchCategory(String keyword) async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.onSearchApiCall(keyword, "exam");
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Platform.isWindows || Platform.isMacOS;
    final store = Provider.of<TestCategoryStore>(context);

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushNamed(Routes.dashboard);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTokens.scaffold(context),
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTokens.scaffold(context),
                  borderRadius: isDesktop
                      ? null
                      : const BorderRadius.only(
                          topLeft: Radius.circular(AppTokens.r28),
                          topRight: Radius.circular(AppTokens.r28),
                        ),
                ),
                padding: const EdgeInsets.only(top: AppTokens.s20),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.s20),
                      child: _buildTopTabs(context),
                    ),
                    const SizedBox(height: AppTokens.s16),
                    if (tabIndex == 0) ...[
                      Center(
                        child: StatusToggleWidget(
                          options: const [
                            'All',
                            'Completed',
                            'Not Started',
                            'In Progress',
                          ],
                          onOptionSelected: (v) async {
                            await store.statusCategoryFilter(context, v);
                          },
                        ),
                      ),
                      const SizedBox(height: AppTokens.s8),
                    ],
                    Expanded(
                      child: TabBarView(
                        controller: _controller,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppTokens.s20),
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
                                if (store.filtterTestcategory.isEmpty) {
                                  return _buildEmpty(context);
                                }
                                final bool showSearch =
                                    store.searchList.isNotEmpty &&
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
                                          physics:
                                              const BouncingScrollPhysics(),
                                          itemBuilder: (ctx, i) => buildItem(
                                              ctx, store.searchList[i]),
                                        );
                                }
                                return isDesktop
                                    ? CustomDynamicHeightGridView(
                                        crossAxisCount: 3,
                                        mainAxisSpacing: AppTokens.s12,
                                        itemCount:
                                            store.filtterTestcategory.length,
                                        shrinkWrap: true,
                                        builder: (ctx, i) => buildItem1(
                                            ctx,
                                            store.filtterTestcategory[i]),
                                      )
                                    : ListView.builder(
                                        itemCount:
                                            store.filtterTestcategory.length,
                                        shrinkWrap: true,
                                        padding: EdgeInsets.zero,
                                        physics: const BouncingScrollPhysics(),
                                        itemBuilder: (ctx, i) => buildItem1(
                                            ctx,
                                            store.filtterTestcategory[i]),
                                      );
                              },
                            ),
                          ),
                          const CustomTestLists(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
            onTap: () => Navigator.of(context).pushNamed(Routes.dashboard),
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
              tabIndex == 0 ? "MCQ Bank" : "Custom Module",
              style: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              maxLines: 1,
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

  Widget _buildTopTabs(BuildContext context) {
    return TabBar(
      dividerColor: Colors.transparent,
      controller: _controller,
      labelPadding: EdgeInsets.zero,
      indicator: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.r8),
      ),
      labelColor: AppTokens.ink(context),
      tabs: [
        _buildTopTab(context, "MCQ Bank", selected: tabIndex == 0, leftMargin: 0, rightMargin: 4),
        _buildTopTab(context, "Custom Module",
            selected: tabIndex == 1, leftMargin: 4, rightMargin: 0),
      ],
    );
  }

  Widget _buildTopTab(
    BuildContext context,
    String label, {
    required bool selected,
    required double leftMargin,
    required double rightMargin,
  }) {
    return Container(
      height: 38,
      width: double.infinity,
      alignment: Alignment.center,
      margin: EdgeInsets.only(left: leftMargin, right: rightMargin),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.r8),
        border: selected
            ? null
            : Border.all(color: AppTokens.border(context), width: 0.8),
        color: selected
            ? AppTokens.accent(context)
            : AppTokens.surface(context),
      ),
      child: Text(
        label,
        style: AppTokens.body(context).copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? Colors.white : AppTokens.ink(context),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.s24),
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

  Widget buildItem(BuildContext context, SearchedDataModel? videoCat) {
    SearchedDataModel? examCat = videoCat;
    String? categoryName = examCat?.categoryName;
    String? subcategoryName = examCat?.subcategoryName;
    String? topicName = examCat?.topicName;

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
                "testid": examCat?.id,
              },
            );
          } else if (type == "Subcategory") {
            Navigator.of(context).pushNamed(
              Routes.testChapterDetail,
              arguments: {
                "chapter": subcategoryName,
                "subcatId": examCat?.id,
              },
            );
          } else if (type == "Topic") {
            Navigator.of(context).pushNamed(
              Routes.selectTestList,
              arguments: {'id': examCat?.id, 'type': "topic"},
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
              _TileIcon(asset: "assets/image/noteCategory.svg"),
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
                      examCat?.description ?? "",
                      style: AppTokens.caption(context).copyWith(
                        color: AppTokens.muted(context),
                      ),
                      maxLines: 2,
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

  Widget buildItem1(BuildContext context, TestCategoryModel? testCat) {
    TestCategoryModel? tstCat = testCat;
    if (query.isNotEmpty &&
        (!tstCat!.category_name!.toLowerCase().contains(query.toLowerCase()))) {
      return Container();
    }
    final bool attempted = tstCat?.isAttempt ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.r16),
        onTap: () {
          Navigator.of(context).pushNamed(
            Routes.testSubjectDetail,
            arguments: {
              "subject": tstCat?.category_name,
              "testid": tstCat?.sid,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TileIcon(asset: "assets/image/noteCategory.svg"),
                  const SizedBox(width: AppTokens.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tstCat?.category_name ?? "",
                          style: AppTokens.body(context).copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTokens.ink(context),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppTokens.s4),
                        Text(
                          "${tstCat?.questionCount.toString()} Questions | ${tstCat?.examCount.toString()} Tests",
                          style: AppTokens.caption(context).copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTokens.accent(context),
                          ),
                        ),
                        const SizedBox(height: AppTokens.s4),
                        Text(
                          tstCat?.description ?? "",
                          style: AppTokens.caption(context).copyWith(
                            color: AppTokens.muted(context),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                                  "${tstCat?.practiceAnswersCount.toString()} ",
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
                              text: "${tstCat?.questionCount.toString()} ",
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
                              text: "${tstCat?.userExamCount.toString()} ",
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
                              text: "${tstCat?.examCount.toString()} ",
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
