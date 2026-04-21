import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../core/enums/direction.dart';
import '../core/models/position.dart';
import '../core/models/food_model.dart';

class MultiplayerEngine extends ChangeNotifier {
  List<Position> snake1 = [];
  List<Position> snake2 = [];
  Position? collisionPoint;
  
  Direction currentDirection1 = Direction.up;
  Direction currentDirection2 = Direction.down;
  
  final List<Direction> _dirQueue1 = [];
  final List<Direction> _dirQueue2 = [];
  
  FoodModel? food;
  
  int score1 = 0;
  int score2 = 0;
  
  bool isPlaying = false;
  bool isPaused = false;
  bool isGameOver = false;
  int winner = 0; // 0: none, 1: p1, 2: p2, 3: draw
  
  int currentTickMs = AppConstants.speedNormal;
  Timer? _gameTimer;
  final Random _rng = Random();

  VoidCallback? onFoodEaten;
  VoidCallback? onGameOver;

  void init() {
    _reset();
  }

  void _reset() {
    // P1 at bottom
    snake1 = [
      const Position(AppConstants.gridColumns ~/ 2, AppConstants.gridRows - 4),
      const Position(AppConstants.gridColumns ~/ 2, AppConstants.gridRows - 3),
      const Position(AppConstants.gridColumns ~/ 2, AppConstants.gridRows - 2),
    ];
    currentDirection1 = Direction.up;
    _dirQueue1.clear();

    // P2 at top
    snake2 = [
      const Position(AppConstants.gridColumns ~/ 2, 3),
      const Position(AppConstants.gridColumns ~/ 2, 2),
      const Position(AppConstants.gridColumns ~/ 2, 1),
    ];
    currentDirection2 = Direction.down;
    _dirQueue2.clear();

    score1 = 0;
    score2 = 0;
    winner = 0;
    collisionPoint = null;
    isGameOver = false;
    isPaused = false;
    currentTickMs = AppConstants.speedNormal;

    _spawnFood();
  }

  void start() {
    isPlaying = true;
    isPaused = false;
    _startTimer();
  }

  void pause() {
    isPaused = true;
    _gameTimer?.cancel();
    notifyListeners();
  }

  void resume() {
    isPaused = false;
    _startTimer();
  }

  void restart() {
    _gameTimer?.cancel();
    _reset();
    start();
  }

  void changeDirection1(Direction newDir) {
    if (_dirQueue1.isNotEmpty) {
      final last = _dirQueue1.last;
      if (last.isOpposite(newDir) || last == newDir) return;
    } else {
      if (currentDirection1.isOpposite(newDir) || currentDirection1 == newDir) return;
    }
    if (_dirQueue1.length < 3) _dirQueue1.add(newDir);
  }

  void changeDirection2(Direction newDir) {
    if (_dirQueue2.isNotEmpty) {
      final last = _dirQueue2.last;
      if (last.isOpposite(newDir) || last == newDir) return;
    } else {
      if (currentDirection2.isOpposite(newDir) || currentDirection2 == newDir) return;
    }
    if (_dirQueue2.length < 3) _dirQueue2.add(newDir);
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(Duration(milliseconds: currentTickMs), (_) {
      if (!isPaused && !isGameOver) _tick();
    });
  }

  void _tick() {
    if (_dirQueue1.isNotEmpty) currentDirection1 = _dirQueue1.removeAt(0);
    if (_dirQueue2.isNotEmpty) currentDirection2 = _dirQueue2.removeAt(0);

    final head1 = snake1.first;
    final head2 = snake2.first;

    final newHead1 = _nextHead(head1, currentDirection1);
    final newHead2 = _nextHead(head2, currentDirection2);

    // Check collisions
    bool crash1 = !_isValid(newHead1);
    bool crash2 = !_isValid(newHead2);

    // Mutual head-on collision
    if (newHead1 == newHead2) {
      crash1 = true;
      crash2 = true;
      collisionPoint = newHead1;
    } else {
      // Check tail bites
      if (snake2.contains(newHead1)) {
        crash1 = true;
        collisionPoint = newHead1;
      }
      if (snake1.contains(newHead2)) {
        crash2 = true;
        collisionPoint = newHead2;
      }
      if (crash1 && collisionPoint == null) collisionPoint = newHead1;
      if (crash2 && collisionPoint == null) collisionPoint = newHead2;
    }

    if (crash1 && crash2) {
      winner = 3;
      _triggerGameOver();
      return;
    } else if (crash1) {
      winner = 2;
      _triggerGameOver();
      return;
    } else if (crash2) {
      winner = 1;
      _triggerGameOver();
      return;
    }

    // Move p1
    bool ate1 = food != null && newHead1 == food!.position;
    snake1.insert(0, newHead1);
    if (!ate1) {
      snake1.removeLast();
    } else {
      score1++;
    }

    // Move p2
    bool ate2 = food != null && newHead2 == food!.position;
    snake2.insert(0, newHead2);
    if (!ate2) {
      snake2.removeLast();
    } else {
      score2++;
    }

    if (ate1 || ate2) {
      onFoodEaten?.call();
      _spawnFood();
      _scaleSpeed();
    }

    notifyListeners();
  }

  Position _nextHead(Position head, Direction dir) {
    int nx = head.x;
    int ny = head.y;
    switch (dir) {
      case Direction.up: ny -= 1; break;
      case Direction.down: ny += 1; break;
      case Direction.left: nx -= 1; break;
      case Direction.right: nx += 1; break;
    }
    return Position(nx, ny);
  }

  bool _isValid(Position pos) {
    if (pos.x < 0 || pos.x >= AppConstants.gridColumns ||
        pos.y < 0 || pos.y >= AppConstants.gridRows) {
      return false;
    }
    return true;
  }

  void _triggerGameOver() {
    isGameOver = true;
    isPlaying = false;
    _gameTimer?.cancel();
    onGameOver?.call();
    notifyListeners();
  }

  void _spawnFood() {
    int attempts = 0;
    Position pos = Position(_rng.nextInt(AppConstants.gridColumns), _rng.nextInt(AppConstants.gridRows));
    while (attempts < 200 && (snake1.contains(pos) || snake2.contains(pos))) {
      pos = Position(_rng.nextInt(AppConstants.gridColumns), _rng.nextInt(AppConstants.gridRows));
      attempts++;
    }
    food = FoodModel(position: pos);
  }

  void _scaleSpeed() {
    final maxLen = max(snake1.length, snake2.length) - AppConstants.initialSnakeLength;
    final thresholds = maxLen ~/ AppConstants.speedScaleEvery;
    final newSpeed = max(
      AppConstants.speedMin,
      AppConstants.speedNormal - thresholds * AppConstants.speedScaleAmount,
    );
    if (newSpeed < currentTickMs) {
      currentTickMs = newSpeed;
      _startTimer();
    }
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }
}
