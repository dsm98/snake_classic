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
import '../core/theme/app_typography.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import 'home_screen.dart';
import 'game_screen.dart';
import 'grimoire_screen.dart';
import '../services/ghost_racing_service.dart';
import 'package:flutter/services.dart';
import '../core/models/campaign_level.dart';
import '../core/models/daily_event.dart';
import '../core/models/expedition_gear.dart';

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
  // Reward breakdown
  final int coinsEarned;
  final double streakMultiplier;
  final int streakBonusCoins;
  final int questCoins;
  final bool rankLeveledUp;
  final int newRankLevel;
  final int campaignStars; // 0-3, set when isCampaignWon
  
  // Death Card Details
  final String? killerType;
  final int currentFloor;
  final List<String> equippedGear;

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
    this.coinsEarned = 0,
    this.streakMultiplier = 1.0,
    this.streakBonusCoins = 0,
    this.questCoins = 0,
    this.rankLeveledUp = false,
    this.newRankLevel = 0,
    this.campaignStars = 0,
    this.killerType,
    this.currentFloor = 1,
    this.equippedGear = const [],
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

  String get _fontFamily =>
      widget.themeType == ThemeType.retro ? AppTypography.retroFont : AppTypography.modernFont;

  @override
  void initState() {
    super.initState();

    final reducedMotion = StorageService().reducedMotion;

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (!reducedMotion) _particleController.repeat();

    _countController = AnimationController(
      vsync: this,
      duration:
          reducedMotion ? Duration.zero : const Duration(milliseconds: 1200),
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
    final nextIndex = widget
        .campaignLevel!.index; // campaignLevel index is 1-based usually? wait.
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
        final imagePath =
            await File('${directory.path}/score_share.png').create();
        await imagePath.writeAsBytes(image);
        await Share.shareXFiles([XFile(imagePath.path)],
            text: 'Beat my score in Snake Classic Reborn! 🐍');
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
    final accent = widget.isHighScore ? Colors.amber : colors.buttonBorder;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          // Subtle celebration particles for high score
          if (widget.isHighScore)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _particleController,
                builder: (_, __) => CustomPaint(
                  painter:
                      _CelebrationPainter(_particleController.value, colors),
                ),
              ),
            ),

          // Top glow — larger, more dramatic
          Positioned(
            top: -60,
            left: -40,
            right: -40,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [accent.withOpacity(0.28), Colors.transparent],
                  radius: 0.75,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top bar: share icon ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: _isSharing ? null : _shareScore,
                        child: AnimatedOpacity(
                          opacity: _isSharing ? 0.4 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colors.hudBg.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: colors.buttonBorder.withOpacity(0.2)),
                            ),
                            child: const Text('📤',
                                style: TextStyle(fontSize: 18)),
                          ),
                        ),
                      ).animate().fadeIn(delay: 900.ms),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),

                          // ── Status label ─────────────────────────────
                          Text(
                            widget.isCampaignWon
                                ? 'VICTORY'
                                : widget.isHighScore
                                    ? 'NEW BEST'
                                    : 'GAME OVER',
                            style: TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 13,
                              letterSpacing: 5,
                              color: accent.withOpacity(0.85),
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .slideY(begin: -0.3, end: 0),

                          const SizedBox(height: 12),

                          // ── Attractive share card (screenshot target) ──
                          Screenshot(
                            controller: _screenshotController,
                            child: _ShareCard(
                              score: _displayScore,
                              mode: widget.mode,
                              difficulty: widget.difficulty,
                              snakeLength: widget.snakeLength,
                              bestScore: storage.bestScore,
                              isHighScore: widget.isHighScore,
                              themeType: widget.themeType,
                              colors: colors,
                              fontFamily: _fontFamily,
                              killerType: widget.killerType,
                              currentFloor: widget.currentFloor,
                              equippedGear: widget.equippedGear,
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 350.ms)
                              .slideY(begin: 0.15, end: 0),

                          const SizedBox(height: 20),

                          // ── XP + Coins reward pills ──────────────────
                          Row(
                            children: [
                              if (widget.xpEarned > 0)
                                Expanded(
                                  child: _RewardPill(
                                    icon: storage.rankEmoji,
                                    label: '+${widget.xpEarned} XP',
                                    sublabel: storage.rankTitle,
                                    color: Colors.greenAccent.shade400,
                                    progress: storage.rankProgress,
                                    progressColor: Colors.greenAccent,
                                    bgColor:
                                        Colors.greenAccent.withOpacity(0.08),
                                    borderColor:
                                        Colors.greenAccent.withOpacity(0.25),
                                  ),
                                ),
                              if (widget.xpEarned > 0 && widget.coinsEarned > 0)
                                const SizedBox(width: 10),
                              if (widget.coinsEarned > 0)
                                Expanded(
                                  child: _RewardPill(
                                    icon: '💰',
                                    label: '+${widget.coinsEarned}',
                                    sublabel: widget.streakMultiplier > 1.0
                                        ? '×${widget.streakMultiplier.toStringAsFixed(1)} streak'
                                        : 'coins',
                                    color: Colors.amber,
                                    progress: null,
                                    progressColor: Colors.amber,
                                    bgColor: Colors.amber.withOpacity(0.08),
                                    borderColor: Colors.amber.withOpacity(0.25),
                                  ),
                                ),
                            ],
                          )
                              .animate()
                              .fadeIn(delay: 480.ms)
                              .slideY(begin: 0.2, end: 0),

                          // ── Safari summary ───────────────────────────
                          if (widget.mode == GameMode.explore) ...[
                            const SizedBox(height: 14),
                            _SafariSummaryCard(
                                    colors: colors, fontFamily: _fontFamily)
                                .animate()
                                .fadeIn(delay: 510.ms)
                                .slideY(begin: 0.15, end: 0),
                          ],

                          // ── Campaign star rating ─────────────────────
                          if (widget.isCampaignWon &&
                              widget.campaignLevel != null) ...[
                            const SizedBox(height: 14),
                            _CampaignStarCard(
                              level: widget.campaignLevel!,
                              starsEarned: widget.campaignStars,
                              colors: colors,
                              fontFamily: _fontFamily,
                            ).animate().fadeIn(delay: 505.ms).scale(
                                  begin: const Offset(0.85, 0.85),
                                  end: const Offset(1, 1),
                                  duration: 500.ms,
                                  delay: 505.ms,
                                  curve: Curves.easeOutBack,
                                ),
                          ],

                          // ── Rank-up banner ───────────────────────────
                          if (widget.rankLeveledUp) ...[
                            const SizedBox(height: 14),
                            _RankUpBanner(
                              newRankLevel: widget.newRankLevel,
                              colors: colors,
                              fontFamily: _fontFamily,
                            ).animate().fadeIn(delay: 520.ms).scale(
                                begin: const Offset(0.8, 0.8),
                                end: const Offset(1, 1),
                                duration: 400.ms,
                                delay: 520.ms,
                                curve: Curves.easeOutBack),
                          ],

                          const SizedBox(height: 32),

                          // ── Primary action ───────────────────────────
                          if (widget.isCampaignWon &&
                              widget.campaignLevel != null &&
                              widget.campaignLevel!.index <
                                  CampaignLevel.all.length) ...[
                            _ActionButton(
                              label: 'NEXT LEVEL',
                              icon: '⏭️',
                              isPrimary: true,
                              colors: colors,
                              font: _fontFamily,
                              onTap: _doNextLevel,
                            )
                                .animate()
                                .fadeIn(delay: 600.ms)
                                .slideY(begin: 0.1, end: 0),
                            const SizedBox(height: 10),
                          ],

                          _ActionButton(
                            label: 'PLAY AGAIN',
                            icon: '🔄',
                            isPrimary: !widget.isCampaignWon,
                            colors: colors,
                            font: _fontFamily,
                            onTap: _doRestart,
                          )
                              .animate()
                              .fadeIn(delay: 650.ms)
                              .slideY(begin: 0.1, end: 0),

                          const SizedBox(height: 10),

                          // ── Home ─────────────────────────────────────
                          _ActionButton(
                            label: 'MAIN MENU',
                            icon: '🏠',
                            isPrimary: false,
                            colors: colors,
                            font: _fontFamily,
                            onTap: () =>
                                Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (_) => const HomeScreen()),
                              (r) => false,
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 750.ms)
                              .slideY(begin: 0.1, end: 0),

                          if (widget.mode == GameMode.explore) ...[
                            const SizedBox(height: 10),
                            _ActionButton(
                              label: 'THE GRIMOIRE',
                              icon: '📖',
                              isPrimary: false,
                              colors: colors,
                              font: _fontFamily,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => GrimoireScreen(
                                      themeType: widget.themeType),
                                ),
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 820.ms)
                                .slideY(begin: 0.1, end: 0),
                          ],

                          const SizedBox(height: 10),
                          _GhostCodeShareButton(
                                  colors: colors, font: _fontFamily)
                              .animate()
                              .fadeIn(delay: 850.ms)
                              .slideY(begin: 0.1, end: 0),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Attractive share card (captured as screenshot for sharing)
// ─────────────────────────────────────────────────────────────────────────────

class _ShareCard extends StatelessWidget {
  final int score;
  final GameMode mode;
  final Difficulty difficulty;
  final int snakeLength;
  final int bestScore;
  final bool isHighScore;
  final ThemeType themeType;
  final AppThemeColors colors;
  final String fontFamily;
  
  final String? killerType;
  final int currentFloor;
  final List<String> equippedGear;

  const _ShareCard({
    required this.score,
    required this.mode,
    required this.difficulty,
    required this.snakeLength,
    required this.bestScore,
    required this.isHighScore,
    required this.themeType,
    required this.colors,
    required this.fontFamily,
    this.killerType,
    this.currentFloor = 1,
    this.equippedGear = const [],
  });

  @override
  Widget build(BuildContext context) {
    // Share card always uses a dark, self-contained look so it looks great
    // when saved/shared regardless of current theme brightness.
    final cardBg =
        Color.lerp(colors.background, const Color(0xFF050505), 0.55)!;
    final cardBorder = colors.buttonBorder.withOpacity(0.55);
    final scoreGradient = isHighScore
        ? const [Color(0xFFFFD700), Color(0xFFFF6B00)]
        : [colors.accent, colors.text];
    final labelColor = colors.text.withOpacity(0.55);

    String themeLabel() {
      switch (themeType) {
        case ThemeType.retro:
          return 'CLASSIC';
        case ThemeType.neon:
          return 'NEON';
        case ThemeType.nature:
          return 'NATURE';
        case ThemeType.arcade:
          return 'ARCADE';
        case ThemeType.cyber:
          return 'CYBER';
        case ThemeType.volcano:
          return 'VOLCANO';
        case ThemeType.ice:
          return 'ICE';
      }
    }

    String diffLabel() {
      switch (difficulty) {
        case Difficulty.easy:
          return 'EASY';
        case Difficulty.normal:
          return 'NORMAL';
        case Difficulty.hard:
          return 'HARD';
        case Difficulty.insane:
          return 'INSANE';
      }
    }

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colors.buttonBorder.withOpacity(0.3),
            blurRadius: 40,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header bar ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.buttonBorder.withOpacity(0.25),
                  colors.accent.withOpacity(0.12),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(27)),
              border: Border(
                bottom: BorderSide(color: cardBorder.withOpacity(0.4)),
              ),
            ),
            child: Row(
              children: [
                Text('🐍', style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'SNAKE CLASSIC',
                    style: TextStyle(
                      fontFamily: AppTypography.modernFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: colors.text.withOpacity(0.9),
                      letterSpacing: 2.5,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.buttonBorder.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cardBorder.withOpacity(0.5)),
                  ),
                  child: Text(
                    themeLabel(),
                    style: TextStyle(
                      fontFamily: AppTypography.modernFont,
                      fontSize: 8,
                      color: colors.accent,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Score area ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
            child: Column(
              children: [
                if (isHighScore)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFFFFD700).withOpacity(0.5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('👑', style: TextStyle(fontSize: 12)),
                        SizedBox(width: 6),
                        Text(
                          'NEW HIGH SCORE!',
                          style: TextStyle(
                            fontFamily: AppTypography.modernFont,
                            fontSize: 9,
                            color: Color(0xFFFFD700),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ShaderMask(
                  shaderCallback: (b) => LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: scoreGradient,
                  ).createShader(b),
                  child: Text(
                    '$score',
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: fontFamily == AppTypography.retroFont ? 44 : 72,
                      color: Colors.white,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'POINTS',
                  style: TextStyle(
                    fontFamily: AppTypography.modernFont,
                    fontSize: 9,
                    letterSpacing: 5,
                    color: labelColor,
                  ),
                ),
              ],
            ),
          ),

          // ── Divider ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(
              color: cardBorder.withOpacity(0.4),
              height: 1,
            ),
          ),

          // ── Stats row ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (mode == GameMode.explore) ...[
                  Expanded(
                    child: _StatCol(
                      icon: '☠️',
                      value: killerType ?? 'Unknown',
                      label: 'SLAIN BY',
                      labelColor: labelColor,
                      valueColor: Colors.redAccent,
                    ),
                  ),
                  _StatDivider(color: cardBorder),
                  Expanded(
                    child: _StatCol(
                      icon: '🪜',
                      value: '$currentFloor',
                      label: 'FLOOR',
                      labelColor: labelColor,
                      valueColor: colors.text,
                    ),
                  ),
                  _StatDivider(color: cardBorder),
                  Expanded(
                    child: _StatCol(
                      icon: '🐍',
                      value: '$snakeLength',
                      label: 'LENGTH',
                      labelColor: labelColor,
                      valueColor: colors.text,
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: _StatCol(
                      icon: mode.icon,
                      value: mode.displayName,
                      label: 'MODE',
                      labelColor: labelColor,
                      valueColor: colors.text,
                    ),
                  ),
                  _StatDivider(color: cardBorder),
                  Expanded(
                    child: _StatCol(
                      icon: '🐍',
                      value: '$snakeLength',
                      label: 'LENGTH',
                      labelColor: labelColor,
                      valueColor: colors.text,
                    ),
                  ),
                  _StatDivider(color: cardBorder),
                  Expanded(
                    child: _StatCol(
                      icon: '🏆',
                      value: '$bestScore',
                      label: 'BEST',
                      labelColor: labelColor,
                      valueColor: colors.text,
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (mode == GameMode.explore && equippedGear.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: cardBorder.withOpacity(0.3), height: 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'EQUIPPED:',
                    style: TextStyle(
                      fontFamily: AppTypography.modernFont,
                      fontSize: 8,
                      color: labelColor,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ...equippedGear.map((id) {
                    final gear = ExpeditionGear.all.firstWhere(
                      (g) => g.type.name == id,
                      orElse: () => ExpeditionGear.all.first,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(gear.emoji,
                          style: const TextStyle(fontSize: 14)),
                    );
                  }),
                ],
              ),
            ),
          ],

          // ── Footer ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.18),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(27)),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.accent.withOpacity(0.35)),
                  ),
                  child: Text(
                    diffLabel(),
                    style: TextStyle(
                      fontFamily: AppTypography.modernFont,
                      fontSize: 7,
                      color: colors.accent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Can you beat this? 🎮',
                  style: TextStyle(
                    fontFamily: AppTypography.modernFont,
                    fontSize: 8,
                    color: labelColor,
                    fontStyle: FontStyle.italic,
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

class _StatCol extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final Color labelColor;
  final Color valueColor;
  const _StatCol({
    required this.icon,
    required this.value,
    required this.label,
    required this.labelColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTypography.modernFont,
            fontSize: 11,
            color: valueColor,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.modernFont,
            fontSize: 7,
            color: labelColor,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  final Color color;
  const _StatDivider({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 48,
      color: color.withOpacity(0.3),
    );
  }
}

class _RewardPill extends StatelessWidget {
  final String icon;
  final String label;
  final String sublabel;
  final Color color;
  final double? progress;
  final Color progressColor;
  final Color bgColor;
  final Color borderColor;

  const _RewardPill({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.progress,
    required this.progressColor,
    required this.bgColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: AppTypography.modernFont,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ).copyWith(color: color),
                    ),
                    Text(
                      sublabel,
                      style: TextStyle(
                        fontFamily: AppTypography.modernFont,
                        fontSize: 8,
                        color: color.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: progressColor.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
          ],
        ],
      ),
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
    return Semantics(
      button: true,
      label: widget.label,
      enabled: widget.onTap != null,
      child: GestureDetector(
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
            color: widget.isPrimary
                ? null
                : widget.colors.buttonBg.withOpacity(0.75),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isPrimary
                  ? Colors.transparent
                  : widget.colors.buttonBorder.withOpacity(0.55),
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
                  color: widget.isPrimary ? Colors.white : widget.colors.text,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        )
            .animate(
              onPlay: widget.isPrimary ? (c) => c.repeat() : null,
            )
            .shimmer(
              duration: 2400.ms,
              delay: 800.ms,
              color: Colors.white.withOpacity(0.15),
            ),
      ),
    );
  }
}

class _RankUpBanner extends StatelessWidget {
  final int newRankLevel;
  final AppThemeColors colors;
  final String fontFamily;

  const _RankUpBanner({
    required this.newRankLevel,
    required this.colors,
    required this.fontFamily,
  });

  static const _rankNames = [
    'Hatchling',
    'Crawler',
    'Slitherer',
    'Viper',
    'Python',
    'Cobra',
    'Serpent',
    'Leviathan',
    'Titan',
    'Legend',
  ];

  static const _rankIcons = [
    '🥚',
    '🐛',
    '🌀',
    '🐍',
    '🐉',
    '🌟',
    '⚡',
    '🔥',
    '👑',
    '🏆'
  ];

  @override
  Widget build(BuildContext context) {
    final rank = newRankLevel.clamp(0, _rankNames.length - 1);
    final name = _rankNames[rank];
    final icon = _rankIcons[rank];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.food.withOpacity(0.25),
            colors.snakeHead.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.food.withOpacity(0.6), width: 1.5),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RANK UP!',
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 11,
                    letterSpacing: 3,
                    color: colors.food.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name.toUpperCase(),
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.food,
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

class _AchievementToast extends StatelessWidget {
  final Achievement achievement;
  final AppThemeColors colors;
  const _AchievementToast({required this.achievement, required this.colors});

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
                        fontFamily: AppTypography.modernFont,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(achievement.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppTypography.modernFont)),
                Text('+${achievement.xpReward} XP',
                    style: TextStyle(
                        color: Colors.greenAccent.shade200,
                        fontSize: 10,
                        fontFamily: AppTypography.modernFont)),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .slideX(begin: 1, end: 0, curve: Curves.easeOutBack, duration: 400.ms);
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

// ── Safari Summary Card ──────────────────────────────────────────────────────
class _SafariSummaryCard extends StatelessWidget {
  final AppThemeColors colors;
  final String fontFamily;
  const _SafariSummaryCard({required this.colors, required this.fontFamily});

  @override
  Widget build(BuildContext context) {
    final s = StorageService();
    final counts = s.safariCounts;
    final totalPrey = counts.values.fold(0, (a, b) => a + b);
    final bestStreak = s.safariBestStreak;
    final gems = s.safariGems;
    final biomes = s.safariVisitedBiomes.length;
    final rooms = s.safariRoomsVisited;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌿', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                'SAFARI RESULTS',
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 10,
                  color: Colors.greenAccent,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (gems > 0) ...[
                const Text('💎', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Text(
                  '$gems total',
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _safarStat('🐾 Prey', '$totalPrey'),
              _safarStat('🗺️ Rooms', '$rooms'),
              _safarStat('🌍 Biomes', '$biomes/5'),
              _safarStat('🔥 Streak', '×$bestStreak'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _safarStat(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 10)),
        const SizedBox(height: 3),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ── Campaign Star Rating Card ────────────────────────────────────────────────
class _CampaignStarCard extends StatelessWidget {
  final CampaignLevel level;
  final int starsEarned;
  final AppThemeColors colors;
  final String fontFamily;
  const _CampaignStarCard({
    required this.level,
    required this.starsEarned,
    required this.colors,
    required this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            level.title.toUpperCase(),
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 11,
              color: Colors.amber.shade300,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Animated stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final lit = i < starsEarned;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  lit ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: lit ? Colors.amber : colors.text.withOpacity(0.2),
                  size: 44,
                ).animate(delay: Duration(milliseconds: 200 + i * 150)).scale(
                      begin: const Offset(0.4, 0.4),
                      end: const Offset(1.0, 1.0),
                      curve: Curves.easeOutBack,
                      duration: 400.ms,
                    ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            starsEarned == 3
                ? 'Perfect run! ★★★'
                : starsEarned == 2
                    ? 'Great work! Keep pushing for 3 stars'
                    : starsEarned == 1
                        ? 'Level cleared! Aim higher for more stars'
                        : 'Level passed — try again for stars',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 10,
              color: colors.text.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 10),
          Divider(color: colors.text.withOpacity(0.1), height: 1),
          const SizedBox(height: 8),
          // Score thresholds
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _threshold('★', level.star1Score, starsEarned >= 1),
              _threshold('★★', level.star2Score, starsEarned >= 2),
              _threshold('★★★', level.star3Score, starsEarned >= 3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _threshold(String stars, int score, bool reached) {
    return Column(
      children: [
        Text(stars,
            style: TextStyle(
              color: reached ? Colors.amber : Colors.white24,
              fontSize: 13,
            )),
        const SizedBox(height: 2),
        Text(
          '$score pts',
          style: TextStyle(
            color: reached ? Colors.white70 : Colors.white24,
            fontSize: 10,
            fontFamily: fontFamily,
          ),
        ),
      ],
    );
  }
}

class _GhostCodeShareButton extends StatelessWidget {
  final AppThemeColors colors;
  final String font;

  const _GhostCodeShareButton({required this.colors, required this.font});

  @override
  Widget build(BuildContext context) {
    return _ActionButton(
      label: 'COPY GHOST CODE',
      icon: '👻',
      isPrimary: false,
      colors: colors,
      font: font,
      onTap: () async {
        final code = await GhostRacingService().exportShareCode();
        if (code != null) {
          await Clipboard.setData(ClipboardData(text: code));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ghost Code copied to clipboard! Share it with friends.'),
              ),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No best run recorded yet!')),
            );
          }
        }
      },
    );
  }
}
