// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters, unused_field, unused_local_variable, non_constant_identifier_names

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/helpers/custom_dynamic_height_gridview.dart';
import 'package:shusruta_lms/models/test_exampaper_list_model.dart';
import 'package:shusruta_lms/modules/new-bookmark-flow/new_bookmark_screen1.dart';
import 'package:shusruta_lms/modules/test/status_toggle_widget.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';
import 'package:shusruta_lms/modules/widgets/no_access_alert_dialog.dart';
import 'package:shusruta_lms/modules/widgets/no_access_bottom_sheet.dart';
import 'package:shusruta_lms/modules/widgets/no_internet_connection.dart';

/// "Choose Test" — list of tests inside a given category, with a status
/// toggle filter (All / Completed / Not Started / In Progress) and
/// lock-gated access.
///
/// Preserved public contract:
///   • `SelectTestList({super.key, required id, required type})`
///   • Static `route(RouteSettings)` reads `{id, type}`.
///   • `store.onTestExamByCategoryApiCall(id, type)` in initState.
///   • `StatusToggleWidget` with options `['All','Completed','Not
///     Started','In Progress']` → `store.statusTestExamFilter(context,
///     v)`.
///   • Tap unlocked card → `Navigator.pushReplacementNamed(
///     Routes.showTestScreen, arguments: {testExamPaperListModel, id,
///     type})`.
///   • Tap locked card → `NoAccessAlertDialog` (Windows/macOS) or
///     `NoAccessBottomSheet` (mobile) with `onTap` re-calling the list
///     API, plus `planId`, `day`, `isFree`.
///   • Bookmark icon → pushes `BookMarkScreen1()` via
///     CupertinoPageRoute.
///   • `!store.isConnected` → `NoInternetScreen`.
///   • Empty-state copy verbatim.
class SelectTestList extends StatefulWidget {
  final String id;
  final String type;
  const SelectTestList({super.key, required this.id, required this.type});

  @override
  State<SelectTestList> createState() => _SelectTestListState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => SelectTestList(
        id: arguments['id'],
        type: arguments['type'],
      ),
    );
  }
}

class _SelectTestListState extends State<SelectTestList> {
  final FocusNode _focusNode = FocusNode();
  String query = '';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    store.onTestExamByCategoryApiCall(widget.id, widget.type);
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  void _openTest(
    BuildContext context,
    TestExamPaperListModel? testExamPaperListModel,
  ) {
    if (testExamPaperListModel?.isAccess ?? false) {
      Navigator.of(context).pushReplacementNamed(
        Routes.showTestScreen,
        arguments: {
          'testExamPaperListModel': testExamPaperListModel,
          'id': widget.id,
          'type': widget.type,
        },
      );
    } else {
      void refresh() {
        final store = Provider.of<TestCategoryStore>(context, listen: false);
        store.onTestExamByCategoryApiCall(widget.id, widget.type);
      }

      if (Platform.isWindows || Platform.isMacOS) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppTokens.scaffold(context),
              insetPadding: const EdgeInsets.symmetric(horizontal: 100),
              actionsPadding: EdgeInsets.zero,
              actions: [
                NoAccessAlertDialog(
                  onTap: refresh,
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
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(AppTokens.r28)),
          ),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          context: context,
          builder: (BuildContext context) {
            return NoAccessBottomSheet(
              onTap: refresh,
              planId: testExamPaperListModel?.plan_id ?? "",
              day: int.parse(testExamPaperListModel?.day ?? "0"),
              isFree: testExamPaperListModel?.isfreeTrail ?? false,
            );
          },
        );
      }
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
          _buildHeader(context),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s20,
                AppTokens.s16,
                AppTokens.s20,
                0,
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
                        'In Progress'
                      ],
                      onOptionSelected: (v) {
                        store.statusTestExamFilter(context, v);
                      },
                    ),
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
                        if (store.filtterTestExam.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppTokens.s24),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 56,
                                    color: AppTokens.muted(context),
                                  ),
                                  const SizedBox(height: AppTokens.s16),
                                  Text(
                                    "We're sorry, there's no content available right now. Please check back later or explore other sections for more educational resources.",
                                    style: AppTokens.body(context).copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: AppTokens.ink(context),
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        if (!store.isConnected) return const NoInternetScreen();
                        return isDesktop
                            ? CustomDynamicHeightGridView(
                                crossAxisCount: 2,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                itemCount: store.filtterTestExam.length,
                                builder:
                                    (BuildContext context, int index) {
                                  return buildItem(
                                      context, store.filtterTestExam[index]);
                                },
                              )
                            : ListView.builder(
                                itemCount: store.filtterTestExam.length,
                                shrinkWrap: true,
                                padding: const EdgeInsets.only(
                                    bottom: AppTokens.s20),
                                physics: const BouncingScrollPhysics(),
                                itemBuilder:
                                    (BuildContext context, int index) {
                                  return buildItem(
                                      context, store.filtterTestExam[index]);
                                },
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
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppTokens.s8,
        left: AppTokens.s8,
        right: AppTokens.s20,
        bottom: AppTokens.s16,
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
              "Choose Test",
              style: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.of(context).push(CupertinoPageRoute(
                builder: (context) => const BookMarkScreen1(),
              ));
            },
            borderRadius: BorderRadius.circular(AppTokens.r20),
            child: Container(
              height: AppTokens.s32,
              width: AppTokens.s32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTokens.r20),
              ),
              child: const Icon(
                Icons.bookmark_border,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(
    BuildContext context,
    TestExamPaperListModel? testExamPaperListModel,
  ) {
    final TestExamPaperListModel? testExamPaper = testExamPaperListModel;
    String fromTime = '';
    String toTime = '';
    if ((testExamPaper?.fromtime?.isNotEmpty ?? false) &&
        (testExamPaper?.totime?.isNotEmpty ?? false)) {
      final String fromString = testExamPaper?.fromtime ?? "";
      final String toString = testExamPaper?.totime ?? "";
      final DateTime datefromTime = DateTime.parse(fromString);
      final DateTime dateToTime = DateTime.parse(toString);
      fromTime = DateFormat('dd/MM/yyyy hh:mm a').format(datefromTime);
      toTime = DateFormat('dd/MM/yyyy hh:mm a').format(dateToTime);
    }

    if (query.isNotEmpty &&
        (!(testExamPaper?.examName ?? "")
            .toLowerCase()
            .contains(query.toLowerCase()))) {
      return const SizedBox.shrink();
    }

    final bool isLocked = testExamPaper?.isAccess == false;
    final bool isAttempt = testExamPaper?.isAttempt ?? false;
    final bool isCompleted = testExamPaper?.isCompleted ?? false;

    String statusAsset;
    String statusLabel;
    if (isAttempt && !isCompleted) {
      statusAsset = "assets/image/inprogress.svg";
      statusLabel = "In progress";
    } else if (isAttempt && isCompleted) {
      statusAsset = "assets/image/correct_i.svg";
      statusLabel = "Completed";
    } else {
      statusAsset = "assets/image/cross.svg";
      statusLabel = "Not Started";
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s12),
      child: InkWell(
        onTap: () => _openTest(context, testExamPaperListModel),
        borderRadius: BorderRadius.circular(AppTokens.r16),
        child: Stack(
          children: [
            Container(
              constraints: (Platform.isMacOS || Platform.isWindows)
                  ? const BoxConstraints(minHeight: 206)
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
                      Container(
                        height: 52,
                        width: 52,
                        padding: const EdgeInsets.all(AppTokens.s12),
                        decoration: BoxDecoration(
                          color: AppTokens.accentSoft(context),
                          borderRadius: BorderRadius.circular(AppTokens.r12),
                        ),
                        child: SvgPicture.asset(
                          "assets/image/examsubject.svg",
                          color: AppTokens.accent(context),
                        ),
                      ),
                      const SizedBox(width: AppTokens.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              testExamPaperListModel?.examName ?? "",
                              style: AppTokens.body(context).copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTokens.ink(context),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${testExamPaperListModel?.totalQuestions.toString()} Questions",
                              style: AppTokens.caption(context).copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTokens.accent(context),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              testExamPaperListModel?.instruction ?? "",
                              style: AppTokens.caption(context).copyWith(
                                color: AppTokens.muted(context),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                SvgPicture.asset(statusAsset),
                                const SizedBox(width: 5),
                                Text(
                                  statusLabel,
                                  style: AppTokens.caption(context).copyWith(
                                    fontWeight: FontWeight.w600,
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
                  if (isAttempt) ...[
                    const SizedBox(height: AppTokens.s12),
                    Container(
                        height: 1, color: AppTokens.border(context)),
                    const SizedBox(height: AppTokens.s12),
                    Text(
                      "Last Practice Session : ${testExamPaperListModel?.lastPracticeTime}",
                      style: AppTokens.caption(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTokens.ink(context),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        SvgPicture.asset(
                          "assets/image/note3.svg",
                          height: 16,
                          width: 16,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                      "${testExamPaperListModel?.practiceAnswersCount.toString()} ",
                                  style: AppTokens.caption(context).copyWith(
                                    color: AppTokens.ink(context),
                                    fontWeight: FontWeight.w700,
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
                                      "${testExamPaperListModel?.totalQuestions.toString()} ",
                                  style: AppTokens.caption(context).copyWith(
                                    color: AppTokens.ink(context),
                                    fontWeight: FontWeight.w700,
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
                    const SizedBox(height: 7),
                    Text(
                      "Last Test Attempted : ${testExamPaperListModel?.lastTestModeTime}",
                      style: AppTokens.caption(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTokens.ink(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        SvgPicture.asset("assets/image/question2.svg"),
                        const SizedBox(width: 5),
                        Text(
                          "${testExamPaperListModel?.userExamType}",
                          style: AppTokens.caption(context).copyWith(
                            color: AppTokens.muted(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (isLocked)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  height: AppTokens.s24,
                  width: AppTokens.s24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTokens.accent(context),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(AppTokens.r16),
                      bottomLeft: Radius.circular(AppTokens.r16),
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
    );
  }
}
