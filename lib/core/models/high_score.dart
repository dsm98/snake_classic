import '../enums/game_mode.dart';

class HighScore {
  final int score;
  final int snakeLength;
  final GameMode mode;
  final DateTime achievedAt;
  final String? playerName;
  final String? photoUrl;
  final int? globalRank;

  const HighScore({
    required this.score,
    required this.snakeLength,
    required this.mode,
    required this.achievedAt,
    this.playerName,
    this.photoUrl,
    this.globalRank,
  });

  Map<String, dynamic> toJson() => {
        'score': score,
        'snakeLength': snakeLength,
        'mode': mode.index,
        'modeName': mode.name,
        'achievedAt': achievedAt.toIso8601String(),
        'playerName': playerName,
        'photoUrl': photoUrl,
      };

  factory HighScore.fromJson(Map<String, dynamic> json) => HighScore(
        score: json['score'] as int,
        snakeLength: json['snakeLength'] as int,
        mode: _parseMode(json),
        achievedAt: DateTime.parse(json['achievedAt'] as String),
        playerName: json['playerName'] as String?,
        photoUrl: json['photoUrl'] as String?,
      );

  static GameMode _parseMode(Map<String, dynamic> json) {
    final modeName = json['modeName'] as String?;
    if (modeName != null) {
      for (final m in GameMode.values) {
        if (m.name == modeName) return m;
      }
    }

    final legacyIndex = json['mode'] as int? ?? 0;
    if (legacyIndex < 4) return GameMode.values[legacyIndex];
    if (legacyIndex == 4) return GameMode.endless;
    if (legacyIndex == 5) return GameMode.campaign;
    if (legacyIndex == 6) return GameMode.multiplayer;
    return GameMode.classic;
  }
}
