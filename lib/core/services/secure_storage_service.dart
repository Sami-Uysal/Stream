import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _traktAccessToken = 'trakt_access_token';
  static const String _traktRefreshToken = 'trakt_refresh_token';
  static const String _traktExpiresAt = 'trakt_expires_at';
  static const String _traktUsername = 'trakt_username';

  static const String _simklAccessToken = 'simkl_access_token';
  static const String _simklUsername = 'simkl_username';
  static const String _activeSyncProvider = 'active_sync_provider';

  // TRAKT

  static Future<void> saveTraktAccessToken(String token) async {
    await _storage.write(key: _traktAccessToken, value: token);
  }

  static Future<String?> getTraktAccessToken() async {
    return await _storage.read(key: _traktAccessToken);
  }

  static Future<void> saveTraktRefreshToken(String token) async {
    await _storage.write(key: _traktRefreshToken, value: token);
  }

  static Future<String?> getTraktRefreshToken() async {
    return await _storage.read(key: _traktRefreshToken);
  }

  static Future<void> saveTraktExpiresAt(int timestamp) async {
    await _storage.write(key: _traktExpiresAt, value: timestamp.toString());
  }

  static Future<int?> getTraktExpiresAt() async {
    final value = await _storage.read(key: _traktExpiresAt);
    return value != null ? int.tryParse(value) : null;
  }

  static Future<void> saveTraktUsername(String username) async {
    await _storage.write(key: _traktUsername, value: username);
  }

  static Future<String?> getTraktUsername() async {
    return await _storage.read(key: _traktUsername);
  }

  static Future<bool> isTraktTokenExpired() async {
    final expiresAt = await getTraktExpiresAt();
    if (expiresAt == null) return true;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= (expiresAt - 3600);
  }

  static Future<void> clearTraktTokens() async {
    await _storage.delete(key: _traktAccessToken);
    await _storage.delete(key: _traktRefreshToken);
    await _storage.delete(key: _traktExpiresAt);
    await _storage.delete(key: _traktUsername);
  }

  // SIMKL

  static Future<void> saveSimklAccessToken(String token) async {
    await _storage.write(key: _simklAccessToken, value: token);
  }

  static Future<String?> getSimklAccessToken() async {
    return await _storage.read(key: _simklAccessToken);
  }

  static Future<void> saveSimklUsername(String username) async {
    await _storage.write(key: _simklUsername, value: username);
  }

  static Future<String?> getSimklUsername() async {
    return await _storage.read(key: _simklUsername);
  }

  static Future<void> clearSimklTokens() async {
    await _storage.delete(key: _simklAccessToken);
    await _storage.delete(key: _simklUsername);
  }

  // UTILITY

  static Future<void> saveActiveSyncProvider(String provider) async {
    await _storage.write(key: _activeSyncProvider, value: provider);
  }

  static Future<String?> getActiveSyncProvider() async {
    return await _storage.read(key: _activeSyncProvider);
  }

  static Future<void> clearAll() async {
    await clearTraktTokens();
    await clearSimklTokens();
    await _storage.delete(key: _activeSyncProvider);
  }
}
