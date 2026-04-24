import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:vibration/vibration.dart';
import '../core/constants/app_constants.dart';
import '../core/enums/direction.dart';
import '../core/enums/game_mode.dart';
import '../core/enums/power_up_type.dart';
import '../core/enums/theme_type.dart';
import '../core/enums/snake_skin.dart';
import '../core/models/position.dart';
import '../core/models/food_model.dart';
import '../core/models/campaign_level.dart';
import '../core/enums/biome_type.dart';
import 'analytics_service.dart';
import 'vibration_service.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../core/models/daily_event.dart';
import '../core/models/game_modifier.dart';

enum BoardEvent { none, lightsOut, iceBoard }

class GameEngine extends ChangeNotifier {
  // ── State ──────────────────────────────────────────────────────
  List<Position> snake = [];
  HashSet<Position> snakeSet = HashSet<Position>();
  List<Position> trail = [];
  List<Position> sessionPath = [];
  List<Position> ghostPath = [];
  int ghostIndex = 0;
  ShadowSnake? activeShadow;
  FoodModel? food;
  List<FoodModel> preyList = [];
  Map<int, BiomeType> roomBiomes = {};
  final Set<int> _visitedRoomKeys = {};
  int get visitedRooms => _visitedRoomKeys.length;
  List<PowerUpModel> boardPowerUps = [];
  List<ActivePowerUp> activePowerUps = [];
  HashSet<Position> obstacleSet = HashSet<Position>();
  List<GameEffect> effects = [];

  Direction currentDirection = Direction.right;
  final List<Direction> _directionQueue = [];

  int score = 0;
  int combo = 0;
  int comboLastFoodMs = 0;
  bool isPlaying = false;
  bool isPaused = false;
  bool isGameOver = false;
  int highestScoreOnRecord = 0;
  bool isHighScoreCelebrated = false;
  int timeRemainingSeconds = AppConstants.timeAttackSeconds;
  int currentTickMs = AppConstants.speedNormal;
  int invertControlsUntilMs = 0;

  bool isBoosting = false;
  int feverMeter = 0;
  bool isFeverMode = false;
  int feverEndMs = 0;
  SnakeSkin equippedSkin = SnakeSkin.classic;

  // Session Stats
  int powerUpsCollectedSession = 0;
  int goldenApplesEatenSession = 0;
  int poisonApplesEatenSession = 0;
  int coinsEarnedSession = 0;

  Map<Position, Position> boardPortals = {};
  Map<Position, int> portalIndices = {};

  // ── Explore mode ───────────────────────────────────────────────
  /// Camera top-left corner in grid cells (updated each tick)
  int cameraX = 0;
  int cameraY = 0;

  /// Previous camera position for smooth inter-tick interpolation
  int prevCameraX = 0;
  int prevCameraY = 0;

  // Hunt Streak (explore-mode combo)
  int huntStreak = 0;
  int huntStreakEndMs = 0; // 30s window to catch a DIFFERENT type
  FoodType? lastCaughtType;
  bool isSuperHunter = false; // streak ≥ 5
  int superHunterEndMs = 0;

  // Croc stun
  bool isCrocStunned = false;
  int crocStunEndMs = 0;

  // Expedition gear state
  int wallHitsLeft = 0; // ghostShell: absorbs 1 wall hit
  int preyMagnetEndMs = 0; // preyMagnet: prey drift toward head
  bool biomeMapActive = false; // biomeMap: reveal all rooms
  int dashCharges = 0; // dashScroll: instant-move charges

  int get gridCols => gameMode == GameMode.explore
      ? AppConstants.exploreGridColumns
      : AppConstants.gridColumns;
  int get gridRows => gameMode == GameMode.explore
      ? AppConstants.exploreGridRows
      : AppConstants.gridRows;
  int get startX => gameMode == GameMode.explore
      ? AppConstants.exploreStartX
      : AppConstants.startX;
  int get startY => gameMode == GameMode.explore
      ? AppConstants.exploreStartY
      : AppConstants.startY;

  CampaignLevel? activeCampaignLevel;
  bool isCampaignWon = false;

  BoardEvent activeEvent = BoardEvent.none;
  int eventEndMs = 0;

  bool comebackBonus = false;
  int comebackBonusEndMs = 0;

  // Boss food
  int _bossMoveTick = 0;
  static const int _bossMovePeriod = 3; // move every N game ticks

  DailyEvent? activeDailyEvent;
  GameModifier? activeModifier;

  GameMode gameMode = GameMode.classic;
  Difficulty difficulty = Difficulty.normal;

  int lastTickRealtimeMs = 0;

  double get movementProgress {
    if (isPaused || isGameOver) return 1.0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = now - lastTickRealtimeMs;
    return (elapsed / currentTickMs).clamp(0.0, 1.0);
  }

  // Callbacks
  VoidCallback? onFoodEaten;
  VoidCallback? onPowerUpCollected;
  VoidCallback? onPoisonEaten;
  VoidCallback? onComboDropped;
  VoidCallback? onHighScoreReached;
  VoidCallback? onGameOver;

  // ── Private ────────────────────────────────────────────────────
  Ticker? _ticker;
  Duration _lastTickTime = Duration.zero;
  Timer? _timeAttackTimer;
  bool _shouldSkidNextTick = false;
  Direction? _skidTurnDirection;

  Future<void> _vibrate(int duration, int amplitude) async {
    try {
      if (await Vibration.hasVibrator()) {
        if (await Vibration.hasAmplitudeControl()) {
          Vibration.vibrate(duration: duration, amplitude: amplitude);
        } else {
          Vibration.vibrate(duration: duration);
        }
      }
    } catch (_) {}
  }

  final Random _rng = Random();
  int _foodEatenSinceLastPowerUp = 0;
  int _preyTickCounter = 0;
  // New-player grace: gentler speed scaling for first 5 games
  bool _newPlayerGrace = false;

  void init({
    required GameMode mode,
    required Difficulty diff,
    required SnakeSkin skin,
    CampaignLevel? campaignLevel,
    bool withComebackBonus = false,
    DailyEvent? dailyEvent,
    GameModifier? modifier,
    List<String> equippedGear = const [],
  }) {
    gameMode = mode;
    difficulty = diff;
    equippedSkin = skin;
    activeCampaignLevel = campaignLevel;
    activeDailyEvent = dailyEvent;
    activeModifier = modifier;

    final gamesPlayed = StorageService().gamesPlayed;
    _newPlayerGrace = gamesPlayed < 5;

    ghostPath = StorageService().getBestReplay();
    ghostIndex = 0;
    sessionPath = [];

    currentTickMs = diff.initialSpeed;
    // Soften starting speed for very first 3 games (20% slower)
    if (gamesPlayed < 3 && gameMode != GameMode.campaign) {
      currentTickMs = (currentTickMs * 1.2).round();
    }

    if (gameMode == GameMode.campaign && campaignLevel != null) {
      currentTickMs =
          (AppConstants.speedNormal / campaignLevel.speedMultiplier).round();
    }

    if (gameMode == GameMode.blitz) {
      currentTickMs = (currentTickMs * 0.85).round();
    }

    // Explore mode: start slower so the large map is enjoyable to navigate
    if (gameMode == GameMode.explore) {
      currentTickMs = (currentTickMs * 1.5).round();
    }

    // Apply daily event modifiers
    if (activeDailyEvent != null) {
      if (activeDailyEvent!.type == DailyEventType.speedDash) {
        currentTickMs = (currentTickMs / 2).round();
      } else if (activeDailyEvent!.type == DailyEventType.zenMode) {
        currentTickMs = (currentTickMs * 1.5).round();
      }
    }

    // Apply modifier effects
    if (activeModifier != null) {
      switch (activeModifier!.type) {
        case GameModifierType.speedBoost:
          currentTickMs = (currentTickMs * 0.75).round();
          break;
        case GameModifierType.frenzy:
          // Fever fires immediately after _reset
          break;
        default:
          break;
      }
    }

    _reset();

    // Apply post-reset modifier effects
    if (activeModifier != null) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      switch (activeModifier!.type) {
        case GameModifierType.invertedStart:
          invertControlsUntilMs = nowMs + 20000;
          break;
        case GameModifierType.frenzy:
          isFeverMode = true;
          feverEndMs = nowMs + 8000;
          feverMeter = 0;
          break;
        default:
          break;
      }
    }

    if (equippedSkin == SnakeSkin.ghost) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      activePowerUps.add(
        ActivePowerUp(
          type: PowerUpType.ghostMode,
          endsAtMs: nowMs + AppConstants.powerUpDurationMs,
        ),
      );
    }

    // Apply expedition gear effects
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    for (final gear in equippedGear) {
      switch (gear) {
        case 'speedTonic':
          currentTickMs = (currentTickMs * 0.8).round();
          break;
        case 'ghostShell':
          wallHitsLeft = 1;
          break;
        case 'preyMagnet':
          preyMagnetEndMs = nowMs + 30000;
          break;
        case 'biomeMap':
          biomeMapActive = true;
          break;
        case 'dashScroll':
          dashCharges = 3;
          break;
      }
    }

    if (withComebackBonus) {
      comebackBonus = true;
      comebackBonusEndMs = DateTime.now().millisecondsSinceEpoch + 30000;
    }

    highestScoreOnRecord = StorageService().bestScore;
    isHighScoreCelebrated = false;
  }

  void _reset() {
    snake = [
      Position(startX, startY),
      Position(startX - 1, startY),
      Position(startX - 2, startY),
    ];
    snakeSet = HashSet<Position>.from(snake);
    cameraX = startX - AppConstants.exploreViewportCols ~/ 2;
    cameraY = startY - AppConstants.exploreViewportRows ~/ 2;
    prevCameraX = cameraX;
    prevCameraY = cameraY;
    currentDirection = Direction.right;
    _directionQueue.clear();
    score = 0;
    combo = 0;
    comboLastFoodMs = 0;
    isGameOver = false;
    isCampaignWon = false;
    isHighScoreCelebrated = false;
    _shouldSkidNextTick = false;
    _skidTurnDirection = null;
    isPaused = false;
    activeEvent = BoardEvent.none;
    eventEndMs = 0;
    comebackBonus = false;
    comebackBonusEndMs = 0;
    boardPowerUps.clear();
    activePowerUps.clear();
    trail.clear();
    effects.clear();
    _foodEatenSinceLastPowerUp = 0;
    _bossMoveTick = 0;
    _preyTickCounter = 0;
    preyList.clear();
    roomBiomes.clear();
    _visitedRoomKeys.clear();
    huntStreak = 0;
    huntStreakEndMs = 0;
    lastCaughtType = null;
    isSuperHunter = false;
    superHunterEndMs = 0;
    isCrocStunned = false;
    crocStunEndMs = 0;
    wallHitsLeft = 0;
    preyMagnetEndMs = 0;
    biomeMapActive = false;
    dashCharges = 0;
    timeRemainingSeconds = gameMode == GameMode.blitz
        ? AppConstants.blitzSeconds
        : AppConstants.timeAttackSeconds;
    if (gameMode == GameMode.campaign &&
        activeCampaignLevel?.timeLimitSeconds != null &&
        activeCampaignLevel!.timeLimitSeconds > 0) {
      timeRemainingSeconds = activeCampaignLevel!.timeLimitSeconds;
    }
    invertControlsUntilMs = 0;
    isBoosting = false;
    feverMeter = 0;
    isFeverMode = false;
    feverEndMs = 0;
    powerUpsCollectedSession = 0;
    goldenApplesEatenSession = 0;
    poisonApplesEatenSession = 0;

    obstacleSet.clear();
    boardPortals.clear();
    portalIndices.clear();

    // Physical perimeter walls for non-wrapping modes
    if (gameMode != GameMode.endless &&
        gameMode != GameMode.campaign &&
        gameMode != GameMode.explore) {
      _generatePerimeterWalls();
    } else if (gameMode == GameMode.campaign) {
      _generatePerimeterWalls();
      _generateCampaignObstacles();
      if (activeCampaignLevel!.hasPortals) _generateTruePortals();
    } else if (gameMode == GameMode.explore) {
      _generateExploreMap();
    }

    if (gameMode == GameMode.maze || gameMode == GameMode.portal) {
      _generateMazeObstacles();
    }

    if (gameMode == GameMode.portal) {
      _generateTruePortals();
    }

    if (gameMode == GameMode.explore) {
      _spawnInitialPrey();
    } else {
      _spawnFood();
    }
    _updateCamera();
    notifyListeners();
  }

  void _generatePerimeterWalls() {
    for (int x = 0; x < AppConstants.gridColumns; x++) {
      obstacleSet.add(Position(x, 0)); // Top wall
      obstacleSet.add(Position(x, AppConstants.gridRows - 1)); // Bottom wall
    }
    for (int y = 1; y < AppConstants.gridRows - 1; y++) {
      obstacleSet.add(Position(0, y)); // Left wall
      obstacleSet.add(Position(AppConstants.gridColumns - 1, y)); // Right wall
    }
  }

  /// Room-and-corridor map: guarantees every open area is reachable, all
  /// corridors are 3 cells wide so the snake can always turn back.
  void _generateExploreMap() {
    const int cols = AppConstants.exploreGridColumns; // 80
    const int rows = AppConstants.exploreGridRows; // 110
    const int bs = 10; // block (room) size
    const int roomCols = cols ~/ bs; // 8
    const int roomRows = rows ~/ bs; // 11

    // --- 1. Fill entire map with walls ---
    for (int x = 0; x < cols; x++) {
      for (int y = 0; y < rows; y++) {
        obstacleSet.add(Position(x, y));
      }
    }

    // --- 2. Carve room interiors (positions 2..7 within each bs×bs block) ---
    for (int rx = 0; rx < roomCols; rx++) {
      for (int ry = 0; ry < roomRows; ry++) {
        for (int dx = 2; dx <= 7; dx++) {
          for (int dy = 2; dy <= 7; dy++) {
            obstacleSet.remove(Position(rx * bs + dx, ry * bs + dy));
          }
        }
      }
    }

    // --- 3. Prim's spanning tree to connect all rooms ---
    // Start from the room containing the spawn point
    final int spawnRx = AppConstants.exploreStartX ~/ bs; // 4
    final int spawnRy = AppConstants.exploreStartY ~/ bs; // 5

    final Set<int> inTree = {};
    // Frontier entries: [fromRx, fromRy, toRx, toRy]
    final List<List<int>> frontier = [];

    void addNeighbors(int rx, int ry) {
      if (rx > 0) frontier.add([rx, ry, rx - 1, ry]);
      if (rx < roomCols - 1) frontier.add([rx, ry, rx + 1, ry]);
      if (ry > 0) frontier.add([rx, ry, rx, ry - 1]);
      if (ry < roomRows - 1) frontier.add([rx, ry, rx, ry + 1]);
    }

    inTree.add(spawnRx * roomRows + spawnRy);
    addNeighbors(spawnRx, spawnRy);

    while (inTree.length < roomCols * roomRows) {
      if (frontier.isEmpty) break;
      final edgeIdx = _rng.nextInt(frontier.length);
      final edge = frontier.removeAt(edgeIdx);
      final int nRx = edge[2], nRy = edge[3];
      final int nIdx = nRx * roomRows + nRy;
      if (!inTree.contains(nIdx)) {
        inTree.add(nIdx);
        _carveCorridorBetween(edge[0], edge[1], nRx, nRy, bs);
        addNeighbors(nRx, nRy);
      }
    }

    // --- 4. Add extra corridors (~55% of remaining possible edges) for loops ---
    for (int rx = 0; rx < roomCols; rx++) {
      for (int ry = 0; ry < roomRows; ry++) {
        if (rx + 1 < roomCols && _rng.nextDouble() < 0.55) {
          _carveCorridorBetween(rx, ry, rx + 1, ry, bs);
        }
        if (ry + 1 < roomRows && _rng.nextDouble() < 0.55) {
          _carveCorridorBetween(rx, ry, rx, ry + 1, bs);
        }
      }
    }

    // --- 5. Assign a random biome to every room ---
    final biomeValues = BiomeType.values;
    for (int rx = 0; rx < roomCols; rx++) {
      for (int ry = 0; ry < roomRows; ry++) {
        roomBiomes[rx * roomRows + ry] =
            biomeValues[_rng.nextInt(biomeValues.length)];
      }
    }
  }

  /// Carve a 3-wide corridor between two adjacent rooms in the block grid.
  void _carveCorridorBetween(int rx1, int ry1, int rx2, int ry2, int bs) {
    // Normalize so we always go right or down
    if (rx1 > rx2 || (rx1 == rx2 && ry1 > ry2)) {
      _carveCorridorBetween(rx2, ry2, rx1, ry1, bs);
      return;
    }

    if (rx2 == rx1 + 1 && ry2 == ry1) {
      // Horizontal: carve 4 wall cells between block rx1 and rx2
      // Wall cells: x = rx1*bs+8, rx1*bs+9, rx2*bs+0, rx2*bs+1
      final int xStart = rx1 * bs + 8;
      final int xEnd = rx2 * bs + 1;
      final int cy = ry1 * bs + 5; // centre of room in y
      for (int x = xStart; x <= xEnd; x++) {
        obstacleSet.remove(Position(x, cy - 1));
        obstacleSet.remove(Position(x, cy));
        obstacleSet.remove(Position(x, cy + 1));
      }
    } else if (ry2 == ry1 + 1 && rx2 == rx1) {
      // Vertical: carve 4 wall cells between block ry1 and ry2
      final int yStart = ry1 * bs + 8;
      final int yEnd = ry2 * bs + 1;
      final int cx = rx1 * bs + 5; // centre of room in x
      for (int y = yStart; y <= yEnd; y++) {
        obstacleSet.remove(Position(cx - 1, y));
        obstacleSet.remove(Position(cx, y));
        obstacleSet.remove(Position(cx + 1, y));
      }
    }
  }

  void start() {
    isPlaying = true;
    isPaused = false;
    _startTimer();
    if (gameMode == GameMode.timeAttack ||
        gameMode == GameMode.blitz ||
        (gameMode == GameMode.campaign &&
            activeCampaignLevel!.timeLimitSeconds > 0)) {
      _startTimeAttackTimer();
    }
  }

  void pause() {
    isPaused = true;
    _ticker?.stop();
    _timeAttackTimer?.cancel();
    notifyListeners();
  }

  void resume() {
    isPaused = false;
    _startTimer();
    if (gameMode == GameMode.timeAttack ||
        gameMode == GameMode.blitz ||
        (gameMode == GameMode.campaign &&
            activeCampaignLevel!.timeLimitSeconds > 0)) {
      _startTimeAttackTimer();
    }
  }

  void restart() {
    _ticker?.stop();
    _timeAttackTimer?.cancel();
    currentTickMs = difficulty.initialSpeed;
    if (gameMode == GameMode.explore) {
      currentTickMs = (currentTickMs * 1.5).round();
    }
    _reset();
    start();
  }

  void changeDirection(Direction newDir) {
    // Croc stun blocks turning
    if (isCrocStunned && DateTime.now().millisecondsSinceEpoch < crocStunEndMs)
      return;
    if (DateTime.now().millisecondsSinceEpoch < invertControlsUntilMs) {
      newDir = newDir.opposite();
    }
    if (_directionQueue.isNotEmpty) {
      final last = _directionQueue.last;
      if (last.isOpposite(newDir) || last == newDir) return;
    } else {
      if (currentDirection.isOpposite(newDir) || currentDirection == newDir)
        return;
    }
    if (_directionQueue.length < 3) {
      _directionQueue.add(newDir);
    }
  }

  void setBoosting(bool value) {
    isBoosting = value;
  }

  void _startTimer() {
    _ticker?.stop();
    _lastTickTime = Duration.zero;
    _ticker ??= Ticker(_onTick);
    if (!_ticker!.isActive) {
      _ticker!.start();
    }
  }

  void _onTick(Duration elapsed) {
    if (isPaused || isGameOver) return;
    int currentDelay = currentTickMs;

    // Skin advantage ninja speed
    if (equippedSkin == SnakeSkin.ninja)
      currentDelay = (currentDelay * 0.9).round();

    if (isFeverMode) {
      currentDelay = (currentDelay * 0.7).round();
    } else if (isBoosting) {
      currentDelay = (currentDelay * 0.5).round();
    }

    if (_lastTickTime == Duration.zero ||
        elapsed.inMilliseconds - _lastTickTime.inMilliseconds >= currentDelay) {
      _lastTickTime = elapsed;
      lastTickRealtimeMs = DateTime.now().millisecondsSinceEpoch;
      if (isBoosting && score > 0) {
        score -= 2; // Drains score when boosting
        if (score < 0) score = 0;
      }
      _tick();
    }
  }

  void _tick() {
    Direction? nextDir;

    if (_directionQueue.isNotEmpty) {
      nextDir = _directionQueue.removeAt(0);
    }

    if (activeEvent == BoardEvent.iceBoard &&
        nextDir != null &&
        !_shouldSkidNextTick) {
      // First turn request on ice? Skid!
      _shouldSkidNextTick = true;
      _skidTurnDirection = nextDir;
      // We don't change currentDirection yet, stay on path for one more tick
    } else if (_shouldSkidNextTick) {
      // Skidding finished, apply the turn we saved
      if (_skidTurnDirection != null) currentDirection = _skidTurnDirection!;
      _shouldSkidNextTick = false;
      _skidTurnDirection = null;
      // If the user tapped ANOTHER turn while skidding, it remains in queue for next tick
    } else if (nextDir != null) {
      currentDirection = nextDir;
    }

    // Advance ghost
    if (ghostPath.isNotEmpty && ghostIndex < ghostPath.length) {
      ghostIndex++;
    }

    // Move boss food every N ticks
    if (food?.type == FoodType.boss) {
      _bossMoveTick++;
      if (_bossMoveTick >= _bossMovePeriod) {
        _bossMoveTick = 0;
        _moveBossFood();
      }
    }

    // Advance shadow
    if (activeShadow != null) {
      _moveShadow();
    }

    // Move prey every 3 ticks (explore mode)
    if (gameMode == GameMode.explore) {
      _preyTickCounter++;
      if (_preyTickCounter >= 3) {
        _preyTickCounter = 0;
        _movePrey();
      }
    }

    if (isFeverMode) {
      _attractFood();
    } else if (_hasPowerUp(PowerUpType.magnet) && food != null) {
      _attractFood();
    }

    final head = snake.first;
    final Position newHead = _nextHead(head);

    if (!_isValidPosition(newHead)) {
      // ghostShell absorbs the first out-of-bounds or obstacle hit
      if (wallHitsLeft > 0) {
        wallHitsLeft--;
        // Keep the snake in place this tick — don't advance
        return;
      }
      _triggerGameOver();
      return;
    }

    PowerUpModel? collectedPowerUp;
    for (final pu in boardPowerUps) {
      if (pu.position == newHead) {
        collectedPowerUp = pu;
        break;
      }
    }

    final oldTail = snake.last;
    snake.insert(0, newHead);
    snakeSet.add(newHead);

    // Track rooms visited in explore mode
    if (gameMode == GameMode.explore) {
      final rx = newHead.x ~/ 10;
      final ry = newHead.y ~/ 10;
      _visitedRoomKeys.add(rx * 11 + ry);
    }

    if (gameMode == GameMode.explore) {
      // Explore uses preyList instead of single food
      FoodModel? eatenPrey;
      bool hitCrocBody = false;
      for (final prey in preyList) {
        if (newHead == prey.position) {
          eatenPrey = prey;
          break;
        }
        // Check croc body segments (non-head)
        if (prey.type == FoodType.croc && prey.crocBody.length > 1) {
          for (int b = 1; b < prey.crocBody.length; b++) {
            if (newHead == prey.crocBody[b]) {
              hitCrocBody = true;
              break;
            }
          }
        }
        if (hitCrocBody) break;
      }
      if (eatenPrey != null) {
        preyList.remove(eatenPrey);
        _onPreyEaten(eatenPrey);
        // Snake grows — don't remove tail
      } else if (hitCrocBody) {
        // crocBane skin: immune to croc stun
        if (equippedSkin == SnakeSkin.crocBane) {
          // skip stun entirely
        } else {
          // Stun — can't turn for 2 ticks (reuse invertControlsUntilMs as a direction-lock)
          final now = DateTime.now().millisecondsSinceEpoch;
          isCrocStunned = true;
          crocStunEndMs = now + (currentTickMs * 2);
          VibrationService().vibrate(duration: 200, amplitude: 200);
          effects.add(GameEffect(
            position: snake.first,
            type: EffectType.comboBurst,
            value: '🐊 STUNNED!',
            startTimeMs: now,
          ));
        } // end else (not crocBane)
        snake.removeLast();
        snakeSet.remove(oldTail);
      } else {
        snake.removeLast();
        snakeSet.remove(oldTail);
      }
    } else {
      if (food != null && newHead == food!.position) {
        _onFoodEaten();
      } else {
        snake.removeLast();
        snakeSet.remove(oldTail);
      }
    }

    // Update trail
    trail.insert(0, oldTail);
    if (trail.length > 5) {
      trail.removeLast();
    }

    sessionPath.add(newHead);

    // Update camera after move (explore mode)
    if (gameMode == GameMode.explore) _updateCamera();

    // Clean up expired visual effects (fading after 0.8s)
    final now = DateTime.now().millisecondsSinceEpoch;
    effects.removeWhere((p) => now - p.startTimeMs > 800);

    if (collectedPowerUp != null) {
      _onPowerUpCollected(collectedPowerUp);
    }

    if (activeEvent != BoardEvent.none && now > eventEndMs) {
      activeEvent = BoardEvent.none;
    }

    if (isFeverMode && now > feverEndMs) {
      isFeverMode = false;
    }

    if (isSuperHunter && now > superHunterEndMs) {
      isSuperHunter = false;
    }
    if (isCrocStunned && now > crocStunEndMs) {
      isCrocStunned = false;
    }

    if (activeEvent == BoardEvent.none &&
        (gameMode == GameMode.classic ||
            gameMode == GameMode.endless ||
            gameMode == GameMode.timeAttack ||
            gameMode == GameMode.blitz)) {
      if (snake.length > 5 && _rng.nextInt(1000) < 15) {
        activeEvent =
            _rng.nextBool() ? BoardEvent.lightsOut : BoardEvent.iceBoard;
        eventEndMs = now + 5000 + _rng.nextInt(2000);
        AudioService().play(SoundEffect.powerUp);
      }
    }

    if (gameMode != GameMode.explore &&
        food != null &&
        food!.expiresAtMs != null &&
        now > food!.expiresAtMs!) {
      _spawnFood();
    }

    boardPowerUps.removeWhere((pu) => pu.isExpired(now));
    activePowerUps.removeWhere((pu) => !pu.isActive(now));

    if (!_hasPowerUp(PowerUpType.slowMotion) &&
        !_hasPowerUp(PowerUpType.speedBoost)) {
      _scaleSpeed();
    }

    if (gameMode == GameMode.campaign &&
        snake.length >= activeCampaignLevel!.targetLength) {
      isCampaignWon = true;
      _triggerGameOver();
      return;
    }

    notifyListeners();
  }

  Position _nextHead(Position head) {
    int nx = head.x;
    int ny = head.y;

    switch (currentDirection) {
      case Direction.up:
        ny -= 1;
        break;
      case Direction.down:
        ny += 1;
        break;
      case Direction.left:
        nx -= 1;
        break;
      case Direction.right:
        nx += 1;
        break;
    }

    Position proposed = Position(nx, ny);
    if (gameMode == GameMode.portal && boardPortals.containsKey(proposed)) {
      AudioService().play(SoundEffect.eat); // Play sound on teleport
      return boardPortals[proposed]!;
    }

    if (gameMode == GameMode.endless) {
      nx = nx % AppConstants.gridColumns;
      ny = ny % AppConstants.gridRows;
      if (nx < 0) nx += AppConstants.gridColumns;
      if (ny < 0) ny += AppConstants.gridRows;
    }

    return Position(nx, ny);
  }

  bool _isValidPosition(Position pos) {
    if (gameMode == GameMode.endless) {
      // Endless wraps — bounds always valid
    } else {
      if (pos.x < 0 || pos.x >= gridCols || pos.y < 0 || pos.y >= gridRows) {
        return false;
      }
    }

    if (obstacleSet.contains(pos)) return false;

    if (!_hasPowerUp(PowerUpType.ghostMode) && !isFeverMode) {
      if (snakeSet.contains(pos) && pos != snake.last) return false;
    }

    return true;
  }

  /// Keep camera centred on snake head, clamped to map bounds.
  void _updateCamera() {
    prevCameraX = cameraX;
    prevCameraY = cameraY;
    final head = snake.first;
    final halfW = AppConstants.exploreViewportCols ~/ 2;
    final halfH = AppConstants.exploreViewportRows ~/ 2;
    cameraX =
        (head.x - halfW).clamp(0, gridCols - AppConstants.exploreViewportCols);
    cameraY =
        (head.y - halfH).clamp(0, gridRows - AppConstants.exploreViewportRows);
  }

  void _onFoodEaten() {
    AudioService().play(SoundEffect.eat);
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now - comboLastFoodMs <= AppConstants.comboWindow * 1000) {
      combo = min(combo + 1, AppConstants.comboMultiplierMax);
      if (combo >= 3) {
        VibrationService().heartbeat();
        effects.add(GameEffect(
            position: snake.first,
            type: EffectType.comboBurst,
            value: 'x$combo STREAK!',
            startTimeMs: now));
      } else {
        VibrationService().vibrate(duration: 30, amplitude: 64);
      }
    } else {
      if (combo > 1) {
        onComboDropped?.call();
      }
      combo = 1;
      VibrationService().vibrate(duration: 20, amplitude: 32);
    }
    if (activeShadow != null) {
      activeShadow!.wins++;
      if (activeShadow!.wins >= 3) {
        int shadowBonus = equippedSkin == SnakeSkin.vampire ? 150 : 50;
        coinsEarnedSession += shadowBonus;
        VibrationService().ripple();
        AudioService().play(SoundEffect.shadowDefeat);
        AnalyticsService().logShadowSnakeEvent('defeated');
        final now = DateTime.now().millisecondsSinceEpoch;
        effects.add(GameEffect(
            position: activeShadow!.segments.first,
            type: EffectType.shadowPoof,
            startTimeMs: now));
        activeShadow = null;
      }
    } else if (Random().nextDouble() < 0.05) {
      // 5% chance to spawn shadow on food eaten if not active
      // Spawn slightly safely
      Position spawnPos = Position(
        AppConstants.gridColumns - 1 - snake.last.x,
        AppConstants.gridRows - 1 - snake.last.y,
      );
      activeShadow = ShadowSnake(spawnPos);
      AnalyticsService().logShadowSnakeEvent('spawn');
      effects.add(GameEffect(
          position: spawnPos,
          type: EffectType.shadowPoof,
          value: 'Challenger!',
          startTimeMs: now));
    }

    comboLastFoodMs = now;

    // Fever Meter Logic
    if (combo >= 3) {
      feverMeter += (equippedSkin == SnakeSkin.rainbow) ? 40 : 20;
      if (feverMeter >= 100 && !isFeverMode) {
        isFeverMode = true;
        feverEndMs = now + 8000;
        feverMeter = 0;
        AudioService().play(SoundEffect.powerUp);
        VibrationService().vibrate(duration: 500, amplitude: 255);
        effects.add(GameEffect(
            position: snake.first,
            type: EffectType.comboBurst,
            value: 'FEVER MODE!',
            startTimeMs: now));
      }
    }

    int points = AppConstants.baseScore;
    points = (points * (1 + combo * 0.5)).round();
    points = (points * difficulty.scoreMultiplier).round();
    if (_hasPowerUp(PowerUpType.scoreMultiplier)) points *= 2;
    if (equippedSkin == SnakeSkin.skeleton) points = (points * 1.05).round();

    if (food?.type == FoodType.boss) {
      points *= 10;
      coinsEarnedSession += 25;
      VibrationService().ripple();
      effects.add(GameEffect(
          position: snake.first,
          type: EffectType.comboBurst,
          value: '👑 BOSS CAUGHT! x10',
          startTimeMs: now));
    } else if (food?.type == FoodType.golden) {
      points *= (equippedSkin == SnakeSkin.dragon) ? 8 : 5;
      goldenApplesEatenSession++;
    } else if (food?.type == FoodType.poison) {
      points = -100;
      invertControlsUntilMs = now + 5000;
      poisonApplesEatenSession++;
      onPoisonEaten?.call();
    }

    if (comebackBonus && now < comebackBonusEndMs) {
      points = (points * 1.5).round();
    } else if (comebackBonus && now >= comebackBonusEndMs) {
      comebackBonus = false;
    }

    if (activeDailyEvent != null) {
      points = (points * activeDailyEvent!.scoreMultiplier).round();
    }

    // Apply modifier score bonus
    if (activeModifier != null) {
      switch (activeModifier!.type) {
        case GameModifierType.speedBoost:
          points = (points * 1.5).round();
          break;
        case GameModifierType.bigScore:
          points *= 2;
          break;
        case GameModifierType.invertedStart:
          if (invertControlsUntilMs > DateTime.now().millisecondsSinceEpoch) {
            points = (points * 1.3).round();
          }
          break;
        case GameModifierType.frenzy:
          points = (points * 1.2).round();
          break;
        default:
          break;
      }
    }

    score += points;

    if (score > highestScoreOnRecord &&
        !isHighScoreCelebrated &&
        highestScoreOnRecord > 0) {
      isHighScoreCelebrated = true;
      onHighScoreReached?.call();
    }

    _foodEatenSinceLastPowerUp++;

    _scaleSpeed();
    _startTimer();

    if (_foodEatenSinceLastPowerUp >= 3 &&
        _rng.nextInt(100) < AppConstants.powerUpSpawnChance &&
        boardPowerUps.length < AppConstants.powerUpMaxOnBoard) {
      _spawnPowerUp();
      _foodEatenSinceLastPowerUp = 0;
    }

    _spawnFood();

    if (gameMode == GameMode.timeAttack) {
      timeRemainingSeconds += 2;
    } else if (gameMode == GameMode.blitz) {
      timeRemainingSeconds += AppConstants.blitzBonusSecondsPerFood;
    }

    onFoodEaten?.call();
  }

  void _scaleSpeed() {
    if (gameMode == GameMode.portal) return; // Portal speed is fixed
    if (gameMode == GameMode.explore) return; // Explore stays at constant pace

    final segments = max(0, snake.length - AppConstants.initialSnakeLength);
    final thresholds = segments ~/ AppConstants.speedScaleEvery;
    final baseSpeed = difficulty.initialSpeed;

    // Endless mode scales twice as fast and allows much lower minimum tick limits
    // New-player grace: reduce scale amount by 40% for first 5 games
    final int baseScaleAmount = gameMode == GameMode.endless
        ? difficulty.speedScaleAmount * 2
        : gameMode == GameMode.blitz
            ? (difficulty.speedScaleAmount * 1.4).round()
            : difficulty.speedScaleAmount;
    final int scaleAmount =
        _newPlayerGrace ? (baseScaleAmount * 0.6).round() : baseScaleAmount;

    final int minSpeed = gameMode == GameMode.endless
        ? (AppConstants.speedMin * 0.5).round() // Let it get impossibly fast
        : AppConstants.speedMin;

    int newSpeed = max(
      minSpeed,
      baseSpeed - thresholds * scaleAmount,
    );

    if (activeEvent == BoardEvent.iceBoard) {
      newSpeed = (newSpeed * 0.6).round();
    }

    if (newSpeed != currentTickMs &&
        !_hasPowerUp(PowerUpType.speedBoost) &&
        !_hasPowerUp(PowerUpType.slowMotion)) {
      currentTickMs = newSpeed;
    }
  }

  void _spawnFood() {
    FoodType t = FoodType.standard;
    int? expires;
    final r = _rng.nextInt(100);

    bool allowGold = true;
    bool allowPoison = true;
    bool allowBoss = snake.length > 6 &&
        gameMode != GameMode.campaign; // boss food after some growth
    if (gameMode == GameMode.campaign && activeCampaignLevel != null) {
      allowGold = activeCampaignLevel!.hasGoldenApples;
      allowPoison = activeCampaignLevel!.hasPoisonApples;
    }

    if (r < 4 && allowBoss) {
      t = FoodType.boss;
      expires = DateTime.now().millisecondsSinceEpoch + 15000; // 15s window
      _bossMoveTick = 0;
    } else if (r >= 4 && r < 9 && allowGold) {
      t = FoodType.golden;
      expires = DateTime.now().millisecondsSinceEpoch + 8000;
    } else if (r >= 9 && r < 19 && allowPoison) {
      t = FoodType.poison;
      expires = DateTime.now().millisecondsSinceEpoch + 8000;
    }

    Position pos = Position(
      _rng.nextInt(gridCols),
      _rng.nextInt(gridRows),
    );
    int attempts = 0;
    while (attempts < 200) {
      pos = Position(
        _rng.nextInt(gridCols),
        _rng.nextInt(gridRows),
      );
      if (!snakeSet.contains(pos) &&
          !obstacleSet.contains(pos) &&
          !boardPowerUps.any((pu) => pu.position == pos)) {
        // In maze/campaign modes with obstacles, verify food is actually reachable
        if (obstacleSet.isNotEmpty && gameMode != GameMode.explore) {
          if (_pathExists(snake.first, pos)) break;
        } else {
          break;
        }
      }
      attempts++;
    }
    food = FoodModel(position: pos, type: t, expiresAtMs: expires);
  }

  void _moveBossFood() {
    if (food == null) return;
    final head = snake.first;
    final bossPos = food!.position;

    // Find the neighbour that maximises distance from snake head
    final candidates = [
      Position(bossPos.x + 1, bossPos.y),
      Position(bossPos.x - 1, bossPos.y),
      Position(bossPos.x, bossPos.y + 1),
      Position(bossPos.x, bossPos.y - 1),
    ];

    Position? best;
    double bestDist = -1;
    for (final m in candidates) {
      if (m.x < 0 || m.x >= gridCols) continue;
      if (m.y < 0 || m.y >= gridRows) continue;
      if (snakeSet.contains(m) || obstacleSet.contains(m)) continue;
      final dx = m.x - head.x;
      final dy = m.y - head.y;
      final d = (dx * dx + dy * dy).toDouble();
      if (d > bestDist) {
        bestDist = d;
        best = m;
      }
    }
    if (best != null) {
      food = FoodModel(
          position: best, type: FoodType.boss, expiresAtMs: food!.expiresAtMs);
    }
  }

  bool _pathExists(Position start, Position end) {
    if (gameMode == GameMode.endless ||
        gameMode == GameMode.portal ||
        gameMode == GameMode.explore)
      return true; // Large / wraparound maps — assume reachable

    HashSet<Position> visited = HashSet<Position>()..add(start);
    Queue<Position> queue = Queue<Position>()..add(start);

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (current == end) return true;

      final neighbors = [
        Position(current.x + 1, current.y),
        Position(current.x - 1, current.y),
        Position(current.x, current.y + 1),
        Position(current.x, current.y - 1),
      ];

      for (var n in neighbors) {
        if (n.x >= 0 &&
            n.x < AppConstants.gridColumns &&
            n.y >= 0 &&
            n.y < AppConstants.gridRows) {
          if (!visited.contains(n) && !obstacleSet.contains(n)) {
            visited.add(n);
            queue.add(n);
          }
        }
      }
    }
    return false;
  }

  void _generateTruePortals() {
    for (int i = 0; i < 3; i++) {
      Position p1 = _getEmptyPos();
      Position p2 = _getEmptyPos();
      if (p1 != p2) {
        boardPortals[p1] = p2;
        boardPortals[p2] = p1;
        portalIndices[p1] = i;
        portalIndices[p2] = i;
      }
    }
  }

  Position _getEmptyPos() {
    Position pos = Position(_rng.nextInt(gridCols), _rng.nextInt(gridRows));
    int attempts = 0;
    while (attempts < 200 &&
        (snakeSet.contains(pos) ||
            obstacleSet.contains(pos) ||
            boardPowerUps.any((pu) => pu.position == pos) ||
            boardPortals.containsKey(pos) ||
            food?.position == pos)) {
      pos = Position(_rng.nextInt(gridCols), _rng.nextInt(gridRows));
      attempts++;
    }
    return pos;
  }

  void _spawnPowerUp() {
    final type = PowerUpType.values[_rng.nextInt(PowerUpType.values.length)];
    Position pos = Position(
      _rng.nextInt(gridCols),
      _rng.nextInt(gridRows),
    );
    int attempts = 0;
    while (attempts < 200 &&
        (snakeSet.contains(pos) ||
            obstacleSet.contains(pos) ||
            food?.position == pos ||
            boardPowerUps.any((pu) => pu.position == pos))) {
      pos = Position(
        _rng.nextInt(gridCols),
        _rng.nextInt(gridRows),
      );
      attempts++;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    boardPowerUps.add(PowerUpModel(
      position: pos,
      type: type,
      expiresAtMs: now + 8000,
    ));
  }

  void _generateMazeObstacles() {
    int count;
    switch (difficulty) {
      case Difficulty.easy:
        count = AppConstants.mazeObstaclesEasy;
        break;
      case Difficulty.normal:
        count = AppConstants.mazeObstaclesNormal;
        break;
      case Difficulty.hard:
        count = AppConstants.mazeObstaclesHard;
        break;
      case Difficulty.insane:
        count = AppConstants.mazeObstaclesInsane;
        break;
    }

    _spawnRandomObstacles(count);
  }

  void _generateCampaignObstacles() {
    if (activeCampaignLevel!.obstacleDensity <= 0) return;
    int count = activeCampaignLevel!.obstacleDensity * 2;
    _spawnRandomObstacles(count);
  }

  void _spawnRandomObstacles(int count) {
    const clearZone = 4;
    int added = 0;
    while (added < count) {
      final pos = Position(
        _rng.nextInt(gridCols),
        _rng.nextInt(gridRows),
      );
      if ((pos.x - startX).abs() > clearZone ||
          (pos.y - startY).abs() > clearZone) {
        if (!obstacleSet.contains(pos)) {
          obstacleSet.add(pos);
          added++;
        }
      }
    }
  }

  void _attractFood() {
    if (food == null) return;
    final head = snake.first;
    final fp = food!.position;
    int nx = fp.x +
        (head.x > fp.x
            ? 1
            : head.x < fp.x
                ? -1
                : 0);
    int ny = fp.y +
        (head.y > fp.y
            ? 1
            : head.y < fp.y
                ? -1
                : 0);
    nx = nx.clamp(0, gridCols - 1);
    ny = ny.clamp(0, gridRows - 1);

    final newPos = Position(nx, ny);
    if (!snakeSet.contains(newPos) &&
        !obstacleSet.contains(newPos) &&
        !boardPowerUps.any((p) => p.position == newPos)) {
      food = FoodModel(position: newPos);
    }
  }

  void _startTimeAttackTimer() {
    _timeAttackTimer?.cancel();
    _timeAttackTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isPaused) return;
      timeRemainingSeconds--;
      if (timeRemainingSeconds <= 0) {
        timeRemainingSeconds = 0;
        _triggerGameOver();
      }
      notifyListeners();
    });
  }

  void _triggerGameOver() {
    isGameOver = true;
    isPlaying = false;
    VibrationService().impact();
    AudioService().play(SoundEffect.gameOver);
    _vibrate(200, 255);
    _ticker?.stop();
    _timeAttackTimer?.cancel();
    onGameOver?.call();
    notifyListeners();
  }

  bool _hasPowerUp(PowerUpType type) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return activePowerUps.any((ap) => ap.type == type && ap.isActive(now));
  }

  ActivePowerUp? getActivePowerUp(PowerUpType type) {
    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      return activePowerUps
          .firstWhere((ap) => ap.type == type && ap.isActive(now));
    } catch (_) {
      return null;
    }
  }

  void revive() {
    if (!isGameOver) return;
    isGameOver = false;
    isPlaying = false; // Requires GameScreen to restart it
    isPaused = true;
    _directionQueue.clear();

    // Reset snake exactly to center but keep current length
    final int cx = startX;
    final int cy = startY;

    // Clear nearby obstacles to prevent immediate death
    obstacleSet.removeWhere(
        (pos) => (pos.x - cx).abs() <= 2 && (pos.y - cy).abs() <= 2);

    List<Position> newSnake = [];
    int x = cx;
    int y = cy;
    int xDir = -1; // Extending tail backwards to the left

    for (int i = 0; i < snake.length; i++) {
      newSnake.add(Position(x, y));
      x += xDir;

      // If we hit the horizontal borders while extending tail, snake it down a row
      if (x < 0) {
        x = 0;
        y += 1;
        xDir = 1; // Start extending to the right
      } else if (x >= gridCols) {
        x = gridCols - 1;
        y += 1;
        xDir = -1; // Start extending to the left
      }

      // Safe wrap the Y coordinate just in case it hits bottom
      if (y >= gridRows) {
        y = 0;
      }
    }

    snake = newSnake;
    currentDirection = Direction.right;

    // Remove any ghost mode that was tied to the old system just in case
    activePowerUps.removeWhere((p) => p.type == PowerUpType.ghostMode);
    // Give 3 seconds of invincibility just to be perfectly safe as they orient themselves
    final now = DateTime.now().millisecondsSinceEpoch;
    activePowerUps.add(ActivePowerUp(
      type: PowerUpType.ghostMode,
      endsAtMs: now + 3000,
    ));

    notifyListeners();
  }

  void _onPowerUpCollected(PowerUpModel pu) {
    AudioService().play(SoundEffect.powerUp);
    VibrationService().ripple();
    powerUpsCollectedSession++;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (pu.type.isInstant) {
      if (pu.type == PowerUpType.shrink) {
        final removeCount = (snake.length * 0.3).floor();
        for (int i = 0; i < removeCount; i++) {
          if (snake.length > 1) snake.removeLast();
        }
      }
    } else {
      activePowerUps.removeWhere((ap) => ap.type == pu.type);
      double durationMult = (equippedSkin == SnakeSkin.robot) ? 1.2 : 1.0;
      activePowerUps.add(ActivePowerUp(
        type: pu.type,
        endsAtMs: now + (AppConstants.powerUpDurationMs * durationMult).round(),
      ));

      if (pu.type == PowerUpType.speedBoost) {
        currentTickMs = (difficulty.initialSpeed / 2).round();
        _startTimer();
      } else if (pu.type == PowerUpType.slowMotion) {
        currentTickMs = (difficulty.initialSpeed * 1.5).round();
        _startTimer();
      }
    }

    boardPowerUps.remove(pu);
    AnalyticsService().logPowerUpCollected(pu.type.name);
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _timeAttackTimer?.cancel();
    super.dispose();
  }

  // ── Explore mode: Prey system ──────────────────────────────────

  /// Returns which prey types are valid to spawn given a biome.
  List<FoodType> _preyTypesForBiome(BiomeType biome) {
    switch (biome) {
      case BiomeType.forest:
        return [FoodType.mouse, FoodType.rabbit];
      case BiomeType.desert:
        return [FoodType.lizard, FoodType.mouse];
      case BiomeType.swamp:
        return [FoodType.croc, FoodType.lizard];
      case BiomeType.cave:
        return [FoodType.butterfly, FoodType.lizard];
      case BiomeType.ruins:
        return [FoodType.mouse, FoodType.butterfly, FoodType.lizard];
    }
  }

  void _spawnInitialPrey() {
    for (int i = 0; i < 3; i++) {
      _spawnSinglePrey();
    }
  }

  void _spawnSinglePrey({Position? nearPos}) {
    Position pos;
    if (nearPos != null) {
      pos = _getEmptyPosNear(nearPos, radius: 12);
    } else {
      pos = _getEmptyPos();
      int attempts = 0;
      while (attempts < 50) {
        final d = (pos.x - snake.first.x).abs() + (pos.y - snake.first.y).abs();
        if (d > 10) break;
        pos = _getEmptyPos();
        attempts++;
      }
    }

    // Pick type based on the biome of the spawn room
    const int bs = 10;
    const int roomRowCount = 11;
    final rx = pos.x ~/ bs;
    final ry = pos.y ~/ bs;
    final roomKey = rx * roomRowCount + ry;
    final biome = roomBiomes[roomKey];
    final candidates = biome != null
        ? _preyTypesForBiome(biome)
        : [FoodType.mouse, FoodType.rabbit];
    final type = candidates[_rng.nextInt(candidates.length)];

    switch (type) {
      case FoodType.rabbit:
        preyList.add(FoodModel(
            position: pos, type: FoodType.rabbit, dashChargesLeft: 3));
        break;
      case FoodType.lizard:
        preyList.add(FoodModel(
            position: pos,
            type: FoodType.lizard,
            stillTicksLeft: 3 + _rng.nextInt(4)));
        break;
      case FoodType.butterfly:
        // monarchWyrm skin doubles butterfly lifespan
        final butterflyMs =
            equippedSkin == SnakeSkin.monarchWyrm ? 30000 : 15000;
        final expires = DateTime.now().millisecondsSinceEpoch + butterflyMs;
        preyList.add(FoodModel(
            position: pos,
            type: FoodType.butterfly,
            expiresAtMs: expires,
            sinAngle: 0.0));
        break;
      case FoodType.croc:
        final body = [
          pos,
          Position(pos.x - 1, pos.y),
          Position(pos.x - 2, pos.y)
        ];
        preyList
            .add(FoodModel(position: pos, type: FoodType.croc, crocBody: body));
        break;
      default:
        preyList.add(FoodModel(position: pos, type: FoodType.mouse));
    }
  }

  Position _getEmptyPosNear(Position center, {int radius = 12}) {
    int attempts = 0;
    while (attempts < 200) {
      final ox = _rng.nextInt(radius * 2 + 1) - radius;
      final oy = _rng.nextInt(radius * 2 + 1) - radius;
      final pos = Position(
        (center.x + ox).clamp(0, gridCols - 1),
        (center.y + oy).clamp(0, gridRows - 1),
      );
      if (!snakeSet.contains(pos) &&
          !obstacleSet.contains(pos) &&
          !preyList.any((p) => p.position == pos)) {
        return pos;
      }
      attempts++;
    }
    return _getEmptyPos();
  }

  void _movePrey() {
    if (preyList.isEmpty || snake.isEmpty) return;
    final head = snake.first;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Expire butterflies
    preyList.removeWhere((p) =>
        p.type == FoodType.butterfly &&
        p.expiresAtMs != null &&
        now > p.expiresAtMs!);

    // Refill to maintain 3 prey
    while (preyList.length < 3) {
      _spawnSinglePrey();
    }

    for (int i = 0; i < preyList.length; i++) {
      final prey = preyList[i];

      // preyMagnet: pull all prey one step toward snake head
      final magnetActive = preyMagnetEndMs > 0 &&
          DateTime.now().millisecondsSinceEpoch < preyMagnetEndMs;
      if (magnetActive) {
        _preySingleStepToward(i, head);
        continue;
      }

      switch (prey.type) {
        case FoodType.mouse:
          _moveMouse(i, head);
          break;
        case FoodType.rabbit:
          _moveRabbit(i, head);
          break;
        case FoodType.lizard:
          _moveLizard(i, head);
          break;
        case FoodType.butterfly:
          _moveButterfly(i);
          break;
        case FoodType.croc:
          _moveCroc(i, head);
          break;
        default:
          break;
      }
    }
  }

  void _moveMouse(int idx, Position head) {
    final prey = preyList[idx];
    final dist =
        (prey.position.x - head.x).abs() + (prey.position.y - head.y).abs();
    if (dist > 5) return;
    _preySingleStep(idx, head);
  }

  void _moveRabbit(int idx, Position head) {
    final prey = preyList[idx];
    final dist =
        (prey.position.x - head.x).abs() + (prey.position.y - head.y).abs();
    if (dist > 6) return;
    if (prey.dashChargesLeft > 0) {
      _rabbitDash(idx, head);
    } else {
      _preySingleStep(idx, head);
    }
  }

  void _moveLizard(int idx, Position head) {
    final prey = preyList[idx];
    // Counts down stillness; when still it's camouflaged
    if (prey.stillTicksLeft > 0) {
      preyList[idx] = prey.copyWith(stillTicksLeft: prey.stillTicksLeft - 1);
      return;
    }
    final dist =
        (prey.position.x - head.x).abs() + (prey.position.y - head.y).abs();
    if (dist > 7) {
      // Far away — stop and hide again
      preyList[idx] = prey.copyWith(stillTicksLeft: 4 + _rng.nextInt(5));
      return;
    }
    _preySingleStep(idx, head);
    // After moving, rest for a few ticks
    preyList[idx] = preyList[idx].copyWith(stillTicksLeft: 2 + _rng.nextInt(3));
  }

  void _moveButterfly(int idx) {
    final prey = preyList[idx];
    // Sine-wave path: move 2 cells along x each tick, y oscillates
    final newAngle = prey.sinAngle + 0.8;
    final ny = (prey.position.y + (sin(newAngle) * 1.5).round())
        .clamp(0, gridRows - 1);
    final nx = (prey.position.x + 2).clamp(0, gridCols - 1);
    final newPos = Position(nx, ny);
    if (!obstacleSet.contains(newPos) && !snakeSet.contains(newPos)) {
      preyList[idx] = prey.copyWith(position: newPos, sinAngle: newAngle);
    } else {
      // Reverse direction on obstacle
      final revPos = Position(
          (prey.position.x - 1).clamp(0, gridCols - 1), prey.position.y);
      preyList[idx] = prey.copyWith(position: revPos, sinAngle: newAngle + pi);
    }
  }

  void _moveCroc(int idx, Position head) {
    final prey = preyList[idx];
    if (prey.crocBody.isEmpty) return;
    final dist =
        (prey.position.x - head.x).abs() + (prey.position.y - head.y).abs();
    if (dist > 8) return;

    // Move head away from snake, body follows
    final pos = prey.crocBody.first;
    final candidates = [
      Position(pos.x + 1, pos.y),
      Position(pos.x - 1, pos.y),
      Position(pos.x, pos.y + 1),
      Position(pos.x, pos.y - 1),
    ];
    Position? best;
    int bestDist = -1;
    for (final c in candidates) {
      if (c.x < 0 || c.x >= gridCols || c.y < 0 || c.y >= gridRows) continue;
      if (obstacleSet.contains(c)) continue;
      if (snakeSet.contains(c)) continue;
      // Don't collide with own body
      if (prey.crocBody.skip(1).contains(c)) continue;
      final d = (c.x - head.x).abs() + (c.y - head.y).abs();
      if (d > bestDist) {
        bestDist = d;
        best = c;
      }
    }
    if (best != null) {
      final newBody = [best, prey.crocBody[0], prey.crocBody[1]];
      preyList[idx] = prey.copyWith(position: best, crocBody: newBody);
    }
  }

  void _preySingleStep(int preyIdx, Position head) {
    final prey = preyList[preyIdx];
    final pos = prey.position;

    final candidates = [
      Position(pos.x + 1, pos.y),
      Position(pos.x - 1, pos.y),
      Position(pos.x, pos.y + 1),
      Position(pos.x, pos.y - 1),
    ];

    Position? best;
    int bestDist = -1;
    for (final c in candidates) {
      if (c.x < 0 || c.x >= gridCols || c.y < 0 || c.y >= gridRows) continue;
      if (obstacleSet.contains(c)) continue;
      if (snakeSet.contains(c)) continue;
      if (preyList.any((p) => p.position == c)) continue;
      final d = (c.x - head.x).abs() + (c.y - head.y).abs();
      if (d > bestDist) {
        bestDist = d;
        best = c;
      }
    }

    if (best != null) {
      preyList[preyIdx] = prey.copyWith(position: best);
    }
  }

  // Move prey one step toward [head] (magnet effect).
  void _preySingleStepToward(int preyIdx, Position head) {
    final prey = preyList[preyIdx];
    final pos = prey.position;

    final candidates = [
      Position(pos.x + 1, pos.y),
      Position(pos.x - 1, pos.y),
      Position(pos.x, pos.y + 1),
      Position(pos.x, pos.y - 1),
    ];

    Position? best;
    int bestDist = 999999;
    for (final c in candidates) {
      if (c.x < 0 || c.x >= gridCols || c.y < 0 || c.y >= gridRows) continue;
      if (obstacleSet.contains(c)) continue;
      if (snakeSet.contains(c)) continue;
      if (preyList.any((p) => p != prey && p.position == c)) continue;
      final d = (c.x - head.x).abs() + (c.y - head.y).abs();
      if (d < bestDist) {
        bestDist = d;
        best = c;
      }
    }

    if (best != null) {
      preyList[preyIdx] = prey.copyWith(position: best);
    }
  }

  void _rabbitDash(int preyIdx, Position head) {
    final prey = preyList[preyIdx];
    final pos = prey.position;
    final dx = pos.x - head.x;
    final dy = pos.y - head.y;

    Position? dashPos;
    if (dx.abs() >= dy.abs()) {
      dashPos = _findDashLanding(pos, dx >= 0 ? 1 : -1, 0, 3);
    } else {
      dashPos = _findDashLanding(pos, 0, dy >= 0 ? 1 : -1, 3);
    }

    if (dashPos != null) {
      preyList[preyIdx] = prey.copyWith(
          position: dashPos, dashChargesLeft: prey.dashChargesLeft - 1);
    } else {
      _preySingleStep(preyIdx, head);
    }
  }

  Position? _findDashLanding(Position start, int xDir, int yDir, int steps) {
    Position pos = start;
    for (int i = 0; i < steps; i++) {
      final next = Position(pos.x + xDir, pos.y + yDir);
      if (next.x < 0 || next.x >= gridCols) break;
      if (next.y < 0 || next.y >= gridRows) break;
      if (obstacleSet.contains(next)) break;
      if (snakeSet.contains(next)) break;
      pos = next;
    }
    return pos == start ? null : pos;
  }

  void _onPreyEaten(FoodModel prey) {
    AudioService().play(SoundEffect.eat);
    VibrationService().vibrate(duration: 30, amplitude: 64);
    final now = DateTime.now().millisecondsSinceEpoch;

    final basePoints = _preyBasePoints(prey.type);
    final label = _preyLabel(prey.type, basePoints);

    // Hunt Streak logic
    int streakMultiplier = 1;
    if (lastCaughtType != null &&
        lastCaughtType != prey.type &&
        now < huntStreakEndMs) {
      huntStreak++;
    } else {
      huntStreak = 1;
    }
    huntStreakEndMs = now + 30000;
    lastCaughtType = prey.type;

    if (huntStreak >= 7) {
      streakMultiplier = 8;
      isSuperHunter = true;
      superHunterEndMs = now + 3000;
      effects.add(GameEffect(
          position: snake.first,
          type: EffectType.comboBurst,
          value: '🏆 APEX PREDATOR ×8!',
          startTimeMs: now));
    } else if (huntStreak >= 5) {
      streakMultiplier = 4;
      isSuperHunter = true;
      superHunterEndMs = now + 3000;
      effects.add(GameEffect(
          position: snake.first,
          type: EffectType.comboBurst,
          value: '🔥 HUNTER ×4',
          startTimeMs: now));
    } else if (huntStreak >= 3) {
      streakMultiplier = 2;
      effects.add(GameEffect(
          position: snake.first,
          type: EffectType.comboBurst,
          value: '🎯 TRACKER ×2',
          startTimeMs: now));
    } else {
      effects.add(GameEffect(
          position: snake.first,
          type: EffectType.comboBurst,
          value: label,
          startTimeMs: now));
    }

    int points =
        (basePoints * streakMultiplier * difficulty.scoreMultiplier).round();
    if (_hasPowerUp(PowerUpType.scoreMultiplier)) points *= 2;

    // Safari skin passives
    if (equippedSkin == SnakeSkin.jadeSerpent && prey.type.name == 'lizard') {
      points = (points * 1.5).round();
    }
    score += points;

    // Safari Journal: record catch + biome + mission progress
    final typeName = prey.type.name;
    StorageService().incrementSafariCount(typeName);
    final room = _roomBiomeAt(snake.first);
    if (room != null) StorageService().recordBiomeVisit(room.name);
    StorageService().incrementSafariMissionProgress();

    if (score > highestScoreOnRecord &&
        !isHighScoreCelebrated &&
        highestScoreOnRecord > 0) {
      isHighScoreCelebrated = true;
      onHighScoreReached?.call();
    }

    _spawnSinglePrey(nearPos: prey.position);
    onFoodEaten?.call();
  }

  BiomeType? _roomBiomeAt(Position pos) {
    final rx = pos.x ~/ 10;
    final ry = pos.y ~/ 10;
    return roomBiomes[rx * 11 + ry];
  }

  int _preyBasePoints(FoodType type) {
    switch (type) {
      case FoodType.mouse:
        return 20;
      case FoodType.rabbit:
        return 40;
      case FoodType.lizard:
        return 80;
      case FoodType.butterfly:
        return 150;
      case FoodType.croc:
        return 250;
      default:
        return 20;
    }
  }

  String _preyLabel(FoodType type, int pts) {
    switch (type) {
      case FoodType.mouse:
        return '🐭 +$pts';
      case FoodType.rabbit:
        return '🐇 RABBIT! +$pts';
      case FoodType.lizard:
        return '🦎 LIZARD! +$pts';
      case FoodType.butterfly:
        return '🦋 BUTTERFLY! +$pts';
      case FoodType.croc:
        return '🐊 CROC BOSS! +$pts';
      default:
        return '+$pts';
    }
  }

  void _moveShadow() {
    // Simple A* would be overkill, just move towards food
    final target = food!.position;
    final current = activeShadow!.segments.first;

    int dx = 0;
    int dy = 0;

    if (target.x > current.x) {
      dx = 1;
    } else if (target.x < current.x)
      dx = -1;
    else if (target.y > current.y)
      dy = 1;
    else if (target.y < current.y) dy = -1;

    final next =
        Position((current.x + dx) % gridCols, (current.y + dy) % gridRows);

    activeShadow!.segments.insert(0, next);
    if (activeShadow!.segments.length > 3) {
      activeShadow!.segments.removeLast();
    }

    // If shadow eats food first
    if (next == food!.position) {
      activeShadow = null;
      food = null;
      _spawnFood();
      AudioService().play(SoundEffect.shadowSteal);
      AnalyticsService().logShadowSnakeEvent('stole_food');
    }
  }
}

class ShadowSnake {
  final List<Position> segments;
  int wins = 0;
  ShadowSnake(Position start) : segments = [start, start, start];
}

enum EffectType { comboBurst, shadowPoof }

class GameEffect {
  final Position position;
  final EffectType type;
  final String? value;
  final int startTimeMs;
  GameEffect(
      {required this.position,
      required this.type,
      this.value,
      required this.startTimeMs});
}
