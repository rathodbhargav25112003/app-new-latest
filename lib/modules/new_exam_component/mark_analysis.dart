// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/models/trend_analysis_model.dart';
import 'package:shusruta_lms/modules/new_exam_component/custome_progress.dart';

/// Marks-analysis trend view showing per-exam rank + marks +
/// correct/skipped/incorrect breakdown via the shared
/// `DynamicProgressBar`.
///
/// Preserved public contract:
///   • Constructor `TrendMarkWidget({super.key, required
///     List&lt;TrendAnalysisModel&gt; trendAnalysisModel})`
///   • Iterates `trendAnalysisModel.length` entries with a
///     `NeverScrollableScrollPhysics` + `shrinkWrap: true` ListView.
///   • For each entry renders a rotated "Exam N" badge + a panel that
///     shows "Not Attempted" when `!isAttempt`, otherwise two
///     `DynamicProgressBar`s:
///       1. Rank (blue) + Marks (purple)
///       2. Correct (green) + Skipped (orange) + Incorrect (red)
///     — colours + labels preserved verbatim so historical data stays
///     comparable.
class TrendMarkWidget extends StatelessWidget {
  const TrendMarkWidget({super.key, required this.trendAnalysisModel});

  final List<TrendAnalysisModel> trendAnalysisModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTokens.s20),
          _SectionHeader(context: context),
          const SizedBox(height: AppTokens.s16),
          ListView.builder(
            itemCount: trendAnalysisModel.length,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              final item = trendAnalysisModel[index];
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: AppTokens.s16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExamBadge(index: index),
                    Expanded(child: _ExamPanel(item: item)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.context});
  final BuildContext context;

  @override
  Widget build(BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: AppTokens.surface(ctx),
        border: Border.all(color: AppTokens.border(ctx)),
        borderRadius: BorderRadius.circular(AppTokens.r12),
        boxShadow: AppTokens.shadow1(ctx),
      ),
      child: Row(
        children: [
          SvgPicture.asset('assets/image/badge.svg'),
          const SizedBox(width: AppTokens.s8),
          Text(
            'Marks Analysis',
            style: AppTokens.titleSm(ctx).copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamBadge extends StatelessWidget {
  const _ExamBadge({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
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
    );
  }
}

class _ExamPanel extends StatelessWidget {
  const _ExamPanel({required this.item});
  final TrendAnalysisModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        border: Border.all(color: AppTokens.border(context)),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(AppTokens.r12),
          bottomRight: Radius.circular(AppTokens.r12),
          bottomLeft: Radius.circular(AppTokens.r12),
        ),
        boxShadow: AppTokens.shadow1(context),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s12),
      child: !item.isAttempt
          ? Center(
              child: Text(
                'Not Attempted',
                style: AppTokens.caption(context).copyWith(
                  color: AppTokens.muted(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: AppTokens.s12),
                DynamicProgressBar(
                  progressItems: [
                    ProgressItem(
                      color: Colors.blue,
                      label: 'Rank',
                      value: item.userRank,
                    ),
                    ProgressItem(
                      color: Colors.purple,
                      label: 'Marks',
                      value: item.mymark.toInt(),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s8),
                DynamicProgressBar(
                  progressItems: [
                    ProgressItem(
                      color: Colors.green,
                      label: 'Correct',
                      value: item.correctAnswers,
                    ),
                    ProgressItem(
                      color: Colors.orange,
                      label: 'Skipped',
                      value: item.skippedAnswers,
                    ),
                    ProgressItem(
                      color: Colors.red,
                      label: 'Incorrect',
                      value: item.incorrectAnswers,
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
