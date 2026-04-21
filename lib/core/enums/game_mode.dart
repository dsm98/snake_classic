enum GameMode {
  classic,
  portal,
  maze,
  timeAttack,
  endless,
  campaign,
  multiplayer,
}

extension GameModeExtension on GameMode {
  String get displayName {
    switch (this) {
      case GameMode.classic: return 'Classic';
      case GameMode.portal: return 'Portal';
      case GameMode.maze: return 'Maze';
      case GameMode.timeAttack: return 'Time Attack';
      case GameMode.endless: return 'Endless';
      case GameMode.campaign: return 'Campaign';
      case GameMode.multiplayer: return 'Versus';
    }
  }

  String get description {
    switch (this) {
      case GameMode.classic: return 'The original Nokia experience.\nWalls kill. Survive as long as you can!';
      case GameMode.portal: return 'Wrap around screen edges.\nCross one side, appear on the other!';
      case GameMode.maze: return 'Navigate deadly obstacle walls.\nOnly the sharpest survive.';
      case GameMode.timeAttack: return 'Score as much as possible in 60 seconds!\nSpeed bonus applies.';
      case GameMode.endless: return 'No walls. No limits.\nSpeed grows forever.';
      case GameMode.campaign: return 'Adventure mode.\nBeat levels to unlock exclusive rewards!';
      case GameMode.multiplayer: return 'Local split-screen.\nBattle your friends on the same device!';
    }
  }

  String get icon {
    switch (this) {
      case GameMode.classic: return '🐍';
      case GameMode.portal: return '🌀';
      case GameMode.maze: return '🏰';
      case GameMode.timeAttack: return '⏱';
      case GameMode.endless: return '♾️';
      case GameMode.campaign: return '🗺️';
      case GameMode.multiplayer: return '⚔️';
    }
  }
}
