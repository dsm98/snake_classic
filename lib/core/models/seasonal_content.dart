import '../enums/game_mode.dart';

class SeasonalContent {
  final String key;
  final String title;
  final String subtitle;
  final String icon;
  final double scoreMultiplier;
  final double coinMultiplier;
  final GameMode suggestedMode;

  const SeasonalContent({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.scoreMultiplier,
    required this.coinMultiplier,
    required this.suggestedMode,
  });

  static SeasonalContent forDate(DateTime now) {
    if (now.month == 10) {
      return const SeasonalContent(
        key: 'spooky_october',
        title: 'Spooky Season',
        subtitle: 'Ghost apples and night vibes. +20% score this month.',
        icon: '🎃',
        scoreMultiplier: 1.2,
        coinMultiplier: 1.1,
        suggestedMode: GameMode.maze,
      );
    }

    if (now.month == 12) {
      return const SeasonalContent(
        key: 'frost_festival',
        title: 'Frost Festival',
        subtitle: 'Cool heads win. +25% coins in all modes.',
        icon: '❄️',
        scoreMultiplier: 1.0,
        coinMultiplier: 1.25,
        suggestedMode: GameMode.endless,
      );
    }

    if (now.month >= 6 && now.month <= 8) {
      return const SeasonalContent(
        key: 'summer_rush',
        title: 'Summer Rush',
        subtitle: 'Fast snakes, bright nights. Blitz is boosted this season.',
        icon: '🌞',
        scoreMultiplier: 1.15,
        coinMultiplier: 1.1,
        suggestedMode: GameMode.blitz,
      );
    }

    if (now.month >= 3 && now.month <= 5) {
      return const SeasonalContent(
        key: 'spring_bloom',
        title: 'Spring Bloom',
        subtitle: 'Fresh start rewards. +15% score and coins.',
        icon: '🌿',
        scoreMultiplier: 1.15,
        coinMultiplier: 1.15,
        suggestedMode: GameMode.classic,
      );
    }

    return const SeasonalContent(
      key: 'autumn_arcade',
      title: 'Autumn Arcade',
      subtitle: 'Steady climb season. +10% score in challenge runs.',
      icon: '🍂',
      scoreMultiplier: 1.1,
      coinMultiplier: 1.0,
      suggestedMode: GameMode.timeAttack,
    );
  }
}
