import '../../core/enums/theme_type.dart';

class CampaignLevel {
  final int index;
  final String title;
  final String description;
  final ThemeType theme;

  // Requirements to pass
  final int targetLength;
  final int timeLimitSeconds; // 0 means no time limit

  // Game Modifiers
  final double speedMultiplier;
  final int obstacleDensity; // 0 to 10
  final bool hasGoldenApples;
  final bool hasPoisonApples;
  final bool hasPortals;

  // Star rating score thresholds (cumulative score when level is won)
  final int star1Score; // ★☆☆ — just pass
  final int star2Score; // ★★☆
  final int star3Score; // ★★★ — excellent

  const CampaignLevel({
    required this.index,
    required this.title,
    required this.description,
    required this.theme,
    required this.targetLength,
    this.timeLimitSeconds = 0,
    this.speedMultiplier = 1.0,
    this.obstacleDensity = 0,
    this.hasGoldenApples = false,
    this.hasPoisonApples = false,
    this.hasPortals = false,
    this.star1Score = 50,
    this.star2Score = 150,
    this.star3Score = 300,
  });

  /// Returns how many stars (0-3) a given score earns on this level.
  int starsForScore(int score) {
    if (score >= star3Score) return 3;
    if (score >= star2Score) return 2;
    if (score >= star1Score) return 1;
    return 0;
  }

  /// Human-readable list of objectives shown before the level.
  List<String> get objectives {
    final list = <String>[];
    list.add('Reach length $targetLength');
    if (timeLimitSeconds > 0) {
      list.add('Within ${timeLimitSeconds}s time limit');
    }
    if (hasPoisonApples) list.add('Avoid poison apples ☠️');
    if (hasGoldenApples) list.add('Grab golden apples ⭐ for bonus score');
    if (hasPortals) list.add('Use portals 🌀 to navigate');
    if (obstacleDensity >= 5) {
      list.add('Navigate dense obstacle walls');
    } else if (obstacleDensity > 0) {
      list.add('Watch out for obstacles');
    }
    if (speedMultiplier >= 1.8) {
      list.add('Extreme speed — react fast!');
    } else if (speedMultiplier >= 1.3) {
      list.add('Increased movement speed');
    } else if (speedMultiplier <= 0.9) {
      list.add('Slower pace — plan ahead');
    }
    return list;
  }

  static const List<CampaignLevel> all = [
    CampaignLevel(
      index: 1,
      title: 'The Forest',
      description: 'Eat 10 apples to grow. Watch out for the edges!',
      theme: ThemeType.nature,
      targetLength: 10,
      speedMultiplier: 0.8,
      star1Score: 50,
      star2Score: 120,
      star3Score: 200,
    ),
    CampaignLevel(
      index: 2,
      title: 'Speed Bump',
      description: 'Things are moving faster. Reach length 15!',
      theme: ThemeType.arcade,
      targetLength: 15,
      speedMultiplier: 1.2,
      star1Score: 80,
      star2Score: 180,
      star3Score: 300,
    ),
    CampaignLevel(
      index: 3,
      title: 'Golden Age',
      description:
          'Golden Apples appear! They give more score but disappear fast. Grow to length 20.',
      theme: ThemeType.retro,
      targetLength: 20,
      hasGoldenApples: true,
      star1Score: 120,
      star2Score: 280,
      star3Score: 500,
    ),
    CampaignLevel(
      index: 4,
      title: 'The Ruins',
      description: 'Navigate ancient obstacle walls to find food.',
      theme: ThemeType.nature,
      targetLength: 15,
      obstacleDensity: 3,
      star1Score: 80,
      star2Score: 180,
      star3Score: 320,
    ),
    CampaignLevel(
      index: 5,
      title: 'Toxic Wasteland',
      description:
          'Poison apples are lethal! Avoid them and grow to length 20.',
      theme: ThemeType.neon,
      targetLength: 20,
      hasPoisonApples: true,
      star1Score: 100,
      star2Score: 230,
      star3Score: 400,
    ),
    CampaignLevel(
      index: 6,
      title: 'Portal Hop',
      description: 'Jump through portals to reach the food. Length 20 needed.',
      theme: ThemeType.arcade,
      targetLength: 20,
      hasPortals: true,
      obstacleDensity: 5,
      star1Score: 120,
      star2Score: 260,
      star3Score: 450,
    ),
    CampaignLevel(
      index: 7,
      title: 'Neon Dash',
      description: 'Extremely fast. No time to think. Reach length 30.',
      theme: ThemeType.neon,
      targetLength: 30,
      speedMultiplier: 1.8,
      star1Score: 150,
      star2Score: 350,
      star3Score: 600,
    ),
    CampaignLevel(
      index: 8,
      title: 'Time Trial',
      description: 'Reach length 20 in under 60 seconds!',
      theme: ThemeType.arcade,
      targetLength: 20,
      timeLimitSeconds: 60,
      star1Score: 120,
      star2Score: 270,
      star3Score: 450,
    ),
    CampaignLevel(
      index: 9,
      title: 'The Gauntlet',
      description: 'Portals, Obstacles, Poison. Survive them all. Length 25.',
      theme: ThemeType.retro,
      targetLength: 25,
      obstacleDensity: 6,
      hasPortals: true,
      hasPoisonApples: true,
      star1Score: 150,
      star2Score: 330,
      star3Score: 560,
    ),
    CampaignLevel(
      index: 10,
      title: 'Grandmaster',
      description: 'The ultimate test. Max speed, pure skill. Length 50.',
      theme: ThemeType.nature,
      targetLength: 50,
      speedMultiplier: 2.0,
      hasGoldenApples: true,
      star1Score: 300,
      star2Score: 650,
      star3Score: 1100,
    ),
  ];
}
