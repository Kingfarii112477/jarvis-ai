import 'package:flutter_test/flutter_test.dart';
import 'package:jarvis_app/core/constants/app_colors.dart';

void main() {
  test('every AssistantMood has a distinct label', () {
    final labels = AssistantMood.values.map((m) => m.label).toSet();
    expect(labels, hasLength(AssistantMood.values.length));
  });

  test('label text matches the documented HUD-style status strings', () {
    expect(AssistantMood.idle.label, 'IDLE');
    expect(AssistantMood.listening.label, 'LISTENING');
    expect(AssistantMood.processing.label, 'PROCESSING');
    expect(AssistantMood.speaking.label, 'SPEAKING');
    expect(AssistantMood.offline.label, 'OFFLINE');
    expect(AssistantMood.error.label, 'ERROR');
    expect(AssistantMood.success.label, 'READY');
  });

  test('offline and error moods use non-brand colors', () {
    expect(AssistantMood.offline.color, AppColors.textTertiary);
    expect(AssistantMood.error.color, AppColors.error);
  });

  test('idle and speaking share the primary glow color', () {
    expect(AssistantMood.idle.color, AppColors.primaryGlow);
    expect(AssistantMood.speaking.color, AppColors.primaryGlow);
  });
}
