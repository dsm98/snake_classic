import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/direction.dart';
import '../../core/models/position.dart';
import '../../services/multiplayer_engine.dart';

class MultiplayerBoard extends StatelessWidget {
  final MultiplayerEngine engine;
  
  const MultiplayerBoard({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: engine,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final cellW = constraints.maxWidth / AppConstants.gridColumns;
          final cellH = constraints.maxHeight / AppConstants.gridRows;
          final cellSize = min(cellW, cellH);

          return CustomPaint(
            size: Size(
              cellSize * AppConstants.gridColumns,
              cellSize * AppConstants.gridRows,
            ),
            painter: _MultiplayerPainter(engine: engine, cellSize: cellSize),
          );
        },
      ),
    );
  }
}

class _MultiplayerPainter extends CustomPainter {
  final MultiplayerEngine engine;
  final double cellSize;

  _MultiplayerPainter({required this.engine, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (cellSize == 0) return;

    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF1E2638), // dark grey
    );

    // Food
    if (engine.food != null) {
      canvas.drawRect(_cellRect(engine.food!.position), Paint()..color = Colors.redAccent);
    }

    _drawSnake(canvas, engine.snake1, engine.currentDirection1, const Color(0xFF00E5FF), const Color(0xFF00B0D5)); // P1 Cyan
    _drawSnake(canvas, engine.snake2, engine.currentDirection2, const Color(0xFFFF3366), const Color(0xFFD51A44)); // P2 Pink
    
    _drawCollision(canvas);
  }

  void _drawCollision(Canvas canvas) {
    if (engine.collisionPoint == null) return;
    
    final rect = _cellRect(engine.collisionPoint!);
    final center = rect.center;
    
    // Draw starburst/explosion
    final paint = Paint()..color = Colors.yellow;
    final path = Path();
    const spikes = 12;
    const outerRadius = 30.0;
    const innerRadius = 15.0;
    
    for (int i = 0; i < spikes * 2; i++) {
      final angle = (pi / spikes) * i;
      final r = i.isEven ? outerRadius : innerRadius;
      final x = center.dx + cos(angle) * r;
      final y = center.dy + sin(angle) * r;
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    path.close();
    
    canvas.drawPath(path, paint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawPath(path, Paint()..color = Colors.orange..style = PaintingStyle.stroke..strokeWidth = 2);

    // BAM! Text
    final tp = TextPainter(
      text: TextSpan(
        text: 'BAM!',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          fontFamily: 'Orbitron',
          shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  void _drawSnake(Canvas canvas, List<Position> snake, Direction currentDir, Color headColor, Color bodyColor) {
    if (snake.isEmpty) return;
    
    final paint = Paint();
    
    // Body
    for (int i = snake.length - 1; i >= 1; i--) {
      paint.color = bodyColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(_cellRect(snake[i]).deflate(1.5), const Radius.circular(4)),
        paint,
      );
    }

    // Head
    paint.color = headColor;
    RRect headRect = RRect.fromRectAndRadius(_cellRect(snake.first).deflate(1.0), const Radius.circular(4));
    canvas.drawRRect(headRect, paint);

    _drawEyes(canvas, snake.first, currentDir);
  }

  void _drawEyes(Canvas canvas, Position head, Direction dir) {
    final rect = _cellRect(head);
    final eyeRadius = cellSize * 0.15;
    final eyePaint = Paint()..color = Colors.white;

    double lx1, ly1, lx2, ly2;
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    const offset = 0.25;

    switch (dir) {
      case Direction.right:
        lx1 = cx + cellSize * 0.2; ly1 = cy - cellSize * offset;
        lx2 = cx + cellSize * 0.2; ly2 = cy + cellSize * offset;
        break;
      case Direction.left:
        lx1 = cx - cellSize * 0.2; ly1 = cy - cellSize * offset;
        lx2 = cx - cellSize * 0.2; ly2 = cy + cellSize * offset;
        break;
      case Direction.up:
        lx1 = cx - cellSize * offset; ly1 = cy - cellSize * 0.2;
        lx2 = cx + cellSize * offset; ly2 = cy - cellSize * 0.2;
        break;
      case Direction.down:
        lx1 = cx - cellSize * offset; ly1 = cy + cellSize * 0.2;
        lx2 = cx + cellSize * offset; ly2 = cy + cellSize * 0.2;
        break;
    }

    canvas.drawCircle(Offset(lx1, ly1), eyeRadius, eyePaint);
    canvas.drawCircle(Offset(lx2, ly2), eyeRadius, eyePaint);
    canvas.drawCircle(Offset(lx1, ly1), eyeRadius/2, Paint()..color=Colors.black);
    canvas.drawCircle(Offset(lx2, ly2), eyeRadius/2, Paint()..color=Colors.black);
  }

  Rect _cellRect(Position pos) {
    return Rect.fromLTWH(pos.x * cellSize, pos.y * cellSize, cellSize, cellSize);
  }

  @override
  bool shouldRepaint(covariant _MultiplayerPainter old) => true;
}
