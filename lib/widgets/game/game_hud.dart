import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/game_mode.dart';
import '../../core/enums/power_up_type.dart';
import '../../core/enums/theme_type.dart';
import '../../core/models/food_model.dart';
import '../../core/utils/layout_util.dart';
import '../../services/game_engine.dart';
import '../../services/storage_service.dart';

class GameHud extends StatelessWidget {
  final GameEngine engine;
  final ThemeType themeType;
  final VoidCallback onPause;

  const GameHud({
    super.key,
    required this.engine,
    required this.themeType,
    required this.onPause,
  });

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

  String get _fontFamily =>
      themeType == ThemeType.retro ? 'PressStart2P' : 'Orbitron';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: engine,
      builder: (context, _) {
        return Column(
          children: [
            _topBar(context),
            // Container with minHeight prevents layout jumps but allows expansion
            Container(
              constraints:
                  BoxConstraints(minHeight: LayoutUtil.spacing(context, 48)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (engine.feverMeter > 0 || engine.isFeverMode)
                    _feverBar(context),
                  if (engine.activePowerUps.isNotEmpty)
                    _powerUpBar(context)
                  else if (themeType != ThemeType.retro)
                    _xpBar(context)
                  else
                    const SizedBox.shrink(),
                  if (engine.activePowerUps.isNotEmpty &&
                      themeType != ThemeType.retro)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: _xpBar(context, slim: true),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _topBar(BuildContext context) {
    final scale = LayoutUtil.getScale(context);
    final isRetro = themeType == ThemeType.retro;

    return isRetro
        ? Container(
            padding: EdgeInsets.symmetric(
              horizontal: LayoutUtil.spacing(context, 16),
              vertical: LayoutUtil.spacing(context, 10),
            ),
            decoration: BoxDecoration(
              color: colors.background,
            ),
            child: _topBarRow(context, scale, isRetro),
          )
        : ClipRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: LayoutUtil.spacing(context, 16),
                  vertical: LayoutUtil.spacing(context, 10),
                ),
                decoration: BoxDecoration(
                  color: colors.hudBg.withValues(alpha: 0.75),
                  border: Border(
                    bottom: BorderSide(
                        color: colors.buttonBorder.withValues(alpha: 0.15), width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _topBarRow(context, scale, isRetro),
              ),
            ),
          );
  }

  Widget _topBarRow(BuildContext context, double scale, bool isRetro) {
    return Row(
      children: [
        // ── Score (left) ──────────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SCORE',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: LayoutUtil.fontSize(context, 7),
                  color: colors.text.withValues(alpha: 0.4),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                '${engine.score}',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: LayoutUtil.fontSize(context, 20),
                  color: colors.text,
                  fontWeight: FontWeight.bold,
                  shadows: isRetro
                      ? []
                      : [
                          Shadow(
                            color: colors.buttonBorder.withValues(alpha: 0.4),
                            blurRadius: 12,
                          ),
                        ],
                ),
              ),
            ],
          ),
        ),

        // ── Center: event, time or combo ────────────────────────
        if (engine.comebackBonus &&
            DateTime.now().millisecondsSinceEpoch < engine.comebackBonusEndMs)
          _comebackBonusBadge(context)
        else if (engine.activeEvent != BoardEvent.none)
          _eventDisplay(context)
        else if (engine.gameMode.name == 'timeAttack' ||
            engine.gameMode.name == 'blitz')
          _timeDisplay(context)
        else if (engine.gameMode == GameMode.explore)
          _huntStreakDisplay(context)
        else
          _comboDisplay(context),

        // ── Right controls ────────────────────────────────────
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Snake length badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.buttonBorder.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: colors.buttonBorder.withValues(alpha: 0.25)),
                ),
                child: Text(
                  '🐍 ${engine.snake.length}',
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: LayoutUtil.fontSize(context, 10),
                    color: colors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: LayoutUtil.spacing(context, 10)),

              // Pause button
              GestureDetector(
                onTap: onPause,
                child: Container(
                  width: 38 * scale,
                  height: 38 * scale,
                  decoration: BoxDecoration(
                    color: colors.buttonBg.withValues(alpha: isRetro ? 1.0 : 0.7),
                    border: Border.all(
                        color: colors.buttonBorder.withValues(alpha: 0.5),
                        width: scale),
                    borderRadius: BorderRadius.circular(12 * scale),
                    boxShadow: isRetro
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                            ),
                          ],
                  ),
                  child: Icon(
                    Icons.pause_rounded,
                    color: colors.text,
                    size: LayoutUtil.fontSize(context, 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _timeDisplay(BuildContext context) {
    final secs = engine.timeRemainingSeconds;
    final isUrgent = secs <= 10;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isUrgent
            ? Colors.red.withValues(alpha: 0.15)
            : colors.buttonBorder.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUrgent
              ? Colors.red.withValues(alpha: 0.5)
              : colors.buttonBorder.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'TIME',
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: LayoutUtil.fontSize(context, 7),
              color: isUrgent
                  ? Colors.red.withValues(alpha: 0.8)
                  : colors.text.withValues(alpha: 0.5),
              letterSpacing: 1,
            ),
          ),
          Text(
            '$secs',
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: LayoutUtil.fontSize(context, 22),
              color: isUrgent ? Colors.red : colors.text,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _comebackBonusBadge(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: LayoutUtil.spacing(context, 10),
        vertical: LayoutUtil.spacing(context, 4),
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9100), Color(0xFFFF3D00)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.orange.withValues(alpha: 0.4), blurRadius: 10)
        ],
      ),
      child: Text(
        '🔥 COMEBACK 1.5×',
        style: TextStyle(
          fontFamily: _fontFamily,
          fontSize: LayoutUtil.fontSize(context, 9),
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _eventDisplay(BuildContext context) {
    final isIce = engine.activeEvent == BoardEvent.iceBoard;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: LayoutUtil.spacing(context, 12),
        vertical: LayoutUtil.spacing(context, 5),
      ),
      decoration: BoxDecoration(
        color: isIce
            ? Colors.cyan.withValues(alpha: 0.2)
            : Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isIce ? Colors.cyan.withValues(alpha: 0.5) : Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(isIce ? '❄️' : '🌑',
              style: TextStyle(fontSize: LayoutUtil.fontSize(context, 12))),
          SizedBox(width: LayoutUtil.spacing(context, 6)),
          Text(
            isIce ? 'ICE BOARD' : 'LIGHTS OUT',
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: LayoutUtil.fontSize(context, 9),
              color: isIce ? Colors.cyanAccent : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _comboDisplay(BuildContext context) {
    if (engine.combo <= 1) return const SizedBox.shrink();

    final now = DateTime.now().millisecondsSinceEpoch;
    final remainingMs =
        (engine.comboLastFoodMs + (AppConstants.comboWindow * 1000) - now)
            .clamp(0, AppConstants.comboWindow * 1000);
    final remainingRatio = remainingMs / (AppConstants.comboWindow * 1000);

    // Urgency color: green → orange → red as timer drains
    final Color urgencyColor = remainingRatio > 0.5
        ? colors.accent
        : remainingRatio > 0.25
            ? Colors.orange
            : Colors.redAccent;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: LayoutUtil.spacing(context, 12),
        vertical: LayoutUtil.spacing(context, 5),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            urgencyColor.withValues(alpha: 0.2),
            urgencyColor.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: urgencyColor.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: urgencyColor.withValues(alpha: remainingRatio < 0.25 ? 0.35 : 0.2),
            blurRadius: remainingRatio < 0.25 ? 16 : 12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'x${engine.combo} COMBO!',
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: LayoutUtil.fontSize(context, 10),
              color: urgencyColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: LayoutUtil.spacing(context, 58),
            height: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: remainingRatio,
                backgroundColor: colors.background.withValues(alpha: 0.4),
                color: urgencyColor.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _powerUpBar(BuildContext context) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final active =
        engine.activePowerUps.where((ap) => ap.isActive(now)).toList();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: LayoutUtil.spacing(context, 16),
        vertical: 3,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: active.map((ap) {
            final progress = ap.progress(now);
            final remainingMs =
                (ap.endsAtMs - now).clamp(0, ap.type.durationMs);
            final remainingSeconds = (remainingMs / 1000).ceil();

            return Padding(
              padding: EdgeInsets.only(right: LayoutUtil.spacing(context, 10)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: colors.powerUp.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: colors.powerUp.withValues(alpha: 0.4)),
                    ),
                    child: Center(
                      child: Text(
                        ap.type.icon,
                        style: TextStyle(
                            fontSize: LayoutUtil.fontSize(context, 12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: LayoutUtil.spacing(context, 56),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 5,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: colors.hudBg.withValues(alpha: 0.5),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(colors.powerUp),
                            ),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${remainingSeconds}s',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: LayoutUtil.fontSize(context, 7),
                            color: colors.text.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _xpBar(BuildContext context, {bool slim = false}) {
    final storage = StorageService();
    final currentRunXpEstimate = engine.score ~/ 5;
    final barHeight = slim ? 2.0 : 4.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: LayoutUtil.spacing(context, 16),
        vertical: slim ? 0 : 2,
      ),
      child: Row(
        children: [
          Text(
            storage.rankEmoji,
            style: TextStyle(
                fontSize: LayoutUtil.fontSize(context, slim ? 10 : 12)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: storage.rankProgress,
                minHeight: barHeight,
                backgroundColor: colors.background.withValues(alpha: 0.4),
                color: colors.buttonBorder.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+$currentRunXpEstimate XP',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: LayoutUtil.fontSize(context, slim ? 7 : 8),
              color: currentRunXpEstimate > 0
                  ? Colors.greenAccent
                  : colors.text.withValues(alpha: 0.3),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _feverBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: LayoutUtil.spacing(context, 16),
        vertical: 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                engine.isFeverMode ? '🔥 FEVER MODE ACTIVE!' : 'FEVER METER',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: engine.isFeverMode
                      ? Colors.orange
                      : colors.text.withValues(alpha: 0.5),
                ),
              ),
              if (!engine.isFeverMode)
                Text(
                  '${engine.feverMeter}%',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 8,
                    color: colors.text.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: engine.isFeverMode ? 1.0 : engine.feverMeter / 100,
                backgroundColor: colors.background.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  engine.isFeverMode ? Colors.orange : Colors.deepOrangeAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Explore: Hunt Streak ────────────────────────────────────────────────────

  Widget _huntStreakDisplay(BuildContext context) {
    final streak = engine.huntStreak;
    if (streak < 2) {
      // Show compass only
      return _foodCompass(context);
    }

    final label = streak >= 7
        ? '🦁 APEX PREDATOR'
        : streak >= 5
            ? '⚡ HUNTER'
            : '🔥 TRACKER';
    final color = streak >= 7
        ? Colors.redAccent
        : streak >= 5
            ? Colors.orange
            : Colors.greenAccent;
    final multi = streak >= 7
        ? '×8'
        : streak >= 5
            ? '×4'
            : '×2';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 12)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label  $multi',
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: LayoutUtil.fontSize(context, 8),
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '×$streak',
              style: TextStyle(
                fontFamily: _fontFamily,
                fontSize: LayoutUtil.fontSize(context, 8),
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _foodCompass(BuildContext context) {
    if (engine.preyList.isEmpty || engine.snake.isEmpty) {
      return const SizedBox.shrink();
    }
    final head = engine.snake.first;
    // Find nearest prey
    FoodModel nearest = engine.preyList.first;
    int minDist = _gridDist(head, nearest.position);
    for (final p in engine.preyList) {
      final d = _gridDist(head, p.position);
      if (d < minDist) {
        minDist = d;
        nearest = p;
      }
    }
    final dx = (nearest.position.x - head.x).toDouble();
    final dy = (nearest.position.y - head.y).toDouble();
    final angle = dy == 0 && dx == 0 ? 0.0 : _atan2(dy, dx);
    final icon = _preyIcon(nearest.type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.buttonBorder.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.buttonBorder.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon,
              style: TextStyle(fontSize: LayoutUtil.fontSize(context, 11))),
          const SizedBox(width: 4),
          Transform.rotate(
            angle: angle,
            child: Icon(Icons.navigation_rounded,
                color: colors.accent, size: LayoutUtil.fontSize(context, 14)),
          ),
          const SizedBox(width: 4),
          Text(
            '$minDist',
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: LayoutUtil.fontSize(context, 9),
              color: colors.text.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  static int _gridDist(dynamic a, dynamic b) =>
      (a.x - b.x).abs() + (a.y - b.y).abs();

  static double _atan2(double y, double x) {
    // Simple approximation of atan2 without dart:math import conflict
    if (x == 0) return y > 0 ? 1.5708 : -1.5708;
    final r = y / x;
    final a = 0.9817 * r - 0.1963 * r * r * r;
    return x < 0 ? (y >= 0 ? a + 3.1416 : a - 3.1416) : a;
  }

  static String _preyIcon(FoodType t) {
    switch (t) {
      case FoodType.mouse:
        return '🐭';
      case FoodType.rabbit:
        return '🐇';
      case FoodType.lizard:
        return '🦎';
      case FoodType.butterfly:
        return '🦋';
      case FoodType.croc:
        return '🐊';
      default:
        return '🍎';
    }
  }
}
