import 'dart:io';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/enums/theme_type.dart';
import '../services/storage_service.dart';

class GrimoireScreen extends StatefulWidget {
  final ThemeType themeType;
  const GrimoireScreen({super.key, required this.themeType});

  @override
  State<GrimoireScreen> createState() => _GrimoireScreenState();
}

class _GrimoireScreenState extends State<GrimoireScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  final _storage = StorageService();

  static const _creatures = [
    _CreatureInfo(
      'mouse',
      '🐭',
      'Ashen Mouse',
      'Forest / Desert / Ruins',
      Color(0xFF9E9E9E),
      'Timid — flees from the snake\'s scent.',
      'They say these mice feed on the ashes of the old world.',
      [
        'Fragment I: Scavengers of the Great Fire, they survive where even the spirits starve.',
        'Fragment II: Their eyes reflect the flickering embers of a civilization long dead.',
        'Fragment III: Legend says they lead the worthy to hidden caches of the Ancients.'
      ],
    ),
    _CreatureInfo(
      'rabbit',
      '🐇',
      'Ghost-Hearth Rabbit',
      'Forest / Ruins',
      Color(0xFFEEEEEE),
      'Dashes away when cornered — watch the charges.',
      'It moves with unnatural speed, almost as if fleeing a shadow we cannot see.',
      [
        'Fragment I: Not truly of this realm, their feet never quite touch the soil.',
        'Fragment II: To catch one is to hold a piece of the shifting winds.',
        'Fragment III: They are the heralds of the Storm; where they gather, lightning soon follows.'
      ],
    ),
    _CreatureInfo(
      'lizard',
      '🦎',
      'Void-Scale Lizard',
      'Desert / Swamp / Cave / Ruins',
      Color(0xFF66BB6A),
      'Camouflages when still — blink and you\'ll miss it.',
      'Its scales are cold, colder than the desert night.',
      [
        'Fragment I: Their skin absorbs light, leaving only a ripple in the air.',
        'Fragment II: They drink the moisture from the dreams of sleeping giants.',
        'Fragment III: A single scale can freeze a boiling cauldron.'
      ],
    ),
    _CreatureInfo(
      'butterfly',
      '🦋',
      'Soul-Wing Butterfly',
      'Cave / Ruins',
      Color(0xFFFF9800),
      'Flies in sine waves — times out quickly!',
      'Lost souls often take the form of these glowing wings.',
      [
        'Fragment I: Born from the sighs of the forgotten, they seek only the warmth of a fire.',
        'Fragment II: Their dust causes visions of a city made of glass.',
        'Fragment III: They guide the dead through the labyrinth of the Caves.'
      ],
    ),
    _CreatureInfo(
      'croc',
      '🐊',
      'Mire-King Crocodile',
      'Swamp',
      Color(0xFF2E7D32),
      'Boss — hits stun you. Aim for the head.',
      'The beast of the mire. It guards the sunken ruins.',
      [
        'Fragment I: Ancient beyond reckoning, it remembers the birth of the Swamp.',
        'Fragment II: Its teeth are carved from the black stone of the Abyss.',
        'Fragment III: To defeat it is to earn the title of Sovereign of the Mud.'
      ],
    ),
  ];

  static const _biomes = [
    _BiomeInfo('forest', '🌲', 'Forest', Color(0xFF00C853)),
    _BiomeInfo('desert', '🏜️', 'Desert', Color(0xFFFF8C00)),
    _BiomeInfo('swamp', '🌿', 'Swamp', Color(0xFF00897B)),
    _BiomeInfo('cave', '🕳️', 'Cave', Color(0xFF7B1FA2)),
    _BiomeInfo('ruins', '🏚️', 'Ruins', Color(0xFF757575)),
  ];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  AppThemeColors get colors {
    switch (widget.themeType) {
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
    final counts = _storage.safariCounts;
    final visited = _storage.safariVisitedBiomes;
    final mission = _storage.safariMission;

    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0C),
      body: Stack(
        children: [
          // ── Parchment Texture ──
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: Image.file(
                File('C:/Users/Diluka/.gemini/antigravity/brain/4d2b09ec-164a-4f26-b72a-69ed1ff32b08/parchment_texture_1777104109361.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  backgroundColor: Colors.transparent,
                  foregroundColor: colors.text,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: const Text(
                    '📜  THE GRIMOIRE',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Daily Mission ────────────────────────────────────────
                        _missionCard(context, mission, colors),
                        const SizedBox(height: 24),

                        // ── Creature Codex ───────────────────────────────────────
                        _sectionHeader(context, '🦇 BESTIARY', colors),
                        const SizedBox(height: 12),
                        ..._creatures.map((c) => _creatureCard(
                            context, c, counts[c.key] ?? 0, colors)),

                        const SizedBox(height: 24),

                        // ── Biome Explorer ───────────────────────────────────────
                        _sectionHeader(context, '🔮 KNOWN REALMS', colors),
                        const SizedBox(height: 12),
                        _biomeGrid(context, visited, colors),

                        const SizedBox(height: 24),

                        // ── Safari Stats ─────────────────────────────────────────
                        _sectionHeader(context, '💀 HUNTER\'S LEGACY', colors),
                        const SizedBox(height: 12),
                        _statsCard(context, counts, colors),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(
      BuildContext context, String title, AppThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: colors.accent, width: 3)),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: colors.text.withOpacity(0.9),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _missionCard(BuildContext context, Map<String, dynamic> mission,
      AppThemeColors colors) {
    final type = mission['type'] as String;
    final target = mission['target'] as int;
    final progress = mission['progress'] as int;
    final done = progress >= target;
    final info = _creatures.firstWhere((c) => c.key == type,
        orElse: () => _creatures.first);

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: done
                  ? Colors.greenAccent.withOpacity(0.6)
                  : info.color.withOpacity(0.3 + _pulse.value * 0.2),
              width: 1.5,
            ),
            boxShadow: [
              if (!done)
                BoxShadow(
                  color: info.color.withOpacity(0.1 * _pulse.value),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    done ? '🔥' : '🕯️',
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'DARK RITUAL',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 11,
                      color: done
                          ? Colors.greenAccent
                          : colors.text.withOpacity(0.8),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Capture $target ${info.name}${target > 1 ? 's' : ''} to appease the Spirits.',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 14,
                  color: colors.text,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (progress / target).clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: Colors.white.withOpacity(0.05),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        done ? Colors.greenAccent : info.color,
                      ),
                    ),
                  ),
                  if (done)
                    const Positioned.fill(
                      child: Center(
                        child: Text(
                          'RITUAL COMPLETE',
                          style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              letterSpacing: 1),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$progress / $target SLAIN',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 9,
                      color: done
                          ? Colors.greenAccent
                          : colors.text.withOpacity(0.5),
                    ),
                  ),
                  if (done)
                    const Text(
                      'SOUULS REAPED',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 9,
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _creatureCard(BuildContext context, _CreatureInfo info, int count,
      AppThemeColors colors) {
    final caught = count > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: caught
              ? info.color.withOpacity(0.3)
              : colors.text.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: caught ? info.color.withOpacity(0.1) : Colors.black26,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        caught ? info.color.withOpacity(0.5) : Colors.white10,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  caught ? info.emoji : '?',
                  style: TextStyle(
                    fontSize: 28,
                    color: caught ? null : Colors.white24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      caught ? info.name.toUpperCase() : 'UNKNOWN ENTITY',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color:
                            caught ? colors.text : colors.text.withOpacity(0.2),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      caught ? info.biomes : 'Location undiscovered',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 9,
                        color: caught
                            ? info.color.withOpacity(0.8)
                            : colors.text.withOpacity(0.15),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    caught ? '$count' : '0',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: caught ? colors.text : colors.text.withOpacity(0.1),
                    ),
                  ),
                  Text(
                    'CAPTURED',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 7,
                      color: colors.text.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (caught) ...[
            const SizedBox(height: 16),
            Text(
              info.hint,
              style: TextStyle(
                fontSize: 11,
                color: colors.text.withOpacity(0.5),
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            _buildLoreSection(info, count, colors),
          ],
        ],
      ),
    );
  }

  Widget _buildLoreSection(_CreatureInfo info, int count, AppThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < info.fragments.length; i++) ...[
          if (i == 0 && count >= 1) _loreTile(info.fragments[i], info.color, colors),
          if (i == 1 && count >= 5) _loreTile(info.fragments[i], info.color, colors),
          if (i == 2 && count >= 10) _loreTile(info.fragments[i], info.color, colors),
        ],
        if (count < 10)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              count < 1 ? '• Capture to reveal Fragment I' :
              count < 5 ? '• Capture 5 to reveal Fragment II' :
              '• Capture 10 to reveal Fragment III',
              style: TextStyle(
                fontSize: 9,
                color: info.color.withOpacity(0.4),
                fontStyle: FontStyle.italic,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
      ],
    );
  }

  Widget _loreTile(String text, Color accent, AppThemeColors colors) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: accent, width: 2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: colors.text.withOpacity(0.85),
          fontFamily: 'Orbitron',
          height: 1.5,
        ),
      ),
    );
  }

  Widget _biomeGrid(
      BuildContext context, Set<String> visited, AppThemeColors colors) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.2,
      children: _biomes.map((b) {
        final seen = visited.contains(b.key);
        return Container(
          decoration: BoxDecoration(
            color: seen ? b.color.withOpacity(0.08) : Colors.black12,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: seen
                  ? b.color.withOpacity(0.4)
                  : colors.text.withOpacity(0.05),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                seen ? b.emoji : '💀',
                style: TextStyle(
                  fontSize: 22,
                  color: seen ? null : Colors.white10,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                seen ? b.name.toUpperCase() : 'LOCKED',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 8,
                  color: seen ? b.color : colors.text.withOpacity(0.15),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _statsCard(
      BuildContext context, Map<String, int> counts, AppThemeColors colors) {
    final total = counts.values.fold(0, (a, b) => a + b);
    final species = _creatures.where((c) => (counts[c.key] ?? 0) > 0).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.text.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          _statRow('LIFETIME REAPINGS', '$total', colors),
          const SizedBox(height: 12),
          _statRow('BEASTS CATALOGUED', '$species / ${_creatures.length}', colors),
          const SizedBox(height: 12),
          _statRow('GRIMOIRE COMPLETION', '${((species / _creatures.length) * 100).toInt()}%', colors),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, AppThemeColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 9,
            color: colors.text.withOpacity(0.5),
            letterSpacing: 1.5,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: colors.accent,
          ),
        ),
      ],
    );
  }
}

class _CreatureInfo {
  final String key;
  final String emoji;
  final String name;
  final String biomes;
  final Color color;
  final String hint;
  final String lore;
  final List<String> fragments;
  const _CreatureInfo(this.key, this.emoji, this.name, this.biomes, this.color,
      this.hint, this.lore, this.fragments);
}

class _BiomeInfo {
  final String key;
  final String emoji;
  final String name;
  final Color color;
  const _BiomeInfo(this.key, this.emoji, this.name, this.color);
}
