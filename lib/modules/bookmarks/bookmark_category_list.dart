import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/modules/bookmarks/store/bookmark_store.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../models/bookmark_category_model.dart';
import '../subscriptionplans/store/subscription_store.dart';
import '../widgets/no_internet_connection.dart';

/// BookMarkCategoryScreen — entry point for the category-keyed
/// bookmarks flow. Loads categories from [BookMarkStore] and taps
/// into [Routes.bookMarkSubcategoryList] with the selected category
/// name + id.
///
/// Public surface preserved exactly:
///   • class [BookMarkCategoryScreen] (name intentionally ends in
///     "Screen" — the filename `bookmark_category_list.dart` is the
///     legacy name)
///   • nullable [fromHome] field + `BookMarkCategoryScreen({super.key,
///     this.fromHome})` constructor
///   • static [route] factory returns [CupertinoPageRoute] and reads
///     `arguments['fromhome']`
///   • initState still calls `_getSubscribedPlan()` +
///     `store.onBookMarkCategoryApiCall(context)` and wires the
///     [FocusNode]
///   • [WillPopScope] behaviour kept: back swallows the default pop
///     and pushes [Routes.dashboard] instead (matches original)
///   • Observer wiring over [BookMarkStore.bookmarkCategory],
///     [BookMarkStore.isLoading], [BookMarkStore.isConnected]
///   • search filter on `category_name.toLowerCase().contains(query)`
///   • navigation unchanged: [Routes.bookMarkSubcategoryList] with
///     `{ "categoryName": ..., "categoryId": ... }`
class BookMarkCategoryScreen extends StatefulWidget {
  final bool? fromHome;
  const BookMarkCategoryScreen({super.key, this.fromHome});

  @override
  State<BookMarkCategoryScreen> createState() => _BookMarkCategoryScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => BookMarkCategoryScreen(fromHome: arguments['fromhome']),
    );
  }
}

class _BookMarkCategoryScreenState extends State<BookMarkCategoryScreen> {
  // Preserved public state. `filterValue` is never wired to UI in the
  // legacy implementation but kept to avoid drifting the contract.
  // ignore: unused_field
  String filterValue = '';
  final FocusNode _focusNode = FocusNode();
  String query = '';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    _getSubscribedPlan();
    final store = Provider.of<BookMarkStore>(context, listen: false);
    store.onBookMarkCategoryApiCall(context);
  }

  Future<void> _getSubscribedPlan() async {
    final store = Provider.of<SubscriptionStore>(context, listen: false);
    await store.onGetSubscribedUserPlan();
    if (store.subscribedPlan.isEmpty) {
      // Preserved as commented-out — legacy behaviour pushed the
      // subscription list when no plan was attached. Leaving the
      // condition intact so any future re-enablement lands in one
      // line.
      // Navigator.of(context).pushNamed(Routes.subscriptionList);
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
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
        body: Column(
          children: [
            _Header(
              onBack: () => Navigator.of(context).pushNamed(Routes.dashboard),
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.s20,
                    AppTokens.s24,
                    AppTokens.s20,
                    AppTokens.s12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (query.isNotEmpty) ...[
                        Text(
                          'Results for "$query"',
                          style: AppTokens.caption(context).copyWith(
                            color: AppTokens.ink2(context),
                          ),
                        ),
                        const SizedBox(height: AppTokens.s8),
                      ],
                      TextField(
                        focusNode: _focusNode,
                        onChanged: (value) => setState(() => query = value),
                        style: AppTokens.body(context).copyWith(
                          color: AppTokens.ink(context),
                        ),
                        cursorColor: AppTokens.accent(context),
                        decoration: AppTokens.inputDecoration(
                          context,
                          hint: 'Search categories',
                          suffix: Icon(
                            CupertinoIcons.search,
                            color: AppTokens.muted(context),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTokens.s16),
                      Expanded(
                        child: Observer(
                          builder: (_) {
                            if (store.isLoading) {
                              return Center(
                                child: CircularProgressIndicator(
                                  color: AppTokens.accent(context),
                                  strokeWidth: 2.5,
                                ),
                              );
                            }
                            if (!store.isConnected) {
                              return const NoInternetScreen();
                            }
                            if (store.bookmarkCategory.isEmpty) {
                              return const _EmptyState();
                            }

                            final filtered =
                                <BookMarkCategoryModel?>[];
                            for (final cat in store.bookmarkCategory) {
                              final name =
                                  cat?.category_name?.toLowerCase() ?? '';
                              if (query.isEmpty ||
                                  name.contains(query.toLowerCase())) {
                                filtered.add(cat);
                              }
                            }

                            if (filtered.isEmpty) {
                              return _NoResults(query: query);
                            }

                            return ListView.separated(
                              itemCount: filtered.length,
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              physics: const BouncingScrollPhysics(),
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: AppTokens.s12),
                              itemBuilder: (context, index) {
                                final cat = filtered[index];
                                return _CategoryCard(
                                  name: cat?.category_name ?? '',
                                  questionCount: cat?.questionCount,
                                  onTap: () {
                                    Navigator.of(context).pushNamed(
                                      Routes.bookMarkSubcategoryList,
                                      arguments: {
                                        'categoryName': cat?.category_name,
                                        'categoryId': cat?.category_id,
                                      },
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
                      'Bookmarks',
                      style: AppTokens.titleLg(context).copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Browse saved questions by category',
                      style: AppTokens.body(context).copyWith(
                        color: Colors.white.withOpacity(0.85),
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
                  Icons.category_rounded,
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

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.name,
    required this.questionCount,
    required this.onTap,
  });

  final String name;
  final int? questionCount;
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
            children: [
              Container(
                height: 48,
                width: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTokens.accentSoft(context),
                  borderRadius: AppTokens.radius12,
                ),
                child: SvgPicture.asset(
                  'assets/image/bookmarkCate.svg',
                  width: 22,
                  height: 22,
                  color: isDark ? AppColors.white : AppTokens.accent(context),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name.isNotEmpty ? name : 'Untitled category',
                      style: AppTokens.titleSm(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (questionCount != null && questionCount! > 0) ...[
                      const SizedBox(height: AppTokens.s4),
                      Row(
                        children: [
                          Icon(
                            Icons.bookmark_rounded,
                            size: 12,
                            color: AppTokens.accent(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$questionCount bookmarked',
                            style: AppTokens.caption(context).copyWith(
                              color: AppTokens.accent(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: AppTokens.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 96,
            width: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTokens.accentSoft(context),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bookmark_border_rounded,
              color: AppTokens.accent(context),
              size: 44,
            ),
          ),
          const SizedBox(height: AppTokens.s20),
          Text(
            'No bookmarks yet',
            style: AppTokens.titleLg(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTokens.s8),
          Text(
            "Sorry — there's nothing saved here yet. Bookmark a "
            'question from the analysis & solution section and it '
            'will show up here.',
            style: AppTokens.body(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTokens.s24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTokens.s16),
            decoration: BoxDecoration(
              color: AppTokens.surface(context),
              borderRadius: AppTokens.radius16,
              border: Border.all(color: AppTokens.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How to add bookmarks',
                  style: AppTokens.titleSm(context),
                ),
                const SizedBox(height: AppTokens.s12),
                const _Step(index: 1, text: 'Attempt an exam'),
                const _Step(
                  index: 2,
                  text: 'Open the Analysis & Solution section',
                ),
                const _Step(index: 3, text: 'View solutions'),
                const _Step(
                  index: 4,
                  text: 'Tap the bookmark icon on any question',
                ),
              ],
            ),
          ),
        ],
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 22,
            width: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTokens.accent(context),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: AppTokens.caption(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Text(
              text,
              style: AppTokens.body(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              color: AppTokens.muted(context),
              size: 44,
            ),
            const SizedBox(height: AppTokens.s12),
            Text(
              'No categories match "$query"',
              style: AppTokens.titleSm(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.s4),
            Text(
              'Try a different keyword or clear the search.',
              style: AppTokens.body(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
