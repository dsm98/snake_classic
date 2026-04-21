import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/enums/game_mode.dart';
import '../core/models/high_score.dart';
import 'auth_service.dart';

class LeaderboardService {
  static final LeaderboardService _instance = LeaderboardService._();
  factory LeaderboardService() => _instance;
  LeaderboardService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();

  /// Submits a score. Returns true if this is a NEW personal best for the player.
  Future<bool> submitScore(HighScore score) async {
    if (!_auth.isSignedIn) return false;

    try {
      final String playerId = _auth.userId;
      final String playerName = _auth.playerName;
      final String? photoUrl = _auth.currentUser?.photoURL;

      final String collectionName =
          'leaderboard_${score.mode.name.toLowerCase()}';
      final docRef = _db.collection(collectionName).doc(playerId);
      final doc = await docRef.get();

      if (doc.exists) {
        final existingScore = doc.data()?['score'] as int? ?? 0;
        if (score.score > existingScore) {
          // New personal best — update and return true
          await docRef.update({
            'score': score.score,
            'playerName': playerName,
            'photoUrl': photoUrl,
            'snakeLength': score.snakeLength,
            'achievedAt': FieldValue.serverTimestamp(),
          });
          return true;
        }
        // Not a new best
        return false;
      } else {
        // First ever score for this player/mode
        await docRef.set({
          'playerId': playerId,
          'playerName': playerName,
          'photoUrl': photoUrl,
          'score': score.score,
          'snakeLength': score.snakeLength,
          'achievedAt': FieldValue.serverTimestamp(),
        });
        // First entry is only a "high score moment" if score > 0
        return score.score > 0;
      }
    } catch (e) {
      print('Error submitting global score: $e');
      return false;
    }
  }

  /// Fetches Top 10 global scores for a mode (includes photoUrl)
  Future<List<HighScore>> getGlobalTopScores(GameMode mode) async {
    try {
      final String collectionName =
          'leaderboard_${mode.name.toLowerCase()}';
      final snapshot = await _db
          .collection(collectionName)
          .orderBy('score', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return HighScore(
          score: data['score'] as int? ?? 0,
          snakeLength: data['snakeLength'] as int? ?? 0,
          mode: mode,
          achievedAt:
              (data['achievedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          playerName: data['playerName'] as String? ?? 'Anonymous',
          photoUrl: data['photoUrl'] as String?,
        );
      }).toList();
    } catch (e) {
      print('Error fetching global scores: $e');
      return [];
    }
  }

  /// Fetches the current player's personal best for a given mode.
  Future<int> getPersonalBest(GameMode mode) async {
    if (!_auth.isSignedIn) return 0;
    try {
      final String collectionName =
          'leaderboard_${mode.name.toLowerCase()}';
      final doc = await _db
          .collection(collectionName)
          .doc(_auth.userId)
          .get();
      if (!doc.exists) return 0;
      return doc.data()?['score'] as int? ?? 0;
    } catch (e) {
      print('Error fetching personal best: $e');
      return 0;
    }
  }
}
