import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/enums/theme_type.dart';
import '../services/storage_service.dart';

class SafariJournalScreen extends StatefulWidget {
  final ThemeType themeType;
  const SafariJournalScreen({super.key, required this.themeType});

  @override
  State<SafariJournalScreen> createState() => _SafariJournalScreenState();
}

class _SafariJournalScreenState extends State<SafariJournalScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  final _storage = StorageService();

  static const _creatures = [
    _CreatureInfo('mouse', '🐭', 'Field Mouse', 'Forest / Desert / Ruins',
        Color(0xFF9E9E9E), 'Timid — flees from the snake\'s scent.'),
    _CreatureInfo('rabbit', '🐇', 'Wild Rabbit', 'Forest / Ruins',
        Color(0xFFEEEEEE), 'Dashes away when cornered — watch the charges.'),
    _CreatureInfo(
        'lizard',
        '🦎',
        'Desert Lizard',
        'Desert / Swamp / Cave / Ruins',
        Color(0xFF66BB6A),
        'Camouflages when still — blink and you\'ll miss it.'),
    _CreatureInfo('butterfly', '🦋', 'Jungle Butterfly', 'Cave / Ruins',
        Color(0xFFFF9800), 'Flies in sine waves — times out quickly!'),
    _CreatureInfo('croc', '🐊', 'Swamp Crocodile', 'Swamp', Color(0xFF2E7D32),
        'Boss — hits stun you. Aim for the head.'),
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
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        foregroundColor: colors.text,
        elevation: 0,
        title: Text(
          '📖  Safari Journal',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // ── Daily Mission ────────────────────────────────────────
            _missionCard(context, mission, colors),
            const SizedBox(height: 20),

            // ── Creature Codex ───────────────────────────────────────
            _sectionHeader(context, '🦁 Creature Codex', colors),
            const SizedBox(height: 8),
            ..._creatures.map(
                (c) => _creatureCard(context, c, counts[c.key] ?? 0, colors)),

            const SizedBox(height: 20),

            // ── Biome Explorer ───────────────────────────────────────
            _sectionHeader(context, '🗺️ Biome Explorer', colors),
            const SizedBox(height: 8),
            _biomeGrid(context, visited, colors),

            const SizedBox(height: 20),

            // ── Safari Stats ─────────────────────────────────────────
            _sectionHeader(context, '📊 Lifetime Stats', colors),
            const SizedBox(height: 8),
            _statsCard(context, counts, colors),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(
      BuildContext context, String title, AppThemeColors colors) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Orbitron',
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: colors.text.withOpacity(0.85),
        letterSpacing: 1.2,
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: done
                  ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
                  : [
                      info.color.withOpacity(0.18 + _pulse.value * 0.06),
                      colors.background,
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: done
                  ? Colors.greenAccent.withOpacity(0.8)
                  : info.color.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    done ? '✅' : '🎯',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'DAILY SAFARI MISSION',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 10,
                      color: done
                          ? Colors.greenAccent
                          : colors.text.withOpacity(0.7),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${info.emoji}  Catch $target ${info.name}${target > 1 ? 's' : ''}',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 14,
                  color: colors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (progress / target).clamp(0.0, 1.0),
                  minHeight: 7,
                  backgroundColor: Colors.black.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    done ? Colors.greenAccent : info.color,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                done ? 'Completed!' : '$progress / $target caught',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 9,
                  color:
                      done ? Colors.greenAccent : colors.text.withOpacity(0.6),
                ),
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: caught
            ? info.color.withOpacity(0.10)
            : colors.background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: caught
              ? info.color.withOpacity(0.4)
              : colors.text.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Text(
            caught ? info.emoji : '❓',
            style: TextStyle(
                fontSize: 28, color: caught ? null : Colors.transparent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caught ? info.name : '???',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: caught ? colors.text : colors.text.withOpacity(0.35),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  caught ? info.biomes : 'Not yet discovered',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 8,
                    color: caught ? info.color : colors.text.withOpacity(0.25),
                  ),
                ),
                if (caught) ...[
                  const SizedBox(height: 3),
                  Text(
                    info.hint,
                    style: TextStyle(
                      fontSize: 10,
                      color: colors.text.withOpacity(0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: caught ? info.color.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: caught
                  ? Border.all(color: info.color.withOpacity(0.4))
                  : null,
            ),
            child: Text(
              caught ? '×$count' : '—',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: caught ? info.color : colors.text.withOpacity(0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _biomeGrid(
      BuildContext context, Set<String> visited, AppThemeColors colors) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.5,
      children: _biomes.map((b) {
        final seen = visited.contains(b.key);
        return Container(
          decoration: BoxDecoration(
            color: seen ? b.color.withOpacity(0.15) : colors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: seen
                  ? b.color.withOpacity(0.5)
                  : colors.text.withOpacity(0.1),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                seen ? b.emoji : '🌫️',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 4),
              Text(
                seen ? b.name : '???',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 8,
                  color: seen ? b.color : colors.text.withOpacity(0.3),
                  fontWeight: FontWeight.bold,
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
    final rarest = counts.entries.isEmpty
        ? null
        : counts.entries.reduce((a, b) => a.value < b.value ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.text.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.text.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _statRow('Total prey caught', '$total', colors),
          const SizedBox(height: 8),
          _statRow(
              'Species discovered',
              '${_creatures.where((c) => (counts[c.key] ?? 0) > 0).length} / ${_creatures.length}',
              colors),
          const SizedBox(height: 8),
          _statRow(
            'Rarest catch',
            rarest == null
                ? '—'
                : '${_creatures.firstWhere((c) => c.key == rarest.key, orElse: () => _creatures.first).emoji} ×${rarest.value}',
            colors,
          ),
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
            color: colors.text.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: colors.text,
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
  const _CreatureInfo(
      this.key, this.emoji, this.name, this.biomes, this.color, this.hint);
}

class _BiomeInfo {
  final String key;
  final String emoji;
  final String name;
  final Color color;
  const _BiomeInfo(this.key, this.emoji, this.name, this.color);
}
