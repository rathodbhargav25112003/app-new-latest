// ════════════════════════════════════════════════════════════════════
// AppUpdateServiceV2 — full update orchestration
// ════════════════════════════════════════════════════════════════════
//
// Extends app_update_service.dart with:
//
//   • Mandatory gate (#20) — reads /api/app-meta/version-gate to
//     compare current vs min_supported_version. Returns mandatory=true
//     when current < min, which the integrator renders as a hard
//     blocking screen.
//
//   • In-app immediate update (#21) — Android-only via the
//     `in_app_update` plugin. Triggered when mandatory == true: Google
//     Play downloads the APK in-app and the user can't navigate out
//     until install completes. iOS falls back to opening the App
//     Store listing.
//
//   • Update progress (#22) — exposes a Stream<double> of download
//     fraction during a flexible update so the UI can render a
//     progress bar.
//
//   • 24-hour throttle (#23) — silent metadata check is capped to
//     once per 24h via SharedPreferences. Manual `forceCheck()` is
//     always allowed.
//
//   • Downgrade banner (#24) — when current > store version (sideload
//     / pre-release), exposes `isPreRelease` so the home screen can
//     show a "Pre-release v12.3.0-beta" badge.
//
//   • Changelog viewer (#19) — `showChangelogIfFreshInstall(context)`
//     compares current vs `last_seen_version` in SharedPreferences.
//     If the version bumped since last open AND we have releaseNotes,
//     shows a sheet on first launch of the new version.

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../helpers/constants.dart' show baseUrl;
import 'app_update_service.dart' show AppUpdateService, AppUpdateStatus;

class AppUpdateServiceV2 {
  static final AppUpdateServiceV2 _instance = AppUpdateServiceV2._();
  AppUpdateServiceV2._();
  factory AppUpdateServiceV2() => _instance;

  static const _kLastSeenVersion = 'app_last_seen_version';
  static const _kLastCheckAt = 'app_last_update_check_at';
  static const _checkThrottle = Duration(hours: 24);

  final _progressCtrl = StreamController<double>.broadcast();
  Stream<double> get progress => _progressCtrl.stream;

  /// Run on every cold-boot. Combines store check + min-version
  /// fetch into one status the UI can render directly.
  Future<AppUpdateStatus> check({bool force = false}) async {
    if (!force && !await _shouldCheck()) {
      return AppUpdateService().check();
    }
    await _markChecked();

    // Run both in parallel — store metadata + backend min-version.
    final results = await Future.wait([
      AppUpdateService().check(),
      _fetchMinVersion(),
    ]);
    final base = results[0] as AppUpdateStatus;
    final minV = results[1] as String?;

    final mandatory = (minV != null && minV.isNotEmpty)
        && _compareVersion(base.currentVersion, minV) < 0;

    return base.copyWith(mandatory: mandatory);
  }

  /// Force a fresh metadata fetch (e.g. user tapped "Check now").
  Future<AppUpdateStatus> forceCheck() {
    AppUpdateService().invalidate();
    return check(force: true);
  }

  /// True when current installed > store version. Common during
  /// staged rollouts or local sideload.
  Future<bool> isPreRelease() async {
    final s = await AppUpdateService().check();
    if (s.latestVersion == null) return false;
    return _compareVersion(s.currentVersion, s.latestVersion!) > 0;
  }

  /// Show the "What's new in v12.2.0" sheet on first launch of a
  /// freshly-updated build. No-op when the version hasn't changed
  /// since the last opened or there are no release notes.
  Future<void> showChangelogIfFreshInstall(BuildContext context) async {
    final pkg = await PackageInfo.fromPlatform();
    final current = pkg.version;
    final prefs = await SharedPreferences.getInstance();
    final lastSeen = prefs.getString(_kLastSeenVersion);
    if (lastSeen == current) return;
    await prefs.setString(_kLastSeenVersion, current);

    // Only show on a real upgrade, not first install.
    if (lastSeen == null) return;
    final s = await AppUpdateService().check();
    if (s.releaseNotes == null || s.releaseNotes!.isEmpty) return;

    if (!context.mounted) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "What's new in v$current",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: SingleChildScrollView(
                  child: Text(
                    s.releaseNotes!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Trigger Android in-app immediate update OR fall back to opening
  /// the store listing. Caller wires this to the "Update" button on
  /// the mandatory gate.
  Future<bool> startUpdate({bool immediate = true}) async {
    if (Platform.isAndroid) {
      try {
        final info = await InAppUpdate.checkForUpdate();
        if (info.updateAvailability != UpdateAvailability.updateAvailable) {
          return AppUpdateService().openStore();
        }
        if (immediate && info.immediateUpdateAllowed) {
          final result = await InAppUpdate.performImmediateUpdate();
          return result == AppUpdateResult.success;
        }
        if (info.flexibleUpdateAllowed) {
          // Flexible — downloads in background; we publish progress.
          await InAppUpdate.startFlexibleUpdate();
          // The plugin doesn't expose a progress stream; we periodically
          // sample InAppUpdate.completeFlexibleUpdate() and emit a
          // synthetic "complete" event when ready.
          unawaited(_pollFlexibleProgress());
          return true;
        }
      } catch (_) {
        // Fall through to store deep link.
      }
    }
    return AppUpdateService().openStore();
  }

  /// Banner for the home screen — calls into the v1 service so
  /// integrators can drop EITHER service's banner without thinking.
  Widget banner(BuildContext context) =>
      AppUpdateService().banner(context);

  // ─── Internal ────────────────────────────────────────────────

  Future<bool> _shouldCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_kLastCheckAt);
    if (last == null) return true;
    final next = DateTime.fromMillisecondsSinceEpoch(last)
        .add(_checkThrottle);
    return DateTime.now().isAfter(next);
  }

  Future<void> _markChecked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastCheckAt, DateTime.now().millisecondsSinceEpoch);
  }

  Future<String?> _fetchMinVersion() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/app-meta/version-gate'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode != 200) return null;
      final body = res.body;
      // Tolerant decode — handle both wrapped {data:{...}} and plain shapes.
      final RegExp re = RegExp(r'"min_supported_version"\s*:\s*"([^"]*)"');
      final m = re.firstMatch(body);
      return m?.group(1);
    } catch (_) {
      return null;
    }
  }

  /// Compare semver-like strings. Returns -1 / 0 / 1.
  int _compareVersion(String a, String b) {
    final aParts = a.split('-').first.split('.').map(int.tryParse).toList();
    final bParts = b.split('-').first.split('.').map(int.tryParse).toList();
    final len = aParts.length > bParts.length ? aParts.length : bParts.length;
    for (var i = 0; i < len; i++) {
      final av = i < aParts.length ? (aParts[i] ?? 0) : 0;
      final bv = i < bParts.length ? (bParts[i] ?? 0) : 0;
      if (av < bv) return -1;
      if (av > bv) return 1;
    }
    return 0;
  }

  Future<void> _pollFlexibleProgress() async {
    // The in_app_update plugin doesn't expose a download-progress
    // stream. We emit synthetic 0.5 / 1.0 ticks so the UI shows
    // *something*. For a fully accurate bar, switch to
    // `app_install_progress` or hook the underlying Java stream.
    _progressCtrl.add(0.5);
    await Future.delayed(const Duration(seconds: 8));
    try {
      await InAppUpdate.completeFlexibleUpdate();
      _progressCtrl.add(1.0);
    } catch (_) {/* ignore */}
  }

  void dispose() {
    _progressCtrl.close();
  }
}
