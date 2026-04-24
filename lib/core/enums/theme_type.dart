enum ThemeType { retro, neon, nature, arcade, cyber, volcano, ice }

extension ThemeTypeExtension on ThemeType {
  String get displayName {
    switch (this) {
      case ThemeType.retro:
        return 'Retro';
      case ThemeType.neon:
        return 'Neon';
      case ThemeType.nature:
        return 'Nature';
      case ThemeType.arcade:
        return 'Arcade';
      case ThemeType.cyber:
        return 'Cyber';
      case ThemeType.volcano:
        return 'Volcano';
      case ThemeType.ice:
        return 'Ice';
    }
  }

  String get description {
    switch (this) {
      case ThemeType.retro:
        return 'Classic Nokia LCD style';
      case ThemeType.neon:
        return 'Glowing cyberpunk vibes';
      case ThemeType.nature:
        return 'Lush forest & falling leaves';
      case ThemeType.arcade:
        return 'Classic 80s coin-op';
      case ThemeType.cyber:
        return 'The Matrix enters the grid';
      case ThemeType.volcano:
        return 'Heat of the core';
      case ThemeType.ice:
        return 'Arctic frost & snowfall';
    }
  }

  String get icon {
    switch (this) {
      case ThemeType.retro:
        return '📱';
      case ThemeType.neon:
        return '💡';
      case ThemeType.nature:
        return '🌿';
      case ThemeType.arcade:
        return '🕹️';
      case ThemeType.cyber:
        return '⚡';
      case ThemeType.volcano:
        return '🌋';
      case ThemeType.ice:
        return '❄️';
    }
  }
}

enum Difficulty { easy, normal, hard, insane }

extension DifficultyExtension on Difficulty {
  String get displayName {
    switch (this) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.normal:
        return 'Normal';
      case Difficulty.hard:
        return 'Hard';
      case Difficulty.insane:
        return 'Insane';
    }
  }

  double get scoreMultiplier {
    switch (this) {
      case Difficulty.easy:
        return 1.0;
      case Difficulty.normal:
        return 1.5;
      case Difficulty.hard:
        return 2.0;
      case Difficulty.insane:
        return 3.0;
    }
  }

  int get initialSpeed {
    switch (this) {
      case Difficulty.easy:
        return 220;
      case Difficulty.normal:
        return 160;
      case Difficulty.hard:
        return 125; // was 110 — smoother entry
      case Difficulty.insane:
        return 90; // was 70 — still fast, less brutal
    }
  }

  /// ms reduction per speed threshold (higher = ramps up faster)
  int get speedScaleAmount {
    switch (this) {
      case Difficulty.easy:
        return 5;
      case Difficulty.normal:
        return 8;
      case Difficulty.hard:
        return 12; // ramps faster to compensate softer start
      case Difficulty.insane:
        return 18; // aggressive ramp — reaches extremes quickly
    }
  }
}

enum GameStatus { idle, playing, paused, gameOver }
