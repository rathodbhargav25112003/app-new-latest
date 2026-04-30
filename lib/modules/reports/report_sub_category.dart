// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters, use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/models/report_by_category_model.dart';
import 'package:shusruta_lms/modules/reports/store/report_by_category_store.dart';
import 'package:shusruta_lms/modules/widgets/no_internet_connection.dart';

/// Regular-exam report sub-category list (attempts for one exam).
///
/// Preserved public contract:
///   • `ReportSubCategory({super.key, required id, required type,
///     required title})`
///   • Static `route(RouteSettings)` reads `id`, `title`, `type`.
///   • `store.onReportByCategoryApiCall(widget.id)` in initState.
///   • `_solutionReport(examId, filter)` chains
///     `store.onSolutionReportApiCall(examId, "")` → pushes
///     `Routes.solutionReport` with
///     `{'solutionReport': store.solutionReportCategory,
///     'filterVal': filter, 'userExamId': examId}`.
///   • "Analysis" → `Routes.testReportDetailsScreen` with
///     `{report, title, userexamId, examId}`.
///   • Empty-state + loading copy preserved verbatim.
///   • `!store.isConnected` → `NoInternetScreen`.
class ReportSubCategory extends StatefulWidget {
  final String id;
  final String title;
  final String? type;

  const ReportSubCategory(
      {super.key, required this.id, required this.type, required this.title});

  @override
  State<ReportSubCategory> createState() => _ReportSubCategoryState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => ReportSubCategory(
        id: arguments['id'],
        title: arguments['title'],
        type: arguments['type'],
      ),
    );
  }
}

class _ReportSubCategoryState extends State<ReportSubCategory> {
  String query = '';

  @override
  void initState() {
    super.initState();
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    store.onReportByCategoryApiCall(widget.id);
    debugPrint("report category");
  }

  Future<void> _solutionReport(String examId, String filter) async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onSolutionReportApiCall(examId, "").then((_) {
      Navigator.of(context).pushNamed(Routes.solutionReport, arguments: {
        'solutionReport': store.solutionReportCategory,
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
          _buildHeader(context),
          Expanded(
            child: Observer(
              builder: (_) {
                if (store.isLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: AppTokens.accent(context),
                        ),
                        const SizedBox(height: AppTokens.s16),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.s24,
                          ),
                          child: Text(
                            "Getting everything ready for you... Just a moment!",
                            style: AppTokens.body(context).copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppTokens.ink(context),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (store.reportscategory.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.s24,
                    ),
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

                return ListView.separated(
                  itemCount: store.reportscategory.length,
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.s20,
                    AppTokens.s20,
                    AppTokens.s20,
                    AppTokens.s20,
                  ),
                  physics: const BouncingScrollPhysics(),
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppTokens.s12),
                  itemBuilder: (BuildContext context, int index) {
                    ReportByCategoryModel? reportsCat =
                        store.reportscategory[index];
                    String originalDate = reportsCat?.date ?? "";
                    DateTime parsedDate = DateTime.parse(originalDate);
                    final formatter = DateFormat('dd MMM, yyyy');
                    String formattedDate = formatter.format(parsedDate);

                    return _ReportCard(
                      title: widget.title,
                      attemptLine:
                          "Attempt ${reportsCat?.isAttemptcount.toString() ?? ""} | $formattedDate",
                      totalMarks: reportsCat?.myMark.toString() ?? "",
                      correctAnswers:
                          reportsCat?.correctAnswers.toString() ?? "",
                      leftQuestions:
                          reportsCat?.leftqusestion.toString() ?? "",
                      incorrectAnswers:
                          reportsCat?.incorrectAnswers.toString() ?? "",
                      maxQuestions: reportsCat?.question.toString() ?? "",
                      onAnalysis: () {
                        Navigator.of(context).pushNamed(
                          Routes.testReportDetailsScreen,
                          arguments: {
                            'report': store.reportscategory[index],
                            'title': widget.title,
                            'userexamId':
                                store.reportscategory[index]?.userExamId,
                            'examId': widget.id,
                          },
                        );
                      },
                      onSolutions: () {
                        _solutionReport(
                          store.reportscategory[index]?.userExamId ?? "",
                          "View all",
                        );
                      },
                    );
                  },
                );
              },
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
              widget.title,
              style: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String attemptLine;
  final String totalMarks;
  final String correctAnswers;
  final String leftQuestions;
  final String incorrectAnswers;
  final String maxQuestions;
  final VoidCallback onAnalysis;
  final VoidCallback onSolutions;

  const _ReportCard({
    required this.title,
    required this.attemptLine,
    required this.totalMarks,
    required this.correctAnswers,
    required this.leftQuestions,
    required this.incorrectAnswers,
    required this.maxQuestions,
    required this.onAnalysis,
    required this.onSolutions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: BorderRadius.circular(AppTokens.r16),
        border: Border.all(color: AppTokens.border(context)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTokens.s16),
            child: Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTokens.accentSoft(context),
                    borderRadius: BorderRadius.circular(AppTokens.r12),
                  ),
                  child: SvgPicture.asset(
                    "assets/image/award.svg",
                    color: AppTokens.accent(context),
                  ),
                ),
                const SizedBox(width: AppTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTokens.body(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTokens.ink(context),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        attemptLine,
                        style: AppTokens.caption(context).copyWith(
                          color: AppTokens.muted(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.s16,
              0,
              AppTokens.s16,
              AppTokens.s12,
            ),
            child: Container(
              padding: const EdgeInsets.all(AppTokens.s12),
              decoration: BoxDecoration(
                color: AppTokens.accentSoft(context).withOpacity(0.4),
                borderRadius: BorderRadius.circular(AppTokens.r12),
              ),
              child: Row(
                children: [
                  Container(
                    height: 36,
                    width: 36,
                    alignment: Alignment.center,
                    child: Image.asset("assets/image/analysisTotalMark.png"),
                  ),
                  const SizedBox(width: AppTokens.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total Marks",
                          style: AppTokens.caption(context).copyWith(
                            color: AppTokens.muted(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          totalMarks,
                          style: AppTokens.titleSm(context).copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTokens.ink(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.s16,
              0,
              AppTokens.s16,
              AppTokens.s16,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCell(
                        label: "Right Questions",
                        value: correctAnswers,
                        gradient: const [
                          Color(0x001EC96C),
                          Color(0xFF1EC96C),
                        ],
                        iconAsset: "assets/image/analysisUpArrow.svg",
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Expanded(
                      child: _StatCell(
                        label: "Left Questions",
                        value: leftQuestions,
                        gradient: const [
                          Color(0x42F6B33A),
                          Color(0xFFF6B33A),
                        ],
                        iconAsset: "assets/image/analysisClock.svg",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s8),
                Row(
                  children: [
                    Expanded(
                      child: _StatCell(
                        label: "Wrong Questions",
                        value: incorrectAnswers,
                        gradient: const [
                          Color(0x00EB5757),
                          Color(0xFFEB5757),
                        ],
                        iconAsset: "assets/image/analysisUpArrow.svg",
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Expanded(
                      child: _StatCell(
                        label: "Max Questions",
                        value: maxQuestions,
                        gradient: const [
                          Color(0x006C63FF),
                          Color(0xFF6C63FF),
                        ],
                        iconAsset: "assets/image/analysisClock.svg",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: onAnalysis,
                        borderRadius: BorderRadius.circular(AppTokens.r12),
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppTokens.surface(context),
                            borderRadius:
                                BorderRadius.circular(AppTokens.r12),
                            border:
                                Border.all(color: AppTokens.border(context)),
                          ),
                          child: Text(
                            "Analysis",
                            style: AppTokens.body(context).copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTokens.ink(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Expanded(
                      child: InkWell(
                        onTap: onSolutions,
                        borderRadius: BorderRadius.circular(AppTokens.r12),
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTokens.brand, AppTokens.brand2],
                            ),
                            borderRadius:
                                BorderRadius.circular(AppTokens.r12),
                          ),
                          child: Text(
                            "Solutions",
                            style: AppTokens.body(context).copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
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

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final List<Color> gradient;
  final String iconAsset;

  const _StatCell({
    required this.label,
    required this.value,
    required this.gradient,
    required this.iconAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        border: Border.all(color: AppTokens.border(context)),
        borderRadius: BorderRadius.circular(AppTokens.r12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTokens.caption(context).copyWith(
                    color: AppTokens.muted(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTokens.titleSm(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTokens.ink(context),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 32,
            width: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.r8),
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SvgPicture.asset(iconAsset),
          ),
        ],
      ),
    );
  }
}
