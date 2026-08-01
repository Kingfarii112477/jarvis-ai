import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../data/settings_repository.dart';
import 'settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _webhookController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _userIdController = TextEditingController();
  final _wakeWordController = TextEditingController();
  bool _secureFieldsLoaded = false;

  @override
  void dispose() {
    _webhookController.dispose();
    _apiKeyController.dispose();
    _userIdController.dispose();
    _wakeWordController.dispose();
    super.dispose();
  }

  Future<void> _loadSecureFields() async {
    final repo = ref.read(settingsRepositoryProvider).secure;
    _webhookController.text = await repo.webhookUrl ?? '';
    _apiKeyController.text = await repo.apiKey ?? '';
    _userIdController.text = await repo.userId ?? 'usr_jarvis_mobile';
    if (mounted) setState(() => _secureFieldsLoaded = true);
  }

  @override
  void initState() {
    super.initState();
    _loadSecureFields();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final secureStorage = ref.read(settingsRepositoryProvider).secure;

    if (!_secureFieldsLoaded) {
      _wakeWordController.text = settings.wakeWord;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
        children: [
          const SectionHeader(title: 'Backend', icon: Icons.cloud_outlined),
          const SizedBox(height: AppSpacing.sm),
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _LabeledField(
                  label: 'n8n webhook URL',
                  controller: _webhookController,
                  hint: 'https://n8n.yourdomain.com/webhook/jarvis',
                  onChanged: secureStorage.setWebhookUrl,
                ),
                const SizedBox(height: AppSpacing.md),
                _LabeledField(
                  label: 'API key (optional)',
                  controller: _apiKeyController,
                  hint: 'Bearer token sent as Authorization header',
                  obscure: true,
                  onChanged: secureStorage.setApiKey,
                ),
                const SizedBox(height: AppSpacing.md),
                _LabeledField(
                  label: 'User ID',
                  controller: _userIdController,
                  hint: 'usr_jarvis_mobile',
                  onChanged: secureStorage.setUserId,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          const SectionHeader(title: 'Appearance', icon: Icons.palette_outlined),
          const SizedBox(height: AppSpacing.sm),
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Accent', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 10,
                  children: AppAccent.values.map((accent) {
                    final selected = settings.accent == accent;
                    return GestureDetector(
                      onTap: () => notifier.setAccent(accent),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: accent.color,
                          shape: BoxShape.circle,
                          border: selected ? Border.all(color: Colors.white, width: 2) : null,
                          boxShadow: [BoxShadow(color: accent.color.withValues(alpha: 0.5), blurRadius: selected ? 14 : 0)],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const Divider(height: AppSpacing.lg),
                _SwitchRow(
                  label: 'Animations',
                  subtitle: 'Orb glow, transitions and micro-interactions',
                  value: settings.animationsEnabled,
                  onChanged: notifier.setAnimationsEnabled,
                ),
                _SwitchRow(
                  label: 'Experimental heavy blur',
                  subtitle: 'Real backdrop blur on floating surfaces — known to gray-wash the screen on some Android GPUs',
                  value: settings.heavyBlurEnabled,
                  onChanged: notifier.setHeavyBlurEnabled,
                  warning: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          const SectionHeader(title: 'Voice', icon: Icons.graphic_eq_rounded),
          const SizedBox(height: AppSpacing.sm),
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _SwitchRow(
                  label: 'Wake word detection',
                  subtitle: 'Hands-free activation (energy-threshold engine — see README for Porcupine upgrade path)',
                  value: settings.wakeWordEnabled,
                  onChanged: notifier.setWakeWordEnabled,
                ),
                if (settings.wakeWordEnabled) ...[
                  const SizedBox(height: AppSpacing.md),
                  _LabeledField(label: 'Wake word', controller: _wakeWordController, hint: 'jarvis', onChanged: notifier.setWakeWord),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(child: Text('Sensitivity', style: Theme.of(context).textTheme.bodySmall)),
                      Text('${(settings.wakeWordSensitivity * 100).toStringAsFixed(0)}%', style: const TextStyle(color: AppColors.primaryGlow, fontSize: 12)),
                    ],
                  ),
                  Slider(value: settings.wakeWordSensitivity, min: 0.1, max: 1.0, onChanged: notifier.setWakeWordSensitivity),
                ],
                _SwitchRow(
                  label: 'Continuous listening',
                  subtitle: 'Like a phone call — stays open after each reply',
                  value: settings.continuousListening,
                  onChanged: notifier.setContinuousListening,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          const SectionHeader(title: 'Privacy & security', icon: Icons.shield_outlined),
          const SizedBox(height: AppSpacing.sm),
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _BiometricLockRow(secureStorage: secureStorage),
                _SwitchRow(
                  label: 'Usage analytics',
                  subtitle: 'Local-only usage log that powers the Analytics tab',
                  value: settings.analyticsOptIn,
                  onChanged: notifier.setAnalyticsOptIn,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          const SectionHeader(title: 'Storage', icon: Icons.storage_outlined),
          const SizedBox(height: AppSpacing.sm),
          const GlassCard(padding: EdgeInsets.all(AppSpacing.md), child: _StorageInfo()),
          const SizedBox(height: AppSpacing.lg),

          const SectionHeader(title: 'Developer', icon: Icons.developer_mode_rounded),
          const SizedBox(height: AppSpacing.sm),
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _SwitchRow(label: 'Developer mode', subtitle: 'Show request/response diagnostics', value: settings.developerMode, onChanged: notifier.setDeveloperMode),
                if (settings.developerMode) const _DeveloperPanel(),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          const _AboutCard(),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.controller, required this.hint, required this.onChanged, this.obscure = false});
  final String label;
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.label, required this.subtitle, required this.value, required this.onChanged, this.warning = false});
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: warning ? AppColors.warning : AppColors.textSecondary, fontSize: 11.5)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _BiometricLockRow extends StatefulWidget {
  const _BiometricLockRow({required this.secureStorage});
  final SecureStorageService secureStorage;

  @override
  State<_BiometricLockRow> createState() => _BiometricLockRowState();
}

class _BiometricLockRowState extends State<_BiometricLockRow> {
  bool _enabled = false;
  bool _loaded = false;
  final _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    widget.secureStorage.biometricLockEnabled.then((v) {
      if (mounted) {
        setState(() {
          _enabled = v;
          _loaded = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox(height: 48);
    return _SwitchRow(
      label: 'Biometric lock',
      subtitle: 'Require fingerprint/face unlock to open JARVIS',
      value: _enabled,
      onChanged: (v) async {
        final messenger = ScaffoldMessenger.of(context);
        if (v) {
          final canCheck = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
          if (!canCheck) {
            if (mounted) {
              messenger.showSnackBar(const SnackBar(content: Text('No biometric hardware available on this device')));
            }
            return;
          }
        }
        await widget.secureStorage.setBiometricLockEnabled(v);
        if (mounted) setState(() => _enabled = v);
      },
    );
  }
}

class _StorageInfo extends ConsumerWidget {
  const _StorageInfo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiClient = ref.watch(apiClientProvider);
    return Row(
      children: [
        const Icon(Icons.inbox_outlined, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(child: Text('${apiClient.pendingOutboxCount} messages queued offline', style: Theme.of(context).textTheme.bodyMedium)),
        TextButton(
          onPressed: () => apiClient.flushOutbox(),
          child: const Text('Retry now'),
        ),
      ],
    );
  }
}

class _DeveloperPanel extends ConsumerWidget {
  const _DeveloperPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: AppSpacing.md),
          Text('Contract version: 1', style: Theme.of(context).textTheme.bodySmall),
          Text('Storage: Hive (AES-256, key in secure enclave)', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final version = snapshot.data?.version ?? '2.0.0';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('JARVIS AI', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('Version $version', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(
                'Open-source, privacy-first AI assistant. All local data stays encrypted on-device; conversations only leave the device through the n8n webhook you configure above.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}
