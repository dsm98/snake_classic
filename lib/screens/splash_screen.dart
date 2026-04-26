import 'dart:math';
import 'package:flutter/material.dart';
import 'home_screen.dart' as home;
import 'cold_open_screen.dart';
import '../services/storage_service.dart';
import '../services/analytics_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _snakeController;
  late AnimationController _glowController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();

    final reducedMotion = StorageService().reducedMotion;

    _snakeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: reducedMotion ? 300 : 1400),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: reducedMotion ? 500 : 900),
    );
    if (!reducedMotion) {
      _glowController.repeat(reverse: true);
    }

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _snakeController.forward().then((_) {
      _fadeController.forward();
    });

    Future.delayed(Duration(milliseconds: reducedMotion ? 700 : 3000), () {
      if (mounted) {
        final bool tutorialCompleted = StorageService().tutorialCompleted;
        final Widget nextScreen = tutorialCompleted
            ? const home.HomeScreen()
            : const ColdOpenScreen();

        if (!tutorialCompleted) {
          AnalyticsService().logTutorialStarted();
        }

        // Log experiment assignments on every launch (no-op if already logged)
        final storage = StorageService();
        AnalyticsService().logExperimentAssigned(
          experimentKey: storage.expTutorialKey,
          variant: storage.expTutorialVariant,
        );
        AnalyticsService().logExperimentAssigned(
          experimentKey: storage.expStreakRewardKey,
          variant: storage.expStreakRewardVariant,
        );
        AnalyticsService().logExperimentAssigned(
          experimentKey: storage.expHudKey,
          variant: storage.expHudSimplifiedVariant,
        );

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (c, a1, a2) => nextScreen,
            transitionsBuilder: (c, a1, a2, child) =>
                FadeTransition(opacity: a1, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _snakeController.dispose();
    _glowController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060B14),
      body: Stack(
        children: [
          // Animated grid background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, _) => CustomPaint(
                painter: _SplashBgPainter(_glowController.value),
              ),
            ),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Snake logo animation
                AnimatedBuilder(
                  animation: _snakeController,
                  builder: (context, _) => CustomPaint(
                    size: const Size(140, 140),
                    painter: _SnakeLogoPainter(
                      progress: _snakeController.value,
                      glow: _glowController.value,
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // SNAKE title with gradient
                FadeTransition(
                  opacity: _fadeController,
                  child: Column(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF00FF88), Color(0xFF00E5FF)],
                        ).createShader(bounds),
                        child: AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, _) => Text(
                            'SNAKE',
                            style: TextStyle(
                              fontFamily: 'PressStart2P',
                              fontSize: 38,
                              color: Colors.white,
                              letterSpacing: 8,
                              shadows: [
                                Shadow(
                                  color: const Color(0xFF00FF88).withValues(alpha: 
                                      0.4 + _glowController.value * 0.4),
                                  blurRadius: 30,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'CLASSIC  REBORN',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 13,
                          color: const Color(0xFF00FF88).withValues(alpha: 0.7),
                          letterSpacing: 6,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),

                // Pulsing dots
                FadeTransition(
                  opacity: _fadeController,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, _) {
                            final phase = (i / 3.0);
                            final t = (_glowController.value + phase) % 1.0;
                            final size = 6.0 + sin(t * pi) * 4;
                            final opacity = 0.3 + sin(t * pi) * 0.7;
                            return Container(
                              width: size,
                              height: size,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00FF88)
                                    .withValues(alpha: opacity),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00FF88)
                                        .withValues(alpha: opacity * 0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashBgPainter extends CustomPainter {
  final double progress;
  _SplashBgPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FF88).withValues(alpha: 0.04)
      ..strokeWidth = 1;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Corner glow
    final radial = RadialGradient(
      center: Alignment.bottomCenter,
      radius: 1.0,
      colors: [
        const Color(0xFF00FF88).withValues(alpha: 0.08 + progress * 0.04),
        Colors.transparent,
      ],
    );
    canvas.drawRect(Offset.zero & size,
        Paint()..shader = radial.createShader(Offset.zero & size));
  }

  @override
  bool shouldRepaint(covariant _SplashBgPainter old) =>
      old.progress != progress;
}

class _SnakeLogoPainter extends CustomPainter {
  final double progress;
  final double glow;
  _SnakeLogoPainter({required this.progress, required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 8;

    // Define snake path as a spiral
    final points = <Offset>[];
    const segments = 60;

    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      final angle = t * 3.5 * pi - pi / 2;
      final radius = r * (1 - t * 0.55);
      points.add(Offset(cx + cos(angle) * radius, cy + sin(angle) * radius));
    }

    // Draw glow trail
    final glowProgress =
        (progress * (segments + 1)).clamp(0, segments + 1).toInt();
    if (glowProgress > 1) {
      for (int i = 1; i < glowProgress && i < points.length; i++) {
        final t = i / segments;
        final bodyColor = Color.lerp(
          const Color(0xFF00E5FF),
          const Color(0xFF00FF88),
          t,
        )!;

        final glowPaint = Paint()
          ..color = bodyColor.withValues(alpha: 0.3)
          ..strokeWidth = 12 + glow * 4
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

        canvas.drawLine(points[i - 1], points[i], glowPaint);

        final solidPaint = Paint()
          ..color = bodyColor.withValues(alpha: 0.9)
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

        canvas.drawLine(points[i - 1], points[i], solidPaint);
      }

      // Head
      if (glowProgress >= 2) {
        final headPos = points[glowProgress.clamp(0, points.length - 1)];
        canvas.drawCircle(
          headPos,
          10,
          Paint()
            ..color = const Color(0xFF00FF88).withValues(alpha: 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
        canvas.drawCircle(
          headPos,
          7,
          Paint()..color = const Color(0xFF00FF88),
        );
        // Eyes
        canvas.drawCircle(
          headPos.translate(-3, -2),
          2,
          Paint()..color = Colors.black,
        );
        canvas.drawCircle(
          headPos.translate(3, -2),
          2,
          Paint()..color = Colors.black,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SnakeLogoPainter old) =>
      old.progress != progress || old.glow != glow;
}
