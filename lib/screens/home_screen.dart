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
import 'altar_screen.dart';
import '../services/ghost_racing_service.dart';
import '../core/theme/app_typography.dart';
import '../widgets/home/mode_selector.dart';
import '../widgets/home/nav_grid.dart';
import '../widgets/home/event_cards.dart';
import '../widgets/home/home_components.dart';

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
                fontFamily: AppTypography.modernFont,
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
                  style: TextStyle(fontFamily: AppTypography.modernFont, fontSize: 13)),
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
      t == ThemeType.retro ? AppTypography.retroFont : AppTypography.modernFont;

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
                            TopBar(
                                    colors: colors,
                                    font: font,
                                    settings: settings,
                                    goTo: _goTo,
                                    onShowReborn: () => _showRebornDialog(userProvider))
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: -0.2, end: 0),

                            SizedBox(height: LayoutUtil.spacing(context, 20)),

                            // ── Hero Title ────────────────────────────────
                            HeroTitle(
                              colors: colors,
                              font: font,
                              pulseController: _pulseController,
                            ).animate().fadeIn(delay: 100.ms),

                            SizedBox(height: LayoutUtil.spacing(context, 24)),

                            // ── Mode Selector ─────────────────────────────
                            ModeSelectorCard(
                              selected: _selectedMode,
                              colors: colors,
                              fontFamily: font,
                              onSelected: (m) =>
                                  setState(() => _selectedMode = m),
                            ).animate().fadeIn(delay: 200.ms),

                            SizedBox(height: LayoutUtil.spacing(context, 20)),

                            // ── PLAY Button ───────────────────────────────
                            PlayButton(
                              colors: colors,
                              font: font,
                              pulseController: _pulseController,
                              onTap: () => _startGame(settings),
                            ).animate().fadeIn(delay: 300.ms).scale(
                                  begin: const Offset(0.9, 0.9),
                                  end: const Offset(1, 1),
                                  delay: 300.ms,
                                ),

                            SizedBox(height: LayoutUtil.spacing(context, 12)),

                            GhostChallengeCard(
                                    colors: colors,
                                    font: font,
                                    onImport: _showImportGhostDialog)
                                .animate()
                                .fadeIn(delay: 320.ms)
                                .slideY(begin: 0.1, end: 0),

                            SizedBox(height: LayoutUtil.spacing(context, 16)),

                            // ── Daily Event Card ──────────────────────────
                            if (userProvider.currentDailyEvent != null)
                              DailyEventCard(
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

                            SeasonalSpotlightCard(
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
                              SocialChallengeCard(
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

                            NextGoalCard(
                              colors: colors,
                              hint: userProvider.personalizedHint,
                            )
                                .animate()
                                .fadeIn(delay: 380.ms)
                                .slideY(begin: 0.06, end: 0),

                            SizedBox(height: LayoutUtil.spacing(context, 16)),

                            // ── Navigation Grid ───────────────────────────
                            NavGrid(
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
                fontFamily: AppTypography.modernFont,
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
                fontFamily: AppTypography.modernFont,
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
                fontFamily: AppTypography.modernFont,
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
                            fontFamily: AppTypography.modernFont,
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

  void _showImportGhostDialog() {
    final TextEditingController controller = TextEditingController();
    final settings = context.read<SettingsProvider>();
    final accent = _accentForTheme(settings.theme);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: accent.withOpacity(0.4)),
        ),
        title: const Text('挑战友人', // Challenge Friend (Ghost)
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: AppTypography.modernFont,
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Paste the ghost share code below:',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Code starts with ey...',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accent),
            onPressed: () async {
              final code = controller.text.trim();
              if (code.isEmpty) return;
              final success = await GhostRacingService().importShareCode(code);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                      content: Text(success
                          ? '✅ Ghost imported! Ready to race.'
                          : '❌ Invalid ghost code.')),
                );
              }
            },
            child: const Text('IMPORT',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
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
