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
import 'package:progress_border/progress_border.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
// ignore: unused_import
import '../../helpers/colors.dart';
// ignore: unused_import
import '../../helpers/dimensions.dart';
// ignore: unused_import
import '../../helpers/styles.dart';
import '../../models/searched_data_model.dart';
import '../../models/test_category_model.dart';
// ignore: unused_import
import '../../models/test_subcategory_model.dart';
// ignore: unused_import
import 'package:expandable_text/expandable_text.dart';
import '../subscriptionplans/store/subscription_store.dart';
import 'package:shusruta_lms/helpers/custom_dynamic_height_gridview.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';
import '../widgets/no_internet_connection.dart';

/// SelectCustomTestsCategory — first step of the custom-test creation
/// wizard. Surface contract preserved exactly:
///   • const constructor `{super.key}` with no positional args
///   • static `route(RouteSettings)` returning a CupertinoPageRoute
///   • boots with `TestCategoryStore.onCustomTestApiCall(context)` and
///     `SubscriptionStore.onGetSubscribedUserPlan()`
///   • focusNode + _onFocusChanged + searchCategory(keyword) kept
///     intact for API parity (not rendered by the rebuilt UI)
///   • selectedCategoryItems map keys unchanged: category_id,
///     category_name, question_count
///   • Navigator.pushNamed(Routes.customTestSelectChapter) ships a
///     single-arg map {selectedCategoryItems}
class SelectCustomTestsCategory extends StatefulWidget {
  const SelectCustomTestsCategory({
    super.key,
  });

  @override
  State<SelectCustomTestsCategory> createState() =>
      _SelectCustomTestsCategoryState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const SelectCustomTestsCategory(),
    );
  }
}

class _SelectCustomTestsCategoryState
    extends State<SelectCustomTestsCategory> {
  // Legacy filter state preserved for API parity.
  // ignore: unused_field
  String filterValue = '';
  final FocusNode _focusNode = FocusNode();
  // ignore: unused_field
  String query = '';
  bool isAll = false;
  List<Map<String, dynamic>> selectedCategoryItems = [];

  bool get _isDesktop => Platform.isWindows || Platform.isMacOS;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    _getSubscribedPlan();
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    store.onCustomTestApiCall(context);
  }

  Future<void> _getSubscribedPlan() async {
    final store = Provider.of<SubscriptionStore>(context, listen: false);
    await store.onGetSubscribedUserPlan();
    if (store.subscribedPlan.isEmpty) {
      // Navigator.of(context).pushNamed(Routes.subscriptionList);
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  // ignore: unused_element
  Future<void> searchCategory(String keyword) async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.onSearchApiCall(keyword, 'exam');
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _toggleSelectAll(TestCategoryStore store) {
    setState(() {
      if (!isAll) {
        selectedCategoryItems
          ..clear()
          ..addAll(store.customtestcategory
              .map((e) => {
                    'category_id': e?.sId,
                    'category_name': e?.category_name,
                    'question_count': e?.questionCount,
                  })
              .toList());
      } else {
        selectedCategoryItems.clear();
      }
      isAll = !isAll;
    });
  }

  void _toggleOne(TestCategoryModel? model, int totalLength) {
    setState(() {
      final idx = selectedCategoryItems
          .indexWhere((item) => item['category_id'] == model?.sId);
      if (idx >= 0) {
        selectedCategoryItems.removeAt(idx);
        if (selectedCategoryItems.length < totalLength) {
          isAll = false;
        }
      } else {
        selectedCategoryItems.add({
          'category_id': model?.sId,
          'category_name': model?.category_name,
          'question_count': model?.questionCount,
        });
        if (selectedCategoryItems.length == totalLength) {
          isAll = true;
        }
      }
    });
  }

  void _goToChapters() {
    Navigator.of(context).pushNamed(
      Routes.customTestSelectChapter,
      arguments: {
        'selectedCategoryItems': selectedCategoryItems,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store =
        Provider.of<TestCategoryStore>(context, listen: false);
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          Observer(
            builder: (_) => _GradientHeader(
              title: 'Modules',
              subtitle: 'Select the subjects you want to practice',
              count: store.customtestcategory.length,
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
                  if (store.customtestcategory.isEmpty) {
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
                                store.customtestcategory.length,
                            builder: (BuildContext context, int index) {
                              return buildItem1(
                                context,
                                store.customtestcategory[index],
                              );
                            },
                          )
                        : ListView.builder(
                            itemCount: store.customtestcategory.length,
                            padding: EdgeInsets.zero,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder:
                                (BuildContext context, int index) {
                              return buildItem1(
                                context,
                                store.customtestcategory[index],
                              );
                            },
                          ),
                  );
                },
              ),
            ),
          ),
          _NextCta(
            enabled: selectedCategoryItems.isNotEmpty,
            selectedCount: selectedCategoryItems.length,
            onTap: _goToChapters,
          ),
        ],
      ),
    );
  }

  /// Legacy category-search tile. Preserved for API parity — the rebuilt
  /// screen does not render it, but callers holding references stay safe.
  // ignore: unused_element
  Widget buildItem(
      BuildContext context, SearchedDataModel? searchDataModel) {
    final SearchedDataModel? examSubcat = searchDataModel;
    final String? categoryName = examSubcat?.categoryName;
    final String? subcategoryName = examSubcat?.subcategoryName;
    final String? topicName = examSubcat?.topicName;

    final String displayText =
        categoryName ?? subcategoryName ?? topicName ?? '';
    final String type = categoryName != null
        ? 'Category'
        : subcategoryName != null
            ? 'Subcategory'
            : 'Topic';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.r16),
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(AppTokens.s12),
            decoration: BoxDecoration(
              color: AppTokens.surface(context),
              border: Border.all(color: AppTokens.border(context)),
              borderRadius: BorderRadius.circular(AppTokens.r16),
            ),
            child: Row(
              children: [
                Container(
                  height: 56,
                  width: 56,
                  padding: const EdgeInsets.all(AppTokens.s12),
                  decoration: BoxDecoration(
                    color: AppTokens.accentSoft(context),
                    borderRadius: BorderRadius.circular(AppTokens.r16),
                    border: ProgressBorder.all(
                      width: 2,
                      color: AppTokens.success(context),
                      progress: 0.55,
                    ),
                  ),
                  child: SvgPicture.asset(
                    'assets/image/examsubject.svg',
                    colorFilter: ColorFilter.mode(
                      AppTokens.accent(context),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.s12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayText,
                        style: AppTokens.titleSm(context)
                            .copyWith(fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        examSubcat?.description ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTokens.caption(context).copyWith(
                          color: AppTokens.ink2(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        type,
                        style: AppTokens.caption(context).copyWith(
                          color: AppTokens.accent(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildItem1(
      BuildContext context, TestCategoryModel? testCatModel) {
    final store =
        Provider.of<TestCategoryStore>(context, listen: false);
    final model = testCatModel;
    final bool isSelected = selectedCategoryItems
        .any((item) => item['category_id'] == model?.sId);

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
          onTap: () =>
              _toggleOne(model, store.customtestcategory.length),
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
                        model?.category_name ?? '',
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

/// Brand-gradient header: back chip, title, subtitle, count pill, and
/// the Select-All / Deselect pill — shared across the wizard steps.
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
                Icons.grid_view_rounded,
                color: AppTokens.ink2(context),
                size: 32,
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              'No modules available',
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
