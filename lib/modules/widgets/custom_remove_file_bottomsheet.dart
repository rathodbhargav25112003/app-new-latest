import 'dart:io';
import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/dbhelper.dart';
// Legacy imports preserved for API parity; no longer referenced by the UI.
// ignore: unused_import, unnecessary_import
import 'package:flutter/cupertino.dart';
// ignore: unused_import
import 'package:flutter_svg/svg.dart';
// ignore: unused_import, depend_on_referenced_packages
import 'package:hive/hive.dart';
// ignore: unused_import
import 'package:shusruta_lms/helpers/colors.dart';
// ignore: unused_import
import 'package:shusruta_lms/modules/videolectures/store/video_category_store.dart';
// ignore: unused_import
import '../../helpers/dimensions.dart';
// ignore: unused_import
import '../../helpers/styles.dart';
// ignore: unused_import
import '../../models/notes_offline_data_model.dart';
// ignore: unused_import
import 'custom_button.dart';

/// CustomRemoveFileBottomSheet — confirmation sheet for deleting an offline
/// notes topic. Public surface preserved exactly:
///   • const constructor `(BuildContext context, this.topicId, {super.key})`
///     with a nullable `String topicId` positional arg
///   • On confirm: `DbHelper().deleteAllNotesByTitleId(topicId ?? '')`
///     followed by `Navigator.of(context).pushNamed(Routes.dashboard)`
class CustomRemoveFileBottomSheet extends StatefulWidget {
  // final FileSystemEntity file;
  final String? topicId;
  const CustomRemoveFileBottomSheet(
    BuildContext context,
    // this.file,
    this.topicId, {
    super.key,
  });

  @override
  State<CustomRemoveFileBottomSheet> createState() =>
      _CustomRemoveFileBottomSheetState();
}

class _CustomRemoveFileBottomSheetState
    extends State<CustomRemoveFileBottomSheet> {
  @override
  void initState() {
    super.initState();
  }

  bool get _isDesktop => Platform.isWindows || Platform.isMacOS;

  Future<void> _handleRemove() async {
    try {
      final dbHelper = DbHelper();
      final String topicIdToDelete = widget.topicId ?? '';

      final int rowsAffected =
          await dbHelper.deleteAllNotesByTitleId(topicIdToDelete);
      if (rowsAffected > 0) {
        debugPrint(
            'All records with topicId $topicIdToDelete deleted successfully');
      } else {
        debugPrint('No records found for topicId $topicIdToDelete');
      }
      if (!mounted) return;
      Navigator.of(context).pushNamed(Routes.dashboard);
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: _isDesktop
          ? const BoxConstraints(maxWidth: 480)
          : null,
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: _isDesktop
            ? BorderRadius.circular(AppTokens.r20)
            : const BorderRadius.vertical(
                top: Radius.circular(AppTokens.r20),
              ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.s20,
          AppTokens.s16,
          AppTokens.s20,
          AppTokens.s20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_isDesktop)
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
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTokens.dangerSoft(context),
                  borderRadius: BorderRadius.circular(AppTokens.r20),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: AppTokens.danger(context),
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              'Are you sure you want to\nremove this file?',
              textAlign: TextAlign.center,
              style: AppTokens.titleLg(context)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppTokens.s8),
            Text(
              'This action cannot be undone.',
              textAlign: TextAlign.center,
              style: AppTokens.body(context).copyWith(
                color: AppTokens.ink2(context),
              ),
            ),
            const SizedBox(height: AppTokens.s20),
            Row(
              children: [
                Expanded(
                  child: _GhostCta(
                    label: 'Cancel',
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: AppTokens.s12),
                Expanded(
                  child: _DangerCta(
                    label: 'Remove',
                    icon: Icons.delete_outline_rounded,
                    onTap: _handleRemove,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DangerCta extends StatelessWidget {
  const _DangerCta({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTokens.danger(context),
            borderRadius: BorderRadius.circular(AppTokens.r12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: AppTokens.s8),
              Text(
                label,
                style: AppTokens.body(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GhostCta extends StatelessWidget {
  const _GhostCta({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTokens.surface2(context),
            border: Border.all(color: AppTokens.border(context)),
            borderRadius: BorderRadius.circular(AppTokens.r12),
          ),
          child: Text(
            label,
            style: AppTokens.body(context).copyWith(
              fontWeight: FontWeight.w700,
              color: AppTokens.ink2(context),
            ),
          ),
        ),
      ),
    );
  }
}
