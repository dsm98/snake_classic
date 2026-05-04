import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class CRTFilter extends StatelessWidget {
  final Widget child;

  const CRTFilter({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        IgnorePointer(
          child: CustomPaint(
            painter: _CRTPainter(),
          ),
        ),
      ],
    );
  }
}

class _CRTPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Scanlines
    final scanlinePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double y = 0; y < size.height; y += 3.0) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scanlinePaint);
    }

    // Vignette
    final gradient = ui.Gradient.radial(
      rect.center,
      size.width * 0.8,
      [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
      [0.6, 1.0],
    );

    canvas.drawRect(
      rect,
      Paint()..shader = gradient,
    );

    // RGB shift (Chromatic Aberration) simulation is harder with just CustomPaint 
    // unless we render the child to a texture, so we'll skip it for now and stick to scanlines/vignette.
  }

  @override
  bool shouldRepaint(covariant _CRTPainter oldDelegate) => false;
}
