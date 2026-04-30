import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../widgets/no_internet_connection.dart';
import 'model/custom_test_sub_by_category_model.dart';
import 'package:shusruta_lms/helpers/custom_dynamic_height_gridview.dart';
import 'package:shusruta_lms/modules/customtests/store/custom_test_store.dart';

// Legacy imports preserved for API parity; no longer referenced by the UI.
// ignore: unused_import
import '../../helpers/colors.dart';
// ignore: unused_import
import '../../helpers/styles.dart';
// ignore: unused_import, unnecessary_import
import 'package:flutter/widgets.dart';
// ignore: unused_import, unnecessary_import
import 'package:flutter/services.dart';
// ignore: unused_import
import '../../helpers/dimensions.dart';
// ignore: unused_import
import '../../models/searched_data_model.dart';
// ignore: unused_import
import '../../models/test_subcategory_model.dart';
// ignore: unused_import
import 'package:expandable_text/expandable_text.dart';
// ignore: unused_import
import 'package:progress_border/progress_border.dart';
// ignore: unused_import
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';

/// SelectCustomTestsChapter — second step of the custom-test wizard: shows
/// chapters that live under the previously selected categories and lets
/// the learner multi-select them. Public surface preserved exactly:
///   • const `SelectCustomTestsChapter({super.key,
///       required List of Map selectedCategoryItems})`
///   • static `Route<dynamic> route(RouteSettings)` factory reading
///     `arguments['selectedCategoryItems']`
///   • Next button pushes [Routes.customTestSelectTopic] with
///     `selectedCategoryItems` + `selectedChapterItems` (map keys:
///     `subcategory_id`, `subcategory_name`, `category_id`,
///     `question_count`)
///   • Chapter load dispatches
///     `CustomTestCategoryStore.onCustomSubCategoryApiCall(csvIds)`
class SelectCustomTestsChapter extends StatefulWidget {
  final List<Map<String, dynamic>> selectedCategoryItems;
  const SelectCustomTestsChapter({
    super.key,
    required this.selectedCategoryItems,
  });

  @override
  State<SelectCustomTestsChapter> createState() =>
      _SelectCustomTestsChapterState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => SelectCustomTestsChapter(
        selectedCategoryItems: arguments['selectedCategoryItems'],
      ),
    );
  }
}

class _SelectCustomTestsChapterState extends State<SelectCustomTestsChapter> {
  // ignore: unused_field
  String query = '';
  List<Map<String, dynamic>> selectedChapterItems = [];
  bool isAll = false;
  @override
  void initState() {
    super.initState();
    getChapterData();
  }

  Future<void> getChapterData() async {
    final List<Map<String, dynamic>> selectedItems =
        widget.selectedCategoryItems;
    final List<String> categoryIds =
        selectedItems.map((item) => item['category_id'].toString()).toList();
    final String categoryIdsString = categoryIds.join(',');
    final store =
        Provider.of<CustomTestCategoryStore>(context, listen: false);
    await store.onCustomSubCategoryApiCall(categoryIdsString);
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = Platform.isWindows || Platform.isMacOS;
    final store = Provider.of<CustomTestCategoryStore>(context);
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          _GradientHeader(
            count: store.customTestSubByCateList.length,
            isAll: isAll,
            onBack: () => Navigator.pop(context),
            onToggleAll: () {
              if (!isAll) {
                selectedChapterItems
                  ..clear()
                  ..addAll(store.customTestSubByCateList
                      .map((e) => {
                            'subcategory_id': e?.sId,
                            'subcategory_name': e?.subcategoryName,
                            'category_id': e?.categoryId,
                            'question_count': e?.questionCount,
                          })
                      .toList());
              } else {
                selectedChapterItems.clear();
              }
              isAll = !isAll;
              setState(() {});
            },
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTokens.scaffold(context),
                borderRadius: isDesktop
                    ? null
                    : const BorderRadius.only(
                        topLeft: Radius.circular(AppTokens.r28),
                        topRight: Radius.circular(AppTokens.r28),
                      ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.s16,
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
                          if (store.customTestSubByCateList.isEmpty) {
                            return const _EmptyView();
                          }
                          return store.isConnected
                              ? Padding(
                                  padding: const EdgeInsets.only(
                                    top: AppTokens.s16,
                                  ),
                                  child: isDesktop
                                      ? CustomDynamicHeightGridView(
                                          crossAxisCount: 3,
                                          mainAxisSpacing: AppTokens.s12,
                                          shrinkWrap: true,
                                          physics:
                                              const BouncingScrollPhysics(),
                                          itemCount: store
                                              .customTestSubByCateList
                                              .length,
                                          builder: (BuildContext context,
                                              int index) {
                                            return _buildItem(
                                                context,
                                                store.customTestSubByCateList[
                                                    index]);
                                          },
                                        )
                                      : ListView.builder(
                                          itemCount: store
                                              .customTestSubByCateList.length,
                                          shrinkWrap: true,
                                          padding: EdgeInsets.zero,
                                          physics:
                                              const BouncingScrollPhysics(),
                                          itemBuilder: (BuildContext context,
                                              int index) {
                                            return _buildItem(
                                                context,
                                                store.customTestSubByCateList[
                                                    index]);
                                          },
                                        ),
                                )
                              : const NoInternetScreen();
                        },
                      ),
                    ),
                  ),
                  _NextCta(
                    enabled: selectedChapterItems.isNotEmpty,
                    selectedCount: selectedChapterItems.length,
                    onTap: () {
                      Navigator.of(context).pushNamed(
                          Routes.customTestSelectTopic,
                          arguments: {
                            "selectedCategoryItems":
                                widget.selectedCategoryItems,
                            "selectedChapterItems": selectedChapterItems,
                          });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
      BuildContext context, CustomTestSubByCategoryModel? testCatModel) {
    CustomTestSubByCategoryModel? customSubCate = testCatModel;
    bool isSelected = selectedChapterItems
        .any((item) => item['subcategory_id'] == customSubCate?.sId);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.r16),
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedChapterItems.removeWhere(
                    (item) => item['subcategory_id'] == customSubCate?.sId);
              } else {
                selectedChapterItems.add({
                  'subcategory_id': customSubCate?.sId,
                  'subcategory_name': customSubCate?.subcategoryName,
                  'category_id': customSubCate?.categoryId,
                  'question_count': customSubCate?.questionCount,
                });
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(AppTokens.s12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTokens.accentSoft(context)
                  : AppTokens.surface(context),
              border: Border.all(
                color: isSelected
                    ? AppTokens.accent(context)
                    : AppTokens.border(context),
                width: isSelected ? 1.6 : 1,
              ),
              borderRadius: BorderRadius.circular(AppTokens.r16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        height: 48,
                        width: 48,
                        padding: const EdgeInsets.all(AppTokens.s8),
                        decoration: BoxDecoration(
                          color: AppTokens.accentSoft(context),
                          borderRadius:
                              BorderRadius.circular(AppTokens.r12),
                        ),
                        child: SvgPicture.asset(
                          "assets/image/examsubject2.svg",
                          colorFilter: ColorFilter.mode(
                              AppTokens.accent(context),
                              BlendMode.srcIn),
                        ),
                      ),
                      const SizedBox(width: AppTokens.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customSubCate?.subcategoryName ?? '',
                              style: AppTokens.titleSm(context).copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.quiz_outlined,
                                  size: 13,
                                  color: AppTokens.accent(context),
                                ),
                                const SizedBox(width: AppTokens.s4),
                                Text(
                                  "${customSubCate?.questionCount ?? ''} Questions",
                                  style: AppTokens.caption(context)
                                      .copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTokens.accent(context),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTokens.accent(context)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? AppTokens.accent(context)
                          : AppTokens.border(context),
                      width: 1.6,
                    ),
                    borderRadius:
                        BorderRadius.circular(AppTokens.r8),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 18)
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

class _GradientHeader extends StatelessWidget {
  const _GradientHeader({
    required this.count,
    required this.isAll,
    required this.onBack,
    required this.onToggleAll,
  });

  final int count;
  final bool isAll;
  final VoidCallback onBack;
  final VoidCallback onToggleAll;

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Platform.isWindows || Platform.isMacOS;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: isDesktop
            ? AppTokens.s20
            : MediaQuery.of(context).padding.top + AppTokens.s8,
        left: AppTokens.s16,
        right: AppTokens.s16,
        bottom: AppTokens.s20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTokens.brand, AppTokens.brand2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: Colors.white24,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onBack,
                  child: const SizedBox(
                    width: 40,
                    height: 40,
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
                  'Chapters',
                  style: AppTokens.titleMd(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s12,
                  vertical: AppTokens.s8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius:
                      BorderRadius.circular(AppTokens.r12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.menu_book_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: AppTokens.s8),
                    Text(
                      '${count.toString().padLeft(2, '0')} chapters',
                      style: AppTokens.caption(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: isAll ? AppTokens.danger(context) : Colors.white,
                borderRadius:
                    BorderRadius.circular(AppTokens.r28),
                child: InkWell(
                  onTap: onToggleAll,
                  borderRadius:
                      BorderRadius.circular(AppTokens.r28),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.s16,
                      vertical: AppTokens.s8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAll
                              ? Icons.close_rounded
                              : Icons.check_circle_rounded,
                          color: isAll
                              ? Colors.white
                              : AppTokens.brand,
                          size: 16,
                        ),
                        const SizedBox(width: AppTokens.s8),
                        Text(
                          isAll ? 'Deselect' : 'Select All',
                          style: AppTokens.caption(context).copyWith(
                            color: isAll
                                ? Colors.white
                                : AppTokens.brand,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.s24),
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
              'No chapters available',
              textAlign: TextAlign.center,
              style: AppTokens.titleSm(context)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppTokens.s8),
            Text(
              "We're sorry, there's no content here yet. Please check back later or explore other sections for more educational resources.",
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
  const _NextCta({
    required this.enabled,
    required this.selectedCount,
    required this.onTap,
  });

  final bool enabled;
  final int selectedCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.s16,
          AppTokens.s12,
          AppTokens.s16,
          AppTokens.s12,
        ),
        child: Opacity(
          opacity: enabled ? 1 : 0.55,
          child: Container(
            width: double.infinity,
            height: 54,
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
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: enabled ? onTap : null,
                borderRadius: BorderRadius.circular(AppTokens.r16),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedCount > 0
                            ? 'Next · $selectedCount selected'
                            : 'Next',
                        style: AppTokens.body(context).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: AppTokens.s8),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
