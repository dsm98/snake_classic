import 'position.dart';
import '../enums/power_up_type.dart';

enum FoodType {
  standard,
  golden,
  poison,
  boss,
  mouse,
  rabbit,
  lizard,
  butterfly,
  croc,
  elite,
  biomeEvent,
  fruit,
  portal,
  shrine,
  merchant
}

extension FoodTypeExtension on FoodType {
  String get loreName {
    switch (this) {
      case FoodType.standard:
        return 'Ember Seed';
      case FoodType.golden:
        return 'Radiant Core';
      case FoodType.poison:
        return 'Blight Bloom';
      case FoodType.boss:
        return 'Titan Relic';
      case FoodType.mouse:
        return 'Ashen Mouse';
      case FoodType.rabbit:
        return 'Ghost-Hearth Rabbit';
      case FoodType.lizard:
        return 'Void-Scale Lizard';
      case FoodType.butterfly:
        return 'Soul-Wing Butterfly';
      case FoodType.croc:
        return 'Mire-King Crocodile';
      case FoodType.elite:
        return 'Alpha Predator';
      case FoodType.biomeEvent:
        return 'Biome Anomaly';
      case FoodType.fruit:
        return 'Wildgrown Fruit';
      case FoodType.portal:
        return 'Void Rift';
      case FoodType.shrine:
        return 'Ancient Altar';
      case FoodType.merchant:
        return 'The Wandering Shade';
    }
  }

  String get flavorText {
    switch (this) {
      case FoodType.standard:
        return 'A small spark of life in the growing dark.';
      case FoodType.golden:
        return 'It glows with the intensity of a thousand suns.';
      case FoodType.poison:
        return 'Bitterness that corrupts the senses.';
      case FoodType.boss:
        return 'A weight that anchors the soul to the earth.';
      case FoodType.mouse:
        return 'It scurries from the light, hiding in the shadows.';
      case FoodType.rabbit:
        return 'Faster than a heartbeat, fleeting as a dream.';
      case FoodType.lizard:
        return 'A master of stillness, waiting for the perfect moment.';
      case FoodType.butterfly:
        return 'Wings made of sighs and forgotten whispers.';
      case FoodType.croc:
        return 'The apex of the mire, ancient and unyielding.';
      case FoodType.elite:
        return 'A rare apex encounter that tests your hunt mastery.';
      case FoodType.biomeEvent:
        return 'A volatile anomaly infused with local biome power.';
      case FoodType.fruit:
        return 'Ripe and radiant. Touched by the land itself.';
      case FoodType.portal:
        return 'A gateway to where the stars are different.';
      case FoodType.shrine:
        return 'Sacrifice for power; the old gods are hungry.';
      case FoodType.merchant:
        return 'He trades in curiosities that defy explanation.';
    }
  }
}

class FoodModel {
  final Position position;
  final FoodType type;
  final int? expiresAtMs;

  /// Rabbit: dash charges remaining.
  final int dashChargesLeft;

  /// Lizard: ticks remaining being still (camouflaged).
  final int stillTicksLeft;

  /// Butterfly: current sine-wave angle in radians.
  final double sinAngle;

  /// Croc: list of body segment positions (length 3: head + 2 body).
  final List<Position> crocBody;

  final int spawnTimeMs;

  const FoodModel({
    required this.position,
    this.type = FoodType.standard,
    this.expiresAtMs,
    this.spawnTimeMs = 0,
    this.dashChargesLeft = 0,
    this.stillTicksLeft = 0,
    this.sinAngle = 0.0,
    this.crocBody = const [],
  });

  FoodModel copyWith({
    Position? position,
    FoodType? type,
    int? expiresAtMs,
    int? dashChargesLeft,
    int? stillTicksLeft,
    double? sinAngle,
    int? spawnTimeMs,
    List<Position>? crocBody,
  }) {
    return FoodModel(
      position: position ?? this.position,
      type: type ?? this.type,
      expiresAtMs: expiresAtMs ?? this.expiresAtMs,
      spawnTimeMs: spawnTimeMs ?? this.spawnTimeMs,
      dashChargesLeft: dashChargesLeft ?? this.dashChargesLeft,
      stillTicksLeft: stillTicksLeft ?? this.stillTicksLeft,
      sinAngle: sinAngle ?? this.sinAngle,
      crocBody: crocBody ?? this.crocBody,
    );
  }
}

class PowerUpModel {
  final Position position;
  final PowerUpType type;
  final int expiresAtMs; // epoch ms when it disappears from board

  const PowerUpModel({
    required this.position,
    required this.type,
    required this.expiresAtMs,
  });

  bool isExpired(int nowMs) => nowMs > expiresAtMs;
}

class ActivePowerUp {
  final PowerUpType type;
  final int endsAtMs;

  const ActivePowerUp({required this.type, required this.endsAtMs});

  bool isActive(int nowMs) => nowMs < endsAtMs;

  double progress(int nowMs) {
    final total = type.durationMs;
    if (total == 0) return 0;
    final remaining = endsAtMs - nowMs;
    return (remaining / total).clamp(0.0, 1.0);
  }
}
