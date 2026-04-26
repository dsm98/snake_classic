import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/enums/direction.dart';
import '../../core/enums/theme_type.dart';

class SwipeController extends StatefulWidget {
  final Widget child;
  final void Function(Direction) onDirectionChanged;

  const SwipeController({
    super.key,
    required this.child,
    required this.onDirectionChanged,
  });

  @override
  State<SwipeController> createState() => _SwipeControllerState();
}

class _SwipeControllerState extends State<SwipeController> {
  Offset? _startPos;

  /// Minimum drag distance before a swipe is registered
  static const double _minDistance = 20.0;

  /// Once a swipe fires, the new anchor shifts to the current position
  /// allowing continuous flicking without lifting the finger.
  Direction? _lastDirection;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) {
        _startPos = details.localPosition;
        _lastDirection = null;
      },
      onPanUpdate: (details) {
        if (_startPos == null) return;
        final delta = details.localPosition - _startPos!;
        if (delta.distance < _minDistance) return;

        Direction dir;
        if (delta.dx.abs() > delta.dy.abs()) {
          dir = delta.dx > 0 ? Direction.right : Direction.left;
        } else {
          dir = delta.dy > 0 ? Direction.down : Direction.up;
        }

        // Only fire if direction changed — avoids repeated calls on same drag
        if (dir != _lastDirection) {
          _lastDirection = dir;
          widget.onDirectionChanged(dir);
          HapticFeedback.selectionClick();
        }
        // Re-anchor so the user can chain multiple swipes in one gesture
        _startPos = details.localPosition;
      },
      onPanEnd: (_) {
        _startPos = null;
        _lastDirection = null;
      },
      onPanCancel: () {
        _startPos = null;
        _lastDirection = null;
      },
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium Glass Joystick
// ─────────────────────────────────────────────────────────────────────────────

class JoystickWidget extends StatefulWidget {
  final void Function(Direction) onDirectionChanged;
  final AppThemeColors colors;
  final ThemeType themeType;

  const JoystickWidget({
    super.key,
    required this.onDirectionChanged,
    required this.colors,
    required this.themeType,
  });

  @override
  State<JoystickWidget> createState() => _JoystickWidgetState();
}

class _JoystickWidgetState extends State<JoystickWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  Direction? _activeDirection;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRetro = widget.themeType == ThemeType.retro;
    final size = isRetro ? 200.0 : 210.0;

    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring with pulsing glow
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRetro
                      ? widget.colors.buttonBg.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.15),
                  border: Border.all(
                    color: widget.colors.buttonBorder
                        .withValues(alpha: 0.08 + _pulseCtrl.value * 0.08),
                    width: 1.5,
                  ),
                  boxShadow: isRetro
                      ? []
                      : [
                          BoxShadow(
                            color: widget.colors.buttonBorder
                                .withValues(alpha: 0.04 + _pulseCtrl.value * 0.06),
                            blurRadius: 20 + _pulseCtrl.value * 10,
                          ),
                        ],
                ),
              ),

              // Four direction buttons
              _buildDirectionButton(Direction.up, size),
              _buildDirectionButton(Direction.down, size),
              _buildDirectionButton(Direction.left, size),
              _buildDirectionButton(Direction.right, size),

              // Center hub
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isRetro
                      ? null
                      : RadialGradient(
                          colors: [
                            widget.colors.buttonBg.withValues(alpha: 0.6),
                            widget.colors.buttonBg.withValues(alpha: 0.2),
                          ],
                        ),
                  color:
                      isRetro ? widget.colors.buttonBg.withValues(alpha: 0.4) : null,
                  border: Border.all(
                    color: widget.colors.buttonBorder.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.colors.buttonBorder.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDirectionButton(Direction dir, double containerSize) {
    final isRetro = widget.themeType == ThemeType.retro;
    final isActive = _activeDirection == dir;
    final btnSize = isRetro ? 64.0 : 60.0;
    final offset = containerSize / 2 - btnSize / 2;

    // Position the button
    double top = 0, left = 0;
    IconData icon;

    switch (dir) {
      case Direction.up:
        top = offset - (containerSize / 2 - btnSize / 2 - 2);
        left = containerSize / 2 - btnSize / 2;
        icon = Icons.keyboard_arrow_up_rounded;
        break;
      case Direction.down:
        top = offset + (containerSize / 2 - btnSize / 2 - 2);
        left = containerSize / 2 - btnSize / 2;
        icon = Icons.keyboard_arrow_down_rounded;
        break;
      case Direction.left:
        top = containerSize / 2 - btnSize / 2;
        left = offset - (containerSize / 2 - btnSize / 2 - 2);
        icon = Icons.keyboard_arrow_left_rounded;
        break;
      case Direction.right:
        top = containerSize / 2 - btnSize / 2;
        left = offset + (containerSize / 2 - btnSize / 2 - 2);
        icon = Icons.keyboard_arrow_right_rounded;
        break;
    }

    return Positioned(
      top: top,
      left: left,
      child: _DpadButton(
        icon: icon,
        size: btnSize,
        isRetro: isRetro,
        isActive: isActive,
        colors: widget.colors,
        onTapDown: () {
          setState(() => _activeDirection = dir);
          HapticFeedback.lightImpact();
          widget.onDirectionChanged(dir);
        },
        onTapUp: () => setState(() => _activeDirection = null),
      ),
    );
  }
}

class _DpadButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool isRetro;
  final bool isActive;
  final AppThemeColors colors;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;

  const _DpadButton({
    required this.icon,
    required this.size,
    required this.isRetro,
    required this.isActive,
    required this.colors,
    required this.onTapDown,
    required this.onTapUp,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapUp,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: isRetro ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: isRetro ? BorderRadius.circular(12) : null,
          gradient: isRetro
              ? null
              : isActive
                  ? RadialGradient(
                      colors: [
                        colors.buttonBorder.withValues(alpha: 0.5),
                        colors.buttonBorder.withValues(alpha: 0.15),
                      ],
                    )
                  : RadialGradient(
                      colors: [
                        colors.buttonBg.withValues(alpha: 0.7),
                        colors.buttonBg.withValues(alpha: 0.3),
                      ],
                    ),
          color: isRetro
              ? (isActive
                  ? colors.buttonBorder.withValues(alpha: 0.4)
                  : colors.buttonBg.withValues(alpha: 0.8))
              : null,
          border: Border.all(
            color: isActive
                ? colors.buttonBorder.withValues(alpha: 0.9)
                : colors.buttonBorder.withValues(alpha: isRetro ? 0.8 : 0.3),
            width: isRetro ? 2 : 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: colors.buttonBorder.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : isRetro
                  ? [
                      BoxShadow(
                        color: colors.buttonBorder.withValues(alpha: 0.4),
                        offset: const Offset(0, 4),
                        blurRadius: 0,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
        ),
        transform: isActive
            ? (Matrix4.identity()..scale(0.93, 0.93))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        child: Icon(
          icon,
          color: isActive
              ? colors.text
              : colors.text.withValues(alpha: isRetro ? 0.9 : 0.7),
          size: 30,
        ),
      ),
    );
  }
}
