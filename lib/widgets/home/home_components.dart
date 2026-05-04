import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/layout_util.dart';
import '../../providers/settings_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../screens/profile_screen.dart';
import '../../services/ghost_racing_service.dart';

class TopBar extends StatelessWidget {
  final AppThemeColors colors;
  final String font;
  final SettingsProvider settings;
  final Function(BuildContext, Widget) goTo;
  final VoidCallback onShowReborn;

  const TopBar({
    super.key,
    required this.colors,
    required this.font,
    required this.settings,
    required this.goTo,
    required this.onShowReborn,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final auth = context.watch<AuthService>();
    final streak = userProvider.dailyStreak;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.buttonBg.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.buttonBorder.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: colors.buttonBorder.withValues(alpha: 0.08),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () =>
                goTo(context, ProfileScreen(themeType: settings.theme)),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    colors.buttonBorder.withValues(alpha: 0.6),
                    colors.buttonBorder.withValues(alpha: 0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                    color: colors.buttonBorder.withValues(alpha: 0.5)),
              ),
              child: Center(
                child: Text(
                  userProvider.rankEmoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        auth.isSignedIn
                            ? auth.playerName.toUpperCase()
                            : 'GUEST PLAYER',
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 10,
                          color: colors.text,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (userProvider.isMaxRank)
                      GestureDetector(
                        onTap: onShowReborn,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.5)),
                          ),
                          child: const Text('REBORN',
                              style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: AppTypography.modernFont)),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .shimmer(duration: 2.seconds)
                            .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.1, 1.1)),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      userProvider.rankTitle,
                      style: TextStyle(
                        fontFamily: AppTypography.modernFont,
                        fontSize: 9,
                        color: colors.accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: userProvider.rankProgress,
                          minHeight: 4,
                          backgroundColor:
                              colors.background.withValues(alpha: 0.5),
                          color: colors.buttonBorder,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      '💰 ${userProvider.coins}',
                      style: const TextStyle(
                        fontFamily: AppTypography.modernFont,
                        fontSize: 9,
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.cyanAccent.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '💎 ${userProvider.snakeSouls}',
                      style: const TextStyle(
                        fontFamily: AppTypography.modernFont,
                        fontSize: 9,
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (streak > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 12)),
                    Text(
                      ' $streak',
                      style: const TextStyle(
                        fontFamily: AppTypography.modernFont,
                        fontSize: 10,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class HeroTitle extends StatelessWidget {
  final AppThemeColors colors;
  final String font;
  final AnimationController pulseController;

  const HeroTitle({
    super.key,
    required this.colors,
    required this.font,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: pulseController,
          builder: (context, _) {
            return Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors.buttonBorder
                        .withValues(alpha: 0.15 + pulseController.value * 0.1),
                    colors.buttonBorder.withValues(alpha: 0.0),
                  ],
                ),
                border: Border.all(
                  color: colors.buttonBorder
                      .withValues(alpha: 0.2 + pulseController.value * 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.buttonBorder
                        .withValues(alpha: 0.1 + pulseController.value * 0.15),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Text('🐍', style: TextStyle(fontSize: 44)),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [colors.text, colors.accent],
          ).createShader(bounds),
          child: Text(
            'SNAKE',
            style: TextStyle(
              fontFamily: font,
              fontSize: LayoutUtil.fontSize(
                  context, font == AppTypography.retroFont ? 30 : 38),
              color: Colors.white,
              letterSpacing: 6,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'CLASSIC REBORN',
          style: TextStyle(
            fontFamily: AppTypography.modernFont,
            fontSize: LayoutUtil.fontSize(context, 11),
            color: colors.accent.withValues(alpha: 0.8),
            letterSpacing: 5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class PlayButton extends StatefulWidget {
  final AppThemeColors colors;
  final String font;
  final AnimationController pulseController;
  final VoidCallback onTap;

  const PlayButton({
    super.key,
    required this.colors,
    required this.font,
    required this.pulseController,
    required this.onTap,
  });

  @override
  State<PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<PlayButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Play game now',
      hint: 'Starts the selected game mode',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedBuilder(
          animation: widget.pulseController,
          builder: (context, _) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutQuad,
              width: double.infinity,
              height: 68,
              transform: _pressed
                  ? (Matrix4.identity()..scale(0.97, 0.97))
                  : Matrix4.identity(),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: [
                    widget.colors.buttonBorder,
                    Color.lerp(
                        widget.colors.buttonBorder, widget.colors.accent, 0.5)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: _pressed
                    ? []
                    : [
                        BoxShadow(
                          color: widget.colors.buttonBorder.withValues(
                              alpha: 0.35 + widget.pulseController.value * 0.2),
                          blurRadius: 24 + widget.pulseController.value * 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: AnimatedBuilder(
                      animation: widget.pulseController,
                      builder: (context, _) {
                        return CustomPaint(
                          size: const Size(double.infinity, 68),
                          painter:
                              _ShimmerPainter(widget.pulseController.value),
                        );
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('▶',
                          style: TextStyle(fontSize: 20, color: Colors.white)),
                      const SizedBox(width: 16),
                      Text(
                        'PLAY NOW',
                        style: TextStyle(
                          fontFamily: widget.font,
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          shadows: [
                            Shadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  final double progress;
  _ShimmerPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final x = -100 + progress * (size.width + 200);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment(x / size.width, 0),
      end: Alignment((x + 80) / size.width, 0),
      colors: [
        Colors.white.withValues(alpha: 0),
        Colors.white.withValues(alpha: 0.12),
        Colors.white.withValues(alpha: 0),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter old) => old.progress != progress;
}

class GhostChallengeCard extends StatelessWidget {
  final AppThemeColors colors;
  final String font;
  final VoidCallback onImport;

  const GhostChallengeCard({
    super.key,
    required this.colors,
    required this.font,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GhostRacingService>(builder: (context, ghostService, _) {
      final rival = ghostService.activeRivalGhost;

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.hudBg.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (rival != null ? Colors.cyanAccent : colors.buttonBorder)
                .withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Text('👻', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rival != null
                            ? 'ACTIVE RIVAL: ${rival.rivalName.toUpperCase()}'
                            : 'GHOST CHALLENGE',
                        style: TextStyle(
                          fontFamily: AppTypography.modernFont,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color:
                              rival != null ? Colors.cyanAccent : colors.text,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rival != null
                            ? 'Target Score: ${rival.rivalScore} pts'
                            : 'Import a friend\'s ghost to race them!',
                        style: TextStyle(
                          color: colors.text.withValues(alpha: 0.6),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                if (rival != null)
                  IconButton(
                    onPressed: () => ghostService.setRivalGhost(null),
                    icon: const Icon(Icons.close,
                        size: 18, color: Colors.white24),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: onImport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: rival != null
                      ? Colors.cyan[700]
                      : colors.buttonBorder.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  rival != null ? 'CHALLENGE RIVAL' : 'IMPORT GHOST CODE',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
