// ════════════════════════════════════════════════════════════════════
// ProctorService — fullscreen lock + tab-switch / app-switch detection
// ════════════════════════════════════════════════════════════════════
//
// One service the exam screen calls to:
//   • Lock to fullscreen / immersive mode (Android + iOS) and prevent
//     the system bar gestures from being trivially triggered.
//   • Track app-pause events as "switches" — every time the user
//     backgrounds the app during a mock, we count it. Counts are
//     reported back to the host via [onSwitch] so they can be
//     attached to the heartbeat metadata or surfaced in the report.
//
// Web-specific tab-switch detection (visibilitychange) is left to a
// platform-specific shim — flutter_web_plugins or `dart:html` — added
// only when web build is needed. The mobile path here covers 95% of
// users.
//
// No new pubspec dependencies. Uses Flutter's SystemChrome only.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProctorService with WidgetsBindingObserver {
  /// Called every time the app moves to background while proctoring
  /// is active. Caller decides what to do — e.g. increment a counter
  /// the next heartbeat ships in metadata.
  final void Function(int totalSwitches) onSwitch;

  ProctorService({required this.onSwitch});

  bool _active = false;
  int _switchCount = 0;
  int get switchCount => _switchCount;

  /// Begin proctoring — enter immersive fullscreen and start watching
  /// for backgrounding events. Call from the exam screen's initState
  /// when the attempt starts.
  Future<void> begin() async {
    if (_active) return;
    _active = true;
    WidgetsBinding.instance.addObserver(this);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  /// End proctoring — restore system UI and stop watching.
  Future<void> end() async {
    if (!_active) return;
    _active = false;
    WidgetsBinding.instance.removeObserver(this);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void resetCount() {
    _switchCount = 0;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_active) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _switchCount += 1;
      onSwitch(_switchCount);
    }
  }
}
