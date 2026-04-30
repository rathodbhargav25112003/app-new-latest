import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/models/bookmark_by_examlist_model.dart';
import 'package:shusruta_lms/modules/bookmarks/store/bookmark_store.dart';
import 'package:shusruta_lms/modules/new-bookmark-flow/configuration_screen.dart';
import 'package:shusruta_lms/modules/new-bookmark-flow/store/new_bookmark_store.dart';

import '../../helpers/app_tokens.dart';

/// BookMarkPreviewScreen — preview tree before the module is finalised.
/// Shows the selected bookmark hierarchy (Category > Subcategory > Topic >
/// Test for MCQ bookmarks, or Category > Test for Mock bookmarks) with
/// inline controls to drop individual nodes before continuing on to
/// [BookMarkConfigrationScreen].
///
/// Public surface preserved exactly:
///   • class [BookMarkPreviewScreen]
///   • required `String` [type] field
///   • const constructor
///     [BookMarkPreviewScreen]({super.key, required this.type})
///   • [SingleTickerProviderStateMixin] on state (legacy carry-over)
///   • state fields [expandedCategory], [tabIndex], [indexs],
///     [numberOfQuestions], [duration], [name], [description]
///   • helper methods [convertMinutesToHHMMSS],
///     [sumQuestionCountsByMode] unchanged
///   • [WillPopScope] still pops and returns false
///   • Bottom CTA still pushes a [CupertinoPageRoute] to
///     [BookMarkConfigrationScreen]`(type: widget.type)`
///   • Category-tile first-tap expands, second-tap calls
///     `store.deleteCategoryAndLinkedData(categoryId)`
///   • Subcategory tile → `store.deleteSubcategoryAndLinkedData(id)`
///   • Topic tile → `store.deleteTopicAndLinkedData(id)`
///   • Test row → `store.selectedBookmarkTest.value!.remove(test)`
class BookMarkPreviewScreen extends StatefulWidget {
  const BookMarkPreviewScreen({super.key, required this.type});
  final String type;

  @override
  State<BookMarkPreviewScreen> createState() => _BookMarkPreviewScreenState();
}

class _BookMarkPreviewScreenState extends State<BookMarkPreviewScreen>
    with SingleTickerProviderStateMixin {
  Map<int, bool> expandedCategory = {};
  // ignore: unused_field
  int tabIndex = 0;
  // ignore: unused_field
  List indexs = [];
  // ignore: unused_field
  int numberOfQuestions = 1;
  // ignore: unused_field
  int duration = 180;
  // ignore: unused_field
  final TextEditingController name = TextEditingController();
  // ignore: unused_field
  final TextEditingController description = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    super.dispose();
  }

  String convertMinutesToHHMMSS(int minutes) {
    int hours = minutes ~/ 60; // Calculate whole hours
    int remainingMinutes = minutes % 60; // Remaining minutes after hours
    int seconds = 0; // If you have seconds, you can pass them too

    // Format with leading zeros to ensure 2 digits (e.g., 01:05:00)
    String formattedTime = '${hours.toString().padLeft(2, '0')}:'
        '${remainingMinutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';

    return formattedTime;
  }

  int sumQuestionCountsByMode(List<BookMarkByExamListModel> bookmarkList) {
    int count = 0;
    for (var item in bookmarkList) {
      count += item.bookmarkCount ?? 0;
    }
    return count;
  }

  void _toggleOrRemoveCategory({
    required BookmarkNewStore store,
    required int index,
    required bool isExpanded,
    required String categoryId,
  }) {
    if (!isExpanded) {
      expandedCategory[index] = true;
      setState(() {});
    } else {
      store.deleteCategoryAndLinkedData(categoryId);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<BookmarkNewStore>(context);
    // Kept to match legacy listen-pattern even though the main tree reads
    // from [BookmarkNewStore].
    // ignore: unused_local_variable
    final store2 = Provider.of<BookMarkStore>(context);

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTokens.scaffold(context),
        bottomNavigationBar: Observer(builder: (_) {
          final int picked = store.selectedBookmarkTest.value.length;
          final bool enabled = !store.isLoading && picked > 0;
          return _PrimaryCta(
            label: 'Next',
            enabled: enabled,
            loading: store.isLoading,
            onTap: enabled
                ? () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => BookMarkConfigrationScreen(
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
              type: widget.type,
              totalsBuilder: () => Observer(builder: (_) {
                final int totalTests =
                    store.selectedBookmarkTest.value.length;
                final int totalQuestions = sumQuestionCountsByMode(
                  store.selectedBookmarkTest.value,
                );
                return _HeaderStatsRow(
                  totalTests: totalTests,
                  totalQuestions: totalQuestions,
                );
              }),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTokens.surface(context),
                  borderRadius: (Platform.isWindows || Platform.isMacOS)
                      ? null
                      : const BorderRadius.only(
                          topLeft: Radius.circular(28.8),
                          topRight: Radius.circular(28.8),
                        ),
                ),
                child: Observer(builder: (_) {
                  final categories =
                      store.selectedBookmarkCategory.value ?? const [];
                  if (categories.isEmpty) {
                    return const _EmptyState();
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppTokens.s20,
                      AppTokens.s24,
                      AppTokens.s20,
                      AppTokens.s24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Review your picks',
                          style: AppTokens.overline(context),
                        ),
                        const SizedBox(height: AppTokens.s8),
                        Text(
                          'Expand a category to peek at what will run. Tap Edit to drop a node.',
                          style: AppTokens.caption(context),
                        ),
                        const SizedBox(height: AppTokens.s20),
                        ListView.separated(
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: categories.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppTokens.s12),
                          itemBuilder: (context, categoryIndex) {
                            final category = categories[categoryIndex];
                            final isExpanded =
                                expandedCategory[categoryIndex] ?? false;

                            final tests = store.selectedBookmarkTest.value
                                .where((t) =>
                                    t.category_id == category.category_id)
                                .toList();
                            final subcategories = store
                                .selectedBookmarkSubCategory.value
                                .where((s) =>
                                    s.category_id == category.category_id)
                                .toList();

                            return _CategoryCard(
                              title: category.category_name ?? '',
                              questionCount: category.questionCount ?? 0,
                              isExpanded: isExpanded,
                              onCollapse: () {
                                expandedCategory[categoryIndex] = false;
                                setState(() {});
                              },
                              onPrimaryTap: () => _toggleOrRemoveCategory(
                                store: store,
                                index: categoryIndex,
                                isExpanded: isExpanded,
                                categoryId: category.category_id ?? '',
                              ),
                              child: widget.type == 'MockBookmark'
                                  ? _MockTestList(
                                      tests: tests,
                                      onRemove: (test) {
                                        store.selectedBookmarkTest.value
                                            .remove(test);
                                        setState(() {});
                                      },
                                    )
                                  : _McqHierarchy(
                                      store: store,
                                      subcategories: subcategories,
                                      onRemoveSubcategory: (sub) {
                                        store.deleteSubcategoryAndLinkedData(
                                          sub.subcategory_id ?? '',
                                        );
                                        setState(() {});
                                      },
                                      onRemoveTopic: (topic) {
                                        store.deleteTopicAndLinkedData(
                                          topic.topic_id ?? '',
                                        );
                                        setState(() {});
                                      },
                                      onRemoveTest: (test) {
                                        store.selectedBookmarkTest.value
                                            .remove(test);
                                        setState(() {});
                                      },
                                    ),
                            );
                          },
                        ),
                        const SizedBox(height: AppTokens.s24),
                      ],
                    ),
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
    required this.type,
    required this.totalsBuilder,
  });

  final VoidCallback onBack;
  final String type;
  final Widget Function() totalsBuilder;

  String _typeLabel() {
    switch (type) {
      case 'McqBookmark':
        return 'MCQ BOOKMARKS';
      case 'MockBookmark':
        return 'MOCK BOOKMARKS';
      default:
        return type.toUpperCase();
    }
  }

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
                      'PREVIEW · ${_typeLabel()}',
                      style: AppTokens.overline(context).copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.s20),
              Text(
                'Look through the plan',
                style: AppTokens.displayMd(context).copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Keep what you want, edit out the rest. Hit Next when the shape feels right.',
                style: AppTokens.body(context).copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: AppTokens.s16),
              totalsBuilder(),
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

class _HeaderStatsRow extends StatelessWidget {
  const _HeaderStatsRow({
    required this.totalTests,
    required this.totalQuestions,
  });

  final int totalTests;
  final int totalQuestions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _HeaderStatTile(
            icon: Icons.quiz_rounded,
            value: totalQuestions.toString(),
            label: 'Total questions',
          ),
        ),
        const SizedBox(width: AppTokens.s12),
        Expanded(
          child: _HeaderStatTile(
            icon: Icons.schedule_rounded,
            value: '$totalQuestions min',
            label: 'Time duration',
          ),
        ),
        const SizedBox(width: AppTokens.s12),
        Expanded(
          child: _HeaderStatTile(
            icon: Icons.collections_bookmark_rounded,
            value: totalTests.toString(),
            label: 'Tests picked',
          ),
        ),
      ],
    );
  }
}

class _HeaderStatTile extends StatelessWidget {
  const _HeaderStatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: AppTokens.radius12,
        border: Border.all(
          color: Colors.white.withOpacity(0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: AppTokens.titleSm(context).copyWith(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTokens.caption(context).copyWith(
              color: Colors.white.withOpacity(0.85),
              fontSize: 11,
            ),
          ),
        ],
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
    required this.questionCount,
    required this.isExpanded,
    required this.onPrimaryTap,
    required this.onCollapse,
    required this.child,
  });

  final String title;
  final int questionCount;
  final bool isExpanded;
  final VoidCallback onPrimaryTap;
  final VoidCallback onCollapse;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius16,
        border: Border.all(color: AppTokens.border(context)),
        boxShadow: AppTokens.shadow1(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: AppTokens.radius16,
            onTap: onPrimaryTap,
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.s16),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTokens.accentSoft(context),
                      borderRadius: AppTokens.radius12,
                    ),
                    child: Icon(
                      Icons.folder_rounded,
                      size: 20,
                      color: AppTokens.accent(context),
                    ),
                  ),
                  const SizedBox(width: AppTokens.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTokens.titleSm(context)),
                        const SizedBox(height: 2),
                        Text(
                          '$questionCount Questions',
                          style: AppTokens.caption(context).copyWith(
                            color: AppTokens.accent(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isExpanded)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _GhostIconButton(
                          icon: Icons.keyboard_arrow_up_rounded,
                          onTap: onCollapse,
                        ),
                        const SizedBox(width: 6),
                        _CloseChip(onTap: onPrimaryTap),
                      ],
                    )
                  else
                    _EditPill(onTap: onPrimaryTap),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s16,
                0,
                AppTokens.s16,
                AppTokens.s12,
              ),
              child: child,
            ),
        ],
      ),
    );
  }
}

class _EditPill extends StatelessWidget {
  const _EditPill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTokens.radius12,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppTokens.accentSoft(context),
            borderRadius: AppTokens.radius12,
            border: Border.all(
              color: AppTokens.accent(context).withOpacity(0.25),
            ),
          ),
          child: Text(
            'Edit',
            style: AppTokens.caption(context).copyWith(
              color: AppTokens.accent(context),
              fontWeight: FontWeight.w700,
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
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTokens.danger(context),
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

class _GhostIconButton extends StatelessWidget {
  const _GhostIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTokens.surface2(context),
            shape: BoxShape.circle,
            border: Border.all(color: AppTokens.border(context)),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppTokens.ink2(context),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mock bookmark — just tests under a category
// ---------------------------------------------------------------------------

class _MockTestList extends StatelessWidget {
  const _MockTestList({
    required this.tests,
    required this.onRemove,
  });

  final List<BookMarkByExamListModel> tests;
  final ValueChanged<BookMarkByExamListModel> onRemove;

  @override
  Widget build(BuildContext context) {
    if (tests.isEmpty) {
      return _InlineHint(
        message: 'No tests in this category yet.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final t in tests)
          Padding(
            padding: const EdgeInsets.only(top: AppTokens.s8),
            child: _LeafTile(
              icon: Icons.quiz_rounded,
              title: t.examName ?? '',
              subtitle: '${t.bookmarkCount ?? 0} Questions',
              onRemove: () => onRemove(t),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// MCQ bookmark — subcategory > topic > test
// ---------------------------------------------------------------------------

class _McqHierarchy extends StatelessWidget {
  const _McqHierarchy({
    required this.store,
    required this.subcategories,
    required this.onRemoveSubcategory,
    required this.onRemoveTopic,
    required this.onRemoveTest,
  });

  final BookmarkNewStore store;
  final List subcategories;
  final ValueChanged onRemoveSubcategory;
  final ValueChanged onRemoveTopic;
  final ValueChanged<BookMarkByExamListModel> onRemoveTest;

  @override
  Widget build(BuildContext context) {
    if (subcategories.isEmpty) {
      return _InlineHint(
        message: 'No subcategories in this category yet.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final sub in subcategories) ...[
          const SizedBox(height: AppTokens.s8),
          _SubLevelHeader(
            icon: Icons.account_tree_rounded,
            title: sub.subcategory_name ?? '',
            subtitle: '${sub.questionCount ?? 0} Questions',
            onRemove: () => onRemoveSubcategory(sub),
          ),
          Padding(
            padding: const EdgeInsets.only(left: AppTokens.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final topic in store.selectedBookmarkTopic.value.where(
                    (t) => t.subcategory_id == sub.subcategory_id)) ...[
                  const SizedBox(height: 6),
                  _SubLevelHeader(
                    icon: Icons.topic_rounded,
                    title: topic.topic_name ?? '',
                    subtitle: '${topic.questionCount ?? 0} Questions',
                    muted: true,
                    onRemove: () => onRemoveTopic(topic),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: AppTokens.s16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final test in store.selectedBookmarkTest.value
                            .where((x) => x.topic_id == topic.topic_id))
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: _LeafTile(
                              icon: Icons.quiz_rounded,
                              title: test.examName ?? '',
                              subtitle:
                                  '${test.questionCount ?? 0} Questions',
                              onRemove: () => onRemoveTest(test),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SubLevelHeader extends StatelessWidget {
  const _SubLevelHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onRemove,
    this.muted = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onRemove;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s8,
      ),
      decoration: BoxDecoration(
        color: muted
            ? AppTokens.surface2(context)
            : AppTokens.accentSoft(context),
        borderRadius: AppTokens.radius12,
        border: Border.all(
          color: muted
              ? AppTokens.border(context)
              : AppTokens.accent(context).withOpacity(0.22),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: muted
                ? AppTokens.ink2(context)
                : AppTokens.accent(context),
          ),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTokens.titleSm(context).copyWith(fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTokens.caption(context)),
              ],
            ),
          ),
          _CloseChip(onTap: onRemove),
        ],
      ),
    );
  }
}

class _LeafTile extends StatelessWidget {
  const _LeafTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onRemove,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s8,
      ),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius12,
        border: Border.all(color: AppTokens.border(context)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTokens.ink2(context)),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTokens.titleSm(context).copyWith(fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTokens.caption(context)),
              ],
            ),
          ),
          _CloseChip(onTap: onRemove),
        ],
      ),
    );
  }
}

class _InlineHint extends StatelessWidget {
  const _InlineHint({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s8,
      ),
      decoration: BoxDecoration(
        color: AppTokens.surface2(context),
        borderRadius: AppTokens.radius12,
        border: Border.all(color: AppTokens.border(context)),
      ),
      child: Text(message, style: AppTokens.caption(context)),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty + CTA
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
                Icons.inbox_rounded,
                color: AppTokens.accent(context),
                size: 30,
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              'Nothing picked yet',
              style: AppTokens.titleMd(context),
            ),
            const SizedBox(height: 6),
            Text(
              'Go back and pick a category to see the preview here.',
              textAlign: TextAlign.center,
              style: AppTokens.body(context),
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
