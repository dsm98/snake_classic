import 'package:flutter/foundation.dart';
import '../core/enums/theme_type.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storage;

  ThemeType _theme = ThemeType.retro;
  Difficulty _difficulty = Difficulty.normal;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _showJoystick = true;

  SettingsProvider(this._storage) {
    _load();
  }

  ThemeType get theme => _theme;
  Difficulty get difficulty => _difficulty;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get showJoystick => _showJoystick;

  void _load() {
    _theme = _storage.theme;
    _difficulty = _storage.difficulty;
    _soundEnabled = _storage.soundEnabled;
    _vibrationEnabled = _storage.vibrationEnabled;
    _showJoystick = _storage.showJoystick;
    AudioService().enabled = _soundEnabled;
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
    notifyListeners();
  }

  Future<void> toggleJoystick() async {
    _showJoystick = !_showJoystick;
    await _storage.saveShowJoystick(_showJoystick);
    notifyListeners();
  }

}
