import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../core/constants/app_colors.dart';
import '../core/enums/direction.dart';
import '../core/enums/game_mode.dart';
import '../core/enums/theme_type.dart';
import '../core/models/high_score.dart';
import '../providers/settings_provider.dart';
import '../core/models/campaign_level.dart';
import '../core/models/daily_event.dart';
import '../core/enums/snake_skin.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/game_engine.dart';
import '../providers/user_provider.dart';
import '../services/audio_service.dart';
import '../services/leaderboard_service.dart';
import '../services/auth_service.dart';
import '../widgets/game/game_board.dart';
import '../widgets/game/game_hud.dart';
import '../widgets/game/swipe_controller.dart';
import '../widgets/game/particle_system.dart';
import '../services/ad_service.dart';
import '../services/analytics_service.dart';
import 'game_over_screen.dart';

class GameScreen extends StatefulWidget {
  final GameMode mode;
  final Difficulty difficulty;
  final ThemeType themeType;
  final CampaignLevel? campaignLevel;
  final DailyEvent? dailyEvent;
  final bool comebackBonus;

  const GameScreen({
    super.key,
    required this.mode,
    required this.difficulty,
    required this.themeType,
    this.campaignLevel,
    this.dailyEvent,
    this.comebackBonus = false,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late GameEngine _engine;
  bool _started = false;
  int _countdown = 3;
  int _revivesUsed = 0;
  final bool _hasComebackBonus = false;
  late final GlobalKey<ParticleSystemState> _particleKey = GlobalKey();
  late AnimationController _countdownController;
  late AnimationController _shakeController;

  AppThemeColors get colors {
    switch (widget.themeType) {
      case ThemeType.retro:  return AppThemeColors.retro;
      case ThemeType.neon:   return AppThemeColors.neon;
      case ThemeType.nature: return AppThemeColors.nature;
      case ThemeType.arcade: return AppThemeColors.arcade;
      case ThemeType.cyber: return AppThemeColors.cyber;
      case ThemeType.volcano: return AppThemeColors.volcano;
    }
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _engine = GameEngine();
    final skin = context.read<UserProvider>().equippedSkin;
    _engine.init(
      mode: widget.mode,
      diff: widget.difficulty,
      skin: skin,
      campaignLevel: widget.campaignLevel,
      withComebackBonus: widget.comebackBonus,
      dailyEvent: widget.dailyEvent,
    );
    _engine.onFoodEaten = () {
      AudioService().play(SoundEffect.eat);
      _particleKey.currentState?.fireBurst(_engine.snake.first, colors.food);
    };
    _engine.onPowerUpCollected = () {
      AudioService().play(SoundEffect.powerUp);
      _particleKey.currentState
          ?.fireBurst(_engine.snake.first, colors.powerUp, count: 20);
    };
    _engine.onPoisonEaten = () {
      _shakeController.forward(from: 0);
      _particleKey.currentState?.fireBurst(_engine.snake.first, Colors.purple, count: 30);
    };
    _engine.onComboDropped = () {
      _shakeController.forward(from: 0);
    };
    _engine.onHighScoreReached = () {
      AudioService().play(SoundEffect.highScore);
      _particleKey.currentState?.fireBurst(_engine.snake.first, Colors.amber, count: 100);
      // Optional: Add notification or visual text
    };
    _engine.onGameOver = _onGameOverTriggered;

    if (kIsWeb) {
      HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    }

    _startCountdown();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    Direction? dir;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.keyW:
        dir = Direction.up;
        break;
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.keyS:
        dir = Direction.down;
        break;
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.keyA:
        dir = Direction.left;
        break;
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.keyD:
        dir = Direction.right;
        break;
      case LogicalKeyboardKey.escape:
      case LogicalKeyboardKey.keyP:
        if (_started && !_engine.isGameOver) {
          if (_engine.isPaused) {
            _engine.resume();
          } else {
            _engine.pause();
            _showPauseDialog();
          }
        }
        return true;
    }
    if (dir != null && _started) {
      _engine.changeDirection(dir);
      return true;
    }
    return false;
  }

  void _startCountdown() async {
    for (int i = 3; i >= 1; i--) {
      AudioService().play(SoundEffect.countdown);
      if (mounted) {
        setState(() => _countdown = i);
        _countdownController.forward(from: 0);
      }
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _countdown = i - 1);
    }
    if (mounted) {
      setState(() => _started = true);
      AnalyticsService().logGameStarted(widget.mode.name, widget.difficulty.name);
      _engine.start();
    }
  }

  void _onGameOverTriggered() {
    if (widget.mode == GameMode.campaign && _engine.isCampaignWon) {
      _handleGameOver();
      return;
    }
    
    _shakeController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      if (_revivesUsed < 3) {
        _showReviveDialog();
      } else {
        _handleGameOver();
      }
    });
  }

  void _showReviveDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (c) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: colors.hudBg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colors.buttonBorder.withOpacity(0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: colors.buttonBorder.withOpacity(0.2),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💀', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  'SECOND CHANCE',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 18,
                    color: colors.accent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Revives: $_revivesUsed / 3',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 11,
                    color: colors.text.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 24),
                _PremiumDialogButton(
                  label: 'WATCH AD TO REVIVE',
                  icon: '📺',
                  isPrimary: true,
                  colors: colors,
                  onTap: () async {
                    Navigator.pop(c);
                    bool adSuccess = await AdService().showRewarded(
                      onRewarded: _executeRevive,
                    );
                    if (!adSuccess) _executeRevive();
                  },
                ),
                const SizedBox(height: 12),
                _PremiumDialogButton(
                  label: 'GIVE UP',
                  icon: '🏳️',
                  isPrimary: false,
                  colors: colors,
                  onTap: () {
                    Navigator.pop(c);
                    _handleGameOver();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _executeRevive() {
    setState(() {
      _revivesUsed++;
      _started = false;
      _countdown = 3;
      _engine.revive();
    });
    _startCountdown();
  }

  void _handleGameOver() async {
    final settings = context.read<SettingsProvider>();
    if (settings.vibrationEnabled) {
      final hasVibrator = (await Vibration.hasVibrator()) == true;
      if (hasVibrator) Vibration.vibrate(duration: 300);
    }
    await AudioService().play(SoundEffect.gameOver);

    final auth = context.read<AuthService>();
    final connectivityResult = await (Connectivity().checkConnectivity());
    final isOnline = !connectivityResult.contains(ConnectivityResult.none);
    final canSaveProgress = auth.isSignedIn && isOnline;

    bool isTop = false;
    int xpEarned = 0;
    List<String> newAchievements = [];

    if (canSaveProgress) {
      final score = HighScore(
        score: _engine.score,
        snakeLength: _engine.snake.length,
        mode: widget.mode,
        achievedAt: DateTime.now(),
        playerName: auth.playerName,
      );

      isTop = await LeaderboardService().submitScore(score);
      if (isTop) AudioService().play(SoundEffect.highScore);

      AnalyticsService().logGameOver(
        mode: widget.mode.name,
        difficulty: widget.difficulty.name,
        score: _engine.score,
        snakeLength: _engine.snake.length,
        isHighScore: isTop,
      );

      final userProvider = context.read<UserProvider>();
      final result = await userProvider.completeGameSession(
        score: _engine.score,
        snakeLength: _engine.snake.length,
        combo: _engine.combo,
        foodEaten: _engine.snake.length - 3,
        powerUps: _engine.powerUpsCollectedSession,
        goldenApples: _engine.goldenApplesEatenSession,
        poisonApples: _engine.poisonApplesEatenSession,
        coinMultiplier: widget.dailyEvent?.coinMultiplier ?? 1.0,
        path: _engine.sessionPath,
        bonusCoins: _engine.coinsEarnedSession,
      );
      
      if (widget.mode == GameMode.campaign && _engine.isCampaignWon && widget.campaignLevel != null) {
        userProvider.unlockCampaignLevel(widget.campaignLevel!.index + 1);
      }

      xpEarned = result['xpEarned'] ?? 0;
      newAchievements = result['newAchievementIds'] ?? [];
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (c, a1, a2) => GameOverScreen(
            score: _engine.score,
            snakeLength: _engine.snake.length,
            mode: widget.mode,
            difficulty: widget.difficulty,
            themeType: widget.themeType,
            isHighScore: isTop,
            xpEarned: xpEarned,
            newAchievementIds: newAchievements,
            isCampaignWon: _engine.isCampaignWon,
            campaignLevel: widget.campaignLevel,
            dailyEvent: widget.dailyEvent,
          ),
          transitionsBuilder: (c, a1, a2, child) =>
              FadeTransition(opacity: a1, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    }
    _countdownController.dispose();
    _shakeController.dispose();
    _engine.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final equippedSkin = context.select<UserProvider, SnakeSkin>((p) => p.equippedSkin);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: StreamBuilder<List<ConnectivityResult>>(
          stream: Connectivity().onConnectivityChanged,
          builder: (context, connectivitySnapshot) {
            final auth = context.watch<AuthService>();
            final isOnline = connectivitySnapshot.data != null &&
                !connectivitySnapshot.data!
                    .contains(ConnectivityResult.none);
            final canSave = auth.isSignedIn && isOnline;
            const font = 'Orbitron';

            return Column(
              children: [
                if (!canSave)
                  _buildOfflineBanner(isOnline, auth.isSignedIn, colors, font),

                GameHud(
                  engine: _engine,
                  themeType: widget.themeType,
                  onPause: () {
                    if (_engine.isPaused) {
                      _engine.resume();
                    } else {
                      _engine.pause();
                      _showPauseDialog();
                    }
                  },
                ),

                Expanded(
                  child: ListenableBuilder(
                    listenable: _engine,
                    builder: (context, child) {
                      final timeCritical =
                          widget.mode == GameMode.timeAttack &&
                              _engine.timeRemainingSeconds <= 10 &&
                              !_engine.isGameOver;

                      final flashRed = timeCritical &&
                          (_engine.timeRemainingSeconds % 2 != 0);

                      return GestureDetector(
                        onTapDown: (_) => _engine.setBoosting(true),
                        onTapUp: (_) => _engine.setBoosting(false),
                        onTapCancel: () => _engine.setBoosting(false),
                        child: AnimatedBuilder(
                          animation: _shakeController,
                          builder: (context, child) {
                            final shakeDist = math.sin(_shakeController.value * math.pi * 6) * 12.0 * (1 - _shakeController.value);
                            return Transform.translate(
                              offset: Offset(shakeDist, 0),
                              child: child,
                            );
                          },
                          child: Container(
                            color: flashRed
                                ? Colors.red.withOpacity(0.12)
                              : colors.grid,
                          child: SwipeController(
                          onDirectionChanged: _engine.changeDirection,
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: 20 / 28,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: colors.grid,
                                  borderRadius:
                                      widget.themeType == ThemeType.retro
                                          ? BorderRadius.zero
                                          : BorderRadius.circular(12),
                                  border: Border.all(
                                    color: colors.gridLine,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    if (widget.themeType != ThemeType.retro)
                                      BoxShadow(
                                        color: widget.themeType ==
                                                ThemeType.neon
                                            ? colors.buttonBorder
                                                .withOpacity(0.4)
                                            : Colors.black.withOpacity(0.4),
                                        blurRadius: widget.themeType ==
                                                ThemeType.neon
                                            ? 24
                                            : 12,
                                        spreadRadius: widget.themeType ==
                                                ThemeType.neon
                                            ? 3
                                            : 2,
                                      ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius:
                                      widget.themeType == ThemeType.retro
                                          ? BorderRadius.zero
                                          : BorderRadius.circular(10),
                                  child: ParticleSystem(
                                    key: _particleKey,
                                    gridWidth: 20,
                                    gridHeight: 28,
                                    child: GameBoard(
                                      engine: _engine,
                                      themeType: widget.themeType,
                                      skin: equippedSkin,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        ),
                        ),
                      );
                    },
                  ),
                ),
                _bottomSection(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOfflineBanner(
      bool isOnline, bool isSignedIn, AppThemeColors colors, String font) {
    final message = !isOnline
        ? 'OFFLINE • Progress not saved'
        : 'GUEST • Login to save scores';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withOpacity(0.8),
            Colors.deepOrange.withOpacity(0.8),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 14, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Orbitron',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomSection() {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (kIsWeb)
          _KeyboardHint(colors: colors)
        else
          Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              if (!settings.showJoystick) return const SizedBox(height: 90);
              return JoystickWidget(
                onDirectionChanged: _engine.changeDirection,
                colors: colors,
                themeType: widget.themeType,
              );
            },
          ),

        // Countdown overlay
        if (!_started)
          AnimatedBuilder(
            animation: _countdownController,
            builder: (context, _) {
              final scale = 1.0 +
                  (1.0 - _countdownController.value) * 0.4;
              final opacity = _countdownController.value.clamp(0.0, 1.0);
              return Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colors.hudBg.withOpacity(0.95),
                      colors.background.withOpacity(0.7),
                    ],
                  ),
                  border: Border.all(
                    color: colors.buttonBorder.withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.buttonBorder.withOpacity(0.3),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: Text(
                      _countdown > 0 ? '$_countdown' : 'GO!',
                      style: TextStyle(
                        fontFamily: 'PressStart2P',
                        fontSize: _countdown > 0 ? 36 : 24,
                        color: _countdown == 0
                            ? colors.accent
                            : colors.text,
                        shadows: [
                          Shadow(
                            color: colors.buttonBorder.withOpacity(0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

        // Paused overlay
        if (_engine.isPaused)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.pause_circle_filled_rounded,
                      color: colors.text.withOpacity(0.9),
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PAUSED',
                      style: TextStyle(
                        fontFamily: 'PressStart2P',
                        fontSize: 16,
                        color: colors.text,
                        shadows: [
                          Shadow(
                              color: colors.buttonBorder.withOpacity(0.4),
                              blurRadius: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showPauseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: colors.hudBg,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
                color: colors.buttonBorder.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: colors.buttonBorder.withOpacity(0.15),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.buttonBorder.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.pause_rounded,
                        color: colors.accent, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PAUSED',
                        style: TextStyle(
                          fontFamily: 'PressStart2P',
                          fontSize: 14,
                          color: colors.text,
                        ),
                      ),
                      Text(
                        'Score: ${_engine.score}',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 13,
                          color: colors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _PremiumDialogButton(
                label: 'RESUME',
                icon: '▶',
                isPrimary: true,
                colors: colors,
                onTap: () {
                  Navigator.pop(ctx);
                  _engine.resume();
                },
              ),

              const SizedBox(height: 12),

              _PremiumDialogButton(
                label: 'RESTART',
                icon: '🔄',
                isPrimary: false,
                colors: colors,
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      pageBuilder: (c, a1, a2) => GameScreen(
                        mode: widget.mode,
                        difficulty: widget.difficulty,
                        themeType: widget.themeType,
                        campaignLevel: widget.campaignLevel,
                        dailyEvent: widget.dailyEvent,
                      ),
                      transitionDuration: Duration.zero,
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              _PremiumDialogButton(
                label: 'MAIN MENU',
                icon: '🏠',
                isPrimary: false,
                colors: colors,
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium Dialog Button
// ─────────────────────────────────────────────────────────────────────────────

class _PremiumDialogButton extends StatefulWidget {
  final String label;
  final String icon;
  final bool isPrimary;
  final AppThemeColors colors;
  final VoidCallback onTap;
  const _PremiumDialogButton(
      {required this.label,
      required this.icon,
      required this.isPrimary,
      required this.colors,
      required this.onTap});
  @override
  State<_PremiumDialogButton> createState() =>
      _PremiumDialogButtonState();
}

class _PremiumDialogButtonState extends State<_PremiumDialogButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: double.infinity,
        height: 52,
        transform: _pressed
            ? (Matrix4.identity()..scale(0.97, 0.97))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: widget.isPrimary
              ? LinearGradient(
                  colors: [
                    widget.colors.buttonBorder,
                    Color.lerp(widget.colors.buttonBorder,
                        widget.colors.accent, 0.4)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: widget.isPrimary
              ? null
              : widget.colors.background.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: widget.isPrimary
              ? null
              : Border.all(
                  color: widget.colors.buttonBorder.withOpacity(0.25)),
          boxShadow: _pressed || !widget.isPrimary
              ? []
              : [
                  BoxShadow(
                    color: widget.colors.buttonBorder.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 12,
                color: widget.isPrimary
                    ? Colors.white
                    : widget.colors.text,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Keyboard hint (web)
// ─────────────────────────────────────────────────────────────────────────────

class _KeyboardHint extends StatelessWidget {
  final AppThemeColors colors;
  const _KeyboardHint({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _KeyCap('↑', colors),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _KeyCap('←', colors),
              const SizedBox(width: 4),
              _KeyCap('↓', colors),
              const SizedBox(width: 4),
              _KeyCap('→', colors),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Arrow keys  or  WASD  •  P / Esc = pause',
            style: TextStyle(
              fontSize: 9,
              color: colors.text.withOpacity(0.5),
              fontFamily: 'Orbitron',
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyCap extends StatelessWidget {
  final String label;
  final AppThemeColors colors;
  const _KeyCap(this.label, this.colors);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.buttonBg.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.buttonBorder.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colors.buttonBorder.withOpacity(0.3),
            offset: const Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.text,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
