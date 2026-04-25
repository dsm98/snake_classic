import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/position.dart';

/// A rival ghost run that can be challenged asynchronously.
/// The entire path is serialised to local storage so a friend's
/// seed + path can be re-played on the same board.
class RivalGhost {
  final String rivalName;
  final int rivalScore;
  final int mapSeed;
  final List<Position> path;
  int _headIndex = 0;

  RivalGhost({
    required this.rivalName,
    required this.rivalScore,
    required this.mapSeed,
    required this.path,
  });

  // Current positions visible this tick (head + trailing body)
  static const int _bodyLength = 6;

  Position? get headPosition =>
      _headIndex < path.length ? path[_headIndex] : null;

  List<Position> get visibleSegments {
    final end = _headIndex;
    final start = (end - _bodyLength).clamp(0, end);
    return path.sublist(start, end + 1 > path.length ? path.length : end + 1);
  }

  void advance() {
    if (_headIndex < path.length - 1) _headIndex++;
  }

  void reset() => _headIndex = 0;

  bool get isFinished => _headIndex >= path.length - 1;

  Map<String, dynamic> toJson() => {
        'rivalName': rivalName,
        'rivalScore': rivalScore,
        'mapSeed': mapSeed,
        'path': path.map((p) => p.toJson()).toList(),
      };

  factory RivalGhost.fromJson(Map<String, dynamic> j) => RivalGhost(
        rivalName: j['rivalName'] as String,
        rivalScore: j['rivalScore'] as int,
        mapSeed: j['mapSeed'] as int,
        path: (j['path'] as List).map((e) => Position.fromJson(e)).toList(),
      );
}

/// Manages saving and loading the local "rival" ghost (your own best run
/// exported so friends can challenge it, and importing theirs).
class GhostRacingService extends ChangeNotifier {
  static final GhostRacingService _instance = GhostRacingService._();
  factory GhostRacingService() => _instance;
  GhostRacingService._();

  static const _keyBestGhost = 'ghost_best_run';
  static const _keyRivalGhost = 'ghost_rival_run';

  RivalGhost? activeRivalGhost;

  // ── Saving own run ───────────────────────────────────────────────
  Future<void> saveMyRun({
    required String name,
    required int score,
    required int mapSeed,
    required List<Position> path,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final ghost = RivalGhost(
      rivalName: name,
      rivalScore: score,
      mapSeed: mapSeed,
      path: path,
    );
    await prefs.setString(_keyBestGhost, jsonEncode(ghost.toJson()));
  }

  Future<RivalGhost?> loadMyRun() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyBestGhost);
    if (raw == null) return null;
    try {
      return RivalGhost.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ── Rival ghost management ────────────────────────────────────────
  Future<void> setRivalGhost(RivalGhost ghost) async {
    activeRivalGhost = ghost;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRivalGhost, jsonEncode(ghost.toJson()));
    notifyListeners();
  }

  Future<void> loadSavedRival() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyRivalGhost);
    if (raw == null) return;
    try {
      activeRivalGhost =
          RivalGhost.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      notifyListeners();
    } catch (_) {}
  }

  void startRace() {
    activeRivalGhost?.reset();
    notifyListeners();
  }

  /// Called each game tick to advance the ghost position.
  void tickGhost() {
    activeRivalGhost?.advance();
  }

  /// Export current best as a shareable JSON string (for copy/share to friend).
  Future<String?> exportShareCode() async {
    final ghost = await loadMyRun();
    if (ghost == null) return null;
    return base64Encode(utf8.encode(jsonEncode(ghost.toJson())));
  }

  /// Import a rival ghost from a share code.
  Future<bool> importShareCode(String code) async {
    try {
      final decoded = utf8.decode(base64Decode(code));
      final ghost =
          RivalGhost.fromJson(jsonDecode(decoded) as Map<String, dynamic>);
      await setRivalGhost(ghost);
      return true;
    } catch (_) {
      return false;
    }
  }
}
