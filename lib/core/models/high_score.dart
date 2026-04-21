import '../enums/game_mode.dart';

class HighScore {
  final int score;
  final int snakeLength;
  final GameMode mode;
  final DateTime achievedAt;
  final String? playerName;
  final String? photoUrl;

  const HighScore({
    required this.score,
    required this.snakeLength,
    required this.mode,
    required this.achievedAt,
    this.playerName,
    this.photoUrl,
  });

  Map<String, dynamic> toJson() => {
    'score': score,
    'snakeLength': snakeLength,
    'mode': mode.index,
    'achievedAt': achievedAt.toIso8601String(),
    'playerName': playerName,
    'photoUrl': photoUrl,
  };

  factory HighScore.fromJson(Map<String, dynamic> json) => HighScore(
    score: json['score'] as int,
    snakeLength: json['snakeLength'] as int,
    mode: GameMode.values[json['mode'] as int],
    achievedAt: DateTime.parse(json['achievedAt'] as String),
    playerName: json['playerName'] as String?,
    photoUrl: json['photoUrl'] as String?,
  );
}
