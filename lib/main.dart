import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/telegram_proxy_provider.dart';
import 'providers/v2ray_provider.dart';
import 'providers/language_provider.dart';
import 'services/wallpaper_service.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/privacy_welcome_screen.dart';
import 'services/update_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize language provider
  final languageProvider = LanguageProvider();
  await languageProvider.initialize();

  // Check if user has accepted privacy policy
  final prefs = await SharedPreferences.getInstance();
  final bool privacyAccepted = prefs.getBool('privacy_accepted') ?? false;

  runApp(
    MyApp(privacyAccepted: privacyAccepted, languageProvider: languageProvider),
  );
}

class MyApp extends StatefulWidget {
  final bool privacyAccepted;
  final LanguageProvider languageProvider;

  const MyApp({
    super.key,
    required this.privacyAccepted,
    required this.languageProvider,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final UpdateService _updateService = UpdateService();

  @override
  void initState() {
    super.initState();
    // Check for updates after the app is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    final update = await _updateService.checkForUpdates();
    if (update != null && mounted) {
      _updateService.showUpdateDialog(context, update);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.languageProvider),
        ChangeNotifierProvider(create: (context) => V2RayProvider()),
        ChangeNotifierProvider(create: (context) => TelegramProxyProvider()),
        ChangeNotifierProvider(
          create: (context) => WallpaperService()..initialize(),
        ),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: 'Proxy Cloud',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme(languageProvider.currentLanguage.code),
            locale: languageProvider.locale,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('tr'), // Turkish
              Locale('es'), // Spanish
              Locale('fr'), // French
              Locale('ar'), // Arabic
              Locale('zh'), // Chinese
              Locale('ru'), // Russian
              Locale('fa'), // Persian
            ],
            home: widget.privacyAccepted
                ? const MainNavigationScreen()
                : const PrivacyWelcomeScreen(),
          );
        },
      ),
    );
  }
}
