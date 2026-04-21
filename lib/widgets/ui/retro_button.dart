import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../services/audio_service.dart';

class RetroButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final AppThemeColors colors;
  final String? prefixIcon;
  final bool large;
  final String fontFamily;

  const RetroButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.colors,
    this.prefixIcon,
    this.large = false,
    this.fontFamily = 'PressStart2P',
  });

  @override
  State<RetroButton> createState() => _RetroButtonState();
}

class _RetroButtonState extends State<RetroButton> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.colors.buttonBorder;
    final fontSize = widget.large ? 14.0 : 10.0;
    final vPad = widget.large ? 18.0 : 13.0;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        HapticFeedback.selectionClick();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.lightImpact();
        AudioService().play(SoundEffect.click);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          final isRetro = widget.fontFamily == 'PressStart2P';
          
          final bgColor = isRetro 
              ? ( _pressed ? borderColor.withValues(alpha: 0.3) : widget.colors.buttonBg )
              : widget.colors.buttonBg.withValues(alpha: _pressed ? 0.4 : 0.2);
          
          final borderOpacity = isRetro ? 1.0 : (_pressed ? 1.0 : 0.6);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOutQuad,
            transform: _pressed
                ? (Matrix4.identity()..scale(0.97, 0.97)..translate(0.0, 4.0))
                : Matrix4.identity(),
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              color: bgColor,
              gradient: isRetro ? null : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.colors.buttonBg.withValues(alpha: 0.1),
                  widget.colors.buttonBg.withValues(alpha: 0.3),
                ],
              ),
              border: Border.all(
                color: borderColor.withValues(alpha: borderOpacity), 
                width: isRetro ? 2 : 1.2,
              ),
              borderRadius: BorderRadius.circular(isRetro ? 6 : 14),
              boxShadow: _pressed
                  ? []
                  : [
                      // Tiered shadows for depth
                      if (isRetro)
                        BoxShadow(
                          color: borderColor.withValues(alpha: 0.4),
                          blurRadius: 0,
                          offset: const Offset(0, 5),
                        )
                      else ...[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: borderColor.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isRetro ? 4 : 12),
              child: Stack(
                children: [
                  // Internal Gloss (State of the art touch)
                  if (!isRetro)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0),
                              Colors.white.withValues(alpha: 0.3),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  
                  // Moving shimmer
                  if (!isRetro && !_pressed)
                    Positioned(
                      left: -150 + (_shimmerController.value * 500),
                      top: -50,
                      bottom: -50,
                      width: 60,
                      child: Transform.rotate(
                        angle: 0.6,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0),
                                Colors.white.withValues(alpha: 0.08),
                                Colors.white.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  // Content
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: vPad),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.prefixIcon != null) ...[
                          Text(widget.prefixIcon!,
                              style: TextStyle(
                                fontSize: fontSize + 6,
                                shadows: [
                                  if (!isRetro) Shadow(color: widget.colors.text.withValues(alpha: 0.6), blurRadius: 12),
                                ],
                              )),
                          const SizedBox(width: 12),
                        ],
                        Text(
                          widget.label.toUpperCase(),
                          style: TextStyle(
                            fontFamily: widget.fontFamily,
                            fontSize: fontSize,
                            color: widget.colors.text,
                            letterSpacing: isRetro ? 1.5 : 2.5,
                            fontWeight: isRetro ? FontWeight.normal : FontWeight.w800,
                            shadows: [
                              if (!isRetro) Shadow(color: widget.colors.text.withValues(alpha: 0.5), blurRadius: 15),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class NeonCard extends StatelessWidget {
  final Widget child;
  final AppThemeColors colors;
  final EdgeInsets? padding;

  const NeonCard({
    super.key,
    required this.child,
    required this.colors,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.buttonBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.buttonBorder.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.buttonBorder.withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}
