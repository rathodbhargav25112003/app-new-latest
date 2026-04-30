// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';

/// Trend-analysis predictive rank preview card. Redesigned with
/// AppTokens while preserving the public contract:
///   • Constructor `PredictionCard({super.key})` — no parameters,
///     same call sites compile unchanged.
///   • Overall visual structure remains: rotated left badge +
///     title + stacked progress bar + low/high rank labels.
///
/// The redesign tokenises colours, softens the rotated-badge
/// gradient, and gives the right panel a proper card surface with a
/// border + soft shadow.
class PredictionCard extends StatelessWidget {
  const PredictionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppTokens.s16),
      child: Row(
        children: [
          _ExamBadge(),
          Expanded(child: _PredictionBody()),
        ],
      ),
    );
    return card;
  }
}

class _ExamBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
          'Exam 1',
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

class _PredictionBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s16,
          vertical: AppTokens.s12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Prediction - NEET SS \'25',
              style: AppTokens.caption(context).copyWith(
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
                    color: AppTokens.surface3(context),
                    borderRadius: BorderRadius.circular(AppTokens.r8 / 2),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: 0.5,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTokens.brand, AppTokens.brand2],
                      ),
                      borderRadius: BorderRadius.circular(AppTokens.r8 / 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.s8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '10000',
                  style: AppTokens.numeric(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTokens.ink(context),
                  ),
                ),
                Text(
                  '12000',
                  style: AppTokens.numeric(context).copyWith(
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
  }
}
