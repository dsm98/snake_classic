import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/enums/power_up_type.dart';
import '../../core/enums/theme_type.dart';
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
      case ThemeType.retro:  return AppThemeColors.retro;
      case ThemeType.neon:   return AppThemeColors.neon;
      case ThemeType.nature: return AppThemeColors.nature;
      case ThemeType.arcade: return AppThemeColors.arcade;
      case ThemeType.cyber: return AppThemeColors.cyber;
      case ThemeType.volcano: return AppThemeColors.volcano;
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
              constraints: BoxConstraints(minHeight: LayoutUtil.spacing(context, 48)),
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

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: LayoutUtil.spacing(context, 16),
        vertical: LayoutUtil.spacing(context, 10),
      ),
      decoration: BoxDecoration(
        color: isRetro ? colors.background : colors.hudBg,
        boxShadow: isRetro
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
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
                    color: colors.text.withOpacity(0.4),
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
                              color: colors.buttonBorder.withOpacity(0.4),
                              blurRadius: 12,
                            ),
                          ],
                  ),
                ),
              ],
            ),
          ),

          // ── Center: event, time or combo ────────────────────────
          if (engine.comebackBonus && DateTime.now().millisecondsSinceEpoch < engine.comebackBonusEndMs)
            _comebackBonusBadge(context)
          else if (engine.activeEvent != BoardEvent.none)
            _eventDisplay(context)
          else if (engine.gameMode.name == 'timeAttack')
            _timeDisplay(context)
          else
            _comboDisplay(context),

          // ── Right controls ────────────────────────────────────
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Snake length badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.buttonBorder.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: colors.buttonBorder.withOpacity(0.25)),
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
                      color: colors.buttonBg.withOpacity(isRetro ? 1.0 : 0.7),
                      border: Border.all(
                          color: colors.buttonBorder.withOpacity(0.5),
                          width: scale),
                      borderRadius: BorderRadius.circular(12 * scale),
                      boxShadow: isRetro
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
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
      ),
    );
  }

  Widget _timeDisplay(BuildContext context) {
    final secs = engine.timeRemainingSeconds;
    final isUrgent = secs <= 10;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isUrgent
            ? Colors.red.withOpacity(0.15)
            : colors.buttonBorder.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUrgent
              ? Colors.red.withOpacity(0.5)
              : colors.buttonBorder.withOpacity(0.2),
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
                  ? Colors.red.withOpacity(0.8)
                  : colors.text.withOpacity(0.5),
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
          BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 10)
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
        color: isIce ? Colors.cyan.withOpacity(0.2) : Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isIce ? Colors.cyan.withOpacity(0.5) : Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(isIce ? '❄️' : '🌑', style: TextStyle(fontSize: LayoutUtil.fontSize(context, 12))),
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
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: LayoutUtil.spacing(context, 12),
        vertical: LayoutUtil.spacing(context, 5),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.accent.withOpacity(0.2),
            colors.buttonBorder.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.accent.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: colors.accent.withOpacity(0.2),
            blurRadius: 12,
          ),
        ],
      ),
      child: Text(
        'x${engine.combo} COMBO!',
        style: TextStyle(
          fontFamily: _fontFamily,
          fontSize: LayoutUtil.fontSize(context, 10),
          color: colors.accent,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _powerUpBar(BuildContext context) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: LayoutUtil.spacing(context, 16),
        vertical: 3,
      ),
      child: Row(
        children: engine.activePowerUps.where((ap) => ap.isActive(now)).map((ap) {
          final progress = ap.progress(now);
          return Padding(
            padding: EdgeInsets.only(right: LayoutUtil.spacing(context, 14)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: colors.powerUp.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: colors.powerUp.withOpacity(0.4)),
                  ),
                  child: Center(
                    child: Text(ap.type.icon,
                        style: TextStyle(
                            fontSize: LayoutUtil.fontSize(context, 12))),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: LayoutUtil.spacing(context, 44),
                  height: 5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: colors.hudBg.withOpacity(0.5),
                      valueColor: AlwaysStoppedAnimation<Color>(colors.powerUp),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
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
                backgroundColor: colors.background.withOpacity(0.4),
                color: colors.buttonBorder.withOpacity(0.6),
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
                  : colors.text.withOpacity(0.3),
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
                  color: engine.isFeverMode ? Colors.orange : colors.text.withOpacity(0.5),
                ),
              ),
              if (!engine.isFeverMode)
                Text(
                  '${engine.feverMeter}%',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 8,
                    color: colors.text.withOpacity(0.5),
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
                backgroundColor: colors.background.withOpacity(0.3),
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
}
