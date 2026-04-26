import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/enums/theme_type.dart';
import '../core/constants/app_colors.dart';
import '../providers/user_provider.dart';
import '../core/enums/snake_skin.dart';
import '../services/storage_service.dart';
import '../widgets/ui/dynamic_background.dart';
import 'grimoire_screen.dart';

class ProfileScreen extends StatelessWidget {
  final ThemeType themeType;
  const ProfileScreen({super.key, required this.themeType});

  String _skinEmoji(SnakeSkin skin) {
    switch (skin) {
      case SnakeSkin.classic:
        return '🐍';
      case SnakeSkin.skeleton:
        return '💀';
      case SnakeSkin.robot:
        return '🤖';
      case SnakeSkin.rainbow:
        return '🌈';
      case SnakeSkin.ghost:
        return '👻';
      case SnakeSkin.ninja:
        return '🥷';
      case SnakeSkin.dragon:
        return '🐉';
      case SnakeSkin.vampire:
        return '🧛';
      case SnakeSkin.golden:
        return '✨';
      case SnakeSkin.jadeSerpent:
        return '🦎';
      case SnakeSkin.monarchWyrm:
        return '🦋';
      case SnakeSkin.crocBane:
        return '🐊';
    }
  }

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
    final user = context.watch<UserProvider>();
    final gamesPlayed = StorageService().gamesPlayed;

    return Scaffold(
      backgroundColor: colors.background,
      body: DynamicBackground(
        themeType: themeType,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              backgroundColor: colors.hudBg.withValues(alpha: 0.86),
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    color: colors.text, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                'PROFILE',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 12,
                  color: colors.text,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colors.buttonBorder.withValues(alpha: 0.3),
                            colors.hudBg.withValues(alpha: 0.9),
                            colors.background,
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 56),
                          Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.accent.withValues(alpha: 0.1),
                              border:
                                  Border.all(color: colors.accent, width: 2),
                              boxShadow: [
                                BoxShadow(
                                    color: colors.accent.withValues(alpha: 0.26),
                                    blurRadius: 24)
                              ],
                            ),
                            child: Center(
                              child: Text(
                                user.rankEmoji,
                                style: const TextStyle(fontSize: 52),
                              ),
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat())
                              .shimmer(duration: 3.seconds),
                          const SizedBox(height: 10),
                          Text(
                            user.rankTitle,
                            style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 17,
                                color: colors.accent,
                                fontWeight: FontWeight.bold),
                          ),
                          if (user.prestigeLevel > 0)
                            Text(
                              'PRESTIGE LEVEL ${user.prestigeLevel}',
                              style: const TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 10,
                                  color: Colors.amber,
                                  fontWeight: FontWeight.w900),
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
                    _StatGrid(
                        user: user, colors: colors, gamesPlayed: gamesPlayed),
                    const SizedBox(height: 32),
                    _SectionTitle(title: '🗺️ SAFARI RECORD', colors: colors),
                    const SizedBox(height: 16),
                    _SafariStatsCard(colors: colors, themeType: themeType),
                    const SizedBox(height: 32),
                    _SectionTitle(title: 'COLLECTION', colors: colors),
                    const SizedBox(height: 16),
                    _SkinsCarousel(
                      user: user,
                      colors: colors,
                      skinEmoji: _skinEmoji,
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              colors.buttonBorder.withValues(alpha: 0.12),
                          foregroundColor: colors.text,
                          side: BorderSide(
                              color: colors.buttonBorder.withValues(alpha: 0.55)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text('BACK TO MENU',
                            style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontWeight: FontWeight.bold)),
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final AppThemeColors colors;
  const _SectionTitle({required this.title, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 12,
                color: colors.text.withValues(alpha: 0.5),
                letterSpacing: 2,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(width: 40, height: 2, color: colors.accent),
      ],
    );
  }
}

class _StatGrid extends StatelessWidget {
  final UserProvider user;
  final AppThemeColors colors;
  final int gamesPlayed;
  const _StatGrid({
    required this.user,
    required this.colors,
    required this.gamesPlayed,
  });

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
        _StatTile(
            label: 'BEST SCORE', value: '${user.bestScore}', colors: colors),
        _StatTile(
            label: 'BEST LENGTH', value: '${user.bestLength}', colors: colors),
        _StatTile(label: 'GAMES PLAYED', value: '$gamesPlayed', colors: colors),
        _StatTile(label: 'TOTAL XP', value: '${user.xp}', colors: colors),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final AppThemeColors colors;
  const _StatTile(
      {required this.label, required this.value, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.hudBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.buttonBorder.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 8,
                  color: colors.text.withValues(alpha: 0.6),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron')),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  color: colors.text,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron')),
        ],
      ),
    );
  }
}

class _SafariStatsCard extends StatelessWidget {
  final AppThemeColors colors;
  final ThemeType themeType;
  const _SafariStatsCard({required this.colors, required this.themeType});

  @override
  Widget build(BuildContext context) {
    final s = StorageService();
    final visited = s.safariVisitedBiomes.length;
    final counts = s.safariCounts;
    final totalPrey = s.safariTotalPrey;
    final bestStreak = s.safariBestStreak;
    final rooms = s.safariRoomsVisited;
    final crocs = s.safariCrocKills;

    // Find rarest catch
    String rarestEmoji = '—';
    int rarestCount = 0;
    final rarityOrder = ['croc', 'butterfly', 'lizard', 'rabbit', 'mouse'];
    for (final type in rarityOrder) {
      final c = counts[type] ?? 0;
      if (c > 0) {
        rarestEmoji = _typeEmoji(type);
        rarestCount = c;
        break;
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GrimoireScreen(themeType: themeType),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.05),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'VIEW GRIMOIRE 📜',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent.withValues(alpha: 0.8),
                    letterSpacing: 1.2,
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.greenAccent),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _safarStat('🗺️ Rooms', '$rooms / 88'),
                _safarStat('🔥 Best Streak', '×$bestStreak'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _safarStat('🐾 Prey Caught', '$totalPrey'),
                _safarStat('🌍 Biomes', '$visited / 5'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _safarStat('🐊 Crocs', '$crocs'),
                _safarStat('🏆 Rarest',
                    rarestCount > 0 ? '$rarestEmoji ×$rarestCount' : '—'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _typeEmoji(String type) {
    switch (type) {
      case 'croc':
        return '🐊';
      case 'butterfly':
        return '🦋';
      case 'lizard':
        return '🦎';
      case 'rabbit':
        return '🐇';
      default:
        return '🐭';
    }
  }

  Widget _safarStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                TextStyle(color: colors.text.withValues(alpha: 0.55), fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: colors.text, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _SkinsCarousel extends StatelessWidget {
  final UserProvider user;
  final AppThemeColors colors;
  final String Function(SnakeSkin) skinEmoji;
  const _SkinsCarousel({
    required this.user,
    required this.colors,
    required this.skinEmoji,
  });

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
              color: isEquipped ? colors.accent.withValues(alpha: 0.2) : colors.hudBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isEquipped
                      ? colors.accent
                      : (isUnlocked
                          ? colors.buttonBorder.withValues(alpha: 0.3)
                          : Colors.transparent)),
            ),
            child: Stack(
              children: [
                Center(
                    child: Text(skinEmoji(skin),
                        style: TextStyle(
                            fontSize: 30,
                            color: Colors.white
                                .withValues(alpha: isUnlocked ? 1.0 : 0.2)))),
                if (!isUnlocked)
                  const Center(
                      child: Icon(Icons.lock, size: 20, color: Colors.white24)),
              ],
            ),
          );
        },
      ),
    );
  }
}
