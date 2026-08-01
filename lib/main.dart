import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/network/connectivity_service.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/storage/hive_service.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_logger.dart';
import 'features/settings/presentation/settings_providers.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      AppLogger.error('Flutter framework error', details.exception, details.stack);
      FlutterError.presentError(details);
    };

    final secureStorage = SecureStorageService(
      const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true)),
    );
    final hiveService = HiveService(secureStorage);
    await hiveService.init();

    final notificationService = NotificationService();
    await notificationService.init();
    await notificationService.requestPermission();

    runApp(
      ProviderScope(
        overrides: [
          hiveServiceProvider.overrideWithValue(hiveService),
          secureStorageProvider.overrideWithValue(secureStorage),
          notificationServiceProvider.overrideWithValue(notificationService),
        ],
        child: const JarvisApp(),
      ),
    );
  }, (error, stack) {
    AppLogger.error('Uncaught zone error', error, stack);
  });
}

class JarvisApp extends ConsumerStatefulWidget {
  const JarvisApp({super.key});

  @override
  ConsumerState<JarvisApp> createState() => _JarvisAppState();
}

class _JarvisAppState extends ConsumerState<JarvisApp> with WidgetsBindingObserver {
  ProviderSubscription<AsyncValue<NetworkStatus>>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Drain any offline-queued messages the moment connectivity returns.
    _connectivitySub = ref.listenManual(networkStatusProvider, (previous, next) {
      final wasOffline = previous?.value == NetworkStatus.offline;
      final isOnline = next.value == NetworkStatus.online;
      if (wasOffline && isOnline) {
        ref.read(apiClientProvider).flushOutbox();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final accent = ref.watch(appSettingsProvider).accent;

    return MaterialApp.router(
      title: 'JARVIS AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(accent: accent.color),
      darkTheme: AppTheme.dark(accent: accent.color),
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
