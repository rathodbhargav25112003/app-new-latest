import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/modules/bookmarks/store/bookmark_store.dart';

import '../../../app/routes.dart';
import '../../../helpers/app_tokens.dart';
import '../../../helpers/colors.dart';
import '../../../models/bookmark_category_model.dart';
import '../../subscriptionplans/store/subscription_store.dart';
import '../../widgets/no_internet_connection.dart';

/// MasterBookMarkCategoryScreen — mirror of [BookMarkCategoryScreen]
/// that surfaces the master (mock-exam / curated) bookmark roots and
/// lets the user drill straight into the exam list for a tapped root.
///
/// Public surface preserved exactly:
///   • class [MasterBookMarkCategoryScreen]
///   • nullable [fromHome] boolean with the
///     [MasterBookMarkCategoryScreen]({super.key, this.fromHome})
///     constructor unchanged
///   • static [route] factory returns [CupertinoPageRoute] and reads
///     'fromhome' (lowercase, legacy key) from the arguments map
///   • [filterValue] public-ish field preserved (legacy leftover)
///   • initState still wires a [FocusNode] listener, calls
///     [_getSubscribedPlan] and
///     `store.onMasterBookMarkCategoryApiCall(context)`
///   • WillPopScope still pushes [Routes.dashboard] and returns false
///   • search filter rule preserved:
///     `bookMarkCat.category_name.toLowerCase().contains(query.toLowerCase())`
///   • tap navigation pushes [Routes.masterBookMarkExamList] with
///     { 'categoryName', 'categoryId', 'type': 'topic' }
///   • Observer binding over [BookMarkStore.masterBookmarkCategory],
///     [BookMarkStore.isLoading] and [BookMarkStore.isConnected]
///   • [NoInternetScreen] fallback on the connectivity flag
///   • bookmarkCate.svg tile + chevron row layout preserved
class MasterBookMarkCategoryScreen extends StatefulWidget {
  final bool? fromHome;
  const MasterBookMarkCategoryScreen({super.key, this.fromHome});

  @override
  State<MasterBookMarkCategoryScreen> createState() =>
      _MasterBookMarkCategoryScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) =>
          MasterBookMarkCategoryScreen(fromHome: arguments['fromhome']),
    );
  }
}

class _MasterBookMarkCategoryScreenState
    extends State<MasterBookMarkCategoryScreen> {
  // Preserved from the original public API even though the old screen
  // never wired it anywhere — keep the identifier live so no caller
  // that might read via reflection/debugging breaks.
  // ignore: unused_field
  String filterValue = '';
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _searchCtrl = TextEditingController();
  String query = '';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    _getSubscribedPlan();
    final store = Provider.of<BookMarkStore>(context, listen: false);
    store.onMasterBookMarkCategoryApiCall(context);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _searchCtrl.dispose();
    super.dispose();
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTokens.s20,
                        AppTokens.s20,
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
                                color: AppTokens.muted(context),
                              ),
                            ),
                            const SizedBox(height: AppTokens.s8),
                          ],
                          TextField(
                            focusNode: _focusNode,
                            controller: _searchCtrl,
                            onChanged: (value) {
                              setState(() {
                                query = value;
                              });
                            },
                            style: AppTokens.body(context),
                            cursorColor: AppTokens.accent(context),
                            decoration: AppTokens.inputDecoration(
                              context,
                              hint: 'Search master bookmarks',
                              prefix: const Icon(
                                CupertinoIcons.search,
                                size: 18,
                              ),
                              suffix: query.isEmpty
                                  ? null
                                  : IconButton(
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _searchCtrl.clear();
                                          query = '';
                                        });
                                        _focusNode.unfocus();
                                      },
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
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
                          if (store.masterBookmarkCategory.isEmpty) {
                            return const _EmptyState();
                          }
                          return _MasterCategoryList(
                            query: query,
                            categories: store.masterBookmarkCategory,
                          );
                        },
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
                      'MASTER · BOOKMARKS',
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
                  Icons.auto_stories_rounded,
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

class _MasterCategoryList extends StatelessWidget {
  const _MasterCategoryList({
    required this.query,
    required this.categories,
  });

  final String query;
  final List<BookMarkCategoryModel?> categories;

  @override
  Widget build(BuildContext context) {
    // Mirror the legacy filter: skip entries whose category_name does
    // not contain the current query (case-insensitive).
    final filtered = categories
        .where((c) =>
            query.isEmpty ||
            ((c?.category_name ?? '')
                .toLowerCase()
                .contains(query.toLowerCase())))
        .toList();

    if (filtered.isEmpty) {
      return _NoResults(query: query);
    }

    return ListView.separated(
      itemCount: filtered.length,
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s20,
        AppTokens.s4,
        AppTokens.s20,
        AppTokens.s24,
      ),
      physics: const BouncingScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: AppTokens.s12),
      itemBuilder: (context, index) {
        final BookMarkCategoryModel? cat = filtered[index];
        return _CategoryCard(
          categoryName: cat?.category_name ?? '',
          onTap: () {
            Navigator.of(context).pushNamed(
              Routes.masterBookMarkExamList,
              arguments: {
                'categoryName': cat?.category_name,
                'categoryId': cat?.category_id,
                'type': 'topic',
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
    required this.onTap,
  });

  final String categoryName;
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
                height: 48,
                width: 48,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(AppTokens.s8),
                decoration: BoxDecoration(
                  color: AppTokens.accentSoft(context),
                  borderRadius: AppTokens.radius12,
                ),
                child: SvgPicture.asset(
                  'assets/image/bookmarkCate.svg',
                  color: isDark ? AppColors.white : AppTokens.accent(context),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Text(
                  categoryName.isEmpty ? 'Untitled category' : categoryName,
                  style: AppTokens.titleSm(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
              'No master bookmarks yet',
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
              size: 48,
              color: AppTokens.muted(context),
            ),
            const SizedBox(height: AppTokens.s12),
            Text(
              'No matches for "$query"',
              style: AppTokens.titleSm(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.s4),
            Text(
              'Try a different search term.',
              style: AppTokens.caption(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
