import 'package:flutter/material.dart';

/// TapToDismissKeyboard — wraps a subtree so taps anywhere outside an
/// active text field unfocus + dismiss the soft keyboard.
///
/// Apple's Mail / Notes / Settings all do this. Without it, users have
/// to tap the system "done" key (or the field's own outside) to close
/// the keyboard, which is awkward inside scroll views.
///
/// Wrap the screen body once:
///
/// ```dart
/// body: TapToDismissKeyboard(child: SafeArea(child: ...))
/// ```
///
/// `behavior: HitTestBehavior.translucent` lets taps still reach
/// children (so tapping a button still works); only "empty" taps
/// unfocus.
class TapToDismissKeyboard extends StatelessWidget {
  const TapToDismissKeyboard({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        final scope = FocusScope.of(context);
        if (!scope.hasPrimaryFocus && scope.focusedChild != null) {
          scope.focusedChild?.unfocus();
        }
      },
      child: child,
    );
  }
}
