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
import '../services/storage_service.dart';
import '../widgets/ui/dynamic_background.dart';
import 'game_screen.dart';
import 'loadout_screen.dart';
import 'settings_screen.dart';
import 'leaderboard_screen.dart';
import '../core/models/daily_event.dart';
import '../core/models/seasonal_content.dart';
import '../core/models/game_modifier.dart';
import 'how_to_play_screen.dart';
import 'achievements_screen.dart';
import 'shop_screen.dart';
import 'quests_screen.dart';
import 'campaign_screen.dart';
import 'multiplayer_screen.dart';
import '../services/ghost_racing_service.dart';
import '../services/auth_service.dart';
import '../core/theme/app_typography.dart';
import '../widgets/home/mode_selector.dart';
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
  int _currentIndex = 2; // Default to PLAY

  List<RivalGhost> _topGhosts = [];
  bool _ghostsLoading = false;

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

  Future<void> _loadTopGhosts() async {
    if (_ghostsLoading) return;
    setState(() => _ghostsLoading = true);
    try {
      final ghosts = await GhostRacingService().fetchTopGhosts();
      if (mounted) setState(() => _topGhosts = ghosts);
    } catch (_) {
      // Firestore errors are non-fatal; silently fail
    } finally {
      if (mounted) setState(() => _ghostsLoading = false);
    }
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
          side: BorderSide(color: accent.withValues(alpha: 0.5), width: 1.5),
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
                  style: TextStyle(
                      fontFamily: AppTypography.modernFont, fontSize: 13)),
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
          child: IndexedStack(
            index: _currentIndex,
            children: [
              _buildShopTab(colors, font, settings),
              _buildEventsTab(colors, font, userProvider, seasonal, settings),
              _buildPlayTab(colors, font, settings, userProvider),
              _buildSocialTab(colors, font, settings),
              _buildProfileTab(colors, font, settings, userProvider),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(colors, font),
    );
  }

  Widget _buildBottomNav(AppThemeColors colors, String font) {
    return Container(
      decoration: BoxDecoration(
        color: colors.hudBg.withValues(alpha: 0.97),
        border: Border(
          top: BorderSide(color: colors.buttonBorder.withValues(alpha: 0.15)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: colors.accent,
        unselectedItemColor: colors.text.withValues(alpha: 0.35),
        selectedFontSize: 9,
        unselectedFontSize: 9,
        selectedLabelStyle: TextStyle(
          fontFamily: font,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: font,
          fontSize: 9,
          letterSpacing: 0.5,
        ),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_bag_outlined, size: 22),
            activeIcon: Icon(Icons.shopping_bag_rounded,
                size: 24, color: colors.accent),
            label: 'SHOP',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.local_activity_outlined, size: 22),
            activeIcon: Icon(Icons.local_activity_rounded,
                size: 24, color: colors.accent),
            label: 'EVENTS',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.sports_esports_outlined, size: 26),
            activeIcon: Icon(Icons.sports_esports_rounded,
                size: 28, color: colors.accent),
            label: 'PLAY',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_outline_rounded, size: 22),
            activeIcon:
                Icon(Icons.people_rounded, size: 24, color: colors.accent),
            label: 'SOCIAL',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline_rounded, size: 22),
            activeIcon:
                Icon(Icons.person_rounded, size: 24, color: colors.accent),
            label: 'PROFILE',
          ),
        ],
      ),
    );
  }

  Widget _buildPlayTab(AppThemeColors colors, String font,
      SettingsProvider settings, UserProvider userProvider) {
    return Center(
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
                              onShowReborn: () =>
                                  _showRebornDialog(userProvider))
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

                      SizedBox(height: LayoutUtil.spacing(context, 28)),

                      // ── Mode Selector ─────────────────────────────
                      ModeSelectorCard(
                        selected: _selectedMode,
                        colors: colors,
                        fontFamily: font,
                        onSelected: (m) => setState(() => _selectedMode = m),
                        gamesPlayed: StorageService().gamesPlayed,
                        highestCampaignLevel:
                            StorageService().highestCampaignLevel,
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

                      SizedBox(height: LayoutUtil.spacing(context, 16)),
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

  Widget _buildEventsTab(
      AppThemeColors colors,
      String font,
      UserProvider userProvider,
      SeasonalContent seasonal,
      SettingsProvider settings) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTabHeader('LIVE EVENTS', colors, font),
          const SizedBox(height: 20),

          // ── Daily Event Card ──────────────────────────
          if (userProvider.currentDailyEvent != null)
            DailyEventCard(
              event: userProvider.currentDailyEvent!,
              colors: colors,
              font: font,
              onTap: () =>
                  _startEventGame(settings, userProvider.currentDailyEvent!),
            ).animate().fadeIn().slideY(begin: 0.1, end: 0),

          const SizedBox(height: 12),

          SeasonalSpotlightCard(
            season: seasonal,
            colors: colors,
            font: font,
            onTap: () {
              setState(() {
                _selectedMode = seasonal.suggestedMode;
                _currentIndex = 2; // Jump to play tab
              });
            },
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

          if (userProvider.socialChallenge != null) ...[
            const SizedBox(height: 12),
            SocialChallengeCard(
              challenge: userProvider.socialChallenge!,
              bestScore: userProvider.bestScore,
              colors: colors,
              font: font,
              onClaim: () async {
                final claimed = await userProvider.claimSocialChallengeReward();
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
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
          ],
        ],
      ),
    );
  }

  Widget _buildShopTab(
      AppThemeColors colors, String font, SettingsProvider settings) {
    // Embedding ShopScreen content
    return ShopScreen(themeType: settings.theme, isEmbedded: true);
  }

  Widget _buildSocialTab(
      AppThemeColors colors, String font, SettingsProvider settings) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: _buildTabHeader('SOCIAL', colors, font),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: _buildSocialHero(colors, font),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: GhostChallengeCard(
            colors: colors,
            font: font,
            onImport: _showImportGhostDialog,
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: _buildSocialActionCard(
                  'LEADERBOARD',
                  '🏆',
                  colors.accent,
                  colors,
                  font,
                  () => _goTo(
                    context,
                    LeaderboardScreen(
                        initialMode: _selectedMode, isEmbedded: false),
                  ),
                  isActive: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSocialActionCard(
                  'ONLINE GHOSTS',
                  '👻',
                  Colors.purpleAccent,
                  colors,
                  font,
                  _loadTopGhosts,
                ),
              ),
            ],
          ),
        ),
        if (_topGhosts.isNotEmpty) _buildOnlineGhostsList(colors, font),
        if (_ghostsLoading)
          const Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'GLOBAL RANKINGS',
              style: TextStyle(
                fontFamily: font,
                fontSize: 9,
                letterSpacing: 2,
                color: colors.text.withValues(alpha: 0.4),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Expanded(
          child:
              LeaderboardScreen(initialMode: _selectedMode, isEmbedded: true),
        ),
      ],
    );
  }

  Widget _buildSocialHero(AppThemeColors colors, String font) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.accent.withValues(alpha: 0.22),
            colors.buttonBorder.withValues(alpha: 0.2),
            colors.hudBg.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.buttonBorder.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: colors.accent.withValues(alpha: 0.12),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.hudBg.withValues(alpha: 0.75),
              border: Border.all(color: colors.accent.withValues(alpha: 0.45)),
            ),
            child: const Center(
              child: Text('🌐', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COMPETE WITH THE WORLD',
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Challenge rivals, import ghost runs, and climb the seasonal ladder.',
                  style: TextStyle(
                    fontFamily: AppTypography.modernFont,
                    fontSize: 10,
                    color: colors.text.withValues(alpha: 0.68),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineGhostsList(AppThemeColors colors, String font) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.hudBg.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.buttonBorder.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TOP GHOSTS — tap to challenge',
              style: TextStyle(
                fontFamily: font,
                fontSize: 9,
                color: colors.text.withValues(alpha: 0.5),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _topGhosts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final ghost = _topGhosts[i];
                  return GestureDetector(
                    onTap: () async {
                      await GhostRacingService().setRivalGhost(ghost);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${ghost.rivalName} set as rival!',
                              style: TextStyle(fontFamily: font),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: 124,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purpleAccent.withValues(alpha: 0.16),
                            Colors.purpleAccent.withValues(alpha: 0.06),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.purpleAccent.withValues(alpha: 0.35)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            ghost.rivalName,
                            style: TextStyle(
                                fontFamily: font,
                                fontSize: 9,
                                color: colors.text),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${ghost.rivalScore}',
                            style: const TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 12,
                              color: Colors.purpleAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialActionCard(String label, String icon, Color color,
      AppThemeColors colors, String font, VoidCallback onTap,
      {bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.18)
              : colors.hudBg.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive
                ? color.withValues(alpha: 0.6)
                : colors.buttonBorder.withValues(alpha: 0.18),
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.18),
                    blurRadius: 12,
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: font,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isActive ? color : colors.text.withValues(alpha: 0.55),
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab(AppThemeColors colors, String font,
      SettingsProvider settings, UserProvider userProvider) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTabHeader('PROFILE', colors, font),
          const SizedBox(height: 16),
          _buildSectionLabel('ACCOUNT', colors, font),
          const SizedBox(height: 8),
          Consumer<AuthService>(
            builder: (context, auth, _) => _buildProfileAccountCard(
              auth: auth,
              colors: colors,
              font: font,
            ),
          ).animate().fadeIn().slideY(begin: 0.08, end: 0),
          const SizedBox(height: 16),
          NextGoalCard(
            colors: colors,
            hint: userProvider.personalizedHint,
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
          const SizedBox(height: 20),
          _buildSectionLabel('PROGRESS', colors, font),
          const SizedBox(height: 8),
          _buildMenuTile(
                  'ACHIEVEMENTS',
                  '🏅',
                  Colors.purpleAccent,
                  colors,
                  font,
                  () => _goTo(
                      context, AchievementsScreen(themeType: settings.theme)))
              .animate(delay: 50.ms)
              .fadeIn()
              .slideX(begin: 0.05, end: 0),
          _buildLockedMenuTile(
            'QUESTS',
            '🗺️',
            Colors.pinkAccent,
            colors,
            font,
            () => _goTo(context, QuestsScreen(themeType: settings.theme)),
            locked: !StorageService().isUnlocked('quests'),
            unlockHint: 'Play 2 games to unlock',
          ).animate(delay: 100.ms).fadeIn().slideX(begin: 0.05, end: 0),
          const SizedBox(height: 16),
          _buildSectionLabel('GENERAL', colors, font),
          const SizedBox(height: 8),
          _buildMenuTile('HOW TO PLAY', '📖', Colors.blueAccent, colors, font,
                  () => _goTo(context, const HowToPlayScreen()))
              .animate(delay: 150.ms)
              .fadeIn()
              .slideX(begin: 0.05, end: 0),
          _buildMenuTile('SETTINGS', '⚙️', Colors.tealAccent, colors, font,
                  () => _goTo(context, const SettingsScreen()))
              .animate(delay: 200.ms)
              .fadeIn()
              .slideX(begin: 0.05, end: 0),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileAccountCard({
    required AuthService auth,
    required AppThemeColors colors,
    required String font,
  }) {
    final isSignedIn = auth.isSignedIn;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.hudBg.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.buttonBorder.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  colors.buttonBorder.withValues(alpha: 0.5),
                  colors.buttonBorder.withValues(alpha: 0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border:
                  Border.all(color: colors.buttonBorder.withValues(alpha: 0.4)),
            ),
            clipBehavior: Clip.antiAlias,
            child: auth.currentUser?.photoURL != null
                ? Image.network(auth.currentUser!.photoURL!, fit: BoxFit.cover)
                : const Center(
                    child: Text('👤', style: TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSignedIn ? 'SIGNED IN AS' : 'GUEST MODE',
                  style: TextStyle(
                    fontFamily: AppTypography.modernFont,
                    fontSize: 8,
                    color: colors.text.withValues(alpha: 0.45),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSignedIn ? auth.playerName : 'Login to save scores',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 12,
                    color: colors.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (isSignedIn)
            GestureDetector(
              onTap: auth.signOut,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
                ),
                child: const Icon(Icons.logout_rounded,
                    color: Colors.redAccent, size: 20),
              ),
            )
          else
            GestureDetector(
              onTap: auth.signInWithGoogle,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.buttonBorder,
                      Color.lerp(colors.buttonBorder, colors.accent, 0.4)!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'SIGN IN',
                  style: TextStyle(
                    fontFamily: AppTypography.modernFont,
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, AppThemeColors colors, String font) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: font,
        fontSize: 9,
        fontWeight: FontWeight.bold,
        color: colors.text.withValues(alpha: 0.4),
        letterSpacing: 2.5,
      ),
    );
  }

  Widget _buildTabHeader(String title, AppThemeColors colors, String font) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: colors.accent,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: colors.accent.withValues(alpha: 0.5),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontFamily: font,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: colors.text,
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLockedMenuTile(
    String title,
    String icon,
    Color accent,
    AppThemeColors colors,
    String font,
    VoidCallback onTap, {
    bool locked = false,
    String unlockHint = '',
  }) {
    return GestureDetector(
      onTap: locked
          ? () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🔒 $unlockHint',
                      style: TextStyle(fontFamily: font)),
                  duration: const Duration(seconds: 2),
                ),
              )
          : onTap,
      child: Opacity(
        opacity: locked ? 0.4 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: colors.buttonBg.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: accent.withValues(alpha: locked ? 0.1 : 0.25)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 4,
                    color: accent.withValues(alpha: locked ? 0.3 : 0.7),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                locked ? '🔒' : icon,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontFamily: font,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: colors.text,
                                  ),
                                ),
                                if (locked) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    unlockHint,
                                    style: TextStyle(
                                      fontFamily: font,
                                      fontSize: 8,
                                      color:
                                          colors.text.withValues(alpha: 0.45),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 13,
                              color: colors.text.withValues(alpha: 0.2)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile(String title, String icon, Color accent,
      AppThemeColors colors, String font, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: colors.buttonBg.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 4,
                  color: accent.withValues(alpha: 0.7),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(icon,
                                style: const TextStyle(fontSize: 18)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colors.text,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 13,
                            color: colors.text.withValues(alpha: 0.2)),
                      ],
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
          border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
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
                color: accent.withValues(alpha: 0.7),
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
          side: BorderSide(color: accent.withValues(alpha: 0.4)),
        ),
        title: const Text('CHALLENGE FRIEND',
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
                fillColor: Colors.white.withValues(alpha: 0.05),
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
            child:
                const Text('CANCEL', style: TextStyle(color: Colors.white38)),
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
