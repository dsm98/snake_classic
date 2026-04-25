import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants/app_colors.dart';
import '../core/enums/theme_type.dart';
import '../core/models/achievement.dart';
import '../services/storage_service.dart';
import '../core/theme/app_typography.dart';

class AchievementsScreen extends StatelessWidget {
  final ThemeType themeType;
  const AchievementsScreen({super.key, required this.themeType});

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
    final storage = StorageService();
    final allProgress = storage.getAllAchievementProgress();
    final unlocked = allProgress.where((p) => p.unlocked).length;
    final total = Achievements.all.length;
    final pct = unlocked / total;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────
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
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: colors.text, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🏅', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Text(
                          'ACHIEVEMENTS',
                          style: TextStyle(
                            fontFamily: AppTypography.modernFont,
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

            // ── Summary hero card ───────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.hudBg.withValues(alpha: 0.5),
                border: Border(
                  bottom: BorderSide(
                      color: colors.buttonBorder.withValues(alpha: 0.1)),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Rank badge
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              colors.buttonBorder.withValues(alpha: 0.3),
                              colors.buttonBorder.withValues(alpha: 0.05),
                            ],
                          ),
                          border: Border.all(
                              color: colors.buttonBorder.withValues(alpha: 0.4),
                              width: 2),
                        ),
                        child: Center(
                          child: Text(storage.rankEmoji,
                              style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    storage.rankTitle,
                                    style: TextStyle(
                                      fontFamily: AppTypography.modernFont,
                                      fontSize: 15,
                                      color: colors.text,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: colors.buttonBorder
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: colors.buttonBorder
                                            .withValues(alpha: 0.4)),
                                  ),
                                  child: Text(
                                    '$unlocked / $total',
                                    style: TextStyle(
                                      fontFamily: AppTypography.modernFont,
                                      fontSize: 13,
                                      color: colors.buttonBorder,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${storage.totalXp} total XP',
                              style: TextStyle(
                                fontFamily: AppTypography.modernFont,
                                fontSize: 10,
                                color: colors.text.withOpacity(0.45),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Master XP progress bar
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(pct * 100).round()}% Complete',
                            style: TextStyle(
                              fontFamily: AppTypography.modernFont,
                              fontSize: 9,
                              color: colors.text.withValues(alpha: 0.5),
                            ),
                          ),
                          Text(
                            storage.rankLevel < 9
                                ? '${storage.xpToNextRank} XP to ${StorageService.rankTitles[storage.rankLevel + 1]}'
                                : '🌟 MAX RANK',
                            style: TextStyle(
                              fontFamily: AppTypography.modernFont,
                              fontSize: 9,
                              color: colors.text.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: storage.rankProgress,
                              minHeight: 12,
                              backgroundColor:
                                  colors.background.withValues(alpha: 0.5),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  colors.buttonBorder),
                            ),
                          ),
                          // Shimmer
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              height: 12,
                              child: FractionallySizedBox(
                                widthFactor: storage.rankProgress,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0),
                                        Colors.white.withValues(alpha: 0.15),
                                        Colors.white.withOpacity(0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Achievement list ─────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                physics: const BouncingScrollPhysics(),
                itemCount: Achievements.all.length,
                itemBuilder: (ctx, i) {
                  final ach = Achievements.all[i];
                  final prog = storage.getAchievementProgress(ach.id);
                  return _AchievementTile(
                    achievement: ach,
                    progress: prog,
                    colors: colors,
                  )
                      .animate(delay: Duration(milliseconds: i * 35))
                      .fadeIn()
                      .slideX(begin: 0.05, end: 0);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final AchievementProgress progress;
  final AppThemeColors colors;

  const _AchievementTile({
    required this.achievement,
    required this.progress,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final locked = !progress.unlocked;
    final pct = (progress.progress / achievement.targetValue).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: locked
            ? null
            : LinearGradient(
                colors: [
                  colors.buttonBorder.withOpacity(0.12),
                  colors.buttonBorder.withOpacity(0.03),
                ],
              ),
        color: locked ? colors.hudBg.withValues(alpha: 0.3) : null,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: locked
              ? colors.buttonBorder.withValues(alpha: 0.1)
              : colors.buttonBorder.withValues(alpha: 0.4),
          width: locked ? 1 : 1.5,
        ),
        boxShadow: locked
            ? []
            : [
                BoxShadow(
                  color: colors.buttonBorder.withOpacity(0.12),
                  blurRadius: 16,
                )
              ],
      ),
      child: Row(
        children: [
          // Icon circle
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: locked
                  ? null
                  : RadialGradient(
                      colors: [
                        colors.buttonBorder.withOpacity(0.25),
                        colors.buttonBorder.withValues(alpha: 0.05),
                      ],
                    ),
              color: locked ? colors.background.withValues(alpha: 0.4) : null,
              border: Border.all(
                color: locked
                    ? colors.buttonBorder.withOpacity(0.12)
                    : colors.buttonBorder.withValues(alpha: 0.5),
                width: locked ? 1 : 2,
              ),
            ),
            child: Center(
              child: Text(
                locked ? '🔒' : achievement.icon,
                style: TextStyle(fontSize: locked ? 20 : 24),
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: TextStyle(
                    fontFamily: AppTypography.modernFont,
                    fontSize: 12,
                    color: locked ? colors.text.withOpacity(0.35) : colors.text,
                    fontWeight: locked ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontFamily: AppTypography.modernFont,
                    fontSize: 9,
                    color: colors.text.withOpacity(locked ? 0.3 : 0.5),
                    height: 1.4,
                  ),
                ),
                if (!progress.unlocked) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 5,
                            backgroundColor:
                                colors.background.withValues(alpha: 0.5),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colors.buttonBorder.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${progress.progress}/${achievement.targetValue}',
                        style: TextStyle(
                          fontFamily: AppTypography.modernFont,
                          fontSize: 8,
                          color: colors.text.withOpacity(0.35),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 10),

          // XP badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: locked
                  ? Colors.transparent
                  : Colors.greenAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: locked
                    ? colors.buttonBorder.withOpacity(0.12)
                    : Colors.greenAccent.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '+${achievement.xpReward}',
                  style: TextStyle(
                    fontFamily: AppTypography.modernFont,
                    fontSize: 12,
                    color: locked
                        ? colors.text.withValues(alpha: 0.2)
                        : Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'XP',
                  style: TextStyle(
                    fontFamily: AppTypography.modernFont,
                    fontSize: 7,
                    color: locked
                        ? colors.text.withValues(alpha: 0.15)
                        : Colors.greenAccent.withValues(alpha: 0.7),
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
