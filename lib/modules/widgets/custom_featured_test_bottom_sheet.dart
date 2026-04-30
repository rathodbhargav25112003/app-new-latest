import 'dart:io';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
// ignore: unnecessary_import
import 'package:carousel_slider/carousel_controller.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:nuts_activity_indicator/nuts_activity_indicator.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../models/featured_list_model.dart';
import '../test/store/test_category_store.dart';
import 'bottom_toast.dart';
// Legacy imports preserved for API parity; no longer referenced by the UI.
// ignore: unused_import
import '../../helpers/colors.dart';
// ignore: unused_import
import '../../helpers/styles.dart';
// ignore: unused_import
import '../../helpers/dimensions.dart';
// ignore: unused_import, unnecessary_import
import 'package:flutter/cupertino.dart';
// ignore: unused_import
import 'custom_button.dart';

/// CustomFeaturedTestBottomSheet — featured-test pre-flight bottom sheet.
/// Public surface preserved exactly:
///   • const constructor `(BuildContext context, this.featuredTestExamPaper,
///     this.isPractice, {super.key})` with `TestsPaper?` / `bool?` positional
///     args
///   • renders an MobX [Observer] gated on `TestCategoryStore.isLoading`
///   • `_startExamApiCall(store, testExamPaper, isPractice)` helper retained
///   • Navigates to [Routes.featuredTestExamPage] with
///     `{'featuredTestData': widget.featuredTestExamPaper, 'userexamId': …}`
class CustomFeaturedTestBottomSheet extends StatefulWidget {
  final TestsPaper? featuredTestExamPaper;
  final bool? isPractice;
  const CustomFeaturedTestBottomSheet(
    BuildContext context,
    this.featuredTestExamPaper,
    this.isPractice, {
    super.key,
  });

  @override
  State<CustomFeaturedTestBottomSheet> createState() =>
      _CustomFeaturedTestBottomSheetState();
}

class _CustomFeaturedTestBottomSheetState
    extends State<CustomFeaturedTestBottomSheet> {
  final CarouselSliderController _controller = CarouselSliderController();

  bool get _isDesktop => Platform.isWindows || Platform.isMacOS;

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: _isDesktop
          ? const BoxConstraints(maxWidth: 560)
          : null,
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: _isDesktop
            ? BorderRadius.circular(AppTokens.r20)
            : const BorderRadius.vertical(
                top: Radius.circular(AppTokens.r20),
              ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.s20,
          AppTokens.s16,
          AppTokens.s20,
          AppTokens.s20,
        ),
        child: Observer(
          builder: (BuildContext context) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_isDesktop)
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppTokens.s12),
                      decoration: BoxDecoration(
                        color: AppTokens.border(context),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                Center(
                  child: Text(
                    widget.featuredTestExamPaper?.examName ?? '',
                    textAlign: TextAlign.center,
                    style: AppTokens.titleMd(context)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: AppTokens.s12),
                Expanded(
                  child: store.isLoading
                      ? _LoadingCarousel(controller: _controller)
                      : _InstructionPanel(
                          negativeMarking:
                              widget.featuredTestExamPaper?.negativeMarking ==
                                  true,
                          marksDeducted:
                              widget.featuredTestExamPaper?.marksDeducted
                                      ?.toString() ??
                                  '',
                          instruction:
                              widget.featuredTestExamPaper?.instruction ?? '',
                        ),
                ),
                const SizedBox(height: AppTokens.s16),
                _GradientCta(
                  label: 'Start Test',
                  icon: Icons.play_arrow_rounded,
                  onTap: () async {
                    await _startExamApiCall(
                      store,
                      widget.featuredTestExamPaper,
                      widget.isPractice,
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _startExamApiCall(
    TestCategoryStore store,
    TestsPaper? testExamPaper,
    bool? isPractice,
  ) async {
    final String examId = testExamPaper?.examId ?? '';
    final DateTime now = DateTime.now();
    final String startTime =
        DateFormat('yyyy-MM-ddTHH:mm:ss.SSSZ').format(now);
    final String timeDuration = testExamPaper?.timeDuration ?? '';
    final List<String> timeParts = timeDuration.split(':');
    final Duration duration = Duration(
      hours: int.parse(timeParts[0]),
      minutes: int.parse(timeParts[1]),
      seconds: int.parse(timeParts[2]),
    );
    final DateTime startDateTime = DateTime.parse(startTime);
    final DateTime endDateTime = startDateTime.add(duration);
    final String endTime =
        DateFormat('yyyy-MM-ddTHH:mm:ss.SSSZ').format(endDateTime);

    await store.startCreateExam(examId, startTime, endTime, isPractice, '', '');
    final String? userExamId = store.startExam.value?.id;
    if (!mounted) return;
    if (widget.featuredTestExamPaper?.questions?.isNotEmpty ?? false) {
      if (store.startExam.value?.err?.message == null) {
        Navigator.of(context).pushNamed(
          Routes.featuredTestExamPage,
          arguments: {
            'featuredTestData': widget.featuredTestExamPaper,
            'userexamId': userExamId,
          },
        );
      } else {
        BottomToast.showBottomToastOverlay(
          context: context,
          errorMessage: store.startExam.value?.err?.message ?? '',
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    } else {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: 'Exam Paper Not Found!',
        backgroundColor: AppTokens.danger(context),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Internal blocks
// ---------------------------------------------------------------------------

class _LoadingCarousel extends StatelessWidget {
  const _LoadingCarousel({required this.controller});

  final CarouselSliderController controller;

  @override
  Widget build(BuildContext context) {
    final List<String> copy = const [
      'Get ready to begin the test. Stay focused and give it your best shot. Good luck!',
      "Test starting soon. Ready to show what you know? Let's go!",
      "Test beginning. Ready? Show what you've got!",
      'Test starting. Ready to shine?',
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        NutsActivityIndicator(
          activeColor: AppTokens.accent(context),
          animating: true,
          radius: 20,
        ),
        const SizedBox(height: AppTokens.s20),
        CarouselSlider(
          items: copy
              .map(
                (line) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.s16,
                  ),
                  child: Text(
                    line,
                    textAlign: TextAlign.center,
                    style: AppTokens.body(context).copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppTokens.ink2(context),
                    ),
                  ),
                ),
              )
              .toList(),
          carouselController: controller,
          options: CarouselOptions(
            autoPlay: true,
            enableInfiniteScroll: false,
            viewportFraction: 1,
            scrollPhysics: const NeverScrollableScrollPhysics(),
            aspectRatio: 4,
          ),
        ),
      ],
    );
  }
}

class _InstructionPanel extends StatelessWidget {
  const _InstructionPanel({
    required this.negativeMarking,
    required this.marksDeducted,
    required this.instruction,
  });

  final bool negativeMarking;
  final String marksDeducted;
  final String instruction;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Instructions',
            style: AppTokens.titleSm(context)
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppTokens.s12),
          const _LegendDot(
            color: Color(0xFF10B981),
            label: 'Attempted',
          ),
          const SizedBox(height: AppTokens.s8),
          const _LegendDot(
            color: Color(0xFF3B82F6),
            label: 'Marked for Review',
          ),
          const SizedBox(height: AppTokens.s8),
          const _LegendDot(
            color: Color(0xFFF59E0B),
            label: 'Attempted and Marked for Review',
          ),
          const SizedBox(height: AppTokens.s8),
          const _LegendDot(
            color: Color(0xFFEF4444),
            label: 'Skipped',
          ),
          const SizedBox(height: AppTokens.s8),
          _LegendDot(
            color: AppTokens.ink(context),
            label: 'Not Visited',
          ),
          const SizedBox(height: AppTokens.s12),
          Text(
            'Touch again on attempted answer to clear',
            style: AppTokens.caption(context).copyWith(
              color: AppTokens.ink2(context),
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          if (negativeMarking) ...[
            Container(
              padding: const EdgeInsets.all(AppTokens.s12),
              decoration: BoxDecoration(
                color: AppTokens.dangerSoft(context),
                borderRadius: BorderRadius.circular(AppTokens.r12),
              ),
              child: Row(
                children: [
                  Icon(Icons.remove_circle_outline_rounded,
                      color: AppTokens.danger(context), size: 18),
                  const SizedBox(width: AppTokens.s8),
                  Expanded(
                    child: Text(
                      'Marks deduction: $marksDeducted',
                      style: AppTokens.caption(context).copyWith(
                        color: AppTokens.danger(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.s12),
          ],
          ExpandableText(
            instruction,
            style: AppTokens.body(context).copyWith(
              color: AppTokens.ink2(context),
            ),
            expandText: 'see more',
            maxLines: 3,
            collapseText: '........show less',
            linkColor: AppTokens.accent(context),
          ),
          const SizedBox(height: AppTokens.s12),
        ],
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
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppTokens.s12),
        Expanded(
          child: Text(
            label,
            style: AppTokens.caption(context).copyWith(
              color: AppTokens.ink2(context),
            ),
          ),
        ),
      ],
    );
  }
}

class _GradientCta extends StatelessWidget {
  const _GradientCta({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTokens.brand, AppTokens.brand2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTokens.r12),
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: AppTokens.brand.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: AppTokens.s8),
              Text(
                label,
                style: AppTokens.body(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
