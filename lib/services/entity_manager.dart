import 'dart:math';
import 'package:flutter/material.dart';
import '../core/models/position.dart';
import '../core/models/food_model.dart';
import '../core/enums/biome_type.dart';
import '../core/enums/snake_skin.dart';
import '../core/enums/game_mode.dart';
import '../core/models/shadow_snake.dart';

class EntityManager {
  final Random _rng = Random();

  List<FoodType> getPreyTypesForBiome(BiomeType biome) {
    switch (biome) {
      case BiomeType.forest:
        return [FoodType.mouse, FoodType.rabbit];
      case BiomeType.jungle:
        return [FoodType.rabbit, FoodType.lizard, FoodType.butterfly];
      case BiomeType.desert:
        return [FoodType.lizard, FoodType.mouse];
      case BiomeType.savanna:
        return [FoodType.rabbit, FoodType.lizard];
      case BiomeType.swamp:
        return [FoodType.croc, FoodType.lizard];
      case BiomeType.coral:
        return [FoodType.butterfly, FoodType.lizard];
      case BiomeType.cave:
        return [FoodType.butterfly, FoodType.lizard];
      case BiomeType.crystalCave:
        return [FoodType.butterfly, FoodType.mouse];
      case BiomeType.ruins:
        return [FoodType.mouse, FoodType.butterfly, FoodType.lizard];
      case BiomeType.tundra:
      case BiomeType.frozenLake:
        return [FoodType.rabbit, FoodType.mouse];
      case BiomeType.lavaField:
      case BiomeType.ashlands:
        return [FoodType.lizard, FoodType.croc];
      case BiomeType.mushroom:
        return [FoodType.butterfly, FoodType.mouse, FoodType.rabbit];
    }
  }

  void moveBossFood({
    required FoodModel? food,
    required List<Position> snake,
    required Set<Position> snakeSet,
    required Set<Position> obstacleSet,
    required int gridCols,
    required int gridRows,
    required Function(FoodModel) onUpdate,
  }) {
    if (food == null) return;
    final head = snake.first;
    final bossPos = food.position;
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
      onUpdate(FoodModel(
          position: best, type: FoodType.boss, expiresAtMs: food.expiresAtMs));
    }
  }

  void movePrey({
    required List<FoodModel> preyList,
    required List<Position> snake,
    required Set<Position> snakeSet,
    required Set<Position> obstacleSet,
    required int gridCols,
    required int gridRows,
    required Map<int, BiomeType> roomBiomes,
    required int gameTimeMs,
    required int preyMagnetEndMs,
    required SnakeSkin equippedSkin,
    required Random rng,
  }) {
    final head = snake.first;
    for (int i = 0; i < preyList.length; i++) {
      final prey = preyList[i];
      if (prey.expiresAtMs != null &&
          prey.expiresAtMs! > 0 &&
          gameTimeMs > prey.expiresAtMs!) continue;

      if (gameTimeMs < preyMagnetEndMs) {
        _magnetPrey(
            i, preyList, head, snakeSet, obstacleSet, gridCols, gridRows);
        continue;
      }

      switch (prey.type) {
        case FoodType.mouse:
          _moveMouse(
              i, preyList, head, snakeSet, obstacleSet, gridCols, gridRows);
          break;
        case FoodType.rabbit:
          _moveRabbit(
              i, preyList, head, snakeSet, obstacleSet, gridCols, gridRows);
          break;
        case FoodType.lizard:
          _moveLizard(
              i, preyList, head, snakeSet, obstacleSet, gridCols, gridRows);
          break;
        case FoodType.croc:
          _moveCroc(
              i, preyList, head, snakeSet, obstacleSet, gridCols, gridRows);
          break;
        case FoodType.butterfly:
          _moveButterfly(
              i, preyList, head, snakeSet, obstacleSet, gridCols, gridRows);
          break;
        case FoodType.elite:
          _moveElite(
              i, preyList, head, snakeSet, obstacleSet, gridCols, gridRows);
          break;
        case FoodType.biomeEvent:
        case FoodType.fruit:
        case FoodType.portal:
        case FoodType.shrine:
        case FoodType.merchant:
        case FoodType.standard:
        case FoodType.golden:
        case FoodType.poison:
        case FoodType.boss:
          break;
      }
    }
  }

  void _moveMouse(
      int idx,
      List<FoodModel> preyList,
      Position head,
      Set<Position> snakeSet,
      Set<Position> obstacleSet,
      int gridCols,
      int gridRows) {
    final prey = preyList[idx];
    final dist =
        (prey.position.x - head.x).abs() + (prey.position.y - head.y).abs();
    if (dist > 5) return;
    _preySingleStep(
        idx, preyList, head, snakeSet, obstacleSet, gridCols, gridRows);
  }

  void _moveRabbit(
      int idx,
      List<FoodModel> preyList,
      Position head,
      Set<Position> snakeSet,
      Set<Position> obstacleSet,
      int gridCols,
      int gridRows) {
    final prey = preyList[idx];
    final dist =
        (prey.position.x - head.x).abs() + (prey.position.y - head.y).abs();
    if (dist > 6) return;
    if (prey.dashChargesLeft > 0) {
      _rabbitDash(
          idx, preyList, head, snakeSet, obstacleSet, gridCols, gridRows);
    } else {
      _preySingleStep(
          idx, preyList, head, snakeSet, obstacleSet, gridCols, gridRows);
    }
  }

  void _moveLizard(
      int idx,
      List<FoodModel> preyList,
      Position head,
      Set<Position> snakeSet,
      Set<Position> obstacleSet,
      int gridCols,
      int gridRows) {
    if (_rng.nextDouble() < 0.7) return;
    _preySingleStep(
        idx, preyList, head, snakeSet, obstacleSet, gridCols, gridRows);
  }

  void _moveCroc(
      int idx,
      List<FoodModel> preyList,
      Position head,
      Set<Position> snakeSet,
      Set<Position> obstacleSet,
      int gridCols,
      int gridRows) {
    final prey = preyList[idx];
    final dist =
        (prey.position.x - head.x).abs() + (prey.position.y - head.y).abs();
    if (dist > 4) return;
    _preySingleStep(
        idx, preyList, head, snakeSet, obstacleSet, gridCols, gridRows);
  }

  void _moveElite(
      int idx,
      List<FoodModel> preyList,
      Position head,
      Set<Position> snakeSet,
      Set<Position> obstacleSet,
      int gridCols,
      int gridRows) {
    final prey = preyList[idx];
    final dist =
        (prey.position.x - head.x).abs() + (prey.position.y - head.y).abs();
    if (dist > 10) return;

    _preySingleStep(
        idx, preyList, head, snakeSet, obstacleSet, gridCols, gridRows);
    if (_rng.nextDouble() < 0.45) {
      _preySingleStep(
          idx, preyList, head, snakeSet, obstacleSet, gridCols, gridRows);
    }
  }

  void _moveButterfly(
      int idx,
      List<FoodModel> preyList,
      Position head,
      Set<Position> snakeSet,
      Set<Position> obstacleSet,
      int gridCols,
      int gridRows) {
    if (_rng.nextDouble() < 0.4) {
      final pos = preyList[idx].position;
      final next =
          Position(pos.x + _rng.nextInt(3) - 1, pos.y + _rng.nextInt(3) - 1);
      if (next.x >= 0 &&
          next.x < gridCols &&
          next.y >= 0 &&
          next.y < gridRows &&
          !snakeSet.contains(next) &&
          !obstacleSet.contains(next)) {
        preyList[idx] = preyList[idx].copyWith(position: next);
      }
    }
  }

  void _magnetPrey(
      int idx,
      List<FoodModel> preyList,
      Position head,
      Set<Position> snakeSet,
      Set<Position> obstacleSet,
      int gridCols,
      int gridRows) {
    final prey = preyList[idx];
    final pos = prey.position;
    final dx = head.x - pos.x;
    final dy = head.y - pos.y;
    final next = Position(
      pos.x + (dx != 0 ? dx.sign : 0),
      pos.y + (dy != 0 ? dy.sign : 0),
    );
    if (!snakeSet.contains(next) && !obstacleSet.contains(next)) {
      preyList[idx] = prey.copyWith(position: next);
    }
  }

  void moveShadow({
    required ShadowSnake? activeShadow,
    required GameMode gameMode,
    required List<Position> snake,
    required Set<Position> snakeSet,
    required FoodModel? food,
    required int gridCols,
    required int gridRows,
    required bool isGhostMode,
    required VoidCallback onKill,
    required VoidCallback onFoodStolen,
  }) {
    if (activeShadow == null) return;
    activeShadow.moveTicks++;
    if (activeShadow.moveTicks % 3 == 0) return; // 33% slower

    final head = activeShadow.segments.first;
    final target = snake.first;

    // Shadow AI: Hunt snake or food
    Position goal = target;
    if (food != null && _rng.nextDouble() < 0.3) {
      goal = food.position;
    }

    Position next = head;
    final dx = goal.x - head.x;
    final dy = goal.y - head.y;

    if (dx.abs() > dy.abs()) {
      next = Position((head.x + dx.sign + gridCols) % gridCols, head.y);
    } else if (dy != 0) {
      next = Position(head.x, (head.y + dy.sign + gridRows) % gridRows);
    }

    // Move body
    final newSegments = [next, ...activeShadow.segments];
    if (newSegments.length > 5) newSegments.removeLast();

    activeShadow.segments.clear();
    activeShadow.segments.addAll(newSegments);

    // Collision checks
    if (!isGhostMode && snakeSet.contains(next)) {
      onKill();
    }
    if (food != null && next == food.position) {
      onFoodStolen();
    }
  }

  void _preySingleStep(
      int preyIdx,
      List<FoodModel> preyList,
      Position head,
      Set<Position> snakeSet,
      Set<Position> obstacleSet,
      int gridCols,
      int gridRows) {
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

  void _rabbitDash(
      int preyIdx,
      List<FoodModel> preyList,
      Position head,
      Set<Position> snakeSet,
      Set<Position> obstacleSet,
      int gridCols,
      int gridRows) {
    final prey = preyList[preyIdx];
    final pos = prey.position;
    final dx = pos.x - head.x;
    final dy = pos.y - head.y;
    Position? dashPos;
    if (dx.abs() >= dy.abs()) {
      dashPos = _findDashLanding(pos, dx >= 0 ? 1 : -1, 0, 3, obstacleSet,
          snakeSet, gridCols, gridRows);
    } else {
      dashPos = _findDashLanding(pos, 0, dy >= 0 ? 1 : -1, 3, obstacleSet,
          snakeSet, gridCols, gridRows);
    }
    if (dashPos != null) {
      preyList[preyIdx] = prey.copyWith(
          position: dashPos, dashChargesLeft: prey.dashChargesLeft - 1);
    } else {
      _preySingleStep(
          preyIdx, preyList, head, snakeSet, obstacleSet, gridCols, gridRows);
    }
  }

  Position? _findDashLanding(
      Position start,
      int xDir,
      int yDir,
      int steps,
      Set<Position> obstacleSet,
      Set<Position> snakeSet,
      int gridCols,
      int gridRows) {
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
}
