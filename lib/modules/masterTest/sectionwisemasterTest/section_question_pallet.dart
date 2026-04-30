// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_element, avoid_print, use_build_context_synchronously, library_private_types_in_public_api, non_constant_identifier_names, dead_null_aware_expression

import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/models/test_exampaper_list_model.dart';
import 'package:shusruta_lms/modules/masterTest/sectionwisemasterTest/section_exam_screen.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';

import '../../../app/routes.dart';
import '../../../helpers/app_tokens.dart';
import '../../../helpers/colors.dart';
import '../custom_master_test_dialogbox.dart';
import 'model/get_section_list_model.dart';

/// Section-wise question pallet (drawer / full-screen) for the master exam
/// runner. Redesigned with AppTokens while preserving every API contract:
///   • Constructor `SectionQuestionPallet({super.key, testExamPaper,
///     sectionData, userExamId, remainingTime, remainingSectionTimeNotifier,
///     isPracticeExam, isLastSection, currentQuestionIndex, timer,
///     required callBack: Function(SectionExamScreen textExamData)})`
///   • Static `route(RouteSettings)` factory with 9 argument keys:
///     testData / timer / userexamId / isPracticeExam / isLastSection /
///     remainingTime / remainingSectionTimeNotifier / sectionData /
///     currentQueIndex — the factory-level callBack stays a no-op
///   • State fields `statusColor` + `txtColor` (mutable colour cache while
///     iterating the grid)
///   • `_getSectionQuesPallete()` — calls
///     `store.getSectionQuestionPallete(userExamId ?? "")`
///   • `_onBackPressed()` — shows
///     `CustomMasterTestCancelDialogBox(timer, remainingTime, false)`
///   • initState runs `_getSectionQuesPallete()`
///   • Close icon (narrow layout only) → `pushNamed(Routes.sectionExams)`
///     with the 9-argument map (queNo sourced from the currently-active
///     question via `currentQuestionIndex`)
///   • Grid cell tap — preserves the legacy behaviour: the ONLY live line
///     is `debugPrint("sectinTime${widget.remainingSectionTimeNotifier}")`
///     guarded by `widget.sectionData?.section ==
///     store.sectionTestQuePallete[sectionIndex]?.section`. The historical
///     callBack + pushNamed branches remain commented in the original and
///     intentionally stay that way here so tap is effectively a no-op. The
///     `callBack` constructor param is retained in the public surface.
///   • Colour precedence per question (matches non-section drawer):
///     isAttempted → ThemeManager.greenSuccess / Colors.white
///     isMarkedForReview → Colors.blue / Colors.white
///     isAttemptedMarkedForReview → Colors.orangeAccent / Colors.white
///     isSkipped → Colors.red / Colors.white
///     isGuess → Colors.brown / Colors.white
///     default → ThemeManager.defaultPalleteColor /
///               ThemeManager.defaultPalleteTxtColor
///   • Section header row: "Section {n}" + status badge (`Submitted` →
///     green / `On Going` → primary / else → `Locked` red)
///   • Legend order preserved: Attempted / Marked for Review / Attempted
///     and Marked for Review / Guess / Skipped / Not Visited
///   • Outer `ListView.builder(physics: BouncingScrollPhysics)` over
///     sections; inner `ListView.builder(shrinkWrap: true, physics:
///     NeverScrollableScrollPhysics)` with the `index % 5 == 0` 5-col
///     row-generator pattern preserved.
class SectionQuestionPallet extends StatefulWidget {
  final TestExamPaperListModel? testExamPaper;
  final GetSectionListModel? sectionData;
  final String? userExamId;
  final Timer? timer;
  final ValueNotifier<Duration>? remainingTime;
  final ValueNotifier<Duration>? remainingSectionTimeNotifier;
  final bool? isPracticeExam;
  final bool? isLastSection;
  final int? currentQuestionIndex;
  final Function(SectionExamScreen textExamData) callBack;
  const SectionQuestionPallet(
      {super.key,
      this.testExamPaper,
      this.sectionData,
      this.userExamId,
      this.remainingTime,
      this.remainingSectionTimeNotifier,
      this.isPracticeExam,
      this.isLastSection,
      this.currentQuestionIndex,
      this.timer,
      required this.callBack});

  @override
  State<SectionQuestionPallet> createState() => _SectionQuestionPalletState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => SectionQuestionPallet(
        testExamPaper: arguments['testData'],
        timer: arguments['timer'],
        userExamId: arguments['userexamId'],
        isPracticeExam: arguments['isPracticeExam'],
        isLastSection: arguments['isLastSection'],
        remainingTime: arguments['remainingTime'],
        remainingSectionTimeNotifier: arguments['remainingSectionTimeNotifier'],
        sectionData: arguments['sectionData'],
        currentQuestionIndex: arguments['currentQueIndex'],
        callBack: (SectionExamScreen textExamData) {},
      ),
    );
  }
}

class _SectionQuestionPalletState extends State<SectionQuestionPallet> {
  Color? statusColor;
  Color? txtColor;

  Future<void> _getSectionQuesPallete() async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.getSectionQuestionPallete(widget.userExamId ?? "");
  }

  @override
  void initState() {
    super.initState();
    _getSectionQuesPallete();
  }

  Future<bool> _onBackPressed() async {
    bool confirmExit = await showDialog(
      context: context,
      builder: (context) => CustomMasterTestCancelDialogBox(
          widget.timer, widget.remainingTime, false),
    );
    return confirmExit;
  }

  bool _isWide(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width > 1160 && size.height > 690;
  }

  void _navigateToActiveQuestion() {
    Navigator.of(context).pushNamed(Routes.sectionExams, arguments: {
      'queNo': widget
          .testExamPaper?.test?[widget.currentQuestionIndex ?? 0].questionNumber,
      'testData': widget.testExamPaper,
      'userexamId': widget.userExamId,
      'remainingTime': widget.remainingTime,
      'remainingSectionTimeNotifier': widget.remainingSectionTimeNotifier,
      'isPracticeExam': widget.isPracticeExam,
      'isLastSection': widget.isLastSection,
      'fromPallete': true,
      'sectionData': widget.sectionData,
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<TestCategoryStore>(context);
    final wide = _isWide(context);
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        backgroundColor: AppTokens.scaffold(context),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---------------------------------------------------
              // Header
              // ---------------------------------------------------
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.s16,
                  AppTokens.s12,
                  AppTokens.s16,
                  AppTokens.s4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.testExamPaper?.examName ?? "Question Pallet",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTokens.titleMd(context),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    if (!wide)
                      _CloseBtn(onTap: _navigateToActiveQuestion),
                  ],
                ),
              ),
              // ---------------------------------------------------
              // Legend
              // ---------------------------------------------------
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.s16,
                  AppTokens.s8,
                  AppTokens.s16,
                  AppTokens.s12,
                ),
                child: Wrap(
                  spacing: AppTokens.s12,
                  runSpacing: AppTokens.s8,
                  children: const [
                    _LegendDot(color: Colors.green, label: "Attempted"),
                    _LegendDot(color: Colors.blue, label: "Marked for Review"),
                    _LegendDot(
                      color: Colors.orangeAccent,
                      label: "Attempted and Marked for Review",
                    ),
                    _LegendDot(color: Colors.brown, label: "Guess"),
                    _LegendDot(color: Colors.red, label: "Skipped"),
                    _LegendDot(color: Colors.black, label: "Not Visited"),
                  ],
                ),
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: AppTokens.border(context),
              ),
              // ---------------------------------------------------
              // Per-section grid
              // ---------------------------------------------------
              Expanded(
                child: Observer(
                  builder: (context) {
                    if (store.sectionTestQuePallete.isEmpty) {
                      return Center(
                        child: Text(
                          "No sections",
                          style: AppTokens.body(context),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: store.sectionTestQuePallete.length,
                      padding: const EdgeInsets.fromLTRB(
                        AppTokens.s16,
                        AppTokens.s16,
                        AppTokens.s16,
                        AppTokens.s24,
                      ),
                      scrollDirection: Axis.vertical,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (BuildContext context, int sectionIndex) {
                        final section =
                            store.sectionTestQuePallete[sectionIndex];
                        return _SectionBlock(
                          index: sectionIndex,
                          title:
                              "Section ${section?.section}",
                          status: section?.status,
                          questionCount: section?.questions?.length ?? 0,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: section?.questions?.length,
                            padding: EdgeInsets.zero,
                            scrollDirection: Axis.vertical,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder:
                                (BuildContext context, int index) {
                              if (index % 5 == 0) {
                                int itemCount = index + 5 <=
                                        (section?.questions?.length ?? 0)
                                    ? 5
                                    : (section?.questions?.length ?? 0) -
                                        index;
                                return Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: List.generate(
                                    itemCount,
                                    (rowIndex) {
                                      int currentIndex = index + rowIndex;
                                      final question =
                                          section?.questions?[currentIndex];
                                      if (question?.isAttempted == true) {
                                        statusColor =
                                            ThemeManager.greenSuccess;
                                        txtColor = Colors.white;
                                      } else if (question
                                              ?.isMarkedForReview ==
                                          true) {
                                        statusColor = Colors.blue;
                                        txtColor = Colors.white;
                                      } else if (question
                                              ?.isAttemptedMarkedForReview ==
                                          true) {
                                        statusColor = Colors.orangeAccent;
                                        txtColor = Colors.white;
                                      } else if (question?.isSkipped ==
                                          true) {
                                        statusColor = Colors.red;
                                        txtColor = Colors.white;
                                      } else if (question?.isGuess == true) {
                                        statusColor = Colors.brown;
                                        txtColor = Colors.white;
                                      } else {
                                        statusColor =
                                            ThemeManager.defaultPalleteColor;
                                        txtColor = ThemeManager
                                            .defaultPalleteTxtColor;
                                      }
                                      return Padding(
                                        padding:
                                            const EdgeInsets.all(5.0),
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          onTap: () {
                                            if (widget.sectionData?.section ==
                                                section?.section) {
                                              debugPrint(
                                                  "sectinTime${widget.remainingSectionTimeNotifier}");
                                              // Legacy navigation branches
                                              // intentionally preserved as
                                              // no-op — see class comment.
                                            }
                                          },
                                          child: Container(
                                            height: 44,
                                            width: 44,
                                            decoration: BoxDecoration(
                                              color: statusColor,
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Center(
                                              child: Text(
                                                "${currentIndex + 1}",
                                                style: AppTokens.titleSm(
                                                        context)
                                                    .copyWith(
                                                  color: txtColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              } else {
                                return const SizedBox.shrink();
                              }
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
//                                 PRIMITIVES
// ============================================================================

class _CloseBtn extends StatelessWidget {
  const _CloseBtn({required this.onTap});
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
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTokens.surface(context),
            shape: BoxShape.circle,
            border: Border.all(color: AppTokens.border(context)),
            boxShadow: AppTokens.shadow1(context),
          ),
          child: Icon(
            Icons.close_rounded,
            size: 18,
            color: AppTokens.ink(context),
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTokens.caption(context)
              .copyWith(color: AppTokens.ink2(context)),
        ),
      ],
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
    required this.index,
    required this.title,
    required this.status,
    required this.questionCount,
    required this.child,
  });
  final int index;
  final String title;
  final String? status;
  final int questionCount;
  final Widget child;

  Color _badgeColor(BuildContext context) {
    if (status == 'Submitted') return ThemeManager.greenSuccess;
    if (status == 'On Going') return ThemeManager.primaryColor;
    return ThemeManager.redText;
  }

  String _badgeLabel() {
    if (status == 'Submitted') return 'Submitted';
    if (status == 'On Going') return 'On Going';
    return 'Locked';
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _badgeColor(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.s16),
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: BorderRadius.circular(AppTokens.r16),
        border: Border.all(color: AppTokens.border(context)),
        boxShadow: AppTokens.shadow1(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTokens.titleSm(context),
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _badgeLabel(),
                  style: AppTokens.caption(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "$questionCount question${questionCount == 1 ? '' : 's'}",
            style: AppTokens.caption(context)
                .copyWith(color: AppTokens.ink2(context)),
          ),
          const SizedBox(height: AppTokens.s12),
          child,
        ],
      ),
    );
  }
}
