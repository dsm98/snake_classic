import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/enums/theme_type.dart';
import '../../providers/settings_provider.dart';
import '../../services/multiplayer_engine.dart';
import '../../services/audio_service.dart';
import '../widgets/game/multiplayer_board.dart';
import '../../core/enums/direction.dart';

class MultiplayerScreen extends StatefulWidget {
  const MultiplayerScreen({super.key});

  @override
  State<MultiplayerScreen> createState() => _MultiplayerScreenState();
}

class _MultiplayerScreenState extends State<MultiplayerScreen> {
  late MultiplayerEngine _engine;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _engine = MultiplayerEngine();
    _engine.init();
    _engine.onFoodEaten = () {
      AudioService().play(SoundEffect.eat);
    };
    _engine.onGameOver = _showGameOver;
  }

  void _showGameOver() {
    String msg;
    Color color;
    if (_engine.winner == 3) {
      msg = "DRAW! 💥";
      color = Colors.amber;
    } else if (_engine.winner == 1) {
      msg = "BLUE WINS! 🏆";
      color = const Color(0xFF00E5FF);
    } else {
      msg = "PINK WINS! 🏆";
      color = const Color(0xFFFF3366);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2638),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color, width: 2),
            boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 40)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                msg,
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Blue Score: ${_engine.score1}\nPink Score: ${_engine.score2}',
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 16,
                  color: Colors.white,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // close dialog
                      Navigator.pop(context); // close screen
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.white70),
                    child: const Text('MENU', style: TextStyle(fontFamily: 'Orbitron')),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _engine.restart();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('REMATCH', style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _engine.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _handleSwipe1(DragEndDetails details) {
    if (!_started) {
      _started = true;
      _engine.start();
    }
    const threshold = 10;
    final dx = details.velocity.pixelsPerSecond.dx;
    final dy = details.velocity.pixelsPerSecond.dy;
    if (dx.abs() > dy.abs()) {
      if (dx > threshold) {
        _engine.changeDirection1(Direction.right);
      } else if (dx < -threshold) _engine.changeDirection1(Direction.left);
    } else {
      if (dy > threshold) {
        _engine.changeDirection1(Direction.down);
      } else if (dy < -threshold) _engine.changeDirection1(Direction.up);
    }
  }

  void _handleSwipe2(DragEndDetails details) {
    if (!_started) {
      _started = true;
      _engine.start();
    }
    // P2 is rotated 180 degrees! So physical "UP" swipe looks like "DOWN" to P2.
    // That means: dx > 0 is actually left to P2. dy > 0 is actually "up" to P2 moving to top of screen.
    const threshold = 10;
    final dx = details.velocity.pixelsPerSecond.dx;
    final dy = details.velocity.pixelsPerSecond.dy;
    
    if (dx.abs() > dy.abs()) {
      if (dx > threshold) {
        _engine.changeDirection2(Direction.left); // opposite
      } else if (dx < -threshold) _engine.changeDirection2(Direction.right); // opposite
    } else {
      if (dy > threshold) {
        _engine.changeDirection2(Direction.up); // swipe down physically means moving up the screen, which is "up" relative to P2 looking from top.
      } else if (dy < -threshold) _engine.changeDirection2(Direction.down);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final themeType = settings.theme;
    
    AppThemeColors colors;
    switch(themeType) {
      case ThemeType.retro: colors = AppThemeColors.retro; break;
      case ThemeType.neon: colors = AppThemeColors.neon; break;
      case ThemeType.nature: colors = AppThemeColors.nature; break;
      case ThemeType.arcade: colors = AppThemeColors.arcade; break;
      case ThemeType.cyber: colors = AppThemeColors.cyber; break;
      case ThemeType.volcano: colors = AppThemeColors.volcano; break;
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // P2 Control Area (Top half)
            Expanded(
              child: GestureDetector(
                onPanEnd: _handleSwipe2,
                behavior: HitTestBehavior.opaque,
                child: RotatedBox(
                  quarterTurns: 2,
                  child: Container(
                    width: double.infinity,
                    color: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ListenableBuilder(
                          listenable: _engine,
                          builder: (c, _) => Text(
                            'SCORE: ${_engine.score2}',
                            style: const TextStyle(
                              fontFamily: 'Orbitron',
                              color: Color(0xFFFF3366),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text('READY', style: TextStyle(color: Colors.white24, letterSpacing: 5)),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Game Board Center
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24, width: 4),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20)],
              ),
              child: AspectRatio(
                aspectRatio: 20 / 28,
                child: MultiplayerBoard(engine: _engine),
              ),
            ),

            // P1 Control Area (Bottom half)
            Expanded(
              child: GestureDetector(
                onPanEnd: _handleSwipe1,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  color: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      if (!_started)
                        const Text('SWIPE TO START', style: TextStyle(color: Colors.white, fontFamily: 'Orbitron', fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2))
                      else
                        const Text('PLAYING', style: TextStyle(color: Colors.white24, letterSpacing: 5)),
                      const SizedBox(height: 10),
                      ListenableBuilder(
                        listenable: _engine,
                        builder: (c, _) => Text(
                          'SCORE: ${_engine.score1}',
                          style: const TextStyle(
                            fontFamily: 'Orbitron',
                            color: Color(0xFF00E5FF),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
