import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';
import 'app/theme/theme_provider.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/locale_provider.dart';
import 'core/services/cache_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/firebase_messaging_service.dart';
import 'core/services/websocket_service.dart';
import 'core/widgets/offline_banner.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await CacheService.init();
  await Hive.openBox('settings');

  // Initialize Firebase and Messaging
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final fcmService = FirebaseMessagingService();
    await fcmService.init();
  } catch (e) {
    debugPrint('Firebase not initialized: $e');
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN', defaultValue: '');
      options.tracesSampleRate = 1.0;
    },
    appRunner: () => runApp(
      const ProviderScope(
        child: KoraApp(),
      ),
    ),
  );
}

class KoraApp extends ConsumerStatefulWidget {
  const KoraApp({super.key});

  @override
  ConsumerState<KoraApp> createState() => _KoraAppState();
}

class _KoraAppState extends ConsumerState<KoraApp> {
  @override
  void initState() {
    super.initState();
    // Initialize connectivity monitoring
    ref.read(connectivityServiceProvider).init();
    // Initialize WebSocket live updates
    ref.read(websocketServiceProvider).init();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Kora Live',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: AppRoutes.router,
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return OfflineBanner(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
