import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._();
  factory AnalyticsService() => _instance;

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  AnalyticsService._();

  FirebaseAnalyticsObserver getObserver() {
    return FirebaseAnalyticsObserver(analytics: _analytics);
  }

  Future<void> logGameStarted(String mode, String difficulty) async {
    await _analytics.logEvent(
      name: 'game_started',
      parameters: {
        'mode': mode,
        'difficulty': difficulty,
      },
    );
  }

  Future<void> logGameOver({
    required String mode,
    required String difficulty,
    required int score,
    required int snakeLength,
    required bool isHighScore,
  }) async {
    await _analytics.logEvent(
      name: 'game_over',
      parameters: {
        'mode': mode,
        'difficulty': difficulty,
        'score': score,
        'snake_length': snakeLength,
        'is_new_high_score': isHighScore ? 1 : 0,
      },
    );
    await _analytics.logPostScore(
      score: score,
      level: mode == 'classic' ? 1 : 2,
    );
  }

  Future<void> logAchievementUnlocked(String achievementId) async {
    await _analytics.logUnlockAchievement(id: achievementId);
  }

  Future<void> logThemeChanged(String themeName) async {
    await _analytics.logEvent(
      name: 'theme_changed',
      parameters: {
        'theme': themeName,
      },
    );
  }

  Future<void> logPowerUpCollected(String type) async {
    await _analytics.logEvent(
      name: 'power_up_collected',
      parameters: {'type': type},
    );
  }

  Future<void> logQuestCompleted(String questId, bool isWeekly) async {
    await _analytics.logEvent(
      name: 'quest_completed',
      parameters: {
        'quest_id': questId,
        'type': isWeekly ? 'weekly' : 'daily',
      },
    );
  }

  Future<void> logShadowSnakeEvent(String action) async {
    await _analytics.logEvent(
      name: 'shadow_snake_encounter',
      parameters: {'action': action}, // 'spawn', 'defeated', 'stole_food'
    );
  }

  Future<void> logUserLogin(String loginMethod) async {
    await _analytics.logLogin(loginMethod: loginMethod);
  }
}
