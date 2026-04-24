import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants/app_colors.dart';
import '../core/enums/game_mode.dart';
import '../core/enums/theme_type.dart';
import '../core/models/high_score.dart';
import '../providers/settings_provider.dart';
import '../services/auth_service.dart';
import '../services/leaderboard_service.dart';
import '../widgets/ui/dynamic_background.dart';

class LeaderboardScreen extends StatefulWidget {
  final GameMode initialMode;

  const LeaderboardScreen({super.key, required this.initialMode});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  static const List<GameMode> _rankedModes = [
    GameMode.classic,
    GameMode.portal,
    GameMode.maze,
    GameMode.timeAttack,
    GameMode.blitz,
    GameMode.endless,
  ];

  late GameMode _selectedMode;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _selectedMode = _rankedModes.contains(widget.initialMode)
        ? widget.initialMode
        : GameMode.classic;
    _tabController = TabController(
      length: _rankedModes.length,
      vsync: this,
      initialIndex: _rankedModes.indexOf(_selectedMode),
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedMode = _rankedModes[_tabController.index]);
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
    final settings = context.watch<SettingsProvider>();
    final colors = _colors(settings.theme);
    final font =
        settings.theme == ThemeType.retro ? 'PressStart2P' : 'Orbitron';

    return Scaffold(
      backgroundColor: colors.background,
      body: DynamicBackground(
        themeType: settings.theme,
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────
              _buildHeader(colors, font),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: _LeaderboardHero(
                  colors: colors,
                  mode: _selectedMode,
                  font: font,
                ),
              ),

              // ── Mode tabs ─────────────────────────────────────────
              _buildTabs(colors, font),

              // ── Content ───────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _rankedModes.map((mode) {
                    return FutureBuilder<_LeaderboardData>(
                      future: _fetchLeaderboardData(mode),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: colors.accent,
                              strokeWidth: 2,
                            ),
                          );
                        }
                        final data =
                            snapshot.data ?? _LeaderboardData([], null);
                        return _buildScoreList(data, colors, font);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: colors.hudBg.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.buttonBorder.withOpacity(0.22)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.center,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: colors.buttonBorder.withOpacity(0.22),
          border: Border.all(color: colors.buttonBorder.withOpacity(0.35)),
        ),
        dividerColor: Colors.transparent,
        labelColor: colors.text,
        unselectedLabelColor: colors.text.withOpacity(0.45),
        labelStyle: const TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 10,
        ),
        tabs: _rankedModes.map((mode) {
          return Tab(
            height: 40,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(mode.icon, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 6),
                Text(mode.displayName),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<_LeaderboardData> _fetchLeaderboardData(GameMode mode) async {
    final auth = AuthService();
    final scores = await LeaderboardService().getGlobalTopScores(mode);
    HighScore? personal;
    if (auth.isSignedIn) {
      final best = await LeaderboardService().getPersonalBest(mode);
      if (best > 0) {
        final rank = scores.indexWhere((s) => s.score <= best);
        personal = HighScore(
          score: best,
          snakeLength: 0,
          mode: mode,
          achievedAt: DateTime.now(),
          playerName: auth.playerName,
          globalRank: rank >= 0 ? rank + 1 : scores.length + 1,
        );
      }
    }
    return _LeaderboardData(scores, personal);
  }

  Widget _buildScoreList(
      _LeaderboardData data, AppThemeColors colors, String font) {
    final scores = data.scores;
    final personal = data.personal;

    if (scores.isEmpty && personal == null) {
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
      itemCount: scores.length + (personal != null ? 1 : 0),
      itemBuilder: (context, i) {
        final reducedMotion = context.read<SettingsProvider>().reducedMotion;
        if (personal != null && i == 0) {
          final row = _PersonalBestRow(score: personal, colors: colors);
          return reducedMotion
              ? row
              : row.animate().fadeIn().slideY(begin: -0.05, end: 0);
        }
        final scoreIndex = personal != null ? i - 1 : i;
        final row = _ScoreRow(
            rank: scoreIndex + 1, score: scores[scoreIndex], colors: colors);
        return reducedMotion
            ? row
            : row
                .animate(delay: Duration(milliseconds: scoreIndex * 50))
                .fadeIn()
                .slideX(begin: 0.05, end: 0);
      },
    );
  }
}

class _LeaderboardHero extends StatelessWidget {
  final AppThemeColors colors;
  final GameMode mode;
  final String font;

  const _LeaderboardHero({
    required this.colors,
    required this.mode,
    required this.font,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.buttonBorder.withOpacity(0.22),
            colors.accent.withOpacity(0.1),
            colors.hudBg.withOpacity(0.58),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.buttonBorder.withOpacity(0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.hudBg.withOpacity(0.75),
              border: Border.all(color: colors.buttonBorder.withOpacity(0.35)),
            ),
            child: Center(
              child: Text(mode.icon, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${mode.displayName.toUpperCase()} RANKINGS',
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: colors.accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Compete globally and chase your personal best.',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 9,
                    color: colors.text.withOpacity(0.7),
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

class _LeaderboardData {
  final List<HighScore> scores;
  final HighScore? personal;
  const _LeaderboardData(this.scores, this.personal);
}

class _PersonalBestRow extends StatelessWidget {
  final HighScore score;
  final AppThemeColors colors;
  const _PersonalBestRow({required this.score, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.buttonBorder.withOpacity(0.18),
            colors.accent.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: colors.buttonBorder.withOpacity(0.55), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colors.buttonBorder.withOpacity(0.14),
            blurRadius: 18,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: colors.buttonBorder.withOpacity(0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'YOU',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: colors.buttonBorder,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  score.playerName ?? 'Unknown',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  score.globalRank != null
                      ? 'Global rank ~#${score.globalRank}'
                      : 'Personal best',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 8,
                    color: colors.text.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${score.score}',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.buttonBorder,
            ),
          ),
        ],
      ),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
                color: isTop3
                    ? _rankColor.withOpacity(0.5)
                    : colors.buttonBorder.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: score.photoUrl != null
                ? Image.network(score.photoUrl!, fit: BoxFit.cover)
                : const Center(
                    child: Text('👤', style: TextStyle(fontSize: 18))),
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
                    fontWeight: isTop3 ? FontWeight.bold : FontWeight.w500,
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
