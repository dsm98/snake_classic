import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/storage_service.dart';
import 'services/audio_service.dart';
import 'services/ad_service.dart';
import 'providers/settings_provider.dart';
import 'providers/score_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snake Classic Reborn',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [AnalyticsService().getObserver()],
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF9BBC0F), // Nokia LCD green
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF8BAC0F),
          elevation: 0,
          foregroundColor: Color(0xFF0F380F), // dark text on LCD
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
