import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureKeys {
  static const _prefix = 'video_key_';
  static const _storage = FlutterSecureStorage();

  static Future<void> saveKey(String videoId, List<int> key) async {
    await _storage.write(
      key: '$_prefix$videoId',
      value: base64Encode(key),
      aOptions: const AndroidOptions(encryptedSharedPreferences: true),
      iOptions: const IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
    );
  }

  static Future<List<int>?> loadKey(String videoId) async {
    final v = await _storage.read(
      key: '$_prefix$videoId',
      aOptions: const AndroidOptions(encryptedSharedPreferences: true),
      iOptions: const IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
    );
    if (v == null) return null;
    return base64Decode(v);
    
  }

  static Future<void> deleteKey(String videoId) async {
    await _storage.delete(
      key: '$_prefix$videoId',
      aOptions: const AndroidOptions(encryptedSharedPreferences: true),
      iOptions: const IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
    );
  }
}
