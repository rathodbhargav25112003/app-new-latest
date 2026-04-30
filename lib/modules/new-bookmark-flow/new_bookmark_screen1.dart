import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/modules/bookmarks/store/bookmark_store.dart';
import 'package:shusruta_lms/modules/new-bookmark-flow/bookmark_exam_dashboard.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../models/bookmark_category_model.dart';
import '../widgets/no_internet_connection.dart';

/// BookMarkScreen1 — two-tab hub for the new bookmark flow.
/// Tab 0 surfaces the MCQ-bank bookmark categories; Tab 1 surfaces the
/// mock-exam (master) bookmark categories. A sticky bottom CTA opens
/// the combined [BookMarkExamDashboardScreen] for the active tab.
///
/// Public surface preserved exactly:
///   • class [BookMarkScreen1] with const no-arg constructor
///   • [SingleTickerProviderStateMixin] on the state (owns the
///     internal [TabController])
///   • initState still calls
///     `store.onBookMarkCategoryApiCall(context)` and
///     `store.onMasterBookMarkCategoryApiCall(context)` and wires a
///     length-2 [TabController] with a setState listener over
///     `tabIndex`
///   • WillPopScope still pushes [Routes.dashboard] and returns false
///   • MCQ-tab tap navigates to [Routes.bookMarkSubcategoryList] with
///     `{ categoryName, categoryId }`
///   • Mock-tab tap navigates to [Routes.masterBookMarkExamList] with
///     `{ categoryId, categoryName, type: 'topic' }`
///   • CTA pushes [CupertinoPageRoute] → [BookMarkExamDashboardScreen]
///     with `isCustome: false, id: '', questionCount: 0, title:
///     'Custom Bookmark Section', type: 'McqBookmark' | 'MockBookmark'`
///   • Observer binding over [BookMarkStore.bookmarkCategory],
///     [BookMarkStore.masterBookmarkCategory], [BookMarkStore.isLoading],
///     [BookMarkStore.isConnected]
///   • [NoInternetScreen] fallback on the connectivity flag
class BookMarkScreen1 extends StatefulWidget {
  const BookMarkScreen1();

  @override
  State<BookMarkScreen1> createState() => _BookMarkScreen1State();
}

class _BookMarkScreen1State extends State<BookMarkScreen1>
    with SingleTickerProviderStateMixin {
  int tabIndex = 0;
  TabController? _controller;

  @override
  void initState() {
    final store = Provider.of<BookMarkStore>(context, listen: false);
    store.onBookMarkCategoryApiCall(context);
    store.onMasterBookMarkCategoryApiCall(context);
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

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<BookMarkStore>(context);
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushNamed(Routes.dashboard);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTokens.scaffold(context),
        bottomNavigationBar: _SolveCta(
          isLoading: store.isLoading,
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => BookMarkExamDashboardScreen(
                  isCustome: false,
                  id: "",
                  questionCount: 0,
                  title: "Custom Bookmark Section",
                  type: _controller!.index == 0
                      ? "McqBookmark"
                      : "MockBookmark",
                ),
              ),
            );
          },
        ),
        body: Column(
          children: [
            _Header(
              onBack: () =>
                  Navigator.of(context).pushNamed(Routes.dashboard),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTokens.scaffold(context),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28.8),
                    topRight: Radius.circular(28.8),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: AppTokens.s20),
                    _SegmentedTabs(
                      controller: _controller!,
                      tabIndex: tabIndex,
                      labels: const ['MCQ Bank', 'Mock Exams'],
                    ),
                    const SizedBox(height: AppTokens.s16),
                    Expanded(
                      child: TabBarView(
                        controller: _controller,
                        children: [
                          _CategoryTab(
                            isMaster: false,
                            isLoading: store.isLoading,
                            isConnected: store.isConnected,
                            categories: store.bookmarkCategory,
                          ),
                          _CategoryTab(
                            isMaster: true,
                            isLoading: store.isLoading,
                            isConnected: store.isConnected,
                            categories: store.masterBookmarkCategory,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
  const _Header({required this.onBack});

  final VoidCallback onBack;

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
            AppTokens.s24,
          ),
          child: Row(
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
                      'MY BOOKMARKS',
                      style: AppTokens.overline(context).copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bookmarks',
                      style: AppTokens.titleLg(context).copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 44,
                width: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.22),
                  ),
                ),
                child: const Icon(
                  Icons.bookmark_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.controller,
    required this.tabIndex,
    required this.labels,
  });

  final TabController controller;
  final int tabIndex;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s20),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTokens.surface2(context),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppTokens.border(context)),
        ),
        child: TabBar(
          controller: controller,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          labelPadding: EdgeInsets.zero,
          indicator: BoxDecoration(
            color: AppTokens.accent(context),
            borderRadius: BorderRadius.circular(999),
            boxShadow: AppTokens.shadow1(context),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: AppTokens.ink2(context),
          labelStyle: AppTokens.caption(context).copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          unselectedLabelStyle: AppTokens.caption(context).copyWith(
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            for (final label in labels)
              Tab(
                child: Container(
                  alignment: Alignment.center,
                  child: Text(label),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    required this.isMaster,
    required this.isLoading,
    required this.isConnected,
    required this.categories,
  });

  final bool isMaster;
  final bool isLoading;
  final bool isConnected;
  final List<BookMarkCategoryModel?> categories;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        if (isLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: AppTokens.accent(context),
            ),
          );
        }
        if (categories.isEmpty) {
          return const _EmptyState();
        }
        if (!isConnected) {
          return const NoInternetScreen();
        }
        return ListView.separated(
          itemCount: categories.length,
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s20,
            AppTokens.s4,
            AppTokens.s20,
            AppTokens.s20,
          ),
          physics: const BouncingScrollPhysics(),
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppTokens.s12),
          itemBuilder: (context, index) {
            final BookMarkCategoryModel? cat = categories[index];
            return _CategoryCard(
              categoryName: cat?.category_name ?? '',
              questionCount: cat?.questionCount?.toString() ?? '0',
              onTap: () {
                if (isMaster) {
                  Navigator.of(context).pushNamed(
                    Routes.masterBookMarkExamList,
                    arguments: {
                      'categoryId': cat?.category_id,
                      'categoryName': cat?.category_name,
                      'type': 'topic',
                    },
                  );
                } else {
                  Navigator.of(context).pushNamed(
                    Routes.bookMarkSubcategoryList,
                    arguments: {
                      'categoryName': cat?.category_name,
                      'categoryId': cat?.category_id,
                    },
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.categoryName,
    required this.questionCount,
    required this.onTap,
  });

  final String categoryName;
  final String questionCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppTokens.radius16,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppTokens.s16),
          decoration: BoxDecoration(
            color: AppTokens.surface(context),
            borderRadius: AppTokens.radius16,
            border: Border.all(color: AppTokens.border(context)),
            boxShadow: AppTokens.shadow1(context),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 56,
                width: 56,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(AppTokens.s12),
                decoration: BoxDecoration(
                  color: AppTokens.accentSoft(context),
                  borderRadius: AppTokens.radius12,
                ),
                child: SvgPicture.asset(
                  'assets/image/bookmarkCate.svg',
                  color:
                      isDark ? AppColors.white : AppTokens.accent(context),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      categoryName.isEmpty ? 'Untitled' : categoryName,
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
              const SizedBox(width: AppTokens.s8),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTokens.muted(context),
                size: 20,
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
                Icons.bookmark_border_rounded,
                color: AppTokens.accent(context),
                size: 38,
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              'No bookmarks yet',
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
            const SizedBox(height: AppTokens.s20),
            Container(
              padding: const EdgeInsets.all(AppTokens.s16),
              decoration: BoxDecoration(
                color: AppTokens.surface2(context),
                borderRadius: AppTokens.radius16,
                border: Border.all(color: AppTokens.border(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To add a bookmark, follow these steps',
                    style: AppTokens.titleSm(context),
                  ),
                  const SizedBox(height: AppTokens.s12),
                  _Step(index: 1, text: 'First you have to give an exam'),
                  _Step(
                    index: 2,
                    text: 'Go to the Analysis & Solution section',
                  ),
                  _Step(index: 3, text: 'View solutions'),
                  _Step(
                    index: 4,
                    text: 'Make a bookmark on any question',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 22,
            width: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTokens.accentSoft(context),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: AppTokens.caption(context).copyWith(
                color: AppTokens.accent(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Text(text, style: AppTokens.body(context)),
          ),
        ],
      ),
    );
  }
}

class _SolveCta extends StatelessWidget {
  const _SolveCta({
    required this.isLoading,
    required this.onTap,
  });

  final bool isLoading;
  final VoidCallback onTap;

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
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [AppTokens.brand, AppTokens.brand2],
                  ),
                  borderRadius: AppTokens.radius12,
                  boxShadow: AppTokens.shadow1(context),
                ),
                child: InkWell(
                  borderRadius: AppTokens.radius12,
                  onTap: isLoading ? null : onTap,
                  child: Center(
                    child: isLoading
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
                              const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                              const SizedBox(width: AppTokens.s8),
                              Text(
                                'Solve Bookmarked Questions',
                                style: AppTokens.titleSm(context).copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
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
