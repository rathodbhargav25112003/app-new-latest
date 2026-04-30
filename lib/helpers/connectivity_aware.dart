import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// ConnectivityAware — mixin for any State<T> that wants to auto-refetch
/// when connectivity returns.
///
/// Usage:
/// ```dart
/// class _MyScreenState extends State<MyScreen> with ConnectivityAware {
///   @override
///   Future<void> onReconnect() async => await _refresh();
/// }
/// ```
///
/// The mixin handles subscription lifecycle in initState/dispose. It
/// triggers [onReconnect] whenever the device transitions from no
/// connectivity to any connectivity, debounced to a single call per
/// transition (some platforms emit duplicates).
mixin ConnectivityAware<T extends StatefulWidget> on State<T> {
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _wasOffline = false;

  /// Called when connectivity returns. Override with your refresh logic.
  Future<void> onReconnect();

  @override
  void initState() {
    super.initState();
    _sub = Connectivity()
        .onConnectivityChanged
        .listen(_handleConnectivityChange);
    _bootstrapInitialState();
  }

  Future<void> _bootstrapInitialState() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _wasOffline = _isOfflineList(results);
    } catch (_) {
      _wasOffline = false;
    }
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final isOffline = _isOfflineList(results);
    if (_wasOffline && !isOffline) {
      _wasOffline = false;
      if (mounted) onReconnect();
    } else if (!_wasOffline && isOffline) {
      _wasOffline = true;
    }
  }

  bool _isOfflineList(List<ConnectivityResult> results) {
    if (results.isEmpty) return true;
    return results.every((r) => r == ConnectivityResult.none);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
