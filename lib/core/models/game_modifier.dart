import 'dart:math';

/// A randomly-rolled per-session twist shown before the game starts.
enum GameModifierType {
  doubleCoins,
  speedBoost,
  bigScore,
  invertedStart,
  frenzy,
}

class GameModifier {
  final GameModifierType type;

  const GameModifier(this.type);

  static GameModifier roll() {
    final vals = GameModifierType.values;
    return GameModifier(vals[Random().nextInt(vals.length)]);
  }

  String get title {
    switch (type) {
      case GameModifierType.doubleCoins:
        return 'DOUBLE COINS';
      case GameModifierType.speedBoost:
        return 'SPEED RUSH';
      case GameModifierType.bigScore:
        return 'SCORE STORM';
      case GameModifierType.invertedStart:
        return 'MIRROR MIND';
      case GameModifierType.frenzy:
        return 'INSTANT FEVER';
    }
  }

  String get description {
    switch (type) {
      case GameModifierType.doubleCoins:
        return 'Earn 2× coins this entire run.';
      case GameModifierType.speedBoost:
        return 'Snake is 25% faster. Score +50%.';
      case GameModifierType.bigScore:
        return 'Every food gives 2× score.';
      case GameModifierType.invertedStart:
        return 'Controls are mirrored for the first 20 seconds. Score +30%.';
      case GameModifierType.frenzy:
        return 'Fever mode is active immediately. Score +20%.';
    }
  }

  String get icon {
    switch (type) {
      case GameModifierType.doubleCoins:
        return '💰';
      case GameModifierType.speedBoost:
        return '⚡';
      case GameModifierType.bigScore:
        return '🌟';
      case GameModifierType.invertedStart:
        return '🪞';
      case GameModifierType.frenzy:
        return '🔥';
    }
  }

  /// Coin multiplier applied at end of session
  double get coinMultiplier {
    switch (type) {
      case GameModifierType.doubleCoins:
        return 2.0;
      default:
        return 1.0;
    }
  }
}
