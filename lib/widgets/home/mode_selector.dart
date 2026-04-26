import 'package:flutter/material.dart';
import '../../core/enums/game_mode.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';

class ModeSelectorCard extends StatelessWidget {
  final GameMode selected;
  final AppThemeColors colors;
  final String fontFamily;
  final void Function(GameMode) onSelected;
  final int gamesPlayed;
  final int highestCampaignLevel;

  const ModeSelectorCard({
    super.key,
    required this.selected,
    required this.colors,
    required this.fontFamily,
    required this.onSelected,
    this.gamesPlayed = 99,
    this.highestCampaignLevel = 99,
  });

  bool _isLocked(GameMode mode) => switch (mode) {
        GameMode.explore => highestCampaignLevel < 3,
        GameMode.multiplayer => gamesPlayed < 5,
        _ => false,
      };

  String _unlockHint(GameMode mode) => switch (mode) {
        GameMode.explore => 'Reach campaign\nlevel 3',
        GameMode.multiplayer => 'Play 5 games',
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.buttonBg.withValues(alpha: 0.7),
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
                fontSize: 10,
                color: colors.text.withValues(alpha: 0.5),
                letterSpacing: 2.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Mode cards
          SizedBox(
            height: 96,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: GameMode.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final mode = GameMode.values[i];
                final isSelected = mode == selected;
                final locked = _isLocked(mode);
                return GestureDetector(
                  onTap: locked
                      ? () => ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '🔒 ${_unlockHint(mode)} to unlock ${mode.displayName}',
                                style: TextStyle(
                                    fontFamily: fontFamily, fontSize: 12),
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          )
                      : () => onSelected(mode),
                  child: Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        width: 105,
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    colors.buttonBorder.withValues(alpha: 0.35),
                                    colors.buttonBorder.withValues(alpha: 0.15),
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
                                : colors.buttonBorder.withValues(alpha: 0.15),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: colors.buttonBorder
                                        .withValues(alpha: 0.2),
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
                                style:
                                    TextStyle(fontSize: isSelected ? 28 : 24)),
                            const SizedBox(height: 6),
                            Text(
                              mode.displayName.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 8.5,
                                color: isSelected
                                    ? colors.text
                                    : colors.text.withValues(alpha: 0.5),
                                fontWeight: isSelected
                                    ? FontWeight.w900
                                    : FontWeight.normal,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Lock overlay
                      if (locked)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text('🔒', style: TextStyle(fontSize: 22)),
                            ),
                          ),
                        ),
                    ],
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
                    height: 34,
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
                        fontFamily: AppTypography.modernFont,
                        fontSize: 11,
                        color: colors.text.withValues(alpha: 0.6),
                        height: 1.4,
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
