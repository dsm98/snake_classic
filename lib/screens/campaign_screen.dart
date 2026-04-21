import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/enums/theme_type.dart';
import '../core/enums/game_mode.dart';
import '../core/models/campaign_level.dart';
import '../providers/user_provider.dart';
import 'game_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CampaignScreen extends StatelessWidget {
  final ThemeType themeType;
  const CampaignScreen({super.key, required this.themeType});

  AppThemeColors get colors {
    switch (themeType) {
      case ThemeType.retro: return AppThemeColors.retro;
      case ThemeType.neon: return AppThemeColors.neon;
      case ThemeType.nature: return AppThemeColors.nature;
      case ThemeType.arcade: return AppThemeColors.arcade;
      case ThemeType.cyber: return AppThemeColors.cyber;
      case ThemeType.volcano: return AppThemeColors.volcano;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final highestLevel = userProvider.highestCampaignLevel;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'ADVENTURE',
          style: TextStyle(color: colors.text, fontFamily: 'Orbitron', fontWeight: FontWeight.bold),
        ),
        backgroundColor: colors.hudBg.withOpacity(0.7),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.text, size: 20),
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
                if (unlocked) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => GameScreen(
                      mode: GameMode.campaign,
                      difficulty: Difficulty.normal,
                      themeType: level.theme,
                      campaignLevel: level,
                    ),
                  ));
                }
              },
            ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX();
          },
        ),
      ),
    );
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCurrent 
              ? colors.buttonBorder.withOpacity(0.2) 
              : isUnlocked 
                  ? colors.hudBg.withOpacity(0.5) 
                  : colors.background.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCurrent 
                ? colors.buttonBorder 
                : isUnlocked 
                    ? colors.buttonBorder.withOpacity(0.4) 
                    : colors.text.withOpacity(0.1),
            width: isCurrent ? 2 : 1,
          ),
          boxShadow: isCurrent ? [
            BoxShadow(color: colors.buttonBorder.withOpacity(0.3), blurRadius: 10)
          ] : [],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isUnlocked ? colors.buttonBorder.withOpacity(0.3) : colors.text.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isUnlocked
                    ? Text('${level.index}', style: TextStyle(fontFamily: 'Orbitron', fontSize: 24, color: colors.text, fontWeight: FontWeight.bold))
                    : Icon(Icons.lock, color: colors.text.withOpacity(0.3)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUnlocked ? level.title : 'Locked',
                    style: TextStyle(
                      fontFamily: 'Orbitron', 
                      fontSize: 16, 
                      color: isUnlocked ? colors.text : colors.text.withOpacity(0.3),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isUnlocked)
                    Text(
                      level.description,
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 11,
                        color: colors.text.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
            if (isCurrent)
               Icon(Icons.play_arrow_rounded, color: colors.buttonBorder, size: 28)
          ],
        ),
      ),
    );
  }
}
