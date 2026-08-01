/// Static, compile-time app configuration. Runtime/user-editable config
/// (webhook URL, API keys, feature toggles) lives in the settings feature
/// and is persisted via [SecureStorageService] / Hive instead — this file
/// only holds values that never change per-install.
class AppConfig {
  const AppConfig._();

  static const String appName = 'JARVIS AI';
  static const String appVersion = '2.0.0';

  /// Contract version sent to n8n so workflows can branch on payload shape.
  static const String apiContractVersion = '1';

  static const Duration networkTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  static const Duration retryBaseDelay = Duration(milliseconds: 600);

  /// Hive box names, centralized so a typo can't silently create a second
  /// box.
  static const String boxChat = 'jarvis_chat';
  static const String boxTasks = 'jarvis_tasks';
  static const String boxMemory = 'jarvis_memory';
  static const String boxAutomation = 'jarvis_automation';
  static const String boxKnowledge = 'jarvis_knowledge';
  static const String boxAnalytics = 'jarvis_analytics';
  static const String boxSettings = 'jarvis_settings';
  static const String boxOutbox = 'jarvis_outbox';
}
