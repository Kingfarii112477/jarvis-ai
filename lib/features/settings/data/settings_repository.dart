import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/hive_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/app_settings.dart';

/// Non-sensitive preferences live in Hive; anything sensitive (webhook
/// URL, API key, user id, biometric-lock flag) is delegated to
/// [SecureStorageService] instead of being duplicated here.
class SettingsRepository {
  SettingsRepository(this._box, this._secureStorage);

  final Box _box;
  final SecureStorageService _secureStorage;
  static const _key = 'app_settings';

  AppSettings load() {
    final raw = _box.get(_key) as Map?;
    if (raw == null) return const AppSettings();
    return AppSettings.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<void> save(AppSettings settings) => _box.put(_key, settings.toJson());

  SecureStorageService get secure => _secureStorage;
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(
    ref.watch(hiveServiceProvider).settingsBox,
    ref.watch(secureStorageProvider),
  );
});
