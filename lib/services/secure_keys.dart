import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureKeys {
  static const _prefix = 'video_key_';
  static const _storage = FlutterSecureStorage();

  /// In-memory cache so repeated loads of the same key skip the OS
  /// Keychain / KeyStore IPC entirely (saves ~50-500ms per call).
  static final Map<String, List<int>> _memCache = {};

  static Future<void> saveKey(String videoId, List<int> key) async {
    await _storage.write(
      key: '$_prefix$videoId',
      value: base64Encode(key),
      aOptions: const AndroidOptions(encryptedSharedPreferences: true),
      iOptions: const IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
    );
    _memCache[videoId] = key;
  }

  static Future<List<int>?> loadKey(String videoId) async {
    // Fast path: return from in-memory cache.
    final cached = _memCache[videoId];
    if (cached != null) return cached;

    final v = await _storage.read(
      key: '$_prefix$videoId',
      aOptions: const AndroidOptions(encryptedSharedPreferences: true),
      iOptions: const IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
    );
    if (v == null) return null;
    final key = base64Decode(v);
    _memCache[videoId] = key;
    return key;
  }

  static Future<void> deleteKey(String videoId) async {
    _memCache.remove(videoId);
    await _storage.delete(
      key: '$_prefix$videoId',
      aOptions: const AndroidOptions(encryptedSharedPreferences: true),
      iOptions: const IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
    );
  }
}
