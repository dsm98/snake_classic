import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/enums/theme_type.dart';
import '../core/enums/game_mode.dart';
import '../core/models/campaign_level.dart';
import '../providers/settings_provider.dart';
import '../providers/user_provider.dart';
import '../services/storage_service.dart';
import 'game_screen.dart';
import 'loadout_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CampaignScreen extends StatefulWidget {
  final ThemeType themeType;
  const CampaignScreen({super.key, required this.themeType});

  @override
  State<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends State<CampaignScreen> {
  ThemeType get themeType => widget.themeType;

  AppThemeColors get colors {
    switch (themeType) {
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
    final userProvider = context.watch<UserProvider>();
    final settings = context.watch<SettingsProvider>();
    final highestLevel = userProvider.highestCampaignLevel;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'ADVENTURE',
          style: TextStyle(
              color: colors.text,
              fontFamily: 'Orbitron',
              fontWeight: FontWeight.bold),
        ),
        backgroundColor: colors.hudBg.withValues(alpha: 0.7),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: colors.text, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          itemCount: CampaignLevel.all.length,
          itemBuilder: (context, index) {
            final level = CampaignLevel.all[index];
            final unlocked = level.index <= highestLevel;
            final isCurrent = level.index == highestLevel;

            return _LevelCard(
              level: level,
              isUnlocked: unlocked,
              isCurrent: isCurrent,
              colors: colors,
              onTap: () {
                if (unlocked) _launchWithLoadout(level, settings);
              },
            )
                .animate()
                .fadeIn(delay: Duration(milliseconds: 50 * index))
                .slideX();
          },
        ),
      ),
    );
  }

  Future<void> _launchWithLoadout(
      CampaignLevel level, SettingsProvider settings) async {
    final result = await Navigator.of(context).push<LoadoutResult>(
      MaterialPageRoute(builder: (_) => const LoadoutScreen()),
    );
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GameScreen(
        mode: GameMode.campaign,
        difficulty: settings.difficulty,
        themeType: level.theme,
        campaignLevel: level,
        equippedGear: result?.gear ?? [],
      ),
    ));
  }
}

class _LevelCard extends StatelessWidget {
  final CampaignLevel level;
  final bool isUnlocked;
  final bool isCurrent;
  final AppThemeColors colors;
  final VoidCallback onTap;

  const _LevelCard({
    required this.level,
    required this.isUnlocked,
    required this.isCurrent,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final earnedStars =
        isUnlocked ? StorageService().getLevelStars(level.index) : 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCurrent
              ? colors.buttonBorder.withValues(alpha: 0.2)
              : isUnlocked
                  ? colors.hudBg.withValues(alpha: 0.5)
                  : colors.background.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCurrent
                ? colors.buttonBorder
                : isUnlocked
                    ? colors.buttonBorder.withValues(alpha: 0.4)
                    : colors.text.withValues(alpha: 0.1),
            width: isCurrent ? 2 : 1,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                      color: colors.buttonBorder.withValues(alpha: 0.3),
                      blurRadius: 10)
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? colors.buttonBorder.withValues(alpha: 0.3)
                        : colors.text.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isUnlocked
                        ? Text('${level.index}',
                            style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 22,
                                color: colors.text,
                                fontWeight: FontWeight.bold))
                        : Icon(Icons.lock, color: colors.text.withValues(alpha: 0.3)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isUnlocked ? level.title : 'Locked',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 15,
                          color: isUnlocked
                              ? colors.text
                              : colors.text.withValues(alpha: 0.3),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isUnlocked) ...[
                        const SizedBox(height: 4),
                        // ── Star row ──────────────────────────
                        Row(
                          children: List.generate(3, (i) {
                            final lit = i < earnedStars;
                            return Padding(
                              padding: const EdgeInsets.only(right: 3),
                              child: Icon(
                                lit
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: lit
                                    ? Colors.amber
                                    : colors.text.withValues(alpha: 0.25),
                                size: 18,
                              ),
                            );
                          }),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isCurrent)
                  Icon(Icons.play_arrow_rounded,
                      color: colors.buttonBorder, size: 28),
              ],
            ),

            // ── Objectives section (unlocked only) ──────────────
            if (isUnlocked) ...[
              const SizedBox(height: 12),
              Divider(color: colors.text.withValues(alpha: 0.1), height: 1),
              const SizedBox(height: 10),
              ...level.objectives.map(
                (obj) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          size: 13,
                          color: colors.buttonBorder.withValues(alpha: 0.8)),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          obj,
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 10,
                            color: colors.text.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // ── Star thresholds ──────────────────────────────
              Row(
                children: [
                  _starThreshold(
                      '★', level.star1Score, Colors.amber.shade300, colors),
                  const SizedBox(width: 10),
                  _starThreshold('★★', level.star2Score, Colors.amber, colors),
                  const SizedBox(width: 10),
                  _starThreshold(
                      '★★★', level.star3Score, Colors.amber.shade600, colors),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _starThreshold(
      String label, int score, Color starColor, AppThemeColors colors) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: starColor, fontSize: 11)),
        const SizedBox(width: 3),
        Text(
          '$score pts',
          style: TextStyle(
            color: colors.text.withValues(alpha: 0.55),
            fontSize: 10,
            fontFamily: 'Orbitron',
          ),
        ),
      ],
    );
  }
}
