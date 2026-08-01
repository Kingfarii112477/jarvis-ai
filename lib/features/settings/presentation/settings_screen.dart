import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/glass_card.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _webhookController;
  late final TextEditingController _userIdController;
  late final TextEditingController _wakeWordController;
  bool _initialized = false;

  @override
  void dispose() {
    _webhookController.dispose();
    _userIdController.dispose();
    _wakeWordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    if (!_initialized) {
      _webhookController = TextEditingController(text: settings.webhookUrl);
      _userIdController = TextEditingController(text: settings.userId);
      _wakeWordController = TextEditingController(text: settings.wakeWord);
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('SETTINGS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Backend Configuration Section
            _buildSectionHeader('BACKEND CONFIGURATION'),
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTextField(
                    label: 'n8n Webhook URL',
                    hint: 'https://n8n.yourdomain.com/webhook/...',
                    controller: _webhookController,
                    onChanged: (value) => settingsNotifier.updateWebhookUrl(value),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'User ID',
                    hint: 'usr_jarvis_mobile',
                    controller: _userIdController,
                    onChanged: (value) => settingsNotifier.updateUserId(value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Voice Interaction Section
            _buildSectionHeader('VOICE INTERACTION'),
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildToggleSetting(
                    label: 'Wake Word Detection',
                    subtitle: 'Enable hands-free activation',
                    value: settings.wakeWordEnabled,
                    onChanged: (value) => settingsNotifier.updateWakeWordEnabled(value),
                  ),
                  const SizedBox(height: 20),
                  if (settings.wakeWordEnabled) ...[
                    _buildTextField(
                      label: 'Wake Word',
                      hint: 'e.g., jarvis, hey jarvis',
                      controller: _wakeWordController,
                      onChanged: (value) => settingsNotifier.updateWakeWord(value),
                    ),
                    const SizedBox(height: 20),
                    _buildSensitivitySlider(
                      label: 'Wake Word Sensitivity',
                      value: settings.wakeWordSensitivity,
                      onChanged: (value) => settingsNotifier.updateWakeWordSensitivity(value),
                    ),
                    const SizedBox(height: 20),
                  ],
                  _buildToggleSetting(
                    label: 'Continuous Listening',
                    subtitle: 'Like a phone call - always listening',
                    value: settings.continuousListening,
                    onChanged: (value) => settingsNotifier.updateContinuousListening(value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // About Section
            _buildSectionHeader('ABOUT'),
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'JARVIS AI Assistant',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Version 2.0.0',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Production-grade AI Assistant with voice interaction, continuous listening, and n8n integration.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
        fontSize: 14,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.glassBorder),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleSetting({
    required String label,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildSensitivitySlider({
    required String label,
    required double value,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(value * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          onChanged: onChanged,
          min: 0.1,
          max: 1.0,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.glassBorder,
        ),
      ],
    );
  }
}
