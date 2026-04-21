import 'position.dart';
import '../enums/power_up_type.dart';

enum FoodType { standard, golden, poison }

class FoodModel {
  final Position position;
  final FoodType type;
  final int? expiresAtMs;

  const FoodModel({
    required this.position,
    this.type = FoodType.standard,
    this.expiresAtMs,
  });
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
