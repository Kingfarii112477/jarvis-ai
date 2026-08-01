import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final String webhookUrl;
  final String userId;
  final bool wakeWordEnabled;
  final String wakeWord;
  final bool continuousListening;
  final double wakeWordSensitivity;

  SettingsState({
    required this.webhookUrl,
    required this.userId,
    required this.wakeWordEnabled,
    required this.wakeWord,
    required this.continuousListening,
    required this.wakeWordSensitivity,
  });

  SettingsState copyWith({
    String? webhookUrl,
    String? userId,
    bool? wakeWordEnabled,
    String? wakeWord,
    bool? continuousListening,
    double? wakeWordSensitivity,
  }) {
    return SettingsState(
      webhookUrl: webhookUrl ?? this.webhookUrl,
      userId: userId ?? this.userId,
      wakeWordEnabled: wakeWordEnabled ?? this.wakeWordEnabled,
      wakeWord: wakeWord ?? this.wakeWord,
      continuousListening: continuousListening ?? this.continuousListening,
      wakeWordSensitivity: wakeWordSensitivity ?? this.wakeWordSensitivity,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier()
      : super(SettingsState(
          webhookUrl: '',
          userId: 'usr_jarvis_mobile',
          wakeWordEnabled: false,
          wakeWord: 'jarvis',
          continuousListening: false,
          wakeWordSensitivity: 0.5,
        )) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      webhookUrl: prefs.getString('n8n_webhook_url') ?? '',
      userId: prefs.getString('user_id') ?? 'usr_jarvis_mobile',
      wakeWordEnabled: prefs.getBool('wake_word_enabled') ?? false,
      wakeWord: prefs.getString('wake_word') ?? 'jarvis',
      continuousListening: prefs.getBool('continuous_listening') ?? false,
      wakeWordSensitivity: prefs.getDouble('wake_word_sensitivity') ?? 0.5,
    );
  }

  Future<void> updateWebhookUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('n8n_webhook_url', url);
    state = state.copyWith(webhookUrl: url);
  }

  Future<void> updateUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    state = state.copyWith(userId: userId);
  }

  Future<void> updateWakeWordEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wake_word_enabled', enabled);
    state = state.copyWith(wakeWordEnabled: enabled);
  }

  Future<void> updateWakeWord(String word) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wake_word', word);
    state = state.copyWith(wakeWord: word);
  }

  Future<void> updateContinuousListening(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('continuous_listening', enabled);
    state = state.copyWith(continuousListening: enabled);
  }

  Future<void> updateWakeWordSensitivity(double sensitivity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('wake_word_sensitivity', sensitivity);
    state = state.copyWith(wakeWordSensitivity: sensitivity);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
