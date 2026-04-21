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
        _paintRetro(canvas, size); // Temporary
        break;
      case ThemeType.volcano:
        _paintArcade(canvas, size); // Temporary
        break;
    }
  }

  void _paintRetro(Canvas canvas, Size size) {
    // base fill
    canvas.drawRect(Offset.zero & size, Paint()..color = colors.background);

    // subtle sub-pixel grid
    final gridPaint = Paint()
      ..color = colors.snakeHead.withOpacity(0.04)
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
      ..color = Colors.black.withOpacity(0.03)
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
        Colors.white.withOpacity(0.05),
        colors.snakeHead.withOpacity(0.12),
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
        colors.grid.withOpacity(0.8),
        colors.background,
      ],
    );
    canvas.drawRect(bgRect, Paint()..shader = bgGradient.createShader(bgRect));

    // Perspective lines
    final linePaint = Paint()
      ..color = colors.gridLine.withOpacity(0.4)
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
    // Drifting light motes / pollen
    final paint = Paint()
      ..color = colors.accent.withOpacity(0.15)
      ..style = PaintingStyle.fill;
      
    final random = Random(42); // Deterministic random for stable particles
    
    for (int i = 0; i < 30; i++) {
      final xOffset = random.nextDouble() * size.width;
      final yOffset = random.nextDouble() * size.height;
      final speed = random.nextDouble() * 0.5 + 0.1;
      final sizeMult = random.nextDouble() * 4 + 2;
      
      // Calculate current position including wrapping
      double curY = yOffset - (progress * size.height * speed);
      if (curY < -10) curY += size.height + 20; // wrap around
      
      // Add slight horizontal drift based on sin wave
      double curX = xOffset + sin((progress * pi * 4) + i) * 20;
      
      // Calculate opacity based on pulse
      final opacity = (sin((progress * pi * 8) + i) * 0.5 + 0.5) * 0.4;
      paint.color = colors.accent.withOpacity(opacity);
      
      canvas.drawCircle(Offset(curX, curY), sizeMult, paint);
    }
    
    // Soft vignette
    final Rect rect = Offset.zero & size;
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        colors.hudBg.withOpacity(0.4),
        Colors.transparent,
        colors.background.withOpacity(0.2),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  void _paintArcade(Canvas canvas, Size size) {
    // True black background is drawn behind this.
    // Let's add a slow-moving grid pattern or starfield.
    final paint = Paint()
      ..color = colors.gridLine.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final spacing = size.width / 8;
    final yOffset = (progress * spacing * 4) % spacing;
    final xOffset = (progress * spacing * 2) % spacing;

    // Draw horizontal lines wrapping
    for (double y = -spacing; y < size.height + spacing; y += spacing) {
      canvas.drawLine(Offset(0, y + yOffset), Offset(size.width, y + yOffset), paint);
    }
    
    // Draw vertical lines wrapping
    for (double x = -spacing; x < size.width + spacing; x += spacing) {
      canvas.drawLine(Offset(x + xOffset, 0), Offset(x + xOffset, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) =>
      oldDelegate.themeType != themeType || oldDelegate.progress != progress;
}
