enum GameMode {
  classic,
  timeAttack,
  endless,
  campaign,
  multiplayer,
  explore,
}

extension GameModeExtension on GameMode {
  String get displayName {
    switch (this) {
      case GameMode.classic:
        return 'Classic';
      case GameMode.timeAttack:
        return 'Time Attack';
      case GameMode.endless:
        return 'Endless';
      case GameMode.campaign:
        return 'Campaign';
      case GameMode.multiplayer:
        return 'Versus';
      case GameMode.explore:
        return 'Explore';
    }
  }

  String get description {
    switch (this) {
      case GameMode.classic:
        return 'The original Nokia experience.\nWalls kill. Survive as long as you can!';
      case GameMode.timeAttack:
        return 'Score as much as possible in 60 seconds!\nSpeed bonus applies.';
      case GameMode.endless:
        return 'No walls. No limits.\nSpeed grows forever.';
      case GameMode.campaign:
        return 'Adventure mode.\nBeat levels to unlock exclusive rewards!';
      case GameMode.multiplayer:
        return 'Local split-screen.\nBattle your friends on the same device!';
      case GameMode.explore:
        return 'Open world snake.\nCamera follows you across a vast generated map!';
    }
  }

  String get icon {
    switch (this) {
      case GameMode.classic:
        return '🐍';
      case GameMode.timeAttack:
        return '⏱';
      case GameMode.endless:
        return '♾️';
      case GameMode.campaign:
        return '🗺️';
      case GameMode.multiplayer:
        return '⚔️';
      case GameMode.explore:
        return '🌍';
    }
  }
}
