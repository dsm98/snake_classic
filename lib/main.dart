import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/storage_service.dart';
import 'services/audio_service.dart';
import 'services/ad_service.dart';
import 'providers/settings_provider.dart';
import 'providers/score_provider.dart';
import 'core/constants/app_colors.dart';
import 'core/enums/theme_type.dart';
import 'services/auth_service.dart';
import 'providers/user_provider.dart';
import 'screens/splash_screen.dart';
import 'firebase_options.dart';
import 'services/analytics_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (wrapped in try-catch for local dev without config)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Initialize services
  final storage = StorageService();
  await storage.init();

  await AudioService().init();

  // AdMob is not supported on Flutter Web — skip on web
  if (!kIsWeb) {
    await AdService().init();
    await NotificationService().init();
    await NotificationService().scheduleDailyReminder();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider(storage)),
        ChangeNotifierProvider(create: (_) => ScoreProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const SnakeApp(),
    ),
  );
}

class SnakeApp extends StatelessWidget {
  const SnakeApp({super.key});

  AppThemeColors _themeColors(ThemeType theme) {
    switch (theme) {
      case ThemeType.retro:
        return AppThemeColors.retro;
      case ThemeType.neon:
        return AppThemeColors.neon;
      case ThemeType.nature:
        return AppThemeColors.nature;
      case ThemeType.arcade:
        return AppThemeColors.arcade;
      case ThemeType.cyber:
        return AppThemeColors.cyber;
      case ThemeType.volcano:
        return AppThemeColors.volcano;
      case ThemeType.ice:
        return AppThemeColors.ice;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final palette = _themeColors(settings.theme);
    final bool isRetro = settings.theme == ThemeType.retro;
    final baseText = isRetro ? const Color(0xFF2B3306) : palette.text;
    final cardColor = isRetro
        ? palette.hudBg.withValues(alpha: 0.85)
        : palette.hudBg.withValues(alpha: 0.72);
    final borderColor = palette.buttonBorder.withValues(alpha: 0.35);

    return MaterialApp(
      title: 'Snake Classic Reborn',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [AnalyticsService().getObserver()],
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(settings.fontScale),
            disableAnimations: settings.reducedMotion,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: palette.background,
        canvasColor: palette.background,
        cardColor: cardColor,
        dividerColor: borderColor,
        textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: baseText,
              displayColor: baseText,
            ),
        appBarTheme: AppBarTheme(
          backgroundColor: cardColor,
          elevation: 0,
          foregroundColor: baseText,
          surfaceTintColor: Colors.transparent,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: palette.hudBg.withValues(alpha: 0.95),
          contentTextStyle: TextStyle(
            color: baseText,
            fontFamily: 'Orbitron',
            fontSize: 12,
          ),
          behavior: SnackBarBehavior.floating,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: palette.buttonBorder,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: baseText,
            side: BorderSide(color: borderColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return palette.buttonBorder;
            }
            return palette.text.withValues(alpha: 0.7);
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return palette.buttonBorder.withValues(alpha: 0.35);
            }
            return palette.background.withValues(alpha: 0.45);
          }),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
