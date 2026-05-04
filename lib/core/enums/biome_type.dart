enum BiomeType {
  forest,
  desert,
  swamp,
  cave,
  ruins,
  tundra,
  frozenLake,
  lavaField,
  ashlands,
  coral,
  jungle,
  mushroom,
  savanna,
  crystalCave,
}

extension BiomeTypeExt on BiomeType {
  String get displayName {
    switch (this) {
      case BiomeType.forest: return 'Whispering Forest';
      case BiomeType.desert: return 'Scorched Sands';
      case BiomeType.swamp: return 'Murky Mire';
      case BiomeType.cave: return 'Dark Caverns';
      case BiomeType.ruins: return 'Ancient Ruins';
      case BiomeType.tundra: return 'Frozen Tundra';
      case BiomeType.frozenLake: return 'Glacial Lake';
      case BiomeType.lavaField: return 'Magma Flows';
      case BiomeType.ashlands: return 'Burning Ashlands';
      case BiomeType.coral: return 'Abyssal Coral';
      case BiomeType.jungle: return 'Emerald Jungle';
      case BiomeType.mushroom: return 'Fungal Grove';
      case BiomeType.savanna: return 'Golden Savanna';
      case BiomeType.crystalCave: return 'Crystal Spines';
    }
  }

  String get emoji {
    switch (this) {
      case BiomeType.forest: return '🌲';
      case BiomeType.desert: return '🏜️';
      case BiomeType.swamp: return '🐊';
      case BiomeType.cave: return '🦇';
      case BiomeType.ruins: return '🏛️';
      case BiomeType.tundra: return '❄️';
      case BiomeType.frozenLake: return '🧊';
      case BiomeType.lavaField: return '🌋';
      case BiomeType.ashlands: return '🔥';
      case BiomeType.coral: return '🪸';
      case BiomeType.jungle: return '🌴';
      case BiomeType.mushroom: return '🍄';
      case BiomeType.savanna: return '🦁';
      case BiomeType.crystalCave: return '💎';
    }
  }
}
