import 'package:vibration/vibration.dart';
import 'package:flutter/services.dart';
import '../core/enums/haptic_intensity.dart';

class VibrationService {
  static final VibrationService _instance = VibrationService._();
  factory VibrationService() => _instance;
  VibrationService._();

  bool _enabled = true;
  HapticIntensity _intensity = HapticIntensity.medium;
  bool get enabled => _enabled;
  set enabled(bool value) => _enabled = value;

  void setIntensity(HapticIntensity intensity) {
    _intensity = intensity;
  }

  int get _baseAmplitude {
    switch (_intensity) {
      case HapticIntensity.light:
        return 80;
      case HapticIntensity.medium:
        return 160;
      case HapticIntensity.strong:
        return 255;
    }
  }

  int get _shortDuration {
    switch (_intensity) {
      case HapticIntensity.light:
        return 35;
      case HapticIntensity.medium:
        return 55;
      case HapticIntensity.strong:
        return 80;
    }
  }

  Future<void> vibrate({int duration = 50, int amplitude = -1}) async {
    if (!_enabled) return;
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(
        duration: duration == 50 ? _shortDuration : duration,
        amplitude: amplitude == -1 ? _baseAmplitude : amplitude,
      );
    }
  }

  /// Heartbeat pattern for high intensity moments
  Future<void> heartbeat() async {
    if (!_enabled) return;
    if (await Vibration.hasVibrator()) {
      final peak = _baseAmplitude;
      final low = (peak * 0.5).round();
      Vibration.vibrate(
          pattern: [0, 50, 100, 50], intensities: [0, low, 0, peak]);
    }
  }

  /// Explosive pattern for game over or mega combo
  Future<void> impact() async {
    if (!_enabled) return;
    switch (_intensity) {
      case HapticIntensity.light:
        HapticFeedback.lightImpact();
        break;
      case HapticIntensity.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticIntensity.strong:
        HapticFeedback.heavyImpact();
        break;
    }
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(
          duration: _shortDuration * 2, amplitude: _baseAmplitude);
    }
  }

  /// Success ripple for power-ups
  Future<void> ripple() async {
    if (!_enabled) return;
    switch (_intensity) {
      case HapticIntensity.light:
        HapticFeedback.selectionClick();
        break;
      case HapticIntensity.medium:
      case HapticIntensity.strong:
        HapticFeedback.lightImpact();
        break;
    }
    final peak = _baseAmplitude;
    final mid = (peak * 0.6).round();
    final low = (peak * 0.3).round();
    Vibration.vibrate(
        pattern: [0, 30, 20, 30, 20, 30],
        intensities: [0, low, 0, mid, 0, peak]);
  }

  /// Ascending triple pulse for level up / floor clear
  Future<void> levelUp() async {
    if (!_enabled) return;
    final peak = _baseAmplitude;
    final mid = (peak * 0.7).round();
    final low = (peak * 0.4).round();
    Vibration.vibrate(
      pattern: [0, 100, 150, 100, 150, 200],
      intensities: [0, low, 0, mid, 0, peak],
    );
  }
}
