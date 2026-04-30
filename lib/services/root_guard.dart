  import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

class RootGuard {
  // Lightweight root detection for Android.
  // Returns true if common root indicators are found.
  static Future<bool> isDeviceRooted() async {
    try {
      if (!Platform.isAndroid) return false; // iOS: handle later if needed

      // Check common su paths
      final suPaths = <String>[
        '/system/bin/su',
        '/system/xbin/su',
        '/sbin/su',
        '/system/sd/xbin/su',
        '/system/bin/failsafe/su',
        '/data/local/su',
        '/data/local/xbin/su',
        '/data/local/bin/su',
        '/system/app/Superuser.apk',
        '/system/app/SuperSU.apk',
      ];
      for (final p in suPaths) {
        if (await File(p).exists()) {
          return true;
        }
      }

      // Try `which su`
      try {
        final result = await Process.run('which', ['su']).timeout(
          const Duration(milliseconds: 400),
          onTimeout: () => ProcessResult(0, -1, '', ''),
        );
        if (result.exitCode == 0 && (result.stdout?.toString().trim().isNotEmpty ?? false)) {
          return true;
        }
      } catch (_) {}

      // Try executing `su -c id` (may hang/deny). Keep it very short.
      try {
        final result = await Process.run('su', ['-c', 'id']).timeout(
          const Duration(milliseconds: 300),
          onTimeout: () => ProcessResult(0, -1, '', ''),
        );
        if (result.exitCode == 0 && result.stdout.toString().contains('uid=0')) {
          return true;
        }
      } catch (_) {}

      return false;
    } catch (_) {
      return false;
    }
  }

  // Wipe sensitive app data: secure storage, app documents, and temp/cache directories.
  static Future<void> wipeAppData() async {
    // 1) Secure storage: remove keys and secrets
    try {
      const storage = FlutterSecureStorage();
      await storage.deleteAll(
        aOptions: const AndroidOptions(encryptedSharedPreferences: true),
        iOptions: const IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      );
    } catch (_) {}

    // 2) Files in app document and temp directories
    try {
      final docs = await getApplicationDocumentsDirectory();
      await _deleteDirContents(docs);
    } catch (_) {}
    try {
      final tmp = await getTemporaryDirectory();
      await _deleteDirContents(tmp);
    } catch (_) {}
  }

  static Future<void> _deleteDirContents(Directory dir) async {
    if (!await dir.exists()) return;
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        try {
          await entity.delete(recursive: true);
        } catch (_) {}
      }
    } catch (_) {}
  }

  // Quit application safely
  static Future<void> quitApp() async {
    try {
      SystemNavigator.pop();
    } catch (_) {
      // Fallback in debug/test environments
      try { exit(0); } catch (_) {}
    }
  }
}
