// ════════════════════════════════════════════════════════════════════
// AppUpdateService — auto-update check + UI status reporter
// ════════════════════════════════════════════════════════════════════
//
// Two responsibilities:
//
//   1. Compare the *installed* app version (from package_info_plus)
//      against the *latest store* version (from `flutter_upgrade_version`
//      which queries Play Console + App Store Connect).
//
//   2. Expose a typed result the UI can render as:
//        "vCurrent → vLatest"
//        with an "Update now" button that opens the store listing OR,
//        on Android, performs the in-app immediate-update flow when
//        the package is integrated.
//
// Why both `upgrader` and `flutter_upgrade_version`?
//
//   • `upgrader: ^12.5.0` already in pubspec ships a one-shot
//     dialog/page UI but doesn't expose a typed "is update available"
//     result for our own UI. Also doesn't tell us *what* version is
//     out there.
//
//   • `flutter_upgrade_version: ^1.1.8` is the metadata fetcher —
//     scrapes the store metadata, gives us {currentVersion,
//     storeVersion, releaseNotes, storeUrl, immediateUpdateAvailable}.
//
// We use the metadata fetcher for the "v12.1.1 → v12.2.0" status
// surface, and fall back to `upgrader`'s page UI when the user taps
// "Update now" but the platform can't auto-install.
//
// Big-bang Apple-like UX:
//   • App boot → silent check
//   • If update available + non-mandatory → small snackbar prompt
//     "Update v12.2.0 available · Update now"
//   • If mandatory (>= min_supported_version from /api/settings) →
//     full-screen blocking gate (handled by app_version_check.dart,
//     which calls into this service).

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_upgrade_version/flutter_upgrade_version.dart' as fuv;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateStatus {
  /// Currently installed version, e.g. "12.1.1".
  final String currentVersion;

  /// Latest version available on the store, e.g. "12.2.0". Null when
  /// the metadata fetch failed (offline / package error).
  final String? latestVersion;

  /// True when [latestVersion] is strictly newer than [currentVersion].
  /// False if equal, lower, or null.
  final bool updateAvailable;

  /// True when the backend's `min_supported_version` is higher than
  /// [currentVersion] — caller should hard-block until updated.
  /// Computed by `app_version_check.dart` using the /api/settings
  /// payload; this service stays focused on the store metadata path.
  final bool mandatory;

  /// Direct deep link to the store listing — used as the fallback when
  /// in-app update isn't supported (e.g. iOS, sideloaded APK).
  final String? storeUrl;

  /// Release notes from the store listing, if surfaced. Useful for a
  /// "what's new" sheet on the update prompt.
  final String? releaseNotes;

  AppUpdateStatus({
    required this.currentVersion,
    this.latestVersion,
    this.updateAvailable = false,
    this.mandatory = false,
    this.storeUrl,
    this.releaseNotes,
  });

  /// "v12.1.1 → v12.2.0" UI hint (or just "v12.1.1" when up to date).
  String get versionLabel {
    if (latestVersion == null || !updateAvailable) return 'v$currentVersion';
    return 'v$currentVersion → v$latestVersion';
  }

  /// "v12.2.0 available" — for snackbar / banner copy.
  String? get availableLabel {
    if (!updateAvailable || latestVersion == null) return null;
    return 'v$latestVersion available';
  }

  AppUpdateStatus copyWith({bool? mandatory}) => AppUpdateStatus(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        updateAvailable: updateAvailable,
        mandatory: mandatory ?? this.mandatory,
        storeUrl: storeUrl,
        releaseNotes: releaseNotes,
      );
}

class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._();
  AppUpdateService._();
  factory AppUpdateService() => _instance;

  AppUpdateStatus? _cached;

  /// Read the installed version + ask the store for the latest.
  /// Caches the result for one app-session — call `invalidate()` if
  /// you want to refetch (e.g. after a "check now" tap).
  ///
  /// Note: `flutter_upgrade_version 1.1.8` only exposes
  /// [getiOSStoreVersion] (the iTunes lookup endpoint). Android Play
  /// Store has no equivalent unauthenticated metadata endpoint via
  /// this lib in 1.1.8, so on Android we return the current version
  /// with [updateAvailable]=false here and let
  /// [AppUpdateServiceV2.check] decide via the backend
  /// `/api/app-meta/version-gate` whether an update is needed.
  Future<AppUpdateStatus> check() async {
    final cached = _cached;
    if (cached != null) return cached;

    final pkg = await PackageInfo.fromPlatform();
    final current = pkg.version; // e.g. "12.1.1"

    String? latest;
    String? notes;
    String? url;
    bool available = false;

    try {
      if (Platform.isIOS) {
        // flutter_upgrade_version uses its own PackageInfo wrapper —
        // bridge from package_info_plus's PackageInfo to it.
        final fuvPkg = fuv.PackageInfo(
          appName: pkg.appName,
          packageName: pkg.packageName,
          version: pkg.version,
          buildNumber: pkg.buildNumber,
        );
        final info = await fuv.UpgradeVersion.getiOSStoreVersion(
          packageInfo: fuvPkg,
        ).timeout(const Duration(seconds: 4));
        // VersionInfo isn't nullable in this lib; check the returned
        // storeVersion string instead — empty means lookup failed.
        if (info.storeVersion.isNotEmpty) {
          latest = info.storeVersion;
          notes = info.releaseNotes;
          url = info.appStoreLink;
          available = info.canUpdate;
        }
      }
      // Android: relying on AppUpdateServiceV2's /api/app-meta gate.
    } catch (_) {
      // Offline / store metadata fetch error — stay silent. The
      // status we return tells the UI we couldn't determine, which
      // it should treat as "no update available" rather than blocking.
    }

    _cached = AppUpdateStatus(
      currentVersion: current,
      latestVersion: latest,
      updateAvailable: available,
      storeUrl: url,
      releaseNotes: notes,
    );
    return _cached!;
  }

  /// Drop the cached result so the next `check()` refetches.
  void invalidate() => _cached = null;

  /// Open the store listing for a manual update. Returns true when the
  /// system handed off to the store, false otherwise.
  Future<bool> openStore() async {
    final status = _cached ?? await check();
    final url = status.storeUrl;
    if (url == null || url.isEmpty) return false;
    return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  /// Render a small Apple-like "update available" banner below the
  /// app bar of the home screen. Tap → opens store. Caller embeds
  /// the returned widget inside any column; widget renders nothing
  /// when no update is pending.
  Widget banner(BuildContext context) {
    return FutureBuilder<AppUpdateStatus>(
      future: check(),
      builder: (ctx, snap) {
        if (!snap.hasData || !(snap.data?.updateAvailable ?? false)) {
          return const SizedBox.shrink();
        }
        final s = snap.data!;
        return _UpdateBanner(
          label: s.availableLabel ?? 'New version',
          onTap: () => openStore(),
        );
      },
    );
  }
}

class _UpdateBanner extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _UpdateBanner({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.primary.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Icon(Icons.system_update_rounded, size: 18, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$label · Tap to update',
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}
