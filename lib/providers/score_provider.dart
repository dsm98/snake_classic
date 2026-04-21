import 'package:flutter/foundation.dart';
import '../core/enums/game_mode.dart';
import '../core/models/high_score.dart';
import '../services/leaderboard_service.dart';

class ScoreProvider extends ChangeNotifier {
  final LeaderboardService _leaderboard = LeaderboardService();

  Future<List<HighScore>> getGlobalScores(GameMode mode) async {
    return _leaderboard.getGlobalTopScores(mode);
  }

  Future<void> submitScore(HighScore score) async {
    await _leaderboard.submitScore(score);
    notifyListeners();
  }
}
