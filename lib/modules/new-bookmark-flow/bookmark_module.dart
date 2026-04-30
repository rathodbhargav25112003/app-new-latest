import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/models/bookmark_category_model.dart';
import 'package:shusruta_lms/modules/bookmarks/store/bookmark_store.dart';
import 'package:shusruta_lms/modules/new-bookmark-flow/bookmark_test.dart';
import 'package:shusruta_lms/modules/new-bookmark-flow/store/new_bookmark_store.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import 'bookmark_subcategory.dart';

/// BookMarkModuleScreen — Step-1 custom-module category picker that feeds
/// either [BookMarkSubcategoryScreen] (MCQ flow) or [BookMarkTestScreen]
/// (Mock flow) with the selected category IDs.
///
/// Public surface preserved exactly:
///   • class [BookMarkModuleScreen]
///   • required `String` [type] and `String` [id] fields
///   • const constructor
///     [BookMarkModuleScreen]({super.key, required type, required id})
///   • [SingleTickerProviderStateMixin] on the state
///   • state fields [tabIndex], [indexs], [isAll], `_controller`
///   • initState still spins up a length-2 [TabController] with a
///     listener that syncs [tabIndex] and fires either
///     `store.onBookMarkCategoryApiCall(context)` (MCQ) or
///     `store.onMasterBookMarkCategoryApiCall(context)` (Mock)
///   • [WillPopScope] pushes [Routes.dashboard] and returns false
///   • Tap-to-select routes through `store.selectBookmarkCategory(item)`
///     only when the item isn't already in the set
///   • Close chip routes through `store.removeBookmarkCategory(item)`
///   • Select-All toggle routes through
///     `store.selectAllBookmarkCategories([...])` /
///     `store.deselectAllBookmarkCategories()` with the same
///     `.map((e) => e!).toList()` casting of the source list
///   • Bottom CTA fires only when `selectedBookmarkCategory.value` is
///     non-empty; MCQ flow pushes a [CupertinoPageRoute] to
///     [BookMarkSubcategoryScreen] and Mock pushes to
///     [BookMarkTestScreen] with the same
///     `.map((e) => e.category_id!)` id payload
class BookMarkModuleScreen extends StatefulWidget {
  const BookMarkModuleScreen({
    super.key,
    required this.type,
    required this.id,
  });
  final String type;
  final String id;

  @override
  State<BookMarkModuleScreen> createState() => _BookMarkModuleScreenState();
}

class _BookMarkModuleScreenState extends State<BookMarkModuleScreen>
    with SingleTickerProviderStateMixin {
  int tabIndex = 0;
  // ignore: unused_field
  List indexs = [];
  bool isAll = false;
  TabController? _controller;

  @override
  void initState() {
    final store = Provider.of<BookMarkStore>(context, listen: false);
    if (widget.type == 'McqBookmark') {
      store.onBookMarkCategoryApiCall(context);
    } else {
      store.onMasterBookMarkCategoryApiCall(context);
    }
    _controller = TabController(
      length: 2,
      vsync: this,
      initialIndex: tabIndex,
    );
    _controller?.addListener(() {
      setState(() {
        tabIndex = _controller?.index ?? 0;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  List<BookMarkCategoryModel> _sourceCategories(BookMarkStore store) {
    final list = widget.type == 'McqBookmark'
        ? store.bookmarkCategory
        : store.masterBookmarkCategory;
    return list.whereType<BookMarkCategoryModel>().toList();
  }

  String _typeLabel() =>
      widget.type == 'McqBookmark' ? 'MCQ BOOKMARKS' : 'MOCK BOOKMARKS';

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
          final selected =
              store.selectedBookmarkCategory.value ?? const [];
          final bool enabled = !store.isLoading && selected.isNotEmpty;
          return _PrimaryCta(
            label: 'Next',
            enabled: enabled,
            loading: store.isLoading,
            onTap: enabled
                ? () {
                    final ids = selected
                        .map((e) => e.category_id ?? '')
                        .where((id) => id.isNotEmpty)
                        .toList();
                    if (widget.type == 'McqBookmark') {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => BookMarkSubcategoryScreen(
                            ids: ids,
                            type: widget.type,
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => BookMarkTestScreen(
                            ids: ids,
                            type: widget.type,
                          ),
                        ),
                      );
                    }
                  }
                : null,
          );
        }),
        body: Column(
          children: [
            _Header(
              onBack: () => Navigator.of(context).pop(),
              typeLabel: _typeLabel(),
              countBuilder: () => Observer(builder: (_) {
                return Text(
                  _sourceCategories(store2)
                      .length
                      .toString()
                      .padLeft(2, '0'),
                  style: AppTokens.titleMd(context).copyWith(
                    color: Colors.white,
                  ),
                );
              }),
              isAll: isAll,
              onToggleSelectAll: () {
                final source = _sourceCategories(store2);
                if (!isAll) {
                  store.selectAllBookmarkCategories(source);
                } else {
                  store.deselectAllBookmarkCategories();
                }
                isAll = !isAll;
                setState(() {});
              },
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTokens.surface(context),
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
                  final source = _sourceCategories(store2);
                  if (source.isEmpty) {
                    return const _EmptyState();
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppTokens.s20,
                      AppTokens.s24,
                      AppTokens.s20,
                      AppTokens.s24,
                    ),
                    itemCount: source.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppTokens.s12),
                    itemBuilder: (context, index) {
                      final item = source[index];
                      final selected =
                          store.selectedBookmarkCategory.value ?? const [];
                      final isSelected = selected.contains(item);
                      return _CategoryCard(
                        title: item.category_name ?? '',
                        subtitle: '${item.questionCount ?? 0} Questions',
                        isSelected: isSelected,
                        onTap: () {
                          if (!isSelected) {
                            store.selectBookmarkCategory(item);
                            setState(() {});
                          }
                        },
                        onRemove: () {
                          store.removeBookmarkCategory(item);
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

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({
    required this.onBack,
    required this.typeLabel,
    required this.countBuilder,
    required this.isAll,
    required this.onToggleSelectAll,
  });

  final VoidCallback onBack;
  final String typeLabel;
  final Widget Function() countBuilder;
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
            AppTokens.s20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _BackChip(onTap: onBack),
                  const SizedBox(width: AppTokens.s8),
                  Expanded(
                    child: Text(
                      'STEP 1/4 · $typeLabel',
                      style: AppTokens.overline(context).copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.s12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: AppTokens.radius12,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.22),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        countBuilder(),
                        const SizedBox(width: 6),
                        Text(
                          'topics',
                          style: AppTokens.caption(context).copyWith(
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.s20),
              Text(
                'Custom Module',
                style: AppTokens.displayMd(context).copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pick the categories you want this module to cover, then we\'ll narrow down the questions step-by-step.',
                style: AppTokens.body(context).copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: AppTokens.s16),
              _SelectAllPill(
                isAll: isAll,
                onTap: onToggleSelectAll,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackChip extends StatelessWidget {
  const _BackChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.22)),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _SelectAllPill extends StatelessWidget {
  const _SelectAllPill({required this.isAll, required this.onTap});
  final bool isAll;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isAll
                ? AppTokens.danger(context)
                : Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isAll
                  ? AppTokens.danger(context)
                  : Colors.white.withOpacity(0.22),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isAll ? Icons.close_rounded : Icons.check_circle_rounded,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                isAll ? 'Deselect all' : 'Select all',
                style: AppTokens.titleSm(context).copyWith(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category card
// ---------------------------------------------------------------------------

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.onRemove,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isSelected
            ? AppTokens.accentSoft(context)
            : AppTokens.surface(context),
        borderRadius: AppTokens.radius16,
        border: Border.all(
          color: isSelected
              ? AppTokens.accent(context)
              : AppTokens.border(context),
          width: isSelected ? 1.6 : 1,
        ),
        boxShadow: isSelected ? null : AppTokens.shadow1(context),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppTokens.radius16,
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.s16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTokens.accent(context)
                        : AppTokens.accentSoft(context),
                    borderRadius: AppTokens.radius12,
                  ),
                  child: SvgPicture.asset(
                    'assets/image/bookmarktopic.svg',
                    width: 22,
                    height: 22,
                    // ignore: deprecated_member_use
                    color: isSelected
                        ? Colors.white
                        : AppTokens.accent(context),
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
                        style: AppTokens.titleSm(context),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTokens.caption(context).copyWith(
                          color: AppTokens.accent(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  _CloseChip(onTap: onRemove)
                else
                  Icon(
                    Icons.radio_button_unchecked_rounded,
                    color: AppTokens.border(context),
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseChip extends StatelessWidget {
  const _CloseChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTokens.accent(context),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.close_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTokens.accentSoft(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_border_rounded,
                color: AppTokens.accent(context),
                size: 30,
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              'No categories yet',
              style: AppTokens.titleMd(context),
            ),
            const SizedBox(height: 6),
            Text(
              'Your bookmark categories will show up here once questions are saved.',
              textAlign: TextAlign.center,
              style: AppTokens.body(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Primary CTA
// ---------------------------------------------------------------------------

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
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.s20,
          AppTokens.s12,
          AppTokens.s20,
          AppTokens.s16,
        ),
        decoration: BoxDecoration(
          color: AppTokens.surface(context),
          border: Border(
            top: BorderSide(color: AppTokens.border(context)),
          ),
        ),
        child: SizedBox(
          height: 54,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: loading ? null : onTap,
              borderRadius: AppTokens.radius16,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: enabled
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppTokens.brand, AppTokens.brand2],
                        )
                      : null,
                  color: enabled ? null : AppTokens.surface3(context),
                  borderRadius: AppTokens.radius16,
                  boxShadow: enabled ? AppTokens.shadow2(context) : null,
                ),
                child: Center(
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              style: AppTokens.titleSm(context).copyWith(
                                color: enabled
                                    ? Colors.white
                                    : AppTokens.muted(context),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: AppTokens.s8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: enabled
                                  ? Colors.white
                                  : AppTokens.muted(context),
                            ),
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
