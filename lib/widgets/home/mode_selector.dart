import 'package:flutter/material.dart';
import '../../core/enums/game_mode.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';

class ModeSelectorCard extends StatelessWidget {
  final GameMode selected;
  final AppThemeColors colors;
  final String fontFamily;
  final void Function(GameMode) onSelected;

  const ModeSelectorCard({
    super.key,
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
                        fontFamily: AppTypography.modernFont,
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
