import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../services/storage_service.dart';

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
  final Random _rng = Random();
  Ticker? _ticker;

  bool get isActive => _active;

  /// Trigger a shake. Magnitude is in logical pixels.
  /// [magnitude] — max displacement per tick
  /// [durationMs] — total shake window
  void shake({double magnitude = 4.0, int durationMs = 300}) {
    if (StorageService().reducedMotion) return;
    
    _magnitude = magnitude;
    _durationMs = durationMs;
    _startMs = DateTime.now().millisecondsSinceEpoch;
    _active = true;

    _ticker?.stop();
    _ticker = Ticker(_onTick)..start();
  }

  /// Convenience shakes mapped to game events
  void eatSmall() => shake(magnitude: 2.5, durationMs: 150);
  void eatGolden() => shake(magnitude: 4.5, durationMs: 250);
  void eatBoss() => shake(magnitude: 8.0, durationMs: 400);
  void nearMiss() => shake(magnitude: 3.0, durationMs: 200);
  void gameOver() => shake(magnitude: 14.0, durationMs: 700);
  void feverStart() => shake(magnitude: 6.0, durationMs: 500);
  void powerUp() => shake(magnitude: 2.5, durationMs: 250);

  void _onTick(Duration elapsed) {
    if (!_active) {
      _ticker?.stop();
      return;
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final elapsedMs = nowMs - _startMs;

    if (elapsedMs >= _durationMs) {
      _offset = Offset.zero;
      _active = false;
      _ticker?.stop();
      notifyListeners();
      return;
    }

    // Decay magnitude over time (exponential decay for smoother feel)
    final progress = elapsedMs / _durationMs;
    final decay = pow(1.0 - progress, 1.5).toDouble();
    final mag = _magnitude * decay;

    final angle = _rng.nextDouble() * 2 * pi;
    // Rapidly alternating directions for high-frequency vibration feel
    _offset = Offset(cos(angle) * mag, sin(angle) * mag);

    notifyListeners();
  }

  void stop() {
    _active = false;
    _offset = Offset.zero;
    _ticker?.stop();
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }
}
