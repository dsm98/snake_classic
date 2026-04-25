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
  portal,
  shrine,
  merchant
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

  const FoodModel({
    required this.position,
    this.type = FoodType.standard,
    this.expiresAtMs,
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
    List<Position>? crocBody,
  }) {
    return FoodModel(
      position: position ?? this.position,
      type: type ?? this.type,
      expiresAtMs: expiresAtMs ?? this.expiresAtMs,
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
