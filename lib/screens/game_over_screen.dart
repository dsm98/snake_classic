import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants/app_colors.dart';
import '../core/enums/game_mode.dart';
import '../core/enums/theme_type.dart';
import '../core/models/achievement.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import 'home_screen.dart';
import 'game_screen.dart';
import '../core/models/campaign_level.dart';
import '../core/models/daily_event.dart';

class GameOverScreen extends StatefulWidget {
  final int score;
  final int snakeLength;
  final GameMode mode;
  final Difficulty difficulty;
  final ThemeType themeType;
  final bool isHighScore;
  final int xpEarned;
  final List<String> newAchievementIds;
  final bool isCampaignWon;
  final CampaignLevel? campaignLevel;
  final DailyEvent? dailyEvent;

  const GameOverScreen({
    super.key,
    required this.score,
    required this.snakeLength,
    required this.mode,
    required this.difficulty,
    required this.themeType,
    required this.isHighScore,
    this.xpEarned = 0,
    this.newAchievementIds = const [],
    this.isCampaignWon = false,
    this.campaignLevel,
    this.dailyEvent,
  });

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _countController;
  final ScreenshotController _screenshotController = ScreenshotController();
  int _displayScore = 0;
  bool _isSharing = false;

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

  String get _fontFamily =>
      widget.themeType == ThemeType.retro ? 'PressStart2P' : 'Orbitron';

  @override
  void initState() {
    super.initState();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _countController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Animate score counter
    _countController.addListener(() {
      final val = (widget.score * _countController.value).round();
      if (mounted) setState(() => _displayScore = val);
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _countController.forward();
        if (widget.isHighScore) {
          AudioService().play(SoundEffect.highScore);
        }
      }
    });

    Future.delayed(const Duration(milliseconds: 1500), _showNewAchievements);
  }

  void _showNewAchievements() {
    if (!mounted || widget.newAchievementIds.isEmpty) return;
    for (int i = 0; i < widget.newAchievementIds.length; i++) {
      final ach = Achievements.findById(widget.newAchievementIds[i]);
      if (ach == null || !mounted) continue;
      Future.delayed(Duration(milliseconds: i * 1200), () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.transparent,
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            content: _AchievementToast(achievement: ach, colors: colors),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
    _countController.dispose();
    super.dispose();
  }

  void _doNextLevel() {
    if (widget.campaignLevel == null) return;
    final nextIndex = widget.campaignLevel!.index; // campaignLevel index is 1-based usually? wait. 
    // let's check index in CampaignLevel.all
    // Index starts at 1 in the model.
    if (nextIndex >= CampaignLevel.all.length) return;
    
    final nextLevel = CampaignLevel.all[nextIndex];
    
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (c, a1, a2) => GameScreen(
          mode: GameMode.campaign,
          difficulty: widget.difficulty,
          themeType: nextLevel.theme,
          campaignLevel: nextLevel,
        ),
        transitionsBuilder: (c, a1, a2, child) =>
            FadeTransition(opacity: a1, child: child),
      ),
    );
  }

  void _doRestart() {
    final wasShortGame = widget.snakeLength <= 6;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (c, a1, a2) => GameScreen(
          mode: widget.mode,
          difficulty: widget.difficulty,
          themeType: widget.themeType,
          campaignLevel: widget.campaignLevel,
          dailyEvent: widget.dailyEvent,
          comebackBonus: wasShortGame,
        ),
        transitionsBuilder: (c, a1, a2, child) =>
            FadeTransition(opacity: a1, child: child),
      ),
    );
  }

  Future<void> _shareScore() async {
    setState(() => _isSharing = true);
    try {
      final image = await _screenshotController.capture();
      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final imagePath = await File('${directory.path}/score_share.png').create();
        await imagePath.writeAsBytes(image);
        await Share.shareXFiles([XFile(imagePath.path)], text: 'Beat my score in Snake Classic Reborn! 🐍');
      }
    } catch (e) {
       debugPrint('Share error: $e');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = StorageService();

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          // Background particles
          if (widget.isHighScore)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _particleController,
                builder: (context, _) => CustomPaint(
                  painter:
                      _CelebrationPainter(_particleController.value, colors),
                ),
              ),
            ),

          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.5,
                  colors: [
                    colors.hudBg.withOpacity(0.3),
                    colors.background,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),

                      // ── GAME OVER title ──────────────────────────────
                      _GameOverTitle(
                        colors: colors,
                        fontFamily: _fontFamily,
                        isHighScore: widget.isHighScore,
                        isCampaignWon: widget.isCampaignWon,
                      ),

                      const SizedBox(height: 24),

                      // ── Score showcase ───────────────────────────────
                      Screenshot(
                        controller: _screenshotController,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.background, // Background for the screenshot
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: _ScoreShowcase(
                            displayScore: _displayScore,
                            realScore: widget.score,
                            snakeLength: widget.snakeLength,
                            mode: widget.mode,
                            difficulty: widget.difficulty,
                            colors: colors,
                            fontFamily: _fontFamily,
                            isHighScore: widget.isHighScore,
                          ),
                        ),
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 16),

                      // ── XP Card ───────────────────────────────────────
                      _XpCard(
                        xpEarned: widget.xpEarned,
                        storage: storage,
                        colors: colors,
                        fontFamily: _fontFamily,
                      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),

                      // ── Streak ────────────────────────────────────────
                      if (storage.dailyStreak > 1) ...[
                        const SizedBox(height: 12),
                        _StreakCard(
                          streak: storage.dailyStreak,
                          colors: colors,
                          fontFamily: _fontFamily,
                        ).animate().fadeIn(delay: 650.ms),
                      ],

                      // ── Near Miss ─────────────────────────────────────
                      if (!widget.isHighScore && !widget.isCampaignWon) ...[
                        const SizedBox(height: 12),
                        _NearMissCard(
                          score: widget.score,
                          snakeLength: widget.snakeLength,
                          storage: storage,
                          colors: colors,
                          fontFamily: _fontFamily,
                        ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.15, end: 0),
                      ],

                      const SizedBox(height: 28),

                      // ── Action buttons ────────────────────────────────
                      if (widget.isCampaignWon && widget.campaignLevel != null && widget.campaignLevel!.index < CampaignLevel.all.length) ...[
                        _ActionButton(
                          label: 'NEXT LEVEL',
                          icon: '⏭️',
                          isPrimary: true,
                          colors: colors,
                          font: _fontFamily,
                          onTap: _doNextLevel,
                        ).animate().fadeIn(delay: 720.ms).slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 12),
                      ],

                      _ActionButton(
                        label: 'PLAY AGAIN',
                        icon: '🔄',
                        isPrimary: !widget.isCampaignWon,
                        colors: colors,
                        font: _fontFamily,
                        onTap: _doRestart,
                      ).animate().fadeIn(delay: 750.ms).slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 12),

                      _ActionButton(
                        label: _isSharing ? 'PREPARING...' : 'SHARE SCORE',
                        icon: '📤',
                        isPrimary: false,
                        colors: colors,
                        font: _fontFamily,
                        onTap: _isSharing ? null : () => _shareScore(),
                      ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 12),

                      _ActionButton(
                        label: 'MAIN MENU',
                        icon: '🏠',
                        isPrimary: false,
                        colors: colors,
                        font: _fontFamily,
                        onTap: () => Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                        ),
                      ).animate().fadeIn(delay: 850.ms).slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _GameOverTitle extends StatelessWidget {
  final AppThemeColors colors;
  final String fontFamily;
  final bool isHighScore;
  final bool isCampaignWon;
  const _GameOverTitle(
      {required this.colors,
      required this.fontFamily,
      required this.isHighScore,
      this.isCampaignWon = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: isCampaignWon ? [Colors.green.shade300, Colors.green.shade600] : [Colors.red.shade300, Colors.red.shade600],
          ).createShader(bounds),
          child: Text(
            isCampaignWon ? 'VICTORY!' : 'GAME OVER',
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 28,
              color: Colors.white,
              letterSpacing: 4,
            ),
            textAlign: TextAlign.center,
          ),
        )
            .animate()
            .scale(
                begin: const Offset(0.4, 0.4),
                end: const Offset(1, 1),
                curve: Curves.elasticOut,
                duration: 700.ms)
            .shake(delay: 750.ms),

        if (isHighScore) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [
                Color(0xFFFFD700),
                Color(0xFFFF8C00),
              ]),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🏆', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  'NEW HIGH SCORE!',
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                          color: Colors.black.withOpacity(0.3), blurRadius: 4)
                    ],
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: 500.ms)
              .shimmer(delay: 600.ms, duration: 1500.ms),
        ],
      ],
    );
  }
}

class _ScoreShowcase extends StatelessWidget {
  final int displayScore;
  final int realScore;
  final int snakeLength;
  final GameMode mode;
  final Difficulty difficulty;
  final AppThemeColors colors;
  final String fontFamily;
  final bool isHighScore;

  const _ScoreShowcase({
    required this.displayScore,
    required this.realScore,
    required this.snakeLength,
    required this.mode,
    required this.difficulty,
    required this.colors,
    required this.fontFamily,
    required this.isHighScore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.hudBg.withOpacity(0.6),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isHighScore
              ? Colors.amber.withOpacity(0.4)
              : colors.buttonBorder.withOpacity(0.25),
          width: isHighScore ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isHighScore
                ? Colors.amber.withOpacity(0.12)
                : colors.buttonBorder.withOpacity(0.08),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Score number
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: isHighScore
                        ? [Colors.amber, Colors.orange]
                        : [colors.text, colors.accent],
                  ).createShader(bounds),
                  child: Text(
                    '$displayScore',
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 72,
                      color: Colors.white,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'POINTS',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 11,
                    color: colors.text.withOpacity(0.4),
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Divider
          Divider(
            color: colors.buttonBorder.withOpacity(0.15),
            thickness: 1,
            height: 1,
          ),

          // Stats grid
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _StatCell(
                  label: 'MODE',
                  value: '${mode.icon} ${mode.displayName}',
                  colors: colors,
                ),
                _VertDivider(colors: colors),
                _StatCell(
                  label: 'DIFFICULTY',
                  value: difficulty.displayName,
                  colors: colors,
                ),
                _VertDivider(colors: colors),
                _StatCell(
                  label: 'LENGTH',
                  value: '$snakeLength',
                  colors: colors,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final AppThemeColors colors;
  const _StatCell({required this.label, required this.value, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 8,
              color: colors.text.withOpacity(0.4),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 11,
              color: colors.accent,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  final AppThemeColors colors;
  const _VertDivider({required this.colors});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: colors.buttonBorder.withOpacity(0.15),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final String icon;
  final bool isPrimary;
  final AppThemeColors colors;
  final String font;
  final VoidCallback? onTap;
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.colors,
    required this.font,
    this.onTap,
  });
  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: _pressed
            ? (Matrix4.identity()..scale(0.97, 0.97))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: widget.isPrimary
              ? LinearGradient(
                  colors: [
                    widget.colors.buttonBorder,
                    Color.lerp(widget.colors.buttonBorder,
                        widget.colors.accent, 0.5)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: widget.isPrimary ? null : widget.colors.hudBg.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isPrimary
                ? Colors.transparent
                : widget.colors.buttonBorder.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: _pressed || !widget.isPrimary
              ? []
              : [
                  BoxShadow(
                    color: widget.colors.buttonBorder.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Text(
              widget.label,
              style: TextStyle(
                fontFamily: widget.font,
                fontSize: 13,
                color: widget.isPrimary
                    ? Colors.white
                    : widget.colors.text,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _XpCard extends StatelessWidget {
  final int xpEarned;
  final StorageService storage;
  final AppThemeColors colors;
  final String fontFamily;
  const _XpCard(
      {required this.xpEarned,
      required this.storage,
      required this.colors,
      required this.fontFamily});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.hudBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.buttonBorder.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(storage.rankEmoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(storage.rankTitle,
                        style: TextStyle(
                            fontFamily: 'Orbitron',
                            color: colors.text,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                    if (xpEarned > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.greenAccent.withOpacity(0.4)),
                        ),
                        child: Text(
                          '+$xpEarned XP',
                          style: const TextStyle(
                            fontFamily: 'Orbitron',
                            color: Colors.greenAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: storage.rankProgress,
                    minHeight: 8,
                    backgroundColor: colors.background.withOpacity(0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colors.buttonBorder,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  storage.rankLevel < 9
                      ? '${storage.xpToNextRank} XP to next rank'
                      : '🌟 MAX RANK',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 8,
                    color: colors.text.withOpacity(0.45),
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

class _StreakCard extends StatelessWidget {
  final int streak;
  final AppThemeColors colors;
  final String fontFamily;
  const _StreakCard(
      {required this.streak,
      required this.colors,
      required this.fontFamily});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.15),
            Colors.deepOrange.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.35), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orange.withOpacity(0.15),
            ),
            child: const Center(
              child: Text('🔥', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$streak Day Streak! 🎉',
                  style: TextStyle(
                      color: Colors.orange,
                      fontFamily: fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              Text('Come back tomorrow to keep it alive!',
                  style: TextStyle(
                      color: Colors.orange.withOpacity(0.6),
                      fontFamily: 'Orbitron',
                      fontSize: 8.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchievementToast extends StatelessWidget {
  final Achievement achievement;
  final AppThemeColors colors;
  const _AchievementToast(
      {required this.achievement, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 16)
        ],
      ),
      child: Row(
        children: [
          Text(achievement.icon, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🏅 Achievement Unlocked!',
                    style: TextStyle(
                        color: Colors.amber,
                        fontSize: 10,
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(achievement.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron')),
                Text('+${achievement.xpReward} XP',
                    style: TextStyle(
                        color: Colors.greenAccent.shade200,
                        fontSize: 10,
                        fontFamily: 'Orbitron')),
              ],
            ),
          ),
        ],
      ),
    ).animate().slideX(begin: 1, end: 0, curve: Curves.easeOutBack, duration: 400.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Near Miss Card
// ─────────────────────────────────────────────────────────────────────────────

class _NearMissCard extends StatelessWidget {
  final int score;
  final int snakeLength;
  final StorageService storage;
  final AppThemeColors colors;
  final String fontFamily;

  const _NearMissCard({
    required this.score,
    required this.snakeLength,
    required this.storage,
    required this.colors,
    required this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    final scoreGap = storage.bestScore - score;
    final lengthGap = storage.bestLength - snakeLength;

    // Only show if within striking distance of personal best
    final showScore = scoreGap > 0 && scoreGap <= (storage.bestScore * 0.3).ceil();
    final showLength = lengthGap > 0 && lengthGap <= 10;

    if (!showScore && !showLength) return const SizedBox.shrink();

    String msg;
    String emoji;
    if (showScore && scoreGap <= 30) {
      msg = 'Only $scoreGap more points for your best score!';
      emoji = '🎯';
    } else if (showLength && lengthGap <= 5) {
      msg = 'Just $lengthGap more food to beat your length record!';
      emoji = '📏';
    } else if (showScore) {
      msg = '$scoreGap points away from your personal best...';
      emoji = '💪';
    } else {
      msg = '$lengthGap more food to match your best run!';
      emoji = '🐍';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.15),
            Colors.deepPurple.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purpleAccent.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SO CLOSE!',
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 10,
                    color: Colors.purpleAccent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  msg,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 11,
                    color: colors.text.withOpacity(0.8),
                    height: 1.4,
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

// ─────────────────────────────────────────────────────────────────────────────
// Celebration background painter for high score
// ─────────────────────────────────────────────────────────────────────────────

class _CelebrationPainter extends CustomPainter {
  final double progress;
  final AppThemeColors colors;

  _CelebrationPainter(this.progress, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 25; i++) {
      final seed = i * 37;
      final x = ((seed * 0.137 + progress * 0.3) % 1.0) * size.width;
      final y = (1.0 - ((progress + i * 0.04) % 1.0)) * size.height;
      final r = 4.0 + (seed % 5);
      final opacity = (0.3 + (i % 3) * 0.15) *
          ((1.0 - ((progress + i * 0.04) % 1.0)).clamp(0.0, 1.0));

      final hue = (i * 47.0) % 360;
      final paint = Paint()
        ..color = HSVColor.fromAHSV(opacity, hue, 0.9, 1.0).toColor();
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter old) =>
      old.progress != progress;
}

class _ShareStat extends StatelessWidget {
  final String label;
  final String value;
  final String font;

  const _ShareStat({required this.label, required this.value, required this.font});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontFamily: font, color: Colors.white60, fontSize: 8)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontFamily: font, color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
