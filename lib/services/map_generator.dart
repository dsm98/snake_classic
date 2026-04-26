import 'dart:math';
import 'dart:collection';
import '../core/models/position.dart';
import '../core/enums/biome_type.dart';
import '../core/constants/app_constants.dart';
import '../core/enums/theme_type.dart';
import '../core/models/campaign_level.dart';

class MapGenerator {
  final Random _rng = Random();

  static const Map<BiomeType, int> _biomeSeedWeights = {
    BiomeType.forest: 20,
    BiomeType.jungle: 11,
    BiomeType.desert: 12,
    BiomeType.savanna: 11,
    BiomeType.swamp: 9,
    BiomeType.coral: 7,
    BiomeType.cave: 9,
    BiomeType.ruins: 8,
    BiomeType.tundra: 6,
    BiomeType.frozenLake: 5,
    BiomeType.mushroom: 5,
    BiomeType.crystalCave: 2,
    BiomeType.lavaField: 1,
    BiomeType.ashlands: 2,
  };

  BiomeType _pickWeightedBiome() {
    final totalWeight = _biomeSeedWeights.values.fold<int>(0, (a, b) => a + b);
    int roll = _rng.nextInt(totalWeight);
    for (final entry in _biomeSeedWeights.entries) {
      roll -= entry.value;
      if (roll < 0) return entry.key;
    }
    return BiomeType.forest;
  }

  void generatePerimeterWalls(HashSet<Position> obstacleSet) {
    for (int x = 0; x < AppConstants.gridColumns; x++) {
      obstacleSet.add(Position(x, 0)); // Top wall
      obstacleSet.add(Position(x, AppConstants.gridRows - 1)); // Bottom wall
    }
    for (int y = 1; y < AppConstants.gridRows - 1; y++) {
      obstacleSet.add(Position(0, y)); // Left wall
      obstacleSet.add(Position(AppConstants.gridColumns - 1, y)); // Right wall
    }
  }

  void generateExploreMap({
    required HashSet<Position> obstacleSet,
    required Map<int, BiomeType> roomBiomes,
    required Set<Position> spikeTraps,
    required HashSet<Position> snakeSet,
  }) {
    const int cols = AppConstants.exploreGridColumns;
    const int rows = AppConstants.exploreGridRows;
    const int bs = 10;
    const int roomCols = cols ~/ bs;
    const int roomRows = rows ~/ bs;

    for (int x = 0; x < cols; x++) {
      for (int y = 0; y < rows; y++) {
        obstacleSet.add(Position(x, y));
      }
    }

    for (int rx = 0; rx < roomCols; rx++) {
      for (int ry = 0; ry < roomRows; ry++) {
        for (int dx = 2; dx <= 7; dx++) {
          for (int dy = 2; dy <= 7; dy++) {
            obstacleSet.remove(Position(rx * bs + dx, ry * bs + dy));
          }
        }
      }
    }

    final int spawnRx = AppConstants.exploreStartX ~/ bs;
    final int spawnRy = AppConstants.exploreStartY ~/ bs;

    final Set<int> inTree = {};
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
        _carveCorridorBetween(obstacleSet, edge[0], edge[1], nRx, nRy, bs);
        addNeighbors(nRx, nRy);
      }
    }

    for (int rx = 0; rx < roomCols; rx++) {
      for (int ry = 0; ry < roomRows; ry++) {
        if (rx + 1 < roomCols && _rng.nextDouble() < 0.55) {
          _carveCorridorBetween(obstacleSet, rx, ry, rx + 1, ry, bs);
        }
        if (ry + 1 < roomRows && _rng.nextDouble() < 0.55) {
          _carveCorridorBetween(obstacleSet, rx, ry, rx, ry + 1, bs);
        }
      }
    }

    // — Voronoi-style biome zone assignment —
    // Plant random seeds across the room grid; each room gets the nearest seed's biome.
    final numSeeds = 8 + _rng.nextInt(4); // 8-11 seeds for 8×11 room grid
    final List<(int, int, BiomeType)> seeds = [];
    for (int i = 0; i < numSeeds; i++) {
      seeds.add((
        _rng.nextInt(roomCols),
        _rng.nextInt(roomRows),
        _pickWeightedBiome(),
      ));
    }
    for (int rx = 0; rx < roomCols; rx++) {
      for (int ry = 0; ry < roomRows; ry++) {
        int bestDist = 999999;
        BiomeType bestBiome = BiomeType.forest;
        for (final seed in seeds) {
          final d = (rx - seed.$1).abs() + (ry - seed.$2).abs();
          if (d < bestDist) {
            bestDist = d;
            bestBiome = seed.$3;
          }
        }
        roomBiomes[rx * roomRows + ry] = bestBiome;
      }
    }

    // — Biome-specific interior decorations —
    // Safe corners: dx/dy ∈ {2,3} or {6,7} avoid the corridor path at 4-6.
    final int spawnRoomKey = spawnRx * roomRows + spawnRy;
    for (int rx = 0; rx < roomCols; rx++) {
      for (int ry = 0; ry < roomRows; ry++) {
        final key = rx * roomRows + ry;
        if (key == spawnRoomKey) continue; // keep spawn room clear
        final biome = roomBiomes[key]!;
        _addBiomeDecoration(obstacleSet, spikeTraps, rx, ry, biome, snakeSet);
      }
    }

    // — Spike traps (lava & swamp rooms already add extras above) —
    for (int rx = 0; rx < roomCols; rx++) {
      for (int ry = 0; ry < roomRows; ry++) {
        final key = rx * roomRows + ry;
        final biome = roomBiomes[key]!;
        final chance =
            (biome == BiomeType.lavaField || biome == BiomeType.ashlands)
                ? 0.35
                : 0.15;
        if (_rng.nextDouble() < chance) {
          final int sx = rx * bs + 3 + _rng.nextInt(3);
          final int sy = ry * bs + 3 + _rng.nextInt(3);
          final pos = Position(sx, sy);
          if (!snakeSet.contains(pos) && !obstacleSet.contains(pos)) {
            spikeTraps.add(pos);
          }
        }
      }
    }
  }

  /// Adds biome-themed obstacle decorations inside a room's safe corner zones.
  /// Corner zones (dx∈{2,3}∪{6,7}, dy∈{2,3}∪{6,7}) never overlap corridor paths.
  void _addBiomeDecoration(
    HashSet<Position> obstacleSet,
    Set<Position> spikeTraps,
    int rx,
    int ry,
    BiomeType biome,
    Set<Position> snakeSet,
  ) {
    const int bs = 10;
    final int bx = rx * bs;
    final int by = ry * bs;

    int sdx() =>
        _rng.nextBool() ? (2 + _rng.nextInt(2)) : (6 + _rng.nextInt(2));
    int sdy() =>
        _rng.nextBool() ? (2 + _rng.nextInt(2)) : (6 + _rng.nextInt(2));

    void add(int x, int y) {
      final p = Position(x, y);
      if (!snakeSet.contains(p)) obstacleSet.add(p);
    }

    switch (biome) {
      case BiomeType.forest:
        // 1-2 tree clusters (2×2)
        for (int t = 0; t < 1 + _rng.nextInt(2); t++) {
          final dx = sdx();
          final dy = sdy();
          add(bx + dx, by + dy);
          if (dx + 1 <= 7) add(bx + dx + 1, by + dy);
          add(bx + dx, by + dy);
          if (dy + 1 <= 7) add(bx + dx, by + dy + 1);
        }
        break;
      case BiomeType.jungle:
        // 3-4 scattered dense blocks
        for (int t = 0; t < 3 + _rng.nextInt(2); t++) {
          add(bx + sdx(), by + sdy());
        }
        break;
      case BiomeType.desert:
        // 1-2 sand ridges (horizontal 2-3 cells)
        for (int t = 0; t < 1 + _rng.nextInt(2); t++) {
          final dx = sdx();
          final dy = sdy();
          for (int d = 0; d < 2 + _rng.nextInt(2); d++) {
            if (dx + d <= 7) add(bx + dx + d, by + dy);
          }
        }
        break;
      case BiomeType.savanna:
        // 1-2 thin acacia trees (1×2 vertical)
        for (int t = 0; t < 1 + _rng.nextInt(2); t++) {
          final dx = sdx();
          final dy = sdy();
          add(bx + dx, by + dy);
          if (dy + 1 <= 7) add(bx + dx, by + dy + 1);
        }
        break;
      case BiomeType.swamp:
        // L-shaped mud bank in one corner
        final dx = _rng.nextBool() ? 2 : 6;
        final dy = _rng.nextBool() ? 2 : 6;
        add(bx + dx, by + dy);
        if (dx + 1 <= 7) add(bx + dx + 1, by + dy);
        if (dy + 1 <= 7) add(bx + dx, by + dy + 1);
        break;
      case BiomeType.cave:
        // 2-3 scattered rock boulders
        for (int t = 0; t < 2 + _rng.nextInt(2); t++) {
          final dx = sdx();
          final dy = sdy();
          add(bx + dx, by + dy);
          if (_rng.nextBool() && dx + 1 <= 7) add(bx + dx + 1, by + dy);
        }
        break;
      case BiomeType.crystalCave:
        // 1-2 crystal clusters (diagonal pair)
        for (int t = 0; t < 1 + _rng.nextInt(2); t++) {
          final dx = sdx();
          final dy = sdy();
          add(bx + dx, by + dy);
          if (dx + 1 <= 7 && dy + 1 <= 7) add(bx + dx + 1, by + dy + 1);
        }
        break;
      case BiomeType.ruins:
        // 1-2 crumbled wall segments (2-3 cells horizontal or vertical)
        for (int t = 0; t < 1 + _rng.nextInt(2); t++) {
          final dx = sdx();
          final dy = sdy();
          if (_rng.nextBool()) {
            for (int d = 0; d < 2 + _rng.nextInt(2); d++) {
              if (dx + d <= 7) add(bx + dx + d, by + dy);
            }
          } else {
            for (int d = 0; d < 2 + _rng.nextInt(2); d++) {
              if (dy + d <= 7) add(bx + dx, by + dy + d);
            }
          }
        }
        break;
      case BiomeType.tundra:
        // 1-2 ice block pairs (1×2 horizontal)
        for (int t = 0; t < 1 + _rng.nextInt(2); t++) {
          final dx = sdx();
          final dy = sdy();
          add(bx + dx, by + dy);
          if (dx + 1 <= 7) add(bx + dx + 1, by + dy);
        }
        break;
      case BiomeType.frozenLake:
        // Cracked ice lines
        for (int t = 0; t < 2 + _rng.nextInt(2); t++) {
          final dx = sdx();
          final dy = sdy();
          add(bx + dx, by + dy);
          if (_rng.nextBool() && dx + 1 <= 7) add(bx + dx + 1, by + dy);
          if (_rng.nextBool() && dy + 1 <= 7) add(bx + dx, by + dy + 1);
        }
        break;
      case BiomeType.lavaField:
        // 1-2 obsidian spires (1×2 vertical)
        for (int t = 0; t < 1 + _rng.nextInt(2); t++) {
          final dx = sdx();
          final dy = sdy();
          add(bx + dx, by + dy);
          if (dy + 1 <= 7) add(bx + dx, by + dy + 1);
        }
        break;
      case BiomeType.ashlands:
        // Jagged volcanic rubble
        for (int t = 0; t < 2 + _rng.nextInt(3); t++) {
          add(bx + sdx(), by + sdy());
        }
        break;
      case BiomeType.coral:
        // Plus/cross shape at inner corner
        final dx = _rng.nextBool() ? 3 : 6;
        final dy = _rng.nextBool() ? 3 : 6;
        add(bx + dx, by + dy);
        if (dx - 1 >= 2) add(bx + dx - 1, by + dy);
        if (dx + 1 <= 7) add(bx + dx + 1, by + dy);
        if (dy - 1 >= 2) add(bx + dx, by + dy - 1);
        if (dy + 1 <= 7) add(bx + dx, by + dy + 1);
        break;
      case BiomeType.mushroom:
        // T-shaped mushroom cap
        final dx = _rng.nextBool() ? 3 : 6;
        final dy = _rng.nextBool() ? 2 : 6;
        if (dy + 1 <= 7) add(bx + dx, by + dy + 1); // stem
        if (dx - 1 >= 2) add(bx + dx - 1, by + dy); // cap left
        add(bx + dx, by + dy); // cap centre
        if (dx + 1 <= 7) add(bx + dx + 1, by + dy); // cap right
        break;
    }
  }

  void _carveCorridorBetween(HashSet<Position> obstacleSet, int rx1, int ry1,
      int rx2, int ry2, int bs) {
    if (rx1 > rx2 || (rx1 == rx2 && ry1 > ry2)) {
      _carveCorridorBetween(obstacleSet, rx2, ry2, rx1, ry1, bs);
      return;
    }

    if (rx2 == rx1 + 1 && ry2 == ry1) {
      final int xStart = rx1 * bs + 8;
      final int xEnd = rx2 * bs + 1;
      final int cy = ry1 * bs + 5;
      for (int x = xStart; x <= xEnd; x++) {
        obstacleSet.remove(Position(x, cy - 1));
        obstacleSet.remove(Position(x, cy));
        obstacleSet.remove(Position(x, cy + 1));
      }
    } else if (ry2 == ry1 + 1 && rx2 == rx1) {
      final int yStart = ry1 * bs + 8;
      final int yEnd = ry2 * bs + 1;
      final int cx = rx1 * bs + 5;
      for (int y = yStart; y <= yEnd; y++) {
        obstacleSet.remove(Position(cx - 1, y));
        obstacleSet.remove(Position(cx, y));
        obstacleSet.remove(Position(cx + 1, y));
      }
    }
  }

  void generateMazeObstacles(HashSet<Position> obstacleSet,
      Difficulty difficulty, int startX, int startY) {
    int count = 0;
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
    _spawnRandomObstacles(obstacleSet, count, startX, startY,
        AppConstants.gridColumns, AppConstants.gridRows);
  }

  void generateCampaignObstacles(HashSet<Position> obstacleSet,
      CampaignLevel level, int startX, int startY) {
    if (level.obstacleDensity <= 0) return;
    int count = level.obstacleDensity * 2;
    _spawnRandomObstacles(obstacleSet, count, startX, startY,
        AppConstants.gridColumns, AppConstants.gridRows);
  }

  void _spawnRandomObstacles(HashSet<Position> obstacleSet, int count,
      int startX, int startY, int cols, int rows) {
    const clearZone = 4;
    int added = 0;
    while (added < count) {
      final pos = Position(_rng.nextInt(cols), _rng.nextInt(rows));
      if ((pos.x - startX).abs() > clearZone ||
          (pos.y - startY).abs() > clearZone) {
        if (!obstacleSet.contains(pos)) {
          obstacleSet.add(pos);
          added++;
        }
      }
    }
  }
}
