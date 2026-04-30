// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_element, avoid_print, use_build_context_synchronously, library_private_types_in_public_api, non_constant_identifier_names

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/helpers/custom_dynamic_height_gridview.dart';
import 'package:shusruta_lms/modules/reports/rank_list_screen.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';

import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../models/test_exampaper_list_model.dart';
import '../widgets/no_internet_connection.dart';

/// Leaderboard exam list screen — redesigned with AppTokens.
/// Preserves:
///   • Constructor `AllLeaderBoardSelectTestList({super.key, required id})`
///   • State: `_focusNode`, `query`, `_onFocusChanged`
///   • initState: focus listener + `store.onAllLeaderboardTestExamByCategoryApiCall(widget.id)`
///   • Desktop `CustomDynamicHeightGridView(crossAxisCount: 3)` vs
///     mobile `ListView.builder(physics: BouncingScrollPhysics())`
///   • `NoInternetScreen()` when `!store.isConnected`
///   • `buildItem(context, TestExamPaperListModel?)` → pushes
///     `RankListScreen(examId: testExamPaper!.examId!)` via CupertinoPageRoute
class AllLeaderBoardSelectTestList extends StatefulWidget {
  final String id;

  const AllLeaderBoardSelectTestList({super.key, required this.id});

  @override
  State<AllLeaderBoardSelectTestList> createState() =>
      _AllLeaderBoardSelectTestListState();
}

class _AllLeaderBoardSelectTestListState
    extends State<AllLeaderBoardSelectTestList> {
  final FocusNode _focusNode = FocusNode();
  String query = '';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    store.onAllLeaderboardTestExamByCategoryApiCall(widget.id);
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Platform.isWindows || Platform.isMacOS;
    final store = Provider.of<TestCategoryStore>(context);

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          // ---------------------------------------------------
          // Header
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
            child: Column(
              children: [
                Row(
                  children: [
                    _CircleBtn(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: AppTokens.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Leaderboard",
                            style: AppTokens.overline(context)
                                .copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Choose Test",
                            style: AppTokens.titleMd(context)
                                .copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s16),
                _TestsCountChip(),
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
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s16,
                AppTokens.s20,
                AppTokens.s16,
                0,
              ),
              child: Observer(
                builder: (_) {
                  if (store.isLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppTokens.accent(context),
                      ),
                    );
                  }
                  if (store.alltestexam.isEmpty) {
                    return _EmptyState();
                  }
                  return store.isConnected
                      ? isDesktop
                          ? CustomDynamicHeightGridView(
                              crossAxisCount: 3,
                              mainAxisSpacing: 10,
                              itemCount: store.alltestexam.length,
                              builder: (BuildContext context, int index) {
                                return buildItem(
                                    context, store.alltestexam[index]);
                              },
                            )
                          : ListView.builder(
                              itemCount: store.alltestexam.length,
                              shrinkWrap: true,
                              padding: const EdgeInsets.only(
                                  bottom: AppTokens.s24),
                              physics: const BouncingScrollPhysics(),
                              itemBuilder:
                                  (BuildContext context, int index) {
                                return buildItem(
                                    context, store.alltestexam[index]);
                              },
                            )
                      : const NoInternetScreen();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------
  //  Preserved item builder
  // --------------------------------------------------------------
  Widget buildItem(
      BuildContext context, TestExamPaperListModel? testExamPaperListModel) {
    final TestExamPaperListModel? testExamPaper = testExamPaperListModel;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s12),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppTokens.radius16,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) =>
                    RankListScreen(examId: testExamPaper!.examId!),
              ),
            );
          },
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
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(AppTokens.s12),
                  decoration: BoxDecoration(
                    color: AppTokens.accentSoft(context),
                    borderRadius: AppTokens.radius12,
                  ),
                  child: Icon(
                    Icons.leaderboard_rounded,
                    color: AppTokens.accent(context),
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        testExamPaper?.examName ?? "",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTokens.titleSm(context),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.emoji_events_outlined,
                            size: 14,
                            color: AppTokens.muted(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "View ranks & scores",
                            style: AppTokens.caption(context),
                          ),
                        ],
                      ),
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

class _TestsCountChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: AppTokens.radius12,
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            padding: const EdgeInsets.all(AppTokens.s8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: AppTokens.radius8,
            ),
            child: SvgPicture.asset(
              "assets/image/choosetest.svg",
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Tests",
                style: AppTokens.caption(context)
                    .copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 2),
              Observer(builder: (context) {
                final store = Provider.of<TestCategoryStore>(context);
                return Text(
                  store.alltestexam.length.toString().padLeft(2, '0'),
                  style: AppTokens.titleSm(context)
                      .copyWith(color: Colors.white),
                );
              }),
            ],
          ),
        ],
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
                Icons.quiz_outlined,
                color: AppTokens.accent(context),
                size: 36,
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              "No tests available",
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
