import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../helpers/app_tokens.dart';
import '../reports/store/report_by_category_store.dart';
import 'bottom_toast.dart';

/// CustomBottomStickNotes — dialog (not a bottom sheet) that surfaces the
/// system keyboard for the learner's personal MCQ notes. Public surface
/// preserved exactly:
///   • const constructor `{super.key, required this.questionId,
///     required this.notes}`
///   • state fields `queryController`, `_notesFocusNode`,
///     `_hasRequestedInitialFocus`, `_isClosing`
///   • `didChangeDependencies` requests initial focus exactly once via
///     `WidgetsBinding.instance.addPostFrameCallback`
///   • `_handleFocusChange` reclaims focus + invokes
///     `SystemChannels.textInput.invokeMethod('TextInput.show')`
///   • `_getNotesData` / `addNotes` call
///     `ReportsCategoryStore.onGetNotesData` and
///     `ReportsCategoryStore.onCreateNotes(context, …)`
class CustomBottomStickNotes extends StatefulWidget {
  final String questionId;
  final String notes;
  const CustomBottomStickNotes({
    super.key,
    required this.questionId,
    required this.notes,
  });

  @override
  State<CustomBottomStickNotes> createState() => _CustomBottomStickNotesState();
}

class _CustomBottomStickNotesState extends State<CustomBottomStickNotes> {
  final TextEditingController queryController = TextEditingController();
  final FocusNode _notesFocusNode = FocusNode();
  bool _hasRequestedInitialFocus = false;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    queryController.text = widget.notes;
    _notesFocusNode.addListener(_handleFocusChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasRequestedInitialFocus) {
      _hasRequestedInitialFocus = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          FocusScope.of(context).requestFocus(_notesFocusNode);
        }
      });
    }
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
    _isClosing = true;
    // ignore: use_build_context_synchronously
    Navigator.of(context).pop();
  }

  void _handleFocusChange() {
    if (!mounted || _isClosing) return;
    if (_notesFocusNode.hasFocus) {
      SystemChannels.textInput.invokeMethod('TextInput.show');
    } else {
      final route = ModalRoute.of(context);
      if (route != null && route.isCurrent && route.isActive) {
        Future.microtask(() {
          if (mounted && !_isClosing) {
            FocusScope.of(context).requestFocus(_notesFocusNode);
            SystemChannels.textInput.invokeMethod('TextInput.show');
          }
        });
      }
    }
  }

  @override
  void dispose() {
    queryController.dispose();
    _isClosing = true;
    _notesFocusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    const double verticalPadding = AppTokens.s20;
    final double availableHeight =
        mediaQuery.size.height - (verticalPadding * 2);
    const double minDialogHeight = 340;
    const double maxDialogHeight = 460;
    final double dialogHeight;
    if (availableHeight <= 0) {
      dialogHeight = minDialogHeight;
    } else if (availableHeight < minDialogHeight) {
      dialogHeight = availableHeight;
    } else {
      dialogHeight = availableHeight.clamp(minDialogHeight, maxDialogHeight);
    }
    final double availableWidth = mediaQuery.size.width -
        (AppTokens.s20 * 2) -
        mediaQuery.padding.horizontal;
    final double dialogWidth = availableWidth.clamp(320.0, 480.0);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s20,
        vertical: verticalPadding,
      ),
      child: Center(
        child: Dialog(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.r20),
          ),
          backgroundColor: AppTokens.surface(context),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s20,
          ),
          child: SizedBox(
            height: dialogHeight,
            width: dialogWidth,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const double reservedSpace = 260;
                const double minTextFieldHeight = 140;
                const double maxTextFieldHeight = 280;
                double textFieldHeight =
                    constraints.maxHeight - reservedSpace;
                textFieldHeight =
                    math.max(textFieldHeight, minTextFieldHeight);
                textFieldHeight =
                    math.min(textFieldHeight, maxTextFieldHeight);

                final bool allowScroll =
                    constraints.maxHeight < reservedSpace + minTextFieldHeight;

                final content = Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.s20,
                    AppTokens.s16,
                    AppTokens.s20,
                    AppTokens.s20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Soft accent header: icon + title + subtitle
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
                      SizedBox(
                        height: textFieldHeight,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.s12,
                            vertical: AppTokens.s12,
                          ),
                          decoration: BoxDecoration(
                            color: AppTokens.surface2(context),
                            borderRadius:
                                BorderRadius.circular(AppTokens.r12),
                            border: Border.all(
                              color: AppTokens.border(context),
                            ),
                          ),
                          child: TextField(
                            focusNode: _notesFocusNode,
                            autofocus: false,
                            enableInteractiveSelection: true,
                            onTap: () {
                              if (!_notesFocusNode.hasFocus) {
                                FocusScope.of(context)
                                    .requestFocus(_notesFocusNode);
                              }
                              SystemChannels.textInput
                                  .invokeMethod('TextInput.show');
                            },
                            maxLines: null,
                            minLines: null,
                            expands: true,
                            cursorColor: AppTokens.accent(context),
                            style: AppTokens.body(context),
                            controller: queryController,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            decoration: const InputDecoration(
                              isCollapsed: true,
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              counterText: '',
                              hintText: 'Type your notes here...',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTokens.s16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
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
                );

                if (!allowScroll) {
                  return content;
                }

                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: content,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gradient CTA — identical across notes sheets to keep save button coherent
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
