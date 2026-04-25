import 'dart:math';
import 'dart:collection';
import '../core/models/position.dart';
import '../core/enums/biome_type.dart';
import '../core/constants/app_constants.dart';
import '../core/enums/theme_type.dart';
import '../core/models/campaign_level.dart';

class MapGenerator {
  final Random _rng = Random();

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

    final biomeValues = BiomeType.values;
    for (int rx = 0; rx < roomCols; rx++) {
      for (int ry = 0; ry < roomRows; ry++) {
        roomBiomes[rx * roomRows + ry] =
            biomeValues[_rng.nextInt(biomeValues.length)];
      }
    }

    for (int rx = 0; rx < roomCols; rx++) {
      for (int ry = 0; ry < roomRows; ry++) {
        if (_rng.nextDouble() < 0.20) {
          final int sx = rx * bs + 3 + _rng.nextInt(3);
          final int sy = ry * bs + 3 + _rng.nextInt(3);
          final pos = Position(sx, sy);
          if (!snakeSet.contains(pos)) {
            spikeTraps.add(pos);
            obstacleSet.remove(pos);
          }
        }
      }
    }
  }

  void _carveCorridorBetween(HashSet<Position> obstacleSet, int rx1, int ry1, int rx2, int ry2, int bs) {
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

  void generateMazeObstacles(HashSet<Position> obstacleSet, Difficulty difficulty, int startX, int startY) {
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
    _spawnRandomObstacles(obstacleSet, count, startX, startY, AppConstants.gridColumns, AppConstants.gridRows);
  }

  void generateCampaignObstacles(HashSet<Position> obstacleSet, CampaignLevel level, int startX, int startY) {
    if (level.obstacleDensity <= 0) return;
    int count = level.obstacleDensity * 2;
    _spawnRandomObstacles(obstacleSet, count, startX, startY, AppConstants.gridColumns, AppConstants.gridRows);
  }

  void _spawnRandomObstacles(HashSet<Position> obstacleSet, int count, int startX, int startY, int cols, int rows) {
    const clearZone = 4;
    int added = 0;
    while (added < count) {
      final pos = Position(_rng.nextInt(cols), _rng.nextInt(rows));
      if ((pos.x - startX).abs() > clearZone || (pos.y - startY).abs() > clearZone) {
        if (!obstacleSet.contains(pos)) {
          obstacleSet.add(pos);
          added++;
        }
      }
    }
  }
}
