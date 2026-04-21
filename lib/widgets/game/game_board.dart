import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/direction.dart';
import '../../core/enums/game_mode.dart';

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

  const GameBoard({super.key, required this.engine, required this.themeType, this.skin = SnakeSkin.classic});

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
      case ThemeType.retro: return AppThemeColors.retro;
      case ThemeType.neon: return AppThemeColors.neon;
      case ThemeType.nature: return AppThemeColors.nature;
      case ThemeType.arcade: return AppThemeColors.arcade;
      case ThemeType.cyber: return AppThemeColors.cyber;
      case ThemeType.volcano: return AppThemeColors.volcano;
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
                final cellW = constraints.maxWidth / AppConstants.gridColumns;
                final cellH = constraints.maxHeight / AppConstants.gridRows;
                final cellSize = min(cellW, cellH);

                return RepaintBoundary(
                  child: CustomPaint(
                    size: Size(
                      cellSize * AppConstants.gridColumns,
                      cellSize * AppConstants.gridRows,
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
    _drawEffects(canvas);
    _drawShadow(canvas);
    _drawEvents(canvas, size);
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

      canvas.drawCircle(center, radius, Paint()..color = portalColor.withOpacity(0.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawCircle(center, radius * 0.8, Paint()..color = portalColor..style = PaintingStyle.stroke..strokeWidth = 2.0);
      canvas.drawCircle(center, radius * 0.4, Paint()..color = Colors.black);
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = colors.background,
    );

    // DRAW LCD MATRIX DOTS (Retro Only)
    if (themeType == ThemeType.retro) {
      final dotPaint = Paint()..color = colors.gridLine.withOpacity(0.4);
      const dotSize = 1.0;
      final spacing = cellSize / 5; // 5 sub-pixels per cell

      for (double x = 0; x < size.width; x += spacing) {
        for (double y = 0; y < size.height; y += spacing) {
          canvas.drawCircle(Offset(x + spacing/2, y + spacing/2), dotSize/2, dotPaint);
        }
      }
    }
  }
  
  void _drawEvents(Canvas canvas, Size size) {
    if (engine.activeEvent == BoardEvent.none) return;

    if (engine.activeEvent == BoardEvent.iceBoard) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFF00FFFF).withOpacity(0.15)
               ..blendMode = BlendMode.srcOver,
      );
    } else if (engine.activeEvent == BoardEvent.lightsOut && engine.snake.isNotEmpty) {
      final headCenter = _cellRect(engine.snake.first).center;
      
      final gradient = ui.Gradient.radial(
        headCenter,
        cellSize * 5,
        [
          Colors.transparent,
          Colors.black87,
          Colors.black,
        ],
        [0.0, 0.4, 1.0]
      );
      
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..shader = gradient,
      );
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    if (themeType == ThemeType.retro || themeType == ThemeType.nature) return;

    if (themeType == ThemeType.arcade) {
      final paint = Paint()
        ..color = colors.gridLine
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      
      for (int x = 0; x <= AppConstants.gridColumns; x++) {
        for (int y = 0; y <= AppConstants.gridRows; y++) {
          canvas.drawPoints(ui.PointMode.points, [Offset(x * cellSize, y * cellSize)], paint);
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

    for (int x = 0; x <= AppConstants.gridColumns; x++) {
      canvas.drawLine(
        Offset(x * cellSize, 0),
        Offset(x * cellSize, size.height),
        paint,
      );
    }
    for (int y = 0; y <= AppConstants.gridRows; y++) {
      canvas.drawLine(
        Offset(0, y * cellSize),
        Offset(size.width, y * cellSize),
        paint,
      );
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
          final xPaint = Paint()..color = colors.background..strokeWidth = 1.0;
          canvas.drawLine(rect.topLeft + const Offset(4, 4), rect.bottomRight - const Offset(4, 4), xPaint);
          canvas.drawLine(rect.topRight + const Offset(-4, 4), rect.bottomLeft - const Offset(-4, -4), xPaint);
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
          canvas.drawLine(rect.topLeft + const Offset(4, 4), rect.bottomRight - const Offset(4, 4), Paint()..color=hazardColor..strokeWidth=1);
          canvas.drawLine(rect.topRight + const Offset(-4, 4), rect.bottomLeft - const Offset(-4, -4), Paint()..color=hazardColor..strokeWidth=1);
          break;
        case ThemeType.nature:
          // Solid geometric rock/stone
          final rrect = RRect.fromRectAndRadius(rect.deflate(0.5), const Radius.circular(4));
          // Shadow/Base
          canvas.drawRRect(rrect, Paint()..color = const Color(0xFF1B2631)); 
          // Highlight
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect.deflate(1.5), const Radius.circular(3)), 
            Paint()..color = const Color(0xFF2C3E50)
          );
          break;
        case ThemeType.arcade:
          // Glowing classic red barrier
          canvas.drawRect(
             rect.deflate(1.0),
             Paint()..color = const Color(0xFFFF0000)..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3)
          );
          canvas.drawRect(
             rect.deflate(3.0),
             Paint()..color = const Color(0xFF990000)
          );
          break;
        case ThemeType.cyber:
          // Glowing Matrix-green tech block
          canvas.drawRect(rect.deflate(2.0), Paint()..color = const Color(0xFF003B00));
          canvas.drawRect(rect.deflate(4.0), Paint()..color = const Color(0xFF00FF41)..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2));
          break;
        case ThemeType.volcano:
          // Rough obsidian block with lave core
          canvas.drawRect(rect.deflate(1.0), Paint()..color = const Color(0xFF1A0505));
          canvas.drawRect(rect.deflate(4.0), Paint()..color = const Color(0xFFFF4500)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
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
      
      canvas.drawRect(rect.deflate(cellSize * 0.1), Paint()..color = baseColor..style = PaintingStyle.stroke..strokeWidth = cellSize * 0.15);
      if (isGolden) {
        canvas.drawRect(rect.deflate(cellSize * 0.25), Paint()..color = baseColor);
      } else {
        canvas.drawRect(rect.deflate(cellSize * 0.35), Paint()..color = baseColor);
      }
      return;
    }

    if (themeType == ThemeType.neon) {
      // Intense Bloom
      canvas.drawCircle(center, radius * 1.5, Paint()..color = baseColor..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      canvas.drawCircle(center, radius, Paint()..color = baseColor);
      canvas.drawCircle(Offset(center.dx - radius * 0.3, center.dy - radius * 0.3), radius * 0.25, Paint()..color = Colors.white.withOpacity(0.6));
      return;
    }

    if (themeType == ThemeType.nature) {
      // Berry with a leaf
      canvas.drawCircle(center, radius, Paint()..color = baseColor);
      if (!isPoison) {
        final path = Path()
          ..moveTo(center.dx, center.dy - radius)
          ..quadraticBezierTo(center.dx - cellSize*0.2, center.dy - radius - cellSize*0.2, center.dx + cellSize*0.1, center.dy - radius - cellSize*0.3)
          ..quadraticBezierTo(center.dx + cellSize*0.2, center.dy - radius - cellSize*0.1, center.dx, center.dy - radius);
        canvas.drawPath(path, Paint()..color = const Color(0xFF4CAF50));
      }
      return;
    }

    if (themeType == ThemeType.arcade) {
      // Classic Cherry
      canvas.drawCircle(center, radius, Paint()..color = baseColor);
      if (!isPoison) {
        canvas.drawRect(Rect.fromLTWH(center.dx, center.dy - radius - 2, 2, 6), Paint()..color = const Color(0xFF00FF00)); // Stem
      }
      return;
    }

    if (themeType == ThemeType.cyber) {
      // Digital Hexagon / Cube
      final path = Path();
      for (int i = 0; i < 6; i++) {
        double angle = i * pi / 3;
        double px = center.dx + radius * cos(angle);
        double py = center.dy + radius * sin(angle);
        if (i == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }
      path.close();
      canvas.drawPath(path, Paint()..color = baseColor..style = PaintingStyle.stroke..strokeWidth = 2);
      canvas.drawCircle(center, radius * 0.4, Paint()..color = baseColor);
      return;
    }

    if (themeType == ThemeType.volcano) {
      // Molten core
      canvas.drawCircle(center, radius * 1.2, Paint()..color = baseColor.withOpacity(0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      canvas.drawCircle(center, radius, Paint()..color = baseColor);
      canvas.drawCircle(center, radius * 0.6, Paint()..color = Colors.yellow.withOpacity(0.7));
      return;
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
        canvas.drawCircle(center, r * 1.6,
            Paint()..color = colors.powerUp.withOpacity(0.25));
      }

      // Background circle
      canvas.drawCircle(
        center, r,
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
      final bodyColor = Color.lerp(colors.snakeTail, colors.snakeBody, colorProgress)!.withOpacity(opacity);
      Position prevPos = (i + 1 < snake.length) ? snake[i + 1] : (engine.trail.isNotEmpty ? engine.trail.first : snake[i]);
      final rect = _interpolatedRect(snake[i], prevPos, progress);

      if (skin == SnakeSkin.ghost) {
        canvas.drawCircle(rect.center, cellSize * 0.45, Paint()..color = Colors.white.withOpacity(0.3 * opacity));
        canvas.drawCircle(rect.center, cellSize * 0.2, Paint()..color = Colors.lightBlueAccent.withOpacity(0.5 * opacity));
      } else if (skin == SnakeSkin.skeleton) {
        canvas.drawRect(Rect.fromCenter(center: rect.center, width: cellSize * 0.6, height: cellSize * 0.2), Paint()..color = Colors.white.withOpacity(opacity));
        canvas.drawRect(Rect.fromCenter(center: rect.center, width: cellSize * 0.2, height: cellSize * 0.6), Paint()..color = Colors.white.withOpacity(opacity));
      } else if (skin == SnakeSkin.robot) {
        canvas.drawRect(rect.deflate(1.0), Paint()..color = Colors.grey[700]!.withOpacity(opacity));
        canvas.drawRect(rect.deflate(3.0), Paint()..color = Colors.cyanAccent.withOpacity(opacity));
      } else if (skin == SnakeSkin.rainbow) {
        final rbColor = HSLColor.fromAHSL(1.0, ((i * 15.0) + (DateTime.now().millisecondsSinceEpoch / 5)) % 360, 1.0, 0.5).toColor();
        canvas.drawCircle(rect.center, cellSize * 0.5, Paint()..color = rbColor.withOpacity(opacity));
      } else {
        if (themeType == ThemeType.retro) {
          canvas.drawRect(rect.deflate(1.5), Paint()..color = bodyColor);
        } else if (themeType == ThemeType.nature) {
          canvas.drawCircle(rect.center, cellSize * 0.5, Paint()..color = bodyColor);
        } else if (themeType == ThemeType.arcade) {
          canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(1.0), const Radius.circular(2)), Paint()..color = bodyColor);
        } else if (themeType == ThemeType.neon) {
          canvas.drawRect(rect.inflate(0.5), Paint()..color = bodyColor..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
          canvas.drawRect(rect, Paint()..color = Colors.white.withOpacity(opacity * 0.8));
        }
      }
    }

    // Draw head
    Position headPrev = snake.length > 1 ? snake[1] : snake.first;
    final headRect = _interpolatedRect(snake.first, headPrev, progress);
    final headColor = colors.snakeHead.withOpacity(opacity);

    if (skin == SnakeSkin.ghost) {
      canvas.drawCircle(headRect.center, cellSize * 0.5, Paint()..color = Colors.white.withOpacity(0.5 * opacity));
      _drawEyes(canvas, headRect, eyeColor: Colors.lightBlueAccent);
      return;
    } else if (skin == SnakeSkin.skeleton) {
      canvas.drawRRect(RRect.fromRectAndRadius(headRect.deflate(2.0), const Radius.circular(4)), Paint()..color = Colors.white.withOpacity(opacity));
      _drawEyes(canvas, headRect, eyeColor: Colors.black);
      return;
    } else if (skin == SnakeSkin.robot) {
      canvas.drawRect(headRect.deflate(1.0), Paint()..color = Colors.black.withOpacity(opacity));
      canvas.drawRect(headRect.deflate(3.0), Paint()..color = Colors.grey[400]!.withOpacity(opacity));
      _drawEyes(canvas, headRect, eyeColor: Colors.redAccent);
      return;
    } else if (skin == SnakeSkin.rainbow) {
      final rbColor = HSLColor.fromAHSL(1.0, (DateTime.now().millisecondsSinceEpoch / 5) % 360, 1.0, 0.5).toColor();
      canvas.drawRect(headRect.deflate(1.0), Paint()..color = rbColor.withOpacity(opacity));
      _drawEyes(canvas, headRect);
      return;
    }

    if (themeType == ThemeType.retro) {
       canvas.drawRect(headRect.deflate(1.5), Paint()..color = headColor);
       return;
    }

    if (themeType == ThemeType.neon) {
       canvas.drawRect(headRect.inflate(1.0), Paint()..color = headColor..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
       canvas.drawRect(headRect.inflate(0.5), Paint()..color = Colors.white.withOpacity(opacity));
       return;
    }

    if (themeType == ThemeType.nature) {
       canvas.drawCircle(headRect.center, cellSize * 0.55, Paint()..color = headColor);
       _drawEyes(canvas, headRect);
       return;
    }

    if (themeType == ThemeType.arcade) {
       final jawOffset = 1.0 * pulse;
       final sweepAngle = (2 * pi) - jawOffset;
       final startAngle = _getPacmanStartAngle(engine.currentDirection, jawOffset);
       
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
    if (engine.ghostPath.isEmpty || engine.ghostIndex >= engine.ghostPath.length) return;
    
    final ghostPos = engine.ghostPath[engine.ghostIndex];
    final rect = _cellRect(ghostPos);
    
    final ghostPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      
    canvas.drawCircle(rect.center, cellSize * 0.6, ghostPaint);
    canvas.drawCircle(rect.center, cellSize * 0.4, Paint()..color = Colors.cyanAccent.withOpacity(0.2));
    
    // Draw "PB" text on ghost
    final tp = TextPainter(
      text: const TextSpan(
        text: 'PB',
        style: TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'Orbitron'),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2));
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
                Shadow(color: Colors.black.withOpacity(opacity), blurRadius: 4, offset: const Offset(2, 2)),
                Shadow(color: Colors.orange.withOpacity(opacity * 0.5), blurRadius: 10),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        
        tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2 - offset));
      } else if (effect.type == EffectType.shadowPoof) {
        // Draw glitchy poof particles
        final random = Random(effect.startTimeMs);
        final p = Paint()..color = Colors.deepPurpleAccent.withOpacity(opacity);
        for (int i = 0; i < 8; i++) {
          final pOffset = Offset(random.nextDouble() * 40 - 20, random.nextDouble() * 40 - 20 + offset * 0.5);
          canvas.drawRect(Rect.fromCenter(center: center + pOffset, width: 4, height: 4), p);
          if (random.nextBool()) {
             canvas.drawRect(Rect.fromCenter(center: center + pOffset, width: 8, height: 1), Paint()..color = Colors.cyan.withOpacity(opacity * 0.5));
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
          rect.shift(Offset(Random().nextDouble()*10-5, Random().nextDouble()*10-5)),
          Paint()..color = Colors.cyanAccent.withOpacity(0.3)
        );
      }
    }
  }

  double _getPacmanStartAngle(Direction dir, double jawOffset) {
    final halfJaw = jawOffset / 2;
    switch (dir) {
      case Direction.right: return halfJaw;
      case Direction.down: return (pi / 2) + halfJaw;
      case Direction.left: return pi + halfJaw;
      case Direction.up: return (3 * pi / 2) + halfJaw;
    }
  }

  void _drawEyes(Canvas canvas, Rect rect, {Color? eyeColor, Color? glowColor}) {
    final eyeRadius = cellSize * 0.1;
    final eyePaint = Paint()..color = eyeColor ?? Colors.black;
    final glowPaint = Paint()..color = glowColor ?? Colors.white;

    double lx1, ly1, lx2, ly2;
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    const offset = 0.25;

    switch (engine.currentDirection) {
      case Direction.right:
        lx1 = cx + cellSize * 0.2; ly1 = cy - cellSize * offset;
        lx2 = cx + cellSize * 0.2; ly2 = cy + cellSize * offset;
        break;
      case Direction.left:
        lx1 = cx - cellSize * 0.2; ly1 = cy - cellSize * offset;
        lx2 = cx - cellSize * 0.2; ly2 = cy + cellSize * offset;
        break;
      case Direction.up:
        lx1 = cx - cellSize * offset; ly1 = cy - cellSize * 0.2;
        lx2 = cx + cellSize * offset; ly2 = cy - cellSize * 0.2;
        break;
      case Direction.down:
        lx1 = cx - cellSize * offset; ly1 = cy + cellSize * 0.2;
        lx2 = cx + cellSize * offset; ly2 = cy + cellSize * 0.2;
        break;
    }

    if (themeType == ThemeType.neon || themeType == ThemeType.arcade) {
      canvas.drawCircle(Offset(lx1, ly1), eyeRadius * 3, Paint()..color = glowPaint.color..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawCircle(Offset(lx2, ly2), eyeRadius * 3, Paint()..color = glowPaint.color..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    }
    
    canvas.drawCircle(Offset(lx1, ly1), eyeRadius * 1.5, glowPaint);
    canvas.drawCircle(Offset(lx2, ly2), eyeRadius * 1.5, glowPaint);
    canvas.drawCircle(Offset(lx1, ly1), eyeRadius, eyePaint);
    canvas.drawCircle(Offset(lx2, ly2), eyeRadius, eyePaint);
  }

  Rect _interpolatedRect(Position current, Position previous, double progress) {
    if ((current.x - previous.x).abs() > 1 || (current.y - previous.y).abs() > 1) {
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
