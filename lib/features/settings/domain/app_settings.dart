import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/theme/app_theme.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

@freezed
class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(AppAccent.cyan) AppAccent accent,
    @Default(true) bool animationsEnabled,
    @Default(false) bool heavyBlurEnabled,
    @Default(false) bool wakeWordEnabled,
    @Default('jarvis') String wakeWord,
    @Default(0.5) double wakeWordSensitivity,
    @Default(false) bool continuousListening,
    @Default('en-US') String language,
    @Default(false) bool developerMode,
    @Default(true) bool analyticsOptIn,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) => _$AppSettingsFromJson(json);
}
