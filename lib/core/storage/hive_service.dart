import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../config/app_config.dart';
import '../utils/app_logger.dart';
import 'secure_storage_service.dart';

/// Bootstraps Hive with an AES encryption key held in secure storage, and
/// opens every box the app needs up front. Domain models are stored as
/// plain `Map<String, dynamic>` (via each model's `toJson`/`fromJson`)
/// rather than generated `TypeAdapter`s — one less codegen pipeline, and
/// it keeps persistence decoupled from the freezed model internals.
class HiveService {
  HiveService(this._secureStorage);

  final SecureStorageService _secureStorage;

  late final Box chatBox;
  late final Box tasksBox;
  late final Box memoryBox;
  late final Box automationBox;
  late final Box knowledgeBox;
  late final Box analyticsBox;
  late final Box settingsBox;
  late final Box outboxBox;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();

    final cipher = await _resolveCipher();

    chatBox = await Hive.openBox(AppConfig.boxChat, encryptionCipher: cipher);
    tasksBox = await Hive.openBox(AppConfig.boxTasks, encryptionCipher: cipher);
    memoryBox = await Hive.openBox(AppConfig.boxMemory, encryptionCipher: cipher);
    automationBox = await Hive.openBox(AppConfig.boxAutomation, encryptionCipher: cipher);
    knowledgeBox = await Hive.openBox(AppConfig.boxKnowledge, encryptionCipher: cipher);
    analyticsBox = await Hive.openBox(AppConfig.boxAnalytics, encryptionCipher: cipher);
    settingsBox = await Hive.openBox(AppConfig.boxSettings, encryptionCipher: cipher);
    outboxBox = await Hive.openBox(AppConfig.boxOutbox, encryptionCipher: cipher);

    _initialized = true;
    AppLogger.info('Hive initialized with 8 encrypted boxes');
  }

  Future<HiveAesCipher> _resolveCipher() async {
    var keyBase64 = await _secureStorage.hiveCipherKeyBase64;
    if (keyBase64 == null) {
      final key = Hive.generateSecureKey();
      keyBase64 = base64UrlEncode(key);
      await _secureStorage.setHiveCipherKeyBase64(keyBase64);
      return HiveAesCipher(key);
    }
    return HiveAesCipher(base64Url.decode(keyBase64));
  }
}

final hiveServiceProvider = Provider<HiveService>((ref) {
  throw UnimplementedError('HiveService must be overridden in main() after init()');
});
