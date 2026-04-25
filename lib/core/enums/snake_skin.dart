enum SnakeSkin {
  classic,
  skeleton,
  robot,
  rainbow,
  ghost,
  ninja,
  dragon,
  vampire,
  golden,
  // Safari-exclusive — unlocked via milestones, cannot be bought
  jadeSerpent,
  monarchWyrm,
  crocBane,
}

enum SkinRarity { common, rare, epic, legendary, safari }

extension SnakeSkinExtension on SnakeSkin {
  String get displayName {
    switch (this) {
      case SnakeSkin.classic:
        return 'Classic';
      case SnakeSkin.skeleton:
        return 'Skeletal';
      case SnakeSkin.robot:
        return 'Mecha Snake';
      case SnakeSkin.rainbow:
        return 'Prism';
      case SnakeSkin.ghost:
        return 'Phantom';
      case SnakeSkin.ninja:
        return 'Ninja';
      case SnakeSkin.dragon:
        return 'Dragon';
      case SnakeSkin.vampire:
        return 'Vampire';
      case SnakeSkin.golden:
        return 'Radiant Gold';
      case SnakeSkin.jadeSerpent:
        return 'Jade Serpent';
      case SnakeSkin.monarchWyrm:
        return 'Monarch Wyrm';
      case SnakeSkin.crocBane:
        return 'Croc Bane';
    }
  }

  SkinRarity get rarity {
    switch (this) {
      case SnakeSkin.classic:
        return SkinRarity.common;
      case SnakeSkin.skeleton:
        return SkinRarity.common;
      case SnakeSkin.robot:
        return SkinRarity.rare;
      case SnakeSkin.rainbow:
        return SkinRarity.rare;
      case SnakeSkin.ghost:
        return SkinRarity.epic;
      case SnakeSkin.ninja:
        return SkinRarity.epic;
      case SnakeSkin.dragon:
        return SkinRarity.legendary;
      case SnakeSkin.vampire:
        return SkinRarity.epic;
      case SnakeSkin.golden:
        return SkinRarity.legendary;
      case SnakeSkin.jadeSerpent:
        return SkinRarity.safari;
      case SnakeSkin.monarchWyrm:
        return SkinRarity.safari;
      case SnakeSkin.crocBane:
        return SkinRarity.safari;
    }
  }

  String get advantageDescription {
    switch (this) {
      case SnakeSkin.classic:
        return 'No advantage. Pure skill.';
      case SnakeSkin.skeleton:
        return '+5% Score multiplier';
      case SnakeSkin.robot:
        return 'Power-ups last 20% longer';
      case SnakeSkin.rainbow:
        return 'Combos generate 2x Fever';
      case SnakeSkin.ghost:
        return 'Start with Ghost power-up';
      case SnakeSkin.ninja:
        return 'Base movement speed +10%';
      case SnakeSkin.dragon:
        return 'Golden apples give +50% score';
      case SnakeSkin.vampire:
        return 'Bite shadow snakes for +100 coins';
      case SnakeSkin.golden:
        return '+25% Coin multiplier';
      case SnakeSkin.jadeSerpent:
        return 'Lizards award +50% points';
      case SnakeSkin.monarchWyrm:
        return 'Butterfly timer lasts 2× longer';
      case SnakeSkin.crocBane:
        return 'Immune to croc stun';
    }
  }

  /// Safari skins are milestone-unlocked, not purchasable
  bool get isSafariExclusive {
    return rarity == SkinRarity.safari;
  }

  /// For safari skins: description of how to unlock
  String get safariUnlockHint {
    switch (this) {
      case SnakeSkin.jadeSerpent:
        return 'Catch 100 lizards in Safari mode';
      case SnakeSkin.monarchWyrm:
        return 'Catch 50 butterflies in Safari mode';
      case SnakeSkin.crocBane:
        return 'Catch 20 crocodiles in Safari mode';
      default:
        return '';
    }
  }

  /// Milestone target for safari skins
  int get safariUnlockTarget {
    switch (this) {
      case SnakeSkin.jadeSerpent:
        return 100;
      case SnakeSkin.monarchWyrm:
        return 50;
      case SnakeSkin.crocBane:
        return 20;
      default:
        return 0;
    }
  }

  /// Which safari prey type to track for this skin
  String get safariUnlockPreyType {
    switch (this) {
      case SnakeSkin.jadeSerpent:
        return 'lizard';
      case SnakeSkin.monarchWyrm:
        return 'butterfly';
      case SnakeSkin.crocBane:
        return 'croc';
      default:
        return '';
    }
  }

  String get emoji {
    switch (this) {
      case SnakeSkin.classic:
        return '🐍';
      case SnakeSkin.skeleton:
        return '💀';
      case SnakeSkin.robot:
        return '🤖';
      case SnakeSkin.rainbow:
        return '🌈';
      case SnakeSkin.ghost:
        return '👻';
      case SnakeSkin.ninja:
        return '🥷';
      case SnakeSkin.dragon:
        return '🐉';
      case SnakeSkin.vampire:
        return '🧛';
      case SnakeSkin.golden:
        return '✨';
      case SnakeSkin.jadeSerpent:
        return '🦎';
      case SnakeSkin.monarchWyrm:
        return '🦋';
      case SnakeSkin.crocBane:
        return '🐊';
    }
  }

  int get price {
    switch (this) {
      case SnakeSkin.classic:
        return 0;
      case SnakeSkin.skeleton:
        return 250;
      case SnakeSkin.robot:
        return 600;
      case SnakeSkin.rainbow:
        return 1000;
      case SnakeSkin.ghost:
        return 1800;
      case SnakeSkin.ninja:
        return 2200;
      case SnakeSkin.vampire:
        return 3000;
      case SnakeSkin.dragon:
        return 4000;
      case SnakeSkin.golden:
        return 7500;
      // Safari skins: not for sale
      case SnakeSkin.jadeSerpent:
        return 0;
      case SnakeSkin.monarchWyrm:
        return 0;
      case SnakeSkin.crocBane:
        return 0;
    }
  }

  String get lore {
    switch (this) {
      case SnakeSkin.classic:
        return 'The progenitor. A simple serpent from a forgotten era.';
      case SnakeSkin.skeleton:
        return 'Reanimated bones bound by a hunger that never dies.';
      case SnakeSkin.robot:
        return 'A high-precision hunter forged in the fires of the Great Forge.';
      case SnakeSkin.rainbow:
        return 'A celestial traveler that leaves a trail of pure starlight.';
      case SnakeSkin.ghost:
        return 'A restless spirit that flickers between this realm and the Void.';
      case SnakeSkin.ninja:
        return 'A shadow that strikes without sound, leaving only a whisper.';
      case SnakeSkin.dragon:
        return 'An ancient wyrm of legendary power, hoarding the riches of the world.';
      case SnakeSkin.vampire:
        return 'A creature of the night that feasts on the essence of its rivals.';
      case SnakeSkin.golden:
        return 'The ultimate evolution of the serpent, shining with divine light.';
      case SnakeSkin.jadeSerpent:
        return 'A guardian of the deep jungles, carved from the earth itself.';
      case SnakeSkin.monarchWyrm:
        return 'A royal predator that commands the winds of the shifting sands.';
      case SnakeSkin.crocBane:
        return 'A hunter of giants, wearing the scales of its fallen foes.';
    }
  }
}
