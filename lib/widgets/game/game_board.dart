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
    _drawGrid(canvas, size);
    if (engine.gameMode == GameMode.portal) {
      _drawTruePortals(canvas);
    }
    _drawObstacles(canvas);
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
    
    // Only draw fog if in cave/ruins, OR if cursed by Wraith's Eye
    if (!isCursed && biome != BiomeType.cave && biome != BiomeType.ruins) return;
    if (engine.snake.isEmpty) return;
    
    final head = engine.snake.first;
    final double progress = engine.movementProgress;
    final double smoothCamX = ui.lerpDouble(engine.prevCameraX.toDouble(), engine.cameraX.toDouble(), progress)!;
    final double smoothCamY = ui.lerpDouble(engine.prevCameraY.toDouble(), engine.cameraY.toDouble(), progress)!;
    
    final double headScreenX = (head.x - smoothCamX) * cellSize + cellSize / 2;
    final double headScreenY = (head.y - smoothCamY) * cellSize + cellSize / 2;
    final center = Offset(headScreenX, headScreenY);

    // Wraith's eye further restricts vision!
    final double visionRadius = isCursed ? cellSize * 4.0 : cellSize * 5.5; 
    final opacity = (biome == BiomeType.cave || isCursed) ? 0.95 : 0.85;

    final gradient = ui.Gradient.radial(
      center, 
      visionRadius, 
      [
        Colors.transparent,
        Colors.transparent,
        Colors.black.withOpacity(opacity),
        Colors.black.withOpacity(opacity)
      ],
      [0.0, 0.45, 1.0, 1.0]
    );

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

  void _drawTruePortals(Canvas canvas) {
    final colorsList = [
      const Color(0xFF00E5FF), // Cyan
      const Color(0xFFFF9100), // Orange
      const Color(0xFFAA00FF), // Purple
    ];

    for (final pos in engine.boardPortals.keys) {
      final rect = _cellRect(pos);
      final center = rect.center;
      final radius = (cellSize / 2) * (0.8 + pulse * 0.2);
      final idx = engine.portalIndices[pos] ?? 0;
      final portalColor = colorsList[idx % colorsList.length];

      canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = portalColor.withOpacity(0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawCircle(
          center,
          radius * 0.8,
          Paint()
            ..color = portalColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0);
      canvas.drawCircle(center, radius * 0.4, Paint()..color = Colors.black);
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    final double bgW = engine.gameMode == GameMode.explore
        ? engine.gridCols * cellSize
        : size.width;
    final double bgH = engine.gameMode == GameMode.explore
        ? engine.gridRows * cellSize
        : size.height;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, bgW, bgH),
      Paint()..color = colors.background,
    );

    // Draw biome tints for explore mode
    if (engine.gameMode == GameMode.explore && engine.roomBiomes.isNotEmpty) {
      const int bs = 10; // must match AppConstants block size
      const int roomRowCount = 11; // AppConstants.exploreGridRows / bs
      for (final entry in engine.roomBiomes.entries) {
        final rx = entry.key ~/ roomRowCount;
        final ry = entry.key % roomRowCount;
        final rect = Rect.fromLTWH(
          rx * bs * cellSize,
          ry * bs * cellSize,
          bs * cellSize,
          bs * cellSize,
        );
        canvas.drawRect(rect, Paint()..color = _biomeColor(entry.value));
      }
    }

    // Radial vignette for depth (all non-retro themes)
    if (themeType != ThemeType.retro) {
      final center = Offset(size.width / 2, size.height / 2);
      final maxRadius = size.longestSide * 0.75;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..shader = ui.Gradient.radial(center, maxRadius, [
            Colors.transparent,
            Colors.black.withOpacity(0.25),
          ], [
            0.4,
            1.0
          ]),
      );
    }

    // DRAW LCD MATRIX DOTS / GRID (Retro Only)
    if (themeType == ThemeType.retro) {
      final gridPaint = Paint()
        ..color = colors.gridLine.withOpacity(0.08)
        ..strokeWidth = 1.0;
      
      // Draw sub-pixel lines
      final subSize = cellSize / 4;
      for (double x = 0; x < size.width; x += subSize) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
      for (double y = 0; y < size.height; y += subSize) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
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
        Paint()..color = colors.snakeBody.withOpacity(opacity),
      );
    }
  }

  void _drawEvents(Canvas canvas, Size size) {
    if (engine.activeEvent == BoardEvent.none) return;

    if (engine.activeEvent == BoardEvent.iceBoard) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..color = const Color(0xFF00FFFF).withOpacity(0.15)
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
    final spikeColor = isActive ? const Color(0xFFFF1744) : Colors.white10;
    
    for (final pos in engine.spikeTraps) {
      final rect = _cellRect(pos);
      final center = rect.center;
      
      // Draw base plate
      canvas.drawRect(
        rect.deflate(1.0),
        Paint()..color = Colors.black.withOpacity(0.4),
      );
      
      if (isActive) {
        // Glowing aura for active spikes
        canvas.drawCircle(
          center,
          cellSize * 0.7,
          Paint()
            ..color = spikeColor.withOpacity(0.2 * (0.8 + pulse * 0.4))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
        
        // Spike blades (X pattern)
        final spikePaint = Paint()
          ..color = spikeColor
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;
          
        final offset = cellSize * 0.3;
        canvas.drawLine(center + Offset(-offset, -offset), center + Offset(offset, offset), spikePaint);
        canvas.drawLine(center + Offset(offset, -offset), center + Offset(-offset, offset), spikePaint);
        
        // Center core glow
        canvas.drawCircle(center, 2.0, Paint()..color = Colors.white);
      } else {
        // Retracted dim spikes
        final dimPaint = Paint()
          ..color = Colors.white24
          ..strokeWidth = 1.0;
        final offset = cellSize * 0.2;
        canvas.drawLine(center + Offset(-offset, -offset), center + Offset(offset, offset), dimPaint);
        canvas.drawLine(center + Offset(offset, -offset), center + Offset(-offset, offset), dimPaint);
      }
    }
  }

  void _drawObstacles(Canvas canvas) {
    for (final obs in engine.obstacleSet) {
      final rect = _cellRect(obs);
      switch (themeType) {
        case ThemeType.retro:
          // Solid dark brick with an X pattern for Retro - matches original Nokia 3310 Maze
          final paint = Paint()..color = colors.snakeHead;
          canvas.drawRect(rect.deflate(1.0), paint);
          // Simple X cross to differentiate from body
          final xPaint = Paint()
            ..color = colors.background
            ..strokeWidth = 1.0;
          canvas.drawLine(rect.topLeft + const Offset(4, 4),
              rect.bottomRight - const Offset(4, 4), xPaint);
          canvas.drawLine(rect.topRight + const Offset(-4, 4),
              rect.bottomLeft - const Offset(-4, -4), xPaint);
          break;
        case ThemeType.neon:
          // Bright, dangerous warning grid
          const hazardColor = Color(0xFFFF3300); // Danger red/orange
          canvas.drawRect(
            rect.deflate(2.0),
            Paint()
              ..color = hazardColor.withOpacity(0.3)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
          );
          canvas.drawRect(
            rect.deflate(2.0),
            Paint()
              ..color = hazardColor.withOpacity(0.8)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
          // Small X inside
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
          // Solid geometric rock/stone
          final rrect = RRect.fromRectAndRadius(
              rect.deflate(0.5), const Radius.circular(4));
          // Shadow/Base
          canvas.drawRRect(rrect, Paint()..color = const Color(0xFF1B2631));
          // Highlight
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  rect.deflate(1.5), const Radius.circular(3)),
              Paint()..color = const Color(0xFF2C3E50));
          break;
        case ThemeType.arcade:
          // Glowing classic red barrier
          canvas.drawRect(
              rect.deflate(1.0),
              Paint()
                ..color = const Color(0xFFFF0000)
                ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3));
          canvas.drawRect(
              rect.deflate(3.0), Paint()..color = const Color(0xFF990000));
          break;
        case ThemeType.cyber:
          // Glowing Matrix-green tech block
          canvas.drawRect(
              rect.deflate(2.0), Paint()..color = const Color(0xFF003B00));
          canvas.drawRect(
              rect.deflate(4.0),
              Paint()
                ..color = const Color(0xFF00FF41)
                ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2));
          break;
        case ThemeType.volcano:
          // Rough obsidian block with lave core
          canvas.drawRect(
              rect.deflate(1.0), Paint()..color = const Color(0xFF1A0505));
          canvas.drawRect(
              rect.deflate(4.0),
              Paint()
                ..color = const Color(0xFFFF4500)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
          break;
        case ThemeType.ice:
          // Frost-glazed ice block with cyan glow
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
        ..color = Colors.amber.withOpacity(0.35 + pulse * 0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + pulse * 4);
      canvas.drawCircle(center, radius * 1.6, bossOuter);
      // Inner skull/crown body
      canvas.drawCircle(
          center, radius * 1.1, Paint()..color = const Color(0xFFFFCC00));
      canvas.drawCircle(
          center, radius * 0.6, Paint()..color = const Color(0xFFFF6600));
      // Spinning dash ring
      final dashPaint = Paint()
        ..color = Colors.white.withOpacity(0.8)
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
          Paint()..color = Colors.white.withOpacity(0.9));
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
            ..color = baseColor.withOpacity(0.15 + pulse * 0.1)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
      // Mid bloom
      canvas.drawCircle(
          center,
          radius * 1.4,
          Paint()
            ..color = baseColor.withOpacity(0.55)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      // Core
      canvas.drawCircle(center, radius, Paint()..color = baseColor);
      // Specular highlight
      canvas.drawCircle(
          Offset(center.dx - radius * 0.3, center.dy - radius * 0.3),
          radius * 0.3,
          Paint()..color = Colors.white.withOpacity(0.75));
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
            ..color = baseColor.withOpacity(0.2 + pulse * 0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      // Semi-transparent fill
      canvas.drawPath(path, Paint()..color = baseColor.withOpacity(0.22));
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
            ..color = baseColor.withOpacity(0.2 + pulse * 0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      // Mid-ring
      canvas.drawCircle(
          center,
          radius * 1.3,
          Paint()
            ..color = baseColor.withOpacity(0.55)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      // Core fill
      canvas.drawCircle(center, radius, Paint()..color = baseColor);
      // Hot white centre
      canvas.drawCircle(center, radius * 0.45,
          Paint()..color = Colors.white.withOpacity(0.6 + pulse * 0.2));
      return;
    }

    if (themeType == ThemeType.ice) {
      // Frosty berry with icy bloom
      canvas.drawCircle(
          center,
          radius * 2.0,
          Paint()
            ..color = baseColor.withOpacity(0.15 + pulse * 0.1)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
      // Mid glow
      canvas.drawCircle(
          center,
          radius * 1.2,
          Paint()
            ..color = baseColor.withOpacity(0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      // Core
      canvas.drawCircle(center, radius, Paint()..color = baseColor);
      // Ice-crystal specular
      canvas.drawCircle(
          Offset(center.dx - radius * 0.3, center.dy - radius * 0.3),
          radius * 0.3,
          Paint()..color = Colors.white.withOpacity(0.85));
      return;
    }
  }

  Color _biomeColor(BiomeType biome) {
    switch (biome) {
      case BiomeType.forest:
        return const Color(0xFF00FF00).withOpacity(0.06);
      case BiomeType.desert:
        return const Color(0xFFFF8C00).withOpacity(0.07);
      case BiomeType.swamp:
        return const Color(0xFF008080).withOpacity(0.08);
      case BiomeType.cave:
        return const Color(0xFF4B0082).withOpacity(0.10);
      case BiomeType.ruins:
        return const Color(0xFF808080).withOpacity(0.08);
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
      case FoodType.portal:
        _drawPortal(canvas, prey);
        break;
      case FoodType.shrine:
        _drawShrine(canvas, prey);
        break;
      default:
        _drawMouse(canvas, prey);
    }
  }

  void _drawPortal(Canvas canvas, FoodModel prey) {
    final center = _cellRect(prey.position).center;
    final r = (cellSize / 2) * (0.8 + pulse * 0.2);
    canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = Colors.deepPurpleAccent.withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawCircle(
        center,
        r * 0.8,
        Paint()
          ..color = Colors.deepPurpleAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0);
    canvas.drawCircle(center, r * 0.4, Paint()..color = Colors.black87);
  }

  void _drawShrine(Canvas canvas, FoodModel prey) {
    final center = _cellRect(prey.position).center;
    final r = (cellSize / 2) * (0.8 + pulse * 0.1);
    
    // Base stone
    canvas.drawRect(
        Rect.fromCenter(center: center, width: r * 2, height: r * 2),
        Paint()..color = Colors.grey[800]!
    );
    
    // Glowing red runes/pentagram
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = i * 4 * pi / 5 - pi / 2;
      final px = center.dx + r * 0.8 * cos(angle);
      final py = center.dy + r * 0.8 * sin(angle);
      if (i == 0) path.moveTo(px, py);
      else path.lineTo(px, py);
    }
    path.close();
    
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.redAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2)
    );
    
    // Core blood gem
    canvas.drawCircle(center, r * 0.3, Paint()..color = Colors.red);
  }

  void _drawMouse(Canvas canvas, FoodModel prey) {
    final center = _cellRect(prey.position).center;
    final r = cellSize * (0.24 + pulse * 0.03);
    const color = Color(0xFFBDBDBD);
    canvas.drawCircle(
        center,
        r * 1.6,
        Paint()
          ..color = color.withOpacity(0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawCircle(center, r, Paint()..color = color);
    // Ears
    for (final xOff in [-0.75, 0.75]) {
      canvas.drawCircle(center + Offset(xOff * r, -r * 0.85), r * 0.38,
          Paint()..color = color);
      canvas.drawCircle(center + Offset(xOff * r, -r * 0.85), r * 0.18,
          Paint()..color = Colors.pink.withOpacity(0.7));
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
          ..color = Colors.white.withOpacity(0.18 + pulse * 0.12)
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
    final color = const Color(0xFF66BB6A).withOpacity(opacity);
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
        Paint()..color = Colors.red.withOpacity(isHiding ? 0.4 : 1.0));
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
            ..color =
                wingColors[(side + 1) ~/ 2].withOpacity(0.7 + pulse * 0.2));
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
          ..color = Colors.white.withOpacity(0.6)
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
              ..color = Colors.amber.withOpacity(0.4 + pulse * 0.4)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0);
      }
    }
  }

  void _drawPowerUps(Canvas canvas) {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final pu in engine.boardPowerUps) {
      if (pu.isExpired(now)) continue;
      final rect = _cellRect(pu.position);
      final center = rect.center;
      final r = (cellSize / 2) * (0.8 + pulse * 0.1);

      if (themeType == ThemeType.neon) {
        canvas.drawCircle(
            center, r * 1.6, Paint()..color = colors.powerUp.withOpacity(0.25));
      }

      // Background circle
      canvas.drawCircle(
        center,
        r,
        Paint()..color = colors.powerUp.withOpacity(0.85),
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
              .withOpacity(opacity);
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
            Paint()..color = Colors.white.withOpacity(0.3 * opacity));
        canvas.drawCircle(rect.center, cellSize * 0.2,
            Paint()..color = Colors.lightBlueAccent.withOpacity(0.5 * opacity));
      } else if (skin == SnakeSkin.skeleton) {
        canvas.drawRect(
            Rect.fromCenter(
                center: rect.center,
                width: cellSize * 0.6,
                height: cellSize * 0.2),
            Paint()..color = Colors.white.withOpacity(opacity));
        canvas.drawRect(
            Rect.fromCenter(
                center: rect.center,
                width: cellSize * 0.2,
                height: cellSize * 0.6),
            Paint()..color = Colors.white.withOpacity(opacity));
      } else if (skin == SnakeSkin.robot) {
        canvas.drawRect(rect.deflate(1.0),
            Paint()..color = Colors.grey[700]!.withOpacity(opacity));
        canvas.drawRect(rect.deflate(3.0),
            Paint()..color = Colors.cyanAccent.withOpacity(opacity));
      } else if (skin == SnakeSkin.rainbow) {
        final rbColor = HSLColor.fromAHSL(
                1.0,
                ((i * 15.0) + (DateTime.now().millisecondsSinceEpoch / 5)) %
                    360,
                1.0,
                0.5)
            .toColor();
        canvas.drawCircle(rect.center, cellSize * 0.5,
            Paint()..color = rbColor.withOpacity(opacity));
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
                ..color = bodyColor.withOpacity(0.6)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
          // Core bright segment
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  rect.deflate(1.0), Radius.circular(cellSize * 0.3)),
              Paint()..color = Colors.white.withOpacity(opacity * 0.9));
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
              Paint()..color = Colors.white.withOpacity(0.12 * opacity));
        }
      }
    }

    // Draw head
    Position headPrev = snake.length > 1 ? snake[1] : snake.first;
    final headRect = _interpolatedRect(snake.first, headPrev, progress);
    final headColor = colors.snakeHead.withOpacity(opacity);

    if (skin == SnakeSkin.ghost) {
      canvas.drawCircle(headRect.center, cellSize * 0.5,
          Paint()..color = Colors.white.withOpacity(0.5 * opacity));
      _drawEyes(canvas, headRect, eyeColor: Colors.lightBlueAccent);
      return;
    } else if (skin == SnakeSkin.skeleton) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              headRect.deflate(2.0), const Radius.circular(4)),
          Paint()..color = Colors.white.withOpacity(opacity));
      _drawEyes(canvas, headRect, eyeColor: Colors.black);
      return;
    } else if (skin == SnakeSkin.robot) {
      canvas.drawRect(headRect.deflate(1.0),
          Paint()..color = Colors.black.withOpacity(opacity));
      canvas.drawRect(headRect.deflate(3.0),
          Paint()..color = Colors.grey[400]!.withOpacity(opacity));
      _drawEyes(canvas, headRect, eyeColor: Colors.redAccent);
      return;
    } else if (skin == SnakeSkin.rainbow) {
      final rbColor = HSLColor.fromAHSL(
              1.0, (DateTime.now().millisecondsSinceEpoch / 5) % 360, 1.0, 0.5)
          .toColor();
      canvas.drawRect(
          headRect.deflate(1.0), Paint()..color = rbColor.withOpacity(opacity));
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
            ..color = headColor.withOpacity(0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      // Bright core
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              headRect.deflate(0.5), Radius.circular(cellSize * 0.35)),
          Paint()..color = Colors.white.withOpacity(opacity));
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
    if (engine.trail.isEmpty) return;

    final trailColor = colors.snakeTail.withOpacity(0.35);
    for (int i = 0; i < engine.trail.length; i++) {
      final opacity = (0.35 * (1 - (i / engine.trail.length))).clamp(0.0, 1.0);
      final rect = _cellRect(engine.trail[i]);

      if (themeType == ThemeType.neon) {
        canvas.drawRect(
          rect,
          Paint()
            ..color = colors.accent.withOpacity(opacity)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
      } else {
        canvas.drawCircle(
          rect.center,
          cellSize * 0.35 * (1 - (i / engine.trail.length)),
          Paint()..color = trailColor.withOpacity(opacity),
        );
      }
    }
  }

  void _drawGhost(Canvas canvas) {
    if (engine.ghostPath.isEmpty ||
        engine.ghostIndex >= engine.ghostPath.length) return;

    final ghostPos = engine.ghostPath[engine.ghostIndex];
    final rect = _cellRect(ghostPos);

    final ghostPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(rect.center, cellSize * 0.6, ghostPaint);
    canvas.drawCircle(rect.center, cellSize * 0.4,
        Paint()..color = Colors.cyanAccent.withOpacity(0.2));

    // Draw "PB" text on ghost
    final tp = TextPainter(
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
    tp.paint(canvas,
        Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2));
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
              color: Colors.white.withOpacity(opacity),
              fontSize: 14 + (pulse * 2),
              fontWeight: FontWeight.w900,
              fontFamily: 'Orbitron',
              shadows: [
                Shadow(
                    color: Colors.black.withOpacity(opacity),
                    blurRadius: 4,
                    offset: const Offset(2, 2)),
                Shadow(
                    color: Colors.orange.withOpacity(opacity * 0.5),
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
        final p = Paint()..color = Colors.deepPurpleAccent.withOpacity(opacity);
        for (int i = 0; i < 8; i++) {
          final pOffset = Offset(random.nextDouble() * 40 - 20,
              random.nextDouble() * 40 - 20 + offset * 0.5);
          canvas.drawRect(
              Rect.fromCenter(center: center + pOffset, width: 4, height: 4),
              p);
          if (random.nextBool()) {
            canvas.drawRect(
                Rect.fromCenter(center: center + pOffset, width: 8, height: 1),
                Paint()..color = Colors.cyan.withOpacity(opacity * 0.5));
          }
        }
      }
    }
  }

  void _drawShadow(Canvas canvas) {
    final shadow = engine.activeShadow;
    if (shadow == null) return;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final glowPaint = Paint()
      ..color = Colors.deepPurpleAccent.withOpacity(0.4)
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
            Paint()..color = Colors.cyanAccent.withOpacity(0.3));
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
  bool shouldRepaint(covariant _SnakePainter old) => true;
}
