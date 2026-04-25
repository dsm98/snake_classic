import 'package:flutter/foundation.dart';
import '../core/enums/theme_type.dart';
import '../core/enums/haptic_intensity.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../services/vibration_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storage;

  ThemeType _theme = ThemeType.neon;
  Difficulty _difficulty = Difficulty.normal;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _showJoystick = false;
  bool _showRunModifierPrompt = true;
  double _fontScale = 1.0;
  bool _reducedMotion = false;
  HapticIntensity _hapticIntensity = HapticIntensity.medium;

  SettingsProvider(this._storage) {
    _load();
  }

  ThemeType get theme => _theme;
  Difficulty get difficulty => _difficulty;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get showJoystick => _showJoystick;
  bool get showRunModifierPrompt => _showRunModifierPrompt;
  double get fontScale => _fontScale;
  bool get reducedMotion => _reducedMotion;
  HapticIntensity get hapticIntensity => _hapticIntensity;

  void _load() {
    _theme = _storage.theme;
    _difficulty = _storage.difficulty;
    _soundEnabled = _storage.soundEnabled;
    _vibrationEnabled = _storage.vibrationEnabled;
    _showJoystick = _storage.showJoystick;
    _showRunModifierPrompt = _storage.showRunModifierPrompt;
    _fontScale = _storage.fontScale;
    _reducedMotion = _storage.reducedMotion;
    _hapticIntensity = HapticIntensity.values[_storage.hapticIntensityIndex
        .clamp(0, HapticIntensity.values.length - 1)];
    AudioService().enabled = _soundEnabled;
    VibrationService().enabled = _vibrationEnabled;
    VibrationService().setIntensity(_hapticIntensity);
  }

  Future<void> setTheme(ThemeType t) async {
    _theme = t;
    await _storage.saveTheme(t);
    notifyListeners();
  }

  Future<void> setDifficulty(Difficulty d) async {
    _difficulty = d;
    await _storage.saveDifficulty(d);
    notifyListeners();
  }

  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    AudioService().enabled = _soundEnabled;
    await _storage.saveSoundEnabled(_soundEnabled);
    notifyListeners();
  }

  Future<void> toggleVibration() async {
    _vibrationEnabled = !_vibrationEnabled;
    await _storage.saveVibrationEnabled(_vibrationEnabled);
    VibrationService().enabled = _vibrationEnabled;
    notifyListeners();
  }

  Future<void> toggleJoystick() async {
    _showJoystick = !_showJoystick;
    await _storage.saveShowJoystick(_showJoystick);
    notifyListeners();
  }

  Future<void> toggleRunModifierPrompt() async {
    _showRunModifierPrompt = !_showRunModifierPrompt;
    await _storage.saveShowRunModifierPrompt(_showRunModifierPrompt);
    notifyListeners();
  }

  Future<void> setFontScale(double value) async {
    _fontScale = value.clamp(0.9, 1.35);
    await _storage.saveFontScale(_fontScale);
    notifyListeners();
  }

  Future<void> toggleReducedMotion() async {
    _reducedMotion = !_reducedMotion;
    await _storage.saveReducedMotion(_reducedMotion);
    notifyListeners();
  }

  Future<void> setHapticIntensity(HapticIntensity value) async {
    _hapticIntensity = value;
    await _storage.saveHapticIntensityIndex(value.index);
    VibrationService().setIntensity(value);
    notifyListeners();
  }
}
