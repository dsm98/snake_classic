import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/direction.dart';
import '../../core/enums/game_mode.dart';
import '../../core/enums/biome_type.dart';

import '../../core/enums/power_up_type.dart';
import '../../core/enums/theme_type.dart';
import '../../core/models/position.dart';
import '../../core/models/food_model.dart';
import '../../core/enums/snake_skin.dart';

import '../../services/game_engine.dart';
import '../../services/tail_trail_service.dart';
import '../../services/ghost_racing_service.dart';

class GameBoard extends StatefulWidget {
  final GameEngine engine;
  final ThemeType themeType;
  final SnakeSkin skin;

  const GameBoard(
      {super.key,
      required this.engine,
      required this.themeType,
      this.skin = SnakeSkin.classic});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  AppThemeColors get colors {
    switch (widget.themeType) {
      case ThemeType.retro:
        return AppThemeColors.retro;
      case ThemeType.neon:
        return AppThemeColors.neon;
      case ThemeType.nature:
        return AppThemeColors.nature;
      case ThemeType.arcade:
        return AppThemeColors.arcade;
      case ThemeType.cyber:
        return AppThemeColors.cyber;
      case ThemeType.volcano:
        return AppThemeColors.volcano;
      case ThemeType.ice:
        return AppThemeColors.ice;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return ListenableBuilder(
          listenable: widget.engine,
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isExplore = widget.engine.gameMode == GameMode.explore;
                final int viewCols = isExplore
                    ? AppConstants.exploreViewportCols
                    : AppConstants.gridColumns;
                final int viewRows = isExplore
                    ? AppConstants.exploreViewportRows
                    : AppConstants.gridRows;
                final cellW = constraints.maxWidth / viewCols;
                final cellH = constraints.maxHeight / viewRows;
                final cellSize = min(cellW, cellH);

                return RepaintBoundary(
                  child: CustomPaint(
                    size: Size(
                      cellSize * viewCols,
                      cellSize * viewRows,
                    ),
                    painter: _SnakePainter(
                      engine: widget.engine,
                      colors: colors,
                      themeType: widget.themeType,
                      cellSize: cellSize,
                      pulse: _pulseController.value,
                      skin: widget.skin,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _SnakePainter extends CustomPainter {
  final GameEngine engine;
  final AppThemeColors colors;
  final ThemeType themeType;
  final double cellSize;
  final double pulse;
  final SnakeSkin skin;

  _SnakePainter({
    required this.engine,
    required this.colors,
    required this.themeType,
    required this.cellSize,
    required this.pulse,
    required this.skin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (cellSize == 0) return;

    // Explore mode: translate canvas so the viewport follows the snake head.
    // Use movementProgress to smoothly interpolate camera between ticks.
    if (engine.gameMode == GameMode.explore) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
      final double progress = engine.movementProgress;
      final double smoothCamX = ui.lerpDouble(
          engine.prevCameraX.toDouble(), engine.cameraX.toDouble(), progress)!;
      final double smoothCamY = ui.lerpDouble(
          engine.prevCameraY.toDouble(), engine.cameraY.toDouble(), progress)!;
      canvas.translate(-smoothCamX * cellSize, -smoothCamY * cellSize);
    }

    if (engine.gameMode == GameMode.endless) {
      _drawPortalEdges(canvas, size);
    }

    _drawBackground(canvas, size);
    _drawBiomeDecals(canvas);
    _drawBiomeLandmarks(canvas);
    _drawGrid(canvas, size);
    _drawObstacles(canvas);
    _drawBiomeAmbient(canvas);
    _drawPowerUps(canvas);
    _drawTrail(canvas);
    _drawGhost(canvas);
    _drawSnake(canvas);
    _drawFood(canvas);
    _drawPrey(canvas);
    _drawEffects(canvas);
    _drawShadow(canvas);
    if (themeType == ThemeType.retro) _drawRetroGhosting(canvas);
    _drawSpikeTraps(canvas);

    if (engine.gameMode == GameMode.explore) {
      // Restore before drawing viewport-relative overlays
      canvas.restore();
      _drawEvents(canvas, size);
      _drawFogOfWar(canvas, size);
    } else {
      _drawEvents(canvas, size);
    }
  }

  void _drawFogOfWar(Canvas canvas, Size size) {
    final biome = engine.currentBiome;
    final isCursed = engine.hasWraithsEye;

    // Only draw fog in dark biomes, or when cursed by Wraith's Eye
    if (!isCursed &&
        biome != BiomeType.cave &&
        biome != BiomeType.ruins &&
        biome != BiomeType.crystalCave) {
      return;
    }
    if (engine.snake.isEmpty) return;

    final head = engine.snake.first;
    final double progress = engine.movementProgress;
    final double smoothCamX = ui.lerpDouble(
        engine.prevCameraX.toDouble(), engine.cameraX.toDouble(), progress)!;
    final double smoothCamY = ui.lerpDouble(
        engine.prevCameraY.toDouble(), engine.cameraY.toDouble(), progress)!;

    final double headScreenX = (head.x - smoothCamX) * cellSize + cellSize / 2;
    final double headScreenY = (head.y - smoothCamY) * cellSize + cellSize / 2;
    final center = Offset(headScreenX, headScreenY);

    // Wraith's eye further restricts vision!
    final double visionRadius = isCursed ? cellSize * 4.0 : cellSize * 5.5;
    final opacity =
        (biome == BiomeType.cave || biome == BiomeType.crystalCave || isCursed)
            ? 0.95
            : 0.85;

    final gradient = ui.Gradient.radial(center, visionRadius, [
      Colors.transparent,
      Colors.transparent,
      Colors.black.withValues(alpha: opacity),
      Colors.black.withValues(alpha: opacity)
    ], [
      0.0,
      0.45,
      1.0,
      1.0
    ]);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = gradient,
    );
  }

  void _drawPortalEdges(Canvas canvas, Size size) {
    final borderRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(
      borderRect,
      Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8),
    );
  }

  void _drawBackground(Canvas canvas, Size size) {
    final double bgW = engine.gameMode == GameMode.explore
        ? engine.gridCols * cellSize
        : size.width;
    final double bgH = engine.gameMode == GameMode.explore
        ? engine.gridRows * cellSize
        : size.height;

    if (engine.gameMode == GameMode.explore && engine.roomBiomes.isNotEmpty) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, bgW, bgH),
        Paint()..color = const Color(0xFF050508),
      );
      const int bs = 10;
      const int roomRowCount = 11;
      for (final entry in engine.roomBiomes.entries) {
        final rx = entry.key ~/ roomRowCount;
        final ry = entry.key % roomRowCount;
        final rect = Rect.fromLTWH(
          rx * bs * cellSize,
          ry * bs * cellSize,
          bs * cellSize,
          bs * cellSize,
        );
        canvas.drawRect(rect, Paint()..color = _biomeBgColor(entry.value));
      }
      // Draw transition blends on top of solid floor tiles
      _drawBiomeTransitions(canvas);
      return;
    }

    canvas.drawRect(
      Rect.fromLTWH(0, 0, bgW, bgH),
      Paint()..color = colors.background,
    );

    if (themeType != ThemeType.retro) {
      final center = Offset(size.width / 2, size.height / 2);
      final maxRadius = size.longestSide * 0.75;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..shader = ui.Gradient.radial(center, maxRadius, [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.25),
          ], [
            0.4,
            1.0
          ]),
      );
    }

    if (themeType == ThemeType.retro) {
      final gridPaint = Paint()
        ..color = colors.gridLine.withValues(alpha: 0.08)
        ..strokeWidth = 1.0;
      final subSize = cellSize / 4;
      for (double x = 0; x < size.width; x += subSize) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
      for (double y = 0; y < size.height; y += subSize) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }
  }

  void _drawObstacles(Canvas canvas) {
    for (final obs in engine.obstacleSet) {
      if (engine.gameMode == GameMode.explore) {
        _drawExploreObstacle(canvas, obs);
        continue;
      }
      final rect = _cellRect(obs);
      switch (themeType) {
        case ThemeType.retro:
          final paint = Paint()..color = colors.snakeHead;
          canvas.drawRect(rect.deflate(1.0), paint);
          final xPaint = Paint()
            ..color = colors.background
            ..strokeWidth = 1.0;
          canvas.drawLine(rect.topLeft + const Offset(4, 4),
              rect.bottomRight - const Offset(4, 4), xPaint);
          canvas.drawLine(rect.topRight + const Offset(-4, 4),
              rect.bottomLeft - const Offset(-4, -4), xPaint);
          break;
        case ThemeType.neon:
          const hazardColor = Color(0xFFFF3300);
          canvas.drawRect(
            rect.deflate(2.0),
            Paint()
              ..color = hazardColor.withValues(alpha: 0.3)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
          );
          canvas.drawRect(
            rect.deflate(2.0),
            Paint()
              ..color = hazardColor.withValues(alpha: 0.8)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
          canvas.drawLine(
              rect.topLeft + const Offset(4, 4),
              rect.bottomRight - const Offset(4, 4),
              Paint()
                ..color = hazardColor
                ..strokeWidth = 1);
          canvas.drawLine(
              rect.topRight + const Offset(-4, 4),
              rect.bottomLeft - const Offset(-4, -4),
              Paint()
                ..color = hazardColor
                ..strokeWidth = 1);
          break;
        case ThemeType.nature:
          final rrect = RRect.fromRectAndRadius(
              rect.deflate(0.5), const Radius.circular(4));
          canvas.drawRRect(rrect, Paint()..color = const Color(0xFF1B2631));
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  rect.deflate(1.5), const Radius.circular(3)),
              Paint()..color = const Color(0xFF2C3E50));
          break;
        case ThemeType.arcade:
          canvas.drawRect(
              rect.deflate(1.0),
              Paint()
                ..color = const Color(0xFFFF0000)
                ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3));
          canvas.drawRect(
              rect.deflate(3.0), Paint()..color = const Color(0xFF990000));
          break;
        case ThemeType.cyber:
          canvas.drawRect(
              rect.deflate(2.0), Paint()..color = const Color(0xFF003B00));
          canvas.drawRect(
              rect.deflate(4.0),
              Paint()
                ..color = const Color(0xFF00FF41)
                ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2));
          break;
        case ThemeType.volcano:
          canvas.drawRect(
              rect.deflate(1.0), Paint()..color = const Color(0xFF1A0505));
          canvas.drawRect(
              rect.deflate(4.0),
              Paint()
                ..color = const Color(0xFFFF4500)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
          break;
        case ThemeType.ice:
          canvas.drawRect(
              rect.deflate(1.0), Paint()..color = const Color(0xFF0B1829));
          canvas.drawRect(
              rect.deflate(4.0),
              Paint()
                ..color = const Color(0xFF7FEFFF)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
          break;
      }
    }
  }

  void _drawBiomeAmbient(Canvas canvas) {
    if (engine.gameMode != GameMode.explore || engine.snake.isEmpty) return;
    final biome = engine.currentBiome;
    if (biome == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final int particleCount;
    final Color color;
    final double radiusBase;

    switch (biome) {
      case BiomeType.desert:
      case BiomeType.savanna:
        particleCount = 14;
        color = const Color(0xFFE0C27A).withValues(alpha: 0.12);
        radiusBase = cellSize * 0.09;
        break;
      case BiomeType.tundra:
      case BiomeType.frozenLake:
        particleCount = 18;
        color = const Color(0xFFDDF3FF).withValues(alpha: 0.16);
        radiusBase = cellSize * 0.08;
        break;
      case BiomeType.lavaField:
      case BiomeType.ashlands:
        particleCount = 14;
        color = const Color(0xFFFF7A45).withValues(alpha: 0.16);
        radiusBase = cellSize * 0.11;
        break;
      case BiomeType.mushroom:
        particleCount = 12;
        color = const Color(0xFFE2A6FF).withValues(alpha: 0.13);
        radiusBase = cellSize * 0.10;
        break;
      case BiomeType.swamp:
        particleCount = 12;
        color = const Color(0xFFA4D1A0).withValues(alpha: 0.10);
        radiusBase = cellSize * 0.09;
        break;
      case BiomeType.coral:
        particleCount = 10;
        color = const Color(0xFF9DE7FF).withValues(alpha: 0.10);
        radiusBase = cellSize * 0.09;
        break;
      case BiomeType.crystalCave:
        particleCount = 12;
        color = const Color(0xFFCFC8FF).withValues(alpha: 0.20);
        radiusBase = cellSize * 0.11;
        break;
      case BiomeType.cave:
      case BiomeType.ruins:
        particleCount = 8;
        color = Colors.white.withValues(alpha: 0.06);
        radiusBase = cellSize * 0.08;
        break;
      case BiomeType.forest:
      case BiomeType.jungle:
        particleCount = 10;
        color = const Color(0xFFBDE7A8).withValues(alpha: 0.09);
        radiusBase = cellSize * 0.09;
        break;
    }

    double fract(double v) => v - v.floorToDouble();
    final camX = engine.cameraX.toDouble();
    final camY = engine.cameraY.toDouble();
    final viewW = AppConstants.exploreViewportCols.toDouble();
    final viewH = AppConstants.exploreViewportRows.toDouble();

    // Cinematic boost for rare biomes only.
    if (biome == BiomeType.crystalCave ||
        biome == BiomeType.lavaField ||
        biome == BiomeType.ashlands) {
      final center = Offset(viewW * cellSize * 0.5, viewH * cellSize * 0.5);
      final rareTint = biome == BiomeType.crystalCave
          ? const Color(0xFF8F82FF).withValues(alpha: 0.10)
          : const Color(0xFFFF5A36).withValues(alpha: 0.10);
      canvas.drawRect(
        Rect.fromLTWH(
          camX * cellSize,
          camY * cellSize,
          viewW * cellSize,
          viewH * cellSize,
        ),
        Paint()
          ..shader = ui.Gradient.radial(
            center,
            viewW * cellSize * 0.9,
            [Colors.transparent, rareTint],
            [0.4, 1.0],
          ),
      );
    }

    for (int i = 0; i < particleCount; i++) {
      final t = now * 0.00035 + i * 13.13;
      final nx = fract(sin(i * 97.31 + t * 1.7) * 43758.5453);
      final ny = fract(sin(i * 41.77 + t * 1.2) * 15731.7431);
      final wobble = sin(t + i) * 0.35;
      final x = (camX + nx * viewW + wobble) * cellSize;
      final y = (camY + ny * viewH + sin(t * 1.4 + i * 0.5) * 0.2) * cellSize;
      final r = radiusBase * (0.7 + fract(sin(i * 17.0 + t) * 991.0));

      canvas.drawCircle(Offset(x, y), r, Paint()..color = color);

      if (biome == BiomeType.lavaField || biome == BiomeType.ashlands) {
        // Heat shimmer streaks
        final shimmer = Paint()
          ..color = const Color(0xFFFFB199).withValues(alpha: 0.05)
          ..strokeWidth = 1.0;
        canvas.drawLine(
          Offset(x - cellSize * 0.35, y),
          Offset(x + cellSize * 0.35, y),
          shimmer,
        );
      } else if (biome == BiomeType.crystalCave && (i % 3 == 0)) {
        final sparkle = Paint()
          ..color = const Color(0xFFE6E1FF).withValues(alpha: 0.22)
          ..strokeWidth = 1.0;
        canvas.drawLine(
          Offset(x - r * 0.9, y),
          Offset(x + r * 0.9, y),
          sparkle,
        );
        canvas.drawLine(
          Offset(x, y - r * 0.9),
          Offset(x, y + r * 0.9),
          sparkle,
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Biome transition gradient edges between adjacent rooms.
  // ---------------------------------------------------------------------------
  void _drawBiomeTransitions(Canvas canvas) {
    if (engine.roomBiomes.isEmpty) return;
    const int bs = 10;
    const int roomRowCount = 11;
    const double blendCells = 2.5;
    final double blendW = blendCells * cellSize;

    for (final entry in engine.roomBiomes.entries) {
      final rx = entry.key ~/ roomRowCount;
      final ry = entry.key % roomRowCount;
      final biomeA = entry.value;

      // Right neighbour
      final rightKey = (rx + 1) * roomRowCount + ry;
      final biomeB = engine.roomBiomes[rightKey];
      if (biomeB != null && biomeA != biomeB) {
        final x = (rx + 1) * bs * cellSize;
        final y = ry * bs * cellSize;
        canvas.drawRect(
          Rect.fromLTWH(x - blendW / 2, y, blendW, bs * cellSize),
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(x - blendW / 2, 0),
              Offset(x + blendW / 2, 0),
              [_biomeBgColor(biomeA), _biomeBgColor(biomeB)],
            ),
        );
      }

      // Bottom neighbour
      final bottomKey = rx * roomRowCount + ry + 1;
      final biomeC = engine.roomBiomes[bottomKey];
      if (biomeC != null && biomeA != biomeC) {
        final x = rx * bs * cellSize;
        final y = (ry + 1) * bs * cellSize;
        canvas.drawRect(
          Rect.fromLTWH(x, y - blendW / 2, bs * cellSize, blendW),
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(0, y - blendW / 2),
              Offset(0, y + blendW / 2),
              [_biomeBgColor(biomeA), _biomeBgColor(biomeC)],
            ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Biome ground decals — subtle static floor markings per room.
  // ---------------------------------------------------------------------------
  void _drawBiomeDecals(Canvas canvas) {
    if (engine.gameMode != GameMode.explore || engine.roomBiomes.isEmpty)
      return;
    const int bs = 10;
    const int roomRowCount = 11;

    for (final entry in engine.roomBiomes.entries) {
      final rx = entry.key ~/ roomRowCount;
      final ry = entry.key % roomRowCount;
      final biome = entry.value;
      final rng = Random(entry.key * 2654435761 + biome.index);
      final decalCount = 5 + rng.nextInt(5);

      for (int d = 0; d < decalCount; d++) {
        // Scatter within walkable interior (cells 2–7 of each 10-cell room)
        final localX = 2.0 + rng.nextDouble() * 5.5;
        final localY = 2.0 + rng.nextDouble() * 5.5;
        final cx = (rx * bs + localX) * cellSize;
        final cy = (ry * bs + localY) * cellSize;
        _drawDecalAt(canvas, biome, cx, cy, rng);
      }
    }
  }

  void _drawDecalAt(
      Canvas canvas, BiomeType biome, double cx, double cy, Random rng) {
    switch (biome) {
      case BiomeType.forest:
      case BiomeType.jungle:
        final angle = rng.nextDouble() * pi;
        final leafW = cellSize * (0.20 + rng.nextDouble() * 0.15);
        canvas.save();
        canvas.translate(cx, cy);
        canvas.rotate(angle);
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset.zero, width: leafW, height: cellSize * 0.09),
          Paint()..color = const Color(0xFF5A8A3C).withValues(alpha: 0.32),
        );
        canvas.restore();
        break;
      case BiomeType.desert:
      case BiomeType.savanna:
        canvas.drawCircle(
          Offset(cx, cy),
          cellSize * (0.05 + rng.nextDouble() * 0.06),
          Paint()..color = const Color(0xFFB89B6A).withValues(alpha: 0.42),
        );
        break;
      case BiomeType.cave:
      case BiomeType.ruins:
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(cx, cy),
            width: cellSize * (0.14 + rng.nextDouble() * 0.10),
            height: cellSize * 0.07,
          ),
          Paint()..color = const Color(0xFF8A8570).withValues(alpha: 0.38),
        );
        break;
      case BiomeType.swamp:
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx, cy),
            width: cellSize * (0.28 + rng.nextDouble() * 0.20),
            height: cellSize * (0.11 + rng.nextDouble() * 0.07),
          ),
          Paint()..color = const Color(0xFF3A5E38).withValues(alpha: 0.28),
        );
        break;
      case BiomeType.tundra:
      case BiomeType.frozenLake:
        canvas.drawCircle(
          Offset(cx, cy),
          cellSize * (0.05 + rng.nextDouble() * 0.05),
          Paint()..color = const Color(0xFFCCECFF).withValues(alpha: 0.38),
        );
        break;
      case BiomeType.lavaField:
      case BiomeType.ashlands:
        final len = cellSize * (0.15 + rng.nextDouble() * 0.14);
        final angle = rng.nextDouble() * pi;
        canvas.drawLine(
          Offset(cx - cos(angle) * len, cy - sin(angle) * len),
          Offset(cx + cos(angle) * len, cy + sin(angle) * len),
          Paint()
            ..color = const Color(0xFF6B1A0A).withValues(alpha: 0.48)
            ..strokeWidth = 0.8,
        );
        break;
      case BiomeType.crystalCave:
        canvas.drawCircle(
          Offset(cx, cy),
          cellSize * (0.04 + rng.nextDouble() * 0.04),
          Paint()..color = const Color(0xFF9F8FFF).withValues(alpha: 0.42),
        );
        break;
      case BiomeType.mushroom:
        canvas.drawCircle(
          Offset(cx, cy),
          cellSize * (0.04 + rng.nextDouble() * 0.04),
          Paint()..color = const Color(0xFFCC88FF).withValues(alpha: 0.32),
        );
        break;
      case BiomeType.coral:
        canvas.drawCircle(
          Offset(cx, cy),
          cellSize * (0.04 + rng.nextDouble() * 0.05),
          Paint()
            ..color = const Color(0xFF7ECCE0).withValues(alpha: 0.28)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.7,
        );
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Biome landmark props — one distinctive prop per room (25% chance).
  // ---------------------------------------------------------------------------
  void _drawBiomeLandmarks(Canvas canvas) {
    if (engine.gameMode != GameMode.explore || engine.roomBiomes.isEmpty)
      return;
    const int bs = 10;
    const int roomRowCount = 11;

    for (final entry in engine.roomBiomes.entries) {
      final rx = entry.key ~/ roomRowCount;
      final ry = entry.key % roomRowCount;
      final biome = entry.value;
      final rng = Random(entry.key * 6364136223 + biome.index * 31337);
      if (rng.nextDouble() > 0.25) continue;

      final lx = (rx * bs + 4.5 + (rng.nextDouble() - 0.5) * 2.0) * cellSize;
      final ly = (ry * bs + 4.5 + (rng.nextDouble() - 0.5) * 2.0) * cellSize;
      _drawLandmarkAt(canvas, biome, lx, ly);
    }
  }

  void _drawLandmarkAt(Canvas canvas, BiomeType biome, double cx, double cy) {
    switch (biome) {
      case BiomeType.forest:
      case BiomeType.jungle:
        // Large canopy tree
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset(cx, cy + cellSize * 0.6),
              width: cellSize * 0.44,
              height: cellSize * 1.2),
          Paint()..color = const Color(0xFF4A2E12),
        );
        canvas.drawCircle(
          Offset(cx, cy - cellSize * 0.2),
          cellSize * 0.74,
          Paint()
            ..color = const Color(0xFF2A5E2A).withValues(alpha: 0.80)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
        canvas.drawCircle(
          Offset(cx, cy - cellSize * 0.2),
          cellSize * 0.62,
          Paint()..color = const Color(0xFF3D8A3D).withValues(alpha: 0.75),
        );
        break;
      case BiomeType.cave:
        // Stalactite cluster
        for (int i = -1; i <= 1; i++) {
          final sx = cx + i * cellSize * 0.55;
          final height = cellSize * (i == 0 ? 1.3 : 0.95);
          final path = Path()
            ..moveTo(sx - cellSize * 0.20, cy - cellSize * 0.55)
            ..lineTo(sx + cellSize * 0.20, cy - cellSize * 0.55)
            ..lineTo(sx, cy - cellSize * 0.55 + height)
            ..close();
          canvas.drawPath(path,
              Paint()..color = const Color(0xFF555565).withValues(alpha: 0.72));
        }
        break;
      case BiomeType.ruins:
        // Broken arch
        final archPaint = Paint()
          ..color = const Color(0xFF7A7060).withValues(alpha: 0.78);
        canvas.drawRect(
            Rect.fromLTWH(cx - cellSize * 0.90, cy - cellSize * 0.80,
                cellSize * 0.30, cellSize * 1.20),
            archPaint);
        canvas.drawRect(
            Rect.fromLTWH(cx + cellSize * 0.60, cy - cellSize * 0.80,
                cellSize * 0.30, cellSize * 1.20),
            archPaint);
        canvas.drawRect(
            Rect.fromLTWH(cx - cellSize * 0.90, cy - cellSize * 0.80,
                cellSize * 0.95, cellSize * 0.22),
            archPaint);
        break;
      case BiomeType.desert:
      case BiomeType.savanna:
        // Cactus
        final cPaint = Paint()..color = const Color(0xFF4A7A30);
        canvas.drawRect(
            Rect.fromCenter(
                center: Offset(cx, cy),
                width: cellSize * 0.22,
                height: cellSize * 1.20),
            cPaint);
        canvas.drawRect(
            Rect.fromLTWH(cx - cellSize * 0.55, cy - cellSize * 0.28,
                cellSize * 0.55, cellSize * 0.18),
            cPaint);
        canvas.drawRect(
            Rect.fromLTWH(
                cx, cy - cellSize * 0.08, cellSize * 0.55, cellSize * 0.18),
            cPaint);
        break;
      case BiomeType.crystalCave:
        // Crystal pillar
        final pillar = Path()
          ..moveTo(cx, cy - cellSize * 1.1)
          ..lineTo(cx + cellSize * 0.34, cy - cellSize * 0.2)
          ..lineTo(cx + cellSize * 0.27, cy + cellSize * 0.60)
          ..lineTo(cx - cellSize * 0.27, cy + cellSize * 0.60)
          ..lineTo(cx - cellSize * 0.34, cy - cellSize * 0.2)
          ..close();
        canvas.drawPath(pillar,
            Paint()..color = const Color(0xFF7A6ECC).withValues(alpha: 0.78));
        canvas.drawPath(
          pillar,
          Paint()
            ..color = const Color(0xFFBEB0FF).withValues(alpha: 0.28)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        break;
      case BiomeType.swamp:
        // Gnarled dead tree
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset(cx, cy + cellSize * 0.3),
              width: cellSize * 0.20,
              height: cellSize * 1.0),
          Paint()..color = const Color(0xFF3B2A1A),
        );
        canvas.drawLine(
          Offset(cx, cy - cellSize * 0.1),
          Offset(cx - cellSize * 0.65, cy - cellSize * 0.65),
          Paint()
            ..color = const Color(0xFF3B2A1A)
            ..strokeWidth = cellSize * 0.12,
        );
        canvas.drawLine(
          Offset(cx, cy + cellSize * 0.10),
          Offset(cx + cellSize * 0.55, cy - cellSize * 0.35),
          Paint()
            ..color = const Color(0xFF3B2A1A)
            ..strokeWidth = cellSize * 0.10,
        );
        break;
      case BiomeType.tundra:
      case BiomeType.frozenLake:
        // Frost-covered conifer
        final treePath = Path()
          ..moveTo(cx, cy - cellSize * 1.0)
          ..lineTo(cx + cellSize * 0.60, cy + cellSize * 0.45)
          ..lineTo(cx - cellSize * 0.60, cy + cellSize * 0.45)
          ..close();
        canvas.drawPath(treePath,
            Paint()..color = const Color(0xFF4E7A8A).withValues(alpha: 0.62));
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset(cx, cy + cellSize * 0.65),
              width: cellSize * 0.18,
              height: cellSize * 0.45),
          Paint()..color = const Color(0xFF3C5260),
        );
        break;
      case BiomeType.lavaField:
      case BiomeType.ashlands:
        // Obsidian spire
        final spire = Path()
          ..moveTo(cx, cy - cellSize * 1.0)
          ..lineTo(cx + cellSize * 0.28, cy + cellSize * 0.50)
          ..lineTo(cx - cellSize * 0.28, cy + cellSize * 0.50)
          ..close();
        canvas.drawPath(spire, Paint()..color = const Color(0xFF1A0D0D));
        canvas.drawLine(
          Offset(cx, cy - cellSize * 0.9),
          Offset(cx, cy + cellSize * 0.4),
          Paint()
            ..color = const Color(0xFFFF5500).withValues(alpha: 0.45)
            ..strokeWidth = 1.0
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
        break;
      case BiomeType.mushroom:
        // Giant mushroom
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset(cx, cy + cellSize * 0.55),
              width: cellSize * 0.24,
              height: cellSize * 0.90),
          Paint()..color = const Color(0xFFD9C8A8),
        );
        canvas.drawCircle(
          Offset(cx, cy - cellSize * 0.1),
          cellSize * 0.64,
          Paint()..color = const Color(0xFF9A3DBF).withValues(alpha: 0.82),
        );
        for (final xOff in [-0.28, 0.0, 0.28]) {
          canvas.drawCircle(
            Offset(cx + xOff * cellSize, cy - cellSize * 0.06),
            cellSize * 0.07,
            Paint()..color = Colors.white.withValues(alpha: 0.72),
          );
        }
        break;
      case BiomeType.coral:
        // Tall coral fan
        final branch = Paint()
          ..color = const Color(0xFF4DA5BE)
          ..strokeCap = StrokeCap.round;
        branch.strokeWidth = cellSize * 0.14;
        canvas.drawLine(Offset(cx, cy + cellSize * 0.6),
            Offset(cx, cy - cellSize * 0.5), branch);
        branch.strokeWidth = cellSize * 0.10;
        canvas.drawLine(Offset(cx, cy - cellSize * 0.1),
            Offset(cx - cellSize * 0.50, cy - cellSize * 0.65), branch);
        canvas.drawLine(Offset(cx, cy + cellSize * 0.1),
            Offset(cx + cellSize * 0.50, cy - cellSize * 0.45), branch);
        break;
    }
  }

  void _drawRetroGhosting(Canvas canvas) {
    if (engine.trail.isEmpty) return;

    // Draw trail segments with fading opacity to simulate LCD ghosting
    for (int i = 0; i < engine.trail.length; i++) {
      final pos = engine.trail[i];
      final rect = _cellRect(pos);
      final opacity = (0.3 - (i * 0.05)).clamp(0.0, 1.0);

      canvas.drawRect(
        rect.deflate(1.0),
        Paint()..color = colors.snakeBody.withValues(alpha: opacity),
      );
    }
  }

  void _drawEvents(Canvas canvas, Size size) {
    if (engine.activeEvent == BoardEvent.none) return;

    if (engine.activeEvent == BoardEvent.iceBoard) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..color = const Color(0xFF00FFFF).withValues(alpha: 0.15)
          ..blendMode = BlendMode.srcOver,
      );
    } else if (engine.activeEvent == BoardEvent.lightsOut &&
        engine.snake.isNotEmpty) {
      final headCenter = _cellRect(engine.snake.first).center;

      final gradient = ui.Gradient.radial(headCenter, cellSize * 5, [
        Colors.transparent,
        Colors.black87,
        Colors.black,
      ], [
        0.0,
        0.4,
        1.0
      ]);

      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..shader = gradient,
      );
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    // Explore mode uses natural biome backgrounds — no grid overlay needed
    if (engine.gameMode == GameMode.explore) return;
    if (themeType == ThemeType.retro || themeType == ThemeType.nature) return;

    final int cols = engine.gridCols;
    final int rows = engine.gridRows;

    if (themeType == ThemeType.arcade) {
      final paint = Paint()
        ..color = colors.gridLine
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      for (int x = 0; x <= cols; x++) {
        for (int y = 0; y <= rows; y++) {
          canvas.drawPoints(
              ui.PointMode.points, [Offset(x * cellSize, y * cellSize)], paint);
        }
      }
      return;
    }

    final paint = Paint()
      ..color = colors.gridLine
      ..strokeWidth = 0.5;

    if (themeType == ThemeType.neon) {
      paint.maskFilter = const MaskFilter.blur(BlurStyle.outer, 1.5);
    }

    for (int x = 0; x <= cols; x++) {
      canvas.drawLine(
        Offset(x * cellSize, 0),
        Offset(x * cellSize, rows * cellSize),
        paint,
      );
    }
    for (int y = 0; y <= rows; y++) {
      canvas.drawLine(
        Offset(0, y * cellSize),
        Offset(cols * cellSize, y * cellSize),
        paint,
      );
    }
  }

  void _drawSpikeTraps(Canvas canvas) {
    if (engine.gameMode != GameMode.explore) return;
    final isActive = engine.spikesActive;
    final isWarning = engine.spikesWarning;
    final Color spikeColor;
    if (isActive) {
      spikeColor = const Color(0xFFFF1744);
    } else if (isWarning) {
      spikeColor = const Color(0xFFFFAB00); // amber warning
    } else {
      spikeColor = Colors.white10;
    }

    for (final pos in engine.spikeTraps) {
      final rect = _cellRect(pos);
      final center = rect.center;

      // Draw base plate
      canvas.drawRect(
        rect.deflate(1.0),
        Paint()..color = Colors.black.withValues(alpha: 0.4),
      );

      if (isActive) {
        // Glowing aura for active spikes
        canvas.drawCircle(
          center,
          cellSize * 0.7,
          Paint()
            ..color = spikeColor.withValues(alpha: 0.2 * (0.8 + pulse * 0.4))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );

        // Spike blades (X pattern)
        final spikePaint = Paint()
          ..color = spikeColor
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;

        final offset = cellSize * 0.3;
        canvas.drawLine(center + Offset(-offset, -offset),
            center + Offset(offset, offset), spikePaint);
        canvas.drawLine(center + Offset(offset, -offset),
            center + Offset(-offset, offset), spikePaint);

        // Center core glow
        canvas.drawCircle(center, 2.0, Paint()..color = Colors.white);
      } else if (isWarning) {
        // Warning phase: pulsing amber glow + rising spikes
        canvas.drawCircle(
          center,
          cellSize * 0.6,
          Paint()
            ..color = spikeColor.withValues(alpha: 0.15 + pulse * 0.25)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        final warnPaint = Paint()
          ..color = spikeColor.withValues(alpha: 0.5 + pulse * 0.4)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round;
        final offset = cellSize * 0.25;
        canvas.drawLine(center + Offset(-offset, -offset),
            center + Offset(offset, offset), warnPaint);
        canvas.drawLine(center + Offset(offset, -offset),
            center + Offset(-offset, offset), warnPaint);
      } else {
        // Retracted dim spikes
        final dimPaint = Paint()
          ..color = Colors.white24
          ..strokeWidth = 1.0;
        final offset = cellSize * 0.2;
        canvas.drawLine(center + Offset(-offset, -offset),
            center + Offset(offset, offset), dimPaint);
        canvas.drawLine(center + Offset(offset, -offset),
            center + Offset(-offset, offset), dimPaint);
      }
    }
  }

  void _drawFood(Canvas canvas) {
    if (engine.food == null) return;
    final food = engine.food!;
    final pos = food.position;
    final rect = _cellRect(pos);
    final center = rect.center;
    final radius = (cellSize / 2) * (0.7 + pulse * 0.15);

    final isGolden = food.type == FoodType.golden;
    final isPoison = food.type == FoodType.poison;
    final isBoss = food.type == FoodType.boss;

    // ── Boss food — draw before normal theme handling ─────────────
    if (isBoss) {
      // Pulsing gold outer ring
      final bossOuter = Paint()
        ..color = Colors.amber.withValues(alpha: 0.35 + pulse * 0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + pulse * 4);
      canvas.drawCircle(center, radius * 1.6, bossOuter);
      // Inner skull/crown body
      canvas.drawCircle(
          center, radius * 1.1, Paint()..color = const Color(0xFFFFCC00));
      canvas.drawCircle(
          center, radius * 0.6, Paint()..color = const Color(0xFFFF6600));
      // Spinning dash ring
      final dashPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      const int dashes = 8;
      for (int d = 0; d < dashes; d++) {
        final a1 = (d / dashes) * 2 * pi + pulse * 2 * pi;
        final a2 = a1 + (0.5 / dashes) * 2 * pi;
        canvas.drawArc(Rect.fromCircle(center: center, radius: radius * 1.35),
            a1, a2 - a1, false, dashPaint);
      }
      // Crown symbol
      canvas.drawCircle(center, radius * 0.25,
          Paint()..color = Colors.white.withValues(alpha: 0.9));
      return;
    }

    Color baseColor = colors.food;
    if (themeType != ThemeType.retro) {
      if (isGolden) {
        baseColor = const Color(0xFFFFD700);
      } else if (isPoison) baseColor = const Color(0xFFAA00FF);
    }

    if (themeType == ThemeType.retro) {
      // Hollow flickering square for retro food
      final t = DateTime.now().millisecondsSinceEpoch;
      final flicker = isPoison ? 250 : 500;
      if (t % flicker > (flicker / 2)) return; // True 1997 flicker effect

      canvas.drawRect(
          rect.deflate(cellSize * 0.1),
          Paint()
            ..color = baseColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = cellSize * 0.15);
      if (isGolden) {
        canvas.drawRect(
            rect.deflate(cellSize * 0.25), Paint()..color = baseColor);
      } else {
        canvas.drawRect(
            rect.deflate(cellSize * 0.35), Paint()..color = baseColor);
      }
      return;
    }

    if (themeType == ThemeType.neon) {
      // Outer soft bloom
      canvas.drawCircle(
          center,
          radius * 2.2,
          Paint()
            ..color = baseColor.withValues(alpha: 0.15 + pulse * 0.1)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
      // Mid bloom
      canvas.drawCircle(
          center,
          radius * 1.4,
          Paint()
            ..color = baseColor.withValues(alpha: 0.55)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      // Core
      canvas.drawCircle(center, radius, Paint()..color = baseColor);
      // Specular highlight
      canvas.drawCircle(
          Offset(center.dx - radius * 0.3, center.dy - radius * 0.3),
          radius * 0.3,
          Paint()..color = Colors.white.withValues(alpha: 0.75));
      return;
    }

    if (themeType == ThemeType.nature) {
      // Berry with a leaf
      canvas.drawCircle(center, radius, Paint()..color = baseColor);
      if (!isPoison) {
        final path = Path()
          ..moveTo(center.dx, center.dy - radius)
          ..quadraticBezierTo(
              center.dx - cellSize * 0.2,
              center.dy - radius - cellSize * 0.2,
              center.dx + cellSize * 0.1,
              center.dy - radius - cellSize * 0.3)
          ..quadraticBezierTo(
              center.dx + cellSize * 0.2,
              center.dy - radius - cellSize * 0.1,
              center.dx,
              center.dy - radius);
        canvas.drawPath(path, Paint()..color = const Color(0xFF4CAF50));
      }
      return;
    }

    if (themeType == ThemeType.arcade) {
      // Classic Cherry
      canvas.drawCircle(center, radius, Paint()..color = baseColor);
      if (!isPoison) {
        canvas.drawRect(Rect.fromLTWH(center.dx, center.dy - radius - 2, 2, 6),
            Paint()..color = const Color(0xFF00FF00)); // Stem
      }
      return;
    }

    if (themeType == ThemeType.cyber) {
      // Glowing digital hex
      final path = Path();
      for (int i = 0; i < 6; i++) {
        final angle = i * pi / 3;
        final px = center.dx + radius * cos(angle);
        final py = center.dy + radius * sin(angle);
        if (i == 0)
          path.moveTo(px, py);
        else
          path.lineTo(px, py);
      }
      path.close();
      // Outer bloom
      canvas.drawPath(
          path,
          Paint()
            ..color = baseColor.withValues(alpha: 0.2 + pulse * 0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      // Semi-transparent fill
      canvas.drawPath(path, Paint()..color = baseColor.withValues(alpha: 0.22));
      // Bright outline
      canvas.drawPath(
          path,
          Paint()
            ..color = baseColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
      // Bright center dot
      canvas.drawCircle(center, radius * 0.38, Paint()..color = baseColor);
      return;
    }

    if (themeType == ThemeType.volcano) {
      // Wide lava bloom
      canvas.drawCircle(
          center,
          radius * 2.0,
          Paint()
            ..color = baseColor.withValues(alpha: 0.2 + pulse * 0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      // Mid-ring
      canvas.drawCircle(
          center,
          radius * 1.3,
          Paint()
            ..color = baseColor.withValues(alpha: 0.55)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      // Core fill
      canvas.drawCircle(center, radius, Paint()..color = baseColor);
      // Hot white centre
      canvas.drawCircle(center, radius * 0.45,
          Paint()..color = Colors.white.withValues(alpha: 0.6 + pulse * 0.2));
      return;
    }

    if (themeType == ThemeType.ice) {
      // Frosty berry with icy bloom
      canvas.drawCircle(
          center,
          radius * 2.0,
          Paint()
            ..color = baseColor.withValues(alpha: 0.15 + pulse * 0.1)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
      // Mid glow
      canvas.drawCircle(
          center,
          radius * 1.2,
          Paint()
            ..color = baseColor.withValues(alpha: 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      // Core
      canvas.drawCircle(center, radius, Paint()..color = baseColor);
      // Ice-crystal specular
      canvas.drawCircle(
          Offset(center.dx - radius * 0.3, center.dy - radius * 0.3),
          radius * 0.3,
          Paint()..color = Colors.white.withValues(alpha: 0.85));
      return;
    }
  }

  Color _biomeBgColor(BiomeType biome) {
    switch (biome) {
      case BiomeType.forest:
        return const Color(0xFF1E3A24);
      case BiomeType.jungle:
        return const Color(0xFF163A1E);
      case BiomeType.desert:
        return const Color(0xFF7C6330);
      case BiomeType.savanna:
        return const Color(0xFF6D6A2E);
      case BiomeType.swamp:
        return const Color(0xFF1D3026);
      case BiomeType.coral:
        return const Color(0xFF1F3F4A);
      case BiomeType.cave:
        return const Color(0xFF1A1D24);
      case BiomeType.crystalCave:
        return const Color(0xFF232345);
      case BiomeType.ruins:
        return const Color(0xFF3A3128);
      case BiomeType.tundra:
        return const Color(0xFF2B3B48);
      case BiomeType.frozenLake:
        return const Color(0xFF2A465A);
      case BiomeType.lavaField:
        return const Color(0xFF331515);
      case BiomeType.ashlands:
        return const Color(0xFF2C2020);
      case BiomeType.mushroom:
        return const Color(0xFF2D2239);
    }
  }

  void _drawExploreObstacle(Canvas canvas, Position obs) {
    final rect = _cellRect(obs);
    final rx = obs.x ~/ 10;
    final ry = obs.y ~/ 10;
    final roomKey = rx * 11 + ry;
    final biome =
        engine.roomBiomes[roomKey] ?? engine.currentBiome ?? BiomeType.forest;
    late final Color base;
    late final Color accent;
    switch (biome) {
      case BiomeType.forest:
      case BiomeType.jungle:
        base = const Color(0xFF2F3B2F);
        accent = const Color(0xFF4B6A44);
        break;
      case BiomeType.desert:
      case BiomeType.savanna:
        base = const Color(0xFF7D6A48);
        accent = const Color(0xFFB49A64);
        break;
      case BiomeType.swamp:
        base = const Color(0xFF31443A);
        accent = const Color(0xFF4A6A55);
        break;
      case BiomeType.coral:
        base = const Color(0xFF2D5460);
        accent = const Color(0xFF5EA3B3);
        break;
      case BiomeType.cave:
      case BiomeType.ruins:
        base = const Color(0xFF3A3A3F);
        accent = const Color(0xFF6A6A70);
        break;
      case BiomeType.crystalCave:
        base = const Color(0xFF3E3A64);
        accent = const Color(0xFF8A79D6);
        break;
      case BiomeType.tundra:
      case BiomeType.frozenLake:
        base = const Color(0xFF4A5F73);
        accent = const Color(0xFF9FC7D6);
        break;
      case BiomeType.lavaField:
      case BiomeType.ashlands:
        base = const Color(0xFF271818);
        accent = const Color(0xFFFF5A36);
        break;
      case BiomeType.mushroom:
        base = const Color(0xFF4D355A);
        accent = const Color(0xFFB26AD4);
        break;
    }
    final seed = (obs.x * 73856093) ^ (obs.y * 19349663);
    final variant = seed & 3;

    // Base obstacle tile.
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(0.8), const Radius.circular(3)),
      Paint()..color = base,
    );

    switch (biome) {
      case BiomeType.forest:
      case BiomeType.jungle:
        // Tree trunk + canopy
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(rect.center.dx, rect.center.dy + cellSize * 0.1),
            width: cellSize * 0.22,
            height: cellSize * 0.45,
          ),
          Paint()..color = const Color(0xFF5E3C1B),
        );
        canvas.drawCircle(
          rect.center + Offset(0, -cellSize * 0.15),
          cellSize * (variant == 0 ? 0.30 : 0.26),
          Paint()..color = accent,
        );
        if (biome == BiomeType.jungle) {
          canvas.drawLine(
            rect.topCenter + Offset(cellSize * 0.1, 0),
            rect.centerRight + Offset(0, cellSize * 0.2),
            Paint()
              ..color = const Color(0xFF2A7A3A).withValues(alpha: 0.7)
              ..strokeWidth = 1.0,
          );
        }
        break;
      case BiomeType.desert:
      case BiomeType.savanna:
        // Dune stone
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: rect.center,
              width: cellSize * 0.65,
              height: cellSize * 0.42,
            ),
            const Radius.circular(2),
          ),
          Paint()..color = accent,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: rect.center + Offset(0, cellSize * 0.15),
            width: cellSize * 0.65,
            height: cellSize * 0.25,
          ),
          pi,
          pi,
          false,
          Paint()
            ..color = const Color(0xFFE2C58A).withValues(alpha: 0.45)
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke,
        );
        break;
      case BiomeType.swamp:
        // Mud stump + roots
        canvas.drawCircle(
            rect.center, cellSize * 0.22, Paint()..color = accent);
        final rootPaint = Paint()
          ..color = const Color(0xFF3B2A1A).withValues(alpha: 0.8)
          ..strokeWidth = 1.0;
        canvas.drawLine(rect.center,
            rect.centerLeft + Offset(0, cellSize * 0.2), rootPaint);
        canvas.drawLine(rect.center,
            rect.centerRight + Offset(0, cellSize * 0.2), rootPaint);
        break;
      case BiomeType.coral:
        // Coral branch
        final branch = Paint()
          ..color = accent
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round;
        final c = rect.center;
        canvas.drawLine(c + Offset(0, cellSize * 0.2),
            c + Offset(0, -cellSize * 0.2), branch);
        canvas.drawLine(c + Offset(0, -cellSize * 0.05),
            c + Offset(-cellSize * 0.18, -cellSize * 0.2), branch);
        canvas.drawLine(c + Offset(0, -cellSize * 0.02),
            c + Offset(cellSize * 0.18, -cellSize * 0.18), branch);
        break;
      case BiomeType.cave:
      case BiomeType.ruins:
        // Cracked stone
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(2.0), const Radius.circular(2)),
          Paint()..color = accent.withValues(alpha: 0.45),
        );
        canvas.drawLine(
          rect.topLeft + Offset(cellSize * 0.25, cellSize * 0.2),
          rect.bottomRight - Offset(cellSize * 0.2, cellSize * 0.25),
          Paint()
            ..color = const Color(0xFF8A8A8F).withValues(alpha: 0.45)
            ..strokeWidth = 1.0,
        );
        break;
      case BiomeType.crystalCave:
        // Crystal shard + glow
        final c = rect.center;
        final shard = Path()
          ..moveTo(c.dx, c.dy - cellSize * 0.32)
          ..lineTo(c.dx + cellSize * 0.18, c.dy + cellSize * 0.25)
          ..lineTo(c.dx - cellSize * 0.18, c.dy + cellSize * 0.25)
          ..close();
        canvas.drawPath(shard, Paint()..color = accent.withValues(alpha: 0.9));
        canvas.drawCircle(
          c,
          cellSize * 0.35,
          Paint()
            ..color = accent.withValues(alpha: 0.16)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        break;
      case BiomeType.tundra:
      case BiomeType.frozenLake:
        // Ice shard
        final c = rect.center;
        final shard = Path()
          ..moveTo(c.dx, c.dy - cellSize * 0.30)
          ..lineTo(c.dx + cellSize * 0.16, c.dy + cellSize * 0.22)
          ..lineTo(c.dx - cellSize * 0.16, c.dy + cellSize * 0.22)
          ..close();
        canvas.drawPath(shard, Paint()..color = accent.withValues(alpha: 0.8));
        break;
      case BiomeType.lavaField:
      case BiomeType.ashlands:
        // Obsidian with lava fissure
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(2.2), const Radius.circular(2)),
          Paint()..color = const Color(0xFF1A1212),
        );
        canvas.drawLine(
          rect.centerLeft + Offset(cellSize * 0.22, 0),
          rect.centerRight - Offset(cellSize * 0.22, 0),
          Paint()
            ..color = accent
            ..strokeWidth = 1.4
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
        break;
      case BiomeType.mushroom:
        // Mushroom cap + stem
        canvas.drawRect(
          Rect.fromCenter(
            center: rect.center + Offset(0, cellSize * 0.12),
            width: cellSize * 0.16,
            height: cellSize * 0.30,
          ),
          Paint()..color = const Color(0xFFE5D7C3),
        );
        canvas.drawCircle(
          rect.center + Offset(0, -cellSize * 0.08),
          cellSize * 0.24,
          Paint()..color = accent,
        );
        canvas.drawCircle(
          rect.center + Offset(-cellSize * 0.08, -cellSize * 0.12),
          cellSize * 0.04,
          Paint()..color = Colors.white.withValues(alpha: 0.8),
        );
        break;
    }
  }

  void _drawPrey(Canvas canvas) {
    if (engine.preyList.isEmpty) return;
    for (final prey in engine.preyList) {
      _drawSinglePrey(canvas, prey);
    }
  }

  void _drawSinglePrey(Canvas canvas, FoodModel prey) {
    switch (prey.type) {
      case FoodType.rabbit:
        _drawRabbit(canvas, prey);
        break;
      case FoodType.lizard:
        _drawLizard(canvas, prey);
        break;
      case FoodType.butterfly:
        _drawButterfly(canvas, prey);
        break;
      case FoodType.croc:
        _drawCroc(canvas, prey);
        break;
      case FoodType.elite:
        _drawElite(canvas, prey);
        break;
      case FoodType.biomeEvent:
        _drawBiomeEvent(canvas, prey);
        break;
      case FoodType.fruit:
        _drawFruit(canvas, prey);
        break;
      default:
        _drawMouse(canvas, prey);
        break;
    }
  }

  void _drawMouse(Canvas canvas, FoodModel prey) {
    final center = _cellRect(prey.position).center;
    final r = cellSize * (0.24 + pulse * 0.03);
    const color = Color(0xFFBDBDBD);
    canvas.drawCircle(
        center,
        r * 1.6,
        Paint()
          ..color = color.withValues(alpha: 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawCircle(center, r, Paint()..color = color);
    // Ears
    for (final xOff in [-0.75, 0.75]) {
      canvas.drawCircle(center + Offset(xOff * r, -r * 0.85), r * 0.38,
          Paint()..color = color);
      canvas.drawCircle(center + Offset(xOff * r, -r * 0.85), r * 0.18,
          Paint()..color = Colors.pink.withValues(alpha: 0.7));
    }
    canvas.drawCircle(
        center + Offset(0, r * 0.28), r * 0.13, Paint()..color = Colors.pink);
  }

  void _drawRabbit(Canvas canvas, FoodModel prey) {
    final center = _cellRect(prey.position).center;
    canvas.drawCircle(
        center,
        cellSize * 0.45,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.18 + pulse * 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawCircle(center, cellSize * 0.3, Paint()..color = Colors.white);
    // Ears
    for (final xOff in [-0.10, 0.10]) {
      canvas.drawCircle(center + Offset(xOff * cellSize, -cellSize * 0.36),
          cellSize * 0.09, Paint()..color = Colors.white);
    }
    // Dash charge dots
    for (int i = 0; i < prey.dashChargesLeft; i++) {
      canvas.drawCircle(
          center + Offset((i - 1) * cellSize * 0.22, cellSize * 0.40),
          cellSize * 0.07,
          Paint()..color = Colors.yellow);
    }
  }

  void _drawLizard(Canvas canvas, FoodModel prey) {
    final center = _cellRect(prey.position).center;
    final isHiding = prey.stillTicksLeft > 0;
    final opacity = isHiding ? 0.25 : (0.7 + pulse * 0.3);
    final color = const Color(0xFF66BB6A).withValues(alpha: opacity);
    final r = cellSize * 0.28;
    // Body (elongated oval)
    canvas.drawOval(
      Rect.fromCenter(center: center, width: r * 2.2, height: r * 1.4),
      Paint()..color = color,
    );
    // Head
    canvas.drawCircle(
        center + Offset(r * 1.1, 0), r * 0.6, Paint()..color = color);
    // Tail
    final tailPath = Path()
      ..moveTo(center.dx - r * 0.9, center.dy)
      ..lineTo(center.dx - r * 2.2, center.dy + r * 0.4)
      ..lineTo(center.dx - r * 0.9, center.dy - r * 0.2)
      ..close();
    canvas.drawPath(tailPath, Paint()..color = color);
    // Eye
    canvas.drawCircle(center + Offset(r * 1.45, -r * 0.2), r * 0.15,
        Paint()..color = Colors.red.withValues(alpha: isHiding ? 0.4 : 1.0));
  }

  void _drawButterfly(Canvas canvas, FoodModel prey) {
    final center = _cellRect(prey.position).center;
    final r = cellSize * 0.38;
    // Wings (two arcs)
    final wingColors = [const Color(0xFFFF9800), const Color(0xFFFFEB3B)];
    for (int side = -1; side <= 1; side += 2) {
      final wingCenter = center + Offset(side * r * 0.9, 0);
      canvas.drawCircle(
          wingCenter,
          r * (0.65 + pulse * 0.1),
          Paint()
            ..color = wingColors[(side + 1) ~/ 2]
                .withValues(alpha: 0.7 + pulse * 0.2));
    }
    // Body
    canvas.drawOval(
      Rect.fromCenter(center: center, width: r * 0.28, height: r * 1.1),
      Paint()..color = Colors.brown,
    );
    // Timer ring (countdown to expiry)
    if (prey.expiresAtMs != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final remaining = (prey.expiresAtMs! - now) / 15000.0;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r * 1.5),
        -pi / 2,
        2 * pi * remaining.clamp(0, 1),
        false,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.6)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _drawCroc(Canvas canvas, FoodModel prey) {
    if (prey.crocBody.isEmpty) return;
    const color = Color(0xFF2E7D32);
    const headColor = Color(0xFF1B5E20);
    // Draw body segments back to front
    for (int b = prey.crocBody.length - 1; b >= 0; b--) {
      final pos = prey.crocBody[b];
      final rect = _cellRect(pos);
      final rr = RRect.fromRectAndRadius(
          rect.deflate(1.5), Radius.circular(cellSize * 0.2));
      canvas.drawRRect(rr, Paint()..color = b == 0 ? headColor : color);
      if (b == 0) {
        // Eyes on head
        final hc = rect.center;
        canvas.drawCircle(hc + Offset(-cellSize * 0.18, -cellSize * 0.2),
            cellSize * 0.1, Paint()..color = Colors.yellow);
        canvas.drawCircle(hc + Offset(cellSize * 0.18, -cellSize * 0.2),
            cellSize * 0.1, Paint()..color = Colors.yellow);
        // Pulsing gold outline (boss indicator)
        canvas.drawRRect(
            rr,
            Paint()
              ..color = Colors.amber.withValues(alpha: 0.4 + pulse * 0.4)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0);
      }
    }
  }

  void _drawFruit(Canvas canvas, FoodModel prey) {
    final center = _cellRect(prey.position).center;
    final r = cellSize * (0.27 + pulse * 0.03);

    // Glow halo
    canvas.drawCircle(
      center,
      r * 1.6,
      Paint()
        ..color = const Color(0xFFE53935).withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Main body – red circle (apple-like)
    canvas.drawCircle(center, r, Paint()..color = const Color(0xFFE53935));

    // Highlight
    canvas.drawCircle(
      center + Offset(-r * 0.28, -r * 0.28),
      r * 0.28,
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );

    // Stem
    final stemTop = center + Offset(r * 0.08, -r * 1.05);
    canvas.drawLine(
      center + Offset(r * 0.08, -r),
      stemTop,
      Paint()
        ..color = const Color(0xFF5D4037)
        ..strokeWidth = cellSize * 0.08
        ..strokeCap = StrokeCap.round,
    );

    // Leaf
    final leafPath = Path()
      ..moveTo(stemTop.dx, stemTop.dy)
      ..quadraticBezierTo(
        stemTop.dx + r * 0.55,
        stemTop.dy - r * 0.25,
        stemTop.dx + r * 0.28,
        stemTop.dy + r * 0.1,
      )
      ..close();
    canvas.drawPath(
      leafPath,
      Paint()..color = const Color(0xFF43A047).withValues(alpha: 0.9),
    );

    // Expiry ring
    if (prey.expiresAtMs != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final fraction = ((prey.expiresAtMs! - now) / 20000.0).clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r * 1.45),
        -pi / 2,
        2 * pi * fraction,
        false,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.55)
          ..strokeWidth = 1.4
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _drawElite(Canvas canvas, FoodModel prey) {
    final center = _cellRect(prey.position).center;
    final ringR = cellSize * (0.5 + pulse * 0.08);

    canvas.drawCircle(
      center,
      ringR * 1.3,
      Paint()
        ..color = const Color(0xFFFF7043).withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    canvas.drawCircle(
      center,
      ringR,
      Paint()
        ..color = Colors.orange.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: cellSize * 0.52,
        height: cellSize * 0.52,
      ),
      Radius.circular(cellSize * 0.12),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFFEF6C00));

    final blade = Path()
      ..moveTo(center.dx - cellSize * 0.06, center.dy + cellSize * 0.18)
      ..lineTo(center.dx + cellSize * 0.16, center.dy - cellSize * 0.18)
      ..lineTo(center.dx + cellSize * 0.22, center.dy - cellSize * 0.12)
      ..lineTo(center.dx, center.dy + cellSize * 0.24)
      ..close();
    canvas.drawPath(
        blade, Paint()..color = Colors.white.withValues(alpha: 0.9));
  }

  void _drawBiomeEvent(Canvas canvas, FoodModel prey) {
    final center = _cellRect(prey.position).center;
    final r = cellSize * 0.42;
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF80DEEA).withValues(alpha: 0.8),
          const Color(0xFF4DD0E1).withValues(alpha: 0.12),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r * 2.0));
    canvas.drawCircle(center, r * 1.9, glow);

    final pulseScale = 0.78 + pulse * 0.16;
    for (int i = 0; i < 4; i++) {
      final angle = (pi / 2) * i + pulse * 0.6;
      final tip = center + Offset(cos(angle), sin(angle)) * (r * 1.05);
      canvas.drawCircle(
        tip,
        cellSize * 0.1 * pulseScale,
        Paint()..color = Colors.white.withValues(alpha: 0.92),
      );
    }

    final core = Path()
      ..moveTo(center.dx, center.dy - r)
      ..lineTo(center.dx + r * 0.62, center.dy)
      ..lineTo(center.dx, center.dy + r)
      ..lineTo(center.dx - r * 0.62, center.dy)
      ..close();
    canvas.drawPath(core, Paint()..color = const Color(0xFF00ACC1));

    canvas.drawPath(
      core,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  void _drawPowerUps(Canvas canvas) {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final pu in engine.boardPowerUps) {
      if (pu.isExpired(now)) continue;
      final rect = _cellRect(pu.position);
      final center = rect.center;
      final r = (cellSize / 2) * (0.8 + pulse * 0.1);

      if (themeType == ThemeType.neon) {
        canvas.drawCircle(center, r * 1.6,
            Paint()..color = colors.powerUp.withValues(alpha: 0.25));
      }

      // Background circle
      canvas.drawCircle(
        center,
        r,
        Paint()..color = colors.powerUp.withValues(alpha: 0.85),
      );

      // Draw icon text
      final tp = TextPainter(
        text: TextSpan(
          text: pu.type.icon,
          style: TextStyle(fontSize: cellSize * 0.55),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
      );
    }
  }

  void _drawSnake(Canvas canvas) {
    final snake = engine.snake;
    if (snake.isEmpty) return;

    final isGhost = engine.getActivePowerUp(PowerUpType.ghostMode) != null;
    final opacity = isGhost ? 0.55 : 1.0;

    final progress = engine.movementProgress;

    // Draw body (tail to neck)
    for (int i = snake.length - 1; i >= 1; i--) {
      final colorProgress = 1 - (i / snake.length) * 0.6;
      final bodyColor =
          Color.lerp(colors.snakeTail, colors.snakeBody, colorProgress)!
              .withValues(alpha: opacity);
      Position prevPos = (i + 1 < snake.length)
          ? snake[i + 1]
          : (engine.trail.isNotEmpty ? engine.trail.first : snake[i]);
      Rect rect = _interpolatedRect(snake[i], prevPos, progress);

      // Apply food bulge
      if (engine.foodBulges.contains(i)) {
        rect = rect.inflate(cellSize * 0.18);
      }

      if (skin == SnakeSkin.ghost) {
        canvas.drawCircle(rect.center, cellSize * 0.45,
            Paint()..color = Colors.white.withValues(alpha: 0.3 * opacity));
        canvas.drawCircle(
            rect.center,
            cellSize * 0.2,
            Paint()
              ..color =
                  Colors.lightBlueAccent.withValues(alpha: 0.5 * opacity));
      } else if (skin == SnakeSkin.skeleton) {
        canvas.drawRect(
            Rect.fromCenter(
                center: rect.center,
                width: cellSize * 0.6,
                height: cellSize * 0.2),
            Paint()..color = Colors.white.withValues(alpha: opacity));
        canvas.drawRect(
            Rect.fromCenter(
                center: rect.center,
                width: cellSize * 0.2,
                height: cellSize * 0.6),
            Paint()..color = Colors.white.withValues(alpha: opacity));
      } else if (skin == SnakeSkin.robot) {
        canvas.drawRect(rect.deflate(1.0),
            Paint()..color = Colors.grey[700]!.withValues(alpha: opacity));
        canvas.drawRect(rect.deflate(3.0),
            Paint()..color = Colors.cyanAccent.withValues(alpha: opacity));
      } else if (skin == SnakeSkin.rainbow) {
        final rbColor = HSLColor.fromAHSL(
                1.0,
                ((i * 15.0) + (DateTime.now().millisecondsSinceEpoch / 5)) %
                    360,
                1.0,
                0.5)
            .toColor();
        canvas.drawCircle(rect.center, cellSize * 0.5,
            Paint()..color = rbColor.withValues(alpha: opacity));
      } else {
        if (themeType == ThemeType.retro) {
          canvas.drawRect(rect.deflate(1.5), Paint()..color = bodyColor);
        } else if (themeType == ThemeType.nature) {
          final rr = RRect.fromRectAndRadius(
              rect.deflate(1.5), Radius.circular(cellSize * 0.35));
          canvas.drawRRect(rr, Paint()..color = bodyColor);
        } else if (themeType == ThemeType.arcade) {
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  rect.deflate(1.0), const Radius.circular(2)),
              Paint()..color = bodyColor);
        } else if (themeType == ThemeType.neon) {
          // Glow layer
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  rect.inflate(1.0), Radius.circular(cellSize * 0.3)),
              Paint()
                ..color = bodyColor.withValues(alpha: 0.6)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
          // Core bright segment
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  rect.deflate(1.0), Radius.circular(cellSize * 0.3)),
              Paint()..color = Colors.white.withValues(alpha: opacity * 0.9));
        } else {
          // Default: rounded segments with gradient shimmer
          final rr = RRect.fromRectAndRadius(
              rect.deflate(1.5), Radius.circular(cellSize * 0.3));
          canvas.drawRRect(rr, Paint()..color = bodyColor);
          // Subtle top-left highlight for 3D feel
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromLTWH(rect.left + 2, rect.top + 2, rect.width * 0.5,
                      rect.height * 0.4),
                  Radius.circular(cellSize * 0.2)),
              Paint()..color = Colors.white.withValues(alpha: 0.12 * opacity));
        }
      }
    }

    // Draw head
    Position headPrev = snake.length > 1 ? snake[1] : snake.first;
    final headRect = _interpolatedRect(snake.first, headPrev, progress);
    final headColor = colors.snakeHead.withValues(alpha: opacity);

    if (skin == SnakeSkin.ghost) {
      canvas.drawCircle(headRect.center, cellSize * 0.5,
          Paint()..color = Colors.white.withValues(alpha: 0.5 * opacity));
      _drawEyes(canvas, headRect, eyeColor: Colors.lightBlueAccent);
      return;
    } else if (skin == SnakeSkin.skeleton) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              headRect.deflate(2.0), const Radius.circular(4)),
          Paint()..color = Colors.white.withValues(alpha: opacity));
      _drawEyes(canvas, headRect, eyeColor: Colors.black);
      return;
    } else if (skin == SnakeSkin.robot) {
      canvas.drawRect(headRect.deflate(1.0),
          Paint()..color = Colors.black.withValues(alpha: opacity));
      canvas.drawRect(headRect.deflate(3.0),
          Paint()..color = Colors.grey[400]!.withValues(alpha: opacity));
      _drawEyes(canvas, headRect, eyeColor: Colors.redAccent);
      return;
    } else if (skin == SnakeSkin.rainbow) {
      final rbColor = HSLColor.fromAHSL(
              1.0, (DateTime.now().millisecondsSinceEpoch / 5) % 360, 1.0, 0.5)
          .toColor();
      canvas.drawRect(headRect.deflate(1.0),
          Paint()..color = rbColor.withValues(alpha: opacity));
      _drawEyes(canvas, headRect);
      return;
    }

    if (themeType == ThemeType.retro) {
      canvas.drawRect(headRect.deflate(1.5), Paint()..color = headColor);
      // Pixel-art eyes — bright LCD dots on dark head
      _drawEyes(canvas, headRect,
          eyeColor: colors.snakeHead, glowColor: colors.background);
      return;
    }

    if (themeType == ThemeType.neon) {
      // Outer glow
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              headRect.inflate(2.0), Radius.circular(cellSize * 0.35)),
          Paint()
            ..color = headColor.withValues(alpha: 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      // Bright core
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              headRect.deflate(0.5), Radius.circular(cellSize * 0.35)),
          Paint()..color = Colors.white.withValues(alpha: opacity));
      _drawEyes(canvas, headRect);
      return;
    }

    if (themeType == ThemeType.nature) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              headRect.deflate(1.0), Radius.circular(cellSize * 0.4)),
          Paint()..color = headColor);
      _drawEyes(canvas, headRect);
      return;
    }

    if (themeType == ThemeType.arcade) {
      final jawOffset = 1.0 * pulse;
      final sweepAngle = (2 * pi) - jawOffset;
      final startAngle =
          _getPacmanStartAngle(engine.currentDirection, jawOffset);

      canvas.drawArc(
        headRect.deflate(1.0),
        startAngle,
        sweepAngle,
        true,
        Paint()..color = headColor,
      );
      return;
    }
  }

  void _drawTrail(Canvas canvas) {
    // Draw skin-based interactive trail (from TailTrailService)
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final trailService = TailTrailService();
    for (final seg in trailService.segments) {
      final visuals = trailService.visualsFor(seg, nowMs, cellSize);
      if (visuals.radius <= 0) continue;
      final basePos = _cellRect(seg.position).center;
      // Apply physics drift scaled to cell size
      final offset = Offset(seg.vx * cellSize * 0.3, seg.vy * cellSize * 0.3) *
          seg.progress(nowMs);
      final center = basePos + offset;

      final paint = Paint()
        ..color = visuals.color
        ..maskFilter = visuals.blurSigma > 0
            ? MaskFilter.blur(BlurStyle.normal, visuals.blurSigma)
            : null;

      switch (visuals.shape) {
        case TrailShape.ember:
        case TrailShape.blob:
          canvas.drawCircle(center, visuals.radius, paint);
          break;
        case TrailShape.ribbon:
          canvas.drawRect(
            Rect.fromCenter(
                center: center,
                width: visuals.radius * 2,
                height: visuals.radius * 0.5),
            paint,
          );
          break;
        case TrailShape.star:
          // Draw a simple 4-pointed star
          final r = visuals.radius;
          final starPath = Path()
            ..moveTo(center.dx, center.dy - r)
            ..lineTo(center.dx + r * 0.3, center.dy - r * 0.3)
            ..lineTo(center.dx + r, center.dy)
            ..lineTo(center.dx + r * 0.3, center.dy + r * 0.3)
            ..lineTo(center.dx, center.dy + r)
            ..lineTo(center.dx - r * 0.3, center.dy + r * 0.3)
            ..lineTo(center.dx - r, center.dy)
            ..lineTo(center.dx - r * 0.3, center.dy - r * 0.3)
            ..close();
          canvas.drawPath(starPath, paint);
          break;
        case TrailShape.slash:
          canvas.drawLine(
            center + Offset(-visuals.radius, -visuals.radius),
            center + Offset(visuals.radius, visuals.radius),
            paint..strokeWidth = visuals.radius * 0.4,
          );
          break;
      }
    }

    // Also draw the basic position trail for non-skinned fallback
    if (engine.trail.isEmpty) return;
    final trailColor = colors.snakeTail.withValues(alpha: 0.2);
    for (int i = 0; i < engine.trail.length; i++) {
      final opacity = (0.2 * (1 - (i / engine.trail.length))).clamp(0.0, 1.0);
      final rect = _cellRect(engine.trail[i]);
      if (themeType == ThemeType.neon) {
        canvas.drawRect(
          rect,
          Paint()
            ..color = colors.accent.withValues(alpha: opacity * 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
      } else {
        canvas.drawCircle(
          rect.center,
          cellSize * 0.2 * (1 - (i / engine.trail.length)),
          Paint()..color = trailColor.withValues(alpha: opacity),
        );
      }
    }
  }

  void _drawGhost(Canvas canvas) {
    // ── Personal Best ghost ──────────────────────────────────────────
    if (engine.ghostPath.isNotEmpty &&
        engine.ghostIndex < engine.ghostPath.length) {
      final ghostPos = engine.ghostPath[engine.ghostIndex];
      final rect = _cellRect(ghostPos);
      canvas.drawCircle(
          rect.center,
          cellSize * 0.6,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.25)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      canvas.drawCircle(rect.center, cellSize * 0.4,
          Paint()..color = Colors.cyanAccent.withValues(alpha: 0.2));
      final pbTp = TextPainter(
        text: const TextSpan(
          text: 'PB',
          style: TextStyle(
              color: Colors.white38,
              fontSize: 8,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron'),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      pbTp.paint(
          canvas,
          Offset(rect.center.dx - pbTp.width / 2,
              rect.center.dy - pbTp.height / 2));
    }

    // ── Rival ghost (async multiplayer) ─────────────────────────────
    final rival = GhostRacingService().activeRivalGhost;
    if (rival != null && !rival.isFinished) {
      final segments = rival.visibleSegments;
      for (int i = 0; i < segments.length; i++) {
        final pos = segments[i];
        final rect = _cellRect(pos);
        final isHead = i == segments.length - 1;
        final segOpacity = (0.15 + 0.35 * (i / segments.length));

        // Rival body: semi-transparent purple
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(isHead ? 0.5 : 2.0),
              Radius.circular(cellSize * 0.3)),
          Paint()
            ..color = const Color(0xFFAA00FF).withValues(alpha: segOpacity)
            ..maskFilter =
                isHead ? const MaskFilter.blur(BlurStyle.normal, 4) : null,
        );
      }

      // Rival label on head
      if (segments.isNotEmpty) {
        final head = segments.last;
        final headRect = _cellRect(head);
        final rivalTp = TextPainter(
          text: TextSpan(
            text: rival.rivalName,
            style: TextStyle(
                color: const Color(0xFFAA00FF).withValues(alpha: 0.85),
                fontSize: 6,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron'),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        rivalTp.paint(
          canvas,
          Offset(
            headRect.center.dx - rivalTp.width / 2,
            headRect.top - rivalTp.height - 2,
          ),
        );
      }
    }
  }

  void _drawEffects(Canvas canvas) {
    if (engine.effects.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final effect in engine.effects) {
      final elapsed = now - effect.startTimeMs;
      final opacity = (1.0 - (elapsed / 800)).clamp(0.0, 1.0);
      final offset = (elapsed / 800) * 40; // float up
      final center = _cellRect(effect.position).center;

      if (effect.type == EffectType.comboBurst && effect.value != null) {
        final tp = TextPainter(
          text: TextSpan(
            text: effect.value,
            style: TextStyle(
              color: Colors.white.withValues(alpha: opacity),
              fontSize: 14 + (pulse * 2),
              fontWeight: FontWeight.w900,
              fontFamily: 'Orbitron',
              shadows: [
                Shadow(
                    color: Colors.black.withValues(alpha: opacity),
                    blurRadius: 4,
                    offset: const Offset(2, 2)),
                Shadow(
                    color: Colors.orange.withValues(alpha: opacity * 0.5),
                    blurRadius: 10),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        tp.paint(
            canvas,
            Offset(
                center.dx - tp.width / 2, center.dy - tp.height / 2 - offset));
      } else if (effect.type == EffectType.shadowPoof) {
        // Draw glitchy poof particles
        final random = Random(effect.startTimeMs);
        final p = Paint()
          ..color = Colors.deepPurpleAccent.withValues(alpha: opacity);
        for (int i = 0; i < 8; i++) {
          final pOffset = Offset(random.nextDouble() * 40 - 20,
              random.nextDouble() * 40 - 20 + offset * 0.5);
          canvas.drawRect(
              Rect.fromCenter(center: center + pOffset, width: 4, height: 4),
              p);
          if (random.nextBool()) {
            canvas.drawRect(
                Rect.fromCenter(center: center + pOffset, width: 8, height: 1),
                Paint()..color = Colors.cyan.withValues(alpha: opacity * 0.5));
          }
        }
      }
    }
  }

  void _drawShadow(Canvas canvas) {
    final shadow = engine.activeShadow;
    if (shadow == null) return;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final glowPaint = Paint()
      ..color = Colors.deepPurpleAccent.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    for (int i = 0; i < shadow.segments.length; i++) {
      final rect = _cellRect(shadow.segments[i]);
      canvas.drawRect(rect.inflate(4), glowPaint);
      canvas.drawRect(rect, shadowPaint);

      // Glitch effect: occasional offset rect
      if (Random().nextDouble() < 0.1) {
        canvas.drawRect(
            rect.shift(Offset(Random().nextDouble() * 10 - 5,
                Random().nextDouble() * 10 - 5)),
            Paint()..color = Colors.cyanAccent.withValues(alpha: 0.3));
      }
    }
  }

  double _getPacmanStartAngle(Direction dir, double jawOffset) {
    final halfJaw = jawOffset / 2;
    switch (dir) {
      case Direction.right:
        return halfJaw;
      case Direction.down:
        return (pi / 2) + halfJaw;
      case Direction.left:
        return pi + halfJaw;
      case Direction.up:
        return (3 * pi / 2) + halfJaw;
    }
  }

  void _drawEyes(Canvas canvas, Rect rect,
      {Color? eyeColor, Color? glowColor}) {
    final eyeRadius = cellSize * 0.1;
    final eyePaint = Paint()..color = eyeColor ?? Colors.black;
    final glowPaint = Paint()..color = glowColor ?? Colors.white;

    double lx1, ly1, lx2, ly2;
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    const offset = 0.25;

    switch (engine.currentDirection) {
      case Direction.right:
        lx1 = cx + cellSize * 0.2;
        ly1 = cy - cellSize * offset;
        lx2 = cx + cellSize * 0.2;
        ly2 = cy + cellSize * offset;
        break;
      case Direction.left:
        lx1 = cx - cellSize * 0.2;
        ly1 = cy - cellSize * offset;
        lx2 = cx - cellSize * 0.2;
        ly2 = cy + cellSize * offset;
        break;
      case Direction.up:
        lx1 = cx - cellSize * offset;
        ly1 = cy - cellSize * 0.2;
        lx2 = cx + cellSize * offset;
        ly2 = cy - cellSize * 0.2;
        break;
      case Direction.down:
        lx1 = cx - cellSize * offset;
        ly1 = cy + cellSize * 0.2;
        lx2 = cx + cellSize * offset;
        ly2 = cy + cellSize * 0.2;
        break;
    }

    if (themeType == ThemeType.neon || themeType == ThemeType.arcade) {
      canvas.drawCircle(
          Offset(lx1, ly1),
          eyeRadius * 3,
          Paint()
            ..color = glowPaint.color
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawCircle(
          Offset(lx2, ly2),
          eyeRadius * 3,
          Paint()
            ..color = glowPaint.color
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    }

    canvas.drawCircle(Offset(lx1, ly1), eyeRadius * 1.5, glowPaint);
    canvas.drawCircle(Offset(lx2, ly2), eyeRadius * 1.5, glowPaint);
    canvas.drawCircle(Offset(lx1, ly1), eyeRadius, eyePaint);
    canvas.drawCircle(Offset(lx2, ly2), eyeRadius, eyePaint);
  }

  Rect _interpolatedRect(Position current, Position previous, double progress) {
    if ((current.x - previous.x).abs() > 1 ||
        (current.y - previous.y).abs() > 1) {
      return _cellRect(current);
    }
    double dx = previous.x + (current.x - previous.x) * progress;
    double dy = previous.y + (current.y - previous.y) * progress;
    return Rect.fromLTWH(dx * cellSize, dy * cellSize, cellSize, cellSize);
  }

  Rect _cellRect(Position pos) {
    return Rect.fromLTWH(
      pos.x * cellSize,
      pos.y * cellSize,
      cellSize,
      cellSize,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
