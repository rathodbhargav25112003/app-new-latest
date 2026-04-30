import 'package:flutter/material.dart';

import 'app_tokens.dart';
import 'haptics.dart';

/// AppRefresh — opinionated wrapper around [RefreshIndicator] so every
/// pull-to-refresh in the app uses the same colour, fires a haptic at
/// the activation moment, and is keyboard-safe.
///
/// Usage:
/// ```dart
/// body: AppRefresh(
///   onRefresh: () => store.fetchAgain(),
///   child: ListView(...),
/// )
/// ```
///
/// The child must be a scrollable, otherwise the indicator never
/// activates — that's by design from Flutter's RefreshIndicator.
class AppRefresh extends StatelessWidget {
  const AppRefresh({
    Key? key,
    required this.onRefresh,
    required this.child,
  }) : super(key: key);

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTokens.accent(context),
      backgroundColor: AppTokens.surface(context),
      strokeWidth: 2.4,
      displacement: 32,
      onRefresh: () async {
        Haptics.light();
        await onRefresh();
      },
      child: child,
    );
  }
}
