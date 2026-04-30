// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_element, avoid_print, use_build_context_synchronously, library_private_types_in_public_api, non_constant_identifier_names

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/helpers/custom_dynamic_height_gridview.dart';
import 'package:shusruta_lms/models/test_category_model.dart';
import 'package:shusruta_lms/modules/masterTest/leaderboard_examlist_screen.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../models/searched_data_model.dart';
import '../widgets/no_internet_connection.dart';

/// Leaderboard category screen — redesigned with AppTokens. Preserves:
///   • Constructor `LeaderBoardCategoryScreen({super.key, this.isHome = false})`
///   • Static route factory
///   • `SingleTickerProviderStateMixin` + `TabController(length: 2)`
///   • State: `filterValue`, `_focusNode`, `query`, `tabIndex`,
///     `_testCategories` with NEET SS / INISS-ET toggle via `isNeetSS`
///   • initState: `store.getLeaderBoardCategoryList(context)` + tab listener
///   • `WillPopScope` → `Navigator.pop`
///   • Tab1 (NEET SS) / Tab2 (INISS-ET) filtering from
///     `store.alltestcategoryLeaderBoard`
///   • Desktop `CustomDynamicHeightGridView(crossAxisCount: 3)` vs
///     mobile `ListView.builder(physics: BouncingScrollPhysics())`
///   • `NoInternetScreen()` when `!store.isConnected`
///   • `buildTab1Item(context, SearchedDataModel?)` → testSubjectDetail / testChapterDetail / selectTestList
///   • `buildTab1Item1(context, TestCategoryModel?)` → AllLeaderBoardSelectTestList(id: category_id) via CupertinoPageRoute
///   • `buildTab2Item(context, SearchedDataModel?)` / `buildTab2Item1(context, TestCategoryModel?)` (legacy, kept)
class LeaderBoardCategoryScreen extends StatefulWidget {
  const LeaderBoardCategoryScreen({super.key, this.isHome = false});
  final bool isHome;

  @override
  State<LeaderBoardCategoryScreen> createState() =>
      _LeaderBoardCategoryScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const LeaderBoardCategoryScreen(),
    );
  }
}

class _LeaderBoardCategoryScreenState extends State<LeaderBoardCategoryScreen>
    with SingleTickerProviderStateMixin {
  String filterValue = '';
  final FocusNode _focusNode = FocusNode();
  String query = '';
  TabController? _controller;
  int tabIndex = 0;
  List<TestCategoryModel?> _testCategories = [];

  @override
  void initState() {
    super.initState();
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    store.getLeaderBoardCategoryList(context);
    _controller = TabController(length: 2, vsync: this, initialIndex: tabIndex);
    _controller?.addListener(() {
      setState(() {
        tabIndex = _controller?.index ?? 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Platform.isWindows || Platform.isMacOS;
    final store = Provider.of<TestCategoryStore>(context);

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTokens.scaffold(context),
        body: Column(
          children: [
            // ---------------------------------------------------
            // Header (gradient)
            // ---------------------------------------------------
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTokens.brand, AppTokens.brand2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: EdgeInsets.only(
                top: isDesktop
                    ? AppTokens.s24
                    : MediaQuery.of(context).padding.top + AppTokens.s8,
                left: AppTokens.s16,
                right: AppTokens.s16,
                bottom: AppTokens.s16,
              ),
              child: Row(
                children: [
                  if (Navigator.canPop(context)) ...[
                    _CircleBtn(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: AppTokens.s12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Leaderboard",
                          style: AppTokens.overline(context).copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Exam Category",
                          style: AppTokens.titleMd(context)
                              .copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ---------------------------------------------------
            // Body
            // ---------------------------------------------------
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTokens.scaffold(context),
                  borderRadius: isDesktop
                      ? null
                      : const BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.s16,
                    AppTokens.s16,
                    AppTokens.s16,
                    0,
                  ),
                  child: Observer(builder: (context) {
                    if (store.isLoading) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: AppTokens.accent(context),
                        ),
                      );
                    }
                    if (!store.isLoading) {
                      if (tabIndex == 0) {
                        _testCategories = store.alltestcategoryLeaderBoard
                            .where((category) => category!.isNeetSS == true)
                            .toList();
                      } else if (tabIndex == 1) {
                        _testCategories = store.alltestcategoryLeaderBoard
                            .where((category) => category!.isNeetSS == false)
                            .toList();
                      }
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SegmentedTabs(
                          controller: _controller!,
                          tabIndex: tabIndex,
                          labels: const ["NEET SS", "INISS-ET"],
                        ),
                        const SizedBox(height: AppTokens.s16),
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
                              if (store.alltestcategoryLeaderBoard.isEmpty) {
                                return _EmptyState();
                              }
                              return store.isConnected
                                  ? isDesktop
                                      ? CustomDynamicHeightGridView(
                                          crossAxisCount: 3,
                                          mainAxisSpacing: 10,
                                          itemCount: _testCategories.length,
                                          shrinkWrap: true,
                                          builder: (BuildContext context,
                                              int index) {
                                            return buildTab1Item1(
                                                context,
                                                _testCategories[index]);
                                          },
                                        )
                                      : ListView.builder(
                                          itemCount: _testCategories.length,
                                          shrinkWrap: true,
                                          padding: const EdgeInsets.only(
                                              bottom: AppTokens.s24),
                                          physics:
                                              const BouncingScrollPhysics(),
                                          itemBuilder: (BuildContext context,
                                              int index) {
                                            return buildTab1Item1(
                                                context,
                                                _testCategories[index]);
                                          },
                                        )
                                  : const NoInternetScreen();
                            },
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  Preserved helpers
  // ============================================================

  Widget buildTab1Item(
      BuildContext context, SearchedDataModel? mockTestSearchCat) {
    final SearchedDataModel? examCat = mockTestSearchCat;
    final String? categoryName = examCat?.categoryName;
    final String? subcategoryName = examCat?.subcategoryName;
    final String? topicName = examCat?.topicName;

    final String displayText =
        categoryName ?? subcategoryName ?? topicName ?? "";
    final String type = categoryName != null
        ? "Category"
        : subcategoryName != null
            ? "Subcategory"
            : "Topic";

    return _CategoryTile(
      title: displayText,
      subtitle: examCat?.description ?? "",
      badge: type,
      onTap: () {
        if (type == "Category") {
          Navigator.of(context).pushNamed(
            Routes.testSubjectDetail,
            arguments: {"subject": categoryName, "testid": examCat?.id},
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
    );
  }

  Widget buildTab1Item1(BuildContext context, TestCategoryModel? testCat) {
    final TestCategoryModel? tstCat = testCat;
    print(tstCat!.description);
    if (query.isNotEmpty &&
        (!tstCat.category_name!.toLowerCase().contains(query.toLowerCase()))) {
      return Container();
    }
    return _CategoryTile(
      title: tstCat.category_name ?? "",
      subtitle: tstCat.description ?? "",
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => AllLeaderBoardSelectTestList(
              id: tstCat.category_id!,
            ),
          ),
        );
      },
    );
  }

  Widget buildTab2Item(BuildContext context, SearchedDataModel? searchCont) {
    final SearchedDataModel? examCat = searchCont;
    final String? categoryName = examCat?.categoryName;
    final String? subcategoryName = examCat?.subcategoryName;
    final String? topicName = examCat?.topicName;

    final String displayText =
        categoryName ?? subcategoryName ?? topicName ?? "";
    final String type = categoryName != null
        ? "Category"
        : subcategoryName != null
            ? "Subcategory"
            : "Topic";
    return _CategoryTile(
      title: displayText,
      subtitle: examCat?.description ?? "",
      badge: type,
      onTap: () {
        if (type == "Category") {
          Navigator.of(context).pushNamed(
            Routes.testSubjectDetail,
            arguments: {"subject": categoryName, "testid": examCat?.id},
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
    );
  }

  Widget buildTab2Item1(BuildContext context, TestCategoryModel? testCat) {
    final TestCategoryModel? tstCat = testCat;
    if (query.isNotEmpty &&
        (!tstCat!.category_name!.toLowerCase().contains(query.toLowerCase()))) {
      return Container();
    }
    return _CategoryTile(
      title: tstCat?.category_name ?? "",
      subtitle: tstCat?.description ?? "",
      onTap: () {
        Navigator.of(context).pushNamed(
          Routes.allSelectTestList,
          arguments: {'id': tstCat?.sId, 'type': "topic"},
        );
      },
    );
  }
}

// ============================================================
//                        Primitives
// ============================================================

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.15),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.controller,
    required this.tabIndex,
    required this.labels,
  });
  final TabController controller;
  final int tabIndex;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s4),
      decoration: BoxDecoration(
        color: AppTokens.surface2(context),
        borderRadius: BorderRadius.circular(64),
        border: Border.all(color: AppTokens.border(context)),
      ),
      child: TabBar(
        controller: controller,
        indicatorSize: TabBarIndicatorSize.tab,
        labelPadding: EdgeInsets.zero,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTokens.brand, AppTokens.brand2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(64),
          boxShadow: AppTokens.shadow1(context),
        ),
        splashBorderRadius: BorderRadius.circular(64),
        labelColor: Colors.white,
        unselectedLabelColor: AppTokens.ink2(context),
        labelStyle: AppTokens.titleSm(context),
        unselectedLabelStyle: AppTokens.body(context),
        tabs: labels
            .map((l) => Tab(
                  height: 38,
                  child: Center(child: Text(l)),
                ))
            .toList(),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.title,
    required this.subtitle,
    this.badge,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s12),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppTokens.radius16,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppTokens.s16),
            decoration: BoxDecoration(
              color: AppTokens.surface(context),
              borderRadius: AppTokens.radius16,
              border: Border.all(color: AppTokens.border(context)),
              boxShadow: AppTokens.shadow1(context),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(AppTokens.s12),
                  decoration: BoxDecoration(
                    color: AppTokens.accentSoft(context),
                    borderRadius: AppTokens.radius12,
                  ),
                  child: SvgPicture.asset(
                    "assets/image/noteCategory.svg",
                    colorFilter: ColorFilter.mode(
                      AppTokens.accent(context),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTokens.titleSm(context),
                      ),
                      if (subtitle.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTokens.body(context).copyWith(
                            color: AppTokens.ink2(context),
                          ),
                        ),
                      ],
                      if (badge != null) ...[
                        const SizedBox(height: AppTokens.s8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.s8,
                            vertical: AppTokens.s4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTokens.accentSoft(context),
                            borderRadius: BorderRadius.circular(64),
                          ),
                          child: Text(
                            badge!,
                            style: AppTokens.caption(context).copyWith(
                              color: AppTokens.accent(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTokens.muted(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppTokens.accentSoft(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.leaderboard_rounded,
                color: AppTokens.accent(context),
                size: 36,
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              "Nothing here yet",
              textAlign: TextAlign.center,
              style: AppTokens.titleSm(context),
            ),
            const SizedBox(height: AppTokens.s4),
            Text(
              "We're sorry, there's no content available right now. Please check back later or explore other sections for more educational resources.",
              textAlign: TextAlign.center,
              style: AppTokens.body(context).copyWith(
                color: AppTokens.ink2(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
