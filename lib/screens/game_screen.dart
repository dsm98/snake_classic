import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../core/enums/direction.dart';
import '../core/enums/game_mode.dart';
import '../core/enums/theme_type.dart';
import '../core/models/high_score.dart';
import '../providers/settings_provider.dart';
import '../core/models/campaign_level.dart';
import '../core/models/daily_event.dart';
import '../core/models/game_modifier.dart';
import '../core/enums/snake_skin.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/game_engine.dart';
import '../providers/user_provider.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../services/vibration_service.dart';
import '../services/leaderboard_service.dart';
import '../services/auth_service.dart';
import '../widgets/game/game_board.dart';
import '../widgets/game/game_hud.dart';
import '../widgets/game/swipe_controller.dart';
import '../widgets/game/particle_system.dart';
import '../services/ad_service.dart';
import '../services/analytics_service.dart';
import 'game_over_screen.dart';
import 'home_screen.dart';
import 'altar_screen.dart';

class GameScreen extends StatefulWidget {
  final GameMode mode;
  final Difficulty difficulty;
  final ThemeType themeType;
  final CampaignLevel? campaignLevel;
  final DailyEvent? dailyEvent;
  final bool comebackBonus;
  final bool tutorialMode;
  final GameModifier? modifier;
  final List<String> equippedGear;

  const GameScreen({
    super.key,
    required this.mode,
    required this.difficulty,
    required this.themeType,
    this.campaignLevel,
    this.dailyEvent,
    this.comebackBonus = false,
    this.tutorialMode = false,
    this.modifier,
    this.equippedGear = const [],
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late GameEngine _engine;
  bool _started = false;
  int _countdown = 3;
  int _revivesUsed = 0;
  double _eatFlash = 0.0; // 0..1 screen flash overlay
  bool _isDead = false;
  late final GlobalKey<ParticleSystemState> _particleKey = GlobalKey();
  late AnimationController _countdownController;
  late AnimationController _shakeController;
  bool _tutorialMoved = false;
  int _tutorialStep = 0;
  bool _tutorialCompleted = false;
  final Set<int> _loggedTutorialSteps = <int>{};

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
      modifier: widget.modifier,
      equippedGear: widget.equippedGear,
    );
    _wireEngineCallbacks();
    _engine.addListener(_onEngineUpdate);

    if (widget.tutorialMode) {
      _tutorialStep = 0;
      _tutorialMoved = false;
    }

    if (kIsWeb) {
      HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    }

    _startCountdown();
  }

  void _wireEngineCallbacks() {
    _engine.onFoodEaten = () {
      AudioService().play(SoundEffect.eat);
      _particleKey.currentState?.fireBurst(_engine.snake.first, colors.food);
      // Brief screen flash
      if (mounted) {
        setState(() => _eatFlash = 1.0);
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _eatFlash = 0.0);
        });
      }
    };
    _engine.onPowerUpCollected = () {
      AudioService().play(SoundEffect.powerUp);
      _particleKey.currentState
          ?.fireBurst(_engine.snake.first, colors.powerUp, count: 20);
    };
    _engine.onPoisonEaten = () {
      _shakeController.forward(from: 0);
      _particleKey.currentState
          ?.fireBurst(_engine.snake.first, Colors.purple, count: 30);
    };
    _engine.onComboDropped = () {
      _shakeController.forward(from: 0);
    };
    _engine.onHighScoreReached = () {
      AudioService().play(SoundEffect.highScore);
      _particleKey.currentState
          ?.fireBurst(_engine.snake.first, Colors.amber, count: 100);
      // Optional: Add notification or visual text
    };
    _engine.onGameOver = _onGameOverTriggered;
  }

  void _onEngineUpdate() {
    _particleKey.currentState?.setWeather(_engine.currentBiome);

    if (!widget.tutorialMode || _tutorialCompleted) return;

    bool changed = false;
    if (_tutorialMoved && _tutorialStep < 1) {
      _tutorialStep = 1;
      changed = true;
      _logTutorialStep(1);
    }

    if (_engine.snake.length >= 6 && _tutorialStep < 2) {
      _tutorialStep = 2;
      changed = true;
      _logTutorialStep(2);
    }

    if (_engine.snake.length >= 8 && !_tutorialCompleted) {
      _tutorialCompleted = true;
      _tutorialStep = 3;
      _engine.pause();
      changed = true;
      _logTutorialStep(3);
    }

    if (changed && mounted) {
      setState(() {});
    }
  }

  void _logTutorialStep(int step) {
    if (_loggedTutorialSteps.add(step)) {
      AnalyticsService().logTutorialCheckpoint(step);
    }
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
      _onDirectionChanged(dir);
      return true;
    }
    return false;
  }

  void _onDirectionChanged(Direction dir) {
    if (widget.tutorialMode && !_tutorialMoved) {
      setState(() {
        _tutorialMoved = true;
      });
    }
    _engine.changeDirection(dir);
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
      AnalyticsService()
          .logGameStarted(widget.mode.name, widget.difficulty.name);
      _engine.start();
    }
  }

  void _onGameOverTriggered() {
    if (mounted) setState(() => _isDead = true);
    if (widget.tutorialMode && !_tutorialCompleted) {
      _showTutorialRetryDialog();
      return;
    }

    if (widget.mode == GameMode.campaign && _engine.isCampaignWon) {
      _handleGameOver();
      return;
    }

    _shakeController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      if (_revivesUsed < AppConstants.maxRevivesPerRun) {
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
              border: Border.all(
                  color: colors.buttonBorder.withOpacity(0.4), width: 1.5),
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
                  'Revives: $_revivesUsed / ${AppConstants.maxRevivesPerRun}',
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
                    if (!adSuccess && mounted) {
                      final canUseEmergency = _revivesUsed == 0;
                      if (canUseEmergency) {
                        _executeRevive();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Ad unavailable. Emergency revive used.'),
                          ),
                        );
                      } else {
                        _handleGameOver();
                      }
                    }
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

  void _showTutorialRetryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) {
        return AlertDialog(
          backgroundColor: colors.hudBg,
          title:
              const Text('Tutorial', style: TextStyle(fontFamily: 'Orbitron')),
          content: const Text(
            'You crashed before finishing the tutorial mission. Try again or skip for now.',
            style: TextStyle(fontFamily: 'Orbitron', fontSize: 12),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(c);
                _restartTutorialRun();
              },
              child:
                  const Text('Retry', style: TextStyle(fontFamily: 'Orbitron')),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(c);
                _completeTutorial(skipped: true);
              },
              child:
                  const Text('Skip', style: TextStyle(fontFamily: 'Orbitron')),
            ),
          ],
        );
      },
    );
  }

  void _restartTutorialRun() {
    AnalyticsService().logTutorialRetry();
    final skin = context.read<UserProvider>().equippedSkin;
    _engine.init(
      mode: widget.mode,
      diff: widget.difficulty,
      skin: skin,
      campaignLevel: widget.campaignLevel,
      withComebackBonus: widget.comebackBonus,
      dailyEvent: widget.dailyEvent,
      modifier: widget.modifier,
      equippedGear: widget.equippedGear,
    );
    _wireEngineCallbacks();
    setState(() {
      _tutorialMoved = false;
      _tutorialStep = 0;
      _tutorialCompleted = false;
      _countdown = 3;
      _started = false;
    });
    _startCountdown();
  }

  Future<void> _completeTutorial({bool skipped = false}) async {
    await StorageService().setTutorialCompleted(true);
    if (skipped) {
      await AnalyticsService().logTutorialSkipped();
    } else {
      await AnalyticsService().logTutorialCompleted();
      // Grant tutorial completion reward: 150 coins + 100 XP
      if (mounted) {
        final userProvider = context.read<UserProvider>();
        await userProvider.addXp(100);
        await StorageService().addCoins(150);
        userProvider.reloadFromStorage();
      }
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _handleGameOver() async {
    final settings = context.read<SettingsProvider>();
    if (settings.vibrationEnabled) {
      await VibrationService().impact();
    }
    await AudioService().play(SoundEffect.gameOver);

    final auth = context.read<AuthService>();
    final connectivityResult = await (Connectivity().checkConnectivity());
    final isOnline = !connectivityResult.contains(ConnectivityResult.none);
    final canSubmitLeaderboard = auth.isSignedIn && isOnline;

    bool isTop = false;
    int xpEarned = 0;
    List<String> newAchievements = [];
    int coinsEarned = 0;
    double streakMultiplier = 1.0;
    int streakBonusCoins = 0;
    int questCoins = 0;
    bool rankLeveledUp = false;
    int newRankLevel = 0;

    if (canSubmitLeaderboard) {
      final score = HighScore(
        score: _engine.score,
        snakeLength: _engine.snake.length,
        mode: widget.mode,
        achievedAt: DateTime.now(),
        playerName: auth.playerName,
      );

      isTop = await LeaderboardService().submitScore(score);
      if (isTop) AudioService().play(SoundEffect.highScore);
    }

    AnalyticsService().logGameOver(
      mode: widget.mode.name,
      difficulty: widget.difficulty.name,
      score: _engine.score,
      snakeLength: _engine.snake.length,
      isHighScore: isTop,
    );

    final userProvider = context.read<UserProvider>();
    final skinCoinMultiplier =
        _engine.equippedSkin == SnakeSkin.golden ? 1.25 : 1.0;
    final result = await userProvider.completeGameSession(
      score: _engine.score,
      snakeLength: _engine.snake.length,
      combo: _engine.combo,
      foodEaten: _engine.snake.length - 3,
      powerUps: _engine.powerUpsCollectedSession,
      goldenApples: _engine.goldenApplesEatenSession,
      poisonApples: _engine.poisonApplesEatenSession,
      coinMultiplier: (widget.dailyEvent?.coinMultiplier ?? 1.0) *
          (widget.modifier?.coinMultiplier ?? 1.0) *
          skinCoinMultiplier,
      path: _engine.sessionPath,
      bonusCoins: _engine.coinsEarnedSession,
    );

    if (widget.mode == GameMode.campaign &&
        _engine.isCampaignWon &&
        widget.campaignLevel != null) {
      userProvider.unlockCampaignLevel(widget.campaignLevel!.index + 1);
      final stars = widget.campaignLevel!.starsForScore(_engine.score);
      await StorageService().saveLevelStars(widget.campaignLevel!.index, stars);
    }

    // Safari session stats
    if (widget.mode == GameMode.explore) {
      final counts = StorageService().safariCounts;
      final safariAchs = await userProvider.completeSafariSession(
        preyCaught: counts.values.fold(0, (a, b) => a + b),
        crocsCaught: counts['croc'] ?? 0,
        roomsVisited: _engine.visitedRooms,
        bestStreak: _engine.huntStreak > 0 ? _engine.huntStreak : 0,
        biomesDiscovered: StorageService().safariVisitedBiomes.length,
        preyTypes: counts.keys.toList(),
      );
      if (safariAchs.isNotEmpty) {
        newAchievements = [...newAchievements, ...safariAchs];
      }
    }

    xpEarned = result['xpEarned'] ?? 0;
    newAchievements = result['newAchievementIds'] ?? [];
    coinsEarned = result['coinsEarned'] ?? 0;
    streakMultiplier = (result['streakMultiplier'] as double?) ?? 1.0;
    streakBonusCoins = result['streakBonusCoins'] ?? 0;
    questCoins = result['questCoins'] ?? 0;
    rankLeveledUp = result['rankLeveledUp'] ?? false;
    newRankLevel = result['newRankLevel'] ?? 0;

    if (mounted) {
      // Frequency-capped interstitial: skip first 5 games, show every N games
      final gamesPlayed = StorageService().gamesPlayed;
      final shouldShowAd = !kIsWeb &&
          gamesPlayed >= 5 &&
          gamesPlayed % AppConstants.interstitialEveryNGames == 0;
      if (shouldShowAd) {
        await AdService().showInterstitial();
      }

      if (!mounted) return;
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
            coinsEarned: coinsEarned,
            streakMultiplier: streakMultiplier,
            streakBonusCoins: streakBonusCoins,
            questCoins: questCoins,
            rankLeveledUp: rankLeveledUp,
            newRankLevel: newRankLevel,
            campaignStars:
                (_engine.isCampaignWon && widget.campaignLevel != null)
                    ? widget.campaignLevel!.starsForScore(_engine.score)
                    : 0,
            killerType: _engine.killerType,
            currentFloor: _engine.currentFloor,
            equippedGear: _engine.equippedGear,
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
    _engine.removeListener(_onEngineUpdate);
    _engine.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final equippedSkin =
        context.select<UserProvider, SnakeSkin>((p) => p.equippedSkin);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: StreamBuilder<List<ConnectivityResult>>(
          stream: Connectivity().onConnectivityChanged,
          builder: (context, connectivitySnapshot) {
            final auth = context.watch<AuthService>();
            final isOnline = connectivitySnapshot.data != null &&
                !connectivitySnapshot.data!.contains(ConnectivityResult.none);
            final canSave = auth.isSignedIn && isOnline;
            const font = 'Orbitron';

            return Stack(
              children: [
                Column(
                  children: [
                    if (!canSave)
                      _buildOfflineBanner(
                          isOnline, auth.isSignedIn, colors, font),
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
                              (widget.mode == GameMode.timeAttack ||
                                      widget.mode == GameMode.blitz) &&
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
                                final shakeDist = math.sin(
                                        _shakeController.value * math.pi * 6) *
                                    12.0 *
                                    (1 - _shakeController.value);
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
                                  onDirectionChanged: _onDirectionChanged,
                                  child: Center(
                                    child: widget.mode == GameMode.explore
                                        ? _buildGameArea(colors, equippedSkin)
                                        : AspectRatio(
                                            aspectRatio: 20 / 28,
                                            child: _buildGameArea(
                                                colors, equippedSkin),
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
                ),
                if (widget.tutorialMode) _buildTutorialOverlay(),
                if (_engine.isCampfirePhase) _buildCampfireOverlay(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCampfireOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🔥 CAMPFIRE',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Floor ${_engine.currentFloor} Cleared.',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              Text(
                'Coins Gathered: 🪙 ${_engine.coinsEarnedSession}',
                style: const TextStyle(fontFamily: 'Orbitron', fontSize: 18, color: Colors.amber),
              ),
              const SizedBox(height: 32),
              const Text(
                'THE MERCHANT',
                style: TextStyle(fontFamily: 'Orbitron', fontSize: 20, color: Colors.purpleAccent, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildMerchantItem('Ghost Shell (Extra Life: ${_engine.wallHitsLeft})', 50, () {
                if (_engine.coinsEarnedSession >= 50) {
                  setState(() {
                    _engine.coinsEarnedSession -= 50;
                    _engine.wallHitsLeft++;
                  });
                }
              }),
              _buildMerchantItem(
                _engine.hasCrocBane ? 'Croc Bane (Owned)' : 'Croc Bane (Stun Immunity)',
                100,
                () {
                  if (_engine.coinsEarnedSession >= 100 && !_engine.hasCrocBane) {
                    setState(() {
                      _engine.coinsEarnedSession -= 100;
                      _engine.hasCrocBane = true;
                    });
                  }
                },
                disabled: _engine.hasCrocBane,
              ),
              if (_engine.currentFloor % 5 == 0) ...[
                const SizedBox(height: 12),
                _PremiumDialogButton(
                  label: 'VISIT ALTAR',
                  icon: '🏛️',
                  isPrimary: false,
                  colors: colors,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AltarScreen()),
                    );
                  },
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: colors.background,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                onPressed: () {
                  setState(() {
                    _engine.nextFloor();
                  });
                },
                child: Text(
                  'DESCEND TO FLOOR ${_engine.currentFloor + 1}',
                  style: const TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMerchantItem(String name, int cost, VoidCallback onBuy, {bool disabled = false}) {
    final canAfford = _engine.coinsEarnedSession >= cost;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name, style: const TextStyle(fontFamily: 'Orbitron', color: Colors.white70)),
          const SizedBox(width: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: disabled || !canAfford ? Colors.grey[800] : Colors.green[700],
            ),
            onPressed: disabled || !canAfford ? null : onBuy,
            child: Text('🪙 $cost', style: const TextStyle(fontFamily: 'Orbitron')),
          ),
        ],
      ),
    );
  }

  Widget _buildGameArea(AppThemeColors colors, SnakeSkin skin) {
    return Container(
      decoration: BoxDecoration(
        color: colors.grid,
        borderRadius: widget.themeType == ThemeType.retro
            ? BorderRadius.zero
            : BorderRadius.circular(12),
        border: Border.all(color: colors.gridLine, width: 2),
        boxShadow: [
          if (widget.themeType != ThemeType.retro)
            BoxShadow(
              color: widget.themeType == ThemeType.neon
                  ? colors.buttonBorder.withOpacity(0.4)
                  : Colors.black.withOpacity(0.4),
              blurRadius: widget.themeType == ThemeType.neon ? 24 : 12,
              spreadRadius: widget.themeType == ThemeType.neon ? 3 : 2,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: widget.themeType == ThemeType.retro
            ? BorderRadius.zero
            : BorderRadius.circular(10),
        child: Stack(
          children: [
            ParticleSystem(
              key: _particleKey,
              gridWidth: 20,
              gridHeight: 28,
              child: GameBoard(
                engine: _engine,
                themeType: widget.themeType,
                skin: skin,
              ),
            ),
            if (_eatFlash > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _eatFlash * 0.25,
                    duration: const Duration(milliseconds: 200),
                    child: Container(color: colors.food),
                  ),
                ),
              ),
            if (_isDead)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _isDead ? 0.35 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          colors: [Color(0x00FF0000), Color(0xAAFF0000)],
                          radius: 0.9,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (widget.mode == GameMode.explore)
              Positioned(
                bottom: 6,
                right: 6,
                child: IgnorePointer(
                  child: _ExploreMinimapWidget(engine: _engine),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialOverlay() {
    String title = 'Tutorial';
    String message = 'Swipe to move your snake';

    if (_tutorialStep == 1) {
      final eaten = (_engine.snake.length - 3).clamp(0, 3);
      message = 'Great. Eat 3 apples ($eaten/3)';
    } else if (_tutorialStep == 2) {
      message = 'Now grow to length 8 (${_engine.snake.length}/8)';
    } else if (_tutorialStep >= 3) {
      title = 'Tutorial Complete';
      message = 'You are ready to play.';
    }

    return Positioned(
      top: 12,
      left: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.hudBg.withOpacity(0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.buttonBorder.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title,
                    style: const TextStyle(
                        fontFamily: 'Orbitron', fontWeight: FontWeight.bold)),
                const Spacer(),
                if (!_tutorialCompleted)
                  TextButton(
                    onPressed: () => _completeTutorial(skipped: true),
                    child: const Text('Skip',
                        style: TextStyle(fontFamily: 'Orbitron')),
                  ),
              ],
            ),
            Text(message,
                style: const TextStyle(fontFamily: 'Orbitron', fontSize: 12)),
            if (_tutorialCompleted)
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _completeTutorial,
                  child: const Text('Finish',
                      style: TextStyle(fontFamily: 'Orbitron')),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineBanner(
      bool isOnline, bool isSignedIn, AppThemeColors colors, String font) {
    final message = !isOnline
        ? 'OFFLINE • Leaderboard unavailable'
        : 'GUEST • Local progress only';

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
              final scale = 1.0 + (1.0 - _countdownController.value) * 0.4;
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
                        color: _countdown == 0 ? colors.accent : colors.text,
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
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: colors.hudBg.withOpacity(0.55),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                    color: colors.buttonBorder.withOpacity(0.35), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 50,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: colors.buttonBorder.withOpacity(0.12),
                    blurRadius: 30,
                    spreadRadius: 2,
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
                          color: colors.buttonBorder.withOpacity(0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: colors.buttonBorder.withOpacity(0.3)),
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
  State<_PremiumDialogButton> createState() => _PremiumDialogButtonState();
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
                    Color.lerp(
                        widget.colors.buttonBorder, widget.colors.accent, 0.4)!,
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
              : Border.all(color: widget.colors.buttonBorder.withOpacity(0.25)),
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
                color: widget.isPrimary ? Colors.white : widget.colors.text,
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
        border:
            Border.all(color: colors.buttonBorder.withOpacity(0.6), width: 1.5),
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

// ─────────────────────────────────────────────────────────────────────────────
// Minimap overlay for explore mode
// ─────────────────────────────────────────────────────────────────────────────

class _ExploreMinimapWidget extends StatelessWidget {
  final GameEngine engine;
  const _ExploreMinimapWidget({required this.engine});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: engine,
      builder: (_, __) => CustomPaint(
        size: const Size(66, 88),
        painter: _MinimapPainter(engine: engine),
      ),
    );
  }
}

class _MinimapPainter extends CustomPainter {
  final GameEngine engine;
  _MinimapPainter({required this.engine});

  static const int cols = 8; // roomCols
  static const int rows = 11; // roomRows

  @override
  void paint(Canvas canvas, Size size) {
    final cw = size.width / cols;
    final ch = size.height / rows;

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(6)),
      Paint()..color = Colors.black.withOpacity(0.55),
    );

    // Biome rooms
    for (final entry in engine.roomBiomes.entries) {
      final rx = entry.key ~/ rows;
      final ry = entry.key % rows;
      canvas.drawRect(
        Rect.fromLTWH(rx * cw, ry * ch, cw, ch),
        Paint()..color = _biomeColor(entry.value),
      );
    }

    // Room grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 0.5;
    for (int rx = 1; rx < cols; rx++) {
      canvas.drawLine(
          Offset(rx * cw, 0), Offset(rx * cw, size.height), gridPaint);
    }
    for (int ry = 1; ry < rows; ry++) {
      canvas.drawLine(
          Offset(0, ry * ch), Offset(size.width, ry * ch), gridPaint);
    }

    // Prey dots
    for (final p in engine.preyList) {
      final px = p.position.x / (cols * 10) * size.width;
      final py = p.position.y / (rows * 10) * size.height;
      canvas.drawCircle(
        Offset(px, py),
        2.0,
        Paint()..color = _preyDotColor(p.type),
      );
    }

    // Snake head (white dot)
    if (engine.snake.isNotEmpty) {
      final h = engine.snake.first;
      final hx = h.x / (cols * 10) * size.width;
      final hy = h.y / (rows * 10) * size.height;
      canvas.drawCircle(
          Offset(hx, hy),
          3.5,
          Paint()
            ..color = Colors.white.withOpacity(0.9)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
      canvas.drawCircle(Offset(hx, hy), 2.5, Paint()..color = Colors.white);
    }

    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(6)),
      Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  Color _biomeColor(dynamic biome) {
    switch (biome.toString()) {
      case 'BiomeType.forest':
        return const Color(0xFF00FF00).withOpacity(0.18);
      case 'BiomeType.desert':
        return const Color(0xFFFF8C00).withOpacity(0.22);
      case 'BiomeType.swamp':
        return const Color(0xFF008080).withOpacity(0.25);
      case 'BiomeType.cave':
        return const Color(0xFF4B0082).withOpacity(0.30);
      case 'BiomeType.ruins':
        return const Color(0xFF808080).withOpacity(0.22);
      default:
        return Colors.transparent;
    }
  }

  Color _preyDotColor(dynamic type) {
    switch (type.toString()) {
      case 'FoodType.mouse':
        return Colors.grey;
      case 'FoodType.rabbit':
        return Colors.white;
      case 'FoodType.lizard':
        return Colors.green;
      case 'FoodType.butterfly':
        return Colors.orange;
      case 'FoodType.croc':
        return Colors.red;
      default:
        return Colors.yellowAccent;
    }
  }

  @override
  bool shouldRepaint(_MinimapPainter old) => true;
}
