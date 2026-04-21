import '../enums/game_mode.dart';
import '../enums/theme_type.dart';

enum DailyEventType {
  reversed,      // Tuesday Twister
  neonCoins,      // Neon Friday
  speedDash,      // Saturday Speed
  zenMode,        // Zen Monday
  powerUpRain     // Mystery Power-Up
}

class DailyEvent {
  final DailyEventType type;
  final String title;
  final String description;
  final String icon;
  final ThemeType? forcedTheme;
  final double scoreMultiplier;
  final double coinMultiplier;
  final GameMode baseMode;

  const DailyEvent({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    this.forcedTheme,
    this.scoreMultiplier = 1.0,
    this.coinMultiplier = 1.0,
    this.baseMode = GameMode.classic,
  });

  static DailyEvent getEventForDay(DateTime date) {
    // Determine event based on day of week (1 = Monday, 7 = Sunday)
    switch (date.weekday) {
      case DateTime.monday:
        return const DailyEvent(
          type: DailyEventType.zenMode,
          title: 'Zen Monday',
          description: 'No walls, slow pace. Relaxing but rewarding!',
          icon: '🧘',
          baseMode: GameMode.endless,
          scoreMultiplier: 0.8,
        );
      case DateTime.tuesday:
        return const DailyEvent(
          type: DailyEventType.reversed,
          title: 'Tuesday Twister',
          description: 'Controls are INVERTED! Can you handle the twist?',
          icon: '🌀',
          scoreMultiplier: 2.0,
          coinMultiplier: 1.5,
        );
      case DateTime.wednesday:
        return const DailyEvent(
          type: DailyEventType.powerUpRain,
          title: 'Power Wednesday',
          description: 'Power-ups everywhere! Total chaos.',
          icon: '⚡',
          scoreMultiplier: 1.2,
        );
      case DateTime.thursday:
        return const DailyEvent(
          type: DailyEventType.speedDash,
          title: 'Thundery Thursday',
          description: 'Maximum speed from the start!',
          icon: '🌩️',
          scoreMultiplier: 1.5,
        );
      case DateTime.friday:
        return const DailyEvent(
          type: DailyEventType.neonCoins,
          title: 'Neon Friday',
          description: 'Glowing vibes and double coins!',
          icon: '💡',
          forcedTheme: ThemeType.neon,
          coinMultiplier: 2.0,
        );
      case DateTime.saturday:
        return const DailyEvent(
          type: DailyEventType.speedDash,
          title: 'Saturday Sprint',
          description: 'Go fast or go home. 3x speed!',
          icon: '🏁',
          scoreMultiplier: 2.5,
        );
      case DateTime.sunday:
      default:
        return const DailyEvent(
          type: DailyEventType.neonCoins, // Sunday Funday
          title: 'Sunday Funday',
          description: 'All power-ups last longer today!',
          icon: '🥳',
          coinMultiplier: 1.5,
        );
    }
  }
}
