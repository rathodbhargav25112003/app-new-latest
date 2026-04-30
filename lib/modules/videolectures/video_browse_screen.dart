import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../helpers/app_skeleton.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/cached_image.dart';
import '../../helpers/empty_state.dart';
import '../../helpers/haptics.dart';
import '../../helpers/refresh_helper.dart';
import '../../helpers/value_formatters.dart';
import '../../services/recent_videos_service.dart';
import '../dashboard/models/global_search_model.dart';
import '../dashboard/store/home_store.dart';
import '../widgets/no_internet_connection.dart';
import 'store/video_category_store.dart';

/// VideoBrowseScreen — single-tap-to-player entry point.
///
/// Replaces the legacy 4-deep flow
/// (subject → subcategory → topic → lecture → player)
/// with three quick paths:
///
///   1. **Search** at the top — type "renal physiology", see all
///      matching lectures at any depth, tap → player. Uses the
///      existing [HomeStore.onGlobalSearchApiCall] endpoint scoped
///      to "video".
///
///   2. **Continue watching** rail — last 8 videos opened, with a
///      thumbnail + position bar + topic subtitle, pulled from
///      [RecentVideosService] (instant, offline-first).
///
///   3. **Browse all subjects** — expandable subject cards. Tap to
///      expand inline (per-status counts visible) → tap "Open
///      subject" CTA to drill in via the legacy 4-level flow.
class VideoBrowseScreen extends StatefulWidget {
  const VideoBrowseScreen({super.key});

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(builder: (_) => const VideoBrowseScreen());
  }

  @override
  State<VideoBrowseScreen> createState() => _VideoBrowseScreenState();
}

class _VideoBrowseScreenState extends State<VideoBrowseScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _query = '';
  bool _searching = false;
  List<RecentVideoEntry> _recents = const [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final store = Provider.of<VideoCategoryStore>(context, listen: false);
    // ignore: discarded_futures
    store.onRegisterApiCall(context);
    final recents = await RecentVideosService.instance.top(8);
    if (!mounted) return;
    setState(() => _recents = recents);
  }

  Future<void> _refresh() async {
    final store = Provider.of<VideoCategoryStore>(context, listen: false);
    await store.onRegisterApiCall(context);
    final recents = await RecentVideosService.instance.top(8);
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
      await home.onGlobalSearchApiCall(value, "video");
    }
  }

  void _openSearchHit(GlobalSearchDataModel hit) {
    Haptics.selection();
    final type = hit.type ?? '';
    if (type == 'videoCategory') {
      Navigator.of(context).pushNamed(
        Routes.videoSubjectDetail,
        arguments: {"subject": hit.categoryName, "vid": hit.id},
      );
    } else if (type == 'videoSubCategory') {
      Navigator.of(context).pushNamed(
        Routes.VideoTopicCategory,
        arguments: {"chapter": hit.subcategoryName, "subcatId": hit.id},
      );
    } else if (type == 'videoTopic') {
      Navigator.of(context).pushNamed(
        Routes.videoChapterDetail,
        arguments: {
          "chapter": hit.topicName,
          "subject": '',
          "subcatId": hit.id,
        },
      );
    } else if (type == 'content' && (hit.contentType == 'video')) {
      // Direct shortcut — straight to the player.
      Navigator.of(context).pushNamed(
        Routes.videoPlayDetail,
        arguments: {
          'topicId': hit.id,
          'title': hit.title ?? '',
          'topic_name': hit.topicName ?? '',
          'category_name': hit.categoryName ?? '',
          'subcategory_name': hit.subcategoryName ?? '',
          'isDownloaded': false,
          'titleId': hit.id,
          'categoryId': hit.categoryId,
          'subcategoryId': hit.subcategoryId,
        },
      );
    }
  }

  void _openRecent(RecentVideoEntry r) {
    Haptics.selection();
    Navigator.of(context).pushNamed(
      Routes.videoPlayDetail,
      arguments: {
        'topicId': r.videoId,
        'title': r.title,
        'topic_name': r.topicName ?? '',
        'category_name': r.categoryName ?? '',
        'subcategory_name': r.subcategoryName ?? '',
        'isDownloaded': false,
        'titleId': r.videoId,
        'categoryId': r.categoryId,
        'subcategoryId': r.subcategoryId,
        'positionSeconds': r.positionSeconds,
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
    final videoStore = Provider.of<VideoCategoryStore>(context);
    final homeStore = Provider.of<HomeStore>(context);
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppTokens.scaffold(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTokens.ink(context), size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text("Videos", style: AppTokens.titleLg(context)),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Downloads',
            icon: Icon(Icons.download_rounded, color: AppTokens.ink(context), size: 22),
            onPressed: () {
              Haptics.selection();
              Navigator.of(context).pushNamed(Routes.downloadedVideoCategory);
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
              child: _searching ? _buildSearchResults(homeStore) : _buildBrowseBody(videoStore),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Search field ─────────────────────────────────────────────────

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTokens.s24, AppTokens.s8, AppTokens.s24, AppTokens.s8),
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
            Icon(Icons.search_rounded, size: 20, color: AppTokens.muted(context)),
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
                  hintText: 'Search lectures by topic, chapter, or subject…',
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
                icon: Icon(Icons.cancel_rounded, size: 18, color: AppTokens.muted(context)),
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

  // ─── Search results ──────────────────────────────────────────────

  Widget _buildSearchResults(HomeStore home) {
    return Observer(
      builder: (_) {
        if (home.isLoading) {
          return const SkeletonList(count: 6, itemHeight: 80);
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
          padding: const EdgeInsets.fromLTRB(AppTokens.s24, 0, AppTokens.s24, AppTokens.s24),
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
    final title = hit.title ?? hit.topicName ?? hit.subcategoryName ?? hit.categoryName ?? 'Lecture';
    final subtitle = [
      if (hit.categoryName != null) hit.categoryName!,
      if (hit.subcategoryName != null) hit.subcategoryName!,
      if (hit.topicName != null && hit.topicName != title) hit.topicName!,
    ].join(' · ');

    final levelLabel = type == 'videoCategory'
        ? 'Subject'
        : type == 'videoSubCategory'
            ? 'Chapter'
            : type == 'videoTopic'
                ? 'Topic'
                : 'Lecture';

    return Material(
      color: AppTokens.surface(context),
      borderRadius: AppTokens.radius16,
      child: InkWell(
        borderRadius: AppTokens.radius16,
        onTap: () => _openSearchHit(hit),
        child: Container(
          padding: const EdgeInsets.all(AppTokens.s12),
          decoration: BoxDecoration(
            border: Border.all(color: AppTokens.border(context), width: 0.5),
            borderRadius: AppTokens.radius16,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isContent ? AppTokens.accentSoft(context) : AppTokens.surface2(context),
                  borderRadius: AppTokens.radius12,
                ),
                child: Icon(
                  isContent ? Icons.play_circle_fill_rounded : Icons.folder_outlined,
                  color: isContent ? AppTokens.accent(context) : AppTokens.muted(context),
                  size: 22,
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTokens.muted(context)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Browse body ─────────────────────────────────────────────────

  Widget _buildBrowseBody(VideoCategoryStore store) {
    return Observer(
      builder: (_) {
        if (!store.isConnected) return const NoInternetScreen();
        if (store.isLoading && store.videocategory.isEmpty) {
          return const SkeletonList(count: 5, itemHeight: 96);
        }
        return AppRefresh(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppTokens.s24, AppTokens.s8, AppTokens.s24, AppTokens.s24),
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            children: [
              if (_recents.isNotEmpty) ...[
                Text('Continue watching', style: AppTokens.titleMd(context)),
                const SizedBox(height: AppTokens.s8),
                _recentsRail(),
                const SizedBox(height: AppTokens.s20),
              ],
              if (store.videocategory.isNotEmpty) ...[
                Text('All subjects', style: AppTokens.titleMd(context)),
                const SizedBox(height: AppTokens.s8),
                ...store.videocategory.map((cat) {
                  if (cat == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTokens.s8),
                    child: _ExpandableSubjectCard(
                      category: cat,
                      onOpenSubject: () {
                        Haptics.selection();
                        Navigator.of(context).pushNamed(
                          Routes.videoSubjectDetail,
                          arguments: {
                            "subject": cat.category_name,
                            "vid": cat.sid,
                          },
                        );
                      },
                    ),
                  );
                }),
              ] else if (!store.isLoading) ...[
                const EmptyState(
                  icon: Icons.video_library_outlined,
                  title: 'No video lectures yet',
                  subtitle: 'Your subscription doesn’t include lectures right now. '
                      'Check the plans page to upgrade.',
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ─── Recents rail ────────────────────────────────────────────────

  Widget _recentsRail() {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _recents.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTokens.s12),
        itemBuilder: (_, i) {
          final r = _recents[i];
          return _RecentVideoCard(
            entry: r,
            onTap: () => _openRecent(r),
          );
        },
      ),
    );
  }
}

// ─── Components ─────────────────────────────────────────────────────

class _RecentVideoCard extends StatelessWidget {
  const _RecentVideoCard({required this.entry, required this.onTap});

  final RecentVideoEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Material(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius16,
        child: InkWell(
          borderRadius: AppTokens.radius16,
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppTokens.radius16,
              border: Border.all(color: AppTokens.border(context), width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppTokens.r16),
                          topRight: Radius.circular(AppTokens.r16),
                        ),
                        child: AppCachedImage(
                          url: entry.thumbnail,
                          fit: BoxFit.cover,
                          fallback: Container(
                            color: AppTokens.surface2(context),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.play_circle_fill_rounded,
                              size: 36,
                              color: AppTokens.muted(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.history_rounded, color: Colors.white, size: 12),
                            const SizedBox(width: 3),
                            Text(
                              entry.lastSeenAt == null ? 'Recent' : Fmt.relativeTime(entry.lastSeenAt!),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (entry.progressRatio > 0)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.zero,
                          child: LinearProgressIndicator(
                            value: entry.progressRatio,
                            minHeight: 3,
                            backgroundColor: Colors.black.withOpacity(0.4),
                            color: AppTokens.accent(context),
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(AppTokens.s8),
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
                      const SizedBox(height: 2),
                      Text(
                        entry.topicName ?? entry.categoryName ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTokens.caption(context),
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

class _ExpandableSubjectCard extends StatefulWidget {
  const _ExpandableSubjectCard({
    required this.category,
    required this.onOpenSubject,
  });

  final dynamic category; // VideoCategoryModel?
  final VoidCallback onOpenSubject;

  @override
  State<_ExpandableSubjectCard> createState() => _ExpandableSubjectCardState();
}

class _ExpandableSubjectCardState extends State<_ExpandableSubjectCard> {
  bool _expanded = false;

  String? get _name => widget.category?.category_name as String?;
  String? get _description => widget.category?.description as String?;
  int get _completed => (widget.category?.completedVideoCount as int?) ?? 0;
  int get _progress => (widget.category?.progressCount as int?) ?? 0;
  int get _notStarted => (widget.category?.notStart as int?) ?? 0;
  int get _total => (widget.category?.video as int?) ?? 0;
  String? get _priorityLabel => widget.category?.priorityLabel as String?;

  /// VideoCategoryModel.priorityColor is a hex string ("#FFAB00"). Parse
  /// to a Color when present.
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
            border: Border.all(color: AppTokens.border(context), width: 0.5),
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
                      Icons.video_library_rounded,
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
                        if (_total > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            '$_total lectures',
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
                              Text(_description!, style: AppTokens.body(context)),
                              const SizedBox(height: AppTokens.s12),
                            ],
                            Wrap(
                              spacing: AppTokens.s8,
                              runSpacing: AppTokens.s8,
                              children: [
                                _statChip('Completed', _completed, AppTokens.success(context)),
                                _statChip('In progress', _progress, AppTokens.warning(context)),
                                _statChip('Not started', _notStarted, AppTokens.muted(context)),
                              ],
                            ),
                            if (_priorityLabel != null && _priorityColorParsed != null) ...[
                              const SizedBox(height: AppTokens.s12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppTokens.s8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _priorityColorParsed!.withOpacity(0.14),
                                  borderRadius: AppTokens.radius8,
                                ),
                                child: Text(
                                  _priorityLabel!,
                                  style: AppTokens.caption(context).copyWith(
                                    color: _priorityColorParsed,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: AppTokens.s12),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: widget.onOpenSubject,
                                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s8, vertical: 4),
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
