import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/position.dart';

class FloatingScore {
  final String text;
  final Position gridPosition;
  final Color color;
  final Key key;

  FloatingScore({
    required this.text,
    required this.gridPosition,
    required this.color,
  }) : key = UniqueKey();
}

class FloatingScoresOverlay extends StatelessWidget {
  final List<FloatingScore> scores;
  final double cellSize;

  const FloatingScoresOverlay({
    super.key,
    required this.scores,
    required this.cellSize,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: scores.map((score) {
        return Positioned(
          left: score.gridPosition.x * cellSize,
          top: score.gridPosition.y * cellSize,
          child: Text(
            score.text,
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: score.color,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.8),
                  blurRadius: 4,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
          )
              .animate(key: score.key)
              .fadeIn(duration: 200.ms)
              .moveY(begin: 0, end: -30, duration: 800.ms, curve: Curves.easeOut)
              .fadeOut(delay: 500.ms, duration: 300.ms),
        );
      }).toList(),
    );
  }
}
