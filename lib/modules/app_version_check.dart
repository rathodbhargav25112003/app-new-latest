
import 'dart:io'; // For platform detection
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionChecker {
  final String androidPackageName;
  final String iosAppId;

  AppVersionChecker({required this.androidPackageName, required this.iosAppId});

  Future<Map<String, dynamic>> checkVersion() async {
    try {
      // Get the current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      debugPrint("current version$currentVersion");
      // Variables to store live version and store URL
      String liveVersion = '';
      String storeUrl = '';

      if (Platform.isAndroid && androidPackageName.isNotEmpty) {
        // Fetch Android live version
        liveVersion = await _getAndroidVersion();
        storeUrl =
            'https://play.google.com/store/apps/details?id=$androidPackageName';
      } else if (Platform.isIOS && iosAppId.isNotEmpty) {
        // Fetch iOS live version
        liveVersion = await _getIOSVersion();
        storeUrl = 'c$iosAppId';
      } else {
        throw Exception('Unsupported platform or missing identifiers.');
      }

      // Compare versions
      final needsUpdate = _compareVersions(currentVersion, liveVersion);

      return {
        'currentVersion': currentVersion,
        'liveVersion': liveVersion,
        'needsUpdate': needsUpdate,
        'storeUrl': storeUrl,
      };
    } catch (e) {
      throw Exception('Error checking app version: $e');
    }
  }

  Future<String> _getAndroidVersion() async {
    final url =
        'https://play.google.com/store/apps/details?id=$androidPackageName';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final document = response.body;
      final regex = RegExp(r'Current Version.*?>([\d.]+)<');
      final match = regex.firstMatch(document);
      if (match != null) {
        return match.group(1)!;
      }
    }
    throw Exception('Failed to fetch Android version.');
  }

  Future<String> _getIOSVersion() async {
    final url = 'https://itunes.apple.com/lookup?id=$iosAppId';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['resultCount'] > 0) {
        return data['results'][0]['version'];
      }
    }
    throw Exception('Failed to fetch iOS version.');
  }

  bool _compareVersions(String currentVersion, String liveVersion) {
    final current = currentVersion.split('.').map(int.parse).toList();
    final live = liveVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < live.length; i++) {
      if (i >= current.length || live[i] > current[i]) return true;
      if (live[i] < current[i]) return false;
    }
    return false;
  }
}
