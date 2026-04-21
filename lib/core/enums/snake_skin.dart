enum SnakeSkin {
  classic,
  skeleton,
  robot,
  rainbow,
  ghost,
  ninja,
  dragon,
  vampire,
  golden
}

enum SkinRarity { common, rare, epic, legendary }

extension SnakeSkinExtension on SnakeSkin {
  String get displayName {
    switch (this) {
      case SnakeSkin.classic: return 'Classic';
      case SnakeSkin.skeleton: return 'Skeletal';
      case SnakeSkin.robot: return 'Mecha Snake';
      case SnakeSkin.rainbow: return 'Prism';
      case SnakeSkin.ghost: return 'Phantom';
      case SnakeSkin.ninja: return 'Ninja';
      case SnakeSkin.dragon: return 'Dragon';
      case SnakeSkin.vampire: return 'Vampire';
      case SnakeSkin.golden: return 'Radiant Gold';
    }
  }

  SkinRarity get rarity {
    switch (this) {
      case SnakeSkin.classic: return SkinRarity.common;
      case SnakeSkin.skeleton: return SkinRarity.common;
      case SnakeSkin.robot: return SkinRarity.rare;
      case SnakeSkin.rainbow: return SkinRarity.rare;
      case SnakeSkin.ghost: return SkinRarity.epic;
      case SnakeSkin.ninja: return SkinRarity.epic;
      case SnakeSkin.dragon: return SkinRarity.legendary;
      case SnakeSkin.vampire: return SkinRarity.epic;
      case SnakeSkin.golden: return SkinRarity.legendary;
    }
  }

  String get advantageDescription {
    switch (this) {
      case SnakeSkin.classic: return 'No advantage. Pure skill.';
      case SnakeSkin.skeleton: return '+5% Score multiplier';
      case SnakeSkin.robot: return 'Power-ups last 20% longer';
      case SnakeSkin.rainbow: return 'Combos generate 2x Fever';
      case SnakeSkin.ghost: return 'Start with Ghost power-up';
      case SnakeSkin.ninja: return 'Base movement speed +10%';
      case SnakeSkin.dragon: return 'Golden apples give +50% score';
      case SnakeSkin.vampire: return 'Bite shadow snakes for +100 coins';
      case SnakeSkin.golden: return '+25% Coin multiplier';
    }
  }

  int get price {
    switch (this) {
      case SnakeSkin.classic: return 0;
      case SnakeSkin.skeleton: return 500;
      case SnakeSkin.robot: return 1000;
      case SnakeSkin.rainbow: return 1500;
      case SnakeSkin.ghost: return 2500;
      case SnakeSkin.ninja: return 3000;
      case SnakeSkin.dragon: return 5000;
      case SnakeSkin.vampire: return 4000;
      case SnakeSkin.golden: return 10000;
    }
  }
}

