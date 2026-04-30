import 'package:flutter/material.dart';

import 'app_feedback.dart';

/// safeAsync — wrap any async action so:
///  • setState is called only when [State.mounted].
///  • errors get surfaced via [AppFeedback.error] with a friendly
///    fallback message.
///  • a returned value is given back to the caller for chaining.
///
/// Typical usage in a State<T>:
///
/// ```dart
/// await safeAsync<void>(
///   state: this,
///   action: () => store.fetchProgress(),
///   onError: 'Could not load progress',
/// );
/// ```
///
/// Returns the future's value, or null on error.
Future<R?> safeAsync<R>({
  required State state,
  required Future<R> Function() action,
  String onError = "Something went wrong. Please try again.",
  void Function()? onStart,
  void Function()? onDone,
  bool showErrorToUser = true,
}) async {
  try {
    if (state.mounted) onStart?.call();
    final result = await action();
    if (!state.mounted) return null;
    onDone?.call();
    return result;
  } catch (e, st) {
    debugPrint('safeAsync caught: $e\n$st');
    if (!state.mounted) return null;
    onDone?.call();
    if (showErrorToUser) {
      AppFeedback.error(state.context, onError);
    }
    return null;
  }
}
