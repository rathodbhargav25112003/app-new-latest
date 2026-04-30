import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// AppBottomSheet — house-rules bottom sheet shell.
///
/// Always:
///  • Top corners rounded to [AppTokens.r28].
///  • Drag handle pill (44×4) at top.
///  • Background = [AppTokens.surface].
///  • Padding for safe-area + content gutter.
///
/// Use the static helper [show] to spin one up:
///
/// ```dart
/// AppBottomSheet.show(
///   context,
///   title: 'Confirm logout',
///   builder: (ctx) => Column(...),
/// );
/// ```
///
/// Or wrap any custom child manually with [AppBottomSheetShell] if you
/// already have your own [showModalBottomSheet] call.
class AppBottomSheet {
  AppBottomSheet._();

  /// Open a sheet whose body is built by [builder].
  ///
  /// [title] becomes a centered titleSm text under the drag handle.
  /// Pass `null` to omit the title strip.
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget Function(BuildContext) builder,
    String? title,
    bool isScrollControlled = true,
    bool useRootNavigator = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useRootNavigator: useRootNavigator,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) => AppBottomSheetShell(
        title: title,
        child: builder(ctx),
      ),
    );
  }
}

/// AppBottomSheetShell — the visual chrome for a sheet.
class AppBottomSheetShell extends StatelessWidget {
  const AppBottomSheetShell({
    Key? key,
    required this.child,
    this.title,
  }) : super(key: key);

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTokens.r28),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle pill.
            Container(
              margin: const EdgeInsets.only(
                top: AppTokens.s12,
                bottom: AppTokens.s8,
              ),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppTokens.border(context),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            if (title != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.s16,
                  4,
                  AppTokens.s16,
                  AppTokens.s8,
                ),
                child: Text(
                  title!,
                  style: AppTokens.titleMd(context),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}
