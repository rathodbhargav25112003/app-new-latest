import 'dart:io';

import 'package:flutter/material.dart';
// ignore: unused_import, unnecessary_import
import 'package:flutter/cupertino.dart';
// ignore: unused_import, unnecessary_import
import 'package:flutter/widgets.dart';
// ignore: unused_import, unnecessary_import
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
// ignore: unused_import
import '../../helpers/colors.dart';
// ignore: unused_import
import '../../helpers/dimensions.dart';
// ignore: unused_import
import '../../helpers/styles.dart';
// ignore: unused_import
import '../../models/searched_data_model.dart';
// ignore: unused_import
import '../../models/test_subcategory_model.dart';
// ignore: unused_import
import 'package:progress_border/progress_border.dart';
import 'model/custom_test_exam_by_topic_model.dart';
import 'package:shusruta_lms/helpers/custom_dynamic_height_gridview.dart';
// ignore: unused_import
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';
import 'package:shusruta_lms/modules/customtests/store/custom_test_store.dart';
import '../widgets/no_internet_connection.dart';

/// SelectTestCustomTest — fourth step of the custom-test creation wizard.
/// Surface contract preserved exactly:
///   • const constructor `{required selectedCategoryItems,
///     required selectedChapterItems, required selectedTopicItems}`
///   • static `route(RouteSettings)` reading all three argument maps
///   • dispatches `CustomTestCategoryStore.onCustomExamApiCall(
///     topicIdsString)` with CSV of `topic_id`s
///   • selectedExamItems map keys unchanged: exam_id, exam_name,
///     category_id, subcategory_id, topic_id, question_count
///   • rolling totalQuestions (int) and totalDuration (Duration)
///     recomputed on every toggle and isAll updated automatically
///   • Navigator.pushNamed(Routes.customConfiguration) with SIX args:
///     selectedCategoryItems, selectedChapterItems, selectedTopicItems,
///     selectedExamItems, totalQuestions, totalDurations (hh:mm:ss)
class SelectTestCustomTest extends StatefulWidget {
  final List<Map<String, dynamic>> selectedCategoryItems;
  final List<Map<String, dynamic>> selectedChapterItems;
  final List<Map<String, dynamic>> selectedTopicItems;
  const SelectTestCustomTest({
    super.key,
    required this.selectedCategoryItems,
    required this.selectedChapterItems,
    required this.selectedTopicItems,
  });

  @override
  State<SelectTestCustomTest> createState() => _SelectTestCustomTestState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => SelectTestCustomTest(
        selectedCategoryItems: arguments['selectedCategoryItems'],
        selectedChapterItems: arguments['selectedChapterItems'],
        selectedTopicItems: arguments['selectedTopicItems'],
      ),
    );
  }
}

class _SelectTestCustomTestState extends State<SelectTestCustomTest> {
  // Legacy in-memory search field preserved for API parity.
  // ignore: unused_field
  String query = '';
  List<Map<String, dynamic>> selectedExamItems = [];
  int totalQuestions = 0;
  Duration totalDuration = const Duration();
  bool isAll = false;

  bool get _isDesktop => Platform.isWindows || Platform.isMacOS;

  @override
  void initState() {
    super.initState();
    getExamData();
  }

  Future<void> getExamData() async {
    final List<Map<String, dynamic>> selectedItems =
        widget.selectedTopicItems;
    final List<String> topicIds =
        selectedItems.map((item) => item['topic_id'].toString()).toList();
    final String topicIdsString = topicIds.join(',');
    if (!mounted) return;
    final store =
        Provider.of<CustomTestCategoryStore>(context, listen: false);
    await store.onCustomExamApiCall(topicIdsString);
  }

  Duration parseDuration(String durationStr) {
    final List<String> parts = durationStr.split(':');
    final int hours = int.parse(parts[0]);
    final int minutes = int.parse(parts[1]);
    final int seconds = int.parse(parts[2]);
    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final String twoDigitHours = twoDigits(duration.inHours);
    final String twoDigitMinutes =
        twoDigits(duration.inMinutes.remainder(60));
    final String twoDigitSeconds =
        twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds';
  }

  /// Compact "1h 30m" / "45m 20s" label for the footer summary. Uses the
  /// same Duration object, so it never drifts from the hh:mm:ss payload
  /// shipped forward to the configuration screen.
  String _durationLabel(Duration d) {
    if (d.inSeconds == 0) return '0m';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    final parts = <String>[];
    if (h > 0) parts.add('${h}h');
    if (m > 0) parts.add('${m}m');
    if (h == 0 && s > 0) parts.add('${s}s');
    return parts.isEmpty ? '0m' : parts.join(' ');
  }

  void _toggleSelectAll(CustomTestCategoryStore store) {
    setState(() {
      if (!isAll) {
        selectedExamItems.clear();
        totalQuestions = 0;
        totalDuration = const Duration();
        for (final e in store.customTestExamByTopicsList) {
          selectedExamItems.add({
            'exam_id': e?.sId,
            'exam_name': e?.examName,
            'category_id': e?.categoryId,
            'subcategory_id': e?.subCategoryId,
            'topic_id': e?.topicId,
            'question_count': e?.questionCount,
          });
          totalQuestions += e?.questionCount ?? 0;
          totalDuration += parseDuration(e?.timeDuration ?? '00:00:00');
        }
      } else {
        selectedExamItems.clear();
        totalQuestions = 0;
        totalDuration = const Duration();
      }
      isAll = !isAll;
    });
  }

  void _toggleOne(CustomTestExamByTopicModel? exam, int totalLength) {
    setState(() {
      final idx = selectedExamItems
          .indexWhere((item) => item['exam_id'] == exam?.sId);
      if (idx >= 0) {
        selectedExamItems.removeAt(idx);
        totalQuestions -= exam?.questionCount ?? 0;
        totalDuration -=
            parseDuration(exam?.timeDuration ?? '00:00:00');
        if (selectedExamItems.length < totalLength) {
          isAll = false;
        }
      } else {
        selectedExamItems.add({
          'exam_id': exam?.sId,
          'exam_name': exam?.examName,
          'category_id': exam?.categoryId,
          'subcategory_id': exam?.subCategoryId,
          'topic_id': exam?.topicId,
          'question_count': exam?.questionCount,
        });
        totalQuestions += exam?.questionCount ?? 0;
        totalDuration +=
            parseDuration(exam?.timeDuration ?? '00:00:00');
        if (selectedExamItems.length == totalLength) {
          isAll = true;
        }
      }
    });
  }

  void _goToConfig() {
    Navigator.of(context).pushNamed(
      Routes.customConfiguration,
      arguments: {
        'selectedCategoryItems': widget.selectedCategoryItems,
        'selectedChapterItems': widget.selectedChapterItems,
        'selectedTopicItems': widget.selectedTopicItems,
        'selectedExamItems': selectedExamItems,
        'totalQuestions': totalQuestions,
        'totalDurations': formatDuration(totalDuration),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store =
        Provider.of<CustomTestCategoryStore>(context, listen: false);
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          Observer(
            builder: (_) => _GradientHeader(
              title: 'Tests',
              subtitle: 'Choose the mock tests to mix into your session',
              count: store.customTestExamByTopicsList.length,
              isAll: isAll,
              onBack: () => Navigator.pop(context),
              onToggleAll: () => _toggleSelectAll(store),
              isDesktop: _isDesktop,
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTokens.scaffold(context),
                borderRadius: _isDesktop
                    ? null
                    : const BorderRadius.only(
                        topLeft: Radius.circular(AppTokens.r28),
                        topRight: Radius.circular(AppTokens.r28),
                      ),
              ),
              child: Observer(
                builder: (_) {
                  if (store.isLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppTokens.accent(context),
                      ),
                    );
                  }
                  if (!store.isConnected) {
                    return const NoInternetScreen();
                  }
                  if (store.customTestExamByTopicsList.isEmpty) {
                    return const _EmptyView();
                  }
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTokens.s20,
                      AppTokens.s20,
                      AppTokens.s20,
                      AppTokens.s8,
                    ),
                    child: _isDesktop
                        ? CustomDynamicHeightGridView(
                            crossAxisCount: 3,
                            mainAxisSpacing: AppTokens.s12,
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            itemCount:
                                store.customTestExamByTopicsList.length,
                            builder: (BuildContext context, int index) {
                              return buildItem(
                                context,
                                store.customTestExamByTopicsList[index],
                              );
                            },
                          )
                        : ListView.builder(
                            itemCount:
                                store.customTestExamByTopicsList.length,
                            padding: EdgeInsets.zero,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder:
                                (BuildContext context, int index) {
                              return buildItem(
                                context,
                                store.customTestExamByTopicsList[index],
                              );
                            },
                          ),
                  );
                },
              ),
            ),
          ),
          _NextCta(
            enabled: selectedExamItems.isNotEmpty,
            selectedCount: selectedExamItems.length,
            totalQuestions: totalQuestions,
            durationLabel: _durationLabel(totalDuration),
            onTap: _goToConfig,
          ),
        ],
      ),
    );
  }

  Widget buildItem(
      BuildContext context, CustomTestExamByTopicModel? testCatModel) {
    final store =
        Provider.of<CustomTestCategoryStore>(context, listen: false);
    final model = testCatModel;
    final bool isSelected =
        selectedExamItems.any((item) => item['exam_id'] == model?.sId);

    final Color tileBorder = isSelected
        ? AppTokens.accent(context)
        : AppTokens.border(context);
    final Color tileBg = isSelected
        ? AppTokens.accentSoft(context)
        : AppTokens.surface(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.r16),
          onTap: () => _toggleOne(
              model, store.customTestExamByTopicsList.length),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(AppTokens.s12),
            decoration: BoxDecoration(
              color: tileBg,
              border: Border.all(
                color: tileBorder,
                width: isSelected ? 1.6 : 1.0,
              ),
              borderRadius: BorderRadius.circular(AppTokens.r16),
            ),
            child: Row(
              children: [
                // Leading SVG chip
                Container(
                  height: 48,
                  width: 48,
                  padding: const EdgeInsets.all(AppTokens.s12),
                  decoration: BoxDecoration(
                    color: AppTokens.accentSoft(context),
                    borderRadius: BorderRadius.circular(AppTokens.r12),
                  ),
                  child: SvgPicture.asset(
                    'assets/image/customtest.svg',
                    colorFilter: ColorFilter.mode(
                      AppTokens.accent(context),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.s12),
                // Title + metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        model?.examName ?? '',
                        style: AppTokens.titleSm(context).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _MetaPill(
                            icon: Icons.quiz_rounded,
                            label:
                                '${model?.questionCount ?? 0} Questions',
                            color: AppTokens.accent(context),
                            bg: AppTokens.accentSoft(context),
                          ),
                          if ((model?.timeDuration ?? '').isNotEmpty) ...[
                            const SizedBox(width: AppTokens.s8),
                            _MetaPill(
                              icon: Icons.schedule_rounded,
                              label: _durationLabel(parseDuration(
                                  model?.timeDuration ?? '00:00:00')),
                              color: AppTokens.warning(context),
                              bg: AppTokens.warningSoft(context),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTokens.s8),
                // Trailing animated checkbox
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTokens.accent(context)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppTokens.r8),
                    border: Border.all(
                      color: isSelected
                          ? AppTokens.accent(context)
                          : AppTokens.border(context),
                      width: 1.4,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  const _MetaPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTokens.r8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTokens.caption(context).copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Brand-gradient header: back chip, title, subtitle, count pill,
/// and the Select-All / Deselect pill.
class _GradientHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final int count;
  final bool isAll;
  final VoidCallback onBack;
  final VoidCallback onToggleAll;
  final bool isDesktop;
  const _GradientHeader({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.isAll,
    required this.onBack,
    required this.onToggleAll,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final double topPad = isDesktop ? AppTokens.s20 : AppTokens.s32;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppTokens.s20,
        topPad,
        AppTokens.s20,
        AppTokens.s20,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTokens.brand, AppTokens.brand2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: isDesktop
            ? null
            : const BorderRadius.only(
                bottomLeft: Radius.circular(AppTokens.r28),
                bottomRight: Radius.circular(AppTokens.r28),
              ),
      ),
      child: SafeArea(
        top: !isDesktop,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Material(
                  // ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.18),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onBack,
                    child: const Padding(
                      padding: EdgeInsets.all(AppTokens.s8),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.s12),
                Expanded(
                  child: Text(
                    title,
                    style: AppTokens.titleMd(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.s12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subtitle,
                        style: AppTokens.body(context).copyWith(
                          // ignore: deprecated_member_use
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                      const SizedBox(height: AppTokens.s8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.s12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius:
                              BorderRadius.circular(AppTokens.r12),
                        ),
                        child: Text(
                          '$count available',
                          style: AppTokens.caption(context).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTokens.s12),
                _SelectAllPill(isAll: isAll, onTap: onToggleAll),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectAllPill extends StatelessWidget {
  final bool isAll;
  final VoidCallback onTap;
  const _SelectAllPill({required this.isAll, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s16,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: isAll ? AppTokens.danger(context) : Colors.white,
          borderRadius: BorderRadius.circular(AppTokens.r20),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAll ? Icons.close_rounded : Icons.check_circle_rounded,
              size: 16,
              color: isAll ? Colors.white : AppTokens.accent(context),
            ),
            const SizedBox(width: 6),
            Text(
              isAll ? 'Deselect' : 'Select All',
              style: AppTokens.caption(context).copyWith(
                fontWeight: FontWeight.w700,
                color: isAll ? Colors.white : AppTokens.accent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTokens.surface2(context),
                borderRadius: BorderRadius.circular(AppTokens.r20),
              ),
              child: Icon(
                Icons.fact_check_outlined,
                color: AppTokens.ink2(context),
                size: 32,
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              'No tests available',
              style: AppTokens.titleSm(context)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppTokens.s8),
            Text(
              "We're sorry, there's no content available right now. Please check back later or explore other sections for more educational resources.",
              textAlign: TextAlign.center,
              style: AppTokens.body(context).copyWith(
                color: AppTokens.ink2(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sticky Next CTA. Displays an inline summary of selected tests,
/// accumulated question count, and total duration — mirrors the state
/// being shipped to the configuration step.
class _NextCta extends StatelessWidget {
  final bool enabled;
  final int selectedCount;
  final int totalQuestions;
  final String durationLabel;
  final VoidCallback onTap;
  const _NextCta({
    required this.enabled,
    required this.selectedCount,
    required this.totalQuestions,
    required this.durationLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.s20,
          AppTokens.s8,
          AppTokens.s20,
          AppTokens.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedCount > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s12,
                  vertical: AppTokens.s8,
                ),
                decoration: BoxDecoration(
                  color: AppTokens.surface(context),
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                  border: Border.all(
                    color: AppTokens.border(context),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _FooterStat(
                      label: 'Tests',
                      value: '$selectedCount',
                      color: AppTokens.accent(context),
                    ),
                    _FooterDivider(),
                    _FooterStat(
                      label: 'Questions',
                      value: '$totalQuestions',
                      color: AppTokens.success(context),
                    ),
                    _FooterDivider(),
                    _FooterStat(
                      label: 'Duration',
                      value: durationLabel,
                      color: AppTokens.warning(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.s8),
            ],
            AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: enabled ? 1.0 : 0.55,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTokens.r16),
                  onTap: enabled ? onTap : null,
                  child: Container(
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTokens.brand, AppTokens.brand2],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(AppTokens.r16),
                      boxShadow: [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: AppTokens.brand.withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Next',
                          style: AppTokens.titleSm(context).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: AppTokens.s8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _FooterStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTokens.titleSm(context).copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTokens.caption(context).copyWith(
            color: AppTokens.ink2(context),
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _FooterDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: AppTokens.border(context),
    );
  }
}
