import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants/app_colors.dart';
import '../core/enums/game_mode.dart';
import '../core/enums/theme_type.dart';
import '../core/utils/layout_util.dart';
import '../providers/settings_provider.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../widgets/ads/banner_ad_widget.dart';
import '../widgets/ui/dynamic_background.dart';
import 'game_screen.dart';
import 'loadout_screen.dart';
import 'settings_screen.dart';
import 'leaderboard_screen.dart';
import '../core/models/daily_event.dart';
import '../core/models/social_challenge.dart';
import '../core/models/seasonal_content.dart';
import '../core/models/game_modifier.dart';
import 'how_to_play_screen.dart';
import 'achievements_screen.dart';
import 'shop_screen.dart';
import 'quests_screen.dart';
import 'campaign_screen.dart';
import 'profile_screen.dart';
import 'multiplayer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  GameMode _selectedMode = GameMode.classic;
  late AnimationController _bgController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _maybeShowStreakPopup());
  }

  void _maybeShowStreakPopup() {
    final storage = StorageService();
    final streak = storage.dailyStreak;
    if (streak < 2) return; // only show from day 2+
    final shownDate = storage.streakRewardShownDate;
    if (shownDate == storage.todayString()) return; // already shown today
    storage.markStreakRewardShown();
    _showStreakDialog(streak);
  }

  void _showStreakDialog(int streak) {
    final settings = context.read<SettingsProvider>();
    final accent = _accentForTheme(settings.theme);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D0D0D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: accent.withOpacity(0.5), width: 1.5),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(
              '$streak DAY STREAK!',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re on fire! Keep your streak alive to earn bigger coin rewards.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('AWESOME!',
                  style: TextStyle(fontFamily: 'Orbitron', fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  AppThemeColors _colors(ThemeType t) {
    switch (t) {
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

  String _fontFamily(ThemeType t) =>
      t == ThemeType.retro ? 'PressStart2P' : 'Orbitron';

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final userProvider = context.watch<UserProvider>();
    final colors = _colors(settings.theme);
    final font = _fontFamily(settings.theme);
    final seasonal = userProvider.seasonalContent;

    return Scaffold(
      backgroundColor: colors.background,
      body: DynamicBackground(
        themeType: settings.theme,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: LayoutUtil.spacing(context, 20),
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: LayoutUtil.spacing(context, 16)),

                            // ── Top bar: Rank + User ───────────────────────
                            _TopBar(
                                    colors: colors,
                                    font: font,
                                    settings: settings)
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: -0.2, end: 0),

                            SizedBox(height: LayoutUtil.spacing(context, 20)),

                            // ── Hero Title ────────────────────────────────
                            _HeroTitle(
                              colors: colors,
                              font: font,
                              pulseController: _pulseController,
                            ).animate().fadeIn(delay: 100.ms),

                            SizedBox(height: LayoutUtil.spacing(context, 24)),

                            // ── Mode Selector ─────────────────────────────
                            _ModeSelectorCard(
                              selected: _selectedMode,
                              colors: colors,
                              fontFamily: font,
                              onSelected: (m) =>
                                  setState(() => _selectedMode = m),
                            ).animate().fadeIn(delay: 200.ms),

                            SizedBox(height: LayoutUtil.spacing(context, 20)),

                            // ── PLAY Button ───────────────────────────────
                            _PlayButton(
                              colors: colors,
                              font: font,
                              pulseController: _pulseController,
                              onTap: () => _startGame(settings),
                            ).animate().fadeIn(delay: 300.ms).scale(
                                  begin: const Offset(0.9, 0.9),
                                  end: const Offset(1, 1),
                                  delay: 300.ms,
                                ),

                            SizedBox(height: LayoutUtil.spacing(context, 16)),

                            // ── Daily Event Card ──────────────────────────
                            if (userProvider.currentDailyEvent != null)
                              _DailyEventCard(
                                event: userProvider.currentDailyEvent!,
                                colors: colors,
                                font: font,
                                onTap: () => _startEventGame(
                                    settings, userProvider.currentDailyEvent!),
                              )
                                  .animate()
                                  .fadeIn(delay: 350.ms)
                                  .slideY(begin: 0.1, end: 0),

                            const SizedBox(height: 10),

                            _SeasonalSpotlightCard(
                              season: seasonal,
                              colors: colors,
                              font: font,
                              onTap: () {
                                setState(() =>
                                    _selectedMode = seasonal.suggestedMode);
                              },
                            )
                                .animate()
                                .fadeIn(delay: 365.ms)
                                .slideY(begin: 0.08, end: 0),

                            if (userProvider.socialChallenge != null) ...[
                              const SizedBox(height: 10),
                              _SocialChallengeCard(
                                challenge: userProvider.socialChallenge!,
                                bestScore: userProvider.bestScore,
                                colors: colors,
                                font: font,
                                onClaim: () async {
                                  final claimed = await userProvider
                                      .claimSocialChallengeReward();
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        claimed
                                            ? 'Challenge reward claimed!'
                                            : 'Beat the target first to claim.',
                                      ),
                                    ),
                                  );
                                },
                              )
                                  .animate()
                                  .fadeIn(delay: 375.ms)
                                  .slideY(begin: 0.08, end: 0),
                            ],

                            const SizedBox(height: 12),

                            _NextGoalCard(
                              colors: colors,
                              hint: userProvider.personalizedHint,
                            )
                                .animate()
                                .fadeIn(delay: 380.ms)
                                .slideY(begin: 0.06, end: 0),

                            SizedBox(height: LayoutUtil.spacing(context, 16)),

                            // ── Navigation Grid ───────────────────────────
                            _NavGrid(
                              colors: colors,
                              font: font,
                              selectedMode: _selectedMode,
                              onTap: _goTo,
                              themeType: settings.theme,
                            ).animate().fadeIn(delay: 400.ms),

                            SizedBox(height: LayoutUtil.spacing(context, 20)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const BannerAdWidget(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _startEventGame(SettingsProvider settings, DailyEvent event) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (c, a1, a2) => GameScreen(
          mode: event.baseMode,
          difficulty: settings.difficulty,
          themeType: event.forcedTheme ?? settings.theme,
          dailyEvent: event,
        ),
        transitionsBuilder: (c, a1, a2, child) =>
            FadeTransition(opacity: a1, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _showRebornDialog(UserProvider user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF060B14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.amber, width: 2),
        ),
        title: const Text('🌟 ASCEND TO REBORN?',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Orbitron',
                color: Colors.amber,
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You have reached the maximum rank! Ascending will:',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 16),
            const _RebornFeature(
                icon: '♻️', text: 'Reset your level to Hatchling'),
            _RebornFeature(
                icon: '🆙',
                text: 'Inc. Prestige Level (Current: ${user.prestigeLevel})'),
            const _RebornFeature(
                icon: '💰', text: '+10% Score & Coin multiplier'),
            const SizedBox(height: 20),
            const Text(
                'Are you ready to start your journey again with even greater power?',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('NOT YET',
                style:
                    TextStyle(color: Colors.white38, fontFamily: 'Orbitron')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              user.reborn();
              Navigator.pop(context);
              ScaffoldMessenger.of(this.context).showSnackBar(
                const SnackBar(content: Text('🎉 YOU HAVE BEEN REBORN!')),
              );
            },
            child: const Text('ASCEND',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
          ),
        ],
      ),
    );
  }

  void _startGame(SettingsProvider settings) {
    if (_selectedMode == GameMode.campaign) {
      _goTo(context, CampaignScreen(themeType: settings.theme));
      return;
    }

    if (_selectedMode == GameMode.multiplayer) {
      _goTo(context, const MultiplayerScreen());
      return;
    }

    if (_selectedMode == GameMode.explore) {
      _launchExploreWithLoadout(settings);
      return;
    }

    if (settings.showRunModifierPrompt) {
      _showModifierSheet(settings);
    } else {
      _launchGame(settings, null);
    }
  }

  Future<void> _launchExploreWithLoadout(SettingsProvider settings) async {
    final result = await Navigator.push<LoadoutResult>(
      context,
      MaterialPageRoute(builder: (_) => const LoadoutScreen()),
    );
    if (!mounted) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (c, a1, a2) => GameScreen(
          mode: GameMode.explore,
          difficulty: settings.difficulty,
          themeType: settings.theme,
          equippedGear: result?.gear ?? [],
        ),
        transitionsBuilder: (c, a1, a2, child) =>
            FadeTransition(opacity: a1, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _launchGame(SettingsProvider settings, GameModifier? modifier) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (c, a1, a2) => GameScreen(
          mode: _selectedMode,
          difficulty: settings.difficulty,
          themeType: settings.theme,
          modifier: modifier,
        ),
        transitionsBuilder: (c, a1, a2, child) =>
            FadeTransition(opacity: a1, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Color _accentForTheme(ThemeType t) {
    switch (t) {
      case ThemeType.retro:
        return AppThemeColors.retro.food;
      case ThemeType.neon:
        return AppThemeColors.neon.food;
      case ThemeType.nature:
        return AppThemeColors.nature.food;
      case ThemeType.arcade:
        return AppThemeColors.arcade.food;
      case ThemeType.cyber:
        return AppThemeColors.cyber.food;
      case ThemeType.volcano:
        return AppThemeColors.volcano.food;
      case ThemeType.ice:
        return AppThemeColors.ice.food;
    }
  }

  void _showModifierSheet(SettingsProvider settings) {
    final modifier = GameModifier.roll();
    final accent = _accentForTheme(settings.theme);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: accent.withOpacity(0.4), width: 1.5),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'TONIGHT\'S TWIST',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 13,
                letterSpacing: 3,
                color: accent.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              modifier.icon,
              style: const TextStyle(fontSize: 52),
            ),
            const SizedBox(height: 12),
            Text(
              modifier.title,
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: accent,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              modifier.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _launchGame(settings, null);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      foregroundColor: Colors.white54,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Skip',
                        style: TextStyle(fontFamily: 'Orbitron', fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _launchGame(settings, modifier);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('PLAY WITH TWIST',
                        style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _goTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final tween = Tween(begin: const Offset(0.0, 0.05), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeOutCubic));
          final fadeTween = Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOutCubic));
          return FadeTransition(
            opacity: animation.drive(fadeTween),
            child: SlideTransition(
              position: animation.drive(tween),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final AppThemeColors colors;
  final String font;
  final SettingsProvider settings;
  const _TopBar(
      {required this.colors, required this.font, required this.settings});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final auth = context.watch<AuthService>();
    final streak = userProvider.dailyStreak;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.buttonBg.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.buttonBorder.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: colors.buttonBorder.withValues(alpha: 0.08),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  colors.buttonBorder.withValues(alpha: 0.6),
                  colors.buttonBorder.withValues(alpha: 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border:
                  Border.all(color: colors.buttonBorder.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: Text(
                userProvider.rankEmoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Profile Button
          IconButton(
            onPressed: () =>
                (context.findAncestorStateOfType<_HomeScreenState>())
                    ?._goTo(context, ProfileScreen(themeType: settings.theme)),
            icon: Icon(Icons.person_outline_rounded,
                color: colors.text, size: 24),
            tooltip: 'Profile',
          ),

          const SizedBox(width: 8),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        auth.isSignedIn
                            ? auth.playerName.toUpperCase()
                            : 'GUEST PLAYER',
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 10,
                          color: colors.text,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (userProvider.isMaxRank)
                      GestureDetector(
                        onTap: () => (context
                                .findAncestorStateOfType<_HomeScreenState>())
                            ?._showRebornDialog(userProvider),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.5)),
                          ),
                          child: const Text('REBORN',
                              style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Orbitron')),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .shimmer(duration: 2.seconds)
                            .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.1, 1.1)),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      userProvider.rankTitle,
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 9,
                        color: colors.accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: userProvider.rankProgress,
                          minHeight: 4,
                          backgroundColor:
                              colors.background.withValues(alpha: 0.5),
                          color: colors.buttonBorder,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // XP + Coins + Streak
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      '💰 ${userProvider.coins}',
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 9,
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.buttonBorder.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: colors.buttonBorder.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${userProvider.xp} XP',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 9,
                        color: colors.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (streak > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 12)),
                    Text(
                      ' $streak',
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 10,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Title
// ─────────────────────────────────────────────────────────────────────────────

class _HeroTitle extends StatelessWidget {
  final AppThemeColors colors;
  final String font;
  final AnimationController pulseController;
  const _HeroTitle(
      {required this.colors,
      required this.font,
      required this.pulseController});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Animated snake icon
        AnimatedBuilder(
          animation: pulseController,
          builder: (context, _) {
            return Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors.buttonBorder
                        .withOpacity(0.15 + pulseController.value * 0.1),
                    colors.buttonBorder.withOpacity(0.0),
                  ],
                ),
                border: Border.all(
                  color: colors.buttonBorder
                      .withOpacity(0.2 + pulseController.value * 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.buttonBorder
                        .withOpacity(0.1 + pulseController.value * 0.15),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Text('🐍', style: TextStyle(fontSize: 44)),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // Title text
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [colors.text, colors.accent],
          ).createShader(bounds),
          child: Text(
            'SNAKE',
            style: TextStyle(
              fontFamily: font,
              fontSize: LayoutUtil.fontSize(
                  context, font == 'PressStart2P' ? 30 : 38),
              color: Colors.white,
              letterSpacing: 6,
            ),
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'CLASSIC REBORN',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: LayoutUtil.fontSize(context, 11),
            color: colors.accent.withValues(alpha: 0.8),
            letterSpacing: 5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mode Selector Card
// ─────────────────────────────────────────────────────────────────────────────

class _ModeSelectorCard extends StatelessWidget {
  final GameMode selected;
  final AppThemeColors colors;
  final String fontFamily;
  final void Function(GameMode) onSelected;

  const _ModeSelectorCard({
    required this.selected,
    required this.colors,
    required this.fontFamily,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.buttonBg.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.buttonBorder.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'SELECT MODE',
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 9,
                color: colors.text.withOpacity(0.45),
                letterSpacing: 2.5,
              ),
            ),
          ),

          // Mode cards
          SizedBox(
            height: 88,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: GameMode.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final mode = GameMode.values[i];
                final isSelected = mode == selected;
                return GestureDetector(
                  onTap: () => onSelected(mode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    width: 100,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                colors.buttonBorder.withValues(alpha: 0.3),
                                colors.buttonBorder.withValues(alpha: 0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected
                          ? null
                          : colors.buttonBg.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? colors.buttonBorder
                            : colors.buttonBorder.withOpacity(0.12),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: colors.buttonBorder.withOpacity(0.25),
                                blurRadius: 16,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(mode.icon,
                            style: TextStyle(fontSize: isSelected ? 28 : 24)),
                        const SizedBox(height: 6),
                        Text(
                          mode.displayName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 7,
                            color: isSelected
                                ? colors.text
                                : colors.text.withOpacity(0.45),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Mode description
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Container(
              key: ValueKey(selected),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 30,
                    decoration: BoxDecoration(
                      color: colors.buttonBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selected.description,
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 9.5,
                        color: colors.text.withOpacity(0.55),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Play Button
// ─────────────────────────────────────────────────────────────────────────────

class _PlayButton extends StatefulWidget {
  final AppThemeColors colors;
  final String font;
  final AnimationController pulseController;
  final VoidCallback onTap;

  const _PlayButton({
    required this.colors,
    required this.font,
    required this.pulseController,
    required this.onTap,
  });

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Play game now',
      hint: 'Starts the selected game mode',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedBuilder(
          animation: widget.pulseController,
          builder: (context, _) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutQuad,
              width: double.infinity,
              height: 68,
              transform: _pressed
                  ? (Matrix4.identity()..scale(0.97, 0.97))
                  : Matrix4.identity(),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: [
                    widget.colors.buttonBorder,
                    Color.lerp(
                        widget.colors.buttonBorder, widget.colors.accent, 0.5)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: _pressed
                    ? []
                    : [
                        BoxShadow(
                          color: widget.colors.buttonBorder.withOpacity(
                              0.35 + widget.pulseController.value * 0.2),
                          blurRadius: 24 + widget.pulseController.value * 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Shimmer overlay
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: AnimatedBuilder(
                      animation: widget.pulseController,
                      builder: (context, _) {
                        return CustomPaint(
                          size: const Size(double.infinity, 68),
                          painter:
                              _ShimmerPainter(widget.pulseController.value),
                        );
                      },
                    ),
                  ),

                  // Button content
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('▶',
                          style: TextStyle(fontSize: 20, color: Colors.white)),
                      const SizedBox(width: 16),
                      Text(
                        'PLAY NOW',
                        style: TextStyle(
                          fontFamily: widget.font,
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  final double progress;
  _ShimmerPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final x = -100 + progress * (size.width + 200);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment(x / size.width, 0),
      end: Alignment((x + 80) / size.width, 0),
      colors: [
        Colors.white.withOpacity(0),
        Colors.white.withOpacity(0.12),
        Colors.white.withOpacity(0),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Navigation Grid
// ─────────────────────────────────────────────────────────────────────────────

class _NavGrid extends StatelessWidget {
  final AppThemeColors colors;
  final String font;
  final GameMode selectedMode;
  final void Function(BuildContext, Widget) onTap;
  final ThemeType themeType;

  const _NavGrid({
    required this.colors,
    required this.font,
    required this.selectedMode,
    required this.onTap,
    required this.themeType,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(
        label: 'SCORES',
        icon: '🏆',
        color: Colors.amber,
        onTap: () =>
            onTap(context, LeaderboardScreen(initialMode: selectedMode)),
      ),
      _NavItem(
        label: 'SHOP',
        icon: '🛒',
        color: Colors.greenAccent,
        onTap: () => onTap(context, ShopScreen(themeType: themeType)),
      ),
      _NavItem(
        label: 'HOW TO',
        icon: '📖',
        color: Colors.blue,
        onTap: () => onTap(context, const HowToPlayScreen()),
      ),
      _NavItem(
        label: 'AWARDS',
        icon: '🏅',
        color: Colors.purple,
        onTap: () => onTap(context, AchievementsScreen(themeType: themeType)),
      ),
      _NavItem(
        label: 'QUESTS',
        icon: '📅',
        color: Colors.pinkAccent,
        onTap: () => onTap(context, QuestsScreen(themeType: themeType)),
        badgeCount: context
            .watch<UserProvider>()
            .quests
            .where((q) => !q.isCompleted)
            .length,
      ),
      _NavItem(
        label: 'SETTINGS',
        icon: '⚙️',
        color: Colors.teal,
        onTap: () => onTap(context, const SettingsScreen()),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.8,
      children: items
          .asMap()
          .entries
          .map((e) => _NavTile(
                item: e.value,
                colors: colors,
                font: font,
              )
                  .animate(delay: Duration(milliseconds: 450 + e.key * 60))
                  .fadeIn()
                  .slideX(begin: 0.1, end: 0))
          .toList(),
    );
  }
}

class _NavItem {
  final String label;
  final String icon;
  final Color color;
  final VoidCallback onTap;
  final int badgeCount;
  const _NavItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badgeCount = 0,
  });
}

class _NavTile extends StatefulWidget {
  final _NavItem item;
  final AppThemeColors colors;
  final String font;
  const _NavTile(
      {required this.item, required this.colors, required this.font});
  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.item.onTap,
      onTapDown: (_) => setState(() => _hovered = true),
      onTapUp: (_) => setState(() => _hovered = false),
      onTapCancel: () => setState(() => _hovered = false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutQuad,
            transform: _hovered
                ? (Matrix4.identity()..scale(0.96, 0.96))
                : Matrix4.identity(),
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hovered
                  ? widget.colors.buttonBg.withValues(alpha: 0.9)
                  : widget.colors.buttonBg.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _hovered
                    ? widget.item.color.withValues(alpha: 0.6)
                    : widget.colors.buttonBorder.withValues(alpha: 0.35),
                width: _hovered ? 1.5 : 1,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: widget.item.color.withValues(alpha: 0.15),
                        blurRadius: 16,
                      )
                    ]
                  : [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.item.color.withOpacity(0.12),
                  ),
                  child: Center(
                    child: Text(widget.item.icon,
                        style: const TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.item.label,
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 10,
                    color: widget.colors.text.withOpacity(0.85),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          if (widget.item.badgeCount > 0)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '${widget.item.badgeCount}',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
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

class _DailyEventCard extends StatefulWidget {
  final DailyEvent event;
  final AppThemeColors colors;
  final String font;
  final VoidCallback onTap;

  const _DailyEventCard({
    required this.event,
    required this.colors,
    required this.font,
    required this.onTap,
  });

  @override
  State<_DailyEventCard> createState() => _DailyEventCardState();
}

class _DailyEventCardState extends State<_DailyEventCard> {
  late Timer _timer;
  String _timeRemaining = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final diff = tomorrow.difference(now);

    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    final s = diff.inSeconds.remainder(60);

    if (mounted) {
      setState(() {
        _timeRemaining = '${h}h ${m}m ${s}s';
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.colors.accent.withOpacity(0.25),
              widget.colors.buttonBorder.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: widget.colors.accent.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: widget.colors.accent.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: widget.colors.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.event.icon,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'DAILY CHALLENGE',
                        style: TextStyle(
                          fontFamily: widget.font,
                          fontSize: 10,
                          color: widget.colors.accent,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '🔥 $_timeRemaining',
                          style: const TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 8,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.event.title,
                    style: TextStyle(
                      fontFamily: widget.font,
                      fontSize: 16,
                      color: widget.colors.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.event.description,
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 10,
                      color: widget.colors.text.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextGoalCard extends StatelessWidget {
  final AppThemeColors colors;
  final String hint;

  const _NextGoalCard({required this.colors, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.hudBg.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.buttonBorder.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.buttonBorder.withValues(alpha: 0.18),
            ),
            child: const Center(
              child: Text('🎯', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEXT GOAL',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: colors.accent,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hint,
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 10,
                    height: 1.4,
                    color: colors.text.withValues(alpha: 0.75),
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

class _SeasonalSpotlightCard extends StatelessWidget {
  final SeasonalContent season;
  final AppThemeColors colors;
  final String font;
  final VoidCallback onTap;

  const _SeasonalSpotlightCard({
    required this.season,
    required this.colors,
    required this.font,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.buttonBorder.withValues(alpha: 0.25),
              colors.accent.withValues(alpha: 0.14),
              colors.hudBg.withValues(alpha: 0.72),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.buttonBorder.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: colors.buttonBorder.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.hudBg.withValues(alpha: 0.75),
                border: Border.all(
                    color: colors.buttonBorder.withValues(alpha: 0.35)),
              ),
              child: Center(
                child: Text(season.icon, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SEASONAL SPOTLIGHT',
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 9,
                      letterSpacing: 1.3,
                      color: colors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    season.title,
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 14,
                      color: colors.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    season.subtitle,
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 10,
                      color: colors.text.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colors.hudBg.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: colors.buttonBorder.withValues(alpha: 0.28)),
              ),
              child: Text(
                season.suggestedMode.displayName.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialChallengeCard extends StatelessWidget {
  final SocialChallenge challenge;
  final int bestScore;
  final AppThemeColors colors;
  final String font;
  final Future<void> Function() onClaim;

  const _SocialChallengeCard({
    required this.challenge,
    required this.bestScore,
    required this.colors,
    required this.font,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (bestScore / challenge.targetScore).clamp(0.0, 1.0);
    final completed = bestScore >= challenge.targetScore;
    final claimable = completed && !challenge.claimed;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.hudBg.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: claimable
              ? colors.accent.withValues(alpha: 0.55)
              : colors.buttonBorder.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'SOCIAL CHALLENGE',
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 10,
                  letterSpacing: 1.4,
                  color: colors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'vs ${challenge.rivalName}',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 9,
                  color: colors.text.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Score ${challenge.targetScore} in a single run',
            style: TextStyle(
              fontFamily: font,
              fontSize: 13,
              color: colors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: colors.background.withValues(alpha: 0.5),
              color: completed ? colors.accent : colors.buttonBorder,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$bestScore / ${challenge.targetScore}',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 10,
                  color: colors.text.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              Text(
                '${challenge.rewardCoins}💰 + ${challenge.rewardXp}XP',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 10,
                  color: colors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: claimable ? onClaim : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    claimable ? colors.buttonBorder : colors.buttonBg,
                foregroundColor: Colors.white,
                disabledBackgroundColor: colors.buttonBg.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                challenge.claimed
                    ? 'Reward Claimed'
                    : completed
                        ? 'Claim Reward'
                        : 'Beat Challenge First',
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RebornFeature extends StatelessWidget {
  final String icon;
  final String text;
  const _RebornFeature({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text,
                  style: const TextStyle(color: Colors.white, fontSize: 11))),
        ],
      ),
    );
  }
}
