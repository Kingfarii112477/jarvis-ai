import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );
});

/// Thin, typed wrapper around [FlutterSecureStorage]. Anything that must
/// never appear in plaintext on disk — the n8n webhook URL, API keys, the
/// Hive database encryption key, biometric-lock preference — goes through
/// here rather than SharedPreferences.
class SecureStorageService {
  SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  static const _keyWebhookUrl = 'n8n_webhook_url';
  static const _keyApiKey = 'n8n_api_key';
  static const _keyUserId = 'jarvis_user_id';
  static const _keyHiveCipherKey = 'jarvis_hive_cipher_key';
  static const _keyBiometricLockEnabled = 'biometric_lock_enabled';

  Future<String?> get webhookUrl => _storage.read(key: _keyWebhookUrl);
  Future<void> setWebhookUrl(String value) => _storage.write(key: _keyWebhookUrl, value: value);

  Future<String?> get apiKey => _storage.read(key: _keyApiKey);
  Future<void> setApiKey(String value) => _storage.write(key: _keyApiKey, value: value);

  Future<String?> get userId => _storage.read(key: _keyUserId);
  Future<void> setUserId(String value) => _storage.write(key: _keyUserId, value: value);

  Future<String?> get hiveCipherKeyBase64 => _storage.read(key: _keyHiveCipherKey);
  Future<void> setHiveCipherKeyBase64(String value) =>
      _storage.write(key: _keyHiveCipherKey, value: value);

  Future<bool> get biometricLockEnabled async =>
      (await _storage.read(key: _keyBiometricLockEnabled)) == 'true';
  Future<void> setBiometricLockEnabled(bool value) =>
      _storage.write(key: _keyBiometricLockEnabled, value: value.toString());

  Future<void> clearAll() => _storage.deleteAll();
}
