import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/modules/bookmarks/store/bookmark_store.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../models/bookmark_mainlist_model.dart';
import '../widgets/no_internet_connection.dart';

/// BookMarkMainListScreen — flat list of everything the user has
/// bookmarked across categories/subcategories/topics. Tapping a row
/// navigates to [Routes.bookMarkExamList] with `{id, type, title}`.
///
/// The public surface is preserved exactly:
///   • class name [BookMarkMainListScreen]
///   • nullable [fromHome] field + constructor signature
///   • the static [route] factory that reads `arguments['fromhome']`
///   • Observer wiring over [BookMarkStore.bookmarkListAll],
///     [BookMarkStore.isLoading] and [BookMarkStore.isConnected]
///   • initState → `store.onBookMarkListAllApiCall(context)`
class BookMarkMainListScreen extends StatefulWidget {
  final bool? fromHome;
  const BookMarkMainListScreen({Key? key, this.fromHome}) : super(key: key);

  @override
  State<BookMarkMainListScreen> createState() => _BookMarkMainListScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => BookMarkMainListScreen(fromHome: arguments['fromhome']),
    );
  }
}

class _BookMarkMainListScreenState extends State<BookMarkMainListScreen> {
  String query = '';

  @override
  void initState() {
    super.initState();
    final store = Provider.of<BookMarkStore>(context, listen: false);
    store.onBookMarkListAllApiCall(context);
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<BookMarkStore>(context, listen: false);
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          _Header(
            showBack: widget.fromHome == true,
            onBack: () => Navigator.of(context).pushNamed(Routes.dashboard),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.s20,
              AppTokens.s16,
              AppTokens.s20,
              AppTokens.s8,
            ),
            child: TextField(
              cursorColor: AppTokens.accent(context),
              onChanged: (value) => setState(() => query = value),
              style: AppTokens.body(context).copyWith(
                color: AppTokens.ink(context),
              ),
              decoration: AppTokens.inputDecoration(
                context,
                hint: 'Search your bookmarks',
                prefix: Icon(
                  Icons.search_rounded,
                  color: AppTokens.muted(context),
                  size: 20,
                ),
              ),
            ),
          ),
          Expanded(
            child: Observer(
              builder: (_) {
                if (!store.isConnected) {
                  return const NoInternetScreen();
                }
                if (store.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppTokens.accent(context),
                      strokeWidth: 2.5,
                    ),
                  );
                }
                if (store.bookmarkListAll.isEmpty) {
                  return const _EmptyState();
                }

                // Apply search filter — mirrors the original
                // `displayText.toLowerCase().contains(query.toLowerCase())`
                // test, but we precompute to also suppress empty rows.
                final filtered = <_BookmarkRowData>[];
                for (final item in store.bookmarkListAll) {
                  final data = _BookmarkRowData.from(item);
                  if (query.isEmpty ||
                      data.displayText
                          .toLowerCase()
                          .contains(query.toLowerCase())) {
                    filtered.add(data);
                  }
                }

                if (filtered.isEmpty) {
                  return _NoResults(query: query);
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.s20,
                    AppTokens.s12,
                    AppTokens.s20,
                    AppTokens.s24,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppTokens.s12),
                  itemBuilder: (context, index) {
                    final row = filtered[index];
                    return _BookmarkRow(
                      data: row,
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          Routes.bookMarkExamList,
                          arguments: {
                            'id': row.navId,
                            'type': row.navType,
                            'title': row.navTitle,
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
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Row data — computed once per Observer tick
// ────────────────────────────────────────────────────────────────────

class _BookmarkRowData {
  _BookmarkRowData({
    required this.categoryName,
    required this.subcategoryName,
    required this.topicName,
    required this.displayText,
    required this.formattedDate,
    required this.navId,
    required this.navType,
    required this.navTitle,
  });

  final String categoryName;
  final String subcategoryName;
  final String topicName;
  final String displayText;
  final String formattedDate;
  final String navId;
  final String navType;
  final String navTitle;

  factory _BookmarkRowData.from(BookMarkMainListModel? b) {
    final categoryName = b?.categoryName ?? '';
    final subcategoryName = b?.subcategoryName ?? '';
    final topicName = b?.topicName ?? '';

    // Matches the original displayText rules
    String displayText = categoryName;
    if (subcategoryName.isNotEmpty && topicName.isNotEmpty) {
      displayText += ' | $subcategoryName | $topicName';
    } else if (subcategoryName.isNotEmpty) {
      displayText += ' | $subcategoryName';
    } else if (topicName.isNotEmpty) {
      displayText += ' | $topicName';
    }

    // Date formatting — 'dd/MMMM/yyyy' as before. Guard against
    // malformed createdAt so the screen never crashes.
    String formattedDate = '';
    try {
      final originalDate = b?.createdAt ?? '';
      if (originalDate.isNotEmpty) {
        final parsed = DateTime.parse(originalDate);
        formattedDate = DateFormat('dd/MMMM/yyyy').format(parsed);
      }
    } catch (_) {
      formattedDate = b?.createdAt ?? '';
    }

    // Navigation args — identical hierarchy to the original
    final navId = b?.topicId != null
        ? (b?.topicId ?? '')
        : b?.subcategoryId != null
            ? (b?.subcategoryId ?? '')
            : (b?.categoryId ?? '');

    final navType = b?.topicId != null
        ? 'topic'
        : b?.subcategoryId != null
            ? 'subcategory'
            : 'category';

    final navTitle = b?.topicId != null
        ? (b?.topicName ?? '')
        : b?.subcategoryId != null
            ? (b?.subcategoryName ?? '')
            : (b?.categoryName ?? '');

    return _BookmarkRowData(
      categoryName: categoryName,
      subcategoryName: subcategoryName,
      topicName: topicName,
      displayText: displayText,
      formattedDate: formattedDate,
      navId: navId,
      navType: navType,
      navTitle: navTitle,
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Private widgets
// ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.showBack, required this.onBack});

  final bool showBack;
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
            AppTokens.s20,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showBack)
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
                )
              else
                const SizedBox(width: AppTokens.s8),
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
                    const SizedBox(height: AppTokens.s4),
                    Text(
                      'Saved questions, grouped by subject',
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

class _BookmarkRow extends StatelessWidget {
  const _BookmarkRow({required this.data, required this.onTap});

  final _BookmarkRowData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                height: 44,
                width: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTokens.accentSoft(context),
                  borderRadius: AppTokens.radius12,
                ),
                child: Icon(
                  Icons.bookmark_rounded,
                  color: AppTokens.accent(context),
                  size: 22,
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data.categoryName.isNotEmpty
                          ? data.categoryName
                          : 'Untitled',
                      style: AppTokens.titleSm(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (data.subcategoryName.isNotEmpty ||
                        data.topicName.isNotEmpty) ...[
                      const SizedBox(height: AppTokens.s4),
                      Wrap(
                        spacing: AppTokens.s4,
                        runSpacing: AppTokens.s4,
                        children: [
                          if (data.subcategoryName.isNotEmpty)
                            _Chip(label: data.subcategoryName),
                          if (data.topicName.isNotEmpty)
                            _Chip(
                              label: data.topicName,
                              accent: true,
                            ),
                        ],
                      ),
                    ],
                    if (data.formattedDate.isNotEmpty) ...[
                      const SizedBox(height: AppTokens.s8),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: AppTokens.muted(context),
                          ),
                          const SizedBox(width: AppTokens.s4),
                          Text(
                            data.formattedDate,
                            style: AppTokens.caption(context),
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

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.accent = false});

  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: accent
            ? AppTokens.accentSoft(context)
            : AppTokens.surface2(context),
        borderRadius: AppTokens.radius8,
        border: Border.all(
          color: accent
              ? AppTokens.accent(context).withOpacity(0.25)
              : AppTokens.border(context),
        ),
      ),
      child: Text(
        label,
        style: AppTokens.caption(context).copyWith(
          color: accent
              ? AppTokens.accent(context)
              : AppTokens.ink2(context),
          fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s24,
        AppTokens.s24,
        AppTokens.s24,
        AppTokens.s32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: AppTokens.s32),
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
            'Sorry — there\'s nothing saved here yet. Bookmark a '
            'question while you\'re reviewing a report and it will '
            'show up here.',
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
                const _Step(index: 2, text: 'Open the Report section'),
                const _Step(index: 3, text: 'View the solution report'),
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
              'No matches for "$query"',
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
