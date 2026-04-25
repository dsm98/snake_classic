import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/daily_event.dart';
import '../../core/models/seasonal_content.dart';
import '../../core/models/social_challenge.dart';
import '../../core/enums/game_mode.dart';
import '../../core/theme/app_typography.dart';

class DailyEventCard extends StatefulWidget {
  final DailyEvent event;
  final AppThemeColors colors;
  final String font;
  final VoidCallback onTap;

  const DailyEventCard({
    super.key,
    required this.event,
    required this.colors,
    required this.font,
    required this.onTap,
  });

  @override
  State<DailyEventCard> createState() => _DailyEventCardState();
}

class _DailyEventCardState extends State<DailyEventCard> {
  late Timer _timer;
  String _timeRemaining = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final diff = tomorrow.difference(now);

    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    final s = diff.inSeconds.remainder(60);

    if (mounted) {
      setState(() {
        _timeRemaining = '${h}h ${m}m ${s}s';
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.colors.accent.withOpacity(0.25),
              widget.colors.buttonBorder.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: widget.colors.accent.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: widget.colors.accent.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: widget.colors.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.event.icon,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'DAILY CHALLENGE',
                        style: TextStyle(
                          fontFamily: widget.font,
                          fontSize: 10,
                          color: widget.colors.accent,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '🔥 $_timeRemaining',
                          style: const TextStyle(
                            fontFamily: AppTypography.modernFont,
                            fontSize: 8,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.event.title,
                    style: TextStyle(
                      fontFamily: widget.font,
                      fontSize: 16,
                      color: widget.colors.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.event.description,
                    style: TextStyle(
                      fontFamily: AppTypography.modernFont,
                      fontSize: 10,
                      color: widget.colors.text.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NextGoalCard extends StatelessWidget {
  final AppThemeColors colors;
  final String hint;

  const NextGoalCard({super.key, required this.colors, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.hudBg.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.buttonBorder.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.buttonBorder.withValues(alpha: 0.18),
            ),
            child: const Center(
              child: Text('🎯', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEXT GOAL',
                  style: TextStyle(
                    fontFamily: AppTypography.modernFont,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: colors.accent,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hint,
                  style: TextStyle(
                    fontFamily: AppTypography.modernFont,
                    fontSize: 10,
                    height: 1.4,
                    color: colors.text.withValues(alpha: 0.75),
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

class SeasonalSpotlightCard extends StatelessWidget {
  final SeasonalContent season;
  final AppThemeColors colors;
  final String font;
  final VoidCallback onTap;

  const SeasonalSpotlightCard({
    super.key,
    required this.season,
    required this.colors,
    required this.font,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.buttonBorder.withValues(alpha: 0.25),
              colors.accent.withValues(alpha: 0.14),
              colors.hudBg.withValues(alpha: 0.72),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.buttonBorder.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: colors.buttonBorder.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.hudBg.withValues(alpha: 0.75),
                border: Border.all(
                    color: colors.buttonBorder.withValues(alpha: 0.35)),
              ),
              child: Center(
                child: Text(season.icon, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SEASONAL SPOTLIGHT',
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 9,
                      letterSpacing: 1.3,
                      color: colors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    season.title,
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 14,
                      color: colors.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    season.subtitle,
                    style: TextStyle(
                      fontFamily: AppTypography.modernFont,
                      fontSize: 10,
                      color: colors.text.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colors.hudBg.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: colors.buttonBorder.withValues(alpha: 0.28)),
              ),
              child: Text(
                season.suggestedMode.displayName.toUpperCase(),
                style: const TextStyle(
                  fontFamily: AppTypography.modernFont,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SocialChallengeCard extends StatelessWidget {
  final SocialChallenge challenge;
  final int bestScore;
  final AppThemeColors colors;
  final String font;
  final Future<void> Function() onClaim;

  const SocialChallengeCard({
    super.key,
    required this.challenge,
    required this.bestScore,
    required this.colors,
    required this.font,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (bestScore / challenge.targetScore).clamp(0.0, 1.0);
    final completed = bestScore >= challenge.targetScore;
    final claimable = completed && !challenge.claimed;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.hudBg.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: claimable
              ? colors.accent.withValues(alpha: 0.55)
              : colors.buttonBorder.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'SOCIAL CHALLENGE',
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 10,
                  letterSpacing: 1.4,
                  color: colors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'vs ${challenge.rivalName}',
                style: TextStyle(
                  fontFamily: AppTypography.modernFont,
                  fontSize: 9,
                  color: colors.text.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Score ${challenge.targetScore} in a single run',
            style: TextStyle(
              fontFamily: font,
              fontSize: 13,
              color: colors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: colors.background.withValues(alpha: 0.5),
              color: completed ? colors.accent : colors.buttonBorder,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$bestScore / ${challenge.targetScore}',
                style: TextStyle(
                  fontFamily: AppTypography.modernFont,
                  fontSize: 10,
                  color: colors.text.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              Text(
                '${challenge.rewardCoins}💰 + ${challenge.rewardXp}XP',
                style: TextStyle(
                  fontFamily: AppTypography.modernFont,
                  fontSize: 10,
                  color: colors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: claimable ? onClaim : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    claimable ? colors.buttonBorder : colors.buttonBg,
                foregroundColor: Colors.white,
                disabledBackgroundColor: colors.buttonBg.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                challenge.claimed
                    ? 'Reward Claimed'
                    : completed
                        ? 'Claim Reward'
                        : 'Beat Challenge First',
                style: const TextStyle(
                  fontFamily: AppTypography.modernFont,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
