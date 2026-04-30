// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters, unused_field, unused_local_variable, non_constant_identifier_names, dead_code, prefer_final_fields, unnecessary_import

import 'dart:async';
import 'package:flutter/material.dart';

import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/helpers/dimensions.dart';
import 'package:shusruta_lms/helpers/styles.dart';
import 'package:shusruta_lms/services/download_service.dart';

/// Shows the download queue, active download progress, storage usage,
/// and WiFi-only toggle. Invoke via `DownloadManagerSheet.show(context)`.
///
/// Preserved public contract:
///   • `DownloadManagerSheet({super.key})` — const constructor.
///   • Static `show(BuildContext context)` returns a `Future<void>` and
///     presents the sheet via `showModalBottomSheet` + `DraggableScrollableSheet`.
///   • Consumes `DownloadService.instance` for all task state.
class DownloadManagerSheet extends StatefulWidget {
  const DownloadManagerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTokens.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.r28)),
      ),
      builder: (_) => const DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: _sheetBuilder,
      ),
    );
  }

  static Widget _sheetBuilder(BuildContext context, ScrollController controller) {
    return const DownloadManagerSheet();
  }

  @override
  State<DownloadManagerSheet> createState() => _DownloadManagerSheetState();
}

class _DownloadManagerSheetState extends State<DownloadManagerSheet> {
  final _service = DownloadService.instance;
  Timer? _refreshTimer;
  Map<String, dynamic> _storageInfo = {};

  // Scoped stream subscriptions — cancelled in dispose. Replaces the old
  // single-field callback assignment (`_service.onTaskUpdated = …`) which
  // leaked closure references across repeated sheet open/close cycles and
  // clobbered listeners in other parts of the app (store, player). Broadcast
  // streams fan out to any number of listeners with no interference.
  StreamSubscription<DownloadTask>? _updSub;
  StreamSubscription<DownloadTask>? _compSub;
  StreamSubscription<void>? _queueSub;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
    // Refresh UI every second to show download progress
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    // Listen for changes via broadcast streams.
    _updSub = _service.updates.listen((_) {
      if (mounted) setState(() {});
    });
    _compSub = _service.completed.listen((_) {
      if (mounted) {
        setState(() {});
        _loadStorageInfo();
      }
    });
    _queueSub = _service.queueChanges.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _updSub?.cancel();
    _compSub?.cancel();
    _queueSub?.cancel();
    super.dispose();
  }

  Future<void> _loadStorageInfo() async {
    _storageInfo = await _service.getStorageInfo();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _service.allTasks;
    final active = _service.activeTask;
    final queued = tasks.where((t) => t.status == DownloadStatus.queued).toList();
    final completed = tasks.where((t) => t.status == DownloadStatus.completed).toList();
    final failed = tasks.where((t) => t.status == DownloadStatus.failed).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s16,
        AppTokens.s12,
        AppTokens.s16,
        AppTokens.s16,
      ),
      child: ListView(
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppTokens.s16),
              decoration: BoxDecoration(
                color: AppTokens.border(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Downloads',
                style: AppTokens.titleMd(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTokens.ink(context),
                ),
              ),
              // WiFi-only toggle
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wifi,
                    size: 16,
                    color: _service.wifiOnly
                        ? AppTokens.accent(context)
                        : AppTokens.muted(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'WiFi only',
                    style: AppTokens.caption(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: _service.wifiOnly
                          ? AppTokens.accent(context)
                          : AppTokens.muted(context),
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 24,
                    child: Switch(
                      value: _service.wifiOnly,
                      onChanged: (v) async {
                        await _service.setWifiOnly(v);
                        setState(() {});
                      },
                      activeColor: AppTokens.accent(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s8),

          // Storage info bar
          if (_storageInfo.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.s12,
                vertical: AppTokens.s12,
              ),
              decoration: BoxDecoration(
                color: AppTokens.surface2(context),
                borderRadius: BorderRadius.circular(AppTokens.r12),
                border: Border.all(color: AppTokens.border(context)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.storage_rounded,
                    size: 18,
                    color: AppTokens.muted(context),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  Text(
                    '${_storageInfo['fileCount']} videos \u2022 ${_storageInfo['formatted']} used',
                    style: AppTokens.caption(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTokens.muted(context),
                    ),
                  ),
                  const Spacer(),
                  if (completed.isNotEmpty || (_storageInfo['fileCount'] as int? ?? 0) > 0)
                    GestureDetector(
                      onTap: () => _showDeleteAllDialog(context),
                      child: Text(
                        'Clear all',
                        style: AppTokens.caption(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: ThemeManager.redAlert,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.s12),
          ],

          // Active download
          if (active != null && active.status == DownloadStatus.downloading) ...[
            _sectionTitle('Downloading'),
            _activeDownloadTile(active),
            const SizedBox(height: AppTokens.s8),
          ],

          // Encrypting
          if (active != null && active.status == DownloadStatus.encrypting) ...[
            _sectionTitle('Securing'),
            _encryptingTile(active),
            const SizedBox(height: AppTokens.s8),
          ],

          // Queued
          if (queued.isNotEmpty) ...[
            _sectionTitle('In Queue (${queued.length})'),
            ...queued.map(_queuedTile),
            const SizedBox(height: AppTokens.s8),
          ],

          // Failed
          if (failed.isNotEmpty) ...[
            _sectionTitle('Failed'),
            ...failed.map(_failedTile),
            const SizedBox(height: AppTokens.s8),
          ],

          // Completed
          if (completed.isNotEmpty) ...[
            _sectionTitle('Completed (${completed.length})'),
            ...completed.map(_completedTile),
          ],

          // Empty state
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(
                    Icons.download_done_rounded,
                    size: 48,
                    color: AppTokens.muted(context),
                  ),
                  const SizedBox(height: AppTokens.s12),
                  Text(
                    'No downloads yet',
                    style: AppTokens.body(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTokens.muted(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Downloaded videos will appear here',
                    style: AppTokens.caption(context).copyWith(
                      color: AppTokens.muted(context),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(
        title,
        style: AppTokens.caption(context).copyWith(
          fontWeight: FontWeight.w700,
          color: AppTokens.muted(context),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _activeDownloadTile(DownloadTask task) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.accentSoft(context),
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(color: AppTokens.accent(context).withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: AppTokens.body(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTokens.ink(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () => _service.cancel(task.titleId),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: AppTokens.muted(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: task.progressPercent / 100,
              minHeight: 6,
              backgroundColor: AppTokens.surface2(context),
              valueColor: AlwaysStoppedAnimation<Color>(AppTokens.accent(context)),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${task.progressPercent}% \u2022 ${task.downloadedSizeFormatted} / ${task.fileSizeFormatted}',
                style: AppTokens.caption(context).copyWith(
                  color: AppTokens.muted(context),
                ),
              ),
              Text(
                task.quality,
                style: AppTokens.caption(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTokens.accent(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _encryptingTile(DownloadTask task) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(color: Colors.orange.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: AppTokens.body(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTokens.ink(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Encrypting for offline playback...',
                  style: AppTokens.caption(context).copyWith(
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _queuedTile(DownloadTask task) {
    final position = _service.queuedTasks.indexOf(task) + 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s12,
      ),
      decoration: BoxDecoration(
        color: AppTokens.surface2(context),
        borderRadius: BorderRadius.circular(AppTokens.r12),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTokens.border(context),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$position',
              style: AppTokens.caption(context).copyWith(
                fontWeight: FontWeight.w800,
                color: AppTokens.muted(context),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              task.title,
              style: AppTokens.caption(context).copyWith(
                fontWeight: FontWeight.w600,
                color: AppTokens.ink(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () {
              _service.cancel(task.titleId);
              setState(() {});
            },
            child: Icon(
              Icons.close,
              size: 16,
              color: AppTokens.muted(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _failedTile(DownloadTask task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s12,
      ),
      decoration: BoxDecoration(
        color: ThemeManager.redAlert.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTokens.r12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: ThemeManager.redAlert),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: AppTokens.caption(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTokens.ink(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  task.errorMessage ?? 'Download failed',
                  style: AppTokens.caption(context).copyWith(
                    color: ThemeManager.redAlert,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              _service.enqueue(
                titleId: task.titleId,
                url: task.url,
                quality: task.quality,
                title: task.title,
                topicId: task.topicId,
                categoryId: task.categoryId,
                subCategoryId: task.subCategoryId,
              );
              setState(() {});
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTokens.accent(context),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Retry',
                style: AppTokens.caption(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _completedTile(DownloadTask task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s12,
      ),
      decoration: BoxDecoration(
        color: ThemeManager.greenSuccess.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTokens.r12),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 18, color: ThemeManager.greenSuccess),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              task.title,
              style: AppTokens.caption(context).copyWith(
                fontWeight: FontWeight.w600,
                color: AppTokens.ink(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            task.fileSizeFormatted,
            style: AppTokens.caption(context).copyWith(
              color: AppTokens.muted(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTokens.surface(context),
        surfaceTintColor: AppTokens.surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r16),
        ),
        title: Text(
          'Delete All Downloads?',
          style: AppTokens.titleSm(context).copyWith(
            fontWeight: FontWeight.w700,
            color: AppTokens.ink(context),
          ),
        ),
        content: Text(
          'This will remove all offline videos and free up ${_storageInfo['formatted'] ?? '0 MB'} of storage.',
          style: AppTokens.body(context).copyWith(
            color: AppTokens.muted(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTokens.body(context).copyWith(
                fontWeight: FontWeight.w600,
                color: AppTokens.muted(context),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ThemeManager.redAlert),
            onPressed: () async {
              await _service.deleteAllDownloads();
              await _loadStorageInfo();
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) setState(() {});
            },
            child: Text(
              'Delete All',
              style: AppTokens.body(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
