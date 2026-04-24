enum GearType {
  speedTonic,
  ghostShell,
  preyMagnet,
  biomeMap,
  dashScroll,
}

class ExpeditionGear {
  const ExpeditionGear._();

  static const List<GearDef> all = [
    GearDef(
      type: GearType.speedTonic,
      name: 'Speed Tonic',
      emoji: '🧪',
      description: '+20% movement speed for 60 seconds',
      gemPrice: 4,
      effectDurationMs: 60000,
    ),
    GearDef(
      type: GearType.ghostShell,
      name: 'Ghost Shell',
      emoji: '🛡️',
      description: 'Ignore 1 wall collision per run',
      gemPrice: 8,
      effectDurationMs: -1, // passive
    ),
    GearDef(
      type: GearType.preyMagnet,
      name: 'Prey Magnet',
      emoji: '🔮',
      description: 'All prey drift toward you for 30 seconds',
      gemPrice: 6,
      effectDurationMs: 30000,
    ),
    GearDef(
      type: GearType.biomeMap,
      name: 'Biome Map',
      emoji: '🗺️',
      description: 'Instantly reveals all room biomes on the minimap',
      gemPrice: 5,
      effectDurationMs: -1, // instant
    ),
    GearDef(
      type: GearType.dashScroll,
      name: 'Dash Scroll',
      emoji: '⚡',
      description: 'Grants rabbit-style dash ability (3 charges)',
      gemPrice: 5,
      effectDurationMs: -1, // passive per-charge
    ),
  ];

  static GearDef byType(GearType t) => all.firstWhere((g) => g.type == t);
}

class GearDef {
  final GearType type;
  final String name;
  final String emoji;
  final String description;
  final int gemPrice;
  final int effectDurationMs; // -1 = instant/passive

  const GearDef({
    required this.type,
    required this.name,
    required this.emoji,
    required this.description,
    required this.gemPrice,
    required this.effectDurationMs,
  });
}
