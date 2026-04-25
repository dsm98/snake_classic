import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_typography.dart';
import '../services/storage_service.dart';
import '../services/screen_shake_service.dart';
import 'home_screen.dart' as home;

/// "Cold Open" onboarding screen for first-time players.
/// 
/// The moment the app loads, there is no menu — just a dark screen,
/// a glowing apple, and a snake that is already moving. 
/// The tutorial happens seamlessly in-game with minimal swipe hints.
/// After the first death, the player is funnelled to the main menu.
class ColdOpenScreen extends StatefulWidget {
  const ColdOpenScreen({super.key});

  @override
  State<ColdOpenScreen> createState() => _ColdOpenScreenState();
}

class _ColdOpenScreenState extends State<ColdOpenScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeIn;
  late AnimationController _pulseCtrl;
  late AnimationController _snakeCtrl;

  // Simple demo snake state
  List<Offset> _snake = [];
  Offset _food = const Offset(0, 0);
  int _dx = 1, _dy = 0;
  bool _isDead = false;
  int _eatCount = 0;
  final int _gridW = 15, _gridH = 22;
  final Random _rng = Random();
  Timer? _tickTimer;

  // Tutorial phases
  int _tutorialPhase = 0; // 0=waiting, 1=shown swipe hint, 2=eaten 1 food

  @override
  void initState() {
    super.initState();

    _fadeIn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _snakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    // Start snake in center moving right
    final cx = _gridW ~/ 2;
    final cy = _gridH ~/ 2;
    _snake = [
      Offset(cx.toDouble(), cy.toDouble()),
      Offset((cx - 1).toDouble(), cy.toDouble()),
      Offset((cx - 2).toDouble(), cy.toDouble()),
    ];
    _spawnFood();

    // Show swipe hint after 1s
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _tutorialPhase = 1);
    });

    // Start auto-tick
    _tickTimer = Timer.periodic(const Duration(milliseconds: 220), _gameTick);
  }

  void _spawnFood() {
    // Pick a cell not on the snake
    Set<String> occupied = _snake.map((o) => '${o.dx},${o.dy}').toSet();
    Offset pos;
    do {
      pos = Offset(
        _rng.nextInt(_gridW).toDouble(),
        _rng.nextInt(_gridH).toDouble(),
      );
    } while (occupied.contains('${pos.dx},${pos.dy}'));
    _food = pos;
  }

  void _gameTick(Timer _) {
    if (_isDead || !mounted) return;

    final head = _snake.first;
    Offset newHead = Offset(
      (head.dx + _dx) % _gridW,
      (head.dy + _dy) % _gridH,
    );
    if (newHead.dx < 0) newHead = Offset(_gridW - 1, newHead.dy);
    if (newHead.dy < 0) newHead = Offset(newHead.dx, _gridH - 1);

    // Self-collision
    bool hitSelf = _snake.any((s) => s == newHead);
    if (hitSelf) {
      setState(() => _isDead = true);
      ScreenShakeService().gameOver();
      // After 1.5s go to menu
      Future.delayed(const Duration(milliseconds: 1500), _goToMenu);
      return;
    }

    bool ateFood = newHead == _food;
    setState(() {
      _snake = [newHead, ..._snake];
      if (!ateFood) {
        _snake.removeLast();
      } else {
        _eatCount++;
        _spawnFood();
        if (_tutorialPhase == 1) _tutorialPhase = 2;
        ScreenShakeService().eatGolden();
      }
    });
  }

  void _handleSwipe(DragEndDetails details) {
    if (_isDead) return;
    final vx = details.velocity.pixelsPerSecond.dx;
    final vy = details.velocity.pixelsPerSecond.dy;
    if (vx.abs() > vy.abs()) {
      if (vx > 0 && _dx != -1) { _dx = 1; _dy = 0; }
      else if (vx < 0 && _dx != 1) { _dx = -1; _dy = 0; }
    } else {
      if (vy > 0 && _dy != -1) { _dx = 0; _dy = 1; }
      else if (vy < 0 && _dy != 1) { _dx = 0; _dy = -1; }
    }
    if (_tutorialPhase == 1) setState(() => _tutorialPhase = 2);
  }

  void _goToMenu() {
    if (!mounted) return;
    StorageService().setTutorialCompleted(true);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const home.HomeScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _fadeIn.dispose();
    _pulseCtrl.dispose();
    _snakeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onPanEnd: _handleSwipe,
        child: AnimatedBuilder(
          animation: Listenable.merge([_fadeIn, _pulseCtrl]),
          builder: (context, _) => FadeTransition(
            opacity: _fadeIn,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Game grid
                _buildGrid(),

                // Atmospheric vignette
                Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.0,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.55),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),

                // Tutorial text overlay
                if (_tutorialPhase == 1 && !_isDead)
                  _buildTutorialHint('Swipe to turn', Icons.swipe),
                if (_tutorialPhase == 2 && !_isDead && _eatCount < 2)
                  _buildTutorialHint('Eat the apple!', Icons.circle),
                if (_eatCount >= 3 && !_isDead)
                  _buildTutorialHint('Amazing! Avoid your tail', Icons.warning_rounded),

                // Death overlay
                if (_isDead)
                  _buildDeathOverlay(),

                // Top lore line
                Positioned(
                  top: MediaQuery.of(context).padding.top + 24,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: (0.6 + _pulseCtrl.value * 0.2),
                    child: const Text(
                      'THE SERPENT AWAKENS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTypography.retroFont,
                        fontSize: 10,
                        letterSpacing: 3.0,
                        color: Color(0xFF44FF88),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final cellW = constraints.maxWidth / _gridW;
        final cellH = constraints.maxHeight / _gridH;
        final cell = min(cellW, cellH);

        return CustomPaint(
          painter: _ColdOpenPainter(
            snake: _snake,
            food: _food,
            gridW: _gridW,
            gridH: _gridH,
            cellSize: cell,
            pulse: _pulseCtrl.value,
            isDead: _isDead,
          ),
        );
      },
    );
  }

  Widget _buildTutorialHint(String text, IconData icon) {
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 400),
        child: Column(
          children: [
            Icon(icon, color: Colors.white54, size: 28),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTypography.modernFont,
                fontSize: 13,
                color: Colors.white54,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeathOverlay() {
    return Container(
      color: Colors.red.withOpacity(0.15),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'GAME OVER',
              style: TextStyle(
                fontFamily: AppTypography.retroFont,
                fontSize: 22,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Score: $_eatCount',
              style: const TextStyle(
                fontFamily: AppTypography.modernFont,
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Entering the realm...',
              style: TextStyle(
                fontFamily: AppTypography.modernFont,
                fontSize: 11,
                color: Colors.white38,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColdOpenPainter extends CustomPainter {
  final List<Offset> snake;
  final Offset food;
  final int gridW, gridH;
  final double cellSize;
  final double pulse;
  final bool isDead;

  _ColdOpenPainter({
    required this.snake,
    required this.food,
    required this.gridW,
    required this.gridH,
    required this.cellSize,
    required this.pulse,
    required this.isDead,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (cellSize == 0) return;

    // Subtle grid
    final gridPaint = Paint()
      ..color = const Color(0xFF001800)
      ..strokeWidth = 0.5;
    for (int x = 0; x <= gridW; x++) {
      canvas.drawLine(
        Offset(x * cellSize, 0),
        Offset(x * cellSize, gridH * cellSize),
        gridPaint,
      );
    }
    for (int y = 0; y <= gridH; y++) {
      canvas.drawLine(
        Offset(0, y * cellSize),
        Offset(gridW * cellSize, y * cellSize),
        gridPaint,
      );
    }

    // Draw food (glowing apple)
    final foodCenter = Offset(
      (food.dx + 0.5) * cellSize,
      (food.dy + 0.5) * cellSize,
    );
    canvas.drawCircle(
      foodCenter,
      cellSize * 0.5 * (1.1 + pulse * 0.15),
      Paint()
        ..color = const Color(0xFF00FF44).withOpacity(0.15 + pulse * 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawCircle(
      foodCenter,
      cellSize * 0.38,
      Paint()..color = const Color(0xFF44FF66),
    );
    canvas.drawCircle(
      foodCenter,
      cellSize * 0.18,
      Paint()..color = Colors.white.withOpacity(0.7),
    );

    // Draw snake
    final deadColor = Colors.red.shade900;
    for (int i = snake.length - 1; i >= 0; i--) {
      final s = snake[i];
      final center = Offset((s.dx + 0.5) * cellSize, (s.dy + 0.5) * cellSize);
      final isHead = i == 0;
      final progress = 1.0 - (i / snake.length) * 0.5;
      final bodyColor = isDead
          ? deadColor.withOpacity(progress)
          : Color.lerp(
                const Color(0xFF002200),
                const Color(0xFF00BB44),
                progress,
              )!;

      if (isHead && !isDead) {
        // Glowing head
        canvas.drawCircle(
          center,
          cellSize * 0.52,
          Paint()
            ..color = const Color(0xFF00FF66).withOpacity(0.4 + pulse * 0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        canvas.drawCircle(
          center, cellSize * 0.45, Paint()..color = const Color(0xFF00EE44));
        // Eyes
        for (final xOff in [-0.18, 0.18]) {
          canvas.drawCircle(
            center + Offset(xOff * cellSize, -cellSize * 0.1),
            cellSize * 0.1,
            Paint()..color = Colors.black,
          );
        }
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: center, width: cellSize * 0.8, height: cellSize * 0.8),
            Radius.circular(cellSize * 0.2),
          ),
          Paint()..color = bodyColor,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ColdOpenPainter old) => true;
}
