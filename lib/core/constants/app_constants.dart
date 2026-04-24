class AppConstants {
  // Explore mode — large open world
  static const int exploreGridColumns = 80;
  static const int exploreGridRows = 110; // 11 rooms × 10 cell blocks
  // Visible viewport: same visual size as normal grid
  static const int exploreViewportCols = 20;
  static const int exploreViewportRows = 28;
  static const int exploreStartX = 45; // center of room rx=4 (block 4 × 10 + 5)
  static const int exploreStartY = 55; // center of room ry=5 (block 5 × 10 + 5)

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
  static const int blitzSeconds = 90;
  static const int blitzBonusSecondsPerFood = 3;

  // Maze obstacle counts per difficulty
  static const int mazeObstaclesEasy = 8;
  static const int mazeObstaclesNormal = 15;
  static const int mazeObstaclesHard = 25;
  static const int mazeObstaclesInsane = 35;

  // Ads
  static const int interstitialEveryNGames =
      4; // show interstitial every N games (non-intrusive)

  // Session economy balance
  static const int maxRevivesPerRun = 2;

  // Shop / gacha balance
  static const int gachaSpinCost = 900;
  static const int gachaDuplicateCompensationCommon = 250;
  static const int gachaDuplicateCompensationRare = 320;
  static const int gachaDuplicateCompensationEpic = 420;
  static const int gachaDuplicateCompensationLegendary = 650;
}
