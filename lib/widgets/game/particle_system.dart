import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/models/position.dart';
import '../../core/enums/biome_type.dart';

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double life;
  final double initialLife;
  final Color color;
  final double size;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.color,
    required this.size,
  }) : initialLife = life;

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    life -= dt;
  }
}

class ParticleSystem extends StatefulWidget {
  final Widget child;
  final int gridWidth;
  final int gridHeight;

  const ParticleSystem({
    super.key,
    required this.child,
    required this.gridWidth,
    required this.gridHeight,
  });

  @override
  State<ParticleSystem> createState() => ParticleSystemState();
}

class ParticleSystemState extends State<ParticleSystem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final _random = Random();
  double _lastTime = 0;
  BiomeType? _activeWeather;

  void setWeather(BiomeType? biome) {
    if (_activeWeather != biome) {
      setState(() {
        _activeWeather = biome;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(days: 365),
    )..addListener(_tick);
    _controller.forward();
  }

  void _tick() {
    final now = _controller.value * 3600 * 24 * 365; // Seconds since start
    final dt = now - _lastTime;
    _lastTime = now;

    if (dt <= 0) return;

    // Emit weather
    if (_activeWeather == BiomeType.swamp) {
      for (int i = 0; i < 3; i++) {
        _particles.add(Particle(
          x: _random.nextDouble() * 1.2 - 0.1,
          y: -0.1,
          vx: 0.2,
          vy: 1.5 + _random.nextDouble(),
          life: 1.0,
          color: Colors.blueAccent.withValues(alpha: 0.5),
          size: _random.nextDouble() * 2 + 1,
        ));
      }
    } else if (_activeWeather == BiomeType.desert) {
      for (int i = 0; i < 4; i++) {
        _particles.add(Particle(
          x: -0.1,
          y: _random.nextDouble() * 1.2 - 0.1,
          vx: 1.5 + _random.nextDouble(),
          vy: 0.1,
          life: 1.5,
          color: Colors.orangeAccent.withValues(alpha: 0.4),
          size: _random.nextDouble() * 3 + 1,
        ));
      }
    }

    if (_particles.isEmpty && _activeWeather == null) return;

    setState(() {
      for (int i = _particles.length - 1; i >= 0; i--) {
        _particles[i].update(dt);
        if (_particles[i].life <= 0) {
          _particles.removeAt(i);
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant ParticleSystem oldWidget) {
    super.didUpdateWidget(oldWidget);
    _lastTime = _controller.value * 3600 * 24 * 365;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Fire a burst of particles from a specific grid coordinate
  void fireBurst(Position pos, Color color, {int count = 12}) {
    // We defer calculation to get actual screen size in paint, but we can store 
    // fractional coordinates for resolution independence.
    final fractionalX = (pos.x + 0.5) / widget.gridWidth;
    final fractionalY = (pos.y + 0.5) / widget.gridHeight;

    for (int i = 0; i < count; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      // fractional velocity
      final speed = _random.nextDouble() * 0.5 + 0.2; 
      _particles.add(Particle(
        x: fractionalX,
        y: fractionalY,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        life: _random.nextDouble() * 0.4 + 0.2, // 0.2-0.6 seconds
        color: color,
        size: _random.nextDouble() * 4 + 2, // 2-6 pixels
      ));
    }
    
    // Ensure controller is running with valid delta
    _lastTime = _controller.value * 3600 * 24 * 365;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          foregroundPainter: _ParticlePainter(_particles),
          child: widget.child,
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final opacity = (p.life / p.initialLife).clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withValues(alpha: opacity);
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
