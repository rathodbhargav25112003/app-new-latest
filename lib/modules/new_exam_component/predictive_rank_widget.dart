// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/models/trend_analysis_model.dart';
import 'package:shusruta_lms/modules/new_exam_component/exam_report_screen.dart';

/// Predictive-ranking summary card shown on the exam report screen.
///
/// Preserved public contract:
///   • Constructor `PredictiveRankingWidget({super.key, required
///     String headerTitle, required String rankingTitle, required
///     String badgeIconPath, required List&lt;RankItem&gt; rankItems})`
///     — fields, order, and names unchanged.
///   • Public method `buildRankItem({required label, required value,
///     required endValue, required progress, required color})`
///     retained so existing call-sites keep compiling.
///   • The long legal disclaimer text is reproduced verbatim so
///     marketing / legal review stays stable across the redesign.
class PredictiveRankingWidget extends StatelessWidget {
  const PredictiveRankingWidget({
    super.key,
    required this.headerTitle,
    required this.rankingTitle,
    required this.badgeIconPath,
    required this.rankItems,
  });

  final String headerTitle;
  final String rankingTitle;
  final String badgeIconPath;
  final List<RankItem> rankItems;

  @override
  Widget build(BuildContext context) {
    return Column(
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
            headerTitle,
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
              const SizedBox(height: AppTokens.s8),
              Row(
                children: [
                  SvgPicture.asset(badgeIconPath),
                  const SizedBox(width: AppTokens.s8),
                  Text(
                    rankingTitle,
                    style: AppTokens.titleSm(context).copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.s16),
              for (final item in rankItems)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTokens.s12),
                  child: buildRankItem(
                    label: item.label,
                    value: item.value,
                    endValue: item.endValue,
                    progress: item.progress,
                    color: item.color,
                  ),
                ),
              const SizedBox(height: AppTokens.s8),
              Divider(color: AppTokens.border(context)),
              _DisclaimerText(
                body:
                    'The NEET SS surgical Group Rank Predictor offers an estimated rank based on past data, with a possible variation of +100-200 ranks. It is intended for guidance and may not represent the exact final rank.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Public API retained. Rendered via `Builder` so the body can reach
  /// `BuildContext` without a breaking signature change.
  Widget buildRankItem({
    required String label,
    required String value,
    required String endValue,
    required double progress,
    required Color color,
  }) {
    return Builder(
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTokens.body(context).copyWith(
                fontWeight: FontWeight.w600,
                color: AppTokens.ink(context),
              ),
            ),
            const SizedBox(height: AppTokens.s4),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTokens.r8 / 2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppTokens.surface3(context),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: AppTokens.s4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: AppTokens.caption(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTokens.ink(context),
                  ),
                ),
                Text(
                  endValue,
                  style: AppTokens.caption(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTokens.ink(context),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class RankItem {
  RankItem({
    required this.label,
    required this.value,
    required this.endValue,
    required this.progress,
    required this.color,
  });

  final String label;
  final String value;
  final String endValue;
  final double progress;
  final Color color;
}

/// Per-exam predictive-ranking trend card.
///
/// Preserved contract:
///   • Constructor `TrendPredictiveRankingWidget({super.key, required
///     List&lt;TrendAnalysisModel&gt; trendAnalysisModel, required
///     List&lt;Map&lt;String, dynamic&gt;&gt; score})`
///   • `NeverScrollableScrollPhysics` + `shrinkWrap: true` ListView
///     with `EdgeInsets.zero` padding.
///   • "Not Attempted" fallback when `!trendAnalysisModel[i].isAttempt`.
///   • Otherwise renders "Prediction - NEET SS '25" header + a custom
///     two-stack progress row driven by the legacy helper
///     `getProgress(...)` (still imported from
///     `exam_report_screen.dart`) with the existing
///     `predicted_rank_2024.split("-")[0]` / `[1]` parse.
///   • Rotated "Exam N" badge with brand gradient and the identical
///     disclaimer text block are retained verbatim.
class TrendPredictiveRankingWidget extends StatelessWidget {
  const TrendPredictiveRankingWidget({
    super.key,
    required this.trendAnalysisModel,
    required this.score,
  });

  final List<TrendAnalysisModel> trendAnalysisModel;
  final List<Map<String, dynamic>> score;

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
                  'Predictive NEET SS Ranking',
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
              final startRank = item.predicted_rank_2024
                  .split('-')[0]
                  .toString()
                  .trim();
              final endRank = item.predicted_rank_2024
                  .split('-')[1]
                  .toString()
                  .trim();
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: AppTokens.s16),
                child: Row(
                  children: [
                    Container(
                      height: 88,
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
                        height: 88,
                        decoration: BoxDecoration(
                          color: AppTokens.surface(context),
                          border: Border.all(color: AppTokens.border(context)),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(AppTokens.r12),
                            bottomRight: Radius.circular(AppTokens.r12),
                          ),
                          boxShadow: AppTokens.shadow1(context),
                        ),
                        child: !item.isAttempt
                            ? Center(
                                child: Text(
                                  'Not Attempted',
                                  style:
                                      AppTokens.caption(context).copyWith(
                                    color: AppTokens.muted(context),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppTokens.s12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Prediction - NEET SS \'25',
                                      style:
                                          AppTokens.caption(context).copyWith(
                                        color: AppTokens.ink(context),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: AppTokens.s8),
                                    Stack(
                                      children: [
                                        Container(
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color:
                                                AppTokens.surface3(context),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                        FractionallySizedBox(
                                          widthFactor: getProgress(startRank),
                                          child: Container(
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: Colors.orange,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppTokens.s8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          startRank,
                                          style: AppTokens.body(context)
                                              .copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: AppTokens.ink(context),
                                          ),
                                        ),
                                        Text(
                                          endRank,
                                          style: AppTokens.body(context)
                                              .copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: AppTokens.ink(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppTokens.s16),
          Container(
            padding: const EdgeInsets.all(AppTokens.s16),
            decoration: BoxDecoration(
              color: AppTokens.surface(context),
              border: Border.all(color: AppTokens.border(context)),
              borderRadius: BorderRadius.circular(AppTokens.r12),
              boxShadow: AppTokens.shadow1(context),
            ),
            child: _DisclaimerText(
              body:
                  'The NEET SS surgical Group Rank Predictor offers an estimated rank based on past data, with a possible variation of + 100-200 ranks. it is intended for guidance and may not represent the exact final rank.',
            ),
          ),
        ],
      ),
    );
  }
}

class _DisclaimerText extends StatelessWidget {
  const _DisclaimerText({required this.body});
  final String body;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: <TextSpan>[
          TextSpan(
            text: 'Disclaimer: ',
            style: AppTokens.caption(context).copyWith(
              color: AppTokens.muted(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: body,
            style: AppTokens.caption(context).copyWith(
              color: AppTokens.muted(context),
            ),
          ),
        ],
      ),
    );
  }
}
