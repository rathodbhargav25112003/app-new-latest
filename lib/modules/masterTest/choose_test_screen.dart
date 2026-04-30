// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_element, avoid_print, use_build_context_synchronously, library_private_types_in_public_api, non_constant_identifier_names, dead_null_aware_expression, unused_local_variable

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/custom_dynamic_height_gridview.dart';
import '../../models/test_exampaper_list_model.dart';
import '../new-bookmark-flow/new_bookmark_screen1.dart';
import '../test/store/test_category_store.dart';
import '../widgets/no_access_alert_dialog.dart';
import '../widgets/no_access_bottom_sheet.dart';
import '../widgets/no_internet_connection.dart';

/// Exam list within a category — redesigned with AppTokens. Preserves the
/// 4-arg constructor + static route factory, TestCategoryStore fetch via
/// `onAllTestExamByCategoryApiCall(widget.id)` from initState, back-button
/// pushReplacement to allTestCategory, BookMarkScreen1 push, exam-tap
/// navigation to allSelectTestList, and full platform-specific no-access
/// dialog / bottom sheet branching with `onTap` retry callback that refires
/// `onTestExamByCategoryApiCall(widget.id, widget.type)`.
class ChooseTestScreen extends StatefulWidget {
  final String id;
  final String type;
  final bool showPredictive;
  final bool isTrend;

  const ChooseTestScreen({
    super.key,
    required this.id,
    required this.type,
    this.showPredictive = false,
    this.isTrend = false,
  });

  @override
  State<ChooseTestScreen> createState() => _ChooseTestScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => ChooseTestScreen(
        id: arguments['id'],
        type: arguments['type'],
        isTrend: arguments['isTrend'] ?? false,
        showPredictive: arguments['showPredictive'] ?? false,
      ),
    );
  }
}

class _ChooseTestScreenState extends State<ChooseTestScreen> {
  final FocusNode _focusNode = FocusNode();
  String query = '';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    store.onAllTestExamByCategoryApiCall(widget.id);
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Platform.isWindows || Platform.isMacOS;
    final store = Provider.of<TestCategoryStore>(context);

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          _Header(
            title: "Choose Test",
            onBack: () => Navigator.of(context)
                .pushReplacementNamed(Routes.allTestCategory),
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
                  if (!store.isConnected) {
                    return const NoInternetScreen();
                  }
                  if (store.alltestexam.isEmpty) {
                    return const _EmptyExams();
                  }
                  return isDesktop
                      ? CustomDynamicHeightGridView(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          itemCount: store.alltestexam.length,
                          builder: (BuildContext context, int index) {
                            return buildItem(context, store.alltestexam[index]);
                          },
                        )
                      : ListView.builder(
                          itemCount: store.alltestexam.length,
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (BuildContext context, int index) {
                            return buildItem(context, store.alltestexam[index]);
                          },
                        );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(
      BuildContext context, TestExamPaperListModel? testExamPaperListModel) {
    final testExamPaper = testExamPaperListModel;

    if (query.isNotEmpty &&
        (!testExamPaper!.examName!
            .toLowerCase()
            .contains(query.toLowerCase()))) {
      return const SizedBox.shrink();
    }

    return _ExamTile(
      testExamPaper: testExamPaper,
      onTap: () => _handleExamTap(context, testExamPaperListModel),
    );
  }

  void _handleExamTap(
    BuildContext context,
    TestExamPaperListModel? testExamPaperListModel,
  ) {
    final testExamPaper = testExamPaperListModel;
    if (testExamPaper?.isAccess ?? false) {
      Navigator.of(context).pushNamed(
        Routes.allSelectTestList,
        arguments: {
          'id': testExamPaperListModel?.examId,
          'type': "topic",
          'showPredictive': true,
          'testExamPaperListModel': testExamPaper,
          'isTrend': widget.isTrend,
        },
      );
    } else {
      if (Platform.isWindows || Platform.isMacOS) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppTokens.surface(context),
              insetPadding: const EdgeInsets.symmetric(horizontal: 100),
              actionsPadding: EdgeInsets.zero,
              actions: [
                NoAccessAlertDialog(
                  onTap: () {
                    final store = Provider.of<TestCategoryStore>(context,
                        listen: false);
                    store.onTestExamByCategoryApiCall(
                        widget.id, widget.type);
                  },
                  planId: testExamPaperListModel?.plan_id ?? "",
                  day: int.parse(testExamPaperListModel?.day ?? "0"),
                  isFree: testExamPaperListModel?.isfreeTrail ?? false,
                ),
              ],
            );
          },
        );
      } else {
        showModalBottomSheet<void>(
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTokens.r28),
            ),
          ),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          context: context,
          builder: (BuildContext context) {
            return NoAccessBottomSheet(
              onTap: () {
                final store =
                    Provider.of<TestCategoryStore>(context, listen: false);
                store.onTestExamByCategoryApiCall(widget.id, widget.type);
              },
              planId: testExamPaperListModel?.plan_id ?? "",
              day: int.parse(testExamPaperListModel?.day ?? "0"),
              isFree: testExamPaperListModel?.isfreeTrail ?? false,
            );
          },
        );
      }
    }
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

class _ExamTile extends StatelessWidget {
  const _ExamTile({
    required this.testExamPaper,
    required this.onTap,
  });
  final TestExamPaperListModel? testExamPaper;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasAttempt = testExamPaper?.isAttempt ?? false;
    final isSection = testExamPaper?.isSection ?? false;
    final isAccess = testExamPaper?.isAccess ?? true;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s12),
      child: Material(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius12,
        child: InkWell(
          borderRadius: AppTokens.radius12,
          onTap: onTap,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTokens.border(context)),
                  borderRadius: AppTokens.radius12,
                ),
                padding: const EdgeInsets.all(AppTokens.s12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                            "assets/image/papper.svg",
                            color: AppTokens.accent(context),
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
                                  isSection
                                      ? "${testExamPaper?.sectionData?.length ?? 0} Sections"
                                      : "${testExamPaper?.totalQuestions ?? 0} Questions",
                                  style: AppTokens.caption(context).copyWith(
                                    color: AppTokens.accent(context),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if ((testExamPaper?.instruction ?? "")
                                  .isNotEmpty) ...[
                                const SizedBox(height: AppTokens.s4),
                                Text(
                                  testExamPaper?.instruction ?? "",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTokens.caption(context).copyWith(
                                    color: AppTokens.ink2(context),
                                  ),
                                ),
                              ],
                              if (!hasAttempt) ...[
                                const SizedBox(height: AppTokens.s4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.cancel_rounded,
                                      size: 14,
                                      color: AppTokens.ink2(context),
                                    ),
                                    const SizedBox(width: AppTokens.s4),
                                    Text(
                                      "Not Started",
                                      style: AppTokens.caption(context)
                                          .copyWith(
                                        color: AppTokens.ink2(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (hasAttempt) ...[
                      const SizedBox(height: AppTokens.s8),
                      Text(
                        "Best Attempt",
                        style: AppTokens.caption(context).copyWith(
                          color: AppTokens.ink(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppTokens.s4),
                      Wrap(
                        spacing: AppTokens.s12,
                        runSpacing: AppTokens.s4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _MetricPair(
                            asset: "assets/image/exam_mark.svg",
                            label: "Marks",
                            value:
                                "${testExamPaper?.highestScore ?? 0} / ${testExamPaper?.totalMarks ?? 0}",
                          ),
                          if (!(testExamPaper?.isDeclaration ?? true))
                            _MetricPair(
                              asset: "assets/image/rank.svg",
                              label: "Rank",
                              value:
                                  "${testExamPaper?.highestScoreRank ?? 0}",
                            ),
                        ],
                      ),
                    ],
                    if (isSection) ...[
                      const SizedBox(height: AppTokens.s8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: AppTokens.s12,
                        ),
                        decoration: BoxDecoration(
                          color: AppTokens.successSoft(context),
                          borderRadius: BorderRadius.circular(64),
                          border: Border.all(
                            color:
                                AppTokens.success(context).withOpacity(0.35),
                          ),
                        ),
                        child: Text(
                          "Section based exam",
                          style: AppTokens.caption(context).copyWith(
                            color: AppTokens.success(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isAccess)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    height: 28,
                    width: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTokens.accent(context),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(AppTokens.r12),
                        bottomLeft: Radius.circular(AppTokens.r12),
                      ),
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricPair extends StatelessWidget {
  const _MetricPair({
    required this.asset,
    required this.label,
    required this.value,
  });
  final String asset;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(asset, height: 14, width: 14),
        const SizedBox(width: AppTokens.s4),
        Text(
          "$label: ",
          style: AppTokens.caption(context).copyWith(
            color: AppTokens.ink2(context),
          ),
        ),
        Text(
          value,
          style: AppTokens.caption(context).copyWith(
            color: AppTokens.ink(context),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _EmptyExams extends StatelessWidget {
  const _EmptyExams();

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
              "No tests available yet",
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
