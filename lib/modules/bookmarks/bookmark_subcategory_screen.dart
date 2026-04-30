import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/modules/bookmarks/store/bookmark_store.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../models/bookmark_subcategory_model.dart';
import '../widgets/no_internet_connection.dart';

/// BookMarkSubcategoryScreen — lists the subcategories carrying
/// bookmarked questions under a given [categoryName] / [categoryId].
/// Tapping a row continues to [Routes.bookMarkTopicList] with the
/// selected subcategory name + id.
///
/// Public surface preserved exactly:
///   • class [BookMarkSubcategoryScreen]
///   • required [categoryName] + nullable [categoryId] fields
///   • `BookMarkSubcategoryScreen({Key? key, required this.categoryName,
///     this.categoryId})` constructor unchanged
///   • static [route] factory returns [CupertinoPageRoute] and reads
///     'categoryName' + 'categoryId' from the arguments map
///   • initState still calls
///     `store.onBookMarkSubCategoryApiCall(widget.categoryId ?? "")`
///   • Observer wiring over [BookMarkStore.bookmarkSubCategory],
///     [BookMarkStore.isLoading], [BookMarkStore.isConnected]
///   • [query] state is kept (matches the legacy public API — the
///     filter text field was previously commented out but the
///     filter rule is reactivated in the upgrade)
///   • Navigation unchanged: [Routes.bookMarkTopicList] with
///     `{ "subCateName": ..., "subcatId": ... }`
class BookMarkSubcategoryScreen extends StatefulWidget {
  final String categoryName;
  final String? categoryId;
  const BookMarkSubcategoryScreen({
    Key? key,
    required this.categoryName,
    this.categoryId,
  }) : super(key: key);

  @override
  State<BookMarkSubcategoryScreen> createState() =>
      _BookMarkSubcategoryScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => BookMarkSubcategoryScreen(
        categoryName: arguments['categoryName'],
        categoryId: arguments['categoryId'],
      ),
    );
  }
}

class _BookMarkSubcategoryScreenState extends State<BookMarkSubcategoryScreen> {
  String query = '';

  @override
  void initState() {
    super.initState();
    final store = Provider.of<BookMarkStore>(context, listen: false);
    store.onBookMarkSubCategoryApiCall(widget.categoryId ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<BookMarkStore>(context, listen: false);
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          _Header(
            categoryName: widget.categoryName,
            onBack: () => Navigator.pop(context),
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
                    TextField(
                      onChanged: (value) => setState(() => query = value),
                      style: AppTokens.body(context).copyWith(
                        color: AppTokens.ink(context),
                      ),
                      cursorColor: AppTokens.accent(context),
                      decoration: AppTokens.inputDecoration(
                        context,
                        hint: 'Search subcategories',
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
                          if (store.bookmarkSubCategory.isEmpty) {
                            return const _EmptyState();
                          }

                          final filtered = <BookMarkSubCategoryModel?>[];
                          for (final sub in store.bookmarkSubCategory) {
                            final name =
                                sub?.subcategory_name?.toLowerCase() ?? '';
                            if (query.isEmpty ||
                                name.contains(query.toLowerCase())) {
                              filtered.add(sub);
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
                              final sub = filtered[index];
                              return _SubcategoryCard(
                                name: sub?.subcategory_name ?? '',
                                questionCount: sub?.questionCount,
                                onTap: () {
                                  Navigator.of(context).pushNamed(
                                    Routes.bookMarkTopicList,
                                    arguments: {
                                      'subCateName': sub?.subcategory_name,
                                      'subcatId': sub?.subcategory_id,
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
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Private widgets
// ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.categoryName, required this.onBack});

  final String categoryName;
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
                      'CATEGORY',
                      style: AppTokens.overline(context).copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      categoryName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTokens.titleLg(context).copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubcategoryCard extends StatelessWidget {
  const _SubcategoryCard({
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
                  'assets/image/bookmarksubCate.svg',
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
                      name.isNotEmpty ? name : 'Untitled subcategory',
                      style: AppTokens.titleSm(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTokens.s4),
                    Row(
                      children: [
                        Icon(
                          Icons.bookmark_rounded,
                          size: 14,
                          color: AppTokens.accent(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${questionCount ?? 0} Questions',
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
                Icons.layers_outlined,
                color: AppTokens.accent(context),
                size: 38,
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              'Nothing in this category yet',
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
              'No subcategories match "$query"',
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
