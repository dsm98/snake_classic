class AppConstants {
  // Grid
  static const int gridColumns = 20;
  static const int gridRows = 28;
  static const double cellSize = 16.0;

  // Initial snake position (center)
  static const int startX = 10;
  static const int startY = 14;
  static const int initialSnakeLength = 3;

  // Speeds (milliseconds per tick)
  static const int speedEasy = 220;
  static const int speedNormal = 160;
  static const int speedHard = 110;
  static const int speedInsane = 70;

  // Speed scaling: every N segments gained, decrease tick by M ms
  static const int speedScaleEvery = 5;
  static const int speedScaleAmount = 8; // ms to reduce per threshold
  static const int speedMin = 50; // never go below this

  // Power-up
  static const int powerUpSpawnChance = 15; // % chance per food eaten
  static const int powerUpDurationMs = 5000;
  static const int powerUpDurationSeconds = 5;
  static const int powerUpMaxOnBoard = 2;

  // Scoring
  static const int baseScore = 10;
  static const int comboMultiplierMax = 5;
  static const int comboWindow = 3; // seconds to maintain combo

  // Time Attack
  static const int timeAttackSeconds = 60;

  // Maze obstacle counts per difficulty
  static const int mazeObstaclesEasy = 8;
  static const int mazeObstaclesNormal = 15;
  static const int mazeObstaclesHard = 25;
  static const int mazeObstaclesInsane = 35;

  // Ads
  static const int interstitialEveryNGames = 2;
}
