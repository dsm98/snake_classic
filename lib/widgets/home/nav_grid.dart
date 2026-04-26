import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/enums/game_mode.dart';
import '../../core/enums/theme_type.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/user_provider.dart';
import '../../screens/leaderboard_screen.dart';
import '../../screens/shop_screen.dart';
import '../../screens/how_to_play_screen.dart';
import '../../screens/achievements_screen.dart';
import '../../screens/quests_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/altar_screen.dart';

class NavGrid extends StatelessWidget {
  final AppThemeColors colors;
  final String font;
  final GameMode selectedMode;
  final void Function(BuildContext, Widget) onTap;
  final ThemeType themeType;

  const NavGrid({
    super.key,
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
      _NavItem(
        label: 'ALTAR',
        icon: '🗡️',
        color: Colors.redAccent,
        onTap: () => onTap(context, const AltarScreen()),
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
                    color: widget.item.color.withValues(alpha: 0.12),
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
                    fontFamily: AppTypography.modernFont,
                    fontSize: 10,
                    color: widget.colors.text.withValues(alpha: 0.85),
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
                      fontFamily: AppTypography.modernFont,
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
