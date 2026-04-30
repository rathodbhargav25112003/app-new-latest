import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/helpers/empty_state.dart';
import 'package:shusruta_lms/helpers/styles.dart';
import 'package:shusruta_lms/services/download_service.dart';

/// Shows the download queue, active download progress, storage usage,
/// and WiFi-only toggle. Invoke via `DownloadManagerSheet.show(context)`.
///
/// Apple-minimalistic chrome — drag handle pill, 28pt top corners,
/// scaffold-toned background. Empty state when nothing is in flight.
class DownloadManagerSheet extends StatefulWidget {
  const DownloadManagerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          color: AppTokens.surface(sheetCtx),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTokens.r28),
          ),
        ),
        child: SafeArea(
          top: false,
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            expand: false,
            builder: _sheetBuilder,
          ),
        ),
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
      padding: const EdgeInsets.fromLTRB(AppTokens.s16, AppTokens.s12, AppTokens.s16, AppTokens.s16),
      child: ListView(
        children: [
          // Apple-style drag handle pill.
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppTokens.s16),
              decoration: BoxDecoration(
                color: AppTokens.border(context),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Downloads', style: AppTokens.titleLg(context)),
              // WiFi-only toggle
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wifi,
                    size: 16,
                    color: _service.wifiOnly ? AppTokens.accent(context) : AppTokens.muted(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'WiFi only',
                    style: AppTokens.caption(context).copyWith(
                      color: _service.wifiOnly ? AppTokens.accent(context) : AppTokens.muted(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 24,
                    child: Switch(
                      value: _service.wifiOnly,
                      activeColor: AppTokens.accent(context),
                      onChanged: (v) async {
                        await _service.setWifiOnly(v);
                        setState(() {});
                      },
                      activeThumbColor: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Storage info bar
          if (_storageInfo.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.storage_rounded, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${_storageInfo['fileCount']} videos \u2022 ${_storageInfo['formatted']} used',
                    style: interRegular.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const Spacer(),
                  if (completed.isNotEmpty || (_storageInfo['fileCount'] as int? ?? 0) > 0)
                    GestureDetector(
                      onTap: () => _showDeleteAllDialog(context),
                      child: Text(
                        'Clear all',
                        style: interRegular.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.red[400],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Active download
          if (active != null && active.status == DownloadStatus.downloading) ...[
            _sectionTitle('Downloading'),
            _activeDownloadTile(active),
            const SizedBox(height: 8),
          ],

          // Encrypting
          if (active != null && active.status == DownloadStatus.encrypting) ...[
            _sectionTitle('Securing'),
            _encryptingTile(active),
            const SizedBox(height: 8),
          ],

          // Queued
          if (queued.isNotEmpty) ...[
            _sectionTitle('In Queue (${queued.length})'),
            ...queued.map(_queuedTile),
            const SizedBox(height: 8),
          ],

          // Failed
          if (failed.isNotEmpty) ...[
            _sectionTitle('Failed'),
            ...failed.map(_failedTile),
            const SizedBox(height: 8),
          ],

          // Completed
          if (completed.isNotEmpty) ...[
            _sectionTitle('Completed (${completed.length})'),
            ...completed.map(_completedTile),
          ],

          // Empty state — uses the shared EmptyState helper.
          if (tasks.isEmpty)
            const EmptyState(
              icon: Icons.download_done_rounded,
              title: 'No downloads yet',
              subtitle: 'Downloaded videos will appear here. Tap the cloud icon on any lecture to start.',
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
        style: interRegular.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.grey[500],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _activeDownloadTile(DownloadTask task) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: interRegular.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ThemeManager.blackColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () => _service.cancel(task.titleId),
                child: Icon(Icons.close, size: 18, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: task.progressPercent / 100,
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${task.progressPercent}% \u2022 ${task.downloadedSizeFormatted} / ${task.fileSizeFormatted}',
                style: interRegular.copyWith(fontSize: 11, color: Colors.grey[600]),
              ),
              Text(
                task.quality,
                style: interRegular.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: interRegular.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Encrypting for offline playback...',
                  style: interRegular.copyWith(fontSize: 11, color: Colors.orange[700]),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$position',
              style:
                  interRegular.copyWith(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              task.title,
              style: interRegular.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () {
              _service.cancel(task.titleId);
              setState(() {});
            },
            child: Icon(Icons.close, size: 16, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _failedTile(DownloadTask task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: Colors.red[400]),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: interRegular.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  task.errorMessage ?? 'Download failed',
                  style: interRegular.copyWith(fontSize: 10, color: Colors.red[400]),
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
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Retry',
                style: interRegular.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 18, color: Colors.green[600]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              task.title,
              style: interRegular.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            task.fileSizeFormatted,
            style: interRegular.copyWith(fontSize: 10, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete All Downloads?',
          style: interRegular.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will remove all offline videos and free up ${_storageInfo['formatted'] ?? '0 MB'} of storage.',
          style: interRegular.copyWith(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: interRegular.copyWith(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _service.deleteAllDownloads();
              await _loadStorageInfo();
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) setState(() {});
            },
            child: Text('Delete All',
                style: interRegular.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
