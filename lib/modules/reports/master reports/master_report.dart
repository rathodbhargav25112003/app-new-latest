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

/// Mock-exam report sub-category (attempts for one mock exam).
///
/// Preserved public contract:
///   • `MasterReport({super.key, required id, required type,
///     required categoryId, required title, showPredictive = false,
///     isTrend = false})`
///   • Static `route(RouteSettings)` reads
///     `{id, title, type, category_id, isTrend, showPredictive}`
///     (`showPredictive` falls back to `false`).
///   • `store.onMasterReportByCategoryApiCall(widget.id)` in initState.
///   • `_solutionReport(examId, filter)` chains
///     `store.onMasterSolutionReportApiCall(examId)` → pushes
///     `Routes.solutionMasterReport` with
///     `{'solutionReport': store.masterSolutionReportCategory,
///     'filterVal': filter, 'userExamId': examId}`.
///   • "Analysis" → `Routes.masterTestReportDetailsScreen` with
///     `{report, showPredictive, category_id, title, isTrend,
///     userexamId, examId}`.
///   • Empty-state + loading copy verbatim.
///   • `!store.isConnected` → `NoInternetScreen`.
class MasterReport extends StatefulWidget {
  final String id;
  final String title;
  final String? type;
  final String? categoryId;
  final bool showPredictive;
  final bool isTrend;
  const MasterReport({
    super.key,
    required this.id,
    required this.type,
    required this.categoryId,
    required this.title,
    this.showPredictive = false,
    this.isTrend = false,
  });

  @override
  State<MasterReport> createState() => _MasterReportState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => MasterReport(
        id: arguments['id'],
        title: arguments['title'],
        type: arguments['type'],
        categoryId: arguments['category_id'],
        isTrend: arguments['isTrend'],
        showPredictive: arguments['showPredictive'] ?? false,
      ),
    );
  }
}

class _MasterReportState extends State<MasterReport> {
  String query = '';

  @override
  void initState() {
    super.initState();
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    store.onMasterReportByCategoryApiCall(widget.id);
  }

  Future<void> _solutionReport(String examId, String filter) async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onMasterSolutionReportApiCall(examId).then((_) {
      Navigator.of(context).pushNamed(Routes.solutionMasterReport, arguments: {
        'solutionReport': store.masterSolutionReportCategory,
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
                if (store.masterreportscategory.isEmpty) {
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
                  itemCount: store.masterreportscategory.length,
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
                        store.masterreportscategory[index];
                    String originalDate = reportsCat?.date ?? "";
                    DateTime parsedDate = DateTime.parse(originalDate);
                    final formatter = DateFormat('dd MMM, yyyy');
                    String formattedDate = formatter.format(parsedDate);

                    return _MasterReportCard(
                      title: widget.title,
                      attemptLine:
                          "Attempt ${reportsCat?.isAttemptcount.toString() ?? ""} | $formattedDate",
                      onAnalysis: () {
                        Navigator.of(context).pushNamed(
                          Routes.masterTestReportDetailsScreen,
                          arguments: {
                            'report': store.masterreportscategory[index],
                            'showPredictive': widget.showPredictive,
                            'category_id': widget.categoryId,
                            'title': widget.title,
                            'isTrend': widget.isTrend,
                            'userexamId':
                                store.masterreportscategory[index]?.userExamId,
                            'examId': widget.id,
                          },
                        );
                      },
                      onSolutions: () {
                        _solutionReport(
                          store.masterreportscategory[index]?.userExamId ?? "",
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

class _MasterReportCard extends StatelessWidget {
  final String title;
  final String attemptLine;
  final VoidCallback onAnalysis;
  final VoidCallback onSolutions;

  const _MasterReportCard({
    required this.title,
    required this.attemptLine,
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
      padding: const EdgeInsets.all(AppTokens.s16),
      child: Column(
        children: [
          Row(
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
                      borderRadius: BorderRadius.circular(AppTokens.r12),
                      border: Border.all(color: AppTokens.border(context)),
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
                      borderRadius: BorderRadius.circular(AppTokens.r12),
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
    );
  }
}
