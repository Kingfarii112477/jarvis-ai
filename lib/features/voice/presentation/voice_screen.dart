import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/orb/jarvis_orb.dart';
import '../../settings/presentation/settings_providers.dart';
import 'voice_providers.dart';

class VoiceScreen extends ConsumerWidget {
  const VoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(voiceControllerProvider);
    final controller = ref.read(voiceControllerProvider.notifier);
    final settings = ref.watch(appSettingsProvider);

    ref.listen(voiceControllerProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Voice Assistant'),
        actions: [
          IconButton(
            icon: Icon(
              settings.continuousListening ? Icons.podcasts_rounded : Icons.podcasts_outlined,
              color: settings.continuousListening ? AppColors.primaryGlow : AppColors.textSecondary,
            ),
            tooltip: 'Continuous listening',
            onPressed: controller.toggleContinuous,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  JarvisOrb(
                    mood: state.mood,
                    size: 240,
                    amplitude: state.amplitude,
                    onTap: state.isListening ? controller.stopPushToTalk : controller.startPushToTalk,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    state.mood.label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (state.liveTranscript.isNotEmpty || state.isListening)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      child: Text(
                        state.liveTranscript.isEmpty ? 'Listening…' : state.liveTranscript,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    )
                  else if (state.lastReply.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      child: GlassCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(state.lastReply, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: GestureDetector(
              onLongPressStart: (_) => controller.startPushToTalk(),
              onLongPressEnd: (_) => controller.stopPushToTalk(),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: state.isListening ? AppColors.error : AppColors.primaryGlow,
                  boxShadow: [
                    BoxShadow(
                      color: (state.isListening ? AppColors.error : AppColors.primaryGlow).withValues(alpha: 0.4),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Icon(state.isListening ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.black, size: 30),
              ),
            ),
          ),
          Text(
            state.isListening ? 'Release to send' : 'Hold to talk',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
