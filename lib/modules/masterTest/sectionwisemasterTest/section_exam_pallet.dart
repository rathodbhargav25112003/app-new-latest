// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_element, avoid_print, use_build_context_synchronously, library_private_types_in_public_api, non_constant_identifier_names, dead_null_aware_expression, prefer_final_fields, unused_local_variable

import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/helpers/custom_dynamic_height_gridview.dart';
import 'package:shusruta_lms/models/test_exampaper_list_model.dart';
import 'package:shusruta_lms/modules/masterTest/sectionwisemasterTest/model/get_section_list_model.dart';
import 'package:shusruta_lms/modules/masterTest/sectionwisemasterTest/store/section_exam_store.dart';
import 'package:shusruta_lms/modules/new_exam_component/model/exam_ans_model.dart';
import 'package:shusruta_lms/modules/new_exam_component/store/exam_store.dart';
import 'package:shusruta_lms/modules/notes/sharedhelper.dart';

/// Question pallet sheet for the section-wise master exam. Redesigned with
/// AppTokens while preserving every API contract:
///   • Constructor `SectionExamPallet({super.key, required userExamId,
///     required examName, required isDesktop, required sectionData,
///     required ansList, required questionList, required sectionsList,
///     required currentSectionsList})`
///   • State fields: `statusColor`, `txtColor`, `count`, `questionList`,
///     `store`, plus `_ansListReaction` + `_ansListDetailReaction`
///     (ReactionDisposer?)
///   • `_calculateCount(ansList, totalQuestions)` delegates to
///     `analyzeQuestionStatus` from notes/sharedhelper
///   • `_getMasterQuesPallete()` — sources questions from store first,
///     falls back to `widget.questionList[0]`, then sets `count` and
///     re-colours each `TestData` entry via the existing precedence:
///       attempted → ThemeManager.greenSuccess
///       markedForReview → Colors.orange
///       attemptedMarkedForReview → 0xff74367E
///       skipped → Colors.red
///       guess.isNotEmpty → 0xff2E6FEE
///       else → ThemeManager.black
///     (default when no match → defaultPalleteColor/defaultPalleteTxtColor)
///   • `initState` — `WidgetsBinding.addPostFrameCallback(_getMasterQuesPallete)`
///   • `dispose` — calls both `ReactionDisposer`s
///   • `build` sets up the two reactions on first pass (one keyed on
///     length, one on concatenated
///     `${questionId}_${attempted}_${skipped}_${markedForReview}_${attemptedMarkedForReview}_${guess}`)
///   • `_buildScrollableContent(displayCount)` — widescreen (desktop or
///     width≥600) scrolls everything together; mobile keeps grid in a
///     fixed-height (43%) SizedBox
///   • `_getQuestionStatusColor(questionId)` and per-cell Observer ensure
///     live colour updates
///   • Close icon visible only on mobile (not desktop) → `Navigator.pop`
///   • Grid tap → `store.changeIndex(index)` + (mobile) `Navigator.pop`
///   • Each section in `sectionsList` rendered with "Submited" badge
///     (preserved misspelling from original copy)
///   • Current section rendered with "Ongoing" badge + six legend items
///     (Attempted / Not Visited / Marked / Skipped / Guess / Attempted &
///     Marked for Review) with different layouts for desktop vs mobile
class SectionExamPallet extends StatefulWidget {
  final String userExamId;
  final String examName;
  final bool isDesktop;
  final GetSectionListModel sectionData;
  final List<List<ExamAnsModel>> ansList;
  final List<List<TestData>> questionList;
  final List<GetSectionListModel> sectionsList;
  final GetSectionListModel currentSectionsList;
  const SectionExamPallet(
      {super.key,
      required this.userExamId,
      required this.examName,
      required this.isDesktop,
      required this.sectionData,
      required this.ansList,
      required this.questionList,
      required this.sectionsList,
      required this.currentSectionsList});

  @override
  State<SectionExamPallet> createState() => _SectionExamPalletState();
}

class _SectionExamPalletState extends State<SectionExamPallet> {
  Color? statusColor;
  Color? txtColor;
  Map<String, dynamic> count = {};
  List<TestData> questionList = [];
  late SectionExamStore store;

  Map<String, dynamic> _calculateCount(
      List<ExamAnsModel> ansList, int totalQuestions) {
    return analyzeQuestionStatus(ansList, totalQuestions);
  }

  Future<void> _getMasterQuesPallete() async {
    debugPrint("widget.userExamId:${widget.userExamId}");
    final store = Provider.of<SectionExamStore>(context, listen: false);

    final sourceQuestionList = store.questionList.value.isNotEmpty
        ? store.questionList.value
        : (widget.questionList.isNotEmpty && widget.questionList[0].isNotEmpty
            ? widget.questionList[0]
            : <TestData>[]);

    log(analyzeQuestionStatus(store.ansList.value, sourceQuestionList.length)
        .toString());

    final newCount =
        analyzeQuestionStatus(store.ansList.value, sourceQuestionList.length);

    setState(() {
      count = newCount;
      questionList = sourceQuestionList.map((question) {
        final questionIdToMatch = question.sId;
        if (store.ansList.value.isEmpty) {
          question.statusColor = ThemeManager.defaultPalleteColor.value;
          question.txtColor = ThemeManager.defaultPalleteTxtColor.value;
        } else {
          ExamAnsModel? matchingQuestion;
          try {
            matchingQuestion = store.ansList.value.firstWhere(
              (item) => item.questionId == questionIdToMatch,
            );
          } catch (e) {
            matchingQuestion = null;
          }

          if (matchingQuestion != null) {
            if (matchingQuestion.attempted == true) {
              question.statusColor = ThemeManager.greenSuccess.value;
            } else if (matchingQuestion.markedForReview == true) {
              question.statusColor = Colors.orange.value;
            } else if (matchingQuestion.attemptedMarkedForReview == true) {
              question.statusColor = const Color(0xff74367E).value;
            } else if (matchingQuestion.skipped == true) {
              question.statusColor = Colors.red.value;
            } else if (matchingQuestion.guess.isNotEmpty) {
              question.statusColor = const Color(0xff2E6FEE).value;
            } else {
              question.statusColor = ThemeManager.black.value;
            }
          } else {
            question.statusColor = ThemeManager.defaultPalleteColor.value;
            question.txtColor = ThemeManager.defaultPalleteTxtColor.value;
          }
        }
        statusColor = Color(question.statusColor ?? 0);
        txtColor = Color(question.txtColor ?? 0);
        return question;
      }).toList();
    });
  }

  ReactionDisposer? _ansListReaction;
  ReactionDisposer? _ansListDetailReaction;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _getMasterQuesPallete();
      }
    });
  }

  @override
  void dispose() {
    _ansListReaction?.call();
    _ansListDetailReaction?.call();
    super.dispose();
  }

  bool _isWide(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return width > 1160 && height > 670;
  }

  @override
  Widget build(BuildContext context) {
    store = Provider.of<SectionExamStore>(context, listen: false);

    if (_ansListReaction == null) {
      _ansListReaction = reaction(
        (_) => store.ansList.value.length,
        (_) {
          if (mounted) {
            _getMasterQuesPallete();
          }
        },
      );

      _ansListDetailReaction = reaction(
        (_) => store.ansList.value
            .map((ans) =>
                '${ans.questionId}_${ans.attempted}_${ans.skipped}_${ans.markedForReview}_${ans.attemptedMarkedForReview}_${ans.guess}')
            .join(','),
        (_) {
          if (mounted) {
            _getMasterQuesPallete();
          }
        },
      );
    }

    return Observer(
      builder: (context) {
        final ansListLength = store.ansList.value.length;
        final questionListLength = store.questionList.value.length;

        final currentCount = _calculateCount(
          store.ansList.value,
          questionListLength > 0 ? questionListLength : questionList.length,
        );

        if (questionListLength > 0 &&
            questionList.length != questionListLength) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _getMasterQuesPallete();
            }
          });
        } else if (questionList.isEmpty && questionListLength == 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _getMasterQuesPallete();
            }
          });
        }

        return Scaffold(
          backgroundColor: AppTokens.scaffold(context),
          body: SizedBox(
            height: double.infinity,
            width: MediaQuery.of(context).size.width,
            child: questionListLength > 0 ||
                    ansListLength > 0 ||
                    store.getSectionListModel.value.isNotEmpty
                ? _buildScrollableContent(currentCount)
                : const Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }

  Widget _buildScrollableContent(Map<String, dynamic> displayCount) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = widget.isDesktop || screenWidth >= 600;

    if (isWideScreen) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: _buildContent(displayCount),
      );
    } else {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildHeaderSection(displayCount),
            const SizedBox(height: AppTokens.s12),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.43,
              child: _buildQuestionsGrid(),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildContent(Map<String, dynamic> displayCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildHeaderSection(displayCount),
        const SizedBox(height: AppTokens.s12),
        _buildQuestionsGrid(),
      ],
    );
  }

  Widget _buildHeaderSection(Map<String, dynamic> displayCount) {
    final wide = _isWide(context);
    return Padding(
      padding: EdgeInsets.only(
        top: widget.isDesktop
            ? AppTokens.s12
            : MediaQuery.of(context).padding.top + AppTokens.s8,
        left: AppTokens.s16,
        right: AppTokens.s16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isDesktop)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.examName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTokens.titleMd(context),
                  ),
                ),
                const SizedBox(width: AppTokens.s8),
                _CloseBtn(onTap: () => Navigator.pop(context)),
              ],
            ),
          // -------- completed sections --------
          if (widget.sectionsList.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s16),
            ListView.builder(
              itemCount: widget.sectionsList.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                final storeSections = store.getSectionListModel.value;
                final sectionData =
                    index < storeSections.length ? storeSections[index] : null;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTokens.s12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Section ${widget.sectionsList[index].section ?? ""}",
                            style: AppTokens.titleSm(context),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              "Submited",
                              style: AppTokens.caption(context).copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTokens.s8),
                      if (!wide)
                        Row(
                          children: [
                            _buildLegendItem(
                              ThemeManager.evolveYellow,
                              "Total Questions",
                              widget.sectionsList[index].numberOfQuestions
                                      ?.toString() ??
                                  '0',
                            ),
                            const SizedBox(width: AppTokens.s16),
                            _buildLegendItem(
                              ThemeManager.greenBorder,
                              "Attempted",
                              ((sectionData?.attempted ?? 0) +
                                      (sectionData?.markedforreview ?? 0) +
                                      (sectionData
                                              ?.attemptedandmarkedforreview ??
                                          0))
                                  .toString(),
                            ),
                            const SizedBox(width: AppTokens.s16),
                            _buildLegendItem(
                              Colors.orange,
                              "Skipped",
                              (sectionData?.skipped ?? 0).toString(),
                            ),
                          ],
                        )
                      else if (sectionData != null) ...[
                        Builder(
                          builder: (context) {
                            final sectionAttempted = ((sectionData.attempted ??
                                    0) +
                                (sectionData.markedforreview ?? 0) +
                                (sectionData.attemptedandmarkedforreview ?? 0));
                            final sectionSkipped = sectionData.skipped ?? 0;
                            final sectionMarkedForReview =
                                sectionData.markedforreview ?? 0;
                            final sectionAttemptedMarkedForReview =
                                sectionData.attemptedandmarkedforreview ?? 0;
                            final sectionGuess = sectionData.guess ?? 0;
                            final sectionNotVisited = sectionData.notVisited ??
                                ((sectionData.numberOfQuestions ?? 0) -
                                    (sectionAttempted +
                                        sectionSkipped +
                                        sectionGuess));
                            return Wrap(
                              runSpacing: 15,
                              spacing: 18,
                              alignment: WrapAlignment.start,
                              crossAxisAlignment: WrapCrossAlignment.start,
                              children: [
                                _buildLegendItem(Colors.green, "Attempted",
                                    sectionAttempted.toString()),
                                _buildLegendItem(
                                    ThemeManager.evolveYellow,
                                    "Not Visited",
                                    (sectionNotVisited > 0
                                            ? sectionNotVisited
                                            : 0)
                                        .toString()),
                                _buildLegendItem(Colors.orange,
                                    "Marked for Review", sectionMarkedForReview.toString()),
                                _buildLegendItem(Colors.red, "Skipped",
                                    sectionSkipped.toString()),
                                _buildLegendItem(const Color(0xff2E6FEE),
                                    "Guess", sectionGuess.toString()),
                                _buildLegendItem(
                                    const Color(0xff74367E),
                                    "Attempted and Marked for Review",
                                    sectionAttemptedMarkedForReview
                                        .toString()),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
          // -------- current section --------
          const SizedBox(height: AppTokens.s16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Section ${widget.sectionData.section ?? ""}",
                style: AppTokens.titleSm(context),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xffFF9500),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  "Ongoing",
                  style: AppTokens.caption(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          if (!wide) ...[
            Row(
              children: [
                _buildLegendItem(Colors.green, "Attempted",
                    displayCount['isAttempted']?.toString() ?? '0'),
                const SizedBox(width: AppTokens.s16),
                _buildLegendItem(ThemeManager.evolveYellow, "Not Visited",
                    displayCount['notVisited']?.toString() ?? '0'),
                const SizedBox(width: AppTokens.s16),
                _buildLegendItem(Colors.orange, "Marked for Review",
                    displayCount['isMarkedForReview']?.toString() ?? '0'),
              ],
            ),
            const SizedBox(height: AppTokens.s12),
            Row(
              children: [
                _buildLegendItem(Colors.red, "Skipped",
                    displayCount['isSkipped']?.toString() ?? '0'),
                const SizedBox(width: AppTokens.s24 + AppTokens.s8),
                _buildLegendItem(const Color(0xff2E6FEE), "Guess",
                    displayCount['isGuess']?.toString() ?? '0'),
              ],
            ),
            const SizedBox(height: AppTokens.s12),
            Row(
              children: [
                _buildLegendItem(
                    const Color(0xff74367E),
                    "Attempted and Marked for Review",
                    displayCount['isAttemptedMarkedForReview']?.toString() ??
                        '0'),
              ],
            ),
            const SizedBox(height: AppTokens.s16),
          ] else ...[
            Wrap(
              runSpacing: 15,
              spacing: 18,
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                _buildLegendItem(Colors.green, "Attempted",
                    displayCount['isAttempted']?.toString() ?? '0'),
                _buildLegendItem(ThemeManager.evolveYellow, "Not Visited",
                    displayCount['notVisited']?.toString() ?? '0'),
                _buildLegendItem(Colors.orange, "Marked for Review",
                    displayCount['isMarkedForReview']?.toString() ?? '0'),
                _buildLegendItem(Colors.red, "Skipped",
                    displayCount['isSkipped']?.toString() ?? '0'),
                _buildLegendItem(const Color(0xff2E6FEE), "Guess",
                    displayCount['isGuess']?.toString() ?? '0'),
                _buildLegendItem(
                    const Color(0xff74367E),
                    "Attempted and Marked for Review",
                    displayCount['isAttemptedMarkedForReview']?.toString() ??
                        '0'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getQuestionStatusColor(String? questionId) {
    if (questionId == null || store.ansList.value.isEmpty) {
      return Color(ThemeManager.defaultPalleteColor.value);
    }

    try {
      final matchingQuestion = store.ansList.value.firstWhere(
        (item) => item.questionId == questionId,
      );

      if (matchingQuestion.attempted == true) {
        return Color(ThemeManager.greenSuccess.value);
      } else if (matchingQuestion.attemptedMarkedForReview == true) {
        return const Color(0xff74367E);
      } else if (matchingQuestion.markedForReview == true) {
        return Colors.orange;
      } else if (matchingQuestion.skipped == true) {
        return Colors.red;
      } else if (matchingQuestion.guess.isNotEmpty) {
        return const Color(0xff2E6FEE);
      } else {
        return Color(ThemeManager.black.value);
      }
    } catch (e) {
      return Color(ThemeManager.defaultPalleteColor.value);
    }
  }

  Widget _buildQuestionsGrid() {
    final effectiveQuestionList =
        questionList.isNotEmpty ? questionList : store.questionList.value;

    if (effectiveQuestionList.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s16,
        0,
        AppTokens.s16,
        AppTokens.s24,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isWideScreen = widget.isDesktop || screenWidth >= 600;

          if (isWideScreen) {
            final crossAxisCount = 4;
            final itemCount = effectiveQuestionList.length;
            final itemHeight = 50.0;
            final mainAxisSpacing = 12.0;
            double totalHeight = 0;
            if (itemCount > 0) {
              final rowCount = (itemCount / crossAxisCount).ceil();
              totalHeight = (rowCount * itemHeight) +
                  ((rowCount - 1) * mainAxisSpacing);
            }

            return SizedBox(
              height: totalHeight,
              child: CustomDynamicHeightGridView(
                itemCount: effectiveQuestionList.length,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisCount: 4,
                builder: (BuildContext context, int index) {
                  if (index >= effectiveQuestionList.length) {
                    return const SizedBox.shrink();
                  }
                  final question = effectiveQuestionList[index];
                  return Observer(
                    builder: (_) {
                      final borderColor =
                          _getQuestionStatusColor(question.sId);
                      return _QuestionCell(
                        index: index,
                        borderColor: borderColor,
                        onTap: () {
                          store.changeIndex(index);
                          if (!widget.isDesktop) {
                            Navigator.pop(context);
                          }
                        },
                      );
                    },
                  );
                },
              ),
            );
          } else {
            return CustomDynamicHeightGridView(
              itemCount: effectiveQuestionList.length,
              physics: const BouncingScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisCount: 4,
              builder: (BuildContext context, int index) {
                if (index >= effectiveQuestionList.length) {
                  return const SizedBox.shrink();
                }
                final question = effectiveQuestionList[index];
                return Observer(
                  builder: (_) {
                    final borderColor =
                        _getQuestionStatusColor(question.sId);
                    return _QuestionCell(
                      index: index,
                      borderColor: borderColor,
                      onTap: () {
                        store.changeIndex(index);
                        if (!widget.isDesktop) {
                          Navigator.pop(context);
                        }
                      },
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          height: 28,
          width: 3,
          color: color,
        ),
        const SizedBox(width: AppTokens.s8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTokens.titleSm(context),
            ),
            Text(
              label,
              style: AppTokens.caption(context)
                  .copyWith(color: AppTokens.ink2(context), height: 1),
            ),
          ],
        ),
      ],
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

class _QuestionCell extends StatelessWidget {
  const _QuestionCell({
    required this.index,
    required this.borderColor,
    required this.onTap,
  });
  final int index;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.r8),
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTokens.surface(context),
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(AppTokens.r8),
        ),
        child: Text(
          "${index + 1}",
          style: AppTokens.titleSm(context).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
