import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../helpers/app_tokens.dart';
import '../dashboard/store/home_store.dart';
import '../widgets/no_internet_connection.dart';

/// Progress — Apple-minimalistic stats overview.
///
/// The previous design stacked 4 elevated white cards with green linear
/// progress bars. This rewrite keeps the same data points but presents them
/// as soft-surface cards with a leading icon tile, large numeric value, and
/// a thin "rail" progress indicator using [AppTokens.accent]. Cards group
/// related metrics side-by-side instead of two separate columns.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(builder: (_) => const ProgressScreen());
  }
}

class _ProgressScreenState extends State<ProgressScreen> {
  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    final store = Provider.of<HomeStore>(context, listen: false);
    await store.onGetProgressDetailsCall(context);
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<HomeStore>(context, listen: false);

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppTokens.scaffold(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTokens.ink(context), size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text("Progress", style: AppTokens.titleLg(context)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: !store.isConnected
            ? const NoInternetScreen()
            : Observer(builder: (_) {
                if (store.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppTokens.accent(context),
                    ),
                  );
                }

                final pd = store.progressDetails.value;
                final noteCount = pd?.completedPdfCount.toString() ?? "";
                final totalNoteCount = pd?.pdfCount.toString() ?? "";
                final totalMcqExamCount = pd?.McqExamCount.toString() ?? "";
                final attemptMcqExamCount =
                    pd?.McqAttemptExamCount.toString() ?? "";
                final totalMcqQuestionCount =
                    pd?.mcqQuestion.toString() ?? "";
                final attemptMcqQuestionCount =
                    pd?.mcqAttemtQuestion.toString() ?? "";
                final neetSsExamCount = pd?.neetSsExamCount.toString() ?? "";
                final neetSsUserExamCount =
                    pd?.neetSUserExamCount.toString() ?? "";
                final iniSsExamCount =
                    pd?.inissETExamCount.toString() ?? "";
                final iniSsUserExamCount =
                    pd?.innissETUserExamCount.toString() ?? "";
                final videoCount = pd?.videoCount.toString() ?? "";
                final completedVideoCount =
                    pd?.completedVideoCount.toString() ?? "";
                final totalVideoDuration =
                    pd?.totalVideoDuration.toString() ?? "";
                final completedVideoDuration =
                    pd?.completedVideoDuration.toString() ?? "";

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth > 600;
                      return Center(
                        child: Container(
                          width: isDesktop ? 600 : double.infinity,
                          padding: const EdgeInsets.fromLTRB(
                              AppTokens.s24,
                              AppTokens.s8,
                              AppTokens.s24,
                              AppTokens.s24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Hero illustration.
                              Center(
                                child: SvgPicture.asset(
                                  "assets/image/progress_icon.svg",
                                  height: 140,
                                ),
                              ),
                              const SizedBox(height: AppTokens.s8),
                              Text(
                                'Your learning journey',
                                style: AppTokens.titleLg(context),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Track how far you have come across notes, '
                                'quizzes, videos, and mock exams.',
                                style: AppTokens.body(context),
                              ),
                              const SizedBox(height: AppTokens.s20),

                              _MetricCard(
                                iconAsset:
                                    "assets/image/notesprogressicon.svg",
                                title: 'Notes',
                                accent: const Color(0xFF33AD48),
                                metrics: [
                                  _Metric(
                                    current: noteCount,
                                    total: totalNoteCount,
                                    label: 'Notes completed',
                                  ),
                                ],
                              ),

                              _MetricCard(
                                iconAsset:
                                    "assets/image/mcqprogressicon.svg",
                                title: 'MCQ Bank',
                                accent: const Color(0xFFE89B20),
                                metrics: [
                                  _Metric(
                                    current: attemptMcqQuestionCount,
                                    total: totalMcqQuestionCount,
                                    label: 'Questions solved',
                                  ),
                                  _Metric(
                                    current: attemptMcqExamCount,
                                    total: totalMcqExamCount,
                                    label: 'Tests completed',
                                  ),
                                ],
                              ),

                              _MetricCard(
                                iconAsset:
                                    "assets/image/videosprogressicon.svg",
                                title: 'Videos',
                                accent: const Color(0xFF1E88E5),
                                metrics: [
                                  _Metric(
                                    current: completedVideoCount,
                                    total: videoCount,
                                    label: 'Videos completed',
                                  ),
                                  _Metric(
                                    current: completedVideoDuration,
                                    total: totalVideoDuration,
                                    label: 'Watched time',
                                  ),
                                ],
                              ),

                              _MetricCard(
                                iconAsset:
                                    "assets/image/mockexamprogressicon.svg",
                                title: 'Mock Exams',
                                accent: const Color(0xFFE23B3B),
                                metrics: [
                                  _Metric(
                                    current: neetSsUserExamCount,
                                    total: neetSsExamCount,
                                    label: 'NEET SS completed',
                                  ),
                                  _Metric(
                                    current: iniSsUserExamCount,
                                    total: iniSsExamCount,
                                    label: 'INI SS completed',
                                    showProgress: false,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
      ),
    );
  }
}

class _Metric {
  const _Metric({
    required this.current,
    required this.total,
    required this.label,
    this.showProgress = true,
  });

  final String current;
  final String total;
  final String label;
  final bool showProgress;

  /// Returns a 0..1 ratio if both [current] and [total] parse as integers
  /// and total > 0. Falls back to 0 in any other case.
  double get ratio {
    final c = int.tryParse(current) ?? 0;
    final t = int.tryParse(total) ?? 0;
    if (t == 0) return 0;
    return (c / t).clamp(0.0, 1.0);
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    Key? key,
    required this.iconAsset,
    required this.title,
    required this.metrics,
    required this.accent,
  }) : super(key: key);

  final String iconAsset;
  final String title;
  final List<_Metric> metrics;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.s12),
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius16,
        border: Border.all(color: AppTokens.border(context), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header.
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.14),
                  borderRadius: AppTokens.radius12,
                ),
                child: SvgPicture.asset(iconAsset, color: accent),
              ),
              const SizedBox(width: AppTokens.s12),
              Text(title, style: AppTokens.titleSm(context)),
            ],
          ),
          const SizedBox(height: AppTokens.s16),

          // Metric grid — 1 column if a single metric, 2 columns otherwise.
          if (metrics.length == 1)
            _MetricCell(metric: metrics.first, accent: accent)
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _MetricCell(metric: metrics[0], accent: accent),
                ),
                const SizedBox(width: AppTokens.s16),
                Expanded(
                  child: _MetricCell(metric: metrics[1], accent: accent),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({Key? key, required this.metric, required this.accent})
      : super(key: key);

  final _Metric metric;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final hasData =
        metric.current.isNotEmpty && metric.total.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Big number with /total in muted style.
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: metric.current.isEmpty ? '0' : metric.current,
                style: AppTokens.numeric(context, size: 22).copyWith(
                  color: AppTokens.ink(context),
                ),
              ),
              TextSpan(
                text: ' / ${metric.total.isEmpty ? '0' : metric.total}',
                style: AppTokens.caption(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(metric.label, style: AppTokens.caption(context)),
        if (metric.showProgress && hasData) ...[
          const SizedBox(height: AppTokens.s8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: metric.ratio,
              backgroundColor: AppTokens.surface3(context),
              color: accent,
              minHeight: 5,
            ),
          ),
        ],
      ],
    );
  }
}
