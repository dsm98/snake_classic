import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Adaptive music layer system.
/// 
/// The game uses 3 layered audio tracks playing simultaneously:
///   - [Layer.base]   — the constant ambient/bass layer (always on)
///   - [Layer.mid]    — added when combo ≥ 3 or score > 200
///   - [Layer.hype]   — added when fever mode or combo ≥ 6
/// 
/// All tracks are started in sync and only volume is faded up/down
/// (requires the assets to be seamlessly loopable .ogg/.mp3 files of
///  the same BPM and length). If files don't exist they fail silently.
enum MusicLayer { base, mid, hype }

enum MusicState { idle, normal, combo, fever }

class AdaptiveMusicService {
  static final AdaptiveMusicService _instance = AdaptiveMusicService._();
  factory AdaptiveMusicService() => _instance;
  AdaptiveMusicService._();

  final Map<MusicLayer, AudioPlayer> _players = {};
  bool _enabled = true;
  MusicState _currentState = MusicState.idle;
  bool _initialized = false;

  bool get enabled => _enabled;
  set enabled(bool v) {
    _enabled = v;
    if (!v) _muteAll();
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    for (final layer in MusicLayer.values) {
      try {
        final player = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.loop);
        await player.setVolume(0.0);
        _players[layer] = player;
        // Start all tracks in sync (volume = 0 for mid/hype until needed)
        await player.play(AssetSource(_trackPath(layer)));
      } catch (e) {
        debugPrint('AdaptiveMusic init error layer $layer: $e');
      }
    }
    // Bring in the base layer at full volume
    _setVolume(MusicLayer.base, 0.45);
    _currentState = MusicState.normal;
  }

  String _trackPath(MusicLayer layer) {
    switch (layer) {
      case MusicLayer.base:
        return 'sounds/music_base.mp3';
      case MusicLayer.mid:
        return 'sounds/music_mid.mp3';
      case MusicLayer.hype:
        return 'sounds/music_hype.mp3';
    }
  }

  Future<void> _setVolume(MusicLayer layer, double volume) async {
    try {
      await _players[layer]?.setVolume(volume.clamp(0.0, 1.0));
    } catch (_) {}
  }

  void _muteAll() {
    for (final layer in MusicLayer.values) {
      _setVolume(layer, 0.0);
    }
  }

  /// Call this every game tick with the current game state so the music
  /// layers transition smoothly.
  Future<void> update({
    required int combo,
    required bool isFeverMode,
    required bool isGameOver,
    required bool isPaused,
  }) async {
    if (!_enabled) return;

    MusicState target;
    if (isGameOver || isPaused) {
      target = MusicState.idle;
    } else if (isFeverMode || combo >= 6) {
      target = MusicState.fever;
    } else if (combo >= 3) {
      target = MusicState.combo;
    } else {
      target = MusicState.normal;
    }

    if (target == _currentState) return;
    _currentState = target;
    _applyState(target);
  }

  void _applyState(MusicState state) {
    switch (state) {
      case MusicState.idle:
        // Fade all layers to soft
        _setVolume(MusicLayer.base, 0.18);
        _setVolume(MusicLayer.mid, 0.0);
        _setVolume(MusicLayer.hype, 0.0);
        break;
      case MusicState.normal:
        _setVolume(MusicLayer.base, 0.45);
        _setVolume(MusicLayer.mid, 0.0);
        _setVolume(MusicLayer.hype, 0.0);
        break;
      case MusicState.combo:
        // Layer in mid track
        _setVolume(MusicLayer.base, 0.40);
        _setVolume(MusicLayer.mid, 0.40);
        _setVolume(MusicLayer.hype, 0.0);
        break;
      case MusicState.fever:
        // All layers roaring
        _setVolume(MusicLayer.base, 0.35);
        _setVolume(MusicLayer.mid, 0.45);
        _setVolume(MusicLayer.hype, 0.55);
        break;
    }
  }

  Future<void> stopAll() async {
    for (final player in _players.values) {
      try { await player.stop(); } catch (_) {}
    }
    _currentState = MusicState.idle;
    _initialized = false;
  }

  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
    _players.clear();
    _initialized = false;
  }
}
