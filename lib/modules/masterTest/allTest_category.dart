// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_element, avoid_print, use_build_context_synchronously, library_private_types_in_public_api, dead_null_aware_expression

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/custom_dynamic_height_gridview.dart';
import '../../models/searched_data_model.dart';
import '../../models/test_category_model.dart';
import '../new-bookmark-flow/new_bookmark_screen1.dart';
import '../subscriptionplans/store/subscription_store.dart';
import '../test/store/test_category_store.dart';
import '../widgets/no_internet_connection.dart';

/// Mock Exams landing screen — redesigned with AppTokens. Keeps the original
/// TabController wiring (2 tabs → NEET SS + INISS-ET calling
/// `onCategoryMockExams(true,false)` vs `(false,true)`), subscription probe,
/// focus listener, search hook, bookmark push to BookMarkScreen1, and all
/// four item-tap navigation targets (testSubjectDetail / testChapterDetail /
/// selectTestList / chooseTestScreen) fully intact.
class AllTestCategoryScreen extends StatefulWidget {
  const AllTestCategoryScreen({super.key});

  @override
  State<AllTestCategoryScreen> createState() => _AllTestCategoryScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const AllTestCategoryScreen(),
    );
  }
}

class _AllTestCategoryScreenState extends State<AllTestCategoryScreen>
    with SingleTickerProviderStateMixin {
  String filterValue = '';
  final FocusNode _focusNode = FocusNode();
  String query = '';
  TabController? _controller;
  int tabIndex = 0;

  @override
  void initState() {
    super.initState();
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    _controller = TabController(length: 2, vsync: this, initialIndex: tabIndex);
    _controller?.addListener(() {
      setState(() {
        tabIndex = _controller?.index ?? 0;
      });
      if (tabIndex == 0) {
        store.onCategoryMockExams(context, true, false);
      } else if (tabIndex == 1) {
        store.onCategoryMockExams(context, false, true);
      }
    });
    if (tabIndex == 0) {
      store.onCategoryMockExams(context, true, false);
    } else if (tabIndex == 1) {
      store.onCategoryMockExams(context, false, true);
    }
    _focusNode.addListener(_onFocusChanged);
    _getSubscribedPlan();
  }

  Future<void> _getSubscribedPlan() async {
    final store = Provider.of<SubscriptionStore>(context, listen: false);
    await store.onGetSubscribedUserPlan();
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
    final isDesktop = Platform.isWindows || Platform.isMacOS;
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
            _Header(
              title: "Mock Exams",
              onBack: () =>
                  Navigator.of(context).pushNamed(Routes.dashboard),
              onBookmarks: () {
                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (context) => const BookMarkScreen1(),
                ));
              },
            ),
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
                padding: const EdgeInsets.only(top: AppTokens.s16),
                child: Column(
                  children: [
                    _SegmentedTabs(
                      controller: _controller!,
                      tabIndex: tabIndex,
                      labels: const ["NEET SS", "INISS-ET"],
                    ),
                    const SizedBox(height: AppTokens.s12),
                    Expanded(
                      child: TabBarView(
                        controller: _controller,
                        children: [
                          _TestListTab(
                            store: store,
                            query: query,
                            isDesktop: isDesktop,
                            buildSearchItem: buildTab1Item,
                            buildCategoryItem: buildTab1Item1,
                          ),
                          _TestListTab(
                            store: store,
                            query: query,
                            isDesktop: isDesktop,
                            buildSearchItem: buildTab2Item,
                            buildCategoryItem: (c, t, _) => buildTab2Item1(c, t),
                          ),
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

  // ----- search-result tiles -----

  Widget buildTab1Item(
      BuildContext context, SearchedDataModel? mockTestSearchCat) {
    return _SearchResultTile(
      examCat: mockTestSearchCat,
      onTap: () => _navigateFromSearch(context, mockTestSearchCat),
    );
  }

  Widget buildTab2Item(
      BuildContext context, SearchedDataModel? searchCont) {
    return _SearchResultTile(
      examCat: searchCont,
      onTap: () => _navigateFromSearch(context, searchCont),
    );
  }

  void _navigateFromSearch(BuildContext context, SearchedDataModel? examCat) {
    final categoryName = examCat?.categoryName;
    final subcategoryName = examCat?.subcategoryName;

    final type = categoryName != null
        ? "Category"
        : subcategoryName != null
            ? "Subcategory"
            : "Topic";

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
  }

  // ----- category tiles -----

  Widget buildTab1Item1(
      BuildContext context, TestCategoryModel? testCat, bool isTrend) {
    final tstCat = testCat;
    if (query.isNotEmpty &&
        (!tstCat!.category_name!
            .toLowerCase()
            .contains(query.toLowerCase()))) {
      return const SizedBox.shrink();
    }
    return _CategoryTile(
      testCat: tstCat,
      onTap: () {
        Navigator.of(context).pushNamed(
          Routes.chooseTestScreen,
          arguments: {
            'id': tstCat!.sId,
            'type': "topic",
            'showPredictive': true,
            'isTrend': isTrend,
          },
        );
      },
    );
  }

  Widget buildTab2Item1(BuildContext context, TestCategoryModel? testCat) {
    final tstCat = testCat;
    if (query.isNotEmpty &&
        (!tstCat!.category_name!
            .toLowerCase()
            .contains(query.toLowerCase()))) {
      return const SizedBox.shrink();
    }
    return _CategoryTile(
      testCat: tstCat,
      onTap: () {
        Navigator.of(context).pushNamed(
          Routes.chooseTestScreen,
          arguments: {
            'id': tstCat!.sId,
            'type': "topic",
            'showPredictive': true,
            'isTrend': tstCat.isSeries,
          },
        );
      },
    );
  }
}

// ============================================================
//                        Primitives
// ============================================================

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.onBack,
    required this.onBookmarks,
  });
  final String title;
  final VoidCallback onBack;
  final VoidCallback onBookmarks;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTokens.s8,
        MediaQuery.of(context).padding.top + AppTokens.s12,
        AppTokens.s16,
        AppTokens.s20,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTokens.brand, AppTokens.brand2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTokens.brand.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _CircleBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  AppTokens.titleMd(context).copyWith(color: Colors.white),
            ),
          ),
          _CircleBtn(
            icon: Icons.bookmark_border_rounded,
            onTap: onBookmarks,
          ),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.16),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s16),
      child: Container(
        padding: const EdgeInsets.all(AppTokens.s4),
        decoration: BoxDecoration(
          color: AppTokens.surface2(context),
          borderRadius: AppTokens.radius12,
          border: Border.all(color: AppTokens.border(context)),
        ),
        child: TabBar(
          controller: controller,
          dividerColor: Colors.transparent,
          labelPadding: EdgeInsets.zero,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTokens.brand, AppTokens.brand2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppTokens.radius8,
            boxShadow: AppTokens.shadow1(context),
          ),
          indicatorPadding: EdgeInsets.zero,
          labelColor: Colors.white,
          unselectedLabelColor: AppTokens.ink2(context),
          labelStyle: AppTokens.titleSm(context),
          unselectedLabelStyle: AppTokens.body(context).copyWith(
            fontWeight: FontWeight.w600,
          ),
          splashBorderRadius: AppTokens.radius8,
          overlayColor:
              MaterialStateProperty.all(AppTokens.accentSoft(context)),
          tabs: [
            for (final l in labels)
              Tab(
                height: 36,
                child: Text(l),
              ),
          ],
        ),
      ),
    );
  }
}

class _TestListTab extends StatelessWidget {
  const _TestListTab({
    required this.store,
    required this.query,
    required this.isDesktop,
    required this.buildSearchItem,
    required this.buildCategoryItem,
  });

  final TestCategoryStore store;
  final String query;
  final bool isDesktop;
  final Widget Function(BuildContext, SearchedDataModel?) buildSearchItem;
  final Widget Function(BuildContext, TestCategoryModel?, bool)
      buildCategoryItem;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s16),
      child: Observer(
        builder: (_) {
          if (store.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: AppTokens.accent(context),
              ),
            );
          }
          if (!store.isConnected) {
            return const NoInternetScreen();
          }
          if (store.alltestcategory.isEmpty) {
            return const _EmptyTests();
          }

          final showSearch = store.searchList.isNotEmpty && query.isNotEmpty;

          if (showSearch) {
            return isDesktop
                ? CustomDynamicHeightGridView(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    itemCount: store.searchList.length,
                    builder: (_, int index) =>
                        buildSearchItem(context, store.searchList[index]),
                  )
                : ListView.builder(
                    itemCount: store.searchList.length,
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (_, int index) =>
                        buildSearchItem(context, store.searchList[index]),
                  );
          }

          return isDesktop
              ? CustomDynamicHeightGridView(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  itemCount: store.alltestcategory.length,
                  shrinkWrap: true,
                  builder: (_, int index) => buildCategoryItem(
                    context,
                    store.alltestcategory[index],
                    store.alltestcategory[index]!.isSeries ?? false,
                  ),
                )
              : ListView.builder(
                  itemCount: store.alltestcategory.length,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (_, int index) => buildCategoryItem(
                    context,
                    store.alltestcategory[index],
                    store.alltestcategory[index]!.isSeries ?? false,
                  ),
                );
        },
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.examCat, required this.onTap});
  final SearchedDataModel? examCat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final categoryName = examCat?.categoryName;
    final subcategoryName = examCat?.subcategoryName;
    final topicName = examCat?.topicName;

    final displayText = categoryName ?? subcategoryName ?? topicName ?? "";
    final type = categoryName != null
        ? "Category"
        : subcategoryName != null
            ? "Subcategory"
            : "Topic";

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s8),
      child: Material(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius12,
        child: InkWell(
          borderRadius: AppTokens.radius12,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppTokens.s12),
            decoration: BoxDecoration(
              border: Border.all(color: AppTokens.border(context)),
              borderRadius: AppTokens.radius12,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTokens.titleSm(context),
                      ),
                      if ((examCat?.description ?? "").isNotEmpty) ...[
                        const SizedBox(height: AppTokens.s4),
                        Text(
                          examCat?.description ?? "",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTokens.caption(context).copyWith(
                            color: AppTokens.ink2(context),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppTokens.s4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.s8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTokens.accentSoft(context),
                          borderRadius: BorderRadius.circular(64),
                        ),
                        child: Text(
                          type,
                          style: AppTokens.caption(context).copyWith(
                            color: AppTokens.accent(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTokens.ink2(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.testCat, required this.onTap});
  final TestCategoryModel? testCat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s8),
      child: Material(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius12,
        child: InkWell(
          borderRadius: AppTokens.radius12,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppTokens.s12),
            decoration: BoxDecoration(
              border: Border.all(color: AppTokens.border(context)),
              borderRadius: AppTokens.radius12,
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
                        testCat?.category_name ?? "",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTokens.titleSm(context),
                      ),
                      const SizedBox(height: AppTokens.s4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTokens.s8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTokens.accentSoft(context),
                              borderRadius: BorderRadius.circular(64),
                            ),
                            child: Text(
                              "${testCat!.examCount} Exams",
                              style: AppTokens.caption(context).copyWith(
                                color: AppTokens.accent(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if ((testCat?.description ?? "").isNotEmpty) ...[
                        const SizedBox(height: AppTokens.s4),
                        Text(
                          testCat?.description ?? "",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTokens.caption(context).copyWith(
                            color: AppTokens.ink2(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTokens.ink2(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  const _TileIcon({required this.asset});
  final String asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.accentSoft(context),
        borderRadius: AppTokens.radius12,
      ),
      child: SvgPicture.asset(
        asset,
        color: AppTokens.accent(context),
      ),
    );
  }
}

class _EmptyTests extends StatelessWidget {
  const _EmptyTests();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s24),
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
                Icons.quiz_outlined,
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
