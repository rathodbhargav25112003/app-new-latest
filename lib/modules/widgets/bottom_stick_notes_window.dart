import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../helpers/app_tokens.dart';
import '../reports/store/report_by_category_store.dart';
import 'bottom_toast.dart';

/// CustomBottomStickNotesWindow — desktop / tablet counterpart of the
/// notes dialog. Public surface preserved exactly:
///   • const constructor `{super.key, required this.questionId,
///     required this.notes}`
///   • state field `queryController` (seeded with `widget.notes`)
///   • `_getNotesData` → `ReportsCategoryStore.onGetNotesData(queId)`
///   • `addNotes(questionId, notes)` →
///     `ReportsCategoryStore.onCreateNotes(context, …)` + toast + pop
class CustomBottomStickNotesWindow extends StatefulWidget {
  final String questionId;
  final String notes;
  const CustomBottomStickNotesWindow({
    super.key,
    required this.questionId,
    required this.notes,
  });

  @override
  State<CustomBottomStickNotesWindow> createState() =>
      _CustomBottomStickNotesWindowState();
}

class _CustomBottomStickNotesWindowState
    extends State<CustomBottomStickNotesWindow> {
  TextEditingController queryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    queryController.text = widget.notes;
  }

  Future<void> _getNotesData(String queId) async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onGetNotesData(queId);
  }

  Future<void> addNotes(String? questionId, String? notes) async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onCreateNotes(context, questionId ?? "", notes ?? "");
    _getNotesData(widget.questionId);
    if (!mounted) return;
    BottomToast.showBottomToastOverlay(
      // ignore: use_build_context_synchronously
      context: context,
      errorMessage: "Notes Added Successfully!",
      // ignore: use_build_context_synchronously
      backgroundColor: Theme.of(context).primaryColor,
    );
    // ignore: use_build_context_synchronously
    Navigator.of(context).pop();
  }

  bool get _isDesktop => Platform.isWindows || Platform.isMacOS;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        width: MediaQuery.of(context).size.width,
        constraints: _isDesktop
            ? const BoxConstraints(maxWidth: 520)
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
            AppTokens.s20,
            AppTokens.s20,
            AppTokens.s20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTokens.accentSoft(context),
                    borderRadius: BorderRadius.circular(AppTokens.r16),
                  ),
                  child: Icon(
                    Icons.sticky_note_2_rounded,
                    color: AppTokens.accent(context),
                    size: 24,
                  ),
                ),
                const SizedBox(height: AppTokens.s12),
                Text(
                  'Stick Notes',
                  style: AppTokens.titleLg(context)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppTokens.s4),
                Text(
                  'Write / edit your Stick Notes',
                  style: AppTokens.body(context).copyWith(
                    color: AppTokens.ink2(context),
                  ),
                ),
                const SizedBox(height: AppTokens.s16),
                TextFormField(
                  enableInteractiveSelection: true,
                  maxLines: 10,
                  minLines: 5,
                  cursorColor: AppTokens.accent(context),
                  style: AppTokens.body(context),
                  controller: queryController,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  decoration: AppTokens.inputDecoration(
                    context,
                    hint: 'Type your notes here...',
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
                      child: _GradientCta(
                        label: widget.notes == ''
                            ? 'Save'
                            : 'Save & Modify',
                        icon: Icons.save_rounded,
                        onTap: () {
                          final notes = queryController.text;
                          debugPrint('enterTxt$notes');
                          addNotes(widget.questionId, notes);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared CTAs
// ---------------------------------------------------------------------------

class _GradientCta extends StatelessWidget {
  const _GradientCta({
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
            gradient: const LinearGradient(
              colors: [AppTokens.brand, AppTokens.brand2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
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
