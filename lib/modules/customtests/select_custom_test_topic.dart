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
import 'package:expandable_text/expandable_text.dart';
// ignore: unused_import
import 'package:progress_border/progress_border.dart';
// ignore: unused_import
import 'model/custom_test_sub_by_category_model.dart';
import 'model/custom_test_topic_by_subcategory_model.dart';
import 'package:shusruta_lms/helpers/custom_dynamic_height_gridview.dart';
// ignore: unused_import
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';
import 'package:shusruta_lms/modules/customtests/store/custom_test_store.dart';
import '../widgets/no_internet_connection.dart';

/// SelectCustomTestsTopic — third step of the custom-test creation wizard.
/// Surface contract preserved exactly:
///   • const constructor `{required selectedCategoryItems,
///     required selectedChapterItems}` (List of Map of String,dynamic)
///   • static `route(RouteSettings)` reading both argument maps off
///     `routeSettings.arguments`
///   • dispatches `CustomTestCategoryStore.onCustomTopicApiCall(
///     subCategoryIdsString)` with CSV of `subcategory_id`s from chapters
///   • `selectedTopicItems` map keys unchanged: topic_id, topic_name,
///     subcategory_id, category_id, question_count
///   • Navigator.pushNamed(Routes.customTestSelectTest) with all three
///     argument maps (selectedCategoryItems, selectedChapterItems,
///     selectedTopicItems)
class SelectCustomTestsTopic extends StatefulWidget {
  final List<Map<String, dynamic>> selectedCategoryItems;
  final List<Map<String, dynamic>> selectedChapterItems;
  const SelectCustomTestsTopic({
    super.key,
    required this.selectedCategoryItems,
    required this.selectedChapterItems,
  });

  @override
  State<SelectCustomTestsTopic> createState() => _SelectCustomTestsTopicState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => SelectCustomTestsTopic(
        selectedCategoryItems: arguments['selectedCategoryItems'],
        selectedChapterItems: arguments['selectedChapterItems'],
      ),
    );
  }
}

class _SelectCustomTestsTopicState extends State<SelectCustomTestsTopic> {
  // Legacy field preserved (was used for in-memory filtering).
  // ignore: unused_field
  String query = '';
  List<Map<String, dynamic>> selectedTopicItems = [];
  bool isAll = false;

  bool get _isDesktop => Platform.isWindows || Platform.isMacOS;

  @override
  void initState() {
    super.initState();
    getTopicData();
  }

  Future<void> getTopicData() async {
    final List<Map<String, dynamic>> selectedItems =
        widget.selectedChapterItems;
    final List<String> subCategoryIds = selectedItems
        .map((item) => item['subcategory_id'].toString())
        .toList();
    final String subCategoryIdsString = subCategoryIds.join(',');
    if (!mounted) return;
    final store =
        Provider.of<CustomTestCategoryStore>(context, listen: false);
    await store.onCustomTopicApiCall(subCategoryIdsString);
  }

  void _toggleSelectAll(CustomTestCategoryStore store) {
    setState(() {
      if (!isAll) {
        selectedTopicItems
          ..clear()
          ..addAll(store.customTestTopicBySubCateList
              .map((e) => {
                    'topic_id': e?.sId,
                    'topic_name': e?.topicName,
                    'subcategory_id': e?.subCategoryId,
                    'category_id': e?.categoryId,
                    'question_count': e?.questionCount,
                  })
              .toList());
      } else {
        selectedTopicItems.clear();
      }
      isAll = !isAll;
    });
  }

  void _toggleOne(CustomTestTopicBySubCategoryModel? model) {
    setState(() {
      final idx = selectedTopicItems
          .indexWhere((item) => item['topic_id'] == model?.sId);
      if (idx >= 0) {
        selectedTopicItems.removeAt(idx);
      } else {
        selectedTopicItems.add({
          'topic_id': model?.sId,
          'topic_name': model?.topicName,
          'subcategory_id': model?.subCategoryId,
          'category_id': model?.categoryId,
          'question_count': model?.questionCount,
        });
      }
      // Keep Select-All toggle in sync if user hand-matches all.
      isAll = false;
    });
  }

  void _goToNext() {
    Navigator.of(context).pushNamed(
      Routes.customTestSelectTest,
      arguments: {
        'selectedCategoryItems': widget.selectedCategoryItems,
        'selectedChapterItems': widget.selectedChapterItems,
        'selectedTopicItems': selectedTopicItems,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<CustomTestCategoryStore>(context);
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          Observer(
            builder: (_) => _GradientHeader(
              title: 'Topics',
              subtitle: 'Pick the areas you want to practice',
              count: store.customTestTopicBySubCateList.length,
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
                  if (store.customTestTopicBySubCateList.isEmpty) {
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
                                store.customTestTopicBySubCateList.length,
                            builder: (BuildContext context, int index) {
                              return buildItem(
                                context,
                                store.customTestTopicBySubCateList[index],
                              );
                            },
                          )
                        : ListView.builder(
                            itemCount:
                                store.customTestTopicBySubCateList.length,
                            padding: EdgeInsets.zero,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (BuildContext context, int index) {
                              return buildItem(
                                context,
                                store.customTestTopicBySubCateList[index],
                              );
                            },
                          ),
                  );
                },
              ),
            ),
          ),
          _NextCta(
            enabled: selectedTopicItems.isNotEmpty,
            selectedCount: selectedTopicItems.length,
            onTap: _goToNext,
          ),
        ],
      ),
    );
  }

  Widget buildItem(
      BuildContext context, CustomTestTopicBySubCategoryModel? testCatModel) {
    final model = testCatModel;
    final bool isSelected =
        selectedTopicItems.any((item) => item['topic_id'] == model?.sId);
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
          onTap: () => _toggleOne(model),
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
                    'assets/image/examsubject2.svg',
                    colorFilter: ColorFilter.mode(
                      AppTokens.accent(context),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.s12),
                // Title + question count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        model?.topicName ?? '',
                        style: AppTokens.titleSm(context).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.s8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTokens.accentSoft(context),
                          borderRadius:
                              BorderRadius.circular(AppTokens.r8),
                        ),
                        child: Text(
                          '${model?.questionCount ?? 0} Questions',
                          style: AppTokens.caption(context).copyWith(
                            color: AppTokens.accent(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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

/// Brand-gradient header with back chip, title, subtitle, count pill,
/// and Select-All toggle.
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
                          borderRadius: BorderRadius.circular(AppTokens.r12),
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

/// Shown when the API returns no topics for the current chapter selection.
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
                Icons.inbox_rounded,
                color: AppTokens.ink2(context),
                size: 32,
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              'No topics available',
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

/// Sticky bottom Next button. Fades when nothing is selected; shows the
/// selected-count badge when the wizard step is ready to advance.
class _NextCta extends StatelessWidget {
  final bool enabled;
  final int selectedCount;
  final VoidCallback onTap;
  const _NextCta({
    required this.enabled,
    required this.selectedCount,
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
        child: AnimatedOpacity(
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
                    if (selectedCount > 0) ...[
                      const SizedBox(width: AppTokens.s8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.s8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          // ignore: deprecated_member_use
                          color: Colors.white.withOpacity(0.22),
                          borderRadius:
                              BorderRadius.circular(AppTokens.r12),
                        ),
                        child: Text(
                          '$selectedCount selected',
                          style: AppTokens.caption(context).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
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
      ),
    );
  }
}
