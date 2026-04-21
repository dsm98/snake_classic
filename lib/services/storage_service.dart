import 'dart:convert';
import '../core/models/position.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/enums/theme_type.dart';
import '../core/models/achievement.dart';
import '../core/models/quest_model.dart';
import '../core/enums/snake_skin.dart';
import 'analytics_service.dart';

class StorageService {
  static final StorageService _instance = StorageService._();
  factory StorageService() => _instance;
  StorageService._();

  // ── Keys ────────────────────────────────────────────────────────
  static const _keyTheme             = 'theme';
  static const _keyDifficulty        = 'difficulty';
  static const _keySoundEnabled      = 'sound_enabled';
  static const _keyVibrationEnabled  = 'vibration_enabled';
  static const _keyShowJoystick      = 'show_joystick';
  static const _keyGamesPlayed       = 'games_played';

  // XP / Rank
  static const _keyTotalXp           = 'total_xp';

  // Stats
  static const _keyTotalFoodEaten    = 'stat_food_total';
  static const _keyTotalPowerUps     = 'stat_pu_total';
  static const _keyBestCombo         = 'stat_best_combo';
  static const _keyTotalGoldenApples = 'stat_gold_total';
  static const _keyTotalPoisonApples = 'stat_poison_total';
  static const _keyShadowDefeats     = 'stat_shadow_defeats';
  static const _keyQuestsCompleted   = 'stat_quests_total';

  // Economy & Shop
  static const _keyCoins = 'coins_balance';
  static const _keyUnlockedSkins = 'unlocked_skins';
  static const _keyEquippedSkin = 'equipped_skin';

  // Achievements
  static const _keyAchievementsPrefix = 'ach_';

  // Daily streak & Quests
  static const _keyLastPlayedDate    = 'last_played_date';
  static const _keyDailyStreak       = 'daily_streak';
  static const _keyQuestsDate        = 'quests_date';
  static const _keyWeeklyQuestsDate  = 'weekly_quests_date';
  static const _keyQuests            = 'quests_data';
  
  static const _keyCampaignLevel     = 'highest_campaign_level';
  static const _keyBestScore         = 'best_score_all_time';
  static const _keyBestLength        = 'best_length_all_time';
  static const _keyPrestigeLevel     = 'prestige_level';
  static const _keyBestReplay        = 'best_replay_data';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Settings ───────────────────────────────────────────────────
  ThemeType get theme =>
      ThemeType.values[_prefs.getInt(_keyTheme) ?? ThemeType.retro.index];
  Future<void> saveTheme(ThemeType t) => _prefs.setInt(_keyTheme, t.index);

  Difficulty get difficulty =>
      Difficulty.values[_prefs.getInt(_keyDifficulty) ?? Difficulty.normal.index];
  Future<void> saveDifficulty(Difficulty d) => _prefs.setInt(_keyDifficulty, d.index);

  bool get soundEnabled => _prefs.getBool(_keySoundEnabled) ?? true;
  Future<void> saveSoundEnabled(bool v) => _prefs.setBool(_keySoundEnabled, v);

  bool get vibrationEnabled => _prefs.getBool(_keyVibrationEnabled) ?? true;
  Future<void> saveVibrationEnabled(bool v) => _prefs.setBool(_keyVibrationEnabled, v);

  bool get showJoystick => _prefs.getBool(_keyShowJoystick) ?? true;
  Future<void> saveShowJoystick(bool v) => _prefs.setBool(_keyShowJoystick, v);

  // ── Ads / games played ─────────────────────────────────────────
  int get gamesPlayed => _prefs.getInt(_keyGamesPlayed) ?? 0;
  Future<void> incrementGamesPlayed() =>
      _prefs.setInt(_keyGamesPlayed, gamesPlayed + 1);

  // ── Shop & Economy ──────────────────────────────────────────────
  int get coins => _prefs.getInt(_keyCoins) ?? 0;
  Future<void> addCoins(int amount) => _prefs.setInt(_keyCoins, coins + amount);
  Future<void> deductCoins(int amount) {
    int newval = coins - amount;
    return _prefs.setInt(_keyCoins, newval < 0 ? 0 : newval);
  }

  List<SnakeSkin> get unlockedSkins {
    final list = _prefs.getStringList(_keyUnlockedSkins) ?? [];
    if (list.isEmpty) return [SnakeSkin.classic];
    return list.map((e) => SnakeSkin.values.firstWhere((s) => s.name == e, orElse: () => SnakeSkin.classic)).toSet().toList();
  }

  Future<void> unlockSkin(SnakeSkin skin) async {
    final list = unlockedSkins;
    if (!list.contains(skin)) {
      list.add(skin);
      await _prefs.setStringList(_keyUnlockedSkins, list.map((e) => e.name).toList());
    }
  }

  SnakeSkin get equippedSkin {
    final name = _prefs.getString(_keyEquippedSkin) ?? SnakeSkin.classic.name;
    return SnakeSkin.values.firstWhere((e) => e.name == name, orElse: () => SnakeSkin.classic);
  }

  Future<void> equipSkin(SnakeSkin skin) async {
    if (unlockedSkins.contains(skin)) {
      await _prefs.setString(_keyEquippedSkin, skin.name);
    }
  }

  // ── XP & Rank ──────────────────────────────────────────────────
  int get totalXp => _prefs.getInt(_keyTotalXp) ?? 0;

  Future<void> addXp(int xp) async {
    await _prefs.setInt(_keyTotalXp, totalXp + xp);
  }

  Future<void> setTotalXp(int xp) async {
    await _prefs.setInt(_keyTotalXp, xp);
  }

  Future<void> setDailyStreak(int streak) async {
    await _prefs.setInt(_keyDailyStreak, streak);
  }

  /// Rank title and level (0–9) based on XP thresholds
  static const List<int> _rankThresholds = [
    0, 500, 1500, 3000, 5500, 9000, 14000, 21000, 30000, 45000,
  ];
  static const List<String> rankTitles = [
    'Hatchling', 'Crawler', 'Slitherer', 'Viper', 'Cobra',
    'Asp', 'Python', 'Anaconda', 'King Cobra', 'Serpent God',
  ];
  static const List<String> rankEmojis = [
    '🥚', '🐛', '🐍', '🦎', '🐍', '⚡', '🐉', '🔱', '👑', '🌟',
  ];

  int get rankLevel {
    final xp = totalXp;
    int level = 0;
    for (int i = _rankThresholds.length - 1; i >= 0; i--) {
      if (xp >= _rankThresholds[i]) { level = i; break; }
    }
    return level;
  }

  int get prestigeLevel => _prefs.getInt(_keyPrestigeLevel) ?? 0;
  Future<void> setPrestigeLevel(int lvl) => _prefs.setInt(_keyPrestigeLevel, lvl);

  String get rankTitle {
    final base = rankTitles[rankLevel];
    if (prestigeLevel == 0) return base;
    return 'Legend $prestigeLevel $base';
  }

  String get rankEmoji {
    if (prestigeLevel == 0) return rankEmojis[rankLevel];
    return '⭐ $prestigeLevel';
  }

  /// Progress within current rank (0.0 – 1.0)
  double get rankProgress {
    final xp = totalXp;
    final level = rankLevel;
    if (level >= _rankThresholds.length - 1) return 1.0;
    final current = _rankThresholds[level];
    final next    = _rankThresholds[level + 1];
    return ((xp - current) / (next - current)).clamp(0.0, 1.0);
  }

  int get xpToNextRank {
    final level = rankLevel;
    if (level >= _rankThresholds.length - 1) return 0;
    return _rankThresholds[level + 1] - totalXp;
  }

  // ── Lifetime stats ─────────────────────────────────────────────
  int get totalFoodEaten => _prefs.getInt(_keyTotalFoodEaten) ?? 0;
  Future<void> addFoodEaten(int n) =>
      _prefs.setInt(_keyTotalFoodEaten, totalFoodEaten + n);

  int get totalPowerUpsCollected => _prefs.getInt(_keyTotalPowerUps) ?? 0;
  Future<void> addPowerUpsCollected(int n) =>
      _prefs.setInt(_keyTotalPowerUps, totalPowerUpsCollected + n);

  int get totalGoldenApplesEaten => _prefs.getInt(_keyTotalGoldenApples) ?? 0;
  Future<void> addGoldenApplesEaten(int n) =>
      _prefs.setInt(_keyTotalGoldenApples, totalGoldenApplesEaten + n);

  int get totalPoisonApplesEaten => _prefs.getInt(_keyTotalPoisonApples) ?? 0;
  Future<void> addPoisonApplesEaten(int n) =>
      _prefs.setInt(_keyTotalPoisonApples, totalPoisonApplesEaten + n);

  int get shadowDefeats => _prefs.getInt(_keyShadowDefeats) ?? 0;
  Future<void> addShadowDefeats(int n) =>
      _prefs.setInt(_keyShadowDefeats, shadowDefeats + n);

  int get questsCompletedCount => _prefs.getInt(_keyQuestsCompleted) ?? 0;
  Future<void> addQuestsCompletedCount(int n) =>
      _prefs.setInt(_keyQuestsCompleted, questsCompletedCount + n);

  int get bestComboEver => _prefs.getInt(_keyBestCombo) ?? 0;
  Future<void> updateBestCombo(int combo) async {
    if (combo > bestComboEver) await _prefs.setInt(_keyBestCombo, combo);
  }

  int get bestScore => _prefs.getInt(_keyBestScore) ?? 0;
  Future<void> updateBestScore(int score) async {
    if (score > bestScore) await _prefs.setInt(_keyBestScore, score);
  }

  int get bestLength => _prefs.getInt(_keyBestLength) ?? 0;
  Future<void> updateBestLength(int length) async {
    if (length > bestLength) await _prefs.setInt(_keyBestLength, length);
  }

  List<Position> getBestReplay() {
    final raw = _prefs.getString(_keyBestReplay);
    if (raw == null) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((e) => Position.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveBestReplay(List<Position> path) async {
    await _prefs.setString(_keyBestReplay, jsonEncode(path.map((e) => e.toJson()).toList()));
  }

  // ── Daily streak ───────────────────────────────────────────────
  int get dailyStreak => _prefs.getInt(_keyDailyStreak) ?? 0;

  /// Call once per game session — updates streak and returns whether it was a new day
  Future<bool> checkAndUpdateStreak() async {
    final today = todayString();
    final last  = _prefs.getString(_keyLastPlayedDate) ?? '';
    if (last == today) return false; // already played today

    final yesterday = yesterdayString();
    final newStreak = (last == yesterday) ? dailyStreak + 1 : 1;
    await _prefs.setInt(_keyDailyStreak, newStreak);
    await _prefs.setString(_keyLastPlayedDate, today);
    return true; // new day
  }

  String todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
  }

  String yesterdayString() {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return '${y.year}-${y.month.toString().padLeft(2,'0')}-${y.day.toString().padLeft(2,'0')}';
  }

  // ── Achievements ───────────────────────────────────────────────
  AchievementProgress getAchievementProgress(String id) {
    final raw = _prefs.getString('$_keyAchievementsPrefix$id');
    if (raw == null) return AchievementProgress(id: id);
    try {
      return AchievementProgress.fromJson(jsonDecode(raw));
    } catch (_) {
      return AchievementProgress(id: id);
    }
  }

  List<AchievementProgress> getAllAchievementProgress() =>
      Achievements.all.map((a) => getAchievementProgress(a.id)).toList();

  Future<void> _saveAchievementProgress(AchievementProgress p) async {
    await _prefs.setString('$_keyAchievementsPrefix${p.id}', jsonEncode(p.toJson()));
  }

  Future<void> forceSaveAchievements(List<AchievementProgress> updates) async {
    for (final p in updates) {
      await _saveAchievementProgress(p);
    }
  }

  /// Returns list of newly unlocked achievement IDs
  Future<List<String>> checkAchievements({
    required int score,
    required int snakeLength,
    required int combo,
    int? shadowDefeatsExtra,
    int? questsCompletedExtra,
  }) async {
    final unlocked = <String>[];
    final games = gamesPlayed;
    final food  = totalFoodEaten;
    final pus   = totalPowerUpsCollected;
    final gold  = totalGoldenApplesEaten;
    final poison = totalPoisonApplesEaten;
    final shadow = shadowDefeats + (shadowDefeatsExtra ?? 0);
    final qTotal = questsCompletedCount + (questsCompletedExtra ?? 0);

    if (shadowDefeatsExtra != null && shadowDefeatsExtra > 0) await addShadowDefeats(shadowDefeatsExtra);
    if (questsCompletedExtra != null && questsCompletedExtra > 0) await addQuestsCompletedCount(questsCompletedExtra);

    for (final ach in Achievements.all) {
      final prog = getAchievementProgress(ach.id);
      if (prog.unlocked) continue;

      int currentValue = 0;
      switch (ach.type) {
        case AchievementType.score:       currentValue = score;        break;
        case AchievementType.length:      currentValue = snakeLength;  break;
        case AchievementType.gamesPlayed: currentValue = games;        break;
        case AchievementType.foodEaten:   currentValue = food;         break;
        case AchievementType.combo:       currentValue = combo;        break;
        case AchievementType.powerUps:    currentValue = pus;          break;
        case AchievementType.modePlay:    currentValue = 1;            break;
        case AchievementType.survive:     currentValue = 0;            break;
        case AchievementType.goldenApple: currentValue = gold;         break;
        case AchievementType.poisonApple: currentValue = poison;       break;
        case AchievementType.shadowDefeat: currentValue = shadow;      break;
        case AchievementType.questsCompleted: currentValue = qTotal;   break;
        case AchievementType.completionist: 
          currentValue = getAllAchievementProgress().where((p) => p.unlocked && p.id != 'all_ach').length;
          break;
      }

      // Only update if we've made forward progress
      if (currentValue > prog.progress) {
        final newProg = prog.copyWith(progress: currentValue);
        if (currentValue >= ach.targetValue) {
          await _saveAchievementProgress(newProg.copyWith(
            unlocked: true,
            unlockedAt: DateTime.now(),
          ));
          await addXp(ach.xpReward);
          unlocked.add(ach.id);
          AnalyticsService().logAchievementUnlocked(ach.id);
        } else {
          await _saveAchievementProgress(newProg);
        }
      }
    }
    return unlocked;
  }

  // ── Daily Quests ───────────────────────────────────────────────
  String get questsDate => _prefs.getString(_keyQuestsDate) ?? '';
  Future<void> saveQuestsDate(String date) => _prefs.setString(_keyQuestsDate, date);

  String get weeklyQuestsDate => _prefs.getString(_keyWeeklyQuestsDate) ?? '';
  Future<void> saveWeeklyQuestsDate(String date) => _prefs.setString(_keyWeeklyQuestsDate, date);

  List<DailyQuest> get quests {
    final raw = _prefs.getString(_keyQuests);
    if (raw == null) return [];
    try {
      final List dec = jsonDecode(raw);
      return dec.map((e) => DailyQuest.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveQuests(List<DailyQuest> quests) async {
    final raw = jsonEncode(quests.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyQuests, raw);
  }

  // ── Campaign ───────────────────────────────────────────────────
  int get highestCampaignLevel => _prefs.getInt(_keyCampaignLevel) ?? 1;
  Future<void> setHighestCampaignLevel(int level) => _prefs.setInt(_keyCampaignLevel, level);
}
