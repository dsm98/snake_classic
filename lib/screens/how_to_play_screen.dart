import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants/app_colors.dart';
import '../core/enums/theme_type.dart';
import '../providers/settings_provider.dart';
import 'game_screen.dart';
import '../core/enums/game_mode.dart';

class HowToPlayScreen extends StatefulWidget {
  final bool firstRun;
  const HowToPlayScreen({super.key, this.firstRun = false});

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colors = _colors(settings.theme);
    final font =
        settings.theme == ThemeType.retro ? 'PressStart2P' : 'Orbitron';

    final tips = [
      const _TipData(
        icon: '🎮',
        title: 'Controls',
        body:
            'Swipe in any direction to steer the snake. On desktop, use Arrow keys or WASD. Press P or Esc to pause.',
        accentColor: Color(0xFF4CAF50),
      ),
      const _TipData(
        icon: '🍎',
        title: 'Eat Food',
        body:
            'Collect food items to grow longer and earn points. The bigger you get, the higher your score!',
        accentColor: Color(0xFFE53935),
      ),
      const _TipData(
        icon: '⚡',
        title: 'Power-Ups',
        body:
            '⚡ Speed Boost — move faster\n🐢 Slow Motion — think carefully\n💎 2x Score — double points\n👻 Ghost Mode — pass through yourself\n✂️ Shrink — cut your length\n🧲 Magnet — food comes to you',
        accentColor: Color(0xFFFFB300),
      ),
      const _TipData(
        icon: '🔥',
        title: 'Combo System',
        body:
            'Eat food rapidly to build a combo streak! Combos multiply your score up to 5×. Don\'t let the chain break!',
        accentColor: Color(0xFFFF5722),
      ),
      const _TipData(
        icon: '🌀',
        title: 'Game Modes',
        body:
            'Classic — walls are deadly\nPortal — wrap around edges\nMaze — dodge obstacles\nTime Attack — 60 seconds max\nBlitz — 90 seconds, apples add time\nEndless — no walls, speed grows',
        accentColor: Color(0xFF7E57C2),
      ),
      const _TipData(
        icon: '🗺️',
        title: 'Explore Mode',
        body:
            'Roam a vast procedural map split into biomes. Hunt different creatures for points. Catch enough prey to open a portal to the next floor. Your position is saved — pick up right where you left off!',
        accentColor: Color(0xFF26A69A),
      ),
      const _TipData(
        icon: '🐾',
        title: 'Explore Prey',
        body:
            '🐭 Mouse — slow, nearby\n🐇 Rabbit — dashes away (3 charges)\n🦎 Lizard — hides while still\n🦋 Butterfly — flutters, expires\n🐊 Croc Boss — multi-tile, high value\n🍎 Fruit — static, limited time\n⚔ Elite — aggressive, rare, big reward\n✨ Biome Event — special anomaly with a biome effect',
        accentColor: Color(0xFF66BB6A),
      ),
      const _TipData(
        icon: '🌋',
        title: 'Biomes',
        body:
            'Each biome has unique prey, hazards, and weather. New biomes grant a bonus Soul gem on first visit.\n\n🔥 Lava / Ashlands — rare elites, inferno bonus\n❄️ Frozen Lake / Tundra — frost surge events\n🍄 Mushroom — fruit spawns, primal cache events\n🏛 Ruins — common elites, relic echo events\n🐊 Swamp — croc hunts, primal cache rewards',
        accentColor: Color(0xFFEF6C00),
      ),
      const _TipData(
        icon: '⚡',
        title: 'Elite Encounters',
        body:
            'Elites are aggressive prey marked by an orange glow. They move faster and expire in 22s. Catch them for 320+ pts.\n\n• Lava/Ashlands elites grant 1.6× bonus pts + 30 coins\n• Ruins elites grant 1.3× pts + 15 coins\nElites only spawn in high-danger biomes.',
        accentColor: Color(0xFFFF7043),
      ),
      const _TipData(
        icon: '✨',
        title: 'Biome Events',
        body:
            'A cyan diamond appears when a biome anomaly triggers. An ⚡ BIOME EVENT badge flashes on screen. Catch it within 12s for a biome-exclusive effect:\n\n🔥 Lava → Shield +1\n❄️ Frozen → Dash +2 & Ghost\n🍄 Swamp/Mushroom → +1 Soul gem\n🏛 Cave/Ruins → Extra prey spawn',
        accentColor: Color(0xFF00ACC1),
      ),
      const _TipData(
        icon: '💡',
        title: 'Pro Tips',
        body:
            '• Plan several moves ahead\n• Use Ghost Mode to escape tight spots\n• Magnet + Score Multiplier = mega points\n• Insane difficulty gives 3× score bonus\n• Login to save scores to the leaderboard',
        accentColor: Color(0xFF00B0FF),
      ),
    ];

    final tipGroups = [
      // Page 1: Basics
      [tips[0], tips[1], tips[3]],
      // Page 2: Power-Ups & Modes
      [tips[2], tips[4], tips[10]],
      // Page 3: Explore Mode
      [tips[5], tips[6]],
      // Page 4: Biomes & Events
      [tips[7], tips[8], tips[9]],
    ];

    final pageTitles = [
      'BASICS',
      'POWER-UPS & MODES',
      'EXPLORE MODE',
      'BIOMES & EVENTS',
    ];

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: colors.hudBg.withValues(alpha: 0.7),
                border: Border(
                  bottom: BorderSide(
                      color: colors.buttonBorder.withValues(alpha: 0.1)),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: colors.text, size: 24),
                    onPressed: () {
                      if (widget.firstRun) {
                        _finishFirstRun(context);
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('📖', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HOW TO PLAY',
                              style: TextStyle(
                                fontFamily: font,
                                fontSize: 13,
                                color: colors.text,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              pageTitles[_currentPage],
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 10,
                                color: colors.powerUp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (widget.firstRun)
                    TextButton(
                      onPressed: () => _finishFirstRun(context),
                      child: Text(
                        'SKIP',
                        style: TextStyle(
                          color: colors.text.withValues(alpha: 0.6),
                          fontFamily: 'Orbitron',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),

            // ── Content ───────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: tipGroups.length,
                itemBuilder: (context, pageIndex) {
                  final group = tipGroups[pageIndex];
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    physics: const BouncingScrollPhysics(),
                    itemCount: group.length,
                    itemBuilder: (context, i) {
                      return _TipCard(
                        tip: group[i],
                        colors: colors,
                        index: i,
                      )
                          .animate(delay: Duration(milliseconds: i * 60))
                          .fadeIn()
                          .slideX(begin: 0.05, end: 0);
                    },
                  );
                },
              ),
            ),

            // ── Bottom Navigation ─────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                color: colors.hudBg.withValues(alpha: 0.4),
                border: Border(
                  top: BorderSide(
                      color: colors.buttonBorder.withValues(alpha: 0.1)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back / Previous button
                  TextButton(
                    onPressed: _currentPage == 0
                        ? (widget.firstRun
                            ? () => _finishFirstRun(context)
                            : () => Navigator.pop(context))
                        : () {
                            _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut);
                          },
                    child: Text(
                      _currentPage == 0
                          ? (widget.firstRun ? 'SKIP' : 'BACK')
                          : 'PREVIOUS',
                      style: TextStyle(
                        color: colors.text.withValues(alpha: 0.6),
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Page dots
                  Row(
                    children: List.generate(
                      tipGroups.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? colors.powerUp
                              : colors.text.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Next / Start button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.buttonBorder,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    onPressed: () {
                      if (_currentPage == tipGroups.length - 1) {
                        if (widget.firstRun) {
                          _finishFirstRun(context);
                        } else {
                          Navigator.pop(context);
                        }
                      } else {
                        _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut);
                      }
                    },
                    child: Text(
                      _currentPage == tipGroups.length - 1
                          ? (widget.firstRun ? 'START' : 'DONE')
                          : 'NEXT',
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
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

  Future<void> _finishFirstRun(BuildContext context) async {
    if (!context.mounted) return;
    final settings = context.read<SettingsProvider>();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => GameScreen(
          mode: GameMode.classic,
          difficulty: Difficulty.easy,
          themeType: settings.theme,
          tutorialMode: true,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }
}

class _TipData {
  final String icon;
  final String title;
  final String body;
  final Color accentColor;
  const _TipData({
    required this.icon,
    required this.title,
    required this.body,
    required this.accentColor,
  });
}

class _TipCard extends StatelessWidget {
  final _TipData tip;
  final AppThemeColors colors;
  final int index;
  const _TipCard(
      {required this.tip, required this.colors, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.hudBg.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.buttonBorder.withValues(alpha: 0.12)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Accent bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: tip.accentColor.withValues(alpha: 0.7),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  bottomLeft: Radius.circular(22),
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: tip.accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: tip.accentColor.withValues(alpha: 0.25)),
                          ),
                          child: Center(
                            child: Text(tip.icon,
                                style: const TextStyle(fontSize: 22)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            tip.title,
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 14,
                              color: colors.text,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tip.body,
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 10,
                        color: colors.text.withValues(alpha: 0.6),
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
