// ════════════════════════════════════════════════════════════════════
// SessionManagerService — multi-device session control client
// ════════════════════════════════════════════════════════════════════
//
// Talks to the backend's /api/auth/sessions API. Used by:
//   • the new "Sessions" screen under Profile → Security
//   • the cold-boot flow that surfaces "Signed out from your tablet"
//     when the server tells us this device's claim revoked another
//
// Quota policy (enforced server-side; client just shows it):
//   1 active session per class (mobile / tablet / desktop). When the
//   student logs in from a 4th device in the same class, the OLDEST
//   session in that class is revoked LIFO.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/constants.dart' show baseUrl;
import '../api_service/api_service.dart' show ApiService;

class DeviceSession {
  final String deviceId;
  final String platform;          // raw e.g. "iosMobile", "androidTablet"
  final String deviceClass;       // 'mobile' | 'tablet' | 'desktop'
  final String deviceName;
  final DateTime? lastActiveAt;
  final String lastActiveRelative;

  DeviceSession({
    required this.deviceId,
    required this.platform,
    required this.deviceClass,
    required this.deviceName,
    this.lastActiveAt,
    required this.lastActiveRelative,
  });

  factory DeviceSession.fromJson(Map<String, dynamic> j) => DeviceSession(
        deviceId: j['device_id']?.toString() ?? '',
        platform: (j['platform'] as String?) ?? '',
        deviceClass: (j['device_class'] as String?) ?? 'mobile',
        deviceName: (j['device_name'] as String?) ?? '',
        lastActiveAt: j['last_active_at'] != null
            ? DateTime.tryParse(j['last_active_at'].toString())
            : null,
        lastActiveRelative: (j['last_active_relative'] as String?) ?? '',
      );
}

class SessionManagerService {
  final http.Client _http;
  SessionManagerService({http.Client? client})
      : _http = client ?? http.Client();

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final info = await ApiService().getDeviceInfo();
    return {
      'Content-Type': 'application/json',
      'Authorization': token,
      'X-Device-Id': info['device_id'] ?? 'unknown',
    };
  }

  Future<List<DeviceSession>> list() async {
    final url = Uri.parse('$baseUrl/auth/sessions');
    final res = await _http.get(url, headers: await _headers());
    if (res.statusCode != 200) return [];
    final body = (jsonDecode(res.body) as Map);
    final data = body['data'] is Map ? body['data'] : body;
    final list = (data['sessions'] as List?) ?? [];
    return list
        .map((j) => DeviceSession.fromJson((j as Map).cast<String, dynamic>()))
        .toList();
  }

  /// Revoke a single session by device id. Use from the Sessions
  /// screen's swipe-to-delete or the per-row "Sign out" button.
  Future<bool> revoke(String deviceId) async {
    final url = Uri.parse('$baseUrl/auth/sessions/$deviceId');
    final res = await _http.delete(url, headers: await _headers());
    return res.statusCode == 200;
  }

  /// "Sign out from all other devices" button. Server skips the caller
  /// based on the X-Device-Id header.
  Future<int> logoutOthers() async {
    final url = Uri.parse('$baseUrl/auth/sessions/logout-others');
    final res = await _http.post(url, headers: await _headers(), body: '{}');
    if (res.statusCode != 200) return 0;
    final body = (jsonDecode(res.body) as Map);
    final data = body['data'] is Map ? body['data'] : body;
    return (data['revoked'] as num?)?.toInt() ?? 0;
  }
}
