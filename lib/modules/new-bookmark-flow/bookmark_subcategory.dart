import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/models/bookmark_subcategory_model.dart';
import 'package:shusruta_lms/modules/bookmarks/store/bookmark_store.dart';
import 'package:shusruta_lms/modules/new-bookmark-flow/bookmark_chap.dart';
import 'package:shusruta_lms/modules/new-bookmark-flow/store/new_bookmark_store.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';

/// BookMarkSubcategoryScreen — multi-select module picker that feeds the
/// downstream [BookMarkChapScreen] with the user-picked subcategory ids.
///
/// Public surface preserved exactly:
///   • class [BookMarkSubcategoryScreen]
///   • required String [type] and `List<String>` [ids] fields
///   • const constructor
///     [BookMarkSubcategoryScreen]({super.key, required this.type,
///     required this.ids}) unchanged
///   • [SingleTickerProviderStateMixin] on state (legacy carry-over)
///   • preserved public-ish state fields [tabIndex], [indexs],
///     `_controller` (all carried from legacy API) and [isAll]
///   • initState still calls
///     `store.onBookMarkSubCategoryApiCallv2(widget.ids, widget.type)`
///   • WillPopScope still pushes [Routes.dashboard] and returns false
///   • Bottom CTA only fires when
///     `store.selectedBookmarkSubCategory.value.isNotEmpty` and pushes a
///     [CupertinoPageRoute] to [BookMarkChapScreen] with
///     `{ ids: selected → subcategory_id, type: widget.type }`
///   • Row tap calls `store.selectBookmarkSubCategory(bookMarkSubCat)`
///     only when the item isn't already in the selection set
///   • Close chip calls
///     `store.removeBookmarkSubCategory(bookMarkSubCat)`
///   • Select-All toggle routes to
///     `store.selectAllBookmarkSubCategories(items)` /
///     `store.deselectAllBookmarkSubCategories()`
///   • Observer bindings over [BookMarkStore.bookmarkSubCategory] and
///     [BookMarkStore.isLoading]
class BookMarkSubcategoryScreen extends StatefulWidget {
  const BookMarkSubcategoryScreen({
    super.key,
    required this.type,
    required this.ids,
  });
  final String type;
  final List<String> ids;

  @override
  State<BookMarkSubcategoryScreen> createState() =>
      _BookMarkSubcategoryScreenState();
}

class _BookMarkSubcategoryScreenState extends State<BookMarkSubcategoryScreen>
    with SingleTickerProviderStateMixin {
  // Preserved from the legacy API even though the new layout doesn't
  // route a tab bar through here.
  // ignore: unused_field
  int tabIndex = 0;
  // ignore: unused_field
  List indexs = [];
  // ignore: unused_field
  TabController? _controller;
  bool isAll = false;

  @override
  void initState() {
    final store = Provider.of<BookMarkStore>(context, listen: false);
    store.onBookMarkSubCategoryApiCallv2(widget.ids, widget.type);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<BookmarkNewStore>(context);
    final store2 = Provider.of<BookMarkStore>(context);
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushNamed(Routes.dashboard);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTokens.scaffold(context),
        bottomNavigationBar: Observer(builder: (_) {
          final bool enabled =
              store.selectedBookmarkSubCategory.value.isNotEmpty;
          return _PrimaryCta(
            label: 'Next',
            enabled: enabled,
            loading: store.isLoading,
            onTap: enabled
                ? () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => BookMarkChapScreen(
                          ids: store.selectedBookmarkSubCategory.value
                              .map((e) => e.subcategory_id!)
                              .toList(),
                          type: widget.type,
                        ),
                      ),
                    );
                  }
                : null,
          );
        }),
        body: Column(
          children: [
            _Header(
              onBack: () => Navigator.of(context).pop(),
              moduleCountBuilder: () => Observer(builder: (_) {
                return Text(
                  store2.bookmarkSubCategory.length
                      .toString()
                      .padLeft(2, '0'),
                  style: AppTokens.titleMd(context).copyWith(
                    color: Colors.white,
                  ),
                );
              }),
              isAll: isAll,
              onToggleSelectAll: () {
                if (!isAll) {
                  store.selectAllBookmarkSubCategories(
                    store2.bookmarkSubCategory.map((e) => e!).toList(),
                  );
                } else {
                  store.deselectAllBookmarkSubCategories();
                }
                isAll = !isAll;
                setState(() {});
              },
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTokens.scaffold(context),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28.8),
                    topRight: Radius.circular(28.8),
                  ),
                ),
                child: Observer(builder: (_) {
                  if (store2.isLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppTokens.accent(context),
                      ),
                    );
                  }
                  if (store2.bookmarkSubCategory.isEmpty) {
                    return const _EmptyState();
                  }
                  return ListView.separated(
                    itemCount: store2.bookmarkSubCategory.length,
                    padding: const EdgeInsets.fromLTRB(
                      AppTokens.s20,
                      AppTokens.s24,
                      AppTokens.s20,
                      AppTokens.s24,
                    ),
                    physics: const BouncingScrollPhysics(),
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppTokens.s12),
                    itemBuilder: (context, index) {
                      final BookMarkSubCategoryModel? item =
                          store2.bookmarkSubCategory[index];
                      final bool selected = store
                          .selectedBookmarkSubCategory.value
                          .contains(item);
                      if (item == null) {
                        return const SizedBox.shrink();
                      }
                      return _ModuleCard(
                        name: item.subcategory_name ?? '',
                        questionCount:
                            (item.questionCount ?? 0).toString(),
                        selected: selected,
                        onTap: () {
                          if (!selected) {
                            store.selectBookmarkSubCategory(item);
                            setState(() {});
                          }
                        },
                        onRemove: () {
                          store.removeBookmarkSubCategory(item);
                          setState(() {});
                        },
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Private widgets
// ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.onBack,
    required this.moduleCountBuilder,
    required this.isAll,
    required this.onToggleSelectAll,
  });

  final VoidCallback onBack;
  final Widget Function() moduleCountBuilder;
  final bool isAll;
  final VoidCallback onToggleSelectAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTokens.brand, AppTokens.brand2],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s12,
            AppTokens.s8,
            AppTokens.s20,
            AppTokens.s16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: onBack,
                      child: Container(
                        height: 40,
                        width: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.22),
                          ),
                        ),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'STEP 2 / 4',
                          style: AppTokens.overline(context).copyWith(
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Modules',
                          style: AppTokens.titleLg(context).copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.s12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppTokens.s8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          height: 36,
                          width: 36,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: AppTokens.radius12,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.22),
                            ),
                          ),
                          child: SvgPicture.asset(
                            'assets/image/examsubject2.svg',
                          ),
                        ),
                        const SizedBox(width: AppTokens.s8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Modules',
                              style: AppTokens.caption(context).copyWith(
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                            const SizedBox(height: 2),
                            moduleCountBuilder(),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onToggleSelectAll,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isAll
                            ? AppTokens.danger(context)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: isAll
                            ? null
                            : Border.all(color: Colors.white),
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
                                : AppTokens.accent(context),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isAll ? 'Deselect' : 'Select All',
                            style: AppTokens.caption(context).copyWith(
                              color: isAll
                                  ? Colors.white
                                  : AppTokens.ink(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.name,
    required this.questionCount,
    required this.selected,
    required this.onTap,
    required this.onRemove,
  });

  final String name;
  final String questionCount;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppTokens.radius16,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(AppTokens.s16),
          decoration: BoxDecoration(
            color: selected
                ? AppTokens.accentSoft(context)
                : AppTokens.surface(context),
            borderRadius: AppTokens.radius16,
            border: Border.all(
              color: selected
                  ? AppTokens.accent(context)
                  : AppTokens.border(context),
              width: selected ? 1.4 : 1,
            ),
            boxShadow: AppTokens.shadow1(context),
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
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(AppTokens.s8),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white
                            : AppTokens.accentSoft(context),
                        borderRadius: AppTokens.radius12,
                      ),
                      child: Image.asset(
                        'assets/image/setting.png',
                        color: isDark ? AppColors.white : null,
                      ),
                    ),
                    const SizedBox(width: AppTokens.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name.isEmpty ? 'Untitled module' : name,
                            style: AppTokens.titleSm(context),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.bookmark_rounded,
                                size: 14,
                                color: AppTokens.accent(context),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$questionCount Questions',
                                style: AppTokens.caption(context).copyWith(
                                  color: AppTokens.accent(context),
                                  fontWeight: FontWeight.w700,
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
              if (selected) ...[
                const SizedBox(width: AppTokens.s8),
                GestureDetector(
                  onTap: onRemove,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: AppTokens.accent(context),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ] else
                Icon(
                  Icons.radio_button_unchecked,
                  size: 20,
                  color: AppTokens.muted(context),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 84,
              width: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTokens.accentSoft(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_open_rounded,
                color: AppTokens.accent(context),
                size: 38,
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              'No modules here',
              style: AppTokens.titleLg(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.s8),
            Text(
              "We're sorry, there's no content available right now. "
              "Check back later or explore other sections for more "
              "educational resources.",
              style: AppTokens.body(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.label,
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, -4),
            blurRadius: 12,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s20,
            AppTokens.s12,
            AppTokens.s20,
            AppTokens.s16,
          ),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: enabled
                      ? const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [AppTokens.brand, AppTokens.brand2],
                        )
                      : null,
                  color: enabled ? null : AppTokens.muted(context),
                  borderRadius: AppTokens.radius12,
                  boxShadow:
                      enabled ? AppTokens.shadow1(context) : null,
                ),
                child: InkWell(
                  borderRadius: AppTokens.radius12,
                  onTap: (loading || !enabled) ? null : onTap,
                  child: Center(
                    child: loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                label,
                                style: AppTokens.titleSm(context).copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: AppTokens.s8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
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
