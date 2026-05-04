import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/enums/theme_type.dart';

class DynamicBackground extends StatefulWidget {
  final Widget child;
  final ThemeType themeType;

  const DynamicBackground({
    super.key,
    required this.child,
    required this.themeType,
  });

  @override
  State<DynamicBackground> createState() => _DynamicBackgroundState();
}

class _DynamicBackgroundState extends State<DynamicBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
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
    return Stack(
      children: [
        // Base color
        Container(color: colors.background),

        // Animated layer
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _BackgroundPainter(
                    themeType: widget.themeType,
                    colors: colors,
                    progress: _controller.value,
                  ),
                );
              },
            ),
          ),
        ),

        // Foreground content
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final ThemeType themeType;
  final AppThemeColors colors;
  final double progress;

  _BackgroundPainter({
    required this.themeType,
    required this.colors,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (themeType) {
      case ThemeType.retro:
        _paintRetro(canvas, size);
        break;
      case ThemeType.neon:
        _paintNeon(canvas, size);
        break;
      case ThemeType.nature:
        _paintNature(canvas, size);
        break;
      case ThemeType.arcade:
        _paintArcade(canvas, size);
        break;
      case ThemeType.cyber:
        _paintCyber(canvas, size);
        break;
      case ThemeType.volcano:
        _paintVolcano(canvas, size);
        break;
      case ThemeType.ice:
        _paintIce(canvas, size);
        break;
    }

    if (themeType != ThemeType.retro) {
      _paintRoamingSnake(canvas, size);
    }
  }

  void _paintRoamingSnake(Canvas canvas, Size size) {
    final double speed = 0.05;
    final double pathProgress = (progress * speed) % 1.0;
    final double yBase = size.height * 0.45;
    
    final double startX = -size.width * 0.5;
    final double endX = size.width * 1.5;
    final double currentX = startX + (endX - startX) * pathProgress;

    // Draw 12 body segments for a full snake look
    for (int i = 12; i >= 0; i--) {
      final double x = currentX - (i * 14);
      final double y = yBase + sin(progress * pi * 2 + x * 0.01) * 45;
      
      final double opacity = (0.12 * (1.0 - (i / 15.0))).clamp(0.0, 1.0);
      final double radius = i == 0 ? 9.0 : 8.0 - (i * 0.3);
      
      final paint = Paint()
        ..color = colors.accent.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
        
      if (i == 0) {
        // Head glow
        canvas.drawCircle(
          Offset(x, y),
          radius + 4,
          Paint()
            ..color = colors.accent.withValues(alpha: 0.1)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  void _paintRetro(Canvas canvas, Size size) {
    // base fill
    canvas.drawRect(Offset.zero & size, Paint()..color = colors.background);

    // subtle sub-pixel grid
    final gridPaint = Paint()
      ..color = colors.snakeHead.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 12) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 12) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Scanlines
    final scanPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scanPaint);
    }

    // Soft center glow vs edge darkening
    final Rect rect = Offset.zero & size;
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.2,
      colors: [
        Colors.white.withValues(alpha: 0.05),
        colors.snakeHead.withValues(alpha: 0.12),
      ],
    );
    final vignettePaint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, vignettePaint);
  }

  void _paintNeon(Canvas canvas, Size size) {
    // Pulsating perspective grid
    final centerX = size.width / 2;
    final bottomY = size.height;
    final horizonY = size.height * 0.3;

    // Breathing gradient backdrop
    final bgRect = Offset.zero & size;
    final pulse = sin(progress * pi * 2) * 0.5 + 0.5;
    final bgGradient = RadialGradient(
      center: Alignment(0, pulse * 0.2 - 0.4),
      radius: 1.2,
      colors: [
        colors.grid.withValues(alpha: 0.8),
        colors.background,
      ],
    );
    canvas.drawRect(bgRect, Paint()..shader = bgGradient.createShader(bgRect));

    // Perspective lines
    final linePaint = Paint()
      ..color = colors.gridLine.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Vertical vanishing lines
    for (int i = -10; i <= 10; i++) {
      final xOffset = i * (size.width / 5);
      canvas.drawLine(
        Offset(centerX, horizonY),
        Offset(centerX + xOffset, bottomY),
        linePaint,
      );
    }

    // Horizontal moving lines
    for (int i = 0; i < 15; i++) {
      // Non-linear spacing for perspective
      final rawY = ((i + progress) / 15);
      final curvedY = rawY * rawY * rawY; // dramatic perspective curve
      final yPos = horizonY + (bottomY - horizonY) * curvedY;
      canvas.drawLine(Offset(0, yPos), Offset(size.width, yPos), linePaint);
    }
  }

  void _paintNature(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Rich forest gradient backdrop
    final bgGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF0A1A0F),
        const Color(0xFF16251C),
        const Color(0xFF1F3528),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = bgGradient.createShader(rect));

    // ── Falling leaves ──
    // Each leaf is a tiny rotated rounded rectangle.
    final leafPaint = Paint()..style = PaintingStyle.fill;
    const int leafCount = 28;
    final rng = Random(7); // stable seed

    for (int i = 0; i < leafCount; i++) {
      final seedX = rng.nextDouble();
      final seedY = rng.nextDouble();
      final seedSpd = rng.nextDouble();
      final seedSz = rng.nextDouble();
      final seedHue = rng.nextDouble(); // 0 = green, 1 = orange/yellow

      final speed = 0.08 + seedSpd * 0.14;
      final leafW = 6.0 + seedSz * 9.0;
      final leafH = leafW * 0.55;

      // Vertical position – wrap downward
      double cy = (seedY * size.height +
              progress * size.height * speed * (0.7 + i * 0.03)) %
          (size.height + leafH * 2);
      cy -= leafH; // start above top

      // Horizontal sway
      final swayAmp = 18.0 + seedSz * 12.0;
      final cx = seedX * size.width +
          sin(progress * pi * 2.0 * (0.6 + seedSpd * 0.8) + i) * swayAmp;

      // Rotation
      final angle = progress * pi * 2 * (seedSpd + 0.3) * (i.isEven ? 1 : -1);

      // Colour: mix greens, yellows, oranges
      final Color leafColor;
      if (seedHue < 0.45) {
        leafColor = Color.lerp(
          const Color(0xFF3DBE6A),
          const Color(0xFF66FF99),
          seedHue / 0.45,
        )!
            .withValues(alpha: 0.55 + seedSpd * 0.3);
      } else if (seedHue < 0.75) {
        leafColor = Color.lerp(
          const Color(0xFFDDA52A),
          const Color(0xFFFF9933),
          (seedHue - 0.45) / 0.30,
        )!
            .withValues(alpha: 0.5 + seedSpd * 0.25);
      } else {
        leafColor = Color.lerp(
          const Color(0xFFFF9933),
          const Color(0xFFFF5C2E),
          (seedHue - 0.75) / 0.25,
        )!
            .withValues(alpha: 0.45 + seedSpd * 0.25);
      }
      leafPaint.color = leafColor;

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);
      final rr = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: leafW, height: leafH),
        Radius.circular(leafH / 2),
      );
      canvas.drawRRect(rr, leafPaint);
      // Central vein
      canvas.drawLine(
        Offset(-leafW * 0.38, 0),
        Offset(leafW * 0.38, 0),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.18)
          ..strokeWidth = 0.8,
      );
      canvas.restore();
    }

    // ── Firefly glow dots ──
    final glow = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 14; i++) {
      final fx = sin(progress * pi * 1.4 + i * 2.3) * 0.45 + 0.5;
      final fy = cos(progress * pi * 0.9 + i * 1.7) * 0.45 + 0.5;
      final pulse = sin(progress * pi * 6 + i) * 0.5 + 0.5;
      glow.color = const Color(0xFFB5FF7A).withValues(alpha: 0.08 + pulse * 0.22);
      canvas.drawCircle(
        Offset(fx * size.width, fy * size.height),
        2.0 + pulse * 2.0,
        glow,
      );
    }

    // Forest floor vignette
    final vignette = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF040C07).withValues(alpha: 0.55),
        Colors.transparent,
        const Color(0xFF040C07).withValues(alpha: 0.45),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = vignette.createShader(rect));
  }

  void _paintArcade(Canvas canvas, Size size) {
    // True black background is drawn behind this.
    // Let's add a slow-moving grid pattern or starfield.
    final paint = Paint()
      ..color = colors.gridLine.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final spacing = size.width / 8;
    final yOffset = (progress * spacing * 4) % spacing;
    final xOffset = (progress * spacing * 2) % spacing;

    // Draw horizontal lines wrapping
    for (double y = -spacing; y < size.height + spacing; y += spacing) {
      canvas.drawLine(
          Offset(0, y + yOffset), Offset(size.width, y + yOffset), paint);
    }

    // Draw vertical lines wrapping
    for (double x = -spacing; x < size.width + spacing; x += spacing) {
      canvas.drawLine(
          Offset(x + xOffset, 0), Offset(x + xOffset, size.height), paint);
    }
  }

  void _paintCyber(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final bg = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        colors.background,
        colors.grid.withValues(alpha: 0.9),
        colors.background,
      ],
    );
    canvas.drawRect(rect, Paint()..shader = bg.createShader(rect));

    final scan = Paint()
      ..color = colors.snakeHead.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3.5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scan);
    }

    final rain = Paint()
      ..color = colors.accent.withValues(alpha: 0.26)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const int columns = 28;
    final columnWidth = size.width / columns;
    for (int i = 0; i < columns; i++) {
      final seed = (i * 97 + 31) % 1000;
      final speed = 0.35 + ((seed % 7) * 0.08);
      final length = 40.0 + ((seed % 5) * 22.0);
      final offset = ((progress * size.height * speed) + seed * 1.3) %
          (size.height + length);
      final x = i * columnWidth + columnWidth * 0.5;
      final y1 = offset - length;
      final y2 = offset;
      canvas.drawLine(Offset(x, y1), Offset(x, y2), rain);
    }

    final glow = RadialGradient(
      center: const Alignment(0, -0.3),
      radius: 1.1,
      colors: [
        colors.buttonBorder.withValues(alpha: 0.16 + sin(progress * pi * 2) * 0.05),
        Colors.transparent,
      ],
    );
    canvas.drawRect(rect, Paint()..shader = glow.createShader(rect));
  }

  void _paintVolcano(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final heatBg = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF100203),
        colors.background,
        const Color(0xFF2A0906),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = heatBg.createShader(rect));

    final lava = Paint()..style = PaintingStyle.fill;
    const int waves = 6;
    for (int i = 0; i < waves; i++) {
      final phase = progress * pi * 2 + i * 0.9;
      final yBase = size.height * (0.62 + i * 0.08);
      final path = Path()..moveTo(0, size.height);
      for (double x = 0; x <= size.width; x += 12) {
        final y = yBase + sin((x / size.width) * pi * 2 + phase) * (10 + i * 2);
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.close();
      lava.color = Color.lerp(
            colors.accent.withValues(alpha: 0.4),
            Colors.orange.withValues(alpha: 0.2),
            i / waves,
          ) ??
          colors.accent.withValues(alpha: 0.3);
      canvas.drawPath(path, lava);
    }

    final ember = Paint()..style = PaintingStyle.fill;
    const int embers = 40;
    for (int i = 0; i < embers; i++) {
      final seed = (i * 73 + 19) % 1000;
      final x = (seed % 1000) / 1000 * size.width;
      final speed = 0.16 + ((seed % 11) * 0.02);
      final y = size.height -
          (((progress * size.height * speed) + (seed * 3.7)) %
              (size.height + 40));
      final r = 1.2 + (seed % 3);
      ember.color = Colors.orangeAccent.withValues(alpha: 0.2 + ((seed % 5) * 0.09));
      canvas.drawCircle(Offset(x, y), r.toDouble(), ember);
    }

    final vignette = RadialGradient(
      center: const Alignment(0, 0.7),
      radius: 1.2,
      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.35)],
    );
    canvas.drawRect(rect, Paint()..shader = vignette.createShader(rect));
  }

  void _paintIce(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Arctic sky gradient
    final bgGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF020A14),
        const Color(0xFF050E1A),
        const Color(0xFF0B1829),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = bgGradient.createShader(rect));

    // ── Snowflakes ──
    final snowPaint = Paint()..style = PaintingStyle.fill;
    const int flakeCount = 80;
    final rng = Random(13); // stable seed

    for (int i = 0; i < flakeCount; i++) {
      final seedX = rng.nextDouble();
      final seedY = rng.nextDouble();
      final seedSpd = rng.nextDouble();
      final seedSz = rng.nextDouble();
      final seedOp = rng.nextDouble();

      final speed = 0.06 + seedSpd * 0.18;
      final radius = 1.0 + seedSz * 3.5;

      // Falling downward, wrapping
      double cy = (seedY * size.height +
              progress * size.height * speed * (0.5 + i * 0.015)) %
          (size.height + radius * 2);
      cy -= radius;

      // Horizontal drift
      final driftAmp = 8.0 + seedSz * 14.0;
      final cx =
          seedX * size.width + sin(progress * pi * 1.6 + i * 1.3) * driftAmp;

      final opacity = 0.3 + seedOp * 0.6;

      // Large flakes get a cross/star shape; small ones are circles.
      if (radius > 3.0) {
        snowPaint.color = Colors.white.withValues(alpha: opacity * 0.85);
        // Draw 3 crossing lines (hexagonal snowflake approximation)
        final arm = radius * 1.6;
        final angles = [0.0, pi / 3, pi * 2 / 3];
        for (final a in angles) {
          canvas.drawLine(
            Offset(cx + cos(a) * arm, cy + sin(a) * arm),
            Offset(cx - cos(a) * arm, cy - sin(a) * arm),
            Paint()
              ..color = Colors.white.withValues(alpha: opacity * 0.9)
              ..strokeWidth = 0.9
              ..strokeCap = StrokeCap.round,
          );
        }
        // Center dot
        snowPaint.color = Colors.white.withValues(alpha: opacity);
        canvas.drawCircle(Offset(cx, cy), radius * 0.3, snowPaint);
      } else {
        // Small flake – simple circle
        snowPaint.color = Colors.white.withValues(alpha: opacity * 0.75);
        canvas.drawCircle(Offset(cx, cy), radius, snowPaint);
      }
    }

    // ── Aurora shimmer on horizon ──
    final auroraPulse = sin(progress * pi * 2) * 0.5 + 0.5;
    final auroraGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF7FEFFF).withValues(alpha: 0.0 + auroraPulse * 0.07),
        const Color(0xFF00CFAA).withValues(alpha: 0.04 + auroraPulse * 0.05),
        Colors.transparent,
      ],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.45),
      Paint()
        ..shader = auroraGradient
            .createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.45)),
    );

    // ── Ground frost at bottom ──
    final frostGradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        const Color(0xFFB3F3FF).withValues(alpha: 0.18),
        Colors.transparent,
      ],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.7, size.width, size.height * 0.3),
      Paint()
        ..shader = frostGradient.createShader(
            Rect.fromLTWH(0, size.height * 0.7, size.width, size.height * 0.3)),
    );

    // Edge vignette
    final vignette = RadialGradient(
      center: Alignment.center,
      radius: 1.1,
      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.4)],
    );
    canvas.drawRect(rect, Paint()..shader = vignette.createShader(rect));
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) =>
      oldDelegate.themeType != themeType || oldDelegate.progress != progress;
}
