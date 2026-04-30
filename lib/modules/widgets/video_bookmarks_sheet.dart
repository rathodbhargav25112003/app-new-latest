import 'dart:io';
import 'package:flutter/material.dart';

import '../../api_service/api_service.dart';
import '../../helpers/app_tokens.dart';
// Legacy imports preserved for API parity; no longer referenced by the UI.
// ignore: unused_import
import '../../helpers/colors.dart';

/// Modal bottom sheet showing all saved bookmarks for a given content_id.
/// Tapping a row invokes [onSeek] with the position in seconds so the player
/// can jump to that moment. The sheet closes itself after a seek.
///
/// Entry point: `showVideoBookmarksSheet(context: ctx, contentId: id,
///   onSeek: (sec) => controller.seekTo(Duration(seconds: sec)))`
Future<void> showVideoBookmarksSheet({
  required BuildContext context,
  required String contentId,
  required ValueChanged<int> onSeek,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _VideoBookmarksSheet(
      contentId: contentId,
      onSeek: onSeek,
    ),
  );
}

/// Floating action button that saves the current playback position as a new
/// bookmark. Pass [getCurrentPosition] as a pure function so the button can
/// read the player's position at tap-time (avoids stale closure capture).
class VideoBookmarkFab extends StatelessWidget {
  const VideoBookmarkFab({
    super.key,
    required this.contentId,
    required this.getCurrentPosition,
    this.onSaved,
  });

  final String contentId;
  final Duration Function() getCurrentPosition;
  final void Function(Map<String, dynamic> bookmark)? onSaved;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'video_bookmark_fab_$contentId',
      backgroundColor: AppTokens.warning(context),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.bookmark_add_outlined),
      label: const Text('Bookmark'),
      elevation: 2,
      onPressed: () async {
        final pos = getCurrentPosition();
        await _showLabelDialog(context, pos);
      },
    );
  }

  Future<void> _showLabelDialog(BuildContext context, Duration pos) async {
    final controller = TextEditingController();
    final mmss = _fmt(pos);
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppTokens.surface(dialogCtx),
          surfaceTintColor: AppTokens.surface(dialogCtx),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.r20),
          ),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTokens.warningSoft(dialogCtx),
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                ),
                child: Icon(
                  Icons.bookmark_add_rounded,
                  size: 18,
                  color: AppTokens.warning(dialogCtx),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Text(
                  'Bookmark @ $mmss',
                  style: AppTokens.titleMd(dialogCtx)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: TextField(
            controller: controller,
            maxLength: 200,
            autofocus: true,
            cursorColor: AppTokens.accent(dialogCtx),
            style: AppTokens.body(dialogCtx),
            decoration: InputDecoration(
              hintText: 'Label (optional)',
              hintStyle: AppTokens.body(dialogCtx).copyWith(
                color: AppTokens.ink2(dialogCtx),
              ),
              filled: true,
              fillColor: AppTokens.surface2(dialogCtx),
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTokens.s12,
                vertical: AppTokens.s12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTokens.r12),
                borderSide: BorderSide(color: AppTokens.border(dialogCtx)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTokens.r12),
                borderSide:
                    BorderSide(color: AppTokens.accent(dialogCtx), width: 2),
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            AppTokens.s16,
            0,
            AppTokens.s16,
            AppTokens.s16,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                'Cancel',
                style: AppTokens.body(dialogCtx).copyWith(
                  color: AppTokens.ink2(dialogCtx),
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTokens.warning(dialogCtx),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s20,
                  vertical: AppTokens.s12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                ),
              ),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                final bookmark = await ApiService().createVideoBookmark(
                  contentId: contentId,
                  positionSeconds: pos.inSeconds,
                  label: controller.text.trim().isEmpty
                      ? null
                      : controller.text.trim(),
                );
                if (bookmark != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Bookmark saved at $mmss'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppTokens.success(context),
                    ),
                  );
                  onSaved?.call(bookmark);
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Could not save bookmark'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppTokens.danger(context),
                    ),
                  );
                }
              },
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }
}

String _fmt(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

class _VideoBookmarksSheet extends StatefulWidget {
  const _VideoBookmarksSheet({
    required this.contentId,
    required this.onSeek,
  });

  final String contentId;
  final ValueChanged<int> onSeek;

  @override
  State<_VideoBookmarksSheet> createState() => _VideoBookmarksSheetState();
}

class _VideoBookmarksSheetState extends State<_VideoBookmarksSheet> {
  List<Map<String, dynamic>> _items = const <Map<String, dynamic>>[];
  bool _loading = true;

  bool get _isDesktop => Platform.isWindows || Platform.isMacOS;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data =
        await ApiService().listVideoBookmarks(contentId: widget.contentId);
    if (!mounted) return;
    setState(() {
      _items = data;
      _loading = false;
    });
  }

  Future<void> _delete(String id) async {
    final ok = await ApiService().deleteVideoBookmark(id);
    if (!mounted) return;
    if (ok) {
      setState(() => _items = _items
          .where((e) => (e['_id']?.toString()) != id)
          .toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.25,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          width: MediaQuery.of(context).size.width,
          constraints:
              _isDesktop ? const BoxConstraints(maxWidth: 640) : null,
          decoration: BoxDecoration(
            color: AppTokens.surface(context),
            borderRadius: _isDesktop
                ? BorderRadius.circular(AppTokens.r28)
                : const BorderRadius.vertical(
                    top: Radius.circular(AppTokens.r28),
                  ),
          ),
          child: Column(
            children: [
              if (!_isDesktop)
                Container(
                  margin: const EdgeInsets.only(
                    top: AppTokens.s8,
                    bottom: AppTokens.s12,
                  ),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTokens.border(context),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s20,
                  vertical: AppTokens.s8,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTokens.warningSoft(context),
                        borderRadius: BorderRadius.circular(AppTokens.r12),
                      ),
                      child: Icon(
                        Icons.bookmark_rounded,
                        color: AppTokens.warning(context),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppTokens.s12),
                    Text(
                      'Bookmarks',
                      style: AppTokens.titleMd(context)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.s12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTokens.surface2(context),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${_items.length}',
                        style: AppTokens.caption(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTokens.ink2(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppTokens.border(context)),
              Expanded(child: _buildBody(scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(ScrollController scrollController) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: AppTokens.accent(context)),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTokens.surface2(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.bookmark_border_rounded,
                  size: 36,
                  color: AppTokens.ink2(context),
                ),
              ),
              const SizedBox(height: AppTokens.s16),
              Text(
                'No bookmarks yet',
                style: AppTokens.titleSm(context)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppTokens.s4),
              Text(
                'Tap the Bookmark button during playback\nto save a moment you want to revisit.',
                textAlign: TextAlign.center,
                style: AppTokens.body(context).copyWith(
                  color: AppTokens.ink2(context),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: AppTokens.s8),
      itemCount: _items.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: AppTokens.border(context),
        indent: AppTokens.s20,
        endIndent: AppTokens.s20,
      ),
      itemBuilder: (_, i) {
        final b = _items[i];
        final pos = (b['position_seconds'] as num?)?.toInt() ?? 0;
        final label = (b['label'] ?? '').toString();
        final color = _parseColor(b['color']?.toString());
        final id = (b['_id'] ?? '').toString();
        return ListTile(
          onTap: () {
            widget.onSeek(pos);
            Navigator.of(context).pop();
          },
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s20,
            vertical: 2,
          ),
          leading: CircleAvatar(
            backgroundColor: color,
            radius: 18,
            child: const Icon(
              Icons.play_arrow_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          title: Text(
            label.isEmpty ? 'Bookmark @ ${_fmt(Duration(seconds: pos))}' : label,
            style: AppTokens.body(context).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: label.isEmpty
              ? null
              : Text(
                  _fmt(Duration(seconds: pos)),
                  style: AppTokens.caption(context).copyWith(
                    color: AppTokens.ink2(context),
                  ),
                ),
          trailing: IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              color: AppTokens.danger(context),
            ),
            onPressed: () => _delete(id),
          ),
        );
      },
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppTokens.warning(context);
    final h = hex.replaceAll('#', '');
    try {
      return Color(int.parse(h.length == 6 ? 'FF$h' : h, radix: 16));
    } catch (_) {
      return AppTokens.warning(context);
    }
  }
}
