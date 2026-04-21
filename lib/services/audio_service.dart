import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

enum SoundEffect { eat, powerUp, gameOver, highScore, click, countdown, shadowDefeat, shadowSteal }

class AudioService {
  static final AudioService _instance = AudioService._();
  factory AudioService() => _instance;
  AudioService._();

  final Map<SoundEffect, AudioPlayer> _players = {};
  bool _enabled = true;

  bool get enabled => _enabled;
  set enabled(bool value) => _enabled = value;

  Future<void> init() async {
    // Force Android to recognize this as a game and play sound over media channels
    await AudioPlayer.global.setAudioContext(AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: true,
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.game,
        audioFocus: AndroidAudioFocus.gainTransientMayDuck,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.ambient,
      ),
    ));

    for (final sound in SoundEffect.values) {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.stop);
      _players[sound] = player;
    }
  }

  Future<void> play(SoundEffect sound) async {
    if (!_enabled) return;
    final player = _players[sound];
    if (player == null) return;
    try {
      if (player.state == PlayerState.playing) {
        await player.stop();
      }
      await player.play(AssetSource(_soundPath(sound)));
    } catch (e) {
      // Sound files may not exist in development — silently fail
      debugPrint('Audio play error: $e');
    }
  }

  String _soundPath(SoundEffect sound) {
    switch (sound) {
      case SoundEffect.eat: return 'sounds/eat.mp3';
      case SoundEffect.powerUp: return 'sounds/power_up.mp3';
      case SoundEffect.gameOver: return 'sounds/game_over.mp3';
      case SoundEffect.highScore: return 'sounds/high_score.mp3';
      case SoundEffect.click: return 'sounds/click.mp3';
      case SoundEffect.countdown: return 'sounds/countdown.mp3';
      case SoundEffect.shadowDefeat: return 'sounds/shadow_defeat.mp3';
      case SoundEffect.shadowSteal: return 'sounds/shadow_steal.mp3';
    }
  }

  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
    _players.clear();
  }
}
