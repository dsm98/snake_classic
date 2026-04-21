import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants/app_colors.dart';
import '../core/enums/theme_type.dart';
import '../providers/settings_provider.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  AppThemeColors _colors(ThemeType t) {
    switch (t) {
      case ThemeType.retro:  return AppThemeColors.retro;
      case ThemeType.neon:   return AppThemeColors.neon;
      case ThemeType.nature: return AppThemeColors.nature;
      case ThemeType.arcade: return AppThemeColors.arcade;
      case ThemeType.cyber: return AppThemeColors.cyber;
      case ThemeType.volcano: return AppThemeColors.volcano;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colors = _colors(settings.theme);
    final font = settings.theme == ThemeType.retro ? 'PressStart2P' : 'Orbitron';

    final tips = [
      const _TipData(
        icon: '🎮',
        title: 'Controls',
        body: 'Swipe in any direction to steer the snake. On desktop, use Arrow keys or WASD. Press P or Esc to pause.',
        accentColor: Color(0xFF4CAF50),
      ),
      const _TipData(
        icon: '🍎',
        title: 'Eat Food',
        body: 'Collect food items to grow longer and earn points. The bigger you get, the higher your score!',
        accentColor: Color(0xFFE53935),
      ),
      const _TipData(
        icon: '⚡',
        title: 'Power-Ups',
        body: '⚡ Speed Boost — move faster\n🐢 Slow Motion — think carefully\n💎 2x Score — double points\n👻 Ghost Mode — pass through yourself\n✂️ Shrink — cut your length\n🧲 Magnet — food comes to you',
        accentColor: Color(0xFFFFB300),
      ),
      const _TipData(
        icon: '🔥',
        title: 'Combo System',
        body: 'Eat food rapidly to build a combo streak! Combos multiply your score up to 5×. Don\'t let the chain break!',
        accentColor: Color(0xFFFF5722),
      ),
      const _TipData(
        icon: '🌀',
        title: 'Game Modes',
        body: 'Classic — walls are deadly\nPortal — wrap around edges\nMaze — dodge obstacles\nTime Attack — 60 seconds max\nEndless — no walls, speed grows',
        accentColor: Color(0xFF7E57C2),
      ),
      const _TipData(
        icon: '💡',
        title: 'Pro Tips',
        body: '• Plan several moves ahead\n• Use Ghost Mode to escape tight spots\n• Magnet + Score Multiplier = mega points\n• Insane difficulty gives 3× score bonus\n• Login to save scores to the leaderboard',
        accentColor: Color(0xFF00B0FF),
      ),
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
                color: colors.hudBg.withOpacity(0.7),
                border: Border(
                  bottom: BorderSide(
                      color: colors.buttonBorder.withOpacity(0.1)),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: colors.text, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('📖', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Text(
                          'HOW TO PLAY',
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 13,
                            color: colors.text,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── Content ───────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                physics: const BouncingScrollPhysics(),
                itemCount: tips.length,
                itemBuilder: (context, i) {
                  return _TipCard(
                    tip: tips[i],
                    colors: colors,
                    index: i,
                  )
                      .animate(delay: Duration(milliseconds: i * 60))
                      .fadeIn()
                      .slideY(begin: 0.08, end: 0);
                },
              ),
            ),
          ],
        ),
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
  const _TipCard({required this.tip, required this.colors, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.hudBg.withOpacity(0.45),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.buttonBorder.withOpacity(0.12)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Accent bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: tip.accentColor.withOpacity(0.7),
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
                            color: tip.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: tip.accentColor.withOpacity(0.25)),
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
                        color: colors.text.withOpacity(0.6),
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
