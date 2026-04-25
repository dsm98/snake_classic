import 'dart:math';
import 'package:flutter/material.dart';

/// Controls a screen shake animation that can be applied as a Transform
/// overlay. Consumers should listen to [shakeOffset] and apply it to their
/// widget tree.
class ScreenShakeService extends ChangeNotifier {
  static final ScreenShakeService _instance = ScreenShakeService._();
  factory ScreenShakeService() => _instance;
  ScreenShakeService._();

  Offset _offset = Offset.zero;
  Offset get shakeOffset => _offset;

  bool _active = false;
  double _magnitude = 0;
  int _durationMs = 0;
  int _startMs = 0;
  int _tickCount = 0;
  final Random _rng = Random();

  bool get isActive => _active;

  /// Trigger a shake. Magnitude is in logical pixels.
  /// [magnitude] — max displacement per tick
  /// [durationMs] — total shake window
  void shake({double magnitude = 4.0, int durationMs = 300}) {
    _magnitude = magnitude;
    _durationMs = durationMs;
    _startMs = DateTime.now().millisecondsSinceEpoch;
    _active = true;
    _tickCount = 0;
    _nextTick();
  }

  /// Convenience shakes mapped to game events
  void eatSmall() => shake(magnitude: 2.0, durationMs: 150);
  void eatGolden() => shake(magnitude: 3.5, durationMs: 220);
  void eatBoss() => shake(magnitude: 7.0, durationMs: 350);
  void nearMiss() => shake(magnitude: 2.5, durationMs: 180);
  void gameOver() => shake(magnitude: 12.0, durationMs: 600);
  void feverStart() => shake(magnitude: 5.0, durationMs: 400);
  void powerUp() => shake(magnitude: 2.0, durationMs: 200);

  void _nextTick() {
    if (!_active) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final elapsed = nowMs - _startMs;

    if (elapsed >= _durationMs) {
      _offset = Offset.zero;
      _active = false;
      notifyListeners();
      return;
    }

    // Decay magnitude over time
    final decay = 1.0 - (elapsed / _durationMs);
    final mag = _magnitude * decay;

    final angle = _rng.nextDouble() * 2 * pi;
    _offset = Offset(cos(angle) * mag, sin(angle) * mag);
    _tickCount++;

    notifyListeners();

    // Schedule next tick
    Future.delayed(const Duration(milliseconds: 16), _nextTick);
  }

  void stop() {
    _active = false;
    _offset = Offset.zero;
    notifyListeners();
  }
}
