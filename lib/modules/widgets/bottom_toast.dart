import 'package:flutter/material.dart';

import 'bottom_toast_overlay_container.dart';

/// BottomToast — entry point used across the app to surface a transient
/// toast-like overlay. Public surface preserved exactly:
///   • static [showBottomToastOverlay] named parameters
///     `{required BuildContext context, required String errorMessage,
///       required Color backgroundColor}` with a fixed 3000ms display
///     duration and overlay insert/remove lifecycle
class BottomToast {
  static Future<void> showBottomToastOverlay({
    required BuildContext context,
    required String errorMessage,
    required Color backgroundColor,
  }) async {
    const Duration errorMessageDisplayDuration = Duration(milliseconds: 3000);
    final OverlayState overlayState = Overlay.of(context);
    final OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => BottomToastOverlayContainer(
        backgroundColor: backgroundColor,
        errorMessage: errorMessage,
      ),
    );

    overlayState.insert(overlayEntry);
    await Future.delayed(errorMessageDisplayDuration);
    overlayEntry.remove();
  }
}
