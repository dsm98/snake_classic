import 'package:vibration/vibration.dart';
import 'package:flutter/services.dart';

class VibrationService {
  static final VibrationService _instance = VibrationService._();
  factory VibrationService() => _instance;
  VibrationService._();

  bool _enabled = true;
  bool get enabled => _enabled;
  set enabled(bool value) => _enabled = value;

  Future<void> vibrate({int duration = 50, int amplitude = -1}) async {
    if (!_enabled) return;
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: duration, amplitude: amplitude);
    }
  }

  /// Heartbeat pattern for high intensity moments
  Future<void> heartbeat() async {
    if (!_enabled) return;
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 50, 100, 50], intensities: [0, 128, 0, 255]);
    }
  }

  /// Explosive pattern for game over or mega combo
  Future<void> impact() async {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100, amplitude: 255);
    }
  }

  /// Success ripple for power-ups
  Future<void> ripple() async {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
    Vibration.vibrate(pattern: [0, 30, 20, 30, 20, 30], intensities: [0, 64, 0, 128, 0, 255]);
  }
}
