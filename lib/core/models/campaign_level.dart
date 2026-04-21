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
  });

  static const List<CampaignLevel> all = [
    CampaignLevel(
      index: 1,
      title: 'The Forest',
      description: 'Eat 10 apples to grow. Watch out for the edges!',
      theme: ThemeType.nature,
      targetLength: 10,
      speedMultiplier: 0.8,
    ),
    CampaignLevel(
      index: 2,
      title: 'Speed Bump',
      description: 'Things are moving faster. Reach length 15!',
      theme: ThemeType.arcade,
      targetLength: 15,
      speedMultiplier: 1.2,
    ),
    CampaignLevel(
      index: 3,
      title: 'Golden Age',
      description: 'Golden Apples appear! They give more score but disappear fast. Grow to length 20.',
      theme: ThemeType.retro,
      targetLength: 20,
      hasGoldenApples: true,
    ),
    CampaignLevel(
      index: 4,
      title: 'The Ruins',
      description: 'Navigate ancient obstacle walls to find food.',
      theme: ThemeType.nature,
      targetLength: 15,
      obstacleDensity: 3,
    ),
    CampaignLevel(
      index: 5,
      title: 'Toxic Wasteland',
      description: 'Poison apples are lethal! Avoid them and grow to length 20.',
      theme: ThemeType.neon,
      targetLength: 20,
      hasPoisonApples: true,
    ),
    CampaignLevel(
      index: 6,
      title: 'Portal Hop',
      description: 'Jump through portals to reach the food. Length 20 needed.',
      theme: ThemeType.arcade,
      targetLength: 20,
      hasPortals: true,
      obstacleDensity: 5,
    ),
    CampaignLevel(
      index: 7,
      title: 'Neon Dash',
      description: 'Extremely fast. No time to think. Reach length 30.',
      theme: ThemeType.neon,
      targetLength: 30,
      speedMultiplier: 1.8,
    ),
    CampaignLevel(
      index: 8,
      title: 'Time Trial',
      description: 'Reach length 20 in under 60 seconds!',
      theme: ThemeType.arcade,
      targetLength: 20,
      timeLimitSeconds: 60,
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
    ),
    CampaignLevel(
      index: 10,
      title: 'Grandmaster',
      description: 'The ultimate test. Max speed, pure skill. Length 50.',
      theme: ThemeType.nature,
      targetLength: 50,
      speedMultiplier: 2.0,
      hasGoldenApples: true,
    ),
  ];
}
