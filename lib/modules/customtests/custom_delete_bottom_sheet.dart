import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../helpers/app_tokens.dart';
import '../test/store/test_category_store.dart';
import 'package:shusruta_lms/modules/customtests/store/custom_test_store.dart';

// Legacy imports preserved for API parity; no longer referenced by the UI.
// ignore: unused_import
import '../../helpers/colors.dart';
// ignore: unused_import
import '../../helpers/styles.dart';
// ignore: unused_import
import '../../helpers/dimensions.dart';
// ignore: unused_import, unnecessary_import
import 'package:flutter/cupertino.dart';
// ignore: unused_import
import 'package:flutter_mobx/flutter_mobx.dart';

/// CustomTestDeleteBottomSheet — confirmation sheet for removing a custom
/// test module. Public surface preserved exactly:
///   • const constructor
///     `CustomTestDeleteBottomSheet(BuildContext context,
///      {super.key, required String customTestId})`
///   • on tap of Delete → `CustomTestCategoryStore.onDeleteCustomTestCall(
///      customTestId)` → `onCustomTestListApiCall(context)` →
///     `Navigator.pop(context)`
///
/// The [TestCategoryStore] Provider.of listen is preserved so the sheet
/// still participates in any upstream rebuild chain.
class CustomTestDeleteBottomSheet extends StatefulWidget {
  final String customTestId;
  const CustomTestDeleteBottomSheet(BuildContext context,
      {super.key, required this.customTestId});

  @override
  State<CustomTestDeleteBottomSheet> createState() =>
      _CustomTestDeleteBottomSheetState();
}

class _CustomTestDeleteBottomSheetState
    extends State<CustomTestDeleteBottomSheet> {
  bool _isDeleting = false;

  bool get _isDesktop => Platform.isWindows || Platform.isMacOS;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _deleteCustomTest() async {
    if (_isDeleting) return;
    setState(() => _isDeleting = true);
    try {
      final store = Provider.of<CustomTestCategoryStore>(context, listen: false);
      await store.onDeleteCustomTestCall(widget.customTestId);
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      store.onCustomTestListApiCall(context);
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Preserve legacy provider listen — keeps the sheet in the rebuild chain
    // when TestCategoryStore broadcasts.
    // ignore: unused_local_variable
    final store = Provider.of<TestCategoryStore>(context);

    final media = MediaQuery.of(context);
    final double bottomInset = media.viewInsets.bottom + media.padding.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              margin: _isDesktop
                  ? const EdgeInsets.symmetric(
                      horizontal: AppTokens.s16,
                      vertical: AppTokens.s20,
                    )
                  : EdgeInsets.zero,
              decoration: BoxDecoration(
                color: AppTokens.surface(context),
                borderRadius: _isDesktop
                    ? BorderRadius.circular(AppTokens.r28)
                    : const BorderRadius.only(
                        topLeft: Radius.circular(AppTokens.r28),
                        topRight: Radius.circular(AppTokens.r28),
                      ),
                boxShadow: _isDesktop
                    ? [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.s20,
                  AppTokens.s12,
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
                          decoration: BoxDecoration(
                            color: AppTokens.surface3(context),
                            borderRadius:
                                BorderRadius.circular(AppTokens.r8),
                          ),
                        ),
                      ),
                    const SizedBox(height: AppTokens.s16),
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTokens.dangerSoft(context),
                          borderRadius:
                              BorderRadius.circular(AppTokens.r16),
                        ),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: AppTokens.danger(context),
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTokens.s16),
                    Text(
                      'Delete Module',
                      textAlign: TextAlign.center,
                      style: AppTokens.titleMd(context)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppTokens.s8),
                    Text(
                      'Are you sure you want to delete this module? This action cannot be undone.',
                      textAlign: TextAlign.center,
                      style: AppTokens.body(context).copyWith(
                        color: AppTokens.ink2(context),
                      ),
                    ),
                    const SizedBox(height: AppTokens.s24),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: _isDeleting
                                  ? null
                                  : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTokens.ink(context),
                                side: BorderSide(
                                  color: AppTokens.border(context),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTokens.r12),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: AppTokens.body(context).copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTokens.ink(context),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTokens.s12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed:
                                  _isDeleting ? null : _deleteCustomTest,
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: AppTokens.danger(context),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    // ignore: deprecated_member_use
                                    AppTokens.danger(context).withOpacity(0.55),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTokens.r12),
                                ),
                              ),
                              child: _isDeleting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : Text(
                                      'Delete',
                                      style: AppTokens.body(context).copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
