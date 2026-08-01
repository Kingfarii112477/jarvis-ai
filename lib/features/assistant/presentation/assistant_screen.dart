import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'assistant_notifier.dart';
import 'widgets/animated_orb.dart';
import 'widgets/hud_status_bar.dart';
import 'widgets/message_composer.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/hud_frame.dart';
import '../../../shared/widgets/hud_grid_background.dart';
import '../../../shared/widgets/scanline_overlay.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../core/constants/colors.dart';
import '../../settings/presentation/settings_provider.dart';

class AssistantScreen extends ConsumerWidget {
  const AssistantScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(assistantProvider);
    final notifier = ref.read(assistantProvider.notifier);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'JARVIS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'ONLINE',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // HUD grid + vignette base layer
          const HudGridBackground(),

          Column(
            children: [
              SizedBox(height: kToolbarHeight + MediaQuery.of(context).padding.top + 8),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: HudStatusBar(
                  wakeWordArmed: settings.wakeWordEnabled,
                  connected: state.error == null,
                ),
              ),
              const SizedBox(height: 12),

              // Chat Feed
              Expanded(
                child: state.messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        reverse: true,
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) {
                          final message = state.messages.reversed.toList()[index];
                          return _ChatBubble(message: message);
                        },
                      ),
              ),

              // Animated Orb Area
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: GestureDetector(
                  onLongPressStart: (_) => notifier.startRecording(),
                  onLongPressEnd: (_) => notifier.stopRecording(),
                  child: HudFrame(
                    margin: const EdgeInsets.all(4),
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: AnimatedOrb(
                        state: state.orbState,
                        size: 200,
                      ),
                    ),
                  ),
                ),
              ),

              // Status Text
              Text(
                _getStatusText(state),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 16),

              // Message Composer
              MessageComposer(
                onSendMessage: (message) => notifier.sendTextMessage(message),
                isLoading: state.orbState == OrbState.processing,
              ),

              const SizedBox(height: 8),
            ],
          ),

          if (state.error != null)
            Positioned(
              bottom: 120,
              left: 20,
              right: 20,
              child: GlassCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.error!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Sweeping scanline, drawn last so it sits above everything
          const ScanlineOverlay(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: AppColors.primary,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Welcome to JARVIS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Hold the orb to speak or type your message below to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(AssistantState state) {
    if (state.isRecording) return 'LISTENING...';
    if (state.orbState == OrbState.processing) return 'PROCESSING...';
    if (state.orbState == OrbState.speaking) return 'JARVIS IS SPEAKING';
    return 'HOLD ORB TO SPEAK';
  }
}

class _ChatBubble extends StatelessWidget {
  final dynamic message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            borderRadius: isUser
                ? const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  )
                : const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isUser && message.toolUsed != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        message.toolUsed!.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                Text(
                  message.text,
                  style: TextStyle(
                    color: isUser ? Colors.white : AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
