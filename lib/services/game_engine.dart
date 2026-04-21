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
import 'analytics_service.dart';
import 'notification_service.dart';
import 'vibration_service.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../core/models/daily_event.dart';

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

  CampaignLevel? activeCampaignLevel;
  bool isCampaignWon = false;

  BoardEvent activeEvent = BoardEvent.none;
  int eventEndMs = 0;

  bool comebackBonus = false;
  int comebackBonusEndMs = 0;

  DailyEvent? activeDailyEvent;

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
  Direction? _lastMoveDirection;

  Future<void> _vibrate(int duration, int amplitude) async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        if (await Vibration.hasAmplitudeControl() ?? false) {
          Vibration.vibrate(duration: duration, amplitude: amplitude);
        } else {
          Vibration.vibrate(duration: duration);
        }
      }
    } catch (_) {}
  }
  
  final Random _rng = Random();
  int _foodEatenSinceLastPowerUp = 0;

  void init({
    required GameMode mode,
    required Difficulty diff,
    required SnakeSkin skin,
    CampaignLevel? campaignLevel,
    bool withComebackBonus = false,
    DailyEvent? dailyEvent,
  }) {
    gameMode = mode;
    difficulty = diff;
    equippedSkin = skin;
    activeCampaignLevel = campaignLevel;
    activeDailyEvent = dailyEvent;
    
    ghostPath = StorageService().getBestReplay();
    ghostIndex = 0;
    sessionPath = [];
    
    currentTickMs = diff.initialSpeed;
    if (gameMode == GameMode.campaign && campaignLevel != null) {
      currentTickMs = (AppConstants.speedNormal / campaignLevel.speedMultiplier).round();
    }
    
    // Apply daily event modifiers
    if (activeDailyEvent != null) {
      if (activeDailyEvent!.type == DailyEventType.speedDash) {
        currentTickMs = (currentTickMs / 2).round();
      } else if (activeDailyEvent!.type == DailyEventType.zenMode) {
        currentTickMs = (currentTickMs * 1.5).round();
      }
    }

    _reset();
    if (withComebackBonus) {
      comebackBonus = true;
      comebackBonusEndMs = DateTime.now().millisecondsSinceEpoch + 30000;
    }
    
    highestScoreOnRecord = StorageService().bestScore;
    isHighScoreCelebrated = false;
  }

  void _reset() {
    snake = [
      const Position(AppConstants.startX, AppConstants.startY),
      const Position(AppConstants.startX - 1, AppConstants.startY),
      const Position(AppConstants.startX - 2, AppConstants.startY),
    ];
    snakeSet = HashSet<Position>.from(snake);
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
    _lastMoveDirection = null;
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
    timeRemainingSeconds = AppConstants.timeAttackSeconds;
    if (gameMode == GameMode.campaign && activeCampaignLevel?.timeLimitSeconds != null && activeCampaignLevel!.timeLimitSeconds > 0) {
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
    if (gameMode != GameMode.endless && gameMode != GameMode.campaign) {
      _generatePerimeterWalls();
    } else if (gameMode == GameMode.campaign) {
      _generatePerimeterWalls();
      _generateCampaignObstacles();
      if (activeCampaignLevel!.hasPortals) _generateTruePortals();
    }

    if (gameMode == GameMode.maze || gameMode == GameMode.portal) {
      _generateMazeObstacles();
    }
    
    if (gameMode == GameMode.portal) {
      _generateTruePortals();
    }

    _spawnFood();
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

  void start() {
    isPlaying = true;
    isPaused = false;
    _startTimer();
    if (gameMode == GameMode.timeAttack || (gameMode == GameMode.campaign && activeCampaignLevel!.timeLimitSeconds > 0)) {
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
    if (gameMode == GameMode.timeAttack || (gameMode == GameMode.campaign && activeCampaignLevel!.timeLimitSeconds > 0)) {
      _startTimeAttackTimer();
    }
  }

  void restart() {
    _ticker?.stop();
    _timeAttackTimer?.cancel();
    currentTickMs = difficulty.initialSpeed;
    _reset();
    start();
  }

  void changeDirection(Direction newDir) {
    if (DateTime.now().millisecondsSinceEpoch < invertControlsUntilMs) {
      newDir = newDir.opposite();
    }
    if (_directionQueue.isNotEmpty) {
      final last = _directionQueue.last;
      if (last.isOpposite(newDir) || last == newDir) return;
    } else {
      if (currentDirection.isOpposite(newDir) || currentDirection == newDir) return;
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
    if (equippedSkin == SnakeSkin.ninja) currentDelay = (currentDelay * 0.9).round();
    
    if (isFeverMode) {
      currentDelay = (currentDelay * 0.7).round();
    } else if (isBoosting) {
      currentDelay = (currentDelay * 0.5).round();
    }

    if (_lastTickTime == Duration.zero || elapsed.inMilliseconds - _lastTickTime.inMilliseconds >= currentDelay) {
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

    if (activeEvent == BoardEvent.iceBoard && nextDir != null && !_shouldSkidNextTick) {
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
    
    _lastMoveDirection = currentDirection;

    // Advance ghost
    if (ghostPath.isNotEmpty && ghostIndex < ghostPath.length) {
      ghostIndex++;
    }

    // Advance shadow
    if (activeShadow != null) {
      _moveShadow();
    }
    
    if (isFeverMode) {
      _attractFood();
    } else if (_hasPowerUp(PowerUpType.magnet) && food != null) {
      _attractFood();
    }

    final head = snake.first;
    final Position newHead = _nextHead(head);

    if (!_isValidPosition(newHead)) {
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

    if (food != null && newHead == food!.position) {
      _onFoodEaten();
    } else {
      snake.removeLast();
      snakeSet.remove(oldTail);
    }

    // Update trail
    trail.insert(0, oldTail);
    if (trail.length > 5) {
      trail.removeLast();
    }

    sessionPath.add(newHead);

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

    if (activeEvent == BoardEvent.none && (gameMode == GameMode.classic || gameMode == GameMode.endless || gameMode == GameMode.timeAttack)) {
       if (snake.length > 5 && _rng.nextInt(1000) < 15) {
          activeEvent = _rng.nextBool() ? BoardEvent.lightsOut : BoardEvent.iceBoard;
          eventEndMs = now + 5000 + _rng.nextInt(2000);
          AudioService().play(SoundEffect.powerUp);
       }
    }

    if (food != null && food!.expiresAtMs != null && now > food!.expiresAtMs!) {
      _spawnFood();
    }
    
    boardPowerUps.removeWhere((pu) => pu.isExpired(now));
    activePowerUps.removeWhere((pu) => !pu.isActive(now));

    if (!_hasPowerUp(PowerUpType.slowMotion) && !_hasPowerUp(PowerUpType.speedBoost)) {
      _scaleSpeed();
    }

    if (gameMode == GameMode.campaign && snake.length >= activeCampaignLevel!.targetLength) {
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
    if (gameMode != GameMode.endless) {
      if (pos.x < 0 ||
          pos.x >= AppConstants.gridColumns ||
          pos.y < 0 ||
          pos.y >= AppConstants.gridRows) {
        return false;
      }
    }

    if (obstacleSet.contains(pos)) return false;

    if (!_hasPowerUp(PowerUpType.ghostMode) && !isFeverMode) {
      if (snakeSet.contains(pos) && pos != snake.last) return false;
    }

    return true;
  }

  void _onFoodEaten() {
    AudioService().play(SoundEffect.eat);
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now - comboLastFoodMs <= AppConstants.comboWindow * 1000) {
      combo = min(combo + 1, AppConstants.comboMultiplierMax);
      if (combo >= 3) {
        VibrationService().heartbeat();
        effects.add(GameEffect(position: snake.first, type: EffectType.comboBurst, value: 'x$combo STREAK!', startTimeMs: now));
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
        effects.add(GameEffect(position: activeShadow!.segments.first, type: EffectType.shadowPoof, startTimeMs: now));
        activeShadow = null;
      }
    } else if (Random().nextDouble() < 0.05) { // 5% chance to spawn shadow on food eaten if not active
      // Spawn slightly safely
      Position spawnPos = Position(
        AppConstants.gridColumns - 1 - snake.last.x,
        AppConstants.gridRows - 1 - snake.last.y,
      );
      activeShadow = ShadowSnake(spawnPos); 
      AnalyticsService().logShadowSnakeEvent('spawn');
      effects.add(GameEffect(position: spawnPos, type: EffectType.shadowPoof, value: 'Challenger!', startTimeMs: now));
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
        effects.add(GameEffect(position: snake.first, type: EffectType.comboBurst, value: 'FEVER MODE!', startTimeMs: now));
      }
    }

    int points = AppConstants.baseScore;
    points = (points * (1 + combo * 0.5)).round();
    points = (points * difficulty.scoreMultiplier).round();
    if (_hasPowerUp(PowerUpType.scoreMultiplier)) points *= 2;
    if (equippedSkin == SnakeSkin.skeleton) points = (points * 1.05).round();
    
    if (food?.type == FoodType.golden) {
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

    score += points;
    
    if (score > highestScoreOnRecord && !isHighScoreCelebrated && highestScoreOnRecord > 0) {
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
    if (gameMode == GameMode.portal) return; // Portal speed is fixed

    final segments = max(0, snake.length - AppConstants.initialSnakeLength);
    final thresholds = segments ~/ AppConstants.speedScaleEvery;
    final baseSpeed = difficulty.initialSpeed;
    
    // Endless mode scales twice as fast and allows much lower minimum tick limits
    final int scaleAmount = gameMode == GameMode.endless 
        ? AppConstants.speedScaleAmount * 2 
        : AppConstants.speedScaleAmount;
        
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
    if (gameMode == GameMode.campaign && activeCampaignLevel != null) {
      allowGold = activeCampaignLevel!.hasGoldenApples;
      allowPoison = activeCampaignLevel!.hasPoisonApples;
    }

    if (r < 5 && allowGold) {
      t = FoodType.golden;
      expires = DateTime.now().millisecondsSinceEpoch + 8000;
    } else if (r >= 5 && r < 15 && allowPoison) {
      t = FoodType.poison;
      expires = DateTime.now().millisecondsSinceEpoch + 8000;
    }

    Position pos = Position(
      _rng.nextInt(AppConstants.gridColumns),
      _rng.nextInt(AppConstants.gridRows),
    );
    int attempts = 0;
    while (attempts < 200) {
      pos = Position(
        _rng.nextInt(AppConstants.gridColumns),
        _rng.nextInt(AppConstants.gridRows),
      );
      if (!snakeSet.contains(pos) &&
          !obstacleSet.contains(pos) &&
          !boardPowerUps.any((pu) => pu.position == pos)) {
         
         // In maze/campaign modes with obstacles, verify food is actually reachable (A*/BFS check)
         if (obstacleSet.isNotEmpty) {
           if (_pathExists(snake.first, pos)) break;
         } else {
           break;
         }
      }
      attempts++;
    }
    food = FoodModel(position: pos, type: t, expiresAtMs: expires);
  }

  bool _pathExists(Position start, Position end) {
    if (gameMode == GameMode.endless || gameMode == GameMode.portal) return true; // Wraparound complicates simple BFS, assume reachable
    
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
         if (n.x >= 0 && n.x < AppConstants.gridColumns && n.y >= 0 && n.y < AppConstants.gridRows) {
            if (!visited.contains(n) && !obstacleSet.contains(n)) {
               // Ignore snake tail as it will move, but treat existing body as somewhat solid if we want strict, but simpler to ignore snake for reachable check.
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
    Position pos = Position(
      _rng.nextInt(AppConstants.gridColumns),
      _rng.nextInt(AppConstants.gridRows)
    );
    int attempts = 0;
    while (attempts < 200 && (
      snakeSet.contains(pos) || 
      obstacleSet.contains(pos) || 
      boardPowerUps.any((pu) => pu.position == pos) || 
      boardPortals.containsKey(pos) || 
      food?.position == pos
    )) {
      pos = Position(
        _rng.nextInt(AppConstants.gridColumns),
        _rng.nextInt(AppConstants.gridRows)
      );
      attempts++;
    }
    return pos;
  }

  void _spawnPowerUp() {
    final type = PowerUpType.values[_rng.nextInt(PowerUpType.values.length)];
    Position pos = Position(
      _rng.nextInt(AppConstants.gridColumns),
      _rng.nextInt(AppConstants.gridRows),
    );
    int attempts = 0;
    while (attempts < 200 &&
        (snakeSet.contains(pos) ||
            obstacleSet.contains(pos) ||
            food?.position == pos ||
            boardPowerUps.any((pu) => pu.position == pos))) {
      pos = Position(
        _rng.nextInt(AppConstants.gridColumns),
        _rng.nextInt(AppConstants.gridRows),
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
        _rng.nextInt(AppConstants.gridColumns),
        _rng.nextInt(AppConstants.gridRows),
      );
      if ((pos.x - AppConstants.startX).abs() > clearZone ||
          (pos.y - AppConstants.startY).abs() > clearZone) {
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
    int nx = fp.x + (head.x > fp.x ? 1 : head.x < fp.x ? -1 : 0);
    int ny = fp.y + (head.y > fp.y ? 1 : head.y < fp.y ? -1 : 0);
    nx = nx.clamp(0, AppConstants.gridColumns - 1);
    ny = ny.clamp(0, AppConstants.gridRows - 1);
    
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
      return activePowerUps.firstWhere((ap) => ap.type == type && ap.isActive(now));
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
    const int cx = AppConstants.startX;
    const int cy = AppConstants.startY;
    
    // Clear nearby obstacles to prevent immediate death
    obstacleSet.removeWhere((pos) => 
        (pos.x - cx).abs() <= 2 && (pos.y - cy).abs() <= 2);
        
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
      } else if (x >= AppConstants.gridColumns) {
        x = AppConstants.gridColumns - 1;
        y += 1;
        xDir = -1; // Start extending to the left
      }
      
      // Safe wrap the Y coordinate just in case it hits bottom
      if (y >= AppConstants.gridRows) {
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

  void _moveShadow() {
    if (food == null || activeShadow == null) return;
    
    // Simple A* would be overkill, just move towards food
    final target = food!.position;
    final current = activeShadow!.segments.first;
    
    int dx = 0;
    int dy = 0;
    
    if (target.x > current.x) {
      dx = 1;
    } else if (target.x < current.x) dx = -1;
    else if (target.y > current.y) dy = 1;
    else if (target.y < current.y) dy = -1;
    
    final next = Position((current.x + dx) % AppConstants.gridColumns, (current.y + dy) % AppConstants.gridRows);
    
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
  GameEffect({required this.position, required this.type, this.value, required this.startTimeMs});
}
