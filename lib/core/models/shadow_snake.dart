import 'position.dart';

class ShadowSnake {
  final List<Position> segments;
  int wins;
  int moveTicks;

  ShadowSnake({
    required this.segments,
    this.wins = 0,
    this.moveTicks = 0,
  });

  ShadowSnake copyWith({
    List<Position>? segments,
    int? wins,
    int? moveTicks,
  }) {
    return ShadowSnake(
      segments: segments ?? this.segments,
      wins: wins ?? this.wins,
      moveTicks: moveTicks ?? this.moveTicks,
    );
  }
}
