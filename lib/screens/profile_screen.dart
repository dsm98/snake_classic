import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/enums/theme_type.dart';
import '../core/constants/app_colors.dart';
import '../providers/user_provider.dart';
import '../core/enums/snake_skin.dart';

class ProfileScreen extends StatelessWidget {
  final ThemeType themeType;
  const ProfileScreen({super.key, required this.themeType});

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
    final user = context.watch<UserProvider>();
    
    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: colors.hudBg,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Animated background gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colors.hudBg, colors.background],
                      ),
                    ),
                  ),
                  // Rank Badge Center
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.accent.withOpacity(0.1),
                            border: Border.all(color: colors.accent, width: 2),
                            boxShadow: [BoxShadow(color: colors.accent.withOpacity(0.3), blurRadius: 20)],
                          ),
                          child: Center(
                            child: Text(
                              user.rankEmoji,
                              style: const TextStyle(fontSize: 50),
                            ),
                          ),
                        ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 3.seconds),
                        const SizedBox(height: 12),
                        Text(
                          user.rankTitle,
                          style: TextStyle(fontFamily: 'Orbitron', fontSize: 18, color: colors.accent, fontWeight: FontWeight.bold),
                        ),
                        if (user.prestigeLevel > 0)
                          Text(
                            'PRESTIGE LEVEL ${user.prestigeLevel}',
                            style: const TextStyle(fontFamily: 'Orbitron', fontSize: 10, color: Colors.amber, fontWeight: FontWeight.w900),
                          ).animate().fadeIn().scale(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(title: 'LIFETIME STATS', colors: colors),
                  const SizedBox(height: 16),
                  _StatGrid(user: user, colors: colors),
                  
                  const SizedBox(height: 32),
                  _SectionTitle(title: 'COLLECTION', colors: colors),
                  const SizedBox(height: 16),
                  _SkinsCarousel(user: user, colors: colors),
                  
                  const SizedBox(height: 40),
                  // Back Button or Menu shortcut
                  Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.buttonBorder.withOpacity(0.1),
                        foregroundColor: colors.text,
                        side: BorderSide(color: colors.buttonBorder),
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text('BACK TO MENU', style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.bold)),
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final AppThemeColors colors;
  const _SectionTitle({required this.title, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontFamily: 'Orbitron', fontSize: 12, color: colors.text.withOpacity(0.5), letterSpacing: 2, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(width: 40, height: 2, color: colors.accent),
      ],
    );
  }
}

class _StatGrid extends StatelessWidget {
  final UserProvider user;
  final AppThemeColors colors;
  const _StatGrid({required this.user, required this.colors});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _StatTile(label: 'BEST SCORE', value: '${user.bestScore}', colors: colors),
        _StatTile(label: 'BEST LENGTH', value: '${user.bestLength}', colors: colors),
        _StatTile(label: 'GAMES PLAYED', value: '${0}', colors: colors), // Placeholder for actual stat if needed
        _StatTile(label: 'TOTAL XP', value: '${user.xp}', colors: colors),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final AppThemeColors colors;
  const _StatTile({required this.label, required this.value, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.hudBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.buttonBorder.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 8, color: colors.text.withOpacity(0.6), fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, color: colors.text, fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
        ],
      ),
    );
  }
}

class _SkinsCarousel extends StatelessWidget {
  final UserProvider user;
  final AppThemeColors colors;
  const _SkinsCarousel({required this.user, required this.colors});

  @override
  Widget build(BuildContext context) {
    const skins = SnakeSkin.values;
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: skins.length,
        itemBuilder: (context, index) {
          final skin = skins[index];
          final isUnlocked = user.unlockedSkins.contains(skin);
          final isEquipped = user.equippedSkin == skin;
          
          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: isEquipped ? colors.accent.withOpacity(0.2) : colors.hudBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isEquipped ? colors.accent : (isUnlocked ? colors.buttonBorder.withOpacity(0.3) : Colors.transparent)),
            ),
            child: Stack(
              children: [
                Center(child: Text(skin == SnakeSkin.ghost ? '👻' : skin == SnakeSkin.skeleton ? '💀' : '🐍', style: TextStyle(fontSize: 30, color: Colors.white.withOpacity(isUnlocked ? 1.0 : 0.2)))),
                if (!isUnlocked)
                  const Center(child: Icon(Icons.lock, size: 20, color: Colors.white24)),
              ],
            ),
          );
        },
      ),
    );
  }
}
