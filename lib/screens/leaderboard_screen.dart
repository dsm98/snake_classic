import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants/app_colors.dart';
import '../core/enums/game_mode.dart';
import '../core/enums/theme_type.dart';
import '../core/models/high_score.dart';
import '../providers/settings_provider.dart';
import '../services/leaderboard_service.dart';

class LeaderboardScreen extends StatefulWidget {
  final GameMode initialMode;

  const LeaderboardScreen({super.key, required this.initialMode});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late GameMode _selectedMode;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialMode;
    _tabController = TabController(
      length: GameMode.values.length,
      vsync: this,
      initialIndex: GameMode.values.indexOf(_selectedMode),
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedMode = GameMode.values[_tabController.index]);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  AppThemeColors _colors(ThemeType t) {
    switch (t) {
      case ThemeType.retro:  return AppThemeColors.retro;
      case ThemeType.neon:   return AppThemeColors.neon;
      case ThemeType.nature: return AppThemeColors.nature;
      case ThemeType.arcade: return AppThemeColors.arcade;
      case ThemeType.cyber: return AppThemeColors.cyber;
      case ThemeType.volcano: return AppThemeColors.volcano;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colors = _colors(settings.theme);
    final font = settings.theme == ThemeType.retro ? 'PressStart2P' : 'Orbitron';

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────
            _buildHeader(colors, font),

            // ── Mode tabs ─────────────────────────────────────────
            _buildTabs(colors, font),

            // ── Content ───────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: GameMode.values.map((mode) {
                  return FutureBuilder<List<HighScore>>(
                    future: LeaderboardService().getGlobalTopScores(mode),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: colors.accent,
                            strokeWidth: 2,
                          ),
                        );
                      }
                      final list = snapshot.data ?? [];
                      return _buildScoreList(list, colors, font);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppThemeColors colors, String font) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: colors.hudBg.withOpacity(0.7),
        border: Border(
          bottom: BorderSide(color: colors.buttonBorder.withOpacity(0.1)),
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
                const Text('🏆', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Text(
                  'LEADERBOARD',
                  style: TextStyle(
                    fontFamily: font,
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
    );
  }

  Widget _buildTabs(AppThemeColors colors, String font) {
    return Container(
      color: colors.hudBg.withOpacity(0.4),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.center,
        indicatorColor: colors.buttonBorder,
        indicatorWeight: 2.5,
        dividerColor: Colors.transparent,
        labelColor: colors.text,
        unselectedLabelColor: colors.text.withOpacity(0.35),
        labelStyle: const TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 10,
        ),
        tabs: GameMode.values.map((mode) {
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(mode.icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(mode.displayName),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScoreList(
      List<HighScore> scores, AppThemeColors colors, String font) {
    if (scores.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🐍', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text(
              'No scores yet!',
              style: TextStyle(
                fontFamily: font,
                fontSize: 14,
                color: colors.text.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Be the first to play!',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 10,
                color: colors.text.withOpacity(0.3),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: scores.length,
      itemBuilder: (context, i) {
        return _ScoreRow(rank: i + 1, score: scores[i], colors: colors)
            .animate(delay: Duration(milliseconds: i * 50))
            .fadeIn()
            .slideX(begin: 0.05, end: 0);
      },
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final int rank;
  final HighScore score;
  final AppThemeColors colors;

  const _ScoreRow(
      {required this.rank, required this.score, required this.colors});

  Color get _rankColor {
    if (rank == 1) return const Color(0xFFFFD700); // Gold
    if (rank == 2) return const Color(0xFFC0C0C0); // Silver
    if (rank == 3) return const Color(0xFFCD7F32); // Bronze
    return colors.text.withOpacity(0.4);
  }

  String get _rankLabel {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    if (rank == 3) return '🥉';
    return '#$rank';
  }

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: isTop3
            ? LinearGradient(
                colors: [
                  _rankColor.withOpacity(0.12),
                  _rankColor.withOpacity(0.03),
                ],
              )
            : null,
        color: isTop3 ? null : colors.hudBg.withOpacity(0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isTop3
              ? _rankColor.withOpacity(0.4)
              : colors.buttonBorder.withOpacity(0.12),
          width: isTop3 ? 1.5 : 1,
        ),
        boxShadow: isTop3
            ? [
                BoxShadow(
                  color: _rankColor.withOpacity(0.12),
                  blurRadius: 16,
                )
              ]
            : [],
      ),
      child: Row(
        children: [
          // Rank badge
          SizedBox(
            width: 44,
            child: isTop3
                ? Text(
                    _rankLabel,
                    style: const TextStyle(fontSize: 24),
                    textAlign: TextAlign.center,
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.buttonBorder.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _rankLabel,
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 11,
                        color: colors.text.withOpacity(0.5),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),

          const SizedBox(width: 12),

          // Player avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.buttonBorder.withOpacity(0.1),
              border: Border.all(
                color: isTop3 ? _rankColor.withOpacity(0.5) : colors.buttonBorder.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: score.photoUrl != null
                ? Image.network(score.photoUrl!, fit: BoxFit.cover)
                : const Center(child: Text('👤', style: TextStyle(fontSize: 18))),
          ),

          const SizedBox(width: 12),

          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  score.playerName ?? 'Anonymous',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 12,
                    color: isTop3 ? colors.text : colors.text.withOpacity(0.8),
                    fontWeight:
                        isTop3 ? FontWeight.bold : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${score.achievedAt.day}/${score.achievedAt.month}/${score.achievedAt.year}',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 9,
                    color: colors.text.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),

          // Score + length
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: isTop3
                      ? [_rankColor, _rankColor.withOpacity(0.7)]
                      : [colors.accent, colors.accent],
                ).createShader(bounds),
                child: Text(
                  '${score.score}',
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '🐍 ${score.snakeLength}',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 10,
                  color: colors.text.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
