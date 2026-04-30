import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../helpers/app_skeleton.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/empty_state.dart';
import '../../helpers/haptics.dart';
import '../../helpers/refresh_helper.dart';
import '../../helpers/value_formatters.dart';
import '../../services/recent_notes_service.dart';
import '../dashboard/store/home_store.dart';
import '../dashboard/models/global_search_model.dart';
import '../widgets/no_internet_connection.dart';
import 'store/notes_category_store.dart';

/// NotesBrowseScreen — single-tap-to-reader entry point.
///
/// Replaces the legacy 4-deep flow
/// (category → subcategory → topic → content → reader)
/// with three quick paths:
///
///   1. **Search** at the top — type "endocrine", see all matching
///      notes at any depth, tap → reader. Uses the existing
///      [HomeStore.onGlobalSearchApiCall] endpoint scoped to "pdf".
///
///   2. **Continue reading** rail — last 5 notes the user opened,
///      pulled from [RecentNotesService] (instant, offline-first).
///
///   3. **Browse all subjects** — collapsed list of categories that
///      keeps the legacy 4-level flow as a fallback for users who
///      want to drill in from scratch.
///
/// On every cold-boot the recents render synchronously from
/// SharedPreferences while the network call for the catalog runs
/// in parallel.
class NotesBrowseScreen extends StatefulWidget {
  const NotesBrowseScreen({super.key});

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(builder: (_) => const NotesBrowseScreen());
  }

  @override
  State<NotesBrowseScreen> createState() => _NotesBrowseScreenState();
}

class _NotesBrowseScreenState extends State<NotesBrowseScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _query = '';
  bool _searching = false;
  List<RecentNoteEntry> _recents = const [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final store = Provider.of<NotesCategoryStore>(context, listen: false);
    // Fire catalog fetch in parallel with recents.
    // ignore: discarded_futures
    store.onRegisterApiCall(context);
    final recents = await RecentNotesService.instance.top(8);
    if (!mounted) return;
    setState(() => _recents = recents);
  }

  Future<void> _refresh() async {
    final store = Provider.of<NotesCategoryStore>(context, listen: false);
    await store.onRegisterApiCall(context);
    final recents = await RecentNotesService.instance.top(8);
    if (!mounted) return;
    setState(() => _recents = recents);
  }

  Future<void> _runSearch(String value) async {
    setState(() {
      _query = value;
      _searching = value.length >= 3;
    });
    if (_searching) {
      Haptics.light();
      final home = Provider.of<HomeStore>(context, listen: false);
      await home.onGlobalSearchApiCall(value, "pdf");
    }
  }

  void _openSearchHit(GlobalSearchDataModel hit) {
    Haptics.selection();
    final type = hit.type ?? '';
    if (type == 'pdfCategory') {
      Navigator.of(context).pushNamed(
        Routes.notesSubjectDetail,
        arguments: {"subject": hit.categoryName, "noteid": hit.id},
      );
    } else if (type == 'pdfSubCategory') {
      Navigator.of(context).pushNamed(
        Routes.notesTopicCategory,
        arguments: {
          "topicname": hit.subcategoryName,
          "topic": hit.subcategoryName,
          "subcatId": hit.id,
        },
      );
    } else if (type == 'pdfTopic') {
      Navigator.of(context).pushNamed(
        Routes.notesChapterDetail,
        arguments: {
          "topicname": hit.topicName,
          "chapter": hit.topicName,
          "subcatId": hit.id,
          "subcaptername": hit.subName,
        },
      );
    } else if (type == 'content' && (hit.contentType == 'PDF')) {
      // The shortcut path — straight to the reader.
      Navigator.of(context).pushNamed(
        Routes.notesReadView,
        arguments: {
          'topic_name': hit.topicName ?? '',
          'category_name': hit.categoryName ?? '',
          'subcategory_name': hit.subcategoryName ?? '',
          'categoryId': hit.categoryId,
          'subcategoryId': hit.subcategoryId,
          'contentUrl': hit.contentUrl,
          'title': hit.title ?? '',
          'titleId': hit.id,
          'isDownloaded': false,
          'isCompleted': false,
          'topicId': hit.topicId,
        },
      );
    }
  }

  void _openRecent(RecentNoteEntry r) {
    Haptics.selection();
    Navigator.of(context).pushNamed(
      Routes.notesReadView,
      arguments: {
        'topic_name': r.topicName ?? '',
        'category_name': r.categoryName ?? '',
        'subcategory_name': r.subcategoryName ?? '',
        'categoryId': r.categoryId,
        'subcategoryId': r.subcategoryId,
        'contentUrl': r.contentUrl,
        'title': r.title,
        'titleId': r.titleId,
        'isDownloaded': false,
        'isCompleted': r.isCompleted,
        'topicId': r.topicId,
        'initialPage': r.lastPage,
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesStore = Provider.of<NotesCategoryStore>(context);
    final homeStore = Provider.of<HomeStore>(context);
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppTokens.scaffold(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTokens.ink(context), size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text("Notes", style: AppTokens.titleLg(context)),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Offline notes',
            icon: Icon(Icons.cloud_download_outlined,
                color: AppTokens.ink(context), size: 22),
            onPressed: () {
              Haptics.selection();
              Navigator.of(context).pushNamed(Routes.downloadedNotesCategory);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _searchField(),
            Expanded(
              child: _searching
                  ? _buildSearchResults(homeStore)
                  : _buildBrowseBody(notesStore),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Search field ────────────────────────────────────────────────

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTokens.s24, AppTokens.s8, AppTokens.s24, AppTokens.s8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppTokens.surface(context),
          borderRadius: AppTokens.radius12,
          border: Border.all(color: AppTokens.border(context), width: 0.5),
        ),
        child: Row(
          children: [
            const SizedBox(width: AppTokens.s12),
            Icon(Icons.search_rounded,
                size: 20, color: AppTokens.muted(context)),
            const SizedBox(width: AppTokens.s8),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                cursorColor: AppTokens.accent(context),
                style: AppTokens.body(context).copyWith(
                  color: AppTokens.ink(context),
                ),
                textInputAction: TextInputAction.search,
                onChanged: _runSearch,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'Search notes by topic or chapter…',
                  hintStyle: AppTokens.body(context).copyWith(
                    color: AppTokens.muted(context),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            if (_query.isNotEmpty)
              IconButton(
                icon: Icon(Icons.cancel_rounded,
                    size: 18, color: AppTokens.muted(context)),
                onPressed: () {
                  setState(() {
                    _query = '';
                    _searching = false;
                    _searchController.clear();
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  // ─── Search results body ─────────────────────────────────────────

  Widget _buildSearchResults(HomeStore home) {
    return Observer(
      builder: (_) {
        if (home.isLoading) {
          return const SkeletonList(count: 6, itemHeight: 76);
        }
        if (home.globalSearchList.isEmpty) {
          return EmptyState(
            icon: Icons.search_off_rounded,
            title: 'No matches',
            subtitle: 'Try a different keyword or browse subjects below.',
            action: TextButton(
              onPressed: () {
                setState(() {
                  _query = '';
                  _searching = false;
                  _searchController.clear();
                });
              },
              child: Text(
                'Browse subjects',
                style: AppTokens.titleSm(context).copyWith(
                  color: AppTokens.accent(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
              AppTokens.s24, 0, AppTokens.s24, AppTokens.s24),
          physics: const BouncingScrollPhysics(),
          itemCount: home.globalSearchList.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppTokens.s8),
          itemBuilder: (_, i) {
            final hit = home.globalSearchList[i];
            if (hit == null) return const SizedBox.shrink();
            return _searchHitTile(hit);
          },
        );
      },
    );
  }

  Widget _searchHitTile(GlobalSearchDataModel hit) {
    final type = hit.type ?? '';
    final isContent = type == 'content';
    final title = hit.title ??
        hit.topicName ??
        hit.subcategoryName ??
        hit.categoryName ??
        'Note';
    final subtitle = [
      if (hit.categoryName != null) hit.categoryName!,
      if (hit.subcategoryName != null) hit.subcategoryName!,
      if (hit.topicName != null && hit.topicName != title) hit.topicName!,
    ].join(' · ');

    final levelLabel = type == 'pdfCategory'
        ? 'Subject'
        : type == 'pdfSubCategory'
            ? 'Chapter'
            : type == 'pdfTopic'
                ? 'Topic'
                : 'Note';
    final tint = isContent
        ? AppTokens.accent(context)
        : AppTokens.muted(context);

    return Material(
      color: AppTokens.surface(context),
      borderRadius: AppTokens.radius16,
      child: InkWell(
        borderRadius: AppTokens.radius16,
        onTap: () => _openSearchHit(hit),
        child: Container(
          padding: const EdgeInsets.all(AppTokens.s12),
          decoration: BoxDecoration(
            border:
                Border.all(color: AppTokens.border(context), width: 0.5),
            borderRadius: AppTokens.radius16,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tint.withOpacity(0.14),
                  borderRadius: AppTokens.radius12,
                ),
                child: Icon(
                  isContent
                      ? Icons.picture_as_pdf_rounded
                      : Icons.folder_outlined,
                  color: tint,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTokens.surface2(context),
                            borderRadius: AppTokens.radius8,
                          ),
                          child: Text(
                            levelLabel,
                            style: AppTokens.caption(context).copyWith(
                              color: AppTokens.muted(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isContent) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.bolt_rounded,
                              size: 12, color: AppTokens.accent(context)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTokens.titleSm(context),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTokens.caption(context),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppTokens.muted(context)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Browse body ─────────────────────────────────────────────────

  Widget _buildBrowseBody(NotesCategoryStore store) {
    return Observer(
      builder: (_) {
        if (!store.isConnected) return const NoInternetScreen();
        if (store.isLoading && store.notescategory.isEmpty) {
          return const SkeletonList(count: 5, itemHeight: 96);
        }
        return AppRefresh(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppTokens.s24, AppTokens.s8, AppTokens.s24, AppTokens.s24),
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            children: [
              if (_recents.isNotEmpty) ...[
                _sectionHeader('Continue reading',
                    onTap: _recents.length > 3
                        ? () => _showAllRecents()
                        : null),
                const SizedBox(height: AppTokens.s8),
                _recentsRail(),
                const SizedBox(height: AppTokens.s20),
              ],
              if (store.notescategory.isNotEmpty) ...[
                _sectionHeader('All subjects'),
                const SizedBox(height: AppTokens.s8),
                ...store.notescategory.map((cat) {
                  if (cat == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTokens.s8),
                    child: _ExpandableCategoryCard(
                      category: cat,
                      onOpenSubject: () {
                        Haptics.selection();
                        Navigator.of(context).pushNamed(
                          Routes.notesSubjectDetail,
                          arguments: {
                            "subject": cat.category_name,
                            "noteid": cat.sid,
                          },
                        );
                      },
                    ),
                  );
                }),
              ] else if (!store.isLoading) ...[
                const EmptyState(
                  icon: Icons.menu_book_outlined,
                  title: 'No notes yet',
                  subtitle:
                      'Your subscription doesn’t include notes for now. '
                      'Check the plans page for an upgrade.',
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTokens.titleMd(context)),
        if (onTap != null)
          GestureDetector(
            onTap: onTap,
            child: Text(
              'See all',
              style: AppTokens.titleSm(context).copyWith(
                color: AppTokens.accent(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _recentsRail() {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _recents.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTokens.s12),
        itemBuilder: (_, i) {
          final r = _recents[i];
          return _RecentCard(
            entry: r,
            onTap: () => _openRecent(r),
          );
        },
      ),
    );
  }

  void _showAllRecents() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: AppTokens.surface(context),
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTokens.r28)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppTokens.s16, AppTokens.s12, AppTokens.s16, AppTokens.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTokens.border(context),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: AppTokens.s16),
                Text('Recently read', style: AppTokens.titleLg(context)),
                const SizedBox(height: AppTokens.s12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _recents.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppTokens.s8),
                    itemBuilder: (_, i) {
                      final r = _recents[i];
                      return _RecentCard(
                        entry: r,
                        wide: true,
                        onTap: () {
                          Navigator.of(context).pop();
                          _openRecent(r);
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
    );
  }
}

// ─── Components ───────────────────────────────────────────────────

class _RecentCard extends StatelessWidget {
  const _RecentCard({
    required this.entry,
    required this.onTap,
    this.wide = false,
  });

  final RecentNoteEntry entry;
  final VoidCallback onTap;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final width = wide ? double.infinity : 220.0;
    return SizedBox(
      width: width,
      child: Material(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius16,
        child: InkWell(
          borderRadius: AppTokens.radius16,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppTokens.s12),
            decoration: BoxDecoration(
              borderRadius: AppTokens.radius16,
              border:
                  Border.all(color: AppTokens.border(context), width: 0.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTokens.accentSoft(context),
                    borderRadius: AppTokens.radius12,
                  ),
                  child: Icon(
                    entry.isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.menu_book_rounded,
                    color: AppTokens.accent(context),
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppTokens.s8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTokens.titleSm(context),
                      ),
                      const SizedBox(height: 4),
                      if ((entry.topicName ?? '').isNotEmpty ||
                          (entry.categoryName ?? '').isNotEmpty)
                        Text(
                          entry.topicName ?? entry.categoryName ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTokens.caption(context),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (entry.lastPage != null) ...[
                            Icon(Icons.bookmark_rounded,
                                size: 12,
                                color: AppTokens.muted(context)),
                            const SizedBox(width: 2),
                            Text(
                              'Page ${entry.lastPage}',
                              style: AppTokens.caption(context).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: AppTokens.s8),
                          ],
                          if (entry.lastSeenAt != null)
                            Flexible(
                              child: Text(
                                Fmt.relativeTime(entry.lastSeenAt!),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTokens.caption(context),
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
        ),
      ),
    );
  }
}

/// One subject card that expands inline when tapped.
///
/// Tap the chevron / header → expands to show the per-status breakdown
/// (completed / in progress / not started / bookmarked) and a single
/// "Open subject" CTA. The user can then drill in if they want, or
/// collapse back. This saves the "tap to navigate to a screen that
/// shows just the same numbers" round-trip — a tap and a half cheaper
/// than the legacy flow.
class _ExpandableCategoryCard extends StatefulWidget {
  const _ExpandableCategoryCard({
    required this.category,
    required this.onOpenSubject,
  });

  final dynamic category; // NotesCategoryModel? — kept dynamic to avoid model import here
  final VoidCallback onOpenSubject;

  @override
  State<_ExpandableCategoryCard> createState() =>
      _ExpandableCategoryCardState();
}

class _ExpandableCategoryCardState extends State<_ExpandableCategoryCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  String? get _name => widget.category?.category_name as String?;
  String? get _description => widget.category?.description as String?;
  int get _completed => (widget.category?.completedPdfCount as int?) ?? 0;
  int get _progress => (widget.category?.progressCount as int?) ?? 0;
  int get _notStarted => (widget.category?.notStart as int?) ?? 0;
  int get _bookmarked => (widget.category?.bookmarkPdfCount as int?) ?? 0;
  int get _totalNotes => (widget.category?.notes as int?) ?? 0;
  String? get _priorityLabel =>
      widget.category?.priorityLabel as String?;

  /// NotesCategoryModel.priorityColor is a hex string ("#FFAB00").
  /// Parse to a Color when present so the badge renders correctly.
  Color? get _priorityColorParsed {
    final raw = widget.category?.priorityColor as String?;
    if (raw == null || raw.isEmpty) return null;
    try {
      var hex = raw.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTokens.surface(context),
      borderRadius: AppTokens.radius16,
      child: InkWell(
        borderRadius: AppTokens.radius16,
        onTap: () {
          Haptics.selection();
          setState(() => _expanded = !_expanded);
        },
        child: Container(
          padding: const EdgeInsets.all(AppTokens.s16),
          decoration: BoxDecoration(
            borderRadius: AppTokens.radius16,
            border:
                Border.all(color: AppTokens.border(context), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTokens.accentSoft(context),
                      borderRadius: AppTokens.radius12,
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
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
                          _name ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTokens.titleSm(context),
                        ),
                        if (_totalNotes > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            '$_totalNotes notes',
                            style: AppTokens.caption(context),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 180),
                    turns: _expanded ? 0.5 : 0,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTokens.muted(context),
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: !_expanded
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: AppTokens.s12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((_description ?? '').isNotEmpty) ...[
                              Text(
                                _description!,
                                style: AppTokens.body(context),
                              ),
                              const SizedBox(height: AppTokens.s12),
                            ],
                            Wrap(
                              spacing: AppTokens.s8,
                              runSpacing: AppTokens.s8,
                              children: [
                                _statChip(
                                  'Completed',
                                  _completed,
                                  AppTokens.success(context),
                                ),
                                _statChip(
                                  'In progress',
                                  _progress,
                                  AppTokens.warning(context),
                                ),
                                _statChip(
                                  'Not started',
                                  _notStarted,
                                  AppTokens.muted(context),
                                ),
                                if (_bookmarked > 0)
                                  _statChip(
                                    'Bookmarked',
                                    _bookmarked,
                                    AppTokens.accent(context),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppTokens.s12),
                            if (_priorityLabel != null &&
                                _priorityColorParsed != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppTokens.s8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _priorityColorParsed!.withOpacity(0.14),
                                  borderRadius: AppTokens.radius8,
                                ),
                                child: Text(
                                  _priorityLabel!,
                                  style:
                                      AppTokens.caption(context).copyWith(
                                    color: _priorityColorParsed,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            const SizedBox(height: AppTokens.s12),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: widget.onOpenSubject,
                                icon: const Icon(Icons.arrow_forward_rounded,
                                    size: 16),
                                label: Text(
                                  'Open subject',
                                  style: AppTokens.titleSm(context).copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTokens.accent(context),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppTokens.radius12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(String label, int count, Color tint) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppTokens.s8, vertical: 4),
      decoration: BoxDecoration(
        color: tint.withOpacity(0.14),
        borderRadius: AppTokens.radius8,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: AppTokens.caption(context).copyWith(
              color: tint,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
