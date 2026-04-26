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
import '../core/models/shadow_snake.dart';
import 'map_generator.dart';
import 'entity_manager.dart';
import 'screen_shake_service.dart';
import 'tail_trail_service.dart';
import 'adaptive_music_service.dart';
import 'ghost_racing_service.dart';

enum BoardEvent {
  none,
  lightsOut,
  iceBoard,
  goldenRush,
  invertControls,
  scoreBoost
}

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

  // Game Feel / Juice
  bool isNearMissSlowMo = false;
  int nearMissSlowMoEndMs = 0;
  List<int> foodBulges = [];

  // Graze / Near-Miss combos
  int grazeMissCount = 0; // consecutive near misses this run
  int grazeMultiplierEndMs = 0; // window before multiplier resets
  int get grazeMultiplier => (1 + (grazeMissCount ~/ 3)).clamp(1, 5);

  final MapGenerator _mapGenerator = MapGenerator();
  final EntityManager _entityManager = EntityManager();

  int score = 0;
  // Expedition gear state
  List<String> equippedGear = [];
  bool hasMagnetGear = false;
  bool hasSpeedTonic = false;
  bool hasSnakeOil = false;
  bool hasCrocBane = false;

  // Cursed Relics & Events
  bool hasWraithsEye = false;
  bool hasShrineSpawnedThisFloor = false;
  String? activeRelicId;
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
  int mapSeed = 0;

  Map<Position, Position> boardPortals = {};
  Map<Position, int> portalIndices = {};

  // ── Explore mode ───────────────────────────────────────────────
  int currentFloor = 1;
  int maxFloorReached = 1;
  int preyCaughtThisFloor = 0;
  bool isCampfirePhase = false;

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
  int biomeEventCooldownMs = 0;

  // Croc stun
  bool isCrocStunned = false;
  int crocStunEndMs = 0;

  // Expedition gear state
  int wallHitsLeft = 0; // ghostShell: absorbs 1 wall hit
  int preyMagnetEndMs = 0; // preyMagnet: prey drift toward head
  bool biomeMapActive = false; // biomeMap: reveal all rooms
  int dashCharges = 0; // dashScroll: instant-move charges

  // Altar Skills
  int greedLevel = 0;

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

  final Set<Position> spikeTraps = {};
  bool spikesActive = false;
  bool spikesWarning = false; // true for 3 ticks before spikes activate
  int _spikeTickCounter = 0;
  int _weatherTickCounter = 0;

  VoidCallback? onBulgeConsumed;

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

  int gameTimeMs = 0;
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

  String killerType = 'Unknown';

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

  Random _rng = Random();
  int _foodEatenSinceLastPowerUp = 0;
  int _preyTickCounter = 0;
  int _ambientAudioTickCounter = 0;
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
    activeRelicId = StorageService().equippedRelicId;

    final gamesPlayed = StorageService().gamesPlayed;
    _newPlayerGrace = gamesPlayed < 5;

    mapSeed = DateTime.now().millisecondsSinceEpoch;
    _rng = Random(mapSeed);

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

    // Explore mode: start slower so the large map is enjoyable to navigate
    if (gameMode == GameMode.explore) {
      currentTickMs = (currentTickMs * 1.5).round();
    }

    if (activeRelicId == 'swamp_walker') {
      currentTickMs = (currentTickMs * 1.15).round();
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
      switch (activeModifier!.type) {
        case GameModifierType.invertedStart:
          invertControlsUntilMs = gameTimeMs + 20000;
          break;
        case GameModifierType.frenzy:
          isFeverMode = true;
          feverEndMs = gameTimeMs + 8000;
          feverMeter = 0;
          break;
        default:
          break;
      }
    }

    if (equippedSkin == SnakeSkin.ghost) {
      activePowerUps.add(
        ActivePowerUp(
          type: PowerUpType.ghostMode,
          endsAtMs: gameTimeMs + AppConstants.powerUpDurationMs,
        ),
      );
    }

    // Apply expedition gear effects
    for (final gear in equippedGear) {
      switch (gear) {
        case 'speedTonic':
          currentTickMs = (currentTickMs * 0.8).round();
          break;
        case 'ghostShell':
          wallHitsLeft = 1;
          break;
        case 'preyMagnet':
          preyMagnetEndMs = gameTimeMs + 30000;
          break;
        case 'biomeMap':
          biomeMapActive = true;
          break;
        case 'dashScroll':
          dashCharges = 3;
          break;
      }
    }

    // Apply persistent Altar Skills
    if (gameMode == GameMode.explore) {
      wallHitsLeft += StorageService().skillThickScales;
      dashCharges += StorageService().skillDashMastery;
      greedLevel = StorageService().skillGreed;
    }

    if (activeRelicId == 'swamp_walker') {
      wallHitsLeft += 1;
    }

    if (withComebackBonus) {
      comebackBonus = true;
      comebackBonusEndMs = gameTimeMs + 30000;
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
    gameTimeMs = 0;
    isGameOver = false;
    killerType = 'Unknown';
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
    spikeTraps.clear();
    spikesActive = false;
    spikesWarning = false;
    _spikeTickCounter = 0;
    _weatherTickCounter = 0;
    huntStreak = 0;
    huntStreakEndMs = 0;
    lastCaughtType = null;
    isSuperHunter = false;
    superHunterEndMs = 0;
    biomeEventCooldownMs = 0;
    currentFloor = 1;
    preyCaughtThisFloor = 0;
    isCampfirePhase = false;
    hasWraithsEye = false;
    hasShrineSpawnedThisFloor = false;
    isCrocStunned = false;
    crocStunEndMs = 0;
    wallHitsLeft = 0;
    preyMagnetEndMs = 0;
    biomeMapActive = false;
    dashCharges = 0;
    timeRemainingSeconds = AppConstants.timeAttackSeconds;
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

    if (gameMode == GameMode.explore) {
      _spawnInitialPrey();
    } else {
      _spawnFood();
    }
    _updateCamera();
    notifyListeners();
  }

  void _generatePerimeterWalls() {
    _mapGenerator.generatePerimeterWalls(obstacleSet);
  }

  /// Room-and-corridor map: guarantees every open area is reachable, all
  /// corridors are 3 cells wide so the snake can always turn back.
  void _generateExploreMap() {
    _mapGenerator.generateExploreMap(
      obstacleSet: obstacleSet,
      roomBiomes: roomBiomes,
      spikeTraps: spikeTraps,
      snakeSet: snakeSet,
    );
    // Restore snake position if a saved explore session exists
    final resume = StorageService().exploreResume;
    if (resume != null) {
      final rx = resume.x.clamp(0, gridCols - 1);
      final ry = resume.y.clamp(0, gridRows - 1);
      snake = [
        Position(rx, ry),
        Position((rx - 1).clamp(0, gridCols - 1), ry),
        Position((rx - 2).clamp(0, gridCols - 1), ry),
      ];
      snakeSet = HashSet<Position>.from(snake);
      cameraX = rx - AppConstants.exploreViewportCols ~/ 2;
      cameraY = ry - AppConstants.exploreViewportRows ~/ 2;
      prevCameraX = cameraX;
      prevCameraY = cameraY;
      currentFloor = resume.floor;
      score = resume.score;
    }
  }

  void _generateCampaignObstacles() {
    if (activeCampaignLevel == null) return;
    _mapGenerator.generateCampaignObstacles(obstacleSet, activeCampaignLevel!,
        AppConstants.gridColumns ~/ 2, AppConstants.gridRows ~/ 2);
  }

  void start() {
    isPlaying = true;
    isPaused = false;
    _startTimer();
    if (gameMode == GameMode.timeAttack ||
        (gameMode == GameMode.campaign &&
            activeCampaignLevel!.timeLimitSeconds > 0)) {
      _startTimeAttackTimer();
    }
  }

  void pause() {
    isPaused = true;
    _ticker?.stop();
    _timeAttackTimer?.cancel();
    if (gameMode == GameMode.explore && snake.isNotEmpty) {
      StorageService().saveExploreResume(
        headX: snake.first.x,
        headY: snake.first.y,
        floor: currentFloor,
        score: score,
      );
    }
    notifyListeners();
  }

  void resume() {
    isPaused = false;
    _startTimer();
    if (gameMode == GameMode.timeAttack ||
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

  void nextFloor() {
    currentFloor++;
    if (currentFloor > maxFloorReached) maxFloorReached = currentFloor;
    preyCaughtThisFloor = 0;
    isCampfirePhase = false;
    hasShrineSpawnedThisFloor = false;
    biomeEventCooldownMs = gameTimeMs + 8000;
    StorageService().clearExploreResume();

    // Board reset logic (keep score, gear, stats)
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

    activeEvent = BoardEvent.none;
    eventEndMs = 0;
    boardPowerUps.clear();
    trail.clear();
    effects.clear();
    preyList.clear();
    roomBiomes.clear();
    _visitedRoomKeys.clear();
    obstacleSet.clear();

    _generateExploreMap();
    _spawnInitialPrey();
    _updateCamera();

    // Make the game slightly faster
    currentTickMs = max((currentTickMs * 0.95).round(), AppConstants.speedMin);

    notifyListeners();
    start();
  }

  void changeDirection(Direction newDir) {
    // Croc stun blocks turning
    if (isCrocStunned && gameTimeMs < crocStunEndMs) return;
    if (gameTimeMs < invertControlsUntilMs) {
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

    if (isNearMissSlowMo) {
      currentDelay = (currentDelay * 2.5).round(); // Matrix slow-mo!
      if (gameTimeMs > nearMissSlowMoEndMs) {
        isNearMissSlowMo = false;
      }
    }

    if (_lastTickTime == Duration.zero ||
        elapsed.inMilliseconds - _lastTickTime.inMilliseconds >= currentDelay) {
      _lastTickTime = elapsed;
      lastTickRealtimeMs = DateTime.now().millisecondsSinceEpoch;
      gameTimeMs += currentDelay;
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
      _trySpawnBiomeMiniEvent();
      _ensureExplorePreyPopulation();

      // Update spike traps state every 12 ticks (~2.5 seconds)
      _spikeTickCounter++;
      // Warn player 3 ticks before spikes activate
      if (!spikesActive && _spikeTickCounter >= 9 && _spikeTickCounter < 12) {
        spikesWarning = true;
      }
      if (_spikeTickCounter >= 12) {
        _spikeTickCounter = 0;
        spikesActive = !spikesActive;
        spikesWarning = false;
        if (spikesActive) {
          VibrationService().vibrate(duration: 50, amplitude: 100);
        }
      }
    }

    // Weather effects in specific explore biomes
    if (gameMode == GameMode.explore &&
        (currentBiome == BiomeType.desert ||
            currentBiome == BiomeType.savanna ||
            currentBiome == BiomeType.tundra ||
            currentBiome == BiomeType.frozenLake ||
            currentBiome == BiomeType.lavaField ||
            currentBiome == BiomeType.ashlands)) {
      _weatherTickCounter++;
      if (_weatherTickCounter >= 10) {
        _weatherTickCounter = 0;
        final head = snake.first;
        final String weatherText;
        if (currentBiome == BiomeType.tundra ||
            currentBiome == BiomeType.frozenLake) {
          weatherText = '❄ BLIZZARD!';
        } else if (currentBiome == BiomeType.lavaField ||
            currentBiome == BiomeType.ashlands) {
          weatherText = '🔥 HEAT WAVE!';
        } else {
          weatherText = '💨 WIND!';
        }
        effects.add(GameEffect(
          position: head,
          type: EffectType.comboBurst,
          value: weatherText,
          startTimeMs: gameTimeMs,
        ));
      }
    }

    _updateBiomeAmbientAudio();

    if (isFeverMode) {
      _attractFood();
    } else if (activeRelicId == 'eagle_eye' && food != null) {
      _attractFood();
    } else if (_hasPowerUp(PowerUpType.magnet) && food != null) {
      _attractFood();
    }

    final head = snake.first;
    final Position newHead = _nextHead(head);

    // Spike Trap collision logic
    if (gameMode == GameMode.explore &&
        spikesActive &&
        spikeTraps.contains(newHead) &&
        !_hasPowerUp(PowerUpType.ghostMode)) {
      if (wallHitsLeft > 0) {
        wallHitsLeft--;
        VibrationService().impact();
        effects.add(GameEffect(
          position: newHead,
          type: EffectType.comboBurst,
          value: 'SHIELDED!',
          startTimeMs: gameTimeMs,
        ));
      } else {
        killerType = 'Spike Trap';
        _triggerGameOver();
        return;
      }
    }

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

    // Near Miss Matrix Dodge Logic
    if (!isNearMissSlowMo) {
      int dangerCount = 0;
      final neighbors = [
        Position(newHead.x + 1, newHead.y),
        Position(newHead.x - 1, newHead.y),
        Position(newHead.x, newHead.y + 1),
        Position(newHead.x, newHead.y - 1),
      ];
      for (var n in neighbors) {
        if (n == head) continue;
        if (!_isValidPosition(n)) dangerCount++;
      }

      if (dangerCount >= 2) {
        isNearMissSlowMo = true;
        final nowMs = gameTimeMs;
        nearMissSlowMoEndMs = nowMs + 600;

        // Graze mechanic: count consecutive near misses for multiplier
        if (nowMs < grazeMultiplierEndMs) {
          grazeMissCount++;
        } else {
          grazeMissCount = 1;
        }
        grazeMultiplierEndMs = nowMs + 3000; // 3s window

        final int grazeBonus = 15 * grazeMultiplier;
        score += grazeBonus;

        VibrationService().vibrate(duration: 50, amplitude: 255);
        ScreenShakeService().nearMiss();
        AudioService().play(SoundEffect.eat);

        final label = grazeMissCount >= 3
            ? 'GRAZE x$grazeMultiplier! +$grazeBonus'
            : 'DODGE! +$grazeBonus';

        effects.add(GameEffect(
          position: newHead,
          type: EffectType.comboBurst,
          value: label,
          startTimeMs: nowMs,
        ));
      }
    }

    // Move food bulges down the snake
    for (int i = 0; i < foodBulges.length; i++) {
      foodBulges[i]++;
    }

    // Check if any bulge reached the end
    bool bulgeReachedEnd = false;
    foodBulges.removeWhere((b) {
      if (b >= snake.length - 1) {
        bulgeReachedEnd = true;
        return true;
      }
      return false;
    });

    if (bulgeReachedEnd) {
      onBulgeConsumed?.call();
      VibrationService().vibrate(duration: 15, amplitude: 50);
      effects.add(GameEffect(
        position: snake.last,
        type: EffectType.comboBurst,
        value: '✨',
        startTimeMs: gameTimeMs,
      ));
    }

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
          final now = gameTimeMs;
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

    // Update trail & emit skin-based tail trail
    trail.insert(0, oldTail);
    if (trail.length > 5) {
      trail.removeLast();
    }
    TailTrailService().add(oldTail, equippedSkin, gameTimeMs);
    TailTrailService().purge(gameTimeMs);

    // Advance ghost racer
    GhostRacingService().tickGhost();

    sessionPath.add(newHead);

    // Update camera after move (explore mode)
    if (gameMode == GameMode.explore) _updateCamera();

    // Clean up expired visual effects (fading after 0.8s)
    final now = gameTimeMs;
    effects.removeWhere((p) => now - p.startTimeMs > 800);

    if (collectedPowerUp != null) {
      _onPowerUpCollected(collectedPowerUp);
    }

    if (activeEvent != BoardEvent.none && now > eventEndMs) {
      if (activeEvent == BoardEvent.invertControls) {
        invertControlsUntilMs = 0;
      }
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
            gameMode == GameMode.timeAttack)) {
      if (snake.length > 5 && _rng.nextInt(1000) < 15) {
        const events = [
          BoardEvent.lightsOut,
          BoardEvent.iceBoard,
          BoardEvent.goldenRush,
          BoardEvent.invertControls,
          BoardEvent.scoreBoost,
        ];
        activeEvent = events[_rng.nextInt(events.length)];
        eventEndMs = now + 5000 + _rng.nextInt(2000);
        // invertControls reuses existing invertControlsUntilMs mechanism
        if (activeEvent == BoardEvent.invertControls) {
          invertControlsUntilMs = eventEndMs;
        }
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

    // Update adaptive music based on current state
    AdaptiveMusicService().update(
      combo: combo,
      isFeverMode: isFeverMode,
      isGameOver: isGameOver,
      isPaused: isPaused,
    );

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
        killerType = 'Wall';
        return false;
      }
    }

    if (obstacleSet.contains(pos)) {
      killerType = 'Obstacle';
      return false;
    }

    if (!_hasPowerUp(PowerUpType.ghostMode) && !isFeverMode) {
      if (snakeSet.contains(pos) && pos != snake.last) {
        killerType = 'Own Tail';
        return false;
      }
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
    final now = gameTimeMs;

    if (now - comboLastFoodMs <= AppConstants.comboWindow * 1000) {
      combo = min(combo + 1, AppConstants.comboMultiplierMax);
      if (combo >= 3) {
        VibrationService().heartbeat();
        ScreenShakeService().eatGolden();
        effects.add(GameEffect(
            position: snake.first,
            type: EffectType.comboBurst,
            value: 'x$combo STREAK!',
            startTimeMs: now));
      } else {
        VibrationService().vibrate(duration: 30, amplitude: 64);
        ScreenShakeService().eatSmall();
      }
    } else {
      if (combo > 1) {
        onComboDropped?.call();
      }
      combo = 1;
      VibrationService().vibrate(duration: 20, amplitude: 32);
      ScreenShakeService().eatSmall();
    }
    if (activeShadow != null) {
      activeShadow!.wins++;
      if (activeShadow!.wins >= 3) {
        int shadowBonus = equippedSkin == SnakeSkin.vampire ? 150 : 50;
        coinsEarnedSession += (shadowBonus * (1 + (greedLevel * 0.2))).round();
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
      activeShadow = ShadowSnake(segments: [spawnPos, spawnPos, spawnPos]);
      AnalyticsService().logShadowSnakeEvent('spawn');
      effects.add(GameEffect(
          position: spawnPos,
          type: EffectType.shadowPoof,
          value: 'Challenger!',
          startTimeMs: now));
    }

    comboLastFoodMs = now;
    foodBulges.add(0);

    // Fever Meter Logic
    if (combo >= 3) {
      feverMeter += (equippedSkin == SnakeSkin.rainbow) ? 40 : 20;
      if (feverMeter >= 100 && !isFeverMode) {
        isFeverMode = true;
        final feverDurationMs = activeRelicId == 'fever_heart' ? 12000 : 8000;
        feverEndMs = now + feverDurationMs;
        feverMeter = 0;
        AudioService().play(SoundEffect.powerUp);
        VibrationService().vibrate(duration: 500, amplitude: 255);
        ScreenShakeService().feverStart();
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
    if (activeRelicId == 'serrated_fangs') points = (points * 1.15).round();
    if (_hasPowerUp(PowerUpType.scoreMultiplier)) points *= 2;
    if (hasWraithsEye) points *= 3;
    if (equippedSkin == SnakeSkin.skeleton) points = (points * 1.05).round();

    if (food?.type == FoodType.boss) {
      points *= 10;
      coinsEarnedSession += (25 * (1 + (greedLevel * 0.2))).round();
      VibrationService().ripple();
      ScreenShakeService().eatBoss();
      effects.add(GameEffect(
          position: snake.first,
          type: EffectType.comboBurst,
          value: '👑 BOSS CAUGHT! x10',
          startTimeMs: now));
    } else if (food?.type == FoodType.golden) {
      points *= (equippedSkin == SnakeSkin.dragon) ? 8 : 5;
      goldenApplesEatenSession++;
      ScreenShakeService().eatGolden();
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

    // Board event score boost
    if (activeEvent == BoardEvent.scoreBoost) {
      points *= 2;
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
    }

    onFoodEaten?.call();
  }

  void _scaleSpeed() {
    if (gameMode == GameMode.explore) return; // Explore stays at constant pace

    final segments = max(0, snake.length - AppConstants.initialSnakeLength);
    final thresholds = segments ~/ AppConstants.speedScaleEvery;
    final baseSpeed = difficulty.initialSpeed;

    // Endless mode scales twice as fast and allows much lower minimum tick limits
    // New-player grace: reduce scale amount by 40% for first 5 games
    final int baseScaleAmount = gameMode == GameMode.endless
        ? difficulty.speedScaleAmount * 2
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

    // Golden Rush event: force golden food type
    if (activeEvent == BoardEvent.goldenRush) {
      t = FoodType.golden;
      expires = gameTimeMs + 8000;
    } else {
      bool allowGold = true;
      bool allowPoison = true;
      bool allowBoss = snake.length > 6 &&
          gameMode != GameMode.campaign; // boss food after some growth
      if (gameMode == GameMode.campaign && activeCampaignLevel != null) {
        allowGold = activeCampaignLevel!.hasGoldenApples;
        allowPoison = activeCampaignLevel!.hasPoisonApples;
      }

      final int goldenUpper = activeRelicId == 'hunters_luck' ? 12 : 9;

      if (r < 4 && allowBoss) {
        t = FoodType.boss;
        expires = gameTimeMs + 15000; // 15s window
        _bossMoveTick = 0;
      } else if (r >= 4 && r < goldenUpper && allowGold) {
        t = FoodType.golden;
        expires = gameTimeMs + 8000;
      } else if (r >= 9 && r < 19 && allowPoison) {
        t = FoodType.poison;
        expires = gameTimeMs + 8000;
      }
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
    _entityManager.moveBossFood(
      food: food,
      snake: snake,
      snakeSet: snakeSet,
      obstacleSet: obstacleSet,
      gridCols: gridCols,
      gridRows: gridRows,
      onUpdate: (newFood) => food = newFood,
    );
  }

  bool _pathExists(Position start, Position end) {
    if (gameMode == GameMode.endless || gameMode == GameMode.explore)
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
            preyList.any((p) => p.position == pos) ||
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
    final now = gameTimeMs;
    boardPowerUps.add(PowerUpModel(
      position: pos,
      type: type,
      expiresAtMs: now + 8000,
    ));
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
    ScreenShakeService().gameOver();
    TailTrailService().clear();
    _vibrate(200, 255);
    _ticker?.stop();
    _timeAttackTimer?.cancel();
    if (gameMode == GameMode.explore) {
      StorageService().clearExploreResume();
    }
    onGameOver?.call();
    notifyListeners();
  }

  bool _hasPowerUp(PowerUpType type) {
    final now = gameTimeMs;
    return activePowerUps.any((ap) => ap.type == type && ap.isActive(now));
  }

  ActivePowerUp? getActivePowerUp(PowerUpType type) {
    final now = gameTimeMs;
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
    final now = gameTimeMs;
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
    final now = gameTimeMs;

    if (pu.type.isInstant) {
      if (pu.type == PowerUpType.shrink) {
        final removeCount = (snake.length * 0.3).floor();
        for (int i = 0; i < removeCount; i++) {
          if (snake.length > 1) snake.removeLast();
        }
      } else if (pu.type == PowerUpType.cursedRelic) {
        hasWraithsEye = true;
        effects.add(GameEffect(
            position: snake.first,
            type: EffectType.comboBurst,
            value: 'CURSED: WRAITH\'S EYE',
            startTimeMs: now));
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

  /// Returns elite spawn chance (%) for a biome. Rarer in high-risk biomes but higher reward.
  int _eliteSpawnChance(BiomeType biome) {
    switch (biome) {
      case BiomeType.lavaField:
      case BiomeType.ashlands:
        return 7; // rarer → compensated by 1.6× reward bonus in _onPreyEaten
      case BiomeType.ruins:
        return 15;
      case BiomeType.frozenLake:
        return 11;
      case BiomeType.cave:
      case BiomeType.crystalCave:
        return 10;
      default:
        return 12;
    }
  }

  /// Returns which prey types are valid to spawn given a biome.
  List<FoodType> _preyTypesForBiome(BiomeType biome) {
    switch (biome) {
      case BiomeType.forest:
        return [FoodType.mouse, FoodType.rabbit, FoodType.fruit];
      case BiomeType.jungle:
        return [
          FoodType.rabbit,
          FoodType.lizard,
          FoodType.butterfly,
          FoodType.fruit
        ];
      case BiomeType.desert:
        return [FoodType.lizard, FoodType.mouse];
      case BiomeType.savanna:
        return [FoodType.rabbit, FoodType.lizard];
      case BiomeType.swamp:
        return [FoodType.croc, FoodType.lizard, FoodType.fruit];
      case BiomeType.coral:
        return [FoodType.butterfly, FoodType.lizard, FoodType.fruit];
      case BiomeType.cave:
        return [FoodType.butterfly, FoodType.lizard];
      case BiomeType.crystalCave:
        return [FoodType.butterfly, FoodType.mouse];
      case BiomeType.ruins:
        return [FoodType.mouse, FoodType.butterfly, FoodType.lizard];
      case BiomeType.tundra:
        return [FoodType.rabbit, FoodType.mouse];
      case BiomeType.frozenLake:
        return [FoodType.rabbit, FoodType.butterfly, FoodType.mouse];
      case BiomeType.lavaField:
        return [FoodType.lizard, FoodType.croc];
      case BiomeType.ashlands:
        return [FoodType.lizard, FoodType.mouse, FoodType.croc];
      case BiomeType.mushroom:
        return [
          FoodType.butterfly,
          FoodType.mouse,
          FoodType.rabbit,
          FoodType.fruit
        ];
    }
  }

  void _spawnInitialPrey() {
    preyList.clear();
    if (snake.isNotEmpty) {
      _spawnSinglePrey(nearPos: snake.first);
    }
    while (preyList.length < 3) {
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

    if (!hasShrineSpawnedThisFloor &&
        preyCaughtThisFloor >= 2 &&
        _rng.nextInt(100) < 30) {
      hasShrineSpawnedThisFloor = true;
      preyList.add(FoodModel(position: pos, type: FoodType.shrine));
      return;
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
    FoodType type = candidates[_rng.nextInt(candidates.length)];

    if (biome != null &&
        (biome == BiomeType.lavaField ||
            biome == BiomeType.ashlands ||
            biome == BiomeType.cave ||
            biome == BiomeType.crystalCave ||
            biome == BiomeType.frozenLake ||
            biome == BiomeType.ruins) &&
        _rng.nextInt(100) < _eliteSpawnChance(biome)) {
      type = FoodType.elite;
    }

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
        final expires = gameTimeMs + butterflyMs;
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
      case FoodType.elite:
        preyList.add(FoodModel(
            position: pos,
            type: FoodType.elite,
            expiresAtMs: gameTimeMs + 22000,
            dashChargesLeft: 2));
        break;
      case FoodType.fruit:
        preyList.add(FoodModel(
            position: pos,
            type: FoodType.fruit,
            expiresAtMs: gameTimeMs + 20000));
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
    _entityManager.movePrey(
      preyList: preyList,
      snake: snake,
      snakeSet: snakeSet,
      obstacleSet: obstacleSet,
      gridCols: gridCols,
      gridRows: gridRows,
      roomBiomes: roomBiomes,
      gameTimeMs: gameTimeMs,
      preyMagnetEndMs: preyMagnetEndMs,
      equippedSkin: equippedSkin,
      rng: _rng,
    );
  }

  void _ensureExplorePreyPopulation() {
    if (gameMode != GameMode.explore) return;

    final now = gameTimeMs;
    preyList.removeWhere((p) {
      final expired =
          p.expiresAtMs != null && p.expiresAtMs! > 0 && now > p.expiresAtMs!;
      final invalidCell = p.position.x < 0 ||
          p.position.x >= gridCols ||
          p.position.y < 0 ||
          p.position.y >= gridRows ||
          obstacleSet.contains(p.position) ||
          snakeSet.contains(p.position);
      return expired || invalidCell;
    });

    if (preyList.isEmpty && snake.isNotEmpty) {
      _spawnSinglePrey(nearPos: snake.first);
    }
    while (preyList.length < 3) {
      _spawnSinglePrey();
    }
  }

  void _trySpawnBiomeMiniEvent() {
    if (gameMode != GameMode.explore || snake.isEmpty) return;
    if (gameTimeMs < biomeEventCooldownMs) return;
    if (preyList.any((p) => p.type == FoodType.biomeEvent)) return;

    final biome = currentBiome;
    if (biome == null) return;

    final rollChance = switch (biome) {
      BiomeType.lavaField || BiomeType.ashlands => 30,
      BiomeType.frozenLake || BiomeType.tundra => 24,
      BiomeType.cave || BiomeType.crystalCave => 24,
      BiomeType.swamp || BiomeType.mushroom => 20,
      _ => 16,
    };

    if (_rng.nextInt(100) >= rollChance) {
      biomeEventCooldownMs = gameTimeMs + 6000;
      return;
    }

    final spawn = _getEmptyPosNear(snake.first, radius: 9);
    preyList.add(FoodModel(
      position: spawn,
      type: FoodType.biomeEvent,
      expiresAtMs: gameTimeMs + 12000,
    ));

    effects.add(GameEffect(
      position: spawn,
      type: EffectType.comboBurst,
      value: 'BIOME EVENT!',
      startTimeMs: gameTimeMs,
    ));

    biomeEventCooldownMs = gameTimeMs + 18000;
  }

  void _onPreyEaten(FoodModel prey) {
    if (prey.type == FoodType.portal) {
      isCampfirePhase = true;
      pause();
      return;
    }

    if (prey.type == FoodType.shrine) {
      _activateShrine(prey);
      return;
    }

    if (prey.type == FoodType.biomeEvent) {
      _activateBiomeMiniEvent(prey);
      return;
    }

    AudioService().play(SoundEffect.eat);
    VibrationService().vibrate(duration: 30, amplitude: 64);
    final now = gameTimeMs;

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
    if (activeRelicId == 'serrated_fangs') {
      points = (points * 1.15).round();
    }
    if (_hasPowerUp(PowerUpType.scoreMultiplier)) points *= 2;

    // Elite: biome-specific reward bonus
    if (prey.type == FoodType.elite) {
      final eliteBiome = _roomBiomeAt(prey.position);
      if (eliteBiome == BiomeType.lavaField ||
          eliteBiome == BiomeType.ashlands) {
        points = (points * 1.6).round();
        coinsEarnedSession += 30;
        effects.add(GameEffect(
            position: snake.first,
            type: EffectType.comboBurst,
            value: '🔥 INFERNO ELITE! BONUS',
            startTimeMs: now));
      } else if (eliteBiome == BiomeType.ruins) {
        points = (points * 1.3).round();
        coinsEarnedSession += 15;
      }
    }

    // Safari skin passives
    if (equippedSkin == SnakeSkin.jadeSerpent && prey.type.name == 'lizard') {
      points = (points * 1.5).round();
    }
    score += points;

    // Greed Skill: Flat coin bonus per prey
    if (greedLevel > 0) {
      coinsEarnedSession += greedLevel;
    }

    // Safari Journal: record catch + biome + mission progress
    final typeName = prey.type.name;
    StorageService().incrementSafariCount(typeName);
    final room = _roomBiomeAt(snake.first);
    if (room != null) {
      final storage = StorageService();
      final isFirstVisit = !storage.safariVisitedBiomes.contains(room.name);
      storage.recordBiomeVisit(room.name);
      if (isFirstVisit) {
        storage.addSnakeSouls(1);
        coinsEarnedSession += 30;
        effects.add(GameEffect(
            position: snake.first,
            type: EffectType.comboBurst,
            value: 'NEW BIOME! +1💎',
            startTimeMs: now));
      }
    }
    StorageService().incrementSafariMissionProgress();

    if (huntStreak > 0 && huntStreak % 4 == 0) {
      dashCharges += 1;
      effects.add(GameEffect(
          position: snake.first,
          type: EffectType.comboBurst,
          value: 'DASH +1',
          startTimeMs: now));
    }

    if (score > highestScoreOnRecord &&
        !isHighScoreCelebrated &&
        highestScoreOnRecord > 0) {
      isHighScoreCelebrated = true;
      onHighScoreReached?.call();
    }

    preyCaughtThisFloor++;
    foodBulges.add(0);

    // In Explore mode, 5% chance to spawn a shadow hunter when catching prey (15% if cursed!)
    if (activeShadow == null) {
      int spawnChance = hasWraithsEye ? 15 : 5;
      if (_rng.nextInt(100) < spawnChance) {
        Position spawnPos = _getEmptyPosNear(snake.first, radius: 10);
        activeShadow = ShadowSnake(segments: [spawnPos, spawnPos, spawnPos]);
        effects.add(GameEffect(
            position: spawnPos,
            type: EffectType.shadowPoof,
            value: 'HUNTED!',
            startTimeMs: now));
        AudioService().play(SoundEffect.shadowDefeat); // Scary warning sound
        VibrationService().vibrate(duration: 500, amplitude: 255);
      }
    }

    if (preyCaughtThisFloor == 5 + (currentFloor * 2)) {
      _spawnPortal();
    } else {
      _spawnSinglePrey(nearPos: prey.position);
    }
    onFoodEaten?.call();
  }

  void _spawnPortal() {
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
      if (!snakeSet.contains(pos) && !obstacleSet.contains(pos)) {
        break;
      }
      attempts++;
    }
    preyList.add(FoodModel(position: pos, type: FoodType.portal));

    final now = gameTimeMs;
    effects.add(GameEffect(
      position: pos,
      type: EffectType.comboBurst,
      value: '🌀 PORTAL OPENED!',
      startTimeMs: now,
    ));
    VibrationService().heartbeat();
  }

  void _activateShrine(FoodModel prey) {
    AudioService().play(SoundEffect.powerUp);
    VibrationService().vibrate(duration: 500, amplitude: 255);

    // Sacrifice 5 segments (if possible) for massive points and coins
    int sacrifice = min(5, max(0, snake.length - 3));
    for (int i = 0; i < sacrifice; i++) {
      if (snake.length > 3) snake.removeLast();
    }

    score += 500 * currentFloor;
    coinsEarnedSession += (50 * (1 + (greedLevel * 0.2))).round();

    // Grant invincibility (Ghost Mode)
    final now = gameTimeMs;
    activePowerUps.removeWhere((ap) => ap.type == PowerUpType.ghostMode);
    activePowerUps.add(ActivePowerUp(
      type: PowerUpType.ghostMode,
      endsAtMs: now + 15000, // 15 seconds
    ));

    effects.add(GameEffect(
      position: snake.first,
      type: EffectType.comboBurst,
      value: 'BLOOD SACRIFICE!',
      startTimeMs: now,
    ));
    notifyListeners();
  }

  void _activateBiomeMiniEvent(FoodModel prey) {
    final now = gameTimeMs;
    final biome = _roomBiomeAt(prey.position) ?? currentBiome;
    if (biome == null) return;

    AudioService().play(SoundEffect.powerUp);
    VibrationService().ripple();

    switch (biome) {
      case BiomeType.lavaField:
      case BiomeType.ashlands:
        wallHitsLeft += 1;
        score += 260;
        effects.add(GameEffect(
          position: snake.first,
          type: EffectType.comboBurst,
          value: 'HEAT CORE! SHIELD +1',
          startTimeMs: now,
        ));
        break;
      case BiomeType.tundra:
      case BiomeType.frozenLake:
        dashCharges += 2;
        activePowerUps.removeWhere((ap) => ap.type == PowerUpType.ghostMode);
        activePowerUps.add(ActivePowerUp(
          type: PowerUpType.ghostMode,
          endsAtMs: now + 4000,
        ));
        effects.add(GameEffect(
          position: snake.first,
          type: EffectType.comboBurst,
          value: 'FROST SURGE! DASH +2',
          startTimeMs: now,
        ));
        break;
      case BiomeType.swamp:
      case BiomeType.mushroom:
        coinsEarnedSession += 80;
        StorageService().addSnakeSouls(1);
        effects.add(GameEffect(
          position: snake.first,
          type: EffectType.comboBurst,
          value: 'PRIMAL CACHE +1💎',
          startTimeMs: now,
        ));
        break;
      case BiomeType.cave:
      case BiomeType.crystalCave:
      case BiomeType.ruins:
        _spawnSinglePrey(nearPos: snake.first);
        _spawnSinglePrey(nearPos: snake.first);
        score += 180;
        effects.add(GameEffect(
          position: snake.first,
          type: EffectType.comboBurst,
          value: 'RELIC ECHO! EXTRA PREY',
          startTimeMs: now,
        ));
        break;
      default:
        score += 120;
        if (huntStreak >= 2) {
          dashCharges += 1;
        }
        effects.add(GameEffect(
          position: snake.first,
          type: EffectType.comboBurst,
          value: 'BIOME BLESSING!',
          startTimeMs: now,
        ));
        break;
    }

    onFoodEaten?.call();
    notifyListeners();
  }

  BiomeType? get currentBiome {
    if (snake.isEmpty) return null;
    return _roomBiomeAt(snake.first);
  }

  BiomeType? _roomBiomeAt(Position pos) {
    final rx = pos.x ~/ 10;
    final ry = pos.y ~/ 10;
    return roomBiomes[rx * 11 + ry];
  }

  void _updateBiomeAmbientAudio() {
    if (gameMode != GameMode.explore) return;
    final biome = currentBiome;
    if (biome == null) return;

    _ambientAudioTickCounter++;
    // Around every 6-8 seconds depending on speed; keep ambience subtle.
    if (_ambientAudioTickCounter < 30) return;
    _ambientAudioTickCounter = 0;

    switch (biome) {
      case BiomeType.desert:
      case BiomeType.savanna:
        if (_rng.nextDouble() < 0.20) {
          AudioService().play(SoundEffect.click, volume: 0.08);
        }
        break;
      case BiomeType.tundra:
      case BiomeType.frozenLake:
        if (_rng.nextDouble() < 0.18) {
          AudioService().play(SoundEffect.countdown, volume: 0.06);
        }
        break;
      case BiomeType.lavaField:
      case BiomeType.ashlands:
        if (_rng.nextDouble() < 0.15) {
          AudioService().play(SoundEffect.gameOver, volume: 0.04);
        }
        break;
      case BiomeType.mushroom:
        if (_rng.nextDouble() < 0.20) {
          AudioService().play(SoundEffect.powerUp, volume: 0.05);
        }
        break;
      case BiomeType.swamp:
        if (_rng.nextDouble() < 0.20) {
          AudioService().play(SoundEffect.click, volume: 0.05);
        }
        break;
      case BiomeType.coral:
        if (_rng.nextDouble() < 0.18) {
          AudioService().play(SoundEffect.eat, volume: 0.05);
        }
        break;
      case BiomeType.cave:
      case BiomeType.crystalCave:
        if (_rng.nextDouble() < 0.18) {
          AudioService().play(SoundEffect.countdown, volume: 0.05);
        }
        break;
      case BiomeType.forest:
      case BiomeType.jungle:
        if (_rng.nextDouble() < 0.16) {
          AudioService().play(SoundEffect.eat, volume: 0.04);
        }
        break;
      case BiomeType.ruins:
        if (_rng.nextDouble() < 0.18) {
          AudioService().play(SoundEffect.click, volume: 0.05);
        }
        break;
    }
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
      case FoodType.elite:
        return 320;
      case FoodType.biomeEvent:
        return 120;
      case FoodType.fruit:
        return 55;
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
      case FoodType.elite:
        return '⚔ ELITE HUNT! +$pts';
      case FoodType.biomeEvent:
        return '✨ BIOME ANOMALY +$pts';
      case FoodType.fruit:
        return '🍎 FRUIT! +$pts';
      default:
        return '+$pts';
    }
  }

  void _moveShadow() {
    _entityManager.moveShadow(
      activeShadow: activeShadow,
      gameMode: gameMode,
      snake: snake,
      snakeSet: snakeSet,
      food: food,
      gridCols: gridCols,
      gridRows: gridRows,
      isGhostMode: _hasPowerUp(PowerUpType.ghostMode),
      onKill: () {
        killerType = 'Shadow Hunter';
        _triggerGameOver();
      },
      onFoodStolen: () {
        food = null;
        _spawnFood();
      },
    );
  }
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
