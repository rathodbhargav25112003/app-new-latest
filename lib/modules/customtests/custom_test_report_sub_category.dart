// ignore_for_file: use_build_context_synchronously, deprecated_member_use, use_super_parameters, unused_import

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:nuts_activity_indicator/nuts_activity_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/modules/reports/store/report_by_category_store.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';
import '../../models/report_by_category_model.dart';
import '../widgets/no_internet_connection.dart';
import 'model/custom_test_report_by_category_model.dart';

class CustomTestReportSubCategory extends StatefulWidget {
  final String id;
  final String title;
  final String? type;

  const CustomTestReportSubCategory(
      {Key? key, required this.id, required this.type, required this.title})
      : super(key: key);

  @override
  State<CustomTestReportSubCategory> createState() =>
      _CustomTestReportSubCategoryState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => CustomTestReportSubCategory(
        id: arguments['id'],
        title: arguments['title'],
        type: arguments['type'],
      ),
    );
  }
}

class _CustomTestReportSubCategoryState
    extends State<CustomTestReportSubCategory> {
  // ignore: unused_field
  String query = '';

  @override
  void initState() {
    super.initState();
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    store.onCustomTestReportByCategoryApiCall(widget.id);
  }

  Future<void> _solutionReport(String examId, String filter) async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onCustomTestSolutionReportApiCall(examId).then((_) {
      Navigator.of(context)
          .pushNamed(Routes.customTestSolutionReport, arguments: {
        'solutionReport': store.customTestSolutionReportCategory,
        'filterVal': filter,
        'userExamId': examId
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          _GradientHeader(
            title: widget.title,
            subtitle: 'Attempt history and analysis',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTokens.scaffold(context),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTokens.r28),
                  topRight: Radius.circular(AppTokens.r28),
                ),
              ),
              child: Observer(
                builder: (_) {
                  if (store.isLoading) {
                    return _LoadingState();
                  }
                  if (store.customtestreportscategory.isEmpty) {
                    return _EmptyState();
                  }
                  if (!store.isConnected) {
                    return const NoInternetScreen();
                  }
                  return ListView.separated(
                    itemCount: store.customtestreportscategory.length,
                    padding: const EdgeInsets.fromLTRB(
                      AppTokens.s20,
                      AppTokens.s20,
                      AppTokens.s20,
                      AppTokens.s24,
                    ),
                    physics: const BouncingScrollPhysics(),
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppTokens.s16),
                    itemBuilder: (BuildContext context, int index) {
                      CustomTestReportByCategoryModel? reportsCat =
                          store.customtestreportscategory[index];
                      String originalDate = reportsCat?.date ?? "";
                      DateTime parsedDate = DateTime.tryParse(originalDate) ??
                          DateTime.now();
                      final formatter = DateFormat('dd MMM, yyyy');
                      String formattedDate = formatter.format(parsedDate);

                      return _AttemptCard(
                        title: widget.title,
                        attemptLabel:
                            'Attempt ${reportsCat?.isAttemptcount.toString() ?? ""} · $formattedDate',
                        totalMarks: reportsCat?.myMark.toString() ?? '',
                        rightQuestions:
                            reportsCat?.correctAnswers.toString() ?? '',
                        leftQuestions:
                            reportsCat?.leftqusestion.toString() ?? '',
                        wrongQuestions:
                            reportsCat?.incorrectAnswers.toString() ?? '',
                        maxQuestions: reportsCat?.question.toString() ?? '',
                        onAnalysisTap: () {
                          Navigator.of(context).pushNamed(
                            Routes.customTestReportDetailsScreen,
                            arguments: {
                              'report':
                                  store.customtestreportscategory[index],
                              'title': widget.title,
                              'userexamId': store
                                  .customtestreportscategory[index]
                                  ?.userExamId,
                              'examId': widget.id,
                            },
                          );
                        },
                        onSolutionsTap: () => _solutionReport(
                          store.customtestreportscategory[index]?.userExamId ??
                              '',
                          'View all',
                        ),
                      );
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
}

// ============================================================================
// Private UI primitives
// ============================================================================

class _GradientHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  const _GradientHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppTokens.s12,
        left: AppTokens.s16,
        right: AppTokens.s16,
        bottom: AppTokens.s24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTokens.brand, AppTokens.brand2],
        ),
      ),
      child: Row(
        children: [
          Material(
            color: Colors.white.withOpacity(0.15),
            borderRadius: AppTokens.radius12,
            child: InkWell(
              borderRadius: AppTokens.radius12,
              onTap: onBack,
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTokens.titleLg(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTokens.caption(context).copyWith(
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          NutsActivityIndicator(
            activeColor: AppTokens.accent(context),
            animating: true,
            radius: 20,
          ),
          const SizedBox(height: AppTokens.s16),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppTokens.s32),
            child: Text(
              "Getting everything ready for you... Just a moment!",
              textAlign: TextAlign.center,
              style: AppTokens.body(context).copyWith(
                color: AppTokens.ink2(context),
              ),
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTokens.surface2(context),
                borderRadius: AppTokens.radius20,
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 34,
                color: AppTokens.ink2(context),
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              "Nothing here yet",
              style: AppTokens.titleMd(context).copyWith(
                color: AppTokens.ink(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTokens.s8),
            Text(
              "There's no content available right now. Please check back later or explore other sections for more resources.",
              textAlign: TextAlign.center,
              style: AppTokens.body(context).copyWith(
                color: AppTokens.ink2(context),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttemptCard extends StatelessWidget {
  final String title;
  final String attemptLabel;
  final String totalMarks;
  final String rightQuestions;
  final String leftQuestions;
  final String wrongQuestions;
  final String maxQuestions;
  final VoidCallback onAnalysisTap;
  final VoidCallback onSolutionsTap;

  const _AttemptCard({
    required this.title,
    required this.attemptLabel,
    required this.totalMarks,
    required this.rightQuestions,
    required this.leftQuestions,
    required this.wrongQuestions,
    required this.maxQuestions,
    required this.onAnalysisTap,
    required this.onSolutionsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius20,
        border: Border.all(color: AppTokens.border(context), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTokens.s16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTokens.accentSoft(context),
                    borderRadius: AppTokens.radius16,
                  ),
                  child: Icon(
                    Icons.emoji_events_outlined,
                    color: AppTokens.accent(context),
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTokens.titleSm(context).copyWith(
                          color: AppTokens.ink(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        attemptLabel,
                        style: AppTokens.caption(context).copyWith(
                          color: AppTokens.ink2(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTokens.s8),
                _MarksPill(marks: totalMarks),
              ],
            ),
          ),
          Divider(color: AppTokens.border(context), height: 0),
          Padding(
            padding: const EdgeInsets.all(AppTokens.s16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatPill(
                        label: 'Right',
                        value: rightQuestions,
                        icon: Icons.check_circle_outline_rounded,
                        tone: AppTokens.success(context),
                        soft: AppTokens.successSoft(context),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Expanded(
                      child: _StatPill(
                        label: 'Left',
                        value: leftQuestions,
                        icon: Icons.pending_actions_rounded,
                        tone: AppTokens.warning(context),
                        soft: AppTokens.warningSoft(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s8),
                Row(
                  children: [
                    Expanded(
                      child: _StatPill(
                        label: 'Wrong',
                        value: wrongQuestions,
                        icon: Icons.cancel_outlined,
                        tone: AppTokens.danger(context),
                        soft: AppTokens.dangerSoft(context),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Expanded(
                      child: _StatPill(
                        label: 'Max',
                        value: maxQuestions,
                        icon: Icons.assignment_outlined,
                        tone: AppTokens.accent(context),
                        soft: AppTokens.accentSoft(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s16),
                Row(
                  children: [
                    Expanded(
                      child: _OutlinedActionButton(
                        label: 'Analysis',
                        icon: Icons.insights_rounded,
                        onTap: onAnalysisTap,
                      ),
                    ),
                    const SizedBox(width: AppTokens.s12),
                    Expanded(
                      child: _GradientActionButton(
                        label: 'Solutions',
                        icon: Icons.menu_book_rounded,
                        onTap: onSolutionsTap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MarksPill extends StatelessWidget {
  final String marks;
  const _MarksPill({required this.marks});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s8,
      ),
      decoration: BoxDecoration(
        color: AppTokens.accentSoft(context),
        borderRadius: AppTokens.radius12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            marks,
            style: AppTokens.titleMd(context).copyWith(
              color: AppTokens.accent(context),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Marks',
            style: AppTokens.overline(context).copyWith(
              color: AppTokens.accent(context),
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color tone;
  final Color soft;
  const _StatPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
    required this.soft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s8,
      ),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: AppTokens.radius12,
      ),
      child: Row(
        children: [
          Icon(icon, color: tone, size: 18),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTokens.overline(context).copyWith(
                    color: tone,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTokens.titleMd(context).copyWith(
                    color: tone,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlinedActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _OutlinedActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTokens.surface2(context),
      borderRadius: AppTokens.radius12,
      child: InkWell(
        borderRadius: AppTokens.radius12,
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: AppTokens.radius12,
            border: Border.all(color: AppTokens.border(context), width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AppTokens.ink(context)),
              const SizedBox(width: AppTokens.s8),
              Text(
                label,
                style: AppTokens.titleSm(context).copyWith(
                  color: AppTokens.ink(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GradientActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppTokens.radius12,
      child: InkWell(
        borderRadius: AppTokens.radius12,
        onTap: onTap,
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTokens.brand, AppTokens.brand2],
            ),
            borderRadius: AppTokens.radius12,
            boxShadow: [
              BoxShadow(
                color: AppTokens.brand.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: AppTokens.s8),
              Text(
                label,
                style: AppTokens.titleSm(context).copyWith(
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
