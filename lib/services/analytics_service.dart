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

  Future<void> logTutorialStarted() async {
    await _analytics.logEvent(name: 'tutorial_started');
  }

  Future<void> logTutorialCompleted() async {
    await _analytics.logEvent(name: 'tutorial_completed');
  }

  Future<void> logStreakReward({
    required int streak,
    required int coins,
    required double multiplier,
  }) async {
    await _analytics.logEvent(
      name: 'streak_reward_granted',
      parameters: {
        'streak': streak,
        'coins': coins,
        'multiplier_x100': (multiplier * 100).round(),
      },
    );
  }

  Future<void> logTutorialSkipped() async {
    await _analytics.logEvent(name: 'tutorial_skipped');
  }

  Future<void> logTutorialCheckpoint(int step) async {
    await _analytics.logEvent(
      name: 'tutorial_checkpoint',
      parameters: {'step': step},
    );
  }

  Future<void> logTutorialRetry() async {
    await _analytics.logEvent(name: 'tutorial_retry');
  }

  // ── Experiment telemetry ──────────────────────────────────────
  Future<void> logExperimentAssigned({
    required String experimentKey,
    required int variant,
  }) async {
    await _analytics.logEvent(
      name: 'experiment_assigned',
      parameters: {
        'experiment': experimentKey,
        'variant': variant,
      },
    );
  }

  Future<void> logExperimentConversion({
    required String experimentKey,
    required int variant,
    required String event,
  }) async {
    await _analytics.logEvent(
      name: 'experiment_conversion',
      parameters: {
        'experiment': experimentKey,
        'variant': variant,
        'event': event,
      },
    );
  }
}
