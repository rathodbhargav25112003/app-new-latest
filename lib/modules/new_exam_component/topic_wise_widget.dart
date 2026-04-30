// ignore_for_file: deprecated_member_use, avoid_print, library_private_types_in_public_api, dead_null_aware_expression

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/models/exam_report.dart';
import 'package:shusruta_lms/models/trend_analysis_model.dart';
import 'package:shusruta_lms/modules/new_exam_component/custome_progress.dart';

/// "Topicwise Insights" card for the exam report screen. Stateful
/// because the user can select a topic from a dropdown; both the
/// rank-1 and self branches share the same widget but pick from
/// different sources based on `isRank1`.
///
/// Preserved public contract:
///   • Constructor fields and order kept byte-for-byte (12 props):
///       `correct`, `skipped`, `headerTitle`, `selected?`, `incorrect`,
///       `isRank1`, `topicReports2?`, `totalQuestions`,
///       `strengthSpotlight`, `weaknessSpotlight`, `topicReports`,
///       `topicReports1`.
///   • State pair `selectedValue` / `selectedValue1` still hydrated
///     from `widget.selected` / `widget.topicReports2` in `initState`.
///   • Dropdown still dedupes via `.toSet().toList()` on the
///     `topicReports1` branch and emits a plain `.toList()` on the
///     non-rank-1 branch — the difference is retained verbatim.
///   • `DynamicProgressBar` segment order (Correct=green,
///     Skipped=orange, Incorrect=red) and the `buildStatColumn`
///     triple below it are preserved.
///   • `StrengthSpotlight` / `WeaknessSpotlight` child widgets remain
///     public StatelessWidgets with the same
///     `List&lt;AccuracyReport&gt;` props.
///   • Public helper `buildStatColumn(String label, Color color)` kept
///     as a top-level function.
///   • `SpotlightItem({required topic, required accuracy})` class
///     retained as public type for external imports.
class TopicWiseInsights extends StatefulWidget {
  const TopicWiseInsights({
    super.key,
    required this.correct,
    required this.skipped,
    required this.headerTitle,
    this.selected,
    required this.incorrect,
    required this.isRank1,
    required this.topicReports2,
    required this.totalQuestions,
    required this.strengthSpotlight,
    required this.weaknessSpotlight,
    required this.topicReports,
    required this.topicReports1,
  });

  final int correct;
  final int skipped;
  final String headerTitle;
  final int incorrect;
  final bool isRank1;
  final int totalQuestions;
  final List<AccuracyReport> strengthSpotlight;
  final List<AccuracyReport> weaknessSpotlight;
  final List<TopicReport> topicReports;
  final List<TopicReport> topicReports1;
  final TopicReport? selected;
  final TopicReport? topicReports2;

  @override
  State<TopicWiseInsights> createState() => _TopicWiseInsightsState();
}

class _TopicWiseInsightsState extends State<TopicWiseInsights> {
  TopicReport? selectedValue;
  TopicReport? selectedValue1;

  @override
  void initState() {
    selectedValue = widget.selected;
    selectedValue1 = widget.topicReports2;
    setState(() {});
    super.initState();
  }

  TopicReport? get _active =>
      widget.isRank1 ? selectedValue1 : selectedValue;

  @override
  Widget build(BuildContext context) {
    final hasSelection = (selectedValue != null && !widget.isRank1) ||
        (selectedValue1 != null && widget.isRank1);
    final dropdownSource =
        widget.isRank1 ? widget.topicReports1 : widget.topicReports;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppTokens.s16),
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppTokens.s8,
              horizontal: AppTokens.s24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTokens.brand, AppTokens.brand2],
              ),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(AppTokens.r8),
                topLeft: Radius.circular(AppTokens.r8),
              ),
            ),
            child: Text(
              widget.headerTitle,
              style: AppTokens.caption(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppTokens.s16),
            decoration: BoxDecoration(
              color: AppTokens.surface(context),
              border: Border.all(color: AppTokens.border(context)),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(AppTokens.r12),
                bottomLeft: Radius.circular(AppTokens.r12),
                bottomRight: Radius.circular(AppTokens.r12),
              ),
              boxShadow: AppTokens.shadow2(context),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppTokens.s4),
                Row(
                  children: [
                    SvgPicture.asset('assets/image/badge.svg'),
                    const SizedBox(width: AppTokens.s8),
                    Text(
                      'Topicwise Insights',
                      style: AppTokens.titleSm(context).copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s16),
                if (hasSelection) ...[
                  Text(
                    'Choose Topic',
                    style: AppTokens.overline(context).copyWith(
                      color: AppTokens.ink(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppTokens.s4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.s12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTokens.surface2(context),
                      border: Border.all(color: AppTokens.border(context)),
                      borderRadius: BorderRadius.circular(AppTokens.r8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: AppTokens.surface(context),
                        value: _active?.topicName,
                        items: widget.isRank1
                            ? dropdownSource
                                .map((e) => e.topicName ?? '')
                                .map(
                                  (topic) => DropdownMenuItem(
                                    value: topic,
                                    child: Text(
                                      topic,
                                      style: AppTokens.body(context).copyWith(
                                        color: AppTokens.ink(context),
                                      ),
                                    ),
                                  ),
                                )
                                .toSet()
                                .toList()
                            : dropdownSource
                                .map((e) => e.topicName ?? '')
                                .map(
                                  (topic) => DropdownMenuItem(
                                    value: topic,
                                    child: Text(
                                      topic,
                                      style: AppTokens.body(context).copyWith(
                                        color: AppTokens.ink(context),
                                      ),
                                    ),
                                  ),
                                )
                                .toSet()
                                .toList(),
                        onChanged: (value) {
                          if (widget.isRank1) {
                            setState(() {
                              selectedValue1 = widget.topicReports1
                                  .firstWhere((e) => e.topicName == value);
                            });
                            print(selectedValue!.skippedAnswers.toString());
                          } else {
                            setState(() {
                              selectedValue = widget.topicReports
                                  .firstWhere((e) => e.topicName == value);
                            });
                            print(selectedValue!.skippedAnswers.toString());
                          }
                        },
                        isExpanded: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTokens.s16),
                  DynamicProgressBar(
                    progressItems: [
                      ProgressItem(
                        color: Colors.green,
                        label: 'Correct',
                        value: _active!.correctAnswers!,
                      ),
                      ProgressItem(
                        color: Colors.orange,
                        label: 'Skipped',
                        value: _active!.skippedAnswers!,
                      ),
                      ProgressItem(
                        color: Colors.red,
                        label: 'Incorrect',
                        value: _active!.incorrectAnswers!,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.s12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Total Questions  ',
                        style: AppTokens.body(context).copyWith(
                          color: AppTokens.muted(context),
                        ),
                      ),
                      Text(
                        _active!.totalQuestions.toString(),
                        style: AppTokens.body(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTokens.ink(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.s16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      buildStatColumn(
                        'Correct (${_active!.correctAnswers!})',
                        Colors.green,
                      ),
                      buildStatColumn(
                        'Skipped (${_active!.skippedAnswers!})',
                        Colors.orange,
                      ),
                      buildStatColumn(
                        'Incorrect (${_active!.incorrectAnswers!})',
                        Colors.red,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppTokens.s16),
                StrengthSpotlight(
                  strengthSpotlight: widget.strengthSpotlight,
                ),
                const SizedBox(height: AppTokens.s24),
                WeaknessSpotlight(
                  weaknessSpotlight: widget.weaknessSpotlight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Public data class retained for any external imports that referenced
/// it directly.
class SpotlightItem {
  SpotlightItem({required this.topic, required this.accuracy});

  final String topic;
  final String accuracy;
}

/// "Strength Spotlight" table — top-correct topics list.
class StrengthSpotlight extends StatelessWidget {
  const StrengthSpotlight({super.key, required this.strengthSpotlight});

  final List<AccuracyReport> strengthSpotlight;

  @override
  Widget build(BuildContext context) {
    return _SpotlightTable(
      title: 'Strength Spotlight',
      rows: strengthSpotlight,
      accuracyColor: Colors.green,
    );
  }
}

/// "Weakness Spotlight" table — weakest-accuracy topics list.
class WeaknessSpotlight extends StatelessWidget {
  const WeaknessSpotlight({super.key, required this.weaknessSpotlight});

  final List<AccuracyReport> weaknessSpotlight;

  @override
  Widget build(BuildContext context) {
    return _SpotlightTable(
      title: 'Weakness Spotlight',
      rows: weaknessSpotlight,
      accuracyColor: Colors.red,
    );
  }
}

class _SpotlightTable extends StatelessWidget {
  const _SpotlightTable({
    required this.title,
    required this.rows,
    required this.accuracyColor,
  });

  final String title;
  final List<AccuracyReport> rows;
  final Color accuracyColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTokens.body(context).copyWith(
            fontWeight: FontWeight.w700,
            color: AppTokens.ink(context),
          ),
        ),
        const SizedBox(height: AppTokens.s4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Topic',
              style: AppTokens.overline(context).copyWith(
                color: AppTokens.muted(context),
              ),
            ),
            Text(
              'Accuracy',
              style: AppTokens.overline(context).copyWith(
                color: AppTokens.muted(context),
              ),
            ),
          ],
        ),
        Divider(color: AppTokens.border(context)),
        Column(
          children: rows
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTokens.s4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            SvgPicture.asset('assets/image/bullet_icon.svg'),
                            const SizedBox(width: AppTokens.s4),
                            Flexible(
                              child: Text(
                                e.topicName ?? '',
                                style: AppTokens.caption(context).copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: AppTokens.ink(context),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        e.accuracyPercentage ?? '',
                        style: AppTokens.caption(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: accuracyColor,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

/// Public helper retained — small legend row (coloured dot + label).
/// Positional signature `(label, color)` preserved so external callers
/// continue to compile.
Widget buildStatColumn(String label, Color color) {
  return Builder(
    builder: (context) {
      return Row(
        children: [
          CircleAvatar(radius: 5, backgroundColor: color),
          const SizedBox(width: AppTokens.s8),
          Text(
            label,
            style: AppTokens.caption(context).copyWith(
              color: AppTokens.ink(context),
            ),
          ),
        ],
      );
    },
  );
}

/// Per-exam trend list for the selected topic.
///
/// Preserved contract:
///   • Constructor `TopicWiseTrendWidget({super.key, required
///     List&lt;TrendAnalysisModel&gt; trendAnalysisModel})`.
///   • Dropdown seeds from `trendAnalysisModel[0].topicWiseReport`;
///     selection survives across rebuilds.
///   • Per-exam row uses `firstWhereOrNull` (from
///     `package:get/get.dart`) to locate the matching topic report,
///     which may be null — "No Data Avalible " fallback retained
///     including the original typo.
///   • "Not Attempted" fallback preserved when
///     `!trendAnalysisModel[i].isAttempt`.
///   • DynamicProgressBar segments: Correct=green, Skipped=orange,
///     Incorrect=red.
class TopicWiseTrendWidget extends StatefulWidget {
  const TopicWiseTrendWidget({super.key, required this.trendAnalysisModel});

  final List<TrendAnalysisModel> trendAnalysisModel;

  @override
  State<TopicWiseTrendWidget> createState() => _TopicWiseTrendWidgetState();
}

class _TopicWiseTrendWidgetState extends State<TopicWiseTrendWidget> {
  TopicWiseReport? selected;

  @override
  void initState() {
    if (widget.trendAnalysisModel.isNotEmpty) {
      if (widget.trendAnalysisModel[0].topicWiseReport.isNotEmpty) {
        selected = widget.trendAnalysisModel[0].topicWiseReport[0];
        setState(() {});
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTokens.s20),
          Container(
            padding: const EdgeInsets.all(AppTokens.s16),
            decoration: BoxDecoration(
              color: AppTokens.surface(context),
              border: Border.all(color: AppTokens.border(context)),
              borderRadius: BorderRadius.circular(AppTokens.r12),
              boxShadow: AppTokens.shadow1(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SvgPicture.asset('assets/image/badge.svg'),
                    const SizedBox(width: AppTokens.s8),
                    Text(
                      'Topicwise Insights',
                      style: AppTokens.titleSm(context).copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s12),
                Text(
                  'Choose Topic',
                  style: AppTokens.overline(context).copyWith(
                    color: AppTokens.ink(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTokens.s4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.s12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTokens.surface2(context),
                    border: Border.all(color: AppTokens.border(context)),
                    borderRadius: BorderRadius.circular(AppTokens.r8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      dropdownColor: AppTokens.surface(context),
                      value: selected?.topicName,
                      items: widget.trendAnalysisModel[0].topicWiseReport
                          .map((e) => e.topicName ?? '')
                          .map(
                            (topic) => DropdownMenuItem(
                              value: topic,
                              child: Text(
                                topic,
                                style: AppTokens.body(context).copyWith(
                                  color: AppTokens.ink(context),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selected = widget
                              .trendAnalysisModel[0].topicWiseReport
                              .firstWhere((e) => e.topicName == value);
                        });
                      },
                      isExpanded: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (selected != null) ...[
            const SizedBox(height: AppTokens.s16),
            ListView.builder(
              itemCount: widget.trendAnalysisModel.length,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                final item = widget.trendAnalysisModel[index];
                final TopicWiseReport? currentSelected = item.topicWiseReport
                    .firstWhereOrNull((e) => e.topicName == selected!.topicName);
                return _TrendRow(
                  index: index,
                  height: 96,
                  isAttempted: item.isAttempt,
                  body: currentSelected == null
                      ? Center(
                          child: Text(
                            'No Data Avalible ',
                            style: AppTokens.caption(context).copyWith(
                              color: AppTokens.muted(context),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.s12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: AppTokens.s4),
                              DynamicProgressBar(
                                progressItems: [
                                  ProgressItem(
                                    color: Colors.green,
                                    label: 'Correct',
                                    value: currentSelected.correctAnswers,
                                  ),
                                  ProgressItem(
                                    color: Colors.orange,
                                    label: 'Skipped',
                                    value: currentSelected.skippedAnswers,
                                  ),
                                  ProgressItem(
                                    color: Colors.red,
                                    label: 'Incorrect',
                                    value: currentSelected.incorrectAnswers,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTokens.s8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Total Questions  ',
                                    style: AppTokens.body(context).copyWith(
                                      color: AppTokens.muted(context),
                                    ),
                                  ),
                                  Text(
                                    currentSelected.totalQuestions.toString(),
                                    style: AppTokens.body(context).copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppTokens.ink(context),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// Per-exam strength-spotlight trend list.
class TrendStrengthAnalysisWidget extends StatelessWidget {
  const TrendStrengthAnalysisWidget({
    super.key,
    required this.trendAnalysisModel,
  });

  final List<TrendAnalysisModel> trendAnalysisModel;

  @override
  Widget build(BuildContext context) {
    return _SpotlightTrendList(
      headerTitle: 'Strength Spotlight',
      trendAnalysisModel: trendAnalysisModel,
      rowsForItem: (item) => item.topThreeCorrect,
      accuracyColor: Colors.green,
    );
  }
}

/// Per-exam weakness-spotlight trend list.
class TrendWeaknessAnalysisWidget extends StatelessWidget {
  const TrendWeaknessAnalysisWidget({
    super.key,
    required this.trendAnalysisModel,
  });

  final List<TrendAnalysisModel> trendAnalysisModel;

  @override
  Widget build(BuildContext context) {
    return _SpotlightTrendList(
      headerTitle: 'Weakness Spotlight',
      trendAnalysisModel: trendAnalysisModel,
      rowsForItem: (item) => item.lastThreeIncorrect,
      accuracyColor: Colors.red,
    );
  }
}

/// Duck-typed row accessor for the shared `_SpotlightTrendList`.
/// `TopThreeCorrect` and `LastThreeIncorrect` share the same field
/// surface (`topicName` / `correctAnswers` / `totalQuestions`) but do
/// not implement a common interface, so we accept `List&lt;dynamic&gt;`
/// and rely on dynamic field access inside the list (same as the
/// original untyped code).
typedef _AccuracyRowsFor = List<dynamic> Function(TrendAnalysisModel item);

/// Shared trend list used by `TrendStrengthAnalysisWidget` and
/// `TrendWeaknessAnalysisWidget`. The accuracy string formula is kept
/// byte-for-byte:
/// `"${(e.correctAnswers! / e.totalQuestions! * 100).toStringAsFixed(2)}%"`.
class _SpotlightTrendList extends StatelessWidget {
  const _SpotlightTrendList({
    required this.headerTitle,
    required this.trendAnalysisModel,
    required this.rowsForItem,
    required this.accuracyColor,
  });

  final String headerTitle;
  final List<TrendAnalysisModel> trendAnalysisModel;
  final _AccuracyRowsFor rowsForItem;
  final Color accuracyColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTokens.s20),
          Container(
            padding: const EdgeInsets.all(AppTokens.s16),
            decoration: BoxDecoration(
              color: AppTokens.surface(context),
              border: Border.all(color: AppTokens.border(context)),
              borderRadius: BorderRadius.circular(AppTokens.r12),
              boxShadow: AppTokens.shadow1(context),
            ),
            child: Row(
              children: [
                SvgPicture.asset('assets/image/badge.svg'),
                const SizedBox(width: AppTokens.s8),
                Text(
                  headerTitle,
                  style: AppTokens.titleSm(context).copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          ListView.builder(
            itemCount: trendAnalysisModel.length,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              final item = trendAnalysisModel[index];
              final rows = rowsForItem(item);
              return _TrendRow(
                index: index,
                height: 124,
                isAttempted: item.isAttempt,
                body: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.s12,
                    vertical: AppTokens.s8,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Topic',
                            style: AppTokens.overline(context).copyWith(
                              color: AppTokens.muted(context),
                            ),
                          ),
                          Text(
                            'Accuracy',
                            style: AppTokens.overline(context).copyWith(
                              color: AppTokens.muted(context),
                            ),
                          ),
                        ],
                      ),
                      Divider(color: AppTokens.border(context)),
                      Column(
                        children: rows
                            .map(
                              (e) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: AppTokens.s4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          SvgPicture.asset(
                                              'assets/image/bullet_icon.svg'),
                                          const SizedBox(
                                              width: AppTokens.s4),
                                          Flexible(
                                            child: Text(
                                              e.topicName ?? '',
                                              style: AppTokens.caption(
                                                      context)
                                                  .copyWith(
                                                fontWeight: FontWeight.w500,
                                                color: AppTokens.ink(context),
                                              ),
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${(e.correctAnswers! / e.totalQuestions! * 100).toStringAsFixed(2)}%',
                                      style:
                                          AppTokens.caption(context).copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: accuracyColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Shared per-exam row (rotated brand-gradient badge + right-side
/// panel with optional `isAttempted` gate for "Not Attempted"
/// fallback). Used by `TopicWiseTrendWidget` and `_SpotlightTrendList`.
class _TrendRow extends StatelessWidget {
  const _TrendRow({
    required this.index,
    required this.height,
    required this.isAttempted,
    required this.body,
  });

  final int index;
  final double height;
  final bool isAttempted;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppTokens.s16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: height,
            width: 32,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTokens.brand, AppTokens.brand2],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppTokens.r12),
                bottomLeft: Radius.circular(AppTokens.r12),
              ),
            ),
            alignment: Alignment.center,
            child: RotatedBox(
              quarterTurns: 3,
              child: Text(
                'Exam ${index + 1}',
                style: AppTokens.caption(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: AppTokens.surface(context),
                border: Border.all(color: AppTokens.border(context)),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(AppTokens.r12),
                  bottomRight: Radius.circular(AppTokens.r12),
                ),
                boxShadow: AppTokens.shadow1(context),
              ),
              child: !isAttempted
                  ? Center(
                      child: Text(
                        'Not Attempted',
                        style: AppTokens.caption(context).copyWith(
                          color: AppTokens.muted(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : body,
            ),
          ),
        ],
      ),
    );
  }
}
