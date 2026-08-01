import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../data/settings_repository.dart';
import '../domain/app_settings.dart';

final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier(ref.watch(settingsRepositoryProvider));
});

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier(this._repo) : super(_repo.load());

  final SettingsRepository _repo;

  Future<void> _update(AppSettings Function(AppSettings) updater) async {
    final next = updater(state);
    state = next;
    await _repo.save(next);
  }

  Future<void> setAccent(AppAccent accent) => _update((s) => s.copyWith(accent: accent));
  Future<void> setAnimationsEnabled(bool v) => _update((s) => s.copyWith(animationsEnabled: v));
  Future<void> setHeavyBlurEnabled(bool v) => _update((s) => s.copyWith(heavyBlurEnabled: v));
  Future<void> setWakeWordEnabled(bool v) => _update((s) => s.copyWith(wakeWordEnabled: v));
  Future<void> setWakeWord(String v) => _update((s) => s.copyWith(wakeWord: v));
  Future<void> setWakeWordSensitivity(double v) => _update((s) => s.copyWith(wakeWordSensitivity: v));
  Future<void> setContinuousListening(bool v) => _update((s) => s.copyWith(continuousListening: v));
  Future<void> setLanguage(String v) => _update((s) => s.copyWith(language: v));
  Future<void> setDeveloperMode(bool v) => _update((s) => s.copyWith(developerMode: v));
  Future<void> setAnalyticsOptIn(bool v) => _update((s) => s.copyWith(analyticsOptIn: v));
}

/// Secure (non-Hive) fields, loaded once and cached for the session.
final webhookUrlProvider = FutureProvider<String?>((ref) {
  return ref.watch(settingsRepositoryProvider).secure.webhookUrl;
});

final apiKeyProvider = FutureProvider<String?>((ref) {
  return ref.watch(settingsRepositoryProvider).secure.apiKey;
});

final userIdProvider = FutureProvider<String?>((ref) {
  return ref.watch(settingsRepositoryProvider).secure.userId;
});

final biometricLockEnabledProvider = FutureProvider<bool>((ref) {
  return ref.watch(settingsRepositoryProvider).secure.biometricLockEnabled;
});
