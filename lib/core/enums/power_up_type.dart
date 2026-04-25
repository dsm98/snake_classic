enum PowerUpType {
  speedBoost,
  slowMotion,
  scoreMultiplier,
  ghostMode,
  shrink,
  magnet,
  cursedRelic,
}

extension PowerUpTypeExtension on PowerUpType {
  String get displayName {
    switch (this) {
      case PowerUpType.speedBoost: return 'Speed Boost';
      case PowerUpType.slowMotion: return 'Slow Motion';
      case PowerUpType.scoreMultiplier: return '2x Score';
      case PowerUpType.ghostMode: return 'Ghost Mode';
      case PowerUpType.shrink: return 'Shrink';
      case PowerUpType.magnet: return 'Magnet';
      case PowerUpType.cursedRelic: return 'Wraith\'s Eye';
    }
  }

  String get icon {
    switch (this) {
      case PowerUpType.speedBoost: return '⚡';
      case PowerUpType.slowMotion: return '🐢';
      case PowerUpType.scoreMultiplier: return '💎';
      case PowerUpType.ghostMode: return '👻';
      case PowerUpType.shrink: return '✂️';
      case PowerUpType.magnet: return '🧲';
      case PowerUpType.cursedRelic: return '👁️‍🗨️';
    }
  }

  int get durationMs {
    switch (this) {
      case PowerUpType.speedBoost: return 5000;
      case PowerUpType.slowMotion: return 6000;
      case PowerUpType.scoreMultiplier: return 8000;
      case PowerUpType.ghostMode: return 5000;
      case PowerUpType.shrink: return 0; // instant
      case PowerUpType.magnet: return 7000;
      case PowerUpType.cursedRelic: return 0; // permanent effect applied instantly
    }
  }

  bool get isInstant => durationMs == 0;
}
